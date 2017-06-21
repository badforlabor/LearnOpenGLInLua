set src=8.1.deferred_shading
set dst=8.2.deferred_shading_volume

cd advanced_lighting

copy /y %src%.lua %dst%.lua
copy /y %src%.vs %dst%.vs
copy /y %src%.fs %dst%.fs
copy /y %src%.gs %dst%.gs
copy /y %src%.light_box.vs %dst%.light_box.vs
copy /y %src%.light_box.fs %dst%.light_box.fs
copy /y %src%.gbuffer.vs %dst%.gbuffer.vs
copy /y %src%.gbuffer.fs %dst%.gbuffer.fs

::pause