require 'luaglew'

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
  glShaderSource(fid, 1, fs, {});
  glCompileShader(fid);

  local pid = glCreateProgram();
  glAttachShader(pid, vid);
  glAttachShader(pid, fid);
  glLinkProgram(pid);
  
  -- todo 加载失败后提示一下

  glDeleteShader(vid);
  glDeleteShader(fid);
  return pid;
end