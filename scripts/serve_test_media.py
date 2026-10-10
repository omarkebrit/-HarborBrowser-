#!/usr/bin/env python3
"""Local-only genuine MP4, HLS, iframe, blob, and popup playback fixtures."""
import base64
import html
import http.server
import pathlib
import re
import urllib.parse

TESTS = pathlib.Path(__file__).resolve().parents[1] / "HarborTests"
VIDEO = base64.b64decode((TESTS / "video.b64").read_text())


def page(title, body, script=""):
    return (f"<!doctype html><html><head><title>{title}</title>"
            "<meta name='viewport' content='width=device-width,initial-scale=1'>"
            "</head><body>" + f"<h1>{title}</h1>{body}<script>{script}</script>"
            "</body></html>").encode()


def video(source="/video.mp4", muted=True):
    return ("<video id='v' playsinline controls preload='auto' "
            f"{'muted' if muted else ''} src='{source}' width='320'></video>")


PAGES = {
    "/video.html": page("Network Video Fixture", video()),
    "/iframe.html": page("Embedded Video Fixture", "<iframe id='player' src='/video.html' width='350' height='280' allow='autoplay; fullscreen; picture-in-picture'></iframe>"),
    "/blob.html": page("Blob Video Fixture", "<video id='v' playsinline muted controls width='320'></video>", """
        fetch('/video.mp4').then(response => {
            if (!response.ok) throw new Error('MP4 fetch: ' + response.status);
            return response.blob();
        }).then(blob => { document.getElementById('v').src = URL.createObjectURL(blob); })
          .catch(error => { window.fixtureError = String(error); });
    """),
    "/hls.html": page("HLS Video Fixture", video("/hls/playlist.m3u8")),
    "/audio.html": page("Audio Gesture Fixture", video(muted=False) + "<button id='play'>Play with sound</button><p id='playback-status'>Waiting for play</p>", """
        const v = document.getElementById('v');
        const status = document.getElementById('playback-status');
        document.getElementById('play').onclick = () => {
            v.muted = false;
            v.volume = 1;
            v.play().catch(error => { status.textContent = 'Playback failed: ' + error.name; });
        };
        v.addEventListener('timeupdate', () => {
            if (!v.paused && !v.muted && v.volume > 0 && v.currentTime > 0.25)
                status.textContent = 'Playing with sound';
        });
    """),
    "/popup.html": page("Video Popup Fixture", "<button id='open'>Open video tab</button><p>Automatic popup attempted</p>", """
        window.open('/automatic-popup.html', '_blank');
        document.getElementById('open').onclick = () => window.open('/video.html', '_blank');
    """),
    "/automatic-popup.html": page("Unexpected Automatic Popup", "<p>This unsolicited popup should be blocked.</p>"),
    "/fullscreen.html": page("Fullscreen Video Fixture", """
        <style>
            #stage { background: #12323a; color: white; padding: 12px; }
            #stage video { display: block; }
            #stage:fullscreen {
                box-sizing: border-box; width: 100vw; height: 100vh;
                display: flex; flex-direction: column; align-items: center;
                justify-content: center; gap: 8px;
                padding: max(12px, env(safe-area-inset-top)) max(20px, env(safe-area-inset-right)) max(12px, env(safe-area-inset-bottom)) max(20px, env(safe-area-inset-left));
            }
            #stage:fullscreen video { width: 100%; height: calc(100% - 100px); min-height: 0; object-fit: contain; }
            #stage:fullscreen p { margin: 0; flex: 0 0 auto; }
            #stage:fullscreen button { min-height: 44px; flex: 0 0 auto; }
        </style>
        <div id='stage'><video id='v' playsinline muted loop controls preload='auto' src='/video.mp4' width='320'></video>
        <p id='fullscreen-status'>Waiting for fullscreen</p><button id='exit'>Exit fullscreen</button></div><button id='enter'>Enter fullscreen</button>
    """, """
        const stage = document.getElementById('stage');
        const v = document.getElementById('v');
        const status = document.getElementById('fullscreen-status');
        document.getElementById('enter').onclick = async () => {
            try {
                v.play();
                await stage.requestFullscreen();
            } catch (error) { status.textContent = 'Fullscreen failed: ' + error.name; }
        };
        document.getElementById('exit').onclick = () => document.exitFullscreen();
        function reportPlayback() {
            if (document.fullscreenElement && !v.paused && v.currentTime > 0.25) {
                const orientation = stage.clientWidth > stage.clientHeight ? 'landscape' : 'portrait';
                status.textContent = 'Fullscreen video playing in ' + orientation;
            }
        }
        document.addEventListener('fullscreenchange', () => {
            status.textContent = document.fullscreenElement ? 'Fullscreen active' : 'Fullscreen exited';
            reportPlayback();
        });
        v.addEventListener('timeupdate', reportPlayback);
        window.addEventListener('resize', reportPlayback);
    """),
}


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_HEAD(self):
        self.respond(head_only=True)

    def do_GET(self):
        self.respond(head_only=False)

    def do_POST(self):
        if urllib.parse.urlsplit(self.path).path != "/submitted.html":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error(400)
            return
        if not 0 < length <= 64_000:
            self.send_error(400)
            return
        submission = self.rfile.read(length).decode("utf-8", errors="replace")
        content = page("Submitted Video Fixture", video() + "<p id='submission'>" + html.escape(submission) + "</p>")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def respond(self, head_only):
        path = urllib.parse.urlsplit(self.path).path
        if path == "/healthz":
            content, mime = b"ready\n", "text/plain"
        elif path == "/video.mp4":
            content, mime = VIDEO, "video/mp4"
        elif path in PAGES:
            content, mime = PAGES[path], "text/html; charset=utf-8"
        elif re.fullmatch(r"/hls/(playlist\.m3u8|segment\d{2}\.ts)", path):
            asset = TESTS / "Media" / path.rsplit("/", 1)[-1]
            if not asset.is_file():
                self.send_error(404)
                return
            content = asset.read_bytes()
            mime = "application/vnd.apple.mpegurl" if asset.suffix == ".m3u8" else "video/mp2t"
        else:
            self.send_error(404)
            return

        start, end = 0, len(content) - 1
        request = self.headers.get("Range")
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", request or "")
        partial = False
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
                suffix_length = int(last)
                if not suffix_length:
                    self.range_error(len(content))
                    return
                start = max(0, len(content) - suffix_length)
            if start > end or start >= len(content):
                self.range_error(len(content))
                return
            partial = True

        self.send_response(206 if partial else 200)
        self.send_header("Content-Type", mime)
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        if partial:
            self.send_header("Content-Range", f"bytes {start}-{end}/{len(content)}")
        self.send_header("Content-Length", str(end - start + 1))
        self.end_headers()
        if not head_only:
            try:
                self.wfile.write(content[start:end + 1])
            except (BrokenPipeError, ConnectionResetError):
                pass  # WebKit may cancel a speculative range while seeking.

    def range_error(self, length):
        self.send_response(416)
        self.send_header("Content-Range", f"bytes */{length}")
        self.send_header("Content-Length", "0")
        self.end_headers()


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
