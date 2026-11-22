# cod2-screenshot

A small mod for Call of Duty 2 multiplayer (PC, v1.3) that saves your exact view and state, and puts them back later, so you can take the same screenshot again: after changing a setting, in another build of the game, or on another day.

A view holds where you are and where you look, and whether you're a spectator or playing. If you're playing, it also holds your team, class, the weapon in your hands, your stance, and whether you're aiming down the sights. Every player saves and restores their own views, so several players can stage a shot together.

No game files are included. The installer reads the one game script it patches from your own copy of the game.

## Requirements

- Call of Duty 2 multiplayer, v1.3
- Python 3.10+ (standard library only)

## Install

```
python cod2_screenshot.py install "C:\Games\COD2\main"
```

This writes `zzz_shots.iwd` to the game's `main` folder. It holds:

- `maps/mp/gametypes/_shots.gsc`: the view script.
- `maps/mp/gametypes/_callbacksetup.gsc`: the game's own script, patched to start the view script in every gametype. The game loads archives in name order, so this copy wins over the stock one.
- `ui_mp/scriptmenus/shot*.menu`: small menus the script uses to change your stance and aim. Scripts can't do that directly, but a menu can run a console command on your game.

Every player needs the same `zzz_shots.iwd`: the server reads the scripts, and each player's game runs the menus.

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

- `/openScriptMenu shot save:NAME` saves your view as NAME.
- `/openScriptMenu shot NAME` restores it.

Any player can use these, and they work as binds, which makes restaging a shot one key press:

```
/bind F5 "openScriptMenu shot jeep"
```

The host can also type `/set shot save NAME` and `/set shot NAME`.

Restoring closes any open menu, then changes only what differs from the view:

- A spectator view puts you there as a spectator, floating with no weapon in view.
- A playing view switches your team and class if they differ, through the game's own team and class menus, so the game spawns you as usual. You're then moved into place, given the weapon you held, and put in the saved stance and aim.

Views only restore on the map they were saved on. Gametypes that don't let you spawn mid-round, like Search & Destroy, can't restore playing views until the next round.

## The views file

Views are saved in `main/scriptdata/shots.cfg`, one per line:

```
name,map,state,team,class,weapon,stance,ads,x,y,z,pitch,yaw,roll
jeep,mp_toujane,spectator,spectator,none,none,stand,0,1767.6,213.915,48.6523,34.7882,104.837,0
crouchads,mp_toujane,playing,allies,m1garand_mp,m1garand_mp,crouch,1,254.735,1385.79,-5.60219,-2.19177,1.14258,0
```

It's a CSV file with a `.cfg` name: with `sv_pure 1`, the game only lets scripts read unpacked `.cfg` and `.menu` files. Lines the mod writes end with a comma, which is harmless. Lines with just `name,map,state,x,y,z,pitch,yaw,roll` also work, and only restore your position and view.

Saving a name again adds a new line, and restoring uses the last one. The file is plain text: edit it, or copy it between installs to take the same shots in each.

## Notes

- The game prints a warning in the console for each message the mod shows on screen. It's harmless.
- The HUD flickers briefly after a restore that changes your stance or aim.

## License

MIT, for the code in this repository. Call of Duty 2 and its game files belong to their owners.
