#ifndef POI_RGBMASK
    #define POI_RGBMASK
    #if defined(PROP_RGBMASK) || !defined(OPTIMIZER_ENABLED)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_RGBMask); float4 _RGBMask_ST;
    #endif
    #if defined(PROP_REDTEXURE) || !defined(OPTIMIZER_ENABLED)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_RedTexure); float4 _RedTexure_ST;
    #endif
    #if defined(PROP_GREENTEXTURE) || !defined(OPTIMIZER_ENABLED)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_GreenTexture); float4 _GreenTexture_ST;
    #endif
    #if defined(PROP_BLUETEXTURE) || !defined(OPTIMIZER_ENABLED)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_BlueTexture); float4 _BlueTexture_ST;
    #endif
    #if defined(PROP_ALPHATEXTURE) || !defined(OPTIMIZER_ENABLED)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_AlphaTexture); float4 _AlphaTexture_ST;
    #endif
    float4 _RedColor;
    float4 _GreenColor;
    float4 _BlueColor;
    float4 _AlphaColor;
    float2 _RGBMaskPanning;
    float2 _RGBRedPanning;
    float2 _RGBGreenPanning;
    float2 _RGBBluePanning;
    float2 _RGBAlphaPanning;
    float _RGBBlendMultiplicative;
    float _RGBMaskUV;
    float _RGBRed_UV;
    float _RGBGreen_UV;
    float _RGBBlue_UV;
    float _RGBAlpha_UV;
    float _RGBUseVertexColors;
    float _RGBNormalBlend;
    static float4 rgbMask;
    void calculateRGBNormals(inout half3 mainTangentSpaceNormal)
    {
    }
    float3 calculateRGBMask(float3 baseColor)
    {
        #ifndef RGB_MASK_TEXTURE
            #define RGB_MASK_TEXTURE
            
            if (float(0))
            {
                rgbMask = poiMesh.vertexColor;
            }
            else
            {
                #if defined(PROP_RGBMASK) || !defined(OPTIMIZER_ENABLED)
                    rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
                #else
                    rgbMask = 1;
                #endif
            }
        #endif
        #if defined(PROP_REDTEXURE) || !defined(OPTIMIZER_ENABLED)
            float4 red = POI2D_SAMPLER_PAN(_RedTexure, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        #else
            float4 red = 1;
        #endif
        #if defined(PROP_GREENTEXTURE) || !defined(OPTIMIZER_ENABLED)
            float4 green = POI2D_SAMPLER_PAN(_GreenTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        #else
            float4 green = 1;
        #endif
        #if defined(PROP_BLUETEXTURE) || !defined(OPTIMIZER_ENABLED)
            float4 blue = POI2D_SAMPLER_PAN(_BlueTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        #else
            float4 blue = 1;
        #endif
        #if defined(PROP_ALPHATEXTURE) || !defined(OPTIMIZER_ENABLED)
            float4 alpha = POI2D_SAMPLER_PAN(_AlphaTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        #else
            float4 alpha = 1;
        #endif
        
        if(float(1))
        {
            float3 RGBColor = 1;
            RGBColor = lerp(RGBColor, red.rgb * float4(1,1,1,1).rgb, rgbMask.r * red.a * float4(1,1,1,1).a);
            RGBColor = lerp(RGBColor, green.rgb * float4(0.3005438,0.3005438,0.3005438,1).rgb, rgbMask.g * green.a * float4(0.3005438,0.3005438,0.3005438,1).a);
            RGBColor = lerp(RGBColor, blue.rgb * float4(0.3185468,0.4461952,1,1).rgb, rgbMask.b * blue.a * float4(0.3185468,0.4461952,1,1).a);
            RGBColor = lerp(RGBColor, alpha.rgb * float4(1,0.6814206,0.4254881,1).rgb, rgbMask.a * alpha.a * float4(1,0.6814206,0.4254881,1).a);
            baseColor *= RGBColor;
        }
        else
        {
            baseColor = lerp(baseColor, red.rgb * float4(1,1,1,1).rgb, rgbMask.r * red.a * float4(1,1,1,1).a);
            baseColor = lerp(baseColor, green.rgb * float4(0.3005438,0.3005438,0.3005438,1).rgb, rgbMask.g * green.a * float4(0.3005438,0.3005438,0.3005438,1).a);
            baseColor = lerp(baseColor, blue.rgb * float4(0.3185468,0.4461952,1,1).rgb, rgbMask.b * blue.a * float4(0.3185468,0.4461952,1,1).a);
            baseColor = lerp(baseColor, alpha.rgb * float4(1,0.6814206,0.4254881,1).rgb, rgbMask.a * alpha.a * float4(1,0.6814206,0.4254881,1).a);
        }
        return baseColor;
    }
#endif
