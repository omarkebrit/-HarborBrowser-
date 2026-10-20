#!/usr/bin/env python3
"""Generate Aster's bundled Help and Privacy pages."""

import argparse
import html
from html.parser import HTMLParser
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "firefox-ios/Client/Assets/AsterSupport"
LINK = re.compile(r"\[([^\]\n]+)\]\((https?://[^\s)]+)\)")

CSS = """
:root {
  color-scheme: light dark;
  --background: #eef3f5;
  --paper: #ffffff;
  --text: #193440;
  --muted: #48616d;
  --accent: #006b60;
  --border: #cbdce2;
}
* { box-sizing: border-box; }
html { font-size: 100%; }
body {
  margin: 0;
  padding: max(1.25rem, env(safe-area-inset-top))
           max(1rem, env(safe-area-inset-right))
           max(2rem, env(safe-area-inset-bottom))
           max(1rem, env(safe-area-inset-left));
  background: var(--background);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-size: 1rem;
  line-height: 1.7;
  overflow-wrap: anywhere;
}
main {
  width: 100%;
  max-width: 45rem;
  margin: 0 auto;
  padding: clamp(1.25rem, 5vw, 3rem);
  background: var(--paper);
  border: 1px solid var(--border);
  border-radius: 1.25rem;
}
h1, h2, h3 { line-height: 1.25; letter-spacing: -.015em; }
h1 { margin: 0 0 1.25rem; font-size: 2rem; }
h2 {
  margin: 2rem 0 .75rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--border);
  font-size: 1.3rem;
}
p { margin: 0 0 1rem; }
p:last-child { margin-bottom: 0; }
a { color: var(--accent); text-decoration: underline; text-underline-offset: .2em; }
a:focus-visible { outline: 3px solid var(--accent); outline-offset: 4px; border-radius: .2rem; }
.intro { color: var(--muted); font-size: 1.1rem; }
.action {
  display: inline-block;
  min-height: 44px;
  padding: .6rem 1rem;
  border: 1px solid var(--accent);
  border-radius: .65rem;
  font-weight: 600;
}
@media (prefers-color-scheme: dark) {
  :root {
    --background: #10232d;
    --paper: #17313e;
    --text: #e7f1f5;
    --muted: #bed2dc;
    --accent: #8bdfcb;
    --border: #3b5664;
  }
}
"""


def inline(markdown):
    rendered = []
    position = 0
    for match in LINK.finditer(markdown):
        rendered.append(html.escape(markdown[position:match.start()]))
        label, url = match.groups()
        rendered.append(
            f'<a href="{html.escape(url, quote=True)}" rel="noreferrer noopener">'
            f"{html.escape(label)}</a>"
        )
        position = match.end()
    rendered.append(html.escape(markdown[position:]))
    return "".join(rendered)


def markdown_blocks(markdown):
    blocks = []
    paragraph = []

    def finish_paragraph():
        if paragraph:
            blocks.append(("p", "\n".join(paragraph)))
            paragraph.clear()

    for line in markdown.splitlines():
        if not line.strip():
            finish_paragraph()
            continue
        heading = re.fullmatch(r"(#{1,6}) (.+)", line)
        if heading:
            finish_paragraph()
            blocks.append((f"h{len(heading.group(1))}", heading.group(2)))
        else:
            paragraph.append(line)
    finish_paragraph()
    return blocks


def document(title, content):
    return (
        "<!doctype html>\n"
        '<html lang="en">\n<head>\n'
        '  <meta charset="utf-8">\n'
        '  <meta name="viewport" content="width=device-width, initial-scale=1">\n'
        '  <meta http-equiv="Content-Security-Policy" '
        'content="default-src \'none\'; style-src \'unsafe-inline\'; '
        'base-uri \'none\'; form-action \'none\'">\n'
        f"  <title>{html.escape(title)}</title>\n"
        f"  <style>{CSS}</style>\n"
        "</head>\n<body>\n<main>\n<article>\n"
        f"{content}\n"
        "</article>\n</main>\n</body>\n</html>\n"
    )


