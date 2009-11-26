@echo off
setlocal

set tool=ZGameEditor

copy .\exe\ZDesigner.exe ..\..\Deploy\%tool%\%tool%.exe
copy .\exe\player.bin ..\..\Deploy\%tool%\
copy .\exe\player_ss.bin ..\..\Deploy\%tool%\
copy .\exe\about.bin ..\..\Deploy\%tool%\
rem copy .\exe\player_activex.bin ..\..\Deploy\%tool%\
copy .\exe\player_linux.bin ..\..\Deploy\%tool%\
copy .\exe\player_osx86.bin ..\..\Deploy\%tool%\
copy .\exe\MidiInstruments.xml ..\..\Deploy\%tool%\
copy .\exe\Library.xml ..\..\Deploy\%tool%\
copy .\exe\zzdc.map ..\..\Deploy\%tool%\
copy .\exe\zgameeditor.chm ..\..\Deploy\%tool%\

copy .\exe\projects\About.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\Implicit.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\Particles.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\Steering.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\TripleE.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\ZPong.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\FileDemo\FileDemo.zgeproj ..\..\Deploy\%tool%\projects\FileDemo\
copy .\exe\projects\FileDemo\TestFile.txt ..\..\Deploy\%tool%\projects\FileDemo\
copy .\exe\projects\CleanseCube.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\ShaderDemo.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\FpsDemo\FpsDemo.zgeproj ..\..\Deploy\%tool%\projects\FpsDemo\
copy .\exe\projects\FpsDemo\FpsLevelLayout.txt ..\..\Deploy\%tool%\projects\FpsDemo\
copy .\exe\projects\ZBlast.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\RenderTexture.zgeproj ..\..\Deploy\%tool%\projects\
copy .\exe\projects\RenderPass.zgeproj ..\..\Deploy\%tool%\projects\

rem Remove any extra files
rem del ..\..\Deploy\%tool%\%tool%.ini
rem del ..\..\Deploy\%tool%\projects\*.exe
rem del ..\..\Deploy\%tool%\projects\*.scr

:exit
rem Remove local variables
endlocal

