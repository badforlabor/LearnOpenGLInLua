set src=6.1.hdr
set dst=8.1.deferred_shading

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