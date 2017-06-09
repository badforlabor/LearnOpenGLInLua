-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(-2,4,-1);

local myshader;
local debugShader;
local depthShader;

local vbo, vao;

local currentfile = 'advanced_lighting/3.2.shadow_mapping_base'
-- local currentfile = 'lighting/1.colors'

local floorTexture;
local blinn = 1;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local depthMapFBO, depthMap;
local nearPlane = 1.0
local farPlane = 7.5;

function OnInit()

  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;

  glEnable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  debugShader = Shader:new(currentfile .. '.debug.vs', currentfile .. '.debug.fs');
  depthShader = Shader:new(currentfile .. '.depth.vs', currentfile .. '.depth.fs');

  -- >> 准备数据，绘制一些点
  local planeVertices = 
  {
          25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
          -25.0, -0.5,  25.0,  0.0, 1.0, 0.0,   0.0,  0.0,
          -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,

          25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
          -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,
          25.0, -0.5, -25.0,  0.0, 1.0, 0.0,  25.0, 10.0
  };
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

  -- 
  myshader:use();
  myshader:SetInt("diffuseTexture", 0);
  myshader:SetInt("shadowMap", 1);
  debugShader:use();
  debugShader:SetInt("depthMap", 0);

end

function OnDraw()
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- 以灯光的视角，渲染场景，目的是，获取出场景中物件的深度值
  local lightProjection = glm.ortho(-10, 10, -10, 10, nearPlane, farPlane);
  local lightView = glm.lookAt(lightPos, glm.vec3:new(0,0,0), glm.vec3:new(0,1,0));
  local lightSpaceMatrix = lightProjection * lightView;

  -- 渲染深度值到fbo上
  depthShader:use();  
  depthShader:SetMat4("lightSpaceMatrix", lightSpaceMatrix);
  --myshader:SetInt("")
  glViewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT);
  glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
    glClear(GL_DEPTH_BUFFER_BIT);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, floorTexture);
    renderScene(depthShader);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 绘制场景  
  glViewport(0,0,SCREEN_WIDTH, SCREEN_HEIGHT);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  myshader:use();
  local projection = glm.perspective(mainCamera.Zoom, 1.0 * SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100);
  local view = mainCamera:GetViewMatrix();
  myshader:SetMat4("projection", projection);
  myshader:SetMat4("view", view);
  myshader:SetVec3("viewPos", mainCamera.Position);
  myshader:SetVec3("lightPos", lightPos);
  myshader:SetMat4("lightSpaceMatrix", lightSpaceMatrix);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, floorTexture);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, depthMap);
  renderScene(myshader, nil);

  -- 调试
  local debug_depth = false;
  if debug_depth
  then
    debugShader:use();
    debugShader:SetFloat("nearPlane", nearPlane);
    debugShader:SetFloat("farPlane", farPlane);
    debugShader:SetInt("depthMap", 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, depthMap);
    renderQuad();
  end

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

function renderScene(tempShader, nofloor)
  local model;
  -- 绘制地板
  if nofloor == nil then
  model = glm.mat4:new();
  tempShader:SetMat4("model", model);
  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  end
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

  

-- press ESC to exit
function OnKey(key)      
  if key == 'b' then blinn = (blinn + 1) % 2 end;
end

glMain();
