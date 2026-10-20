const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const fixturePath = path.resolve(__dirname, '../aster-test-server.py');
const generated = spawnSync('python3', ['-B', '-c', `
import importlib.util
import json
import re
import sys

spec = importlib.util.spec_from_file_location('aster_fixture', sys.argv[1])
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
page = fixture.PAGES['/media/fullscreen.html'].decode()
print(json.dumps(re.findall(r'<script\\b[^>]*>(.*?)</script\\s*>', page, re.S | re.I)))
`, fixturePath], { encoding: 'utf8' });
assert.equal(generated.status, 0, generated.stderr || 'Could not generate fullscreen fixture');
const scripts = JSON.parse(generated.stdout);
assert.equal(scripts.length, 1, 'Exercise the actual generated fullscreen script');

function eventTarget() {
    const listeners = new Map();
    return {
        addEventListener(type, callback) {
            if (!listeners.has(type)) listeners.set(type, []);
            listeners.get(type).push(callback);
        },
        emit(type) {
            for (const callback of listeners.get(type) || []) callback({ type });
        },
    };
}

function createScene(orientation = 'landscape', { resizeObserver = true } = {}) {
    let now = 100;
    let fullscreen = true;
    let dimensions = orientation === 'landscape' ? [932, 430] : [430, 932];
    let decodedFrames = 0;
    const media = {
        currentTime: 0,
        duration: 6,
        paused: false,
        seeking: false,
        ended: false,
        videoWidth: 160,
        videoHeight: 90,
        readyState: 4,
        networkState: 1,
        playbackRate: 1,
        error: null,
        muted: false,
        volume: 1,
        loop: true,
        src: '/media/video.mp4',
    };
    const actions = [];
    const forbidden = name => () => {
        actions.push(name);
        assert.fail(`Observation must not invoke ${name}`);
    };
    const frameCallbacks = [];
    const video = {
        ...eventTarget(),
        play: forbidden('video.play'),
        pause: forbidden('video.pause'),
        load: forbidden('video.load'),
        fastSeek: forbidden('video.fastSeek'),
        requestVideoFrameCallback(callback) {
            frameCallbacks.push(callback);
            return decodedFrames + 1;
        },
    };
    for (const property of Object.keys(media)) {
        Object.defineProperty(video, property, {
            get: () => media[property],
            set: forbidden(`video.${property} assignment`),
        });
    }
    const stage = {
        get clientWidth() { return dimensions[0]; },
        get clientHeight() { return dimensions[1]; },
        requestFullscreen: forbidden('stage.requestFullscreen'),
    };
    const elements = {
        stage,
        v: video,
        status: { textContent: 'Waiting for fullscreen' },
        'media-state': { textContent: '' },
        'loop-state': { textContent: 'Loop playback pending' },
        'media-clock': { textContent: 'Aster media clock null' },
        'rotation-state': { textContent: 'Waiting for first-loop boundary rotation' },
        'rotation-observation': { textContent: 'Aster rotation observation null' },
        enter: {},
        exit: {},
    };
    const document = {
        ...eventTarget(),
        getElementById(id) {
            assert.ok(Object.hasOwn(elements, id), `Unexpected element ${id}`);
            return elements[id];
        },
        get fullscreenElement() { return fullscreen ? stage : null; },
        visibilityState: 'visible',
        exitFullscreen: forbidden('document.exitFullscreen'),
    };
    const window = eventTarget();
    const intervals = [];
    let resizeCallback;
    const observedTargets = new Set();
    class FakeResizeObserver {
        constructor(callback) {
            assert.equal(resizeCallback, undefined, 'Only one stage observer is needed');
            resizeCallback = callback;
        }
        observe(target) {
            assert.equal(target, stage, 'Observe the actual fullscreen stage');
            observedTargets.add(target);
        }
    }
    const ResizeObserver = resizeObserver ? FakeResizeObserver : undefined;
    window.ResizeObserver = ResizeObserver;
    vm.runInNewContext(scripts[0], {
        document,
        window,
        ResizeObserver,
        performance: { now: () => now },
        Date: { now: () => 1760000000000 + now },
        setInterval(callback, milliseconds) {
            assert.equal(milliseconds, 500);
            intervals.push(callback);
            return intervals.length;
        },
    }, { filename: `${fixturePath}:fullscreen`, timeout: 1000 });
    assert.equal(intervals.length, 1);

    const scene = {
        media,
        actions,
        video,
        document,
        window,
        get status() { return elements.status.textContent; },
        get loopStatus() { return elements['loop-state'].textContent; },
        get diagnostic() { return elements['media-state'].textContent; },
        enter() { return elements.enter.onclick(); },
        get epochMs() { return 1760000000000 + now; },
        get clock() {
            const label = elements['media-clock'].textContent;
            assert.ok(label.startsWith('Aster media clock '));
            return JSON.parse(label.slice('Aster media clock '.length));
        },
        get rotationStatus() { return elements['rotation-state'].textContent; },
        get rotation() {
            const label = elements['rotation-observation'].textContent;
            assert.ok(label.startsWith('Aster rotation observation '));
            return JSON.parse(label.slice('Aster rotation observation '.length));
        },
        tick(milliseconds = 500) {
            now += milliseconds;
            intervals[0]();
        },
        sample(currentTime, { frame = true, milliseconds = 100 } = {}) {
            now += milliseconds;
            media.currentTime = currentTime;
            if (frame) {
                assert.equal(frameCallbacks.length, 1, 'Observe each decoded frame once');
                const callback = frameCallbacks.shift();
                callback(now, { mediaTime: currentTime, presentedFrames: ++decodedFrames });
            }
            video.emit('timeupdate');
        },
        setOrientation(nextOrientation) {
            dimensions = nextOrientation === 'landscape' ? [932, 430] : [430, 932];
        },
        setDimensions(width, height) {
            dimensions = [width, height];
        },
        deliverStageResize(milliseconds = 0) {
            now += milliseconds;
            assert.ok(observedTargets.has(stage), 'The real stage must be observed before callback delivery');
            resizeCallback([{ target: stage, contentRect: {
                width: stage.clientWidth, height: stage.clientHeight,
            } }]);
        },
        rotate(nextOrientation) {
            scene.setOrientation(nextOrientation);
            window.emit('resize');
            if (resizeObserver) scene.deliverStageResize();
        },
        exit() {
            fullscreen = false;
            document.emit('fullscreenchange');
        },
    };
    scene.tick();
    if (resizeObserver) scene.deliverStageResize();
    return scene;
}

