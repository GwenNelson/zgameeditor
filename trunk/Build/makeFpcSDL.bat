@echo off
rem -B   Build all
rem -Sd  Delphi extensions
rem -Os  Generate smaller code
rem -dZZDC_SDL SDL eller ZZDC_WIN32
rem -al  Keep assembler-files
rem -gl  Show line-nr in stack trace (debuginfo)

rem FPC 2.0 krashar zblast i G-l�ge
cd ..
fpc -al -XXis -O2 -dZZDC_SDL SDL -dMINIMAL -FU.\build\obj\ -B -Mdelphi -FE.\build\ zzdc.dpr
cd build

