set src=1.1.advanced_lighting
set dst=3.1.shadow_mapping_depth

cd advanced_lighting

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.gs %dst%.gs
copy /y %src%.skybox.vs %dst%.skybox.vs
copy /y %src%.skybox.fs %dst%.skybox.fs

::pause