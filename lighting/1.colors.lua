print('_VERSION = ' .. _VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'lib/libre_util'

require 'luaglm'
print('luaglm.VERSION = '   .. luaglm.VERSION)

num = glm.CNumber:new()
print("init,num:"..num:GetNumber())
num2 = glm.CNumber:new(222)
print("init,num2:"..num2:GetNumber())

local v1 = glm.vec3:new(1,2,3);
local v2 = glm.vec3:new(2,2,2);
local v3 = v1 + v2;
local v4 = glm.radians(v3);
print("v1.x=" .. v3.y);

local f1 = glm.radians(5);
print("f1=" .. f1);

