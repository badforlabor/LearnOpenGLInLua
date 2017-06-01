#version 330 core

#define GRAY 0
#define BLUR 0
#define EDGE_DETECT 0


out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D screenTexture;

const float offset = 1.0 / 300;

void main()
{
    vec3 col = texture(screenTexture, TexCoords).rgb;

    vec2 offsets[9] = vec2[]
    (
        vec2(-offset, offset),  // 左上角
        vec2(0, offset),        // 上
        vec2(offset, offset),   // 右上角
        vec2(-offset, 0),       // 左
        vec2(0, 0),             // 中
        vec2(offset, 0),        // 右
        vec2(-offset, -offset), // 左下角
        vec2(0, -offset),       // 下
        vec2(offset, -offset)   // 右下角
    );


#if GRAY
    // 灰色图效果
    float avarage = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
    FragColor = vec4(avarage, avarage, avarage, 1);
#elif BLUR
    // 模糊效果
    float kernels[9] = float[] 
    (
        1/16.0,2/16.0,1/16.0,
        2/16.0,4/16.0,2/16.0,
        1/16.0,2/16.0,1/16.0
    );
    vec3 sampledTex[9];
    for(int i=0; i<9; i++)
    {
        sampledTex[i] = vec3(texture(screenTexture, TexCoords + offsets[i]));
    }
    vec3 finalcolor = vec3(0);
    for(int i=0; i<9; i++)
    {
        finalcolor += sampledTex[i] * kernels[i];
    }
    FragColor = vec4(finalcolor, 1);
#elif EDGE_DETECT
    // 边缘检测效果（不是很好）
    float kernels[9] = float[] 
    (
        1,1,1,
        1,-8,1,
        1,1,1
    );
    vec3 sampledTex[9];
    for(int i=0; i<9; i++)
    {
        sampledTex[i] = vec3(texture(screenTexture, TexCoords + offsets[i]));
    }
    vec3 finalcolor = vec3(0);
    for(int i=0; i<9; i++)
    {
        finalcolor += sampledTex[i] * kernels[i];
    }
    FragColor = vec4(finalcolor, 1);

#else
    // 无任何效果，显示原色
    FragColor = vec4(col, 1.0);
#endif
} 