-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(-2,4,-1);

local myshader;
local hdrShader;

local currentfile = 'advanced_lighting/7.1.bloom'
-- local currentfile = 'lighting/1.colors'

local woodTexture;
local debug_depth = 0;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local hdrFBO;
local colorBuffers;
local nearPlane = 1.0
local farPlane = 7.5;

local lightPositions;
local lightColors;
local Inverse_normals = 1;
local exposure = 1.0;
local bloom = 1;

local shaderLight;
local shaderBlur;
local shaderBloomFinal;

local containerTexture;

local pingpongFBO;
local pingpongColorBuffers;

function OnInit()

  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;

  mainCamera.Position = glm.vec3:new(0,0,5);
  mainCamera:updateCameraVectors();

  glEnable(GL_DEPTH_TEST);
  --glEnable(GL_BLEND);
  --glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  shaderLight = Shader:new(currentfile .. '.light_box.vs', currentfile .. '.light_box.fs');
  shaderBlur = Shader:new(currentfile .. '.blur.vs', currentfile .. '.blur.fs');
  shaderBloomFinal = Shader:new(currentfile .. '_final.vs', currentfile .. '_final.fs');

  -- >> 准备数据，绘制一些点
  woodTexture = LoadTexture("resources/textures/wood.png");
  containerTexture = LoadTexture("resources/textures/container2.png");

  -- << 数据准备完毕

  -- framebuffer，用来将阴影渲染到此buffer上
  local fbs = glGenFramebuffers(1);
  hdrFBO = fbs[1];  
  colorBuffers = glGenTextures(1);

  local buffers = glGenRenderbuffers(1);
  local rboDepth = buffers[1];
  glBindRenderbuffer(GL_RENDERBUFFER, rboDepth);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, SCREEN_WIDTH, SCREEN_HEIGHT);
  
  glBindFramebuffer(GL_FRAMEBUFFER, hdrFBO);
    for i=1, table.getn(colorBuffers), 1
    do
      glBindTexture(GL_TEXTURE_2D, colorBuffers[i]);
      -- 作为depth buffer用。
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + (i - 1), GL_TEXTURE_2D, colorBuffers[i], 0);
    end
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepth);

    local attachments = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1};
    glDrawBuffers(2, attachments);

    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE) 
    then 
      print("fbo invalid."); 
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  pingpongFBO = glGenFramebuffers(2);
  pingpongColorBuffers = glGenTextures(2);

  for i=1, table.getn(pingpongFBO), 1
  do
    glBindFramebuffer(GL_FRAMEBUFFER, pingpongFBO[i]);
    glBindTexture(GL_TEXTURE_2D, pingpongColorBuffers[i]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_FLOAT, nil);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pingpongColorBuffers[i], 0);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE)
    then
      print("ping pong frame buffer error.");
    end
  end


  lightPositions = 
  {
    glm.vec3:new(0, 0.5, 1.5),
    glm.vec3:new(-4.0, -0.5, -3.0),
    glm.vec3:new(3.0, 0.5, 1.0),
    glm.vec3:new(-0.8, 2.4, -1.0)
  };
  lightColors = 
  {
    glm.vec3:new(2,2,2),
    glm.vec3:new(1.5, 0, 0),
    glm.vec3:new(0, 0, 1.5),
    glm.vec3:new(0, 1.5, 0)
  };

  -- 
  myshader:use();
  myshader:SetInt("diffuseTexture", 0);
  shaderBlur:use();
  shaderBlur:SetInt("image", 0);
  shaderBloomFinal:use();
  shaderBloomFinal:SetInt("scene", 0);
  shaderBloomFinal:SetInt("bloomBlur", 1);

end

