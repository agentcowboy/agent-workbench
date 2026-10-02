#!/usr/bin/env python3
"""Check present text anchors, not instruction loading or agent behaviour."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys


HERE = Path(__file__).resolve().parent
HANDLE = re.compile(r"^### ([a-z0-9][a-z0-9-]*)$", re.MULTILINE)
PROVENANCE = {"active-rule", "active-skill", "cold-incident"}


def anchor_matches(anchor, root):
    if not isinstance(anchor, dict):
        return False
    name, pattern = anchor.get("file"), anchor.get("pattern")
    if (not isinstance(name, str) or not name
            or not isinstance(pattern, str) or not pattern
            or not isinstance(anchor.get("provenance"), str)
            or anchor["provenance"] not in PROVENANCE):
        return False
    try:
        return pattern in (root / name).read_text(encoding="utf-8")
    except (OSError, UnicodeError, ValueError):
        return False


def check(manifest_path, corpus_path):
    try:
        protections = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(protections, list) or not protections:
            raise ValueError("manifest must be a nonempty JSON array")
        handles = []
        for protection in protections:
            handle = protection.get("handle") if isinstance(protection, dict) else None
            if not isinstance(handle, str) or not HANDLE.fullmatch("### " + handle):
                raise ValueError("manifest protection has an invalid handle")
            handles.append(handle)
        corpus_handles = HANDLE.findall(corpus_path.read_text(encoding="utf-8"))
        if not corpus_handles:
            raise ValueError("corpus has no protection handles")
    except (OSError, UnicodeError, ValueError) as error:
        print(f"INPUT ERROR: {error}", file=sys.stderr)
        return 2

    errors = []
    for label, items in (("manifest", handles), ("corpus", corpus_handles)):
        duplicates = sorted(item for item, count in Counter(items).items() if count > 1)
        if duplicates:
            errors.append(f"duplicate {label} handles: {', '.join(duplicates)}")
    for label, missing in (("corpus-only", set(corpus_handles) - set(handles)),
                           ("manifest-only", set(handles) - set(corpus_handles))):
        if missing:
            errors.append(f"{label} handles: {', '.join(sorted(missing))}")
    if errors:
        for error in errors:
            print(f"BIJECTION ERROR: {error}", file=sys.stderr)
        return 1

    orphaned = []
    for protection in protections:
        anchors = protection.get("anchors")
        present = isinstance(anchors, list) and any(
            anchor_matches(anchor, manifest_path.resolve().parent) for anchor in anchors
        )
        handle = protection["handle"]
        print(f"{'PASS' if present else 'ORPHAN'} {handle}")
        if not present:
            orphaned.append(handle)
    print(f"{len(protections) - len(orphaned)}/{len(protections)} protections have >=1 present text anchor")
    if orphaned:
        print("Orphaned: " + ", ".join(orphaned), file=sys.stderr)
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=HERE / "protection-coverage-manifest.json")
    parser.add_argument("--corpus", type=Path, default=HERE / "protection-corpus.md")
    args = parser.parse_args()
    return check(args.manifest, args.corpus)


if __name__ == "__main__":
    sys.exit(main())