function expectPending(scene) {
    assert.equal(scene.loopStatus, 'Loop playback pending');
}

function expectWaiting(scene, orientation = 'landscape') {
    assert.equal(scene.status, `Fullscreen video waiting in ${orientation}`);
    expectPending(scene);
}

function completeLoop(scene) {
    scene.sample(5.8);
    scene.sample(0);
    scene.sample(0.5);
}

function verifyTwoLoops(scene) {
    completeLoop(scene);
    expectPending(scene);
    completeLoop(scene);
    assert.equal(scene.loopStatus, 'Fullscreen loop playback verified in landscape');
}

test('reporting and lifecycle observations never start, stop, seek, or enter fullscreen', () => {
    const scene = createScene('portrait');
    for (const type of ['loadedmetadata', 'play', 'playing', 'waiting', 'stalled',
        'seeking', 'seeked', 'ended', 'error', 'emptied', 'ratechange']) {
        scene.video.emit(type);
    }
    scene.rotate('landscape');
    verifyTwoLoops(scene);
    scene.media.paused = true;
    scene.video.emit('pause');
    scene.document.emit('visibilitychange');
    scene.exit();
    scene.tick();
    assert.equal(scene.clock.playRequestedEpochMs, null);
    assert.deepEqual(scene.actions, []);
});

test('a frozen zero media clock never reports playing, even with decoded frame callbacks', () => {
    const scene = createScene();
    for (let i = 0; i < 6; i++) {
        scene.sample(0, { frame: i % 2 === 0, milliseconds: 500 });
        expectWaiting(scene);
    }
});

test('an advancing media clock without decoded frames cannot report playing or verified', () => {
    const scene = createScene();
    for (const time of [0.5, 5.8, 0, 0.5, 5.8, 0, 0.5]) {
        scene.sample(time, { frame: false });
        expectWaiting(scene);
    }
});

test('a clock that keeps advancing after decoded frames stop becomes waiting', () => {
    const scene = createScene();
    scene.sample(0.5);
    assert.equal(scene.status, 'Fullscreen video playing in landscape');
    scene.sample(1.8, { frame: false, milliseconds: 1500 });
    expectWaiting(scene);
    scene.sample(3.0, { frame: false, milliseconds: 1200 });
    expectWaiting(scene);
});

