-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(-2,4,-1);

local currentfile = 'advanced_lighting/8.2.deferred_shading_volume'
-- local currentfile = 'lighting/1.colors'

local woodTexture;
local debug_depth = 0;
local shadowFactor = 1;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local hdrFBO;
local colorBuffer;
local nearPlane = 1.0
local farPlane = 7.5;

local lightPositions = {};
local lightColors = {};
local Inverse_normals = 1;
local exposure = 1.0;
local hdr = 1;

local shaderGeometryPass;
local shaderLightingPass;
local shaderLightBox;
local nanosuit;
local objectPositions;

local gBuffer;
local gPosition;
local gNormal;
local gAlbedoSpec;

function OnInit()

  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;

  mainCamera.Position = glm.vec3:new(0,0,5);
  mainCamera:updateCameraVectors();

  glEnable(GL_DEPTH_TEST);
  --glEnable(GL_BLEND);
  --glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  shaderGeometryPass = Shader:new(currentfile .. '.gbuffer.vs', currentfile .. '.gbuffer.fs');
  shaderLightingPass = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  shaderLightBox = Shader:new(currentfile .. '.light_box.vs', currentfile .. '.light_box.fs');

  -- >> 准备数据，绘制一些点
  nanosuit = libre.Model:new("resources/objects/nanosuit/nanosuit.obj");
  objectPositions = 
  {
    glm.vec3:new(-3.0,  -3.0, -3.0),
    glm.vec3:new( 0.0,  -3.0, -3.0),
    glm.vec3:new( 3.0,  -3.0, -3.0),
    glm.vec3:new(-3.0,  -3.0,  0.0),
    glm.vec3:new( 0.0,  -3.0,  0.0),
    glm.vec3:new( 3.0,  -3.0,  0.0),
    glm.vec3:new(-3.0,  -3.0,  3.0),
    glm.vec3:new( 0.0,  -3.0,  3.0),
    glm.vec3:new( 3.0,  -3.0,  3.0)
  }

  -- << 数据准备完毕
  local buffers = glGenFramebuffers(1);
  gBuffer = buffers[1];
  local textures = glGenTextures(3);
  gPosition = textures[1];
  gNormal = textures[2];
  gAlbedoSpec = textures[3];

  glBindTexture(GL_TEXTURE_2D, gPosition);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  
  glBindTexture(GL_TEXTURE_2D, gNormal);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  
  glBindTexture(GL_TEXTURE_2D, gAlbedoSpec);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);


  local rboDepth;
  local rbuffers = glGenRenderbuffers(1);
  rboDepth = rbuffers[1];

  glBindFramebuffer(GL_FRAMEBUFFER, gBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gPosition, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, gNormal, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, gAlbedoSpec, 0);
    local attachments = 
    {
      GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2        
    };
    glDrawBuffers(3, attachments);
    glBindRenderbuffer(GL_RENDERBUFFER, rboDepth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, SCREEN_WIDTH, SCREEN_HEIGHT);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepth);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE) 
    then
      print("frame buffer error");
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  math.randomseed(13);
  
  local NR_LIGHTS = 32;
  for i=1,NR_LIGHTS,1
  do
    local x = math.random() * 6.0 - 3.0;
    local y = math.random() * 6.0 - 4.0;
    local z = math.random() * 6.0 - 3.0;
    table.insert( lightPositions, glm.vec3:new(x,y,z) );
    local r = math.random() * 0.5 + 0.5;
    local g = math.random() * 0.5 + 0.5;
    local b = math.random() * 0.5 + 0.5;
    table.insert(lightColors, glm.vec3:new(r,g,b));
  end

  shaderLightingPass:use();
  shaderLightingPass:SetInt("gPosition", 0);
  shaderLightingPass:SetInt("gNormal", 1);
  shaderLightingPass:SetInt("gAlbedoSpec", 2);  
end

function OnDraw()
  
  glClearColor(0, 0, 0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
  local projection = glm.perspective(glm.radians(mainCamera.Zoom), 1.0 * SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100);
  local view = mainCamera:GetViewMatrix();
  local model;

  glBindFramebuffer(GL_FRAMEBUFFER, gBuffer);
    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
    shaderGeometryPass:use();
    shaderGeometryPass:SetMat4("projection", projection);
    shaderGeometryPass:SetMat4("view", view);
    for i=1,table.getn(objectPositions),1 do
      model = glm.mat4:new();
      model = glm.translate(model, objectPositions[i]);
      model = glm.scale(model, glm.vec3:new(0.25,0.25,0.25));
      shaderGeometryPass:SetMat4("model", model);
      nanosuit:Draw(shaderGeometryPass.ID);
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  shaderLightingPass:use();
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, gPosition);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, gNormal);
  glActiveTexture(GL_TEXTURE2);
  glBindTexture(GL_TEXTURE_2D, gAlbedoSpec);
  for i=1,table.getn(lightPositions),1 do
    shaderLightingPass:SetVec3("lights[" .. (i-1) .. "].Position", lightPositions[i]);
    shaderLightingPass:SetVec3("lights[" .. (i-1) .. "].Color", lightColors[i]);
    local constant = 1.0;
    local linear = 0.7;
    local quadratic = 1.8;
    shaderLightingPass:SetFloat("lights[" .. (i-1) .. "].Linear", linear);
    shaderLightingPass:SetFloat("lights[" .. (i-1) .. "].Quadratic", quadratic);

    local brightness = math.max( lightColors[i].x, lightColors[i].y, lightColors[i].z);
    local radius = (-linear + math.sqrt( linear * linear - 4 * quadratic * (constant - 256.0 / 5.0 * brightness))) / (2 * quadratic);
    shaderLightingPass:SetFloat("lights[" .. (i-1) .. "].Radius", radius);
  end
  shaderLightingPass:SetVec3("viewPos", mainCamera.Position);
  renderQuad();

  glBindFramebuffer(GL_READ_FRAMEBUFFER, gBuffer);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
  glBlitFramebuffer(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, GL_DEPTH_BUFFER_BIT, GL_NEAREST);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);


  shaderLightBox:use();
  shaderLightBox:SetMat4("projection", projection);
  shaderLightBox:SetMat4("view", view);
  for i=1,table.getn(lightPositions) do
    model = glm.mat4:new();
    model = glm.translate(model, lightPositions[i]);
    model = glm.scale(model, glm.vec3:new(0.125,0.125,0.125));
    shaderLightBox:SetMat4("model", model);
    shaderLightBox:SetVec3("lightColor", lightColors[i]);
    renderCube();
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

-- press ESC to exit
function OnKey(key)      
  if key == 'b' then hdr = (hdr + 1) % 2; end;
  if key == 'n' then shadowFactor = (shadowFactor + 1) % 2 end;
  if key == 'q' then exposure = exposure - 0.01 end;
  if key == 'e' then exposure = exposure + 0.01 end;
end

glMain();
