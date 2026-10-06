#!/usr/bin/env python3
"""Local-only HTTP/Range fixture for iOS streaming regression tests."""
import base64, http.server, pathlib, re
VIDEO = base64.b64decode((pathlib.Path(__file__).resolve().parents[1] / 'HarborTests/video.b64').read_text())
PAGE = b"<html><head><title>Network Video Fixture</title><meta name='viewport' content='width=device-width'></head><body><video id='v' playsinline muted controls src='/video.mp4'></video></body></html>"
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        content, mime = (VIDEO, 'video/mp4') if self.path == '/video.mp4' else (PAGE, 'text/html')
        start, end = 0, len(content)-1
        request = self.headers.get('Range', '')
        match = re.fullmatch(r'bytes=(\d+)-(\d*)', request)
        if match:
            start = int(match[1]); end = min(int(match[2]) if match[2] else end, end)
            if start > end:
                self.send_response(416); self.end_headers(); return
        self.send_response(206 if match else 200)
        self.send_header('Content-Type', mime)
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Access-Control-Allow-Origin', '*')
        if match: self.send_header('Content-Range', f'bytes {start}-{end}/{len(content)}')
        self.send_header('Content-Length', str(end-start+1))
        self.end_headers(); self.wfile.write(content[start:end+1])
http.server.ThreadingHTTPServer(('127.0.0.1', 8765), Handler).serve_forever()
