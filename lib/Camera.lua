require 'luaglm'

-- meta class
Camera = 
{
  Position = glm.vec3:new(0,0,0), 
  Front = glm.vec3:new(0,0,-1),
  Up = glm.vec3:new(0,1,0),
  Right = glm.vec3:new(),
  WorldUp = glm.vec3:new(0,1,0),
  
  Yaw = -90,
  Pitch = 0,
  
  MovementSpeed = 2.5,
  MouseSensitivity = 0.1,
  Zoom = 45.0
}


function Camera:updateCameraVectors()
  self.Front.x = math.cos(glm.radians(self.Yaw)) * math.cos(glm.radians(self.Pitch));
  self.Front.y = math.sin(glm.radians(self.Pitch));
  self.Front.z = math.sin(glm.radians(self.Yaw)) * math.cos(glm.radians(self.Pitch));
    
  self.Front = glm.normalize(self.Front);
  self.Right = glm.normalize(glm.cross(self.Front, self.WorldUp));
  self.Up = glm.normalize(glm.cross(self.Right, self.Front));
  -- print('camera rotation, front=' .. Vec3ToString(self.Front) .. ', right=' .. Vec3ToString(self.Right) .. ', up=' .. Vec3ToString(self.Up));
end

function Camera:new(o)
  o = o or {};
  
  setmetatable(o, self);
  self.__index = self;
  
  o:updateCameraVectors();
  return o;
end

function Camera:GetViewMatrix()
  -- print('self.position=' .. Vec3ToString(self.Position)); 
  -- print('self.Front=' .. Vec3ToString(self.Position + self.Front));  
  -- print('self.Up=' .. Vec3ToString(self.Up));   
  return glm.lookAt(self.Position, self.Position + self.Front, self.Up);
end

function Camera:ProcessKeyboard(pos)
  
  local delta = 0.1;
  if(pos == 0)
  then
    self.Position = self.Position + self.Front * delta;
  else if(pos == 1)
    then
      self.Position = self.Position - self.Front * delta;
    else if(pos == 2)
      then
        self.Position = self.Position - self.Right * delta;
      else
        self.Position = self.Position + self.Right * delta;
      end      
    end
  end
  
  print('pos:' .. pos);
  
end

function Camera:ProcessMouseScroll(offset)
  self.Zoom = self.Zoom + offset;
end

function Camera:ProcessMouseMovement(xoffset,yoffset)
  local sensitivity = 1;
  xoffset = xoffset * sensitivity;
  yoffset = yoffset * sensitivity;
  self.Yaw = self.Yaw + xoffset;
  self.Pitch = self.Pitch + yoffset;
  
  self:updateCameraVectors();
end
