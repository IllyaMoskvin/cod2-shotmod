# cod2-shotmod

A small mod for Call of Duty 2 multiplayer (PC, v1.3) that saves your exact view and state for a screenshot, and puts them back later, so you can take the same shot again: after changing a setting, in another build of the game, or on another day.

A view holds where you are and where you look, whether you're a spectator or playing, and whether the HUD is shown. If you're playing, it also holds your team, class, the weapon in your hands, your stance, and whether you're aiming down the sights. Every player saves and restores their own views, so several players can stage a shot together.

No game files are included. The installer reads the one game script it patches from your own copy of the game.

## Requirements

- Call of Duty 2 multiplayer, v1.3
- Python 3.10+ (standard library only)

## Install

```
python cod2_shotmod.py install "C:\Games\COD2\main"
```

This writes `zzz_shotmod.iwd` to the game's `main` folder. It holds:

- `maps/mp/gametypes/_shotmod.gsc`: the view script.
- `maps/mp/gametypes/_callbacksetup.gsc`: the game's own script, patched to start the view script in every gametype. The game loads archives in name order, so this copy wins over the stock one.
- `ui_mp/scriptmenus/shot*.menu`: small menus the script uses to change your stance and aim, and to read whether your HUD is shown. Scripts can't do those directly, but a menu can run a console command on your game.

Every player needs the same `zzz_shotmod.iwd`: the server reads the scripts, and each player's game runs the menus. Installs of the same version are byte-identical, so players can install it themselves.

### Mod folder

If you play with a mod folder (`+set fs_game mymod`), install into it instead:

```
python cod2_shotmod.py install "C:\Games\COD2\mymod"
```

If the mod has its own `_callbacksetup.gsc`, the installer uses it as the base, so the mod keeps its changes. Otherwise, it'll look for the file in a `main` folder next to the mod folder.

### Game folder elsewhere

If the mod folder isn't next to the game's `main` folder, tell the installer where `main` is with `--main`:

```
python cod2_shotmod.py install "D:\Code\mymod" --main "C:\Games\COD2\main"
```

A mod's own `_callbacksetup.gsc` is still used as the base: it's the copy the game runs. `--main` also helps if the installer can't read your `main` archives, for example when another tool has recompressed them: point it at a stock install's `main` folder instead.

## Use

Host a local game with `devmap`. For example:

```
CoD2MP_s.exe +set cg_draw2D 0 +set g_gametype dm +devmap mp_toujane
```

`devmap` loads the map with cheats on. The HUD setting (`cg_draw2D`) is cheat-protected, and `map` resets it as the map loads. [`examples/SCREENSHOTS.bat`](examples/SCREENSHOTS.bat) does this, and binds F11 to toggle the HUD.

In the console:

- `/openScriptMenu shot save:NAME` saves your view as NAME.
- `/openScriptMenu shot NAME` restores it.

Any player can use these, and they work as binds, which makes restaging a shot one key press:

```
/bind F5 "openScriptMenu shot jeep"
```

The host can also type `/set shot save NAME` and `/set shot NAME`.

Restoring closes any open menu, then changes only what differs from the view:

- The HUD is shown or hidden as it was.
- A spectator view puts you there as a spectator, floating with no weapon in view.
- A playing view switches your team and class if they differ, through the game's own team and class menus, so the game spawns you as usual. You're then moved into place, given the weapon you held, and put in the saved stance and aim.

Views only restore on the map they were saved on. Gametypes that don't let you spawn mid-round, like Search & Destroy, can't restore playing views until the next round.

## The views file

Views are saved in `scriptdata/shotmod.cfg` in the game folder in use: `main`, or the mod folder. One view per line:

```
name,map,state,team,class,weapon,stance,ads,x,y,z,pitch,yaw,roll,hud
jeep,mp_toujane,spectator,spectator,none,none,stand,0,1767.6,213.915,48.6523,34.7882,104.837,0,0
crouchads,mp_toujane,playing,allies,m1garand_mp,m1garand_mp,crouch,1,254.735,1385.79,-5.60219,-2.19177,1.14258,0,0
```

It's a CSV file with a `.cfg` name: with `sv_pure 1`, the game only lets scripts read unpacked `.cfg` and `.menu` files. Lines the mod writes end with a comma, which is harmless.

Saving a name again adds a new line, and restoring uses the last one. The file is plain text: edit it, or copy it between installs and mod folders to take the same shots in each. A view without `hud` leaves the HUD alone. A line with just `name,map,state,x,y,z,pitch,yaw,roll` only restores where you are and where you look.

## Notes

- The game prints a warning in the console for each message the mod shows on screen. It's harmless.
- The HUD flickers briefly when you save, and after a restore that changes your stance or aim.

## License

MIT, for the code in this repository. Call of Duty 2 and its game files belong to their owners.
