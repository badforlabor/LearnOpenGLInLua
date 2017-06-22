-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(-2,4,-1);

local currentfile = 'advanced_lighting/9.1.ssao'
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

local Inverse_normals = 1;
local exposure = 1.0;
local hdr = 1;

local shaderGeometryPass;
local shaderLightingPass;
local shaderSSAO;
local shaderSSAOBlur;
local nanosuit;

local gBuffer;
local gPosition;
local gNormal;
local gAlbedoSpec;
local ssaoFBO;
local ssaoColorBuffer;
local ssaoBlurFBO;
local ssaoColorBufferBlur;
local ssaoKernel = {};
local ssaoNoise;
local noiseTexture;
local lightColor;

function OnInit()

  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;

  mainCamera.Position = glm.vec3:new(0,0,5);
  mainCamera:updateCameraVectors();

  glEnable(GL_DEPTH_TEST);
  --glEnable(GL_BLEND);
  --glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  shaderGeometryPass = Shader:new(currentfile .. '_geometry.vs', currentfile .. '_geometry.fs');
  shaderLightingPass = Shader:new(currentfile .. '.vs', currentfile .. '_lighting.fs');
  shaderSSAO = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  shaderSSAOBlur = Shader:new(currentfile .. '.vs', currentfile .. '.blur.fs');

  -- >> 准备数据，绘制一些点
  nanosuit = libre.Model:new("resources/objects/nanosuit/nanosuit.obj");

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
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  
  glBindTexture(GL_TEXTURE_2D, gNormal);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  
  glBindTexture(GL_TEXTURE_2D, gAlbedoSpec);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, nil);
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

  local fbs = glGenFramebuffers(1);
  ssaoFBO = fbs[1];
  
  ssaoColorBuffer = glGenTextures(1)[1];
  glBindTexture(GL_TEXTURE_2D, ssaoColorBuffer)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glBindFramebuffer(GL_FRAMEBUFFER, ssaoFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ssaoColorBuffer, 0);
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE then
      print("ssao frame buffer error.")
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  ssaoBlurFBO = glGenFramebuffers(1)[1];
  ssaoColorBufferBlur = glGenTextures(1)[1];
  glBindTexture(GL_TEXTURE_2D, ssaoColorBufferBlur);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glBindFramebuffer(GL_FRAMEBUFFER, ssaoBlurFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ssaoColorBufferBlur, 0);
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE then
      print("ssao frame buffer error.")
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  
  
  for i=1,64 do
    local sample = glm.vec3:new(math.random() * 2 - 1, math.random() * 2 - 1, math.random());
    sample = glm.normalize(sample);
    sample = sample * math.random();
    local scale = (i-1) / 64.0;
    scale = lerp(0.1, 1.0, scale * scale);
    sample = sample * scale;
    table.insert( ssaoKernel,sample );
  end

  ssaoNoise = glm.vec3_array:new();
  for i=1,16 do
    local noise = glm.vec3:new(math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0, 0);
    ssaoNoise:push_back(noise);
  end

  noiseTexture = glGenTextures(1)[1];
  glBindTexture(GL_TEXTURE_2D, noiseTexture);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, 4, 4, 0, GL_RGB, GL_FLOAT, ssaoNoise:data());
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);


  lightPos = glm.vec3:new(2.0, 4.0, -2.0);
  lightColor = glm.vec3:new(0.2, 0.2, 0.7);

  shaderLightingPass:use();
  shaderLightingPass:SetInt("gPosition", 0);
  shaderLightingPass:SetInt("gNormal", 1);
  shaderLightingPass:SetInt("gAlbedoSpec", 2);  
  shaderLightingPass:SetInt("ssao", 3);  

  shaderSSAO:use();
  shaderSSAO:SetInt("gPosition", 0);
  shaderSSAO:SetInt("gNormal", 1);
  shaderSSAO:SetInt("texNoise", 2);

  shaderSSAOBlur:use();
  shaderSSAOBlur:SetInt("ssaoInput", 0);
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
    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(0, 7, 0));
    model = glm.scale(model, glm.vec3:new(7.5,7.5,7.5));
    shaderGeometryPass:SetMat4("model", model);
    shaderGeometryPass:SetInt("invertedNormals", 1);
    renderCube();
    shaderGeometryPass:SetInt("invertedNormals", 0);
    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3:new(0,0,5));
    model = glm.rotate(model, glm.radians(-90), glm.vec3:new(1,0,0));
    model = glm.scale(model, glm.vec3(0.5));
    shaderGeometryPass:SetMat4("model", model);
    nanosuit:Draw(shaderGeometryPass.ID);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 生成ssao贴图
  glBindFramebuffer(GL_FRAMEBUFFER, ssaoFBO);
    glClear(GL_COLOR_BUFFER_BIT);
    shaderSSAO:use();
    for i=1,64 do
      shaderSSAO:SetVec3("samples[" .. (i-1) .. "]", ssaoKernel[i]);
    end
    shaderSSAO:SetMat4("projection", projection);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gPosition);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, gNormal);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, noiseTexture);
    renderQuad();
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- blur ssao
  glBindFramebuffer(GL_FRAMEBUFFER, ssaoBlurFBO);
    glClear(GL_COLOR_BUFFER_BIT);
    shaderSSAOBlur:use();
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, ssaoColorBuffer);
    renderQuad();
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- lighting pass
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  shaderLightingPass:use();

  local lightPosView = glm.vec3:new(mainCamera:GetViewMatrix() * glm.vec4:new(lightPos, 1));
  shaderLightingPass:SetVec3("light.Position", lightPosView);
  shaderLightingPass:SetVec3("light.Color", lightColor);
  local constant = 1.0;
  local linear = 0.09;
  local quadratic = 0.032;
  shaderLightingPass:SetFloat("light.Linear", linear);
  shaderLightingPass:SetFloat("light.Quadratic", quadratic);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, gPosition);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, gNormal);
  glActiveTexture(GL_TEXTURE2);
  glBindTexture(GL_TEXTURE_2D, gAlbedoSpec);
  glActiveTexture(GL_TEXTURE3);
  glBindTexture(GL_TEXTURE_2D, ssaoColorBufferBlur);
  renderQuad();

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
