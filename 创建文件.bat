set src=5.1.framebuffers
set dst=6.1.cubemaps_skybox

cd advanced_opengl

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%_screen.vs %dst%.skybox.vs
copy /y %src%_screen.fs %dst%.skybox.fs

::pause