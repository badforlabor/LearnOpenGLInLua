set src=1.1.depth_testing
set dst=3.1.blending_discard

cd advanced_opengl

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.lamp.vs %dst%.lamp.vs
copy /y %src%.lamp.fs %dst%.lamp.fs

::pause