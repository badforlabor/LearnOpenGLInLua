
-- 基本的渲染框架
-- 引用该框架之后，只需要定义函数 OnInit(), OnKey(key), OnDraw(), OnQuit() 函数即可。

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

mainCamera = Camera:new();
mainCamera.Position.x = 0;
mainCamera.Position.y = 0;
mainCamera.Position.z = 3;
mainCamera:updateCameraVectors();

SCREEN_WIDTH = 1280;
SCREEN_HEIGHT = 720;

local quit = false
local fps = 60
local msec = 1000 / fps

-- local currentfile = 'lighting/1.colors'

local LastX;
local LastY;

function display_func()
  if quit then return end
  
  -- 外部接口，绘制
  if OnDraw then OnDraw(); end

  glutSwapBuffers()
end

function OnPressKey(key)
    if (OnKey) then OnKey(key); end
end
  

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

function mouse_func(button, updown, x, y)
  LastX = x;
  LastY = y;
  -- print(string.format('button:%d, updown:%d, x:%d, y:%d', button, updown, x, y));
end

function motion_func(x, y)
  -- print(string.format('x:%d, y:%d', x, y));
  mainCamera:ProcessMouseMovement(x - LastX, LastY - y);
  LastX = x;
  LastY = y;  
end

-- press ESC to exit
function keyboard_func(key,x,y)
  
  print('key' .. key .. ', char:' .. string.char(key));
  
   if key == 27 then
      quit = true
      glutDestroyWindow(window)
      os.exit(0)
   end
   
    if key == 119 then
      mainCamera:ProcessKeyboard(0)
    end
    if key == 115 then
      mainCamera:ProcessKeyboard(1)
    end
    if key == 97 then
      mainCamera:ProcessKeyboard(2)
    end
    if key == 100 then
      mainCamera:ProcessKeyboard(3)
    end
    
    if key == 91 then
      mainCamera:ProcessMouseScroll(1);
    end
    if key == 93 then
      mainCamera:ProcessMouseScroll(-1);
    end

    -- 按键'B'
    --if key == 98 then OnPressKey('b') end;
    --if key == 110 then OnPressKey('n') end;

    OnPressKey(string.char(key));
end

function glutGetTime()
  return glutGet(GLUT_ELAPSED_TIME) / 1000.0;
end

function glMain()

    glutInit(arg)
    glutInitDisplayMode(GLUT_RGB + GLUT_DOUBLE + GLUT_DEPTH)
    if arg then title = arg[0] else title = "glut" end
    window = glutCreateWindow(title)

    -- >> init glew and shader
    glewInit()
    -- << init end

    -- 显示电脑的GL版本号，如果版本号小于4，会显示异常（shader不支持）
    print('GL Version=' .. glGetString(GL_VERSION))

    -- 外部接口，准备数据
    if OnInit then OnInit(); end

    glutReshapeWindow(SCREEN_WIDTH, SCREEN_HEIGHT);

    glutDisplayFunc(display_func)
    glutKeyboardFunc(keyboard_func)
    glutReshapeFunc(resize_func)
    glutTimerFunc(msec, timer_func, 0)
    glutMouseFunc(mouse_func);
    glutMotionFunc(motion_func);

    glutMainLoop()

    -- 游戏退出后，清理
    if OnQuit then OnQuit(); end
end