test('landscape verification requires two wraps and a new decoded frame after the second wrap', () => {
    const scene = createScene();
    scene.sample(0.5);
    expectPending(scene);
    completeLoop(scene);
    expectPending(scene);
    scene.sample(5.8);
    expectPending(scene);
    scene.sample(0);
    expectWaiting(scene);
    scene.sample(0.5, { frame: false });
    expectPending(scene);
    scene.sample(0.6);
    assert.equal(scene.status, 'Fullscreen video playing in landscape');
    assert.equal(scene.loopStatus, 'Fullscreen loop playback verified in landscape');
});

test('portrait loops and frames do not satisfy the landscape requirement after rotation', () => {
    const scene = createScene('portrait');
    completeLoop(scene);
    completeLoop(scene);
    assert.equal(scene.status, 'Fullscreen video playing in portrait');
    expectPending(scene);
    scene.rotate('landscape');
    expectWaiting(scene);
    scene.sample(0.6);
    assert.equal(scene.status, 'Fullscreen video playing in landscape');
    expectPending(scene);
    verifyTwoLoops(scene);
});

test('backward clock jumps across the midpoint are not completed loops', () => {
    const scene = createScene();
    for (let i = 0; i < 2; i++) {
        scene.sample(4);
        scene.media.seeking = true;
        scene.video.emit('seeking');
        scene.sample(2);
        scene.media.seeking = false;
        scene.video.emit('seeked');
        assert.equal(scene.status, 'Fullscreen video playing in landscape');
        expectPending(scene);
    }
    verifyTwoLoops(scene);
});

test('natural end/start loops remain observable when the media emits seeking events', () => {
    const scene = createScene();
    for (let completed = 1; completed <= 2; completed++) {
        scene.sample(5.8);
        scene.media.seeking = true;
        scene.video.emit('seeking');
        scene.sample(0);
        expectWaiting(scene);
        scene.media.seeking = false;
        scene.video.emit('seeked');
        scene.sample(0.5);
        assert.equal(scene.clock.totalNaturalWraps, completed);
        if (completed < 2) expectPending(scene);
    }
    assert.equal(scene.loopStatus, 'Fullscreen loop playback verified in landscape');
});

test('a freeze at a later loop boundary invalidates a previous successful observation', () => {
    const scene = createScene();
    verifyTwoLoops(scene);
    scene.sample(5.8);
    scene.sample(0, { frame: false });
    expectWaiting(scene);
    scene.tick(1500);
    expectWaiting(scene);
});

test('pausing invalidates playing and verified immediately', () => {
    const scene = createScene();
    verifyTwoLoops(scene);
    scene.media.paused = true;
    scene.video.emit('pause');
    expectWaiting(scene);
    scene.sample(0.6);
    expectWaiting(scene);
});

test('subsequent timer, media, resize, and visibility reports preserve Fullscreen exited', () => {
    const scene = createScene();
    verifyTwoLoops(scene);
    scene.exit();
    assert.equal(scene.status, 'Fullscreen exited');
    expectPending(scene);
    scene.tick();
    scene.sample(1.0);
    scene.rotate('portrait');
    scene.video.emit('pause');
    scene.document.emit('visibilitychange');
    assert.equal(scene.status, 'Fullscreen exited');
    expectPending(scene);
    assert.match(scene.diagnostic, /fullscreen=false/);
});

test('the clock publishes a complete current sample with epoch freshness and observed playing state', () => {
    const scene = createScene('portrait');
    assert.deepEqual(scene.clock, {
        t: 0, duration: 6, rate: 1, playing: false, epochMs: scene.epochMs,
        playRequestedEpochMs: null, totalNaturalWraps: 0, orientation: 'portrait',
    });
    scene.media.playbackRate = 1.25;
    scene.sample(1.125);
    const playingSample = scene.clock;
    assert.equal(playingSample.t, 1.125);
    assert.equal(playingSample.rate, 1.25);
    assert.equal(playingSample.playing, true);
    assert.equal(playingSample.epochMs, scene.epochMs);
    scene.tick(1500);
    assert.equal(scene.clock.t, 1.125);
    assert.equal(scene.clock.epochMs - playingSample.epochMs, 1500);
    assert.equal(scene.clock.playing, false);
    assert.equal(playingSample.playing, true, 'Previously read samples remain immutable snapshots');
    assert.deepEqual(scene.actions, []);
});

test('global wrap tracking observes a boundary during resize and survives orientation changes', () => {
    const scene = createScene('portrait');
    scene.sample(5.8);
    scene.media.currentTime = 0.2;
    scene.rotate('landscape');
    assert.equal(scene.clock.totalNaturalWraps, 1);
    expectPending(scene);
    for (const type of ['playing', 'timeupdate', 'seeked']) scene.video.emit(type);
    scene.window.emit('resize');
    assert.equal(scene.clock.totalNaturalWraps, 1, 'Repeated observations do not invent extra wraps');
    scene.sample(0.5);
    scene.rotate('portrait');
    assert.equal(scene.clock.totalNaturalWraps, 1);
    completeLoop(scene);
    scene.rotate('landscape');
    assert.equal(scene.clock.totalNaturalWraps, 2);
    expectPending(scene);
});

