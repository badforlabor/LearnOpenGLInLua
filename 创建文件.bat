set src=6.1.cubemaps_skybox
set dst=6.2.cubemaps_environment_mapping

cd advanced_opengl

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.skybox.vs %dst%.skybox.vs
copy /y %src%.skybox.fs %dst%.skybox.fs

::pause