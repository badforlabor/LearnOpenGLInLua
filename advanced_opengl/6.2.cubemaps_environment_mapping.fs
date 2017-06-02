#version 330 core
out vec4 FragColor;

in vec3 Normal;
in vec3 Position;

uniform vec3 cameraPos;
uniform samplerCube skybox;

void main()
{    
    vec3 I = normalize(Position - cameraPos);
    vec3 R = reflect(I, normalize(Normal));
    // 不理解为什么这里能直接用向量。难道是天空离得比较远，近似了？
    FragColor = vec4(texture(skybox, R).rgb, 1.0);
}