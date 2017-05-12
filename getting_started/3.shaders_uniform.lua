-- vim: set ts=3 et:

print('_VERSION = ' .. _VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'lib/libre_util'

local quit = false
local fps = 15
local msec = 1000 / fps

local ProgramID;
local vid;
local fid;

local vbo, vao;

local currentfile = 'getting_started/3.shaders_uniform'

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

  -- 修改shader属性
  local time = glutGet(GLUT_ELAPSED_TIME);
  local g = math.sin(math.rad(time)) / 2.0 + 0.5
  -- 修改shader中的ourColor属性
  local vertexColorLocation = glGetUniformLocation(ProgramID, "ourColor");
  glUniform4f(vertexColorLocation, 0.0, g, 0.0, 1.0);

  -- 绘制三角形
  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLES, 0, 3);
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
vbo = VBO_ARRAY[1];
vao = VAO_ARRAY[1];
local vertices = {-0.5, -0.5, 0.0, 
                  0.5, -0.5, 0.0, 
                  0.0, 0.5, 0.0}

glBindVertexArray(vao);

glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 12, 0);
glEnableVertexAttribArray(0);

glBindBuffer(GL_ARRAY_BUFFER, 0);
glBindVertexArray(0);


-- << 数据准备完毕


glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)

glutMainLoop()