test('the actual first landscape resize must reach the final 0.75 seconds of the first loop', () => {
    for (const [time, nearBoundary] of [[5.249, false], [5.25, true], [5.9, true]]) {
        const scene = createScene('portrait');
        scene.sample(time);
        scene.rotate('landscape');
        assert.equal(scene.rotation.t, time);
        assert.equal(scene.rotation.duration, 6);
        assert.equal(scene.rotation.epochMs, scene.epochMs);
        assert.equal(scene.rotation.frames, 1);
        assert.equal(scene.rotation.stage, '932x430');
        assert.equal(scene.rotation.orientation, 'landscape');
        assert.equal(scene.rotation.source, 'ResizeObserver');
        assert.equal(scene.rotation.totalNaturalWraps, 0);
        assert.equal(scene.rotation.nearBoundary, nearBoundary);
        assert.equal(scene.rotationStatus, nearBoundary
            ? 'Fullscreen first-loop boundary rotation observed'
            : 'Fullscreen rotation missed first-loop boundary');
        assert.deepEqual(scene.actions, []);
    }
});

test('the first wrap qualifies only through the first 0.5 seconds after the boundary', () => {
    for (const [time, nearBoundary] of [[0, true], [0.5, true], [0.501, false]]) {
        const scene = createScene('portrait');
        scene.sample(5.8);
        scene.media.currentTime = time;
        scene.rotate('landscape');
        assert.equal(scene.rotation.t, time);
        assert.equal(scene.rotation.totalNaturalWraps, 1);
        assert.equal(scene.rotation.nearBoundary, nearBoundary);
    }
});

test('the first resize miss and its raw evidence cannot be overwritten by a later qualifying resize', () => {
    const scene = createScene('portrait');
    scene.sample(4.075);
    scene.rotate('landscape');
    const firstResize = scene.rotation;
    assert.equal(firstResize.nearBoundary, false);
    scene.sample(5.8);
    scene.window.emit('resize');
    scene.rotate('portrait');
    scene.rotate('landscape');
    assert.deepEqual(scene.rotation, firstResize);
    assert.equal(scene.rotationStatus, 'Fullscreen rotation missed first-loop boundary');
    assert.equal(scene.clock.t, 5.8, 'The live clock continues after resize evidence is latched');
});

test('rotation near a later loop cannot satisfy the first-loop boundary claim', () => {
    const scene = createScene('portrait');
    completeLoop(scene);
    completeLoop(scene);
    scene.sample(5.8);
    scene.rotate('landscape');
    assert.equal(scene.rotation.totalNaturalWraps, 2);
    assert.equal(scene.rotation.nearBoundary, false);
    assert.equal(scene.rotationStatus, 'Fullscreen rotation missed first-loop boundary');
});

test('rotation evidence requires an earlier fullscreen portrait observation and current fullscreen', () => {
    const scene = createScene();
    scene.sample(5.8);
    scene.window.emit('resize');
    assert.equal(scene.rotation, null);
    scene.rotate('portrait');
    scene.exit();
    scene.rotate('landscape');
    assert.equal(scene.rotation, null);
});

test('only a delivered stage crossing supplies rotation evidence, not window events or polling', () => {
    const scene = createScene('portrait');
    scene.sample(5.8);
    scene.setOrientation('landscape');
    scene.video.emit('timeupdate');
    assert.equal(scene.rotation, null);
    scene.window.emit('resize');
    assert.equal(scene.rotation, null);
    scene.tick(50);
    assert.equal(scene.rotation, null);
    scene.deliverStageResize(25);
    assert.equal(scene.rotation.nearBoundary, true);
    assert.equal(scene.rotation.t, 5.8);
    assert.equal(scene.rotation.source, 'ResizeObserver');
    assert.equal(scene.rotation.epochMs, scene.epochMs);
    assert.equal(scene.rotationStatus, 'Fullscreen first-loop boundary rotation observed');
});

