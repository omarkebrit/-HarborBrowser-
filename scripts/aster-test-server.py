#!/usr/bin/env python3
"""Deterministic, loopback-only fixtures for genuine Aster browser acceptance."""
import html
import http.server
import pathlib
import re
import urllib.parse

ASSETS = pathlib.Path(__file__).resolve().parents[1] / "test-fixtures" / "aster" / "media"
DOWNLOAD = (b"Aster acceptance download\n"
            b"The browser must preserve these exact bytes, including this newline.\n")


def page(title, body, script=""):
    return ("<!doctype html><html lang='en'><head><meta charset='utf-8'>"
            "<meta name='viewport' content='width=device-width,initial-scale=1'>"
            f"<title>{html.escape(title)}</title><style>"
            "body{font:18px system-ui;margin:16px;color:#12323a;background:#fff}"
            "h1{font-size:24px}button,a{display:inline-block;min-height:44px;margin:8px 0}"
            "button{font:inherit;padding:10px 16px}video{max-width:100%;display:block}"
            "iframe{width:100%;height:460px;border:0}p{line-height:1.5}"
            "</style></head><body>"
            f"<h1>{html.escape(title)}</h1>{body}<script>{script}</script></body></html>").encode()


def media_page(title, source="/media/video.mp4", blob=False, autoplay=False):
    body = ("<video id='v' playsinline controls loop preload='auto' width='320'></video>"
            "<button id='play'>Play test media</button>"
            "<p id='status' role='status'>Preparing media</p><p id='diagnostic'></p>")
    script = """
        const v = document.getElementById('v');
        const status = document.getElementById('status');
        const diagnostic = document.getElementById('diagnostic');
        let frames = 0;
        let automaticAttempted = false;
        let automaticOutcome = 'not attempted';
        if (v.requestVideoFrameCallback) {
            const frame = () => { frames++; v.requestVideoFrameCallback(frame); };
            v.requestVideoFrameCallback(frame);
        }
        function report() {
            diagnostic.textContent = 'Frames: ' + frames + ', time: ' + v.currentTime.toFixed(2)
                + ', paused: ' + v.paused + ', readyState: ' + v.readyState
                + ', size: ' + v.videoWidth + 'x' + v.videoHeight
                + ', error: ' + (v.error ? v.error.code : 'none')
                + ', automatic result: ' + automaticOutcome;
            if (!v.paused && !v.muted && v.volume > 0 && v.videoWidth > 0 && v.currentTime > 0.25
                    && (!v.requestVideoFrameCallback || frames > 0))
                status.textContent = 'Audio and video playing';
        }
        v.addEventListener('loadedmetadata', () => {
            if (!automaticAttempted) status.textContent = 'Ready for playback';
            report();
        });
        v.addEventListener('timeupdate', report);
        v.addEventListener('error', () => {
            status.textContent = 'Playback failed: media error ' + v.error.code; report();
        });
        document.getElementById('play').onclick = () => {
            v.muted = false; v.volume = 1;
            v.play().catch(error => { status.textContent = 'Playback failed: ' + error.name; });
        };
        SOURCE
        AUTOPLAY
    """
    automatic = """
        automaticAttempted = true;
        automaticOutcome = 'pending';
        v.muted = false; v.volume = 1;
        status.textContent = 'Attempting automatic playback';
        v.play().then(() => {
            automaticOutcome = 'allowed'; report();
        }).catch(error => {
            automaticOutcome = error.name;
            status.textContent = error.name === 'NotAllowedError'
                ? 'Automatic playback blocked: NotAllowedError'
                : 'Automatic playback failed: ' + error.name;
            report();
        });
    """ if autoplay else ""
    assignment = ("fetch('/media/video.mp4').then(response => {"
                  "if (!response.ok) throw Error('Fetch ' + response.status); return response.blob();"
                  "}).then(blob => { v.src = URL.createObjectURL(blob); })"
                  ".catch(error => { status.textContent = 'Playback failed: ' + error.message; });"
                  if blob else f"v.src = {source!r};")
    return page(title, body, script.replace("AUTOPLAY", automatic).replace("SOURCE", assignment))


