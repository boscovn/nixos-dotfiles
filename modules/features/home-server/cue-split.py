"""Split CUE + single-file album images into one FLAC per track.

Usage: cue-split [--out DIR] [--originals DIR] PATH...

Every .cue under PATH that describes an image (one FILE, several TRACKs) is
split with unflac, tagged from the cue. In place, the image, its cue and the
rip logs are then moved to --originals (keeping their path relative to its
parent), so players don't list the album twice. With --out the tracks go to
DIR/<album dir> and the sources are left alone (torrents keep seeding).

Cues that list one file per track are already split and skipped.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AUDIO = {".flac", ".wav", ".ape", ".wv"}
NAMING = "{{printf .Input.TrackNumberFmt .Track.Number}} - {{.Track.Title | Elem}}"
FILE_RE = re.compile(r'^\s*FILE\s+(?:"(.*)"|(\S+))\s+(\S+)\s*$', re.IGNORECASE)
TRACK_RE = re.compile(r"^\s*TRACK\s+\d+\s+AUDIO", re.IGNORECASE)
INDEX_RE = re.compile(r"^(\s*INDEX\s+)(\d+)(\s+)\S+", re.IGNORECASE)


def warn(msg):
    print(f"cue-split: {msg}", file=sys.stderr)


def decode(raw):
    # Rippers write UTF-8 (sometimes with a BOM) or the Windows code page.
    try:
        return raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace")


def resolve_audio(cue, name):
    """The image the cue names, else the directory's only audio file (the
    name in the cue and on disk can disagree after a bad charset round
    trip)."""
    named = cue.parent / name
    if named.is_file():
        return named
    audio = [p for p in cue.parent.iterdir() if p.suffix.lower() in AUDIO]
    return audio[0] if len(audio) == 1 else None


def append_gaps(lines):
    """unflac drops the audio between a track's INDEX 00 and INDEX 01 (the
    gap). Without INDEX 00 lines each gap stays at the end of the previous
    track, as EAC's "gaps appended" rips do; the first track starts at 0 so
    a hidden pregap isn't lost either."""
    result, first = [], True
    for line in lines:
        m = INDEX_RE.match(line)
        if m and int(m.group(2)) == 0:
            continue
        if m and int(m.group(2)) == 1 and first:
            line = f"{m.group(1)}{m.group(2)}{m.group(3)}00:00:00"
            first = False
        result.append(line)
    return result


def flacs(directory):
    if not directory.is_dir():
        return set()
    return {p for p in directory.iterdir() if p.suffix.lower() == ".flac"}


def split(cue, out, originals):
    lines = decode(cue.read_bytes()).splitlines()
    files = [(i, m) for i, line in enumerate(lines) if (m := FILE_RE.match(line))]
    tracks = sum(1 for line in lines if TRACK_RE.match(line))
    if len(files) != 1 or tracks < 2:
        return True  # already one file per track
    index, match = files[0]
    image = resolve_audio(cue, match.group(1) or match.group(2))
    if image is None:
        warn(f"{cue}: audio file {match.group(1) or match.group(2)!r} not found")
        return False

    target = out / cue.parent.name if out else cue.parent
    target.mkdir(parents=True, exist_ok=True)
    before = flacs(target) - {image}

    with tempfile.TemporaryDirectory() as tmp:
        # unflac resolves FILE next to the cue: give it a UTF-8 copy that
        # names a link to the image (and keeps the gaps).
        link = Path(tmp) / f"image{image.suffix}"
        link.symlink_to(image.resolve())
        lines[index] = f'FILE "{link.name}" {match.group(3)}'
        tmp_cue = Path(tmp) / "image.cue"
        tmp_cue.write_text("\n".join(append_gaps(lines)) + "\n", encoding="utf-8")
        result = subprocess.run(
            ["unflac", "-q", "-o", str(target), "-n", NAMING, str(tmp_cue)],
            check=False,
        )

    new = flacs(target) - before - {image}
    if result.returncode != 0 or len(new) != tracks:
        warn(f"{cue}: split failed ({len(new)} of {tracks} tracks), removing them")
        for path in new:
            path.unlink()
        return False
    print(f"{cue.parent}: {tracks} tracks")

    if not out:
        try:
            rel = cue.parent.resolve().relative_to(originals.parent.resolve())
        except ValueError:
            rel = Path(cue.parent.name)
        dest = originals / rel
        dest.mkdir(parents=True, exist_ok=True)
        for path in {cue, image, *cue.parent.glob("*.log")}:
            shutil.move(path, dest / path.name)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, help="write tracks here, keep sources")
    parser.add_argument(
        "--originals",
        type=Path,
        required=True,
        help="where in-place splits move the image, cue and logs",
    )
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()
    # Shared media tree: group-writable, like its other writers.
    os.umask(0o002)

    ok = True
    for path in args.paths:
        cues = [path] if path.suffix.lower() == ".cue" else sorted(path.rglob("*.cue"))
        for cue in cues:
            # Don't split what was already set aside.
            if args.originals.resolve() in cue.resolve().parents:
                continue
            ok &= split(cue, args.out, args.originals)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
