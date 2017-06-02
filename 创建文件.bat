set src=9.3.normal_visualization
set dst=1.1.advanced_lighting

cd advanced_opengl

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.gs %dst%.gs
copy /y %src%.skybox.vs %dst%.skybox.vs
copy /y %src%.skybox.fs %dst%.skybox.fs

::pause