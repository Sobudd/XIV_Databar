#!/usr/bin/env python3
import re
import sys


def main(argv):
    if len(argv) != 3:
        print("Usage: update_changelog.py <version> <date>", file=sys.stderr)
        return 1

    version, date = argv[1], argv[2]
    notes = ""
    try:
        with open("release-notes.txt", encoding="utf-8") as f:
            notes = f.read().rstrip()
    except FileNotFoundError:
        pass

    with open("CHANGELOG.md", encoding="utf-8") as f:
        content = f.read()

    pattern = rf"(?ms)^## \[{re.escape(version)}\].*?(?=^## \[|\Z)"
    content = re.sub(pattern, "", content)

    header = "# Changelog\n\n"
    rest = content[len(header):].lstrip() if content.startswith(header) else content.lstrip()
    new_section = f"## [{version}] {date}\n\n{notes}\n\n"

    with open("CHANGELOG.md", "w", encoding="utf-8") as f:
        f.write(header + new_section + rest)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
