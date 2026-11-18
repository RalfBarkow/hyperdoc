"""Build the Scratch page attachment from this checkout with Python 3."""
import argparse
import os
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

SOURCE = Path(__file__).resolve().parents[1] / "dreyeck/work/scratch"
FILES = (
    "README.md",
    "evidence/typed-trail.png",
    "fedwiki/matrix-index.json",
    "fedwiki/scratch.json",
    "hyperdoc.lisp",
    "pages/Topics aus dem Federated Wiki Matrix Room.html",
    "reading.lisp",
    "scratch.asd",
    "scratch.ctm",
    "src/topic-index.lisp",
)


def build(destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=destination.parent, delete=False) as staging:
        temp = Path(staging.name)
    try:
        with ZipFile(temp, "w") as archive:
            for member in FILES:
                info = ZipInfo("scratch/" + member, (2026, 11, 18, 0, 0, 0))
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                source = "scratch.asd.in" if member == "scratch.asd" else member
                archive.writestr(info, (SOURCE / source).read_bytes(), compress_type=ZIP_DEFLATED)
        temp.chmod(0o644)
        os.replace(temp, destination)
    finally:
        if temp.exists():
            temp.unlink()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="destination ZIP")
    build(parser.parse_args().output)
