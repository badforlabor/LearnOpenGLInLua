set src=1.1.depth_testing
set dst=6.3.geometry_shader_houses

cd advanced_opengl

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.skybox.vs %dst%.skybox.vs
copy /y %src%.skybox.fs %dst%.skybox.fs

::pause