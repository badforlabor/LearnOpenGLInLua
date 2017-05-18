print('_VERSION = ' .. _VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'lib/libre_util'

require 'luaglm'
print('luaglm.VERSION = '   .. luaglm.VERSION)


local function ShowMatrix(v)
  print('matrix:' .. string.format("\n[\n %.2f %.2f %.2f %.2f,\n %.2f %.2f %.2f %.2f,\n %.2f %.2f %.2f %.2f,\n %.2f %.2f %.2f %.2f\n]", 
      v.get(v, 0,0), v.get(v, 0,1), v.get(v, 0,2), v.get(v, 0,3),
      v.get(v, 1,0), v.get(v, 1,1), v.get(v, 1,2), v.get(v, 1,3),
      v.get(v, 2,0), v.get(v, 2,1), v.get(v, 2,2), v.get(v, 2,3),
      v.get(v, 3,0), v.get(v, 3,1), v.get(v, 3,2), v.get(v, 3,3)
      ));
end

local function MatrixToString(v)
  return string.format("[%.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f]", 
      v.get(v, 0,0), v.get(v, 0,1), v.get(v, 0,2), v.get(v, 0,3),
      v.get(v, 1,0), v.get(v, 1,1), v.get(v, 1,2), v.get(v, 1,3),
      v.get(v, 2,0), v.get(v, 2,1), v.get(v, 2,2), v.get(v, 2,3),
      v.get(v, 3,0), v.get(v, 3,1), v.get(v, 3,2), v.get(v, 3,3)
      )
end


-- vec3 test begin
num = glm.CNumber:new()
print("init,num:"..num:GetNumber())
num2 = glm.CNumber:new(222)
print("init,num2:"..num2:GetNumber())

local v1 = glm.vec3:new(1,2,3);
local v2 = glm.vec3:new(2,2,2);
local v3 = v1 + v2;
print("v1.x=" .. v3.y);

v3 = v1 * 2;
print('v1 * 2=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v1 / 2;
print('v1 / 2=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v1 + 2;
print('v1 / 2=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v1 - 2;
print('v1 / 2=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');

v3 = v2 + v1;
print('v2 + v1=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v2 - v1;
print('v2 - v1=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v2 * v1;
print('v2 * v1=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
v3 = v2 / v1;
print('v2 / v1=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
-- vec3 test end

-- mat4 test begin
local m1 = glm.mat4:new();
ShowMatrix(m1);
local m2 = m1 + 2;
print('m1 + 2=' .. MatrixToString(m2));
m2 = m1 - 2;
print('m1 - 2=' .. MatrixToString(m2));
m2 = m1 * 2;
print('m1 * 2=' .. MatrixToString(m2));
m2 = m1 / 2;
print('m1 / 2=' .. MatrixToString(m2));
local m3 = glm.translate(m1, glm.vec3:new(2,0,0)); -- glm.scale(m1, glm.vec3:new(2,2,2));--
ShowMatrix(m3);
m2 = m3 * m1;
print('m3 * m1=' .. MatrixToString(m2));
-- mat4 test end



-- glm function
local v4 = glm.radians(v3);

local f1 = glm.radians(30);
print("f1=" .. f1);

v1 = glm.vec3:new(1,0,0);
v2 = glm.vec3:new(0,1,0);
v3 = glm.cross(v1, v2);
f1 = glm.dot(v1, v2);
print('cross result=(' .. v3.x .. ',' .. v3.y .. ',' .. v3.z .. ')');
print('dot result=' .. f1);

m2 = glm.rotate(m1, glm.radians(30), v1);
m2 = glm.translate(m1, v1);
m2 = glm.scale(m1, v1);

m2 = glm.perspective(glm.radians(30), 1024 / 768.0, 1, 1000);
m2 = glm.ortho(0, 100, 100, 0, 1, 1000);
m2 = glm.ortho(0, 100, 100, 0);
m2 = glm.frustum(0, 100, 100, 0, 1, 1000);
m2 = glm.lookAt(glm.vec3:new(), v2, glm.vec3:new(0,0,1)); 

m2 = glm.transpose(m1);
m2 = glm.inverse(m1);
-- glm function end.


print('***** all test pass, the end *****');