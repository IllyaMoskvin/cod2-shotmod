"""Save and restore exact views in Call of Duty 2 multiplayer, for repeatable screenshots.

  install FOLDER [--from STOCK_MAIN]
      Writes zzz_shotmod.iwd to FOLDER: the game's main folder, or a mod folder that you launch with
      +set fs_game. The mod patches the game's _callbacksetup.gsc, so every gametype starts the view
      script. It patches the copy the game would load: a mod folder's own, if it has one, or else the
      one in main's archives (or STOCK_MAIN's, if given). Archives load in name order, and a mod
      folder's after main's, so zzz_shotmod.iwd wins.
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
HOOK = "\t\tlevel thread maps\\mp\\gametypes\\_shotmod::init();\n"
ARCHIVE = "zzz_shotmod.iwd"
VIEWS = "shotmod.cfg"
# Earlier versions of this mod
OLD_ARCHIVE, OLD_SCRIPT, OLD_VIEWS = "zzz_shots.iwd", "maps/mp/gametypes/_shots.gsc", "shots.cfg"


def find_callbacks(folders: list[Path]) -> tuple[bytes, str]:
    """The _callbacksetup.gsc the game would load from these folders (main first), and where it's from.

    In each folder, archives load in name order and win over unpacked files; later folders win.
    """
    found = None
    for folder in folders:
        in_archive = None
        for archive in sorted(folder.glob("*.iwd"), key=lambda p: p.name.lower()):
            if archive.name.lower() in (ARCHIVE, OLD_ARCHIVE):
                continue
            with zipfile.ZipFile(archive) as z:
                for info in z.infolist():
                    if info.filename.lower() == CALLBACKS:
                        try:
                            in_archive = (z.read(info), str(archive))
                        except NotImplementedError:
                            sys.exit(f"{archive} stores {CALLBACKS} in a format zipfile can't read; "
                                     "point --from at a stock install's main folder")
        loose = folder / CALLBACKS
        if in_archive:
            found = in_archive
        elif loose.is_file():
            found = (loose.read_bytes(), str(loose))
    if found is None:
        sys.exit(f"no {CALLBACKS} in {', '.join(map(str, folders))}")
    return found


def install(folder: Path, stock: Path | None) -> None:
    if folder.name.lower() == "main":
        folders = [stock or folder]
    else:
        folders = [stock or folder.parent / "main", folder]
    data, source = find_callbacks(folders)
    callbacks = data.decode("latin-1")
    # Stock files use CRLF; match on LF and write the patched file back the same way.
    crlf = "\r\n" in callbacks
    callbacks = callbacks.replace("\r\n", "\n")
    if callbacks.count(ANCHOR) != 1:
        sys.exit(f"{source} doesn't start gametypes like the stock 1.3 {CALLBACKS}: can't hook the view script in")
    callbacks = callbacks.replace(ANCHOR, ANCHOR + HOOK)
    if crlf:
        callbacks = callbacks.replace("\n", "\r\n")

    # A fixed timestamp makes every install of a version byte-identical: pure servers compare
    # each player's archives with their own.
    files = {CALLBACKS: callbacks.encode("latin-1")}
    files.update({p.relative_to(MOD).as_posix(): p.read_bytes() for p in MOD.rglob("*") if p.is_file()})
    with zipfile.ZipFile(folder / ARCHIVE, "w", zipfile.ZIP_DEFLATED) as z:
        for name in sorted(files):
            z.writestr(zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0)), files[name], zipfile.ZIP_DEFLATED)
    print(f"{folder / ARCHIVE} (patched {CALLBACKS} from {source})")

    old = folder / OLD_ARCHIVE
    if old.is_file():
        with zipfile.ZipFile(old) as z:
            ours = OLD_SCRIPT in z.namelist() or "maps/mp/gametypes/dm.gsc" in z.namelist()
        if ours:
            old.unlink()
            print(f"removed {old}, an earlier version")
    views = folder / "scriptdata" / VIEWS
    old_views = folder / "scriptdata" / OLD_VIEWS
    if old_views.is_file() and not views.exists():
        old_views.rename(views)
        print(f"renamed {old_views} to {VIEWS}")
    print(f"Views are saved in {views}.")
    if folder.name.lower() != "main":
        print(f"Launch with +set fs_game {folder.name}.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("install", help="add the mod to a game's main folder or a mod folder")
    p.add_argument("folder", type=Path, help="the game's main folder, or a mod folder next to it")
    p.add_argument("--from", dest="stock", type=Path, help="a stock main folder to read game scripts from")
    args = parser.parse_args(argv)
    install(args.folder, args.stock)
    return 0


if __name__ == "__main__":
    sys.exit(main())
