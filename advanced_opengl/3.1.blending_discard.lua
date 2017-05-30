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

local lightingShader, lampShader;

local vbo, cubeVAO, lightVAO;
local planeVBO, planeVAO;
local transparencyVBO, transparencyVAO;

local currentfile = 'advanced_opengl/3.1.blending_discard'
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
local transparentVertices = 
  {
        0.0,  0.5,  0.0,  0.0,  0.0,
        0.0, -0.5,  0.0,  0.0,  1.0,
        1.0, -0.5,  0.0,  1.0,  1.0,

        0.0,  0.5,  0.0,  0.0,  0.0,
        1.0, -0.5,  0.0,  1.0,  1.0,
        1.0,  0.5,  0.0,  1.0,  0.0
  };
local cubeTexture, floorTexture, transparencyTexture; 
  
local vegetation = 
  {
        glm.vec3:new(-1.5, 0.0, -0.48),
        glm.vec3:new( 1.5, 0.0, 0.51),
        glm.vec3:new( 0.0, 0.0, 0.7),
        glm.vec3:new(-0.3, 0.0, -2.3),
        glm.vec3:new (0.5, 0.0, -0.6)
  };  

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

  
  
  lightingShader:use();  
  -- sample2d用SetInt代替，值1与下面的glActiveTexture(GL_TEXTURE1)相对应
  lightingShader:SetInt("ourTexture", 0);
  

  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  local view = camera:GetViewMatrix();
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

  -- 带有透明度的草
  glBindVertexArray(transparencyVAO);
  glBindTexture(GL_TEXTURE_2D, transparencyTexture);
  for i=1,5,1
  do
    model = glm.mat4:new();
    model = glm.translate(model, vegetation[i]);
    --print('vegatation:' .. Vec3ToString(vegetation[i]));
    lightingShader:setMat4("model", model);
    glDrawArrays(GL_TRIANGLES, 0, 6);
  end


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
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(3);
local VAO_ARRAY = glGenVertexArrays(3);
vbo = VBO_ARRAY[1];
cubeVAO = VAO_ARRAY[1];
planeVBO = VBO_ARRAY[2];
planeVAO = VAO_ARRAY[2];
transparencyVBO = VBO_ARRAY[3];
transparencyVAO = VAO_ARRAY[3];

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

glBindBuffer(GL_ARRAY_BUFFER, transparencyVBO);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, transparentVertices, GL_STATIC_DRAW);

glBindVertexArray(transparencyVAO);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 3 * sizeof_float());
glEnableVertexAttribArray(1);


-- << 数据准备完毕

cubeTexture = LoadTexture("resources/textures/marble.jpg");
floorTexture = LoadTexture("resources/textures/metal.png");
transparencyTexture = LoadTexture("resources/textures/grass.png");

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