function OnDraw()
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- 绘制场景到fbo上
  glBindFramebuffer(GL_FRAMEBUFFER, hdrFBO);
    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
    local projection = glm.perspective(mainCamera.Zoom, 1.0 * SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100);
    local view = mainCamera:GetViewMatrix();
    myshader:use();
    myshader:SetMat4("projection", projection);
    myshader:SetMat4("view", view);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, woodTexture);
    for i=1, table.getn(lightPositions), 1
    do
      myshader:SetVec3("lights[" .. (i-1) .. "].Position", lightPositions[i]);
      myshader:SetVec3("lights[" .. (i-1) .. "].Color", lightColors[i]);
    end  
    myshader:SetVec3("viewPos", mainCamera.Position);
    local model = glm.mat4:new();
    model = glm.translate(model, glm.vec3:new(0,-1, 0));
    model = glm.scale(model, glm.vec3:new(12.5,0.5,12.5));
    myshader:SetMat4("model", model);
    myshader:SetInt("inverse_normals", Inverse_normals);
    renderCube();

    glBindTexture(GL_TEXTURE_2D, containerTexture);
    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(0,1.5,0));
    model = glm.scale(model, glm.vec3(0.5,0.5,0.5));
    myshader:SetMat4("model", model);
    renderCube();
    
    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(2,0,1));
    model = glm.scale(model, glm.vec3(0.5,0.5,0.5));
    myshader:SetMat4("model", model);
    renderCube();
    
    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(-1,-1,2));
    model = glm.rotate(model, glm.radians(60), glm.normalize(glm.vec3(1,0,1)));
    myshader:SetMat4("model", model);
    renderCube();

    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(0,2.7,4.0));
    model = glm.rotate(model, glm.radians(23), glm.normalize(glm.vec3(1,0,1)));
    model = glm.scale(model, glm.vec3(1.25,1.25,1.25));
    myshader:SetMat4("model", model);
    renderCube();

    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(-2.0,1.0,-3.0));
    model = glm.rotate(model, glm.radians(124), glm.normalize(glm.vec3(1,0,1)));
    myshader:SetMat4("model", model);
    renderCube();

    model = glm.mat4:new();
    model = glm.translate(model, glm.vec3(-3.0,0.0,0.0));
    model = glm.scale(model, glm.vec3(0.5,0.5,0.5));
    myshader:SetMat4("model", model);
    renderCube();

    -- 显示所有的灯
    shaderLight:use();
    shaderLight:SetMat4("projection", projection);
    shaderLight:SetMat4("view", view);
    for i=1,table.getn(lightPositions),1 do
      model = glm.mat4:new();
      model = glm.translate(model, lightPositions[i]);
      model = glm.scale(model, glm.vec3:new(0.25,0.25,0.25));
      shaderLight:SetMat4("model", model);
      shaderLight:SetVec3("lightColor", lightColors[i]);
      renderCube();
    end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 高斯模糊
  local horizontal = 1;
  local first_it = true;
  local amount = 10;
  shaderBlur:use();
  for i=1,amount,1 do
    glBindFramebuffer(GL_FRAMEBUFFER, pingpongFBO[horizontal+1]);
      shaderBlur:SetInt("horizontal", horizontal);
      glBindTexture(GL_TEXTURE_2D, first_it and colorBuffers[1+1] or pingpongColorBuffers[(horizontal + 1) % table.getn(pingpongColorBuffers) + 1]);
      renderQuad();
      horizontal = (horizontal + 1) % table.getn(pingpongColorBuffers);
      if first_it then
        first_it = false;
      end
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  end
  

  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  shaderBloomFinal:use();
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, colorBuffers[1]);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, pingpongColorBuffers[(horizontal + 1) % table.getn(pingpongColorBuffers) + 1]);
  shaderBloomFinal:SetInt("bloom", bloom);
  shaderBloomFinal:SetFloat("exposure", exposure);
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
  if key == 'b' then bloom = (bloom + 1) % 2; end;
  if key == 'q' then exposure = exposure - 0.01 end;
  if key == 'e' then exposure = exposure + 0.01 end;
end

glMain();
