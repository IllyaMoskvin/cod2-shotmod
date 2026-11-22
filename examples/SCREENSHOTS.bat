@echo off
rem Hosts mp_toujane locally for screenshots, with the mod from cod2_screenshot.py install.
rem No HUD; F11 toggles it. Put this next to CoD2MP_s.exe. Pass another map with e.g. SCREENSHOTS.bat +map mp_carentan
rem One setting per line: every line but the last ends with ^ to continue the command.
start "" CoD2MP_s.exe ^
  +set cg_draw2D 0 ^
  +bind F11 "toggle cg_draw2D" ^
  +set g_gametype dm ^
  +map mp_toujane ^
  %*
