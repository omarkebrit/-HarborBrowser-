#!/usr/bin/env python3
"""Copy readable native evidence while retaining full XCResults separately."""

import hashlib
import json
from pathlib import Path
import shutil
import sys


def compact(source, destination):
    source, destination = source.resolve(), destination.resolve()
    if not source.is_dir() or source == destination or source in destination.parents:
        sys.exit('Separate existing source and output directories are required.')
    if destination.exists():
        sys.exit('The output directory must not already exist.')
    allowed = {'.json', '.txt', '.log', '.plist', '.ips', '.crash', '.png', '.jpg', '.jpeg'}
    selected = [path for path in sorted(source.rglob('*'))
                if path.is_file() and not path.is_symlink()
                and path.suffix.lower() in allowed
                and not any(part.endswith('.xcresult') for part in path.relative_to(source).parts)]
    total = sum(path.stat().st_size for path in selected)
    if not selected or total > 450 * 1024 * 1024:
        sys.exit(f'Compact evidence must contain files and remain below 450 MiB; found {total} bytes.')
    manifest = []
    for path in selected:
        relative = path.relative_to(source)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
            sys.exit(f'Copied evidence hash mismatch: {relative}')
        manifest.append({'path': relative.as_posix(), 'bytes': path.stat().st_size, 'sha256': digest})
    (destination / 'compact-manifest.json').write_text(json.dumps({
        'scope': 'Exact copies of readable evidence and still images; videos and full XCResults remain in the original artifact.',
        'totalBytes': total, 'files': manifest,
    }, indent=2) + '\n')
    print(f'Copied {len(manifest)} unchanged evidence files ({total} bytes).')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('Usage: aster-compact-evidence.py SOURCE OUTPUT')
    compact(Path(sys.argv[1]), Path(sys.argv[2]))
