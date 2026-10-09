"""Turn a `docker compose` lockfile into diun's file-provider image list.

Usage: diun-images <compose.lock.yaml> <images.yml>

Each service's pinned image (tag@digest) is watched for new tags of the same
shape as the pinned one (v3.6.10 -> ^v\\d+\\.\\d+\\.\\d+$), so nightlies and
other variants don't notify. Semver-like tags are sorted newest first and
capped, so only the newest few are fetched (Docker Hub rate-limits manifest
GETs); others can't be sorted reliably by diun and are watched in full.
"""

import json
import re
import sys

import yaml

SEMVER = re.compile(r"^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$")
MAX_TAGS = 5


def tag_pattern(tag):
    parts = re.split(r"(\d+)", tag)
    return "^" + "".join(
        r"\d+" if p.isdigit() else re.escape(p) for p in parts
    ) + "$"


def entry(service, image):
    ref = image.split("@", 1)[0]
    name, tag = ref.rsplit(":", 1)
    e = {
        "name": ref,
        "watch_repo": True,
        "include_tags": [tag_pattern(tag)],
        "metadata": {"service": service, "running": tag},
    }
    if SEMVER.match(tag.lstrip("v")):
        e["sort_tags"] = "semver"
        e["max_tags"] = MAX_TAGS
    return e


def main(lock_path, out_path):
    with open(lock_path) as f:
        services = yaml.safe_load(f)["services"]
    images = [entry(s, v["image"]) for s, v in sorted(services.items())]
    with open(out_path, "w") as f:
        json.dump(images, f, indent=2)


if __name__ == "__main__":
    main(*sys.argv[1:])
