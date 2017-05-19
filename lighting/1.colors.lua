-- vim: set ts=3 et:

print('_VERSION = ' .. _VERSION)

require 'luaglut'
print('luaglut.VERSION = ' .. luaglut.VERSION)


require 'luaglew'
print('luaglew.VERSION = '   .. luaglew.VERSION)

require 'luaglm'
print('luaglm.VERSION = '   .. luaglm.VERSION)

require 'lib/libre_util'
require 'lib/Camera'


local camera = Camera:new();
camera.Position.z = 0;
camera.Position.y = 0;
camera.Position.x = 0;
camera:updateCameraVectors();

lightPos = glm.vec3:new(1.2, 1.0, 2.0);

local quit = false
local fps = 15
local msec = 1000 / fps

local lightingShader, lampShader;
local vid;
local fid;

local vbo, vao, lightVAO;

local currentfile = 'lighting/1.colors'

local vertex_source = ReadAllText(currentfile .. ".vs");
local fragment_source = ReadAllText(currentfile .. ".fs");

local function set_material_clay()
   glMaterialfv(GL_FRONT, GL_AMBIENT,  {0.2125, 0.1275, 0.054, 1.0})
   glMaterialfv(GL_FRONT, GL_DIFFUSE,  {0.514, 0.4284, 0.18144, 1.0})
   glMaterialfv(GL_FRONT, GL_SPECULAR, {0.393548, 0.271906, 0.166721, 1.0})
   glMaterialf(GL_FRONT, GL_SHININESS, 0.2 * 128.0)

   glMaterialfv(GL_BACK, GL_AMBIENT,  {0.1, 0.18725, 0.1745, 1.0})
   glMaterialfv(GL_BACK, GL_DIFFUSE,  {0.396, 0.74151, 0.69102, 1.0})
   glMaterialfv(GL_BACK, GL_SPECULAR, {0.297254, 0.30829, 0.306678, 1.0})
   glMaterialf(GL_BACK, GL_SHININESS, 0.1 * 128.0)

   glEnable(GL_LIGHT0)
   glLightfv(GL_LIGHT0, GL_AMBIENT, {0.2, 0.2, 0.2, 1})
   glLightfv(GL_LIGHT0, GL_DIFFUSE, {1, 1, 1, 1})
   glLightfv(GL_LIGHT0, GL_POSITION, {0.0, 1.0, 0.0, 0.0})

   glEnable(GL_LIGHT1)
   glLightfv(GL_LIGHT1, GL_AMBIENT, {0.2, 0.2, 0.2, 1})
   glLightfv(GL_LIGHT1, GL_DIFFUSE, {1, 1, 1, 1})
   glLightfv(GL_LIGHT1, GL_POSITION, {1.0, 0.0, 1.0, 0.0})

   glLightModelf(GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE)
   glFrontFace(GL_CW)
end

function resize_func(w, h)
  --[[
   local ratio = w / h
   glMatrixMode(GL_PROJECTION)
   glLoadIdentity()
   ]]--
   glViewport(0,0,w,h)
   --[[
   gluPerspective(45,ratio,1,1000)
   glMatrixMode(GL_MODELVIEW)
   glLoadIdentity()
   set_material_clay()
   ]]--
   glEnable(GL_DEPTH_TEST)
   glEnable(GL_NORMALIZE)
end

function timer_func()
   if quit then return end
   
      glutSetWindow(window)
      glutTimerFunc(msec, timer_func, 0)
      glutPostRedisplay()
end

