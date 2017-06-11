-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(0,0,0);

local myshader;
local depthShader;

local vbo, vao;

local currentfile = 'advanced_lighting/3.4.point_shadows'
-- local currentfile = 'lighting/1.colors'

local floorTexture;
local debug_depth = 0;
local shadowFactor = 1;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local depthMapFBO, depthCubemap;
local nearPlane = 1.0
local farPlane = 25;

function OnInit()

  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;

  glEnable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_CULL_FACE);

  myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  depthShader = Shader:new(currentfile .. '.depth.vs', currentfile .. '.depth.fs', currentfile .. '.depth.gs');

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
  depthCubemap = textures[1];
  glBindTexture(GL_TEXTURE_2D, depthCubemap);
  -- 作为depth buffer用。
  for i=1,10,1
  do
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_DEPTH_COMPONENT, SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
  end

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
  glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
  glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, depthCubemap, 0);
  -- drawbuffer和readbuffer的目的是，提交一次渲染，让depthbuffer生效。
  glDrawBuffer(GL_NONE);
  glReadBuffer(GL_NONE);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 
  myshader:use();
  myshader:SetInt("diffuseTexture", 0);
  myshader:SetInt("shadowMap", 1);

end

function OnDraw()
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  lightPos.z = math.sin(glutGetTime() * 0.5) * 3.0;

  -- 准备cubemap的数据
  local shadowProj = glm.perspective(glm.radians(90), 1.0 * SHADOW_WIDTH / SHADOW_HEIGHT, nearPlane, farPlane);
  local shadowTransforms = 
  {
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3( 1,0,0), glm.vec3(0,-1,0)),  
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3(-1,0,0), glm.vec3(0,-1,0)),
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3(0, 1,0), glm.vec3(0,0, 1)),
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3(0,-1,0), glm.vec3(0,0,-1)),
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3(0,0, 1), glm.vec3(0,-1,0)),
    shadowProj * glm.lookAt(lightPos, lightPos + glm.vec3(0,0,-1), glm.vec3(0,-1,0))
  };

  -- 渲染场景到cubemap上
  glViewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT);
  glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
    glClear(GL_DEPTH_BUFFER_BIT);
    depthShader:use();
    for i=1,6,1
    do
      depthShader:SetMat4("shadowMatrices[" .. (i-1) .. "]", shadowTransforms[i]);
    end
    depthShader:SetFloat("far_plane", farPlane);
    depthShader:SetVec3("lightPos", lightPos);
    renderScene(depthShader);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 正常绘制
  glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  myshader:use();
  local projection = glm.perspective(mainCamera.Zoom, 1.0 * SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100);
  local view = mainCamera:GetViewMatrix();
  myshader:SetMat4("projection", projection);
  myshader:SetMat4("view", view);
  myshader:SetVec3("lightPos", lightPos);
  myshader:SetVec3("viewPos", mainCamera.Position);
  myshader:SetInt("shadows", shadowFactor);
  myshader:SetFloat("far_plane", farPlane);
  myshader:SetInt("diffuseTexture", 0);
  myshader:SetInt("depthMap", 1);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE0, floorTexture);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE1, depthCubemap);
  renderScene(myshader);

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

  -- 
  model = glm.mat4:new();
  model = glm.scale(model, glm.vec3:new(5,5,5));
  tempShader:SetMat4("model", model);
  glDisable(GL_CULL_FACE);
  tempShader:SetInt("reverse_normals", 1);
  renderCube();
  tempShader:SetInt("reverse_normals", 0);
  glEnable(GL_CULL_FACE);

  -- 绘制地板上的箱子
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(4,-3.5,0));
  model = glm.scale(model, glm.vec3:new(0.5,0.5,0.5));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(2,3,1.0));
  model = glm.scale(model, glm.vec3:new(0.75,0.75,0.75));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(-3,-1,0));
  model = glm.rotate(model, glm.radians(60), glm.normalize(glm.vec3:new(1,0,1)));
  model = glm.scale(model, glm.vec3:new(0.5,0.5,0.5));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(-1.5,1.0,1.5));
  model = glm.rotate(model, glm.radians(60), glm.normalize(glm.vec3:new(1,0,1)));
  model = glm.scale(model, glm.vec3:new(0.5,0.5,0.5));
  tempShader:SetMat4("model", model);
  renderCube();
  model = glm.mat4:new();
  model = glm.translate(model, glm.vec3:new(-1.5,2.0,-3.0));
  model = glm.rotate(model, glm.radians(60), glm.normalize(glm.vec3:new(1,0,1)));
  model = glm.scale(model, glm.vec3:new(0.75,0.75,0.75));
  tempShader:SetMat4("model", model);
  renderCube();
end

  

-- press ESC to exit
function OnKey(key)      
  if key == 'b' then debug_depth = (debug_depth + 1) % 2 end;
  if key == 'n' then shadowFactor = (shadowFactor + 1) % 2 end;
end

glMain();
