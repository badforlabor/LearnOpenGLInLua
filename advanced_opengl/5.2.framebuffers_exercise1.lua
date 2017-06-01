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


local camera = Camera:new();
camera.Position.x = 0;
camera.Position.y = 0;
camera.Position.z = 3;
camera:updateCameraVectors();

lightPos = glm.vec3:new(1.2, 1, 2.0);

local quit = false
local fps = 60
local msec = 1000 / fps

local lightingShader, textureColorBuffer;

local vbo, cubeVAO, lightVAO;
local planeVBO, planeVAO;
local quadVBO, quadVAO;

local framebuffer, rbo;
local screen_width = 800;
local screen_height = 600;

local currentfile = 'advanced_opengl/5.2.framebuffers_exercise1'
-- local currentfile = 'lighting/1.colors'

local LastX, LastY;

local planeVertices = 
  {
         5.0, -0.5,  5.0,  2.0, 0.0,
        -5.0, -0.5,  5.0,  0.0, 0.0,
        -5.0, -0.5, -5.0,  0.0, 2.0,

         5.0, -0.5,  5.0,  2.0, 0.0,
        -5.0, -0.5, -5.0,  0.0, 2.0,
         5.0, -0.5, -5.0,  2.0, 2.0	
  };
local quadVertices = 
  {
        -0.5,  1.0,  0.0, 1.0,
        -0.5,  0,  0.0, 0.0,
         0.5,  0,  1.0, 0.0,

        -0.5,  1.0,  0.0, 1.0,
         0.5,  0,  1.0, 0.0,
         0.5,  1.0,  1.0, 1.0
  };
 local cubeTexture, floorTexture; 
  

function resize_func(w, h)
  --[[
   local ratio = w / h
   glMatrixMode(GL_PROJECTION)
   glLoadIdentity()
   ]]--
   print('viewport:' .. w .. ',' .. h);
   glViewport(0,0,w,h);
   screen_width = w;
   screen_height = h;
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
  
  -- 制作一个镜面效果。先绘制所有内容到framebuffer上，然后再绘制所有内容到屏幕，并且绘制framebuffer到屏幕。

  -- 将所有内容都绘制到framebuffer上。
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glEnable(GL_DEPTH_TEST);

  --glClearColor(0.1, 0.1, 0.1, 1.0);
  glClearColor(0,0.5,0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)  
  
  lightingShader:use();  
  -- sample2d用SetInt代替，值1与下面的glActiveTexture(GL_TEXTURE1)相对应
  lightingShader:SetInt("texture1", 0);
  
  camera.Yaw = camera.Yaw + 180;
  camera.Pitch = camera.Pitch + 180;
  camera:updateCameraVectors();
  local view = camera:GetViewMatrix();
  camera.Yaw = camera.Yaw - 180;
  camera.Pitch = camera.Pitch - 180;
  camera:updateCameraVectors();

  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  lightingShader:setMat4("projection", projection);
  lightingShader:setMat4("view", view);
  
  local model = glm.mat4:new();

  glActiveTexture(GL_TEXTURE0);
  
  -- cubes
  glBindVertexArray(cubeVAO);
  glBindTexture(GL_TEXTURE_2D, cubeTexture);
  model = glm.translate(model, glm.vec3:new(-1,0,-1));
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 36);
  
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(2,0,0));
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 36);
  
  -- floor
  glBindVertexArray(planeVAO);
  glBindTexture(GL_TEXTURE_2D, floorTexture);
  model = glm.mat4:new();
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);

  -- 将原有内容绘制到屏幕上
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glClearColor(0.1,0.1,0.1,1);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  -- cubes
  model = glm.mat4:new();
  glBindVertexArray(cubeVAO);
  glBindTexture(GL_TEXTURE_2D, cubeTexture);
  model = glm.translate(model, glm.vec3:new(-1,0,-1));
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 36);
  
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(2,0,0));
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 36);
  
  -- floor
  glBindVertexArray(planeVAO);
  glBindTexture(GL_TEXTURE_2D, floorTexture);
  model = glm.mat4:new();
  lightingShader:SetMat4("model", model);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);
  

  -- 将framebuffer的内容也绘制到屏幕上
  glDisable(GL_DEPTH_TEST);

  screenShader:use();
  screenShader:SetInt('texture1', 0);
  glActiveTexture(GL_TEXTURE0);
  glBindVertexArray(quadVAO);
  glBindTexture(GL_TEXTURE_2D, textureColorBuffer);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  
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
-- glDepthFunc(GL_ALWAYS);
glDepthFunc(GL_LESS);

lightingShader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
screenShader = Shader:new(currentfile .. '_screen.vs', currentfile .. '_screen.fs');
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(3);
local VAO_ARRAY = glGenVertexArrays(3);
vbo = VBO_ARRAY[1];
cubeVAO = VAO_ARRAY[1];
planeVBO = VBO_ARRAY[2];
planeVAO = VAO_ARRAY[2];
quadVBO = VBO_ARRAY[3];
quadVAO = VAO_ARRAY[3];
local vertices = 
    {
    --  // positions     // texture coords
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    };


glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindVertexArray(cubeVAO);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 3 * sizeof_float());
glEnableVertexAttribArray(1);

glBindBuffer(GL_ARRAY_BUFFER, planeVBO);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, planeVertices, GL_STATIC_DRAW);

glBindVertexArray(planeVAO);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 3 * sizeof_float());
glEnableVertexAttribArray(1);

glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, quadVertices, GL_STATIC_DRAW);

glBindVertexArray(quadVAO);
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof_float(), 2 * sizeof_float());
glEnableVertexAttribArray(1);

-- 准备framebuffer和renderbuffer
local framebuffers = glGenFramebuffers(1);
framebuffer = framebuffers[1];
print('framebuffer:' .. framebuffer);
glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
local textureColorBuffers = glGenTextures(1);
textureColorBuffer = textureColorBuffers[1];
print('textureColorBuffer:' .. textureColorBuffer);
glBindTexture(GL_TEXTURE_2D, textureColorBuffer);
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screen_width, screen_height, 0, GL_RGB, GL_UNSIGNED_BYTE, nil);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,textureColorBuffer,0);
local rbos = glGenRenderbuffers(1);
local rbo = rbos[1];
glBindRenderbuffer(GL_RENDERBUFFER, rbo);
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, screen_width, screen_height);
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);
if(glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE)
then
  print('failed frame buffer');
end
glBindFramebuffer(GL_FRAMEBUFFER, 0);

-- << 数据准备完毕

cubeTexture = LoadTexture("resources/textures/marble.jpg");
floorTexture = LoadTexture("resources/textures/metal.png");

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
