require 'luaglew'
require 'luaglm'
require 'lib/libre_util'

Shader = 
{
  ID = 0,
};

function Shader:Init(vs, fs)
  self.ID = LoadShaderEx(vs, fs);
end

function Shader:new(vs, fs)
  local o = {};
  setmetatable(o, self);
  self.__index = self;
  
  o:Init(vs, fs);
  
  return o;
end

function Shader:Use()
  --print(self.ID);
  glUseProgram(self.ID);
end
function Shader:use()
  self:Use();
end

function Shader:SetInt(n, v)
  glUniform1i(glGetUniformLocation(self.ID, n), v);
end

function Shader:SetBool(n, v)
  local iv = 0;
  if(v)
    then iv = 1
  end
  self:SetInt(n, v);
end

function Shader:SetFloat(n, v)
  glUniform1f(glGetUniformLocation(self.ID, n), v);
end

function Shader:Set4Float(n, r,g,b,a)
  glUniform4f(glGetUniformLocation(self.ID, n), r, g, b, a);
end

function Shader:SetVec3(n, v,v1,v2)
  if v1 == nil then
    glUniform3fv(glGetUniformLocation(self.ID, n), 1, Vec3ToTable(v));
  else
    glUniform3fv(glGetUniformLocation(self.ID, n), 1, {v,v1,v2});
  end
end
function Shader:setVec3(n, v,v1,v2)
  self:SetVec3(n, v,v1,v2)
end

function Shader:SetMat4(n, v)
  glUniformMatrix4fv(glGetUniformLocation(self.ID, n), 1, GL_FALSE, Mat4ToTable(v));
end
function Shader:setMat4(n, v)
  self:SetMat4(n, v)
end