ARTICLE_PARAGRAPH = ("A calm browser helps readers follow ideas without distraction. "
                     "This original article is served on the local machine for repeatable testing. "
                     "Bookmarks should return readers to the same article, while reader mode "
                     "keeps the title and meaningful paragraphs available. "
                     "Navigation, private browsing, and accessible controls are part of daily use. ")
PAGES = {
    "/navigation/one.html": page("Aster navigation one", "<p>First local page ready</p>"
        "<a href='/navigation/two.html'>Open second local page</a>"),
    "/navigation/two.html": page("Aster navigation two", "<p>Second local page ready</p>"
        "<p>AsterNeedle first occurrence.</p><p>AsterNeedle second occurrence.</p>"
        "<p>AsterNeedle third occurrence.</p>"),
    "/downloads.html": page("Aster download acceptance", "<a href='/downloads/aster-payload.txt'>"
        "Download Aster fixture</a>"),
    "/media/mp4.html": media_page("Aster MP4 player"),
    "/media/hls.html": media_page("Aster HLS player", "/media/playlist.m3u8"),
    "/media/blob.html": media_page("Aster blob player", blob=True),
    "/media/autoplay.html": media_page("Aster autoplay policy", autoplay=True),
    "/media/iframe.html": page("Aster embedded player", "<iframe title='Aster embedded player' "
        "src='/media/mp4.html' allow='autoplay; fullscreen; picture-in-picture'></iframe>"),
    "/popup.html": page("Aster popup acceptance", "<button id='open'>Open player window</button>"
        "<p>Automatic popup attempted</p>", """
        window.open('/automatic-popup.html', '_blank');
        document.getElementById('open').onclick = () => window.open('/media/mp4.html', '_blank');
    """),
    "/automatic-popup.html": page("Unexpected automatic popup", "<p>Unsolicited popup opened</p>"),
    "/article.html": page("Aster Reading Test Article", "<article><h2>Aster reading acceptance</h2>"
        "<p>Reader keeps the original Aster article text.</p>"
        + "".join(f"<p>{ARTICLE_PARAGRAPH * 3}</p>" for _ in range(12)) + "</article>"),
    "/shields.html": page("Aster shields acceptance", "<p id='allowed'>Allowed script pending</p>"
        "<p id='tracker'>Tracker pending</p>"
        "<script src='/allowed.js'></script>"
        "<script src='http://aster-acceptance.adnxs.com:8766/banner.js' "
        "onerror=\"document.getElementById('tracker').textContent='Tracker blocked'\"></script>"),
    "/media/fullscreen.html": page("Aster fullscreen player", """
        <style>
            #stage{background:#12323a;color:white;padding:12px}
            #stage:fullscreen{box-sizing:border-box;width:100vw;height:100vh;display:flex;
                flex-direction:column;align-items:center;justify-content:center;gap:8px;
                padding:max(12px,env(safe-area-inset-top)) max(20px,env(safe-area-inset-right))
                    max(12px,env(safe-area-inset-bottom)) max(20px,env(safe-area-inset-left))}
            #stage:fullscreen video{width:100%;height:calc(100% - 110px);min-height:0;object-fit:contain}
            #stage:fullscreen p{margin:0;flex:0 0 auto}
            #stage:fullscreen button{min-height:44px;flex:0 0 auto}
        </style>
        <div id='stage'><video id='v' playsinline loop controls preload='auto'
            src='/media/video.mp4' width='320'></video><p id='status'>Waiting for fullscreen</p>
            <button id='exit'>Exit fullscreen</button></div><button id='enter'>Enter fullscreen</button>
    """, """
        const stage = document.getElementById('stage');
        const v = document.getElementById('v');
        const status = document.getElementById('status');
        document.getElementById('enter').onclick = async () => {
            try { v.play(); await stage.requestFullscreen(); }
            catch (error) { status.textContent = 'Fullscreen failed: ' + error.name; }
        };
        document.getElementById('exit').onclick = () => document.exitFullscreen();
        function report() {
            if (document.fullscreenElement && !v.paused && v.videoWidth > 0 && v.currentTime > 0.25)
                status.textContent = 'Fullscreen video playing in '
                    + (stage.clientWidth > stage.clientHeight ? 'landscape' : 'portrait');
        }
        document.addEventListener('fullscreenchange', () => {
            status.textContent = document.fullscreenElement ? 'Fullscreen active' : 'Fullscreen exited';
            report();
        });
        v.addEventListener('timeupdate', report);
        window.addEventListener('resize', report);
    """),
}


