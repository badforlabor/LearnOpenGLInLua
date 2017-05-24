set src=5.3.light_casters_spot
set dst=3.1.model_loading

cd lighting

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.lamp.vs %dst%.lamp.vs
copy /y %src%.lamp.fs %dst%.lamp.fs

::pause