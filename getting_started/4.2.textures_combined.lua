-- vim: set ts=3 et:

print('_VERSION = ' .. _VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'luastb'
print('luastb.VERSION = '   .. luastb.VERSION)

require 'lib/libre_util'

local quit = false
local fps = 15
local msec = 1000 / fps

local ProgramID;
local vid;
local fid;

local vbo, vao, veo;
local texture, tex_face;

local currentfile = 'getting_started/4.2.textures_combined'

local vertex_source = ReadAllText(currentfile .. ".vs");
local fragment_source = ReadAllText(currentfile .. ".fs");

local function set_material_clay()
   glMaterialfv(GL_FRONT, GL_AMBIENT,  {0.2125, 0.1275, 0.054, 1.0})
   glMaterialfv(GL_FRONT, GL_DIFFUSE,  {0.514, 0.4284, 0.18144, 1.0})
   glMaterialfv(GL_FRONT, GL_SPECULAR, {0.393548, 0.271906, 0.166721, 1.0})
   glMaterialf(GL_FRONT, GL_SHININESS, 0.2 * 128.0)

   glMaterialfv(GL_BACK, GL_AMBIENT,  {0.1, 0.18725, 0.1745, 1.0})
   glMaterialfv(GL_BACK, GL_DIFFUSE,  {0.396, 0.74151, 0.69102, 1.0})
   glMaterialfv(GL_BACK, GL_SPECULAR, {0.297254, 0.30829, 0.306678, 1.0})
   glMaterialf(GL_BACK, GL_SHININESS, 0.1 * 128.0)

   glEnable(GL_LIGHT0)
   glLightfv(GL_LIGHT0, GL_AMBIENT, {0.2, 0.2, 0.2, 1})
   glLightfv(GL_LIGHT0, GL_DIFFUSE, {1, 1, 1, 1})
   glLightfv(GL_LIGHT0, GL_POSITION, {0.0, 1.0, 0.0, 0.0})

   glEnable(GL_LIGHT1)
   glLightfv(GL_LIGHT1, GL_AMBIENT, {0.2, 0.2, 0.2, 1})
   glLightfv(GL_LIGHT1, GL_DIFFUSE, {1, 1, 1, 1})
   glLightfv(GL_LIGHT1, GL_POSITION, {1.0, 0.0, 1.0, 0.0})

   glLightModelf(GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE)
   glFrontFace(GL_CW)
end

function resize_func(w, h)
   local ratio = w / h
   glMatrixMode(GL_PROJECTION)
   glLoadIdentity()
   glViewport(0,0,w,h)
   gluPerspective(45,ratio,1,1000)
   glMatrixMode(GL_MODELVIEW)
   glLoadIdentity()
   set_material_clay()
   glEnable(GL_DEPTH_TEST)
   glEnable(GL_NORMALIZE)
end

function timer_func()
   if quit then return end
   
      glutSetWindow(window)
      glutTimerFunc(msec, timer_func, 0)
      glutPostRedisplay()
end

function display_func()
   if quit then return end

   glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- use shader
   glUseProgram(ProgramID);



  -- 绘制贴图
  
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, tex_face);
  -- 设置shader参数
  glUniform1i(glGetUniformLocation(ProgramID, "texture1"), 0);
  glUniform1i(glGetUniformLocation(ProgramID, "texture2"), 1);

  glBindVertexArray(vao);
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, {});
  
  glBindVertexArray(0);

   glutSwapBuffers()
end

-- press ESC to exit
function keyboard_func(key,x,y)
   if key == 27 then
      quit = true
      glutDestroyWindow(window)
      os.exit(0)
   end
end

glutInit(arg)
glutInitDisplayMode(GLUT_RGB + GLUT_DOUBLE + GLUT_DEPTH)
if arg then title = arg[0] else title = "glut" end
window = glutCreateWindow(title)

-- >> init glew and shader
glewInit()
ProgramID = LoadShader(vertex_source, fragment_source);
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(1);
local VAO_ARRAY = glGenVertexArrays(1);
local VEO_ARRAY = glGenBuffers(1);
vbo = VBO_ARRAY[1];
vao = VAO_ARRAY[1];
veo = VEO_ARRAY[1];
local vertices = {
  -- position      color      texture coord
  0.5, 0.5, 0.0,   1,0,0,     1.0, 1.0,
  0.5, -0.5, 0.0,  0,1,0,     1.0, 0.0,
  -0.5, -0.5, 0.0, 0,0,1,     0.0, 0.0,
  -0.5,0.5,0.0,    1,1,0,     0.0, 1.0,  
};
local indices = 
{
  0, 1, 3,
  1, 2, 3
};

glBindVertexArray(vao);

glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, veo);
glBufferFormatedData(GL_ELEMENT_ARRAY_BUFFER, GL_INT, indices, GL_STATIC_DRAW);

-- (position)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 32, 0);
glEnableVertexAttribArray(0);
-- (color)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 32, 12);
glEnableVertexAttribArray(1);
-- (texture)
glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 32, 24);
glEnableVertexAttribArray(2);

-- 加载第一个贴图
local textures = glGenTextures(2);
texture = textures[1];
glBindTexture(GL_TEXTURE_2D, texture);

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

local succ,width,height,data = stbi_load("resources/textures/container.jpg");
--succ,width,height,data = stbi_load("resources/textures/container.jpg");
--local succ = 1;
--succ = stbi_load("resources/textures/container.jpg");
if(succ == 1)
then
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
  glGenerateMipmap(GL_TEXTURE_2D);
  stbi_image_free(data);
else
  print('load texture failed.' .. succ);
end

-- 加载第二个贴图
tex_face = textures[2];
glBindTexture(GL_TEXTURE_2D, tex_face);

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

succ,width,height,data = stbi_load("resources/textures/awesomeface.png");
if(succ == 1)
then
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
  glGenerateMipmap(GL_TEXTURE_2D);
  stbi_image_free(data);
else
  print('load texture failed.' .. succ);
end


--glBindBuffer(GL_ARRAY_BUFFER, 0);
--glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
--glBindVertexArray(0);
--glBindTexture(GL_TEXTURE_2D, 0);


-- << 数据准备完毕


glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)

glutMainLoop()
