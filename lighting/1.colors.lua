-- vim: set ts=3 et:

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


local camera = Camera:new();
camera.Position.x = 0;
camera.Position.y = 0;
camera.Position.z = 3;
camera:updateCameraVectors();

lightPos = glm.vec3:new(1.1, 1, 2.0);

local quit = false
local fps = 60
local msec = 1000 / fps

local lightingShader, lampShader;

local vbo, cubeVAO, lightVAO;

local currentfile = 'lighting/1.colors'

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


  --glViewport(0,0,800,600);
	--	glMatrixMode(GL_PROJECTION);
	--	glLoadIdentity();
	--	glMatrixMode(GL_MODELVIEW);
	--	glLoadIdentity();

  glClearColor(0.2, 0.3, 0.3, 1.0);
  --glClearColor(0, 0, 0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
  
  -- 设置物体的位置
  lightingShader:use();
  lightingShader:SetVec3("objectColor", 1.0, 0.5, 0.31);
  lightingShader:SetVec3("lightColor", 1.0, 1.0, 1.0);

  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  local view = camera:GetViewMatrix();
  local model = glm.mat4:new();
  lightingShader:SetMat4("projection", projection);
  lightingShader:SetMat4("view", view);
  lightingShader:SetMat4("model", model);
  
  --print('proj:' .. Mat4ToString(projection));
  --print('view:' .. Mat4ToString(view));
  --print('model:' .. Mat4ToString(model));
  --print('rotate:' .. camera.Yaw .. ', ' .. camera.Pitch);
  --print('pos:' .. Vec3ToString(camera.Position));
  --print('front:' .. Vec3ToString(camera.Front));
  --print('up:' .. Vec3ToString(camera.Up));

  -- 绘制三角形
  glBindVertexArray(cubeVAO);
  glDrawArrays(GL_TRIANGLES, 0, 36);

  -- 设置灯的位置

  lampShader:Use();

  model = glm.mat4:new();
  model = glm.translate(model, lightPos);
  model = glm.scale(model, glm.vec3:new(0.2,0.2,0.2));
  
  lampShader:SetMat4("projection", projection);
  lampShader:SetMat4("view", view);
  lampShader:SetMat4("model", model);
  
  --print('- proj:' .. Mat4ToString(projection));
  --print('- view:' .. Mat4ToString(view));
  --print('- model:' .. Mat4ToString(model));

  -- print('proj=' .. Mat4ToString(projection));
  -- print('view=' .. Mat4ToString(view));
  -- print('model=' .. Mat4ToString(model));
  -- 绘制三角形
  glBindVertexArray(lightVAO);
  glDrawArrays(GL_TRIANGLES, 0, 36);


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
local a = glewInit();
print('glewInit:' .. a);
glEnable(GL_DEPTH_TEST);

print('gl version:' .. glGetString(GL_VERSION));

lightingShader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
lampShader = Shader:new(currentfile .. '.lamp.vs', currentfile .. '.lamp.fs');
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(1);
local VAO_ARRAY = glGenVertexArrays(2);
vbo = VBO_ARRAY[1];
cubeVAO = VAO_ARRAY[1];
lightVAO = VAO_ARRAY[2];
local vertices = 
    {
        -0.5, -0.5, -0.5, 
         0.5, -0.5, -0.5,  
         0.5,  0.5, -0.5,  
         0.5,  0.5, -0.5,  
        -0.5,  0.5, -0.5, 
        -0.5, -0.5, -0.5, 

        -0.5, -0.5,  0.5, 
         0.5, -0.5,  0.5,  
         0.5,  0.5,  0.5,  
         0.5,  0.5,  0.5,  
        -0.5,  0.5,  0.5, 
        -0.5, -0.5,  0.5, 

        -0.5,  0.5,  0.5, 
        -0.5,  0.5, -0.5, 
        -0.5, -0.5, -0.5, 
        -0.5, -0.5, -0.5, 
        -0.5, -0.5,  0.5, 
        -0.5,  0.5,  0.5, 

         0.5,  0.5,  0.5,  
         0.5,  0.5, -0.5,  
         0.5, -0.5, -0.5,  
         0.5, -0.5, -0.5,  
         0.5, -0.5,  0.5,  
         0.5,  0.5,  0.5,  

        -0.5, -0.5, -0.5, 
         0.5, -0.5, -0.5,  
         0.5, -0.5,  0.5,  
         0.5, -0.5,  0.5,  
        -0.5, -0.5,  0.5, 
        -0.5, -0.5, -0.5, 

        -0.5,  0.5, -0.5, 
         0.5,  0.5, -0.5,  
         0.5,  0.5,  0.5,  
         0.5,  0.5,  0.5,  
        -0.5,  0.5,  0.5, 
        -0.5,  0.5, -0.5, 
    };

glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindVertexArray(cubeVAO);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof_float(), 0);
glEnableVertexAttribArray(0);

glBindVertexArray(lightVAO);
glBindBuffer(GL_ARRAY_BUFFER, vbo);

glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
-- << 数据准备完毕

print(string.format("vbo: %d,%d,%d \n", vbo, cubeVAO, lightVAO));

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