class VisibleBlocks(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.blocks = []
        self.current_tag = None
        self.current_text = []

    def handle_starttag(self, tag, attrs):
        if tag in {"p", "h1", "h2", "h3", "h4", "h5", "h6"}:
            self.current_tag = tag
            self.current_text = []

    def handle_data(self, data):
        if self.current_tag:
            self.current_text.append(data)

    def handle_endtag(self, tag):
        if tag == self.current_tag:
            self.blocks.append((tag, "".join(self.current_text)))
            self.current_tag = None


def privacy_page(markdown):
    blocks = markdown_blocks(markdown)
    if not blocks or blocks[0][0] != "h1":
        raise ValueError("PRIVACY.md must start with a level-one heading.")
    content = "\n".join(f"<{tag}>{inline(text)}</{tag}>" for tag, text in blocks)
    rendered = document(blocks[0][1], content)
    visible = VisibleBlocks()
    visible.feed(rendered)
    expected = [(tag, LINK.sub(lambda match: match.group(1), text)) for tag, text in blocks]
    if visible.blocks != expected:
        raise ValueError("Rendered Privacy content differs from PRIVACY.md.")
    return rendered


def help_page():
    content = """
<h1>Aster Help</h1>
<p class="intro">Aster is an independent browser built from Firefox for iOS. It is not operated by Mozilla or Brave. This Help page is stored on your device and can be read offline.</p>

<h2>Browse and navigate</h2>
<p>Enter a website address or search in the address bar. Use Back and Forward to move between pages you have visited. Open the browser menu for bookmarks, history, Downloads, Settings, and other available tools.</p>

<h2>Tabs and private browsing</h2>
<p>Open the tab tray to switch between pages or close a tab. Choose Tabs or Private, then tap + to add a tab in the selected mode.</p>
<p>Private tabs use separate temporary website storage. They do not hide your IP address from websites or your network, and they do not remove files you download or export.</p>

<h2>Downloads</h2>
<p>Open Downloads from the browser menu to find downloaded files. Tap a completed download to open it, or swipe for Share or Delete. Delete removes the downloaded file. Files you export or share can remain outside Aster; remove those copies separately when you no longer need them.</p>

<h2>Reader View</h2>
<p>Reader View simplifies supported articles for reading. On a readable article, use the reader control in the address bar. Its control is available only when a page can be shown in Reader View; some pages do not support it.</p>

<h2>Protection and site exceptions</h2>
<p>Aster uses tracking protection and bundled advertising rules to block matching requests. Open Settings, then Browsing, then Ad Blocker for advertising protection. Use Protections for the current site, or Settings, then Tracking Protection for tracking protection settings. A site exception reduces protection on that site; if a page stops working, review its exception and reload the page.</p>
<p>Blocking cannot catch every tracker or advertisement. Allowed website resources, search, suggestions, and other browser functions can still make network requests.</p>

<h2>Settings and privacy</h2>
<p>Open Settings from the browser menu to manage available search, appearance, browsing, site data, and privacy controls. Device permissions for the camera, microphone, location, and photos are also controlled by iOS.</p>
<p>Use Settings, then Data Management to choose which stored data to clear. Clear Private Data applies the choices shown on that page.</p>
<p>Technical collection, crash reports, daily usage, remote studies, and rollouts are off by default. These optional choices are separate. Find Privacy Notice in Settings for the full privacy information.</p>

<h2>Independent app and service limits</h2>
<p>Aster is independently maintained. Available features depend on the page, device, and build. Inherited service code may contact its configured providers; Aster has no dedicated analytics or account server. Firefox Account integration has not been certified end to end for Aster.</p>
<p>Installation and updates follow the project's build instructions. Physical-device checks and a complete service and network audit are still outstanding.</p>

<h2>Feedback and help with a problem</h2>
<p>Send Feedback opens GitHub. Submitting an issue requires a GitHub account and access to the repository; issue availability depends on the repository's permissions and settings. If access is unavailable, contact the person who provided your build.</p>
<p>Opening this page or the feedback link sends no report automatically. Aster does not attach your history, screenshots, or logs automatically. Before you submit an issue, review screenshots, website addresses, and logs for private information. GitHub's policies and the repository's visibility govern anything you submit.</p>
<p><a class="action" href="https://github.com/omarkebrit/-HarborBrowser-/issues" rel="noreferrer noopener">Open project feedback on GitHub</a></p>
""".strip()
    return document("Aster Help", content)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if bundled pages are missing or stale.")
    args = parser.parse_args()
    privacy = (ROOT / "PRIVACY.md").read_text(encoding="utf-8")
    pages = {"help.html": help_page(), "privacy.html": privacy_page(privacy)}
    stale = [
        name for name, content in pages.items()
        if not (OUTPUT / name).is_file() or (OUTPUT / name).read_bytes() != content.encode("utf-8")
    ]
    if args.check:
        if stale:
            print("Stale bundled support pages: " + ", ".join(stale), file=sys.stderr)
            print("Run python3 scripts/aster-generate-support.py to refresh them.", file=sys.stderr)
            return 1
        print("Bundled Help and Privacy pages are current; Privacy content matches PRIVACY.md.")
        return 0
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name in stale:
        (OUTPUT / name).write_bytes(pages[name].encode("utf-8"))
    print("Generated bundled support pages." if stale else "Bundled support pages are already current.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
