"""Save and restore exact camera views in Call of Duty 2 multiplayer, for repeatable screenshots.

  install MAIN [--from STOCK_MAIN]
      Writes zzz_shots.iwd to the game's main folder. The mod patches the game's own
      _callbacksetup.gsc, read from the stock archives in STOCK_MAIN (MAIN by default), so every
      gametype starts the view script. Archives load in name order, so zzz_ wins over the stock ones.
"""

from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
MOD = HERE / "mod"
CALLBACKS = "maps/mp/gametypes/_callbacksetup.gsc"
ANCHOR = "\t\tlevel.gametypestarted = true; // so we know that the gametype has been started up\n"
HOOK = "\t\tlevel thread maps\\mp\\gametypes\\_shots::init();\n"
ARCHIVE = "zzz_shots.iwd"


def read_stock(main: Path, name: str) -> bytes:
    """A file from the game's archives; later archives win, as in the game."""
    found = None
    for archive in sorted(main.glob("*.iwd"), key=lambda p: p.name.lower()):
        if archive.name.lower() == ARCHIVE:
            continue
        with zipfile.ZipFile(archive) as z:
            for info in z.infolist():
                if info.filename.lower() == name:
                    try:
                        found = z.read(info)
                    except NotImplementedError:
                        sys.exit(f"{archive} stores {name} in a format zipfile can't read; "
                                 "point --from at a stock install's main folder")
    if found is None:
        sys.exit(f"no {name} in {main}")
    return found


def install(main: Path, stock: Path) -> None:
    callbacks = read_stock(stock, CALLBACKS).decode("latin-1")
    # Stock files use CRLF; match on LF and write the patched file back the same way.
    crlf = "\r\n" in callbacks
    callbacks = callbacks.replace("\r\n", "\n")
    if callbacks.count(ANCHOR) != 1:
        sys.exit(f"{CALLBACKS} isn't the stock 1.3 version: can't find where to start the view script")
    callbacks = callbacks.replace(ANCHOR, ANCHOR + HOOK)
    if crlf:
        callbacks = callbacks.replace("\n", "\r\n")
    with zipfile.ZipFile(main / ARCHIVE, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(CALLBACKS, callbacks.encode("latin-1"))
        for path in sorted(MOD.rglob("*.gsc")):
            z.write(path, path.relative_to(MOD).as_posix())
    print(main / ARCHIVE)
    print(f"Views are saved in {main / 'scriptdata' / 'shots.cfg'}.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("install", help="add the mod to a game's main folder")
    p.add_argument("main", type=Path, help="the game's main folder")
    p.add_argument("--from", dest="stock", type=Path, help="a stock main folder to read game scripts from")
    args = parser.parse_args(argv)
    install(args.main, args.stock or args.main)
    return 0


if __name__ == "__main__":
    sys.exit(main())