test('a window resize before layout does not latch until the stage actually crosses to landscape', () => {
    const scene = createScene('portrait');
    scene.sample(5.8);
    scene.setDimensions(814, 831);
    scene.sample(0.458);
    const windowEpoch = scene.epochMs;
    scene.window.emit('resize');
    assert.equal(scene.rotation, null);
    assert.equal(scene.clock.orientation, 'portrait');
    scene.setDimensions(814, 348);
    scene.sample(0.476, { milliseconds: 18 });
    assert.equal(scene.rotation, null);
    scene.deliverStageResize();
    assert.equal(scene.rotation.t, 0.476);
    assert.equal(scene.rotation.epochMs - windowEpoch, 18);
    assert.equal(scene.rotation.epochMs, scene.epochMs);
    assert.equal(scene.rotation.stage, '814x348');
    assert.equal(scene.rotation.source, 'ResizeObserver');
    assert.equal(scene.rotation.nearBoundary, true);
    assert.deepEqual(scene.actions, []);
});

test('a qualifying early window event cannot backdate an actual stage crossing outside the window', () => {
    const scene = createScene('portrait');
    scene.sample(5.8);
    scene.sample(0.458);
    const windowEpoch = scene.epochMs;
    scene.window.emit('resize');
    assert.equal(scene.rotation, null);
    scene.setOrientation('landscape');
    scene.sample(0.6, { milliseconds: 142 });
    scene.deliverStageResize();
    const firstCrossing = scene.rotation;
    assert.equal(firstCrossing.t, 0.6);
    assert.equal(firstCrossing.epochMs - windowEpoch, 142);
    assert.equal(firstCrossing.totalNaturalWraps, 1);
    assert.equal(firstCrossing.nearBoundary, false);
    scene.rotate('portrait');
    scene.sample(5.8);
    scene.rotate('landscape');
    assert.deepEqual(scene.rotation, firstCrossing);
    assert.equal(scene.rotationStatus, 'Fullscreen rotation missed first-loop boundary');
});

test('portrait polling cannot invent a portrait ResizeObserver notification before a same-orientation delivery', () => {
    const scene = createScene();
    scene.setOrientation('portrait');
    scene.sample(5.8);
    scene.setOrientation('landscape');
    scene.deliverStageResize();
    assert.equal(scene.rotation, null);
    scene.rotate('portrait');
    scene.rotate('landscape');
    assert.equal(scene.rotation.source, 'ResizeObserver');
    assert.equal(scene.rotation.nearBoundary, true);
});

test('missing ResizeObserver reports unavailability and cannot fall back to window resize proof', () => {
    const scene = createScene('portrait', { resizeObserver: false });
    scene.sample(5.8);
    scene.rotate('landscape');
    scene.sample(5.9);
    scene.window.emit('resize');
    scene.tick();
    assert.equal(scene.rotationStatus, 'Fullscreen boundary observation unavailable: ResizeObserver');
    assert.deepEqual(scene.rotation, { error: 'ResizeObserver unavailable' });
    assert.deepEqual(scene.actions, []);
});

test('only the explicit Enter gesture sets the play anchor, once and before requesting playback', async () => {
    const scene = createScene('portrait');
    const stage = scene.document.fullscreenElement;
    const guardedPlay = scene.video.play;
    const guardedRequestFullscreen = stage.requestFullscreen;
    const calls = [];
    const anchorsAtPlay = [];
    scene.video.play = () => {
        calls.push('explicit play');
        scene.video.emit('play');
        anchorsAtPlay.push(scene.clock.playRequestedEpochMs);
        return Promise.resolve();
    };
    stage.requestFullscreen = () => {
        calls.push('explicit requestFullscreen');
        return Promise.resolve();
    };
    const firstTapAt = scene.epochMs;
    await scene.enter();
    assert.equal(anchorsAtPlay[0], firstTapAt, 'The anchor exists when the user-requested play begins');
    scene.sample(0.5);
    scene.video.emit('playing');
    completeLoop(scene);
    scene.rotate('landscape');
    scene.tick(1500);
    assert.equal(scene.clock.playRequestedEpochMs, firstTapAt);
    assert.equal(scene.rotation.playRequestedEpochMs, firstTapAt);
    await scene.enter();
    assert.deepEqual(anchorsAtPlay, [firstTapAt, firstTapAt]);
    assert.deepEqual(calls, ['explicit play', 'explicit requestFullscreen',
        'explicit play', 'explicit requestFullscreen']);
    scene.video.play = guardedPlay;
    stage.requestFullscreen = guardedRequestFullscreen;
    scene.video.emit('playing');
    scene.window.emit('resize');
    scene.tick();
    assert.equal(scene.clock.playRequestedEpochMs, firstTapAt);
    assert.deepEqual(scene.actions, []);
});