def storage_page(mode):
    if mode not in ("regular", "private"):
        return None
    return page(f"Aster {mode} browser state", "<p id='status'>Checking browser storage</p>"
        f"<button id='save'>Save {mode} session</button>", """
        const mode = MODE;
        function report() {
            const cookie = document.cookie.split('; ').find(item => item.startsWith('aster_session='));
            const value = cookie ? cookie.split('=')[1] : '';
            const stored = localStorage.getItem('aster_session');
            document.getElementById('status').textContent = value && value === stored
                ? 'Browser session ' + value + ' with matching storage' : 'No saved browser session';
        }
        document.getElementById('save').onclick = () => {
            document.cookie = 'aster_session=' + mode + '; Path=/; SameSite=Lax';
            localStorage.setItem('aster_session', mode); report();
        };
        report();
    """.replace("MODE", repr(mode)))


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        self.respond(False)

    def do_HEAD(self):
        self.respond(True)

    def respond(self, head_only):
        url = urllib.parse.urlsplit(self.path)
        disposition = None
        if url.path == "/healthz":
            content, mime = b"ready\n", "text/plain"
        elif url.path in PAGES:
            content, mime = PAGES[url.path], "text/html; charset=utf-8"
        elif url.path == "/tab.html":
            number = urllib.parse.parse_qs(url.query).get("number", [""])[0]
            if not number.isdigit() or not 1 <= int(number) <= 100:
                self.send_error(400)
                return
            content, mime = page(f"Aster tab {number}", f"<p>Local tab {number} ready</p>"), "text/html; charset=utf-8"
        elif url.path == "/storage.html":
            mode = urllib.parse.parse_qs(url.query).get("mode", [""])[0]
            content, mime = storage_page(mode), "text/html; charset=utf-8"
            if content is None:
                self.send_error(400)
                return
        elif url.path == "/downloads/aster-payload.txt":
            content, mime = DOWNLOAD, "application/octet-stream"
            disposition = 'attachment; filename="aster-payload.txt"'
        elif url.path == "/allowed.js":
            content, mime = b"document.getElementById('allowed').textContent='Allowed script ran';", "text/javascript"
        elif url.path == "/banner.js":
            content, mime = b"document.getElementById('tracker').textContent='Tracker script ran';", "text/javascript"
        elif re.fullmatch(r"/media/(video\.mp4|playlist\.m3u8|segment\d{2}\.ts)", url.path):
            asset = ASSETS / url.path.rsplit("/", 1)[-1]
            if not asset.is_file():
                self.send_error(404)
                return
            content = asset.read_bytes()
            mime = {".mp4": "video/mp4", ".m3u8": "application/vnd.apple.mpegurl", ".ts": "video/mp2t"}[asset.suffix]
        else:
            self.send_error(404)
            return
        start, end = 0, len(content) - 1
        request = self.headers.get("Range")
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", request or "")
        if request:
            if not match or not any(match.groups()):
                self.range_error(len(content))
                return
            first, last = match.groups()
            if first:
                start = int(first)
                if last:
                    end = min(int(last), end)
            else:
                if not int(last):
                    self.range_error(len(content))
                    return
                start = max(0, len(content) - int(last))
            if start > end or start >= len(content):
                self.range_error(len(content))
                return
        self.send_response(206 if request else 200)
        for key, value in [("Content-Type", mime), ("Accept-Ranges", "bytes"),
                           ("Access-Control-Allow-Origin", "*"), ("Cache-Control", "no-store"),
                           ("Content-Length", str(end - start + 1))]:
            self.send_header(key, value)
        if request:
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(content)}")
        if disposition:
            self.send_header("Content-Disposition", disposition)
        self.end_headers()
        if not head_only:
            try:
                self.wfile.write(content[start:end + 1])
            except (BrokenPipeError, ConnectionResetError):
                pass

    def range_error(self, length):
        self.send_response(416)
        self.send_header("Content-Range", f"bytes */{length}")
        self.send_header("Content-Length", "0")
        self.end_headers()


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", 8766), Handler).serve_forever()
