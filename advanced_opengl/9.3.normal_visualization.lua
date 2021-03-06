-- 深度测试

print('_VERSION = ' .. _VERSION)

require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)

require 'luaglm'
print('luaglm.VERSION = '   .. luaglm.VERSION)

require 'luamesh'
print('luamesh.VERSION = '   .. luamesh.VERSION)

require 'lib/libre_util'
require 'lib/Camera'
require 'lib/Shader'

local camera = Camera:new();
camera.Position.x = 0.6;
camera.Position.y = 5.6;
camera.Position.z = 22.7;
camera:updateCameraVectors();

local quit = false
local fps = 60
local msec = 1000 / fps

local myshader, normalShader;

local vbo, vao;

local currentfile = 'advanced_opengl/9.3.normal_visualization'
-- local currentfile = 'lighting/1.colors'

local LastX, LastY;
local myModel;
  

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

  -- 正常绘制一个模型
  myshader:use();  
  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  local view = camera:GetViewMatrix();
  local model = glm.mat4:new();
  myshader:setMat4("projection", projection);
  myshader:setMat4("view", view);
  myshader:setMat4("model", model);    
  myModel:Draw(myshader.ID);
  
  -- 绘制模型的法线
  normalShader:use();
  normalShader:setMat4("projection", projection);
  normalShader:setMat4("view", view);
  normalShader:setMat4("model", model);
  normalShader:SetFloat("factor", 1 * (0.5 + 0.5 * math.sin(glutGet(GLUT_ELAPSED_TIME) * 0.001)));
  myModel:Draw(normalShader.ID);

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

myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
normalShader = Shader:new(currentfile .. '.normal.vs', currentfile .. '.normal.fs', currentfile .. '.normal.gs');
-- << init end

-- >> 准备数据，绘制一些点

myModel = libre.Model:new("resources/objects/nanosuit/nanosuit.obj");

-- << 数据准备完毕

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
