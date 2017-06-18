set src=3.3.shadow_mapping
set dst=6.1.hdr

cd advanced_lighting

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.gs %dst%.gs
::copy /y %src%.debug.vs %dst%.debug.vs
::copy /y %src%.debug.fs %dst%.debug.fs
::copy /y %src%.depth.vs %dst%.depth.vs
::copy /y %src%.depth.fs %dst%.depth.fs

::pause