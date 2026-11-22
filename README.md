# cod2-screenshot

A small mod for Call of Duty 2 multiplayer (PC, v1.3) that saves your exact camera view and puts it back later, so you can take the same screenshot again: after changing a setting, in another build of the game, or on another day.

No game files are included. The installer reads the one game script it patches from your own copy of the game.

## Requirements

- Call of Duty 2 multiplayer, v1.3
- Python 3.10+ (standard library only)

## Install

```
python cod2_screenshot.py install "C:\Games\COD2\main"
```

This writes `zzz_shots.iwd` to the game's `main` folder. It holds two scripts:

- `maps/mp/gametypes/_shots.gsc`: the view script.
- `maps/mp/gametypes/_callbacksetup.gsc`: the game's own script, patched to start the view script in every gametype. The game loads archives in name order, so this copy wins over the stock one.

If your `main` archives aren't stock (for example, recompressed by another tool), read the game script from a stock install:

```
python cod2_screenshot.py install "D:\SmallBuild\main" --from "C:\Games\COD2\main"
```

## Use

Host a local game. For example:

```
CoD2MP_s.exe +set g_gametype dm +map mp_toujane
```

[`examples/SCREENSHOTS.bat`](examples/SCREENSHOTS.bat) does this, and also hides the HUD and binds F11 to toggle it.

In the console:

- `/set shot save NAME` saves the current view as NAME.
- `/set shot NAME` restores it. A view saved as a spectator puts you back as a spectator, floating with no weapon in view. Otherwise you're moved there as a player.

Views are saved in `main/scriptdata/shots.cfg`, one per line:

```
name,map,state,x,y,z,pitch,yaw,roll
jeep,mp_toujane,spectator,1767.6,213.915,48.6523,34.7882,104.837,0
```

It's a CSV file with a `.cfg` name: with `sv_pure 1`, the game only lets scripts read unpacked `.cfg` and `.menu` files. Lines the mod writes end with a comma, which is harmless.

Saving a name again adds a new line, and restoring uses the last one. The file is plain text: edit it, or copy it between installs to take the same shots in each.

## Notes

- The view is the host's: the first player on the server. It's meant for a local game you host yourself.
- Other players would need the same `zzz_shots.iwd` to join a server running it.
- Views only restore on the map they were saved on.
- The game prints a warning in the console for each message the mod shows on screen. It's harmless.

## License

MIT, for the code in this repository. Call of Duty 2 and its game files belong to their owners.
