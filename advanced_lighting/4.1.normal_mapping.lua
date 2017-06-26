-- 深度测试

require 'lib/MyWindowFramework'

local lightPos = glm.vec3:new(0.5, 1.0, 0.3);

local myshader;

local vbo, vao;

local currentfile = 'advanced_lighting/4.1.normal_mapping'
-- local currentfile = 'lighting/1.colors'

local floorTexture;
local debug_depth = 0;
local shadowFactor = 1;

local SHADOW_WIDTH = 1024;
local SHADOW_HEIGHT = 1024;
local depthMapFBO, depthMap;
local nearPlane = 1.0
local farPlane = 7.5;

local diffuseMap;
local normalMap;

function OnInit()

  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;

  glEnable(GL_DEPTH_TEST);

  myshader = Shader:new(currentfile .. '.vs', currentfile .. '.fs');
  diffuseMap = LoadTexture("resources/textures/brickwall.jpg");
  normalMap = LoadTexture("resources/textures/brickwall_normal.jpg");

  myshader:use();
  myshader:SetInt("diffuseMap", 0);
  myshader:SetInt("normalMap", 1);

  -- >> 准备数据，绘制一些点
  -- << 数据准备完毕

  -- framebuffer，用来将阴影渲染到此buffer上

end

function OnDraw()
  
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- 绘制场景  
  glViewport(0,0,SCREEN_WIDTH, SCREEN_HEIGHT);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);
  myshader:use();
  local projection = glm.perspective(mainCamera.Zoom, 1.0 * SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100);
  local view = mainCamera:GetViewMatrix();
  myshader:SetMat4("projection", projection);
  myshader:SetMat4("view", view);

  local model = glm.mat4:new();
  model = glm.rotate(model, glm.radians(glutGetTime() * -10.0), glm.normalize(glm.vec3:new(1,0,1)));
  myshader:SetMat4("model", model);
  myshader:SetVec3("viewPos", mainCamera.Position);
  myshader:SetVec3("lightPos", lightPos);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, diffuseMap);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, normalMap);
  renderQuad();

  model = glm.mat4:new();
  model = glm.translate(model, lightPos);
  model = glm.scale(model, glm.vec3:new(0.1,0.1,0.1));
  myshader:setMat4("model", model);
  renderQuad();

end

local quadVAO = 0;
local quadVBO = 0;
function renderQuad(  )
  
  if quadVAO == 0
  then

    local pos1 = glm.vec3:new(-1, 1, 0);
    local pos2 = glm.vec3:new(-1,-1, 0);
    local pos3 = glm.vec3:new( 1,-1, 0);
    local pos4 = glm.vec3:new( 1, 1, 0);

    local uv1 = glm.vec3:new(0, 1, 0);
    local uv2 = glm.vec3:new(0, 0, 0);
    local uv3 = glm.vec3:new(1, 0, 0);
    local uv4 = glm.vec3:new(1, 1, 0);

    local nm = glm.vec3:new(0, 0, 1);
    local tangent1 = glm.vec3:new();
    local bitangent1 = glm.vec3:new();
    local tangent2 = glm.vec3:new();
    local bitangent2 = glm.vec3:new();

    -- （点1，点2，点3）组成的三角形
    local edge1 = pos2 - pos1;
    local edge2 = pos3 - pos1;
    local deltaUV1 = uv2 - uv1;
    local deltaUV2 = uv3 - uv1;

    local f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);
    tangent1.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
    tangent1.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
    tangent1.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
    tangent1 = glm.normalize(tangent1);

    bitangent1.x = f * (-deltaUV2.x * edge1.x + deltaUV1.y * edge2.x);
    bitangent1.y = f * (-deltaUV2.x * edge1.y + deltaUV1.y * edge2.y);
    bitangent1.z = f * (-deltaUV2.x * edge1.z + deltaUV1.y * edge2.z);
    bitangent1 = glm.normalize(bitangent1);

    -- （点1，点3，点4）组成的三角形
    edge1 = pos3 - pos1;
    edge2 = pos4 - pos1;
    deltaUV1 = uv3 - uv1;
    deltaUV2 = uv4 - uv1;

    f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);

    tangent2.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
    tangent2.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
    tangent2.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
    tangent2 = glm.normalize(tangent2);


    bitangent2.x = f * (-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x);
    bitangent2.y = f * (-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y);
    bitangent2.z = f * (-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z);
    bitangent2 = glm.normalize(bitangent2);
    
    local quadVertices = 
    {
            pos1.x, pos1.y, pos1.z, nm.x, nm.y, nm.z, uv1.x, uv1.y, tangent1.x, tangent1.y, tangent1.z, bitangent1.x, bitangent1.y, bitangent1.z,
            pos2.x, pos2.y, pos2.z, nm.x, nm.y, nm.z, uv2.x, uv2.y, tangent1.x, tangent1.y, tangent1.z, bitangent1.x, bitangent1.y, bitangent1.z,
            pos3.x, pos3.y, pos3.z, nm.x, nm.y, nm.z, uv3.x, uv3.y, tangent1.x, tangent1.y, tangent1.z, bitangent1.x, bitangent1.y, bitangent1.z,

            pos1.x, pos1.y, pos1.z, nm.x, nm.y, nm.z, uv1.x, uv1.y, tangent2.x, tangent2.y, tangent2.z, bitangent2.x, bitangent2.y, bitangent2.z,
            pos3.x, pos3.y, pos3.z, nm.x, nm.y, nm.z, uv3.x, uv3.y, tangent2.x, tangent2.y, tangent2.z, bitangent2.x, bitangent2.y, bitangent2.z,
            pos4.x, pos4.y, pos4.z, nm.x, nm.y, nm.z, uv4.x, uv4.y, tangent2.x, tangent2.y, tangent2.z, bitangent2.x, bitangent2.y, bitangent2.z
    };


    local vas = glGenVertexArrays(1);
    quadVAO = vas[1];
    local vbs = glGenBuffers(1);
    quadVBO = vbs[1];

    glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
    glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, quadVertices, GL_STATIC_DRAW);

    glBindVertexArray(quadVAO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 14 * sizeof_float(), 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 14 * sizeof_float(), 3 * sizeof_float());
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 14 * sizeof_float(), 6 * sizeof_float());
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 14 * sizeof_float(), 8 * sizeof_float());
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, 14 * sizeof_float(), 11 * sizeof_float());
    glEnableVertexAttribArray(4);
  end

  glBindVertexArray(quadVAO);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);
  glBindVertexArray(0);
end
  

-- press ESC to exit
function OnKey(key)      
  if key == 'b' then debug_depth = (debug_depth + 1) % 2 end;
  if key == 'n' then shadowFactor = (shadowFactor + 1) % 2 end;
end

glMain();
