-- 深度测试

print('_VERSION = ' .. _VERSION)

require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglm'
print('luaglm.VERSION = '   .. luaglm.VERSION)

require 'lib/libre_util'
require 'lib/Camera'
require 'lib/Shader'

local quit = false
local fps = 60
local msec = 1000 / fps

local myshader;

local vbo, vao;

local currentfile = 'advanced_opengl/9.1.geometry_shader_houses'
-- local currentfile = 'lighting/1.colors'

local LastX, LastY;
  

function resize_func(w, h)
  --[[
   local ratio = w / h
   glMatrixMode(GL_PROJECTION)
   glLoadIdentity()
   ]]--
   print('viewport:' .. w .. ',' .. h);
   glViewport(0,0,w,h)
   --[[
   gluPerspective(45,ratio,1,1000)
   glMatrixMode(GL_MODELVIEW)
   glLoadIdentity()
   set_material_clay()
   ]]--
   --glEnable(GL_DEPTH_TEST)
   --glEnable(GL_NORMALIZE)
end

function timer_func()
   if quit then return end
   
      glutSetWindow(window)
      glutTimerFunc(msec, timer_func, 0)
      glutPostRedisplay()
end

function display_func()
  if quit then return end
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  
  
  myshader:use();  
  glBindVertexArray(vao);
  glDrawArrays(GL_POINTS, 0, 4);
  

  glutSwapBuffers()
end

function mouse_func(button, updown, x, y)
  LastX = x;
  LastY = y;
  -- print(string.format('button:%d, updown:%d, x:%d, y:%d', button, updown, x, y));
end

function motion_func(x, y)
  -- print(string.format('x:%d, y:%d', x, y));
  camera:ProcessMouseMovement(x - LastX, LastY - y);
  LastX = x;
  LastY = y;  
end

-- press ESC to exit
function keyboard_func(key,x,y)
  
  print('key' .. key);
  
   if key == 27 then
      quit = true
      glutDestroyWindow(window)
      os.exit(0)
   end
   
    if key == 119 then
      camera:ProcessKeyboard(0)
    end
    if key == 115 then
      camera:ProcessKeyboard(1)
    end
    if key == 97 then
      camera:ProcessKeyboard(2)
    end
    if key == 100 then
      camera:ProcessKeyboard(3)
    end
    
    if key == 91 then
      camera:ProcessMouseScroll(1);
    end
    if key == 93 then
      camera:ProcessMouseScroll(-1);
    end
end

glutInit(arg)
glutInitDisplayMode(GLUT_RGB + GLUT_DOUBLE + GLUT_DEPTH)
if arg then title = arg[0] else title = "glut" end
window = glutCreateWindow(title)
glutReshapeWindow(800,600);

-- >> init glew and shader
glewInit()
glEnable(GL_DEPTH_TEST);

myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs', currentfile .. '.gs');
-- << init end

-- >> 准备数据，绘制一些点
local VBO_ARRAY = glGenBuffers(1);
local VAO_ARRAY = glGenVertexArrays(1);
vbo = VBO_ARRAY[1];
vao = VAO_ARRAY[1];
local vertices = 
    {
        -0.5,  0.5, 1.0, 0.0, 0.0,
         0.5,  0.5, 0.0, 1.0, 0.0,
         0.5, -0.5, 0.0, 0.0, 1.0,
        -0.5, -0.5, 1.0, 1.0, 0.0 
    };


glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindVertexArray(vao);
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 2 * sizeof_float());
glEnableVertexAttribArray(1);

-- << 数据准备完毕

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
