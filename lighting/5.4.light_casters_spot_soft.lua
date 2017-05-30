-- 方向光

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

local currentfile = 'lighting/5.4.light_casters_spot_soft'
-- local currentfile = 'lighting/1.colors'

local LastX, LastY;
local diffuseMap;
local specularMap;
local cubePositions = 
  {
    glm.vec3:new( 0.0,  0.0,  0.0),
    glm.vec3:new( 2.0,  5.0, -15.0),
    glm.vec3:new(-1.5, -2.2, -2.5),
    glm.vec3:new(-3.8, -2.0, -12.3),
    glm.vec3:new( 2.4, -0.4, -3.5),
    glm.vec3:new(-1.7,  3.0, -7.5),
    glm.vec3:new( 1.3, -2.0, -2.5),
    glm.vec3:new( 1.5,  2.0, -2.5),
    glm.vec3:new( 1.5,  0.2, -1.5),
    glm.vec3:new(-1.3,  1.0, -1.5)
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
  
  glClearColor(0.2, 0.3, 0.3, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  
  
  lightingShader:use();
  -- 设置聚光灯的属性：位置，朝向，cutoff
  lightingShader:setVec3("light.position", camera.Position);
  lightingShader:setVec3("light.direction", camera.Front);
  lightingShader:SetFloat("light.cutOff", math.cos(glm.radians(12.5)));
  lightingShader:SetFloat("light.outerCutOff", math.cos(glm.radians(17.5)));
  
  lightingShader:setVec3("light.ambient", 0.1,0.1,0.1);
  lightingShader:setVec3("light.diffuse", 0.8,0.8,0.8);
  lightingShader:setVec3("light.specular", 1.0, 1.0, 1.0);
  lightingShader:SetFloat("light.constant", 1);
  lightingShader:SetFloat("light.linear", 0.09);
  lightingShader:SetFloat("light.quadratic", 0.032);
  
  
  -- 设置观察者方向，用来计算高光的
  lightingShader:setVec3("viewPos", camera.Position);
  
  -- sample2d用SetInt代替，值1与下面的glActiveTexture(GL_TEXTURE1)相对应
  lightingShader:SetInt("material.diffuse", 0);
  lightingShader:SetInt("material.specular", 1);  
  
  lightingShader:SetFloat("material.shininess", 32);

  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  local view = camera:GetViewMatrix();
  lightingShader:setMat4("projection", projection);
  lightingShader:setMat4("view", view);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, diffuseMap);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, specularMap);

  -- 绘制箱子
  glBindVertexArray(cubeVAO);
  
  for i=1,table.getn(cubePositions),1
  do    
    local model = glm.mat4:new();
    local angle = 20 * i;    
    model = glm.translate(model, cubePositions[i]);
    model = glm.rotate(model, glm.radians(angle), glm.vec3:new(1.0,0.3,0.5));
    lightingShader:setMat4("model", model);    
    glDrawArrays(GL_TRIANGLES, 0, 36);
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
print(glGetString(GL_VERSION));
glEnable(GL_DEPTH_TEST);
lampShader = Shader:new(currentfile .. '.lamp.vs', currentfile .. '.lamp.fs');
lightingShader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(1);
local VAO_ARRAY = glGenVertexArrays(2);
vbo = VBO_ARRAY[1];
cubeVAO = VAO_ARRAY[1];
lightVAO = VAO_ARRAY[2];
local vertices = 
    {
    --  // positions          // normals           // texture coords
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  0.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  1.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  1.0,
        -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  1.0,
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  0.0,

        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  0.0,
         0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  1.0,
        -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  1.0,
        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  0.0,

        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0,  0.0,
        -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0,  1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0,  1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0,  1.0,
        -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0,  0.0,
        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0,  0.0,

         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0,  0.0,
         0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0,  1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0,  1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0,  1.0,
         0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0,  0.0,
         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0,  0.0,

        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0,  1.0,
         0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0,  1.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0,  0.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0,  0.0,
        -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0,  0.0,
        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0,  1.0,

        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0,  1.0,
         0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0,  0.0,
        -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0,  0.0,
        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0,  1.0
    };


glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindVertexArray(cubeVAO);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 3 * sizeof_float());
glEnableVertexAttribArray(1);
glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 6 * sizeof_float());
glEnableVertexAttribArray(2);

glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBindVertexArray(lightVAO);

glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
-- << 数据准备完毕

diffuseMap = LoadTexture("resources/textures/container2.png");
specularMap = LoadTexture("resources/textures/container2_specular.png");

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
