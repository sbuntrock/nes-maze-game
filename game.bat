del game.nes
del game.fms
del game.nes.deb
del audio.txt
del audio.asm
"tools\Fami Tracker\FamiTracker.exe" audio.ftm -export audio.txt
tools\text2data.exe audio.txt
tools\NESASM3.exe -s game.asm
tools\fceuxdsp.exe game.nes