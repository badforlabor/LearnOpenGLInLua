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
camera.Position.x = 0;
camera.Position.y = 0;
camera.Position.z = 3;
camera:updateCameraVectors();
local lightPos = glm.vec3:new(-2,4,-1);

local quit = false
local fps = 60
local msec = 1000 / fps
local SCREEN_WIDTH = 1280;
local SCREEN_HEIGHT = 720;

local myshader, debugShader;

local vbo, vao;

local currentfile = 'advanced_lighting/3.1.shadow_mapping_depth'
-- local currentfile = 'lighting/1.colors'

local LastX, LastY;

local planeVertices = 
{
         25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
        -25.0, -0.5,  25.0,  0.0, 1.0, 0.0,   0.0,  0.0,
        -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,

         25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
        -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,
         25.0, -0.5, -25.0,  0.0, 1.0, 0.0,  25.0, 10.0
};
local floorTexture;
local blinn = 1;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local depthMapFBO, depthMap;
local nearPlane = 1.0
local farPlane = 7.5;

function SetData()
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  debugShader = Shader:new(currentfile .. '.debug.vs', currentfile .. '.debug.fs');

  -- >> 准备数据，绘制一些点
  local VBO_ARRAY = glGenBuffers(1);
  local VAO_ARRAY = glGenVertexArrays(1);
  vbo = VBO_ARRAY[1];
  vao = VAO_ARRAY[1];

  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, planeVertices, GL_STATIC_DRAW);

  glBindVertexArray(vao);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 0);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 3 * sizeof_float());
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 6 * sizeof_float());
  glEnableVertexAttribArray(1);

  floorTexture = LoadTexture("resources/textures/wood.png");

  -- << 数据准备完毕

  -- framebuffer，用来将阴影渲染到此buffer上
  local fbs = glGenFramebuffers(1);
  depthMapFBO = fbs[1];
  local textures = glGenTextures(1);
  depthMap = textures[1];
  glBindTexture(GL_TEXTURE_2D, depthMap);
  -- 作为depth buffer用。
  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMap, 0);
  -- drawbuffer和readbuffer的目的是，提交一次渲染，让depthbuffer生效。
  glDrawBuffer(GL_NONE);
  glReadBuffer(GL_NONE);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);



end

local cubeVAO = 0
local cubeVBO = 0;
function renderCube()
  if cubeVAO == 0
  then
    local cubeVertices = 
    {
            -- back ace
            -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-let
             1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
             1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 0.0, -- bottom-right         
             1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
            -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-let
            -1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 1.0, -- top-let
            -- ront ace
            -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-let
             1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 0.0, -- bottom-right
             1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
             1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
            -1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 1.0, -- top-let
            -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-let
            -- let ace
            -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
            -1.0,  1.0, -1.0, -1.0,  0.0,  0.0, 1.0, 1.0, -- top-let
            -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-let
            -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-let
            -1.0, -1.0,  1.0, -1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-right
            -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
            -- right ace
             1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-let
             1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
             1.0,  1.0, -1.0,  1.0,  0.0,  0.0, 1.0, 1.0, -- top-right         
             1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
             1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-let
             1.0, -1.0,  1.0,  1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-let     
            -- bottom ace
            -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
             1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 1.0, 1.0, -- top-let
             1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-let
             1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-let
            -1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 0.0, 0.0, -- bottom-right
            -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
            -- top ace
            -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-let
             1.0,  1.0 , 1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
             1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 1.0, 1.0, -- top-right     
             1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
            -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-let
            -1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 0.0, 0.0  -- bottom-let        
    };
    local vas = glGenVertexArrays(1);
    cubeVAO = vas[1];
    local vbs = glGenBuffers(1);
    cubeVBO = vbs[1];
    glBindBuffer(GL_ARRAY_BUFFER, cubeVBO);
    glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, cubeVertices, GL_STATIC_DRAW);

    glBindVertexArray(cubeVAO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 3 * sizeof_float());
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof_float(), 6 * sizeof_float());
    glEnableVertexAttribArray(2);
  end

  glBindVertexArray(cubeVAO);
  glDrawArrays(GL_TRIANGLES, 0, 36);
  glBindVertexArray(0);
end

local quadVAO = 0;
local quadVBO = 0;
function renderQuad(  )
  
  if quadVAO == 0
  then
    local quadVertices = 
    {
            -1.0,  1.0, 0.0, 0.0, 1.0,
            -1.0, -1.0, 0.0, 0.0, 0.0,
             1.0,  1.0, 0.0, 1.0, 1.0,
             1.0, -1.0, 0.0, 1.0, 0.0,
    };
    local vas = glGenVertexArrays(1);
    quadVAO = vas[1];
    local vbs = glGenBuffers(1);
    quadVBO = vbs[1];

    glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
    glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, quadVertices, GL_STATIC_DRAW);

    glBindVertexArray(quadVAO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof_float(), 3 * sizeof_float());
    glEnableVertexAttribArray(1);
  end

  glBindVertexArray(quadVAO);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glBindVertexArray(0);
end

function renderScene(tempShader)
  local model;
  -- 绘制地板
  model = glm.mat4:new();
  tempShader:SetMat4("model", model);
  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  -- 绘制地板上的箱子
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(0,1.5,0));
  model = glm.scale(model, glm.vec3:new(0.5,0.5,0.5));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(2,0,1.0));
  model = glm.scale(model, glm.vec3:new(0.5,0.5,0.5));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(-1,0,2.0));
  model = glm.rotate(model, glm.radians(60), glm.normalize(glm.vec3:new(1,0,1)));
  model = glm.scale(model, glm.vec3:new(0.25,0.25,0.25));
  tempShader:SetMat4("model", model);
  renderCube();
end



function display_func()
  if quit then return end
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- 以灯光的视角，渲染场景，目的是，获取出场景中物件的深度值
  local lightProjection = glm.ortho(-10, 10, -10, 10, nearPlane, farPlane);
  local lightView = glm.lookAt(lightPos, glm.vec3:new(0,0,0), glm.vec3:new(0,1,0));
  local lightSpaceMatrix = lightProjection * lightView;

  myshader:use();  
  myshader:SetMat4("lightSpaceMatrix", lightSpaceMatrix);
  --myshader:SetInt("")
  glViewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT);
  glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
    glClear(GL_DEPTH_BUFFER_BIT);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, floorTexture);
    renderScene(myshader);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  glViewport(0,0,SCREEN_WIDTH, SCREEN_HEIGHT);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);

  debugShader:use();
  debugShader:SetFloat("nearPlane", nearPlane);
  debugShader:SetFloat("farPlane", farPlane);
  debugShader:SetInt("depthMap", 0);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, depthMap);
  renderQuad();

  glutSwapBuffers()
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

    -- 按键'B'
    if key == 98 then blinn = (blinn + 1) % 2 end;
end

glutInit(arg)
glutInitDisplayMode(GLUT_RGB + GLUT_DOUBLE + GLUT_DEPTH)
if arg then title = arg[0] else title = "glut" end
window = glutCreateWindow(title)
glutReshapeWindow(SCREEN_WIDTH, SCREEN_HEIGHT);

-- >> init glew and shader
glewInit()
-- << init end

SetData();

glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)
glutMouseFunc(mouse_func);
glutMotionFunc(motion_func);

glutMainLoop()
