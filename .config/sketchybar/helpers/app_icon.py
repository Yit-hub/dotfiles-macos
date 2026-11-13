#!/usr/bin/env python3
"""Resolve macOS application names to sketchybar-app-font glyphs.

The mapping is read directly from the installed font's `meta` table (`APPM` data
map).  That way the lookup always matches the font version in use and never goes
stale, unlike the legacy generated `icon_map.sh` / `icon_map.lua` helpers.

Usage:
    app_icon.py [--font PATH] APP [APP ...]
    app_icon.py --release
    app_icon.py --clear-cache

Each app name prints one glyph on its own line.  Unknown apps resolve to the
font's `:default:` glyph.  If the font is missing or invalid, a line with no
glyph is still printed for every app so callers can keep their alignment.
"""

import json
import os
import struct
import sys

SCHEMA = 1
CACHE_DIR = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
CACHE_PATH = os.path.join(CACHE_DIR, "sketchybar", "app-icons.json")

FONT_CANDIDATES = [
    os.environ.get("SKETCHYBAR_APP_FONT"),
    os.path.expanduser("~/Library/Fonts/sketchybar-app-font.ttf"),
    "/Library/Fonts/sketchybar-app-font.ttf",
]

DEFAULT_LIGATURE = ":default:"


def find_font():
    for path in FONT_CANDIDATES:
        if path and os.path.isfile(path):
            return path
    return None


def read_tables(buf):
    """Return {tag: (offset, length)} for a TrueType/OpenType file."""
    if len(buf) < 12:
        raise ValueError("file is too small to be a font")

    num_tables = struct.unpack_from(">H", buf, 4)[0]
    tables = {}
    for i in range(num_tables):
        record = 12 + i * 16
        if record + 16 > len(buf):
            raise ValueError("truncated font table directory")
        tag = buf[record : record + 4].decode("latin1")
        offset, length = struct.unpack_from(">II", buf, record + 8)
        if offset + length > len(buf):
            raise ValueError("table %r extends past end of file" % tag)
        tables[tag] = (offset, length)
    return tables


def read_app_map(font_path):
    """Extract and parse the APPM data map from the font's meta table."""
    with open(font_path, "rb") as handle:
        buf = handle.read()

    tables = read_tables(buf)
    if "meta" not in tables:
        raise ValueError(
            "font has no meta table; install sketchybar-app-font 2.0.0 or newer"
        )

    meta_offset, _meta_length = tables["meta"]
    try:
        _version, _flags, _reserved, count = struct.unpack_from(
            ">IIII", buf, meta_offset
        )
    except struct.error:
        raise ValueError("font meta table is truncated")

    for i in range(count):
        record = meta_offset + 16 + i * 12
        if record + 12 > len(buf):
            raise ValueError("truncated font meta data map")
        tag = buf[record : record + 4]
        if tag != b"APPM":
            continue

        data_offset, data_length = struct.unpack_from(">II", buf, record + 4)
        start = meta_offset + data_offset
        end = start + data_length
        if end > len(buf):
            raise ValueError("APPM data extends past end of file")
        payload = json.loads(buf[start:end].decode("utf-8"))
        if payload.get("version") != SCHEMA:
            raise ValueError(
                "unsupported APPM schema version %r" % payload.get("version")
            )
        return payload

    raise ValueError("font has no APPM data map")


def build_lookup(payload):
    exact = {}
    prefixes = []
    ligatures = {}

    for ligature, codepoint, names in payload.get("icons", []):
        glyph = chr(codepoint)
        ligatures[ligature] = glyph
        for name in names or []:
            if name.endswith("*"):
                prefix = name[:-1]
                if prefix:
                    prefixes.append([prefix, glyph])
            else:
                exact[name] = glyph

    # Longest prefix wins, matching the most specific mapping.
    prefixes.sort(key=lambda item: len(item[0]), reverse=True)

    return {
        "release": payload.get("release"),
        "exact": exact,
        "prefixes": prefixes,
        "default": ligatures.get(DEFAULT_LIGATURE, ""),
    }


def font_signature(font_path):
    stat = os.stat(font_path)
    return {
        "path": os.path.abspath(font_path),
        "mtime_ns": stat.st_mtime_ns,
        "size": stat.st_size,
    }


def load_lookup(font_path, use_cache=True):
    signature = font_signature(font_path)

    if use_cache:
        try:
            with open(CACHE_PATH, "r", encoding="utf-8") as handle:
                cache = json.load(handle)
            if cache.get("schema") == SCHEMA and cache.get("font") == signature:
                return cache["lookup"]
        except (OSError, ValueError, KeyError):
            pass

    lookup = build_lookup(read_app_map(font_path))

    if use_cache:
        try:
            os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
            temp_path = CACHE_PATH + ".tmp"
            with open(temp_path, "w", encoding="utf-8") as handle:
                json.dump(
                    {"schema": SCHEMA, "font": signature, "lookup": lookup},
                    handle,
                    ensure_ascii=False,
                    separators=(",", ":"),
                )
            os.replace(temp_path, CACHE_PATH)
        except OSError:
            pass  # caching is an optimisation only

    return lookup


def resolve(lookup, app_name):
    if app_name in lookup["exact"]:
        return lookup["exact"][app_name]

    for prefix, glyph in lookup["prefixes"]:
        if app_name.startswith(prefix):
            return glyph

    return lookup["default"]


def clear_cache():
    try:
        os.remove(CACHE_PATH)
        return True
    except FileNotFoundError:
        return False


def usage(stream=sys.stdout):
    stream.write(__doc__ or "")


def main(argv):
    font_path = None
    as_json = False
    use_cache = True
    action = "lookup"
    apps = []

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--font":
            i += 1
            if i >= len(argv):
                sys.stderr.write("app_icon.py: --font needs a path\n")
                return 2
            font_path = argv[i]
        elif arg == "--release":
            action = "release"
        elif arg == "--clear-cache":
            action = "clear-cache"
        elif arg == "--no-cache":
            use_cache = False
        elif arg == "--json":
            as_json = True
        elif arg in ("-h", "--help"):
            usage()
            return 0
        elif arg == "--":
            apps.extend(argv[i + 1 :])
            break
        elif arg.startswith("-") and arg != "-":
            sys.stderr.write("app_icon.py: unknown option %s\n" % arg)
            return 2
        else:
            apps.append(arg)
        i += 1

    if action == "clear-cache":
        clear_cache()
        return 0

    if action == "release":
        font_path = font_path or find_font()
        if not font_path:
            sys.stderr.write("app_icon.py: sketchybar-app-font is not installed\n")
            return 1
        try:
            payload = read_app_map(font_path)
        except (OSError, ValueError) as error:
            sys.stderr.write("app_icon.py: %s\n" % error)
            return 1
        print(payload.get("release") or "unknown")
        return 0

    if not apps:
        usage(sys.stderr)
        return 2

    font_path = font_path or find_font()
    glyphs = []
    if font_path:
        try:
            lookup = load_lookup(font_path, use_cache=use_cache)
            glyphs = [resolve(lookup, app) for app in apps]
        except (OSError, ValueError) as error:
            sys.stderr.write("app_icon.py: %s\n" % error)

    if not glyphs:
        glyphs = ["" for _ in apps]

    if as_json:
        print(json.dumps(glyphs, ensure_ascii=False))
    else:
        for glyph in glyphs:
            print(glyph)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
