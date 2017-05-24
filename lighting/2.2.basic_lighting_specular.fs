#version 330 core
out vec4 fragColor;

in vec3 Normal;  
in vec3 FragPos;  
  
uniform vec3 lightPos; 
uniform vec3 viewPos; 
uniform vec3 lightColor;
uniform vec3 objectColor;

void main()
{
    // 环境光，有点类似白天屋子里面的光，你看不到照射，但是有。而且光的强度与观察者的视角无关，与物体位置无光，即便是阴影的地方，也会有此光。
    // ambient
    float ambientStrength = 0.1f;
    vec3 ambient = ambientStrength * lightColor;
  	
    // 漫反射光，主要用来区分阴影的，只有光照射到的物体才有光，而且光照与物体法线方向越接近，亮度越大！
    // diffuse 
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0f);
    vec3 diffuse = diff * lightColor;
    
    // 高光（镜面反射光）。观察者看镜子里面的反光会觉得非常刺眼，就是用来模拟这个的。
    // specular
    float specularStrength = 0.5f;
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;  
        
    // 对象自身的颜色，表示的是吸收光的强度，0表示全部吸收（无论光是什么颜色，物体都显示黑色），1表示完全不吸收（比如光是红色，那么看到的物体也是红色）    
    vec3 result = (ambient + diffuse + specular) * objectColor;
    fragColor = vec4(result, 1.0f);
} 