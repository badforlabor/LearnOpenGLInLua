require 'luaglew'
require 'luaglm'

-- 读取文件
function ReadAllText(filename)
  local file = io.open(filename, "r");
  local alltext = file:read("*a");
  return alltext;
end

-- 加载shader。传入vs代码和fs代码
function LoadShader(vs, fs)
  local vid = glCreateShader(GL_VERTEX_SHADER)
  local fid = glCreateShader(GL_FRAGMENT_SHADER)

  glShaderSource(vid, 1, vs, {});
  glCompileShader(vid);
  
  -- 编译结果检查
  local succ = glGetShaderiv(vid, GL_COMPILE_STATUS);
  if(succ[1] == 0)
  then
    local msg = glGetShaderInfoLog(vid);
    print('compile vertex failed:' .. msg);
  end

  
  glShaderSource(fid, 1, fs, {});
  glCompileShader(fid);
  
  -- 编译结果检查
  succ = glGetShaderiv(fid, GL_COMPILE_STATUS);
  if(succ[1] == 0)
  then
    msg = glGetShaderInfoLog(fid);
    print('compile fragment failed:' .. msg);
  end

  local pid = glCreateProgram();
  glAttachShader(pid, vid);
  glAttachShader(pid, fid);
  glLinkProgram(pid);
  
  -- 加载失败后提示一下
  succ = glGetProgramiv(pid, GL_LINK_STATUS);
  if(succ[1] == 0)
  then
    msg = glGetProgramInfoLog(pid);
    print('link shader failed:' .. msg);
  end

  glDeleteShader(vid);
  glDeleteShader(fid);
  return pid;
end

function LoadShaderEx(vs, fs)  
  local vertex_source = ReadAllText(vs);
  local fragment_source = ReadAllText(fs);
  local sid = LoadShader(vertex_source, fragment_source);
  return sid;
end

-- vec3, mat4工具函数
function vec3_zero()
  return glm.vec3:new();
end

function vec3_one()
  return glm.vec3:new(1);
end

function Vec3ToTable(v)
  local a = {v.x,v.y,v.z};
  return a;
end

function mat4_identity()
  return glm.mat4:new();
end

function Mat4ToTable(m)
  local a = 
  {
      m.get(m,0,0), m.get(m,0,1), m.get(m,0,2), m.get(m,0,3),
      m.get(m,1,0), m.get(m,1,1), m.get(m,1,2), m.get(m,1,3),
      m.get(m,2,0), m.get(m,2,1), m.get(m,2,2), m.get(m,2,3),
      m.get(m,3,0), m.get(m,3,1), m.get(m,3,2), m.get(m,3,3),
  };
  return a;
end
function Mat4ToString(v)
  return string.format("[%f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f]", 
      v.get(v, 0,0), v.get(v, 0,1), v.get(v, 0,2), v.get(v, 0,3),
      v.get(v, 1,0), v.get(v, 1,1), v.get(v, 1,2), v.get(v, 1,3),
      v.get(v, 2,0), v.get(v, 2,1), v.get(v, 2,2), v.get(v, 2,3),
      v.get(v, 3,0), v.get(v, 3,1), v.get(v, 3,2), v.get(v, 3,3)
      )
end
function Vec3ToString(v)
  return string.format("(%f,%f,%f)", v.x, v.y, v.z);
end

function sizeof_float()
  return 4;
end
function sizeof_int()
  return 4;
end