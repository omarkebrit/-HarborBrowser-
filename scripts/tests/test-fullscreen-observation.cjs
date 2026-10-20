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

function createScene(orientation = 'landscape') {
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
    vm.runInNewContext(scripts[0], {
        document,
        window,
        performance: { now: () => now },
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
        rotate(nextOrientation) {
            dimensions = nextOrientation === 'landscape' ? [932, 430] : [430, 932];
            window.emit('resize');
        },
        exit() {
            fullscreen = false;
            document.emit('fullscreenchange');
        },
    };
    scene.tick();
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
