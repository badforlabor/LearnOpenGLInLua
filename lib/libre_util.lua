require 'luaglew'
require 'luaglm'
require 'luastb'

-- 读取文件
function ReadAllText(filename)
  local file = io.open(filename, "r");
  local alltext = file:read("*a");
  return alltext;
end

function CompileShader(vid, vs, tag)
  glShaderSource(vid, 1, vs, {});
  glCompileShader(vid);
  tag = tag or "";
  
  -- 编译结果检查
  local succ = glGetShaderiv(vid, GL_COMPILE_STATUS);
  if(succ[1] == 0)
  then
    local msg = glGetShaderInfoLog(vid);
    print('compile ' .. tag .. ' shader failed:' .. msg);
  else
    print('compile ' .. tag .. ' shader succ:');
  end
end

-- 加载shader。传入vs代码和fs代码
function LoadShader(vs, fs, gs)
  local vid = glCreateShader(GL_VERTEX_SHADER)
  local fid = glCreateShader(GL_FRAGMENT_SHADER)
  local gid = 0;
  if gs ~= nil then gid = glCreateShader(GL_GEOMETRY_SHADER) end

  CompileShader(vid, vs, "VERTEX");
  CompileShader(fid, fs, "FRAGMENT");

  if gs ~= nil then CompileShader(gid, gs, "GEOMETRY"); end  

  local pid = glCreateProgram();
  glAttachShader(pid, vid);
  glAttachShader(pid, fid);
  if gid ~= 0 then glAttachShader(pid, gid); end
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
  glDeleteShader(gid);
  return pid;
end

function LoadShaderEx(vs, fs, gs)  
  local vertex_source = ReadAllText(vs);
  local fragment_source = ReadAllText(fs);
  local gs_source = nil;
  if gs ~= nil then gs_source = ReadAllText(gs); end;
  local sid = LoadShader(vertex_source, fragment_source, gs_source);
  return sid;
end

function LoadTexture(path)
  local ret = 0;
  
  local succ,width,height,data,comp = stbi_load(path);
  
  if(succ == 1)
  then
    local format = GL_RGB;
    
    if (comp == 1) then format = GL_RED; end
    if (comp == 3) then format = GL_RGB; end
    if (comp == 4) then format = GL_RGBA; end
    
    local textures = glGenTextures(1);
    local texture = textures[1];
    glBindTexture(GL_TEXTURE_2D, texture);

    local wrapvalue = GL_REPEAT;
    if (format == GL_RGBA) then wrapvalue = GL_CLAMP_TO_EDGE; end

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapvalue);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapvalue);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
    stbi_image_free(data);
    
    ret = texture;
  else
    print('load texture failed:' .. path);
  end
  
  return ret;
end
function LoadCubemap( faces )
  local textures = glGenTextures(1);
  local textureID = textures[1];
  glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);
  for i=1,table.getn(faces),1
  do
    local succ,width,height,data,comp = stbi_load(faces[i]);
    if(succ == 1)
    then
      print('load texture succ:' .. faces[i]);
      local format = GL_RGB;
      
      if (comp == 1) then format = GL_RED; end
      if (comp == 3) then format = GL_RGB; end
      if (comp == 4) then format = GL_RGBA; end

      glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
      stbi_image_free(data);
    else
      print('load texture failed:' .. faces[i]);
    end
  end
  glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
  return textureID;
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
      m:get(0,0), m:get(0,1), m:get(0,2), m:get(0,3),
      m:get(1,0), m:get(1,1), m:get(1,2), m:get(1,3),
      m:get(2,0), m:get(2,1), m:get(2,2), m:get(2,3),
      m:get(3,0), m:get(3,1), m:get(3,2), m:get(3,3)
  };
  return a;
end
function Mat4ToString(v)
  return string.format("[%f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f, %.2f %.2f %.2f %.2f]", 
      v:get(0,0), v:get(0,1), v:get(0,2), v:get(0,3),
      v:get(1,0), v:get(1,1), v:get(1,2), v:get(1,3),
      v:get(2,0), v:get(2,1), v:get(2,2), v:get(2,3),
      v:get(3,0), v:get(3,1), v:get(3,2), v:get(3,3)
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
function lerp(a,b,alpha)
  return a + alpha * (b-a);
end