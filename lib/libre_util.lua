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