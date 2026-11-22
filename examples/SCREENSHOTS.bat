@echo off
rem Hosts mp_toujane locally for screenshots, with shotmod installed. No HUD; F11 toggles it.
rem devmap loads the map with cheats on, so cheat-protected settings like cg_draw2D stick (+map resets them).
rem Put this next to CoD2MP_s.exe. Pass another map with e.g. SCREENSHOTS.bat +devmap mp_carentan
rem One setting per line: every line but the last ends with ^ to continue the command.
start "" CoD2MP_s.exe ^
  +set cg_draw2D 0 ^
  +bind F11 "toggle cg_draw2D" ^
  +set g_gametype dm ^
  +devmap mp_toujane ^
  %*
