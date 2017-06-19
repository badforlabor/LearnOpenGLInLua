-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(-2,4,-1);

local myshader;
local hdrShader;

local currentfile = 'advanced_lighting/6.1.hdr'
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

local lightPositions;
local lightColors;
local Inverse_normals = 1;
local exposure = 1.0;
local hdr = 1;

function OnInit()

  SCREEN_WIDTH = 1280;
  SCREEN_HEIGHT = 720;

  mainCamera.Position = glm.vec3:new(0,0,5);
  mainCamera:updateCameraVectors();

  glEnable(GL_DEPTH_TEST);
  --glEnable(GL_BLEND);
  --glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  hdrShader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  myshader = Shader:new(currentfile .. '.lighting.vs', currentfile .. '.lighting.fs');

  -- >> 准备数据，绘制一些点
  woodTexture = LoadTexture("resources/textures/wood.png");

  -- << 数据准备完毕

  -- framebuffer，用来将阴影渲染到此buffer上
  local fbs = glGenFramebuffers(1);
  hdrFBO = fbs[1];
  local textures = glGenTextures(1);
  colorBuffer = textures[1];
  glBindTexture(GL_TEXTURE_2D, colorBuffer);
  -- 作为depth buffer用。
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  local buffers = glGenRenderbuffers(1);
  local rboDepth = buffers[1];
  glBindRenderbuffer(GL_RENDERBUFFER, rboDepth);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, SCREEN_WIDTH, SCREEN_HEIGHT);
  
  glBindFramebuffer(GL_FRAMEBUFFER, hdrFBO);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorBuffer, 0);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepth);
  if(glCheckFramebufferStatus(GL_FRAMEBUFFER) ~= GL_FRAMEBUFFER_COMPLETE) 
  then 
    print("fbo invalid."); 
  end
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  lightPositions = 
  {
    glm.vec3:new(0, 0, 49.5),
    glm.vec3:new(-1.4, -1.9, 9),
    glm.vec3:new(0, -1.8, 4),
    glm.vec3:new(0.8, -1.7, 6)
  };
  lightColors = 
  {
    glm.vec3:new(200, 200, 200),
    glm.vec3:new(0.1, 0, 0),
    glm.vec3:new(0, 0, 0.2),
    glm.vec3:new(0, 0.1, 0)
  };

  -- 
  myshader:use();
  myshader:SetInt("diffuseTexture", 0);
  hdrShader:use();
  hdrShader:SetInt("hdrBuffer", 0);

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
    model = glm.translate(model, glm.vec3:new(0,0,25));
    model = glm.scale(model, glm.vec3:new(2.5,2.5,27.5));
    myshader:SetMat4("model", model);
    myshader:SetInt("inverse_normals", Inverse_normals);
    renderCube();
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  -- 绘制tonemap hdr
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  hdrShader:use();
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, colorBuffer);
  hdrShader:SetInt("hdr", hdr);
  hdrShader:SetFloat("exposure", exposure);
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
