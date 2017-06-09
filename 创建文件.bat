set src=3.1.shadow_mapping_depth
set dst=3.2.shadow_mapping_base

cd advanced_lighting

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.gs %dst%.gs
copy /y %src%.debug.vs %dst%.debug.vs
copy /y %src%.debug.fs %dst%.debug.fs

::pause