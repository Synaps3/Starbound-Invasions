#!/usr/bin/env python3
"""Validate that every JSON asset in the repository parses as strict JSON.

Starbound loads these files via root.assetJson, so a stray comma or brace here
breaks the mod at load time with no obvious error. This catches that in CI.

Checked files: `.json`, `.config`, `.patch`, and the `_metadata` mod manifest.
"""

import json
import os
import sys

# File names / extensions that hold JSON content in a Starbound mod.
JSON_EXTENSIONS = (".json", ".config", ".patch")
JSON_FILENAMES = ("_metadata",)

SKIP_DIRS = {".git"}


def json_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name in JSON_FILENAMES or name.endswith(JSON_EXTENSIONS):
                yield os.path.join(dirpath, name)


def main():
    root = os.getcwd()
    failures = []
    checked = 0

    for path in sorted(json_files(root)):
        rel = os.path.relpath(path, root)
        checked += 1
        try:
            with open(path, "r", encoding="utf-8") as handle:
                json.load(handle)
            print(f"OK   {rel}")
        except (ValueError, OSError) as exc:
            print(f"FAIL {rel}: {exc}")
            failures.append(rel)

    if checked == 0:
        print("No JSON files found.")

    if failures:
        print(f"\n{len(failures)} file(s) failed JSON validation.")
        return 1

    print(f"\nAll {checked} JSON file(s) are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
