#!/usr/bin/env python3
"""Capture state from the controlled simulator regression run, before profile reset."""

import json
from pathlib import Path
import shutil
import subprocess
import sys


def container_path(stdout):
    """Accept a direct path or simctl's app-group identifier/path mapping."""
    candidates = [stdout.strip()]
    try:
        decoded = json.loads(stdout)
        if isinstance(decoded, str):
            candidates.append(decoded)
        elif isinstance(decoded, dict):
            candidates.extend(value for value in decoded.values() if isinstance(value, str))
    except json.JSONDecodeError:
        pass
    for line in stdout.splitlines():
        for separator in (" = ", ": "):
            if separator in line:
                candidates.append(line.split(separator, 1)[1].strip().strip('";'))
    return next((Path(value) for value in candidates if Path(value).is_dir()), None)


def collect(device, output):
    output.mkdir(parents=True, exist_ok=True)
    metadata = {}
    for kind, container_type in (("app", "data"), ("shared", "group.com.omarkebrit.aster")):
        result = subprocess.run(
            ["xcrun", "simctl", "get_app_container", device, "com.omarkebrit.aster", container_type],
            text=True, capture_output=True, check=False,
        )
        metadata[kind] = {"returncode": result.returncode, "stderr": result.stderr.strip(),
                          "stdout": result.stdout.strip()}
        if result.returncode:
            continue
        root = container_path(result.stdout)
        if root is None:
            metadata[kind]["error"] = "Container path is unavailable"
            continue
        profiles = ["profile.profile", "profile.testProfile"]
        prefix = "Documents/" if kind == "app" else ""
        paths = [f"{prefix}{profile}/{name}" for profile in profiles
                 for name in ("window-data", "window-data-backup")]
        if kind == "app":
            paths.extend(["Library/Caches/Logs", "Library/Preferences/com.omarkebrit.aster.plist"])
        for relative in paths:
            source = root / relative
            destination = output / kind / relative
            if source.is_dir():
                shutil.copytree(source, destination, dirs_exist_ok=True)
            elif source.is_file():
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
        if kind == "shared":
            metadata[kind]["sessionFiles"] = {
                profile: [{"name": path.name, "bytes": path.stat().st_size}
                          for path in sorted((root / profile / "tab-session-data").glob("*"))
                          if path.is_file()]
                for profile in profiles
            }
    (output / "container-status.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: aster-collect-session-evidence.py SIMULATOR_UDID OUTPUT_DIRECTORY")
    collect(sys.argv[1], Path(sys.argv[2]))