function display_func()
   if quit then return end

  -- glClearColor(0.2, 0.3, 0.3, 1.0);
  glClearColor(0, 0, 0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

  -- 设置物体的位置
  glUseProgram(lightingShader);
  glUniform3fv(glGetUniformLocation(lightingShader, "objectColor"), 1, {1.0, 0.5, 0.31});
  glUniform3fv(glGetUniformLocation(lightingShader, "lightColor"),  1, {1.0, 1.0, 1.0});

  local projection = glm.perspective(glm.radians(camera.Zoom), 800 / 600.0, 0.1, 100);
  local view = camera:GetViewMatrix();
  local model = glm.mat4:new();
  glUniformMatrix4fv(glGetUniformLocation(lightingShader, "projection"), 1, GL_FALSE, Mat4ToTable(projection));
  glUniformMatrix4fv(glGetUniformLocation(lightingShader, "view"), 1, GL_FALSE, Mat4ToTable(view));
  glUniformMatrix4fv(glGetUniformLocation(lightingShader, "model"), 1, GL_FALSE, Mat4ToTable(model));


  -- 绘制三角形
  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLES, 0, 36);

  -- 设置灯的位置

  glUseProgram(lampShader);

  glUniformMatrix4fv(glGetUniformLocation(lampShader, "projection"), 1, GL_FALSE, Mat4ToTable(projection));
  glUniformMatrix4fv(glGetUniformLocation(lampShader, "view"), 1, GL_FALSE, Mat4ToTable(view));
  
  model = glm.mat4:new();
  model = glm.translate(model, lightPos);
  model = glm.scale(model, glm.vec3:new(0.2,0.2,0.2));
  glUniformMatrix4fv(glGetUniformLocation(lampShader, "model"), 1, GL_FALSE, Mat4ToTable(model));

  -- print('proj=' .. Mat4ToString(projection));
  -- print('view=' .. Mat4ToString(view));
  -- print('model=' .. Mat4ToString(model));
  -- 绘制三角形
  glBindVertexArray(lightVAO);
  glDrawArrays(GL_TRIANGLES, 0, 36);


   glutSwapBuffers()
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
lampShader = LoadShaderEx(currentfile .. '.lamp.vs', currentfile .. '.lamp.fs');
lightingShader = LoadShaderEx(currentfile .. '.vs', currentfile .. '.fs');
-- << init end

-- >> 准备数据，绘制一个三角形
local VBO_ARRAY = glGenBuffers(1);
local VAO_ARRAY = glGenVertexArrays(2);
vbo = VBO_ARRAY[1];
vao = VAO_ARRAY[1];
lightVAO = VAO_ARRAY[2];
local vertices = 
    {
        -0.5, -0.5, -0.5, 
         0.5, -0.5, -0.5,  
         0.5,  0.5, -0.5,  
         0.5,  0.5, -0.5,  
        -0.5,  0.5, -0.5, 
        -0.5, -0.5, -0.5, 

        -0.5, -0.5,  0.5, 
         0.5, -0.5,  0.5,  
         0.5,  0.5,  0.5,  
         0.5,  0.5,  0.5,  
        -0.5,  0.5,  0.5, 
        -0.5, -0.5,  0.5, 

        -0.5,  0.5,  0.5, 
        -0.5,  0.5, -0.5, 
        -0.5, -0.5, -0.5, 
        -0.5, -0.5, -0.5, 
        -0.5, -0.5,  0.5, 
        -0.5,  0.5,  0.5, 

         0.5,  0.5,  0.5,  
         0.5,  0.5, -0.5,  
         0.5, -0.5, -0.5,  
         0.5, -0.5, -0.5,  
         0.5, -0.5,  0.5,  
         0.5,  0.5,  0.5,  

        -0.5, -0.5, -0.5, 
         0.5, -0.5, -0.5,  
         0.5, -0.5,  0.5,  
         0.5, -0.5,  0.5,  
        -0.5, -0.5,  0.5, 
        -0.5, -0.5, -0.5, 

        -0.5,  0.5, -0.5, 
         0.5,  0.5, -0.5,  
         0.5,  0.5,  0.5,  
         0.5,  0.5,  0.5,  
        -0.5,  0.5,  0.5, 
        -0.5,  0.5, -0.5, 
    };


glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBufferFormatedData(GL_ARRAY_BUFFER, GL_FLOAT, vertices, GL_STATIC_DRAW);

glBindVertexArray(vao);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof_float(), 0);
glEnableVertexAttribArray(0);

glBindBuffer(GL_ARRAY_BUFFER, vbo);
glBindVertexArray(lightVAO);

glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof_float(), 0);
glEnableVertexAttribArray(0);
-- << 数据准备完毕


glutDisplayFunc(display_func)
glutKeyboardFunc(keyboard_func)
glutReshapeFunc(resize_func)
glutTimerFunc(msec, timer_func, 0)

glutMainLoop()
