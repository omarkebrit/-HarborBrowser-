#!/usr/bin/env python3
"""Capture state from the controlled simulator regression run, before profile reset."""

import json
from pathlib import Path
import shutil
import subprocess
import sys


def collect(device, output):
    output.mkdir(parents=True, exist_ok=True)
    metadata = {}
    for kind, container_type in (("app", "data"), ("shared", "group.com.omarkebrit.aster")):
        result = subprocess.run(
            ["xcrun", "simctl", "get_app_container", device, "com.omarkebrit.aster", container_type],
            text=True, capture_output=True, check=False,
        )
        metadata[kind] = {"returncode": result.returncode, "stderr": result.stderr.strip()}
        if result.returncode:
            continue
        root = Path(result.stdout.strip())
        if not root.is_dir():
            metadata[kind]["error"] = "Container path is unavailable"
            continue
        paths = (["Library/Caches/Logs", "Library/Preferences/com.omarkebrit.aster.plist",
                  "Documents/profile.profile/window-data", "Documents/profile.profile/window-data-backup"]
                 if kind == "app" else ["profile.profile/window-data", "profile.profile/window-data-backup"])
        for relative in paths:
            source = root / relative
            destination = output / kind / relative
            if source.is_dir():
                shutil.copytree(source, destination, dirs_exist_ok=True)
            elif source.is_file():
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
        if kind == "shared":
            sessions = root / "profile.profile/tab-session-data"
            metadata[kind]["sessionFiles"] = [
                {"name": path.name, "bytes": path.stat().st_size}
                for path in sorted(sessions.glob("*")) if path.is_file()
            ]
    (output / "container-status.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: aster-collect-session-evidence.py SIMULATOR_UDID OUTPUT_DIRECTORY")
    collect(sys.argv[1], Path(sys.argv[2]))
