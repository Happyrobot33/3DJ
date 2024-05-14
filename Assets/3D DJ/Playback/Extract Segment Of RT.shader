// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Extract Segment Of RT"
{
    Properties
    {
		[NoScaleOffset]_RT("RT", 2D) = "white" {}
		_Center("Center", Vector) = (0,0,0,0)
		_Size("Size", Vector) = (0,0,0,0)
		[Toggle]_RGSplit("RGSplit", Float) = 0
		[KeywordEnum(LinearToGamma,Raw,GammaToLinear)] _ColorSpaceConvert("ColorSpaceConvert", Float) = 1

    }

	SubShader
	{
		LOD 0

		
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
        Pass
        {
			Name "Custom RT Update"
            CGPROGRAM
            
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex ASECustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0
			#include "UnityCG.cginc"
			#pragma shader_feature_local _COLORSPACECONVERT_LINEARTOGAMMA _COLORSPACECONVERT_RAW _COLORSPACECONVERT_GAMMATOLINEAR


			struct ase_appdata_customrendertexture
			{
				uint vertexID : SV_VertexID;
				
			};

			struct ase_v2f_customrendertexture
			{
				float4 vertex           : SV_POSITION;
				float3 localTexcoord    : TEXCOORD0;    // Texcoord local to the update zone (== globalTexcoord if no partial update zone is specified)
				float3 globalTexcoord   : TEXCOORD1;    // Texcoord relative to the complete custom texture
				uint primitiveID        : TEXCOORD2;    // Index of the update zone (correspond to the index in the updateZones of the Custom Texture)
				float3 direction        : TEXCOORD3;    // For cube textures, direction of the pixel being rendered in the cubemap
				
			};

			uniform float _RGSplit;
			uniform sampler2D _RT;
			uniform float2 _Size;
			float4 _RT_TexelSize;
			uniform float2 _Center;


			ase_v2f_customrendertexture ASECustomRenderTextureVertexShader(ase_appdata_customrendertexture IN  )
			{
				ase_v2f_customrendertexture OUT;
				
			#if UNITY_UV_STARTS_AT_TOP
				const float2 vertexPositions[6] =
				{
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f, -1.0f },
					{  1.0f,  1.0f },
					{ -1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f }
				};
			#else
				const float2 vertexPositions[6] =
				{
					{  1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 1.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f }
				};
			#endif

				uint primitiveID = IN.vertexID / 6;
				uint vertexID = IN.vertexID % 6;
				float3 updateZoneCenter = CustomRenderTextureCenters[primitiveID].xyz;
				float3 updateZoneSize = CustomRenderTextureSizesAndRotations[primitiveID].xyz;
				float rotation = CustomRenderTextureSizesAndRotations[primitiveID].w * UNITY_PI / 180.0f;

			#if !UNITY_UV_STARTS_AT_TOP
				rotation = -rotation;
			#endif

				// Normalize rect if needed
				if (CustomRenderTextureUpdateSpace > 0.0) // Pixel space
				{
					// Normalize xy because we need it in clip space.
					updateZoneCenter.xy /= _CustomRenderTextureInfo.xy;
					updateZoneSize.xy /= _CustomRenderTextureInfo.xy;
				}
				else // normalized space
				{
					// Un-normalize depth because we need actual slice index for culling
					updateZoneCenter.z *= _CustomRenderTextureInfo.z;
					updateZoneSize.z *= _CustomRenderTextureInfo.z;
				}

				// Compute rotation

				// Compute quad vertex position
				float2 clipSpaceCenter = updateZoneCenter.xy * 2.0 - 1.0;
				float2 pos = vertexPositions[vertexID] * updateZoneSize.xy;
				pos = CustomRenderTextureRotate2D(pos, rotation);
				pos.x += clipSpaceCenter.x;
			#if UNITY_UV_STARTS_AT_TOP
				pos.y += clipSpaceCenter.y;
			#else
				pos.y -= clipSpaceCenter.y;
			#endif

				// For 3D texture, cull quads outside of the update zone
				// This is neeeded in additional to the preliminary minSlice/maxSlice done on the CPU because update zones can be disjointed.
				// ie: slices [1..5] and [10..15] for two differents zones so we need to cull out slices 0 and [6..9]
				if (CustomRenderTextureIs3D > 0.0)
				{
					int minSlice = (int)(updateZoneCenter.z - updateZoneSize.z * 0.5);
					int maxSlice = minSlice + (int)updateZoneSize.z;
					if (_CustomRenderTexture3DSlice < minSlice || _CustomRenderTexture3DSlice >= maxSlice)
					{
						pos.xy = float2(1000.0, 1000.0); // Vertex outside of ncs
					}
				}

				OUT.vertex = float4(pos, 0.0, 1.0);
				OUT.primitiveID = asuint(CustomRenderTexturePrimitiveIDs[primitiveID]);
				OUT.localTexcoord = float3(texCoords[vertexID], CustomRenderTexture3DTexcoordW);
				OUT.globalTexcoord = float3(pos.xy * 0.5 + 0.5, CustomRenderTexture3DTexcoordW);
			#if UNITY_UV_STARTS_AT_TOP
				OUT.globalTexcoord.y = 1.0 - OUT.globalTexcoord.y;
			#endif
				OUT.direction = CustomRenderTextureComputeCubeDirection(OUT.globalTexcoord.xy);

				return OUT;
			}

            float4 frag(ase_v2f_customrendertexture IN ) : COLOR
            {
				float4 finalColor;
				float2 Size41 = _Size;
				float2 temp_output_18_0 = (_RT_TexelSize).zw;
				float2 Center40 = _Center;
				float2 texCoord7 = IN.localTexcoord.xy * (float2( 0,0 ) + (Size41 - float2( 0,0 )) * (float2( 1,1 ) - float2( 0,0 )) / (temp_output_18_0 - float2( 0,0 ))) + (float2( 0,0 ) + (( ( ( (_RT_TexelSize).zw * float2( 0,1 ) ) - ( Center40 * float2( -1,1 ) ) ) - ( Size41 / float2( 2,2 ) ) ) - float2( 0,0 )) * (float2( 1,1 ) - float2( 0,0 )) / (temp_output_18_0 - float2( 0,0 )));
				float2 temp_output_49_0 = (_RT_TexelSize).zw;
				float2 texCoord54 = IN.localTexcoord.xy * (float2( 0,0 ) + (Size41 - float2( 0,0 )) * (float2( 1,2 ) - float2( 0,0 )) / (temp_output_49_0 - float2( 0,0 ))) + (float2( 0,0 ) + (( ( ( ( (_RT_TexelSize).zw * float2( 0,1 ) ) - ( Center40 * float2( -1,1 ) ) ) - ( Size41 / float2( 2,2 ) ) ) + ( IN.localTexcoord.xy.y > 0.5 ? ( Size41 * float2( -1,-1 ) ) : float2( 0,0 ) ) ) - float2( 0,0 )) * (float2( 1,1 ) - float2( 0,0 )) / (temp_output_49_0 - float2( 0,0 )));
				float4 tex2DNode39 = tex2D( _RT, texCoord54 );
				float4 appendResult36 = (float4(( IN.localTexcoord.xy.y < 0.5 ? tex2DNode39.r : tex2DNode39.g ) , 0.0 , 0.0 , 0.0));
				float3 linearToGamma66 = LinearToGammaSpace( (( _RGSplit )?( appendResult36 ):( tex2D( _RT, texCoord7 ) )).rgb );
				float3 gammaToLinear67 = GammaToLinearSpace( (( _RGSplit )?( appendResult36 ):( tex2D( _RT, texCoord7 ) )).rgb );
				#if defined(_COLORSPACECONVERT_LINEARTOGAMMA)
				float4 staticSwitch68 = float4( linearToGamma66 , 0.0 );
				#elif defined(_COLORSPACECONVERT_RAW)
				float4 staticSwitch68 = (( _RGSplit )?( appendResult36 ):( tex2D( _RT, texCoord7 ) ));
				#elif defined(_COLORSPACECONVERT_GAMMATOLINEAR)
				float4 staticSwitch68 = float4( gammaToLinear67 , 0.0 );
				#else
				float4 staticSwitch68 = (( _RGSplit )?( appendResult36 ):( tex2D( _RT, texCoord7 ) ));
				#endif
				
                finalColor = staticSwitch68;
				return finalColor;
            }
            ENDCG
		}
    }
	
	CustomEditor "ASEMaterialInspector"
	Fallback Off
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.TexturePropertyNode;3;-1760,-528;Inherit;True;Property;_RT;RT;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;86309c450e338be458544111d4f51804;ae67e204164b10844b1cb588885119d4;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexelSizeNode;5;-1472,-480;Inherit;False;-1;1;0;SAMPLER2D;;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;35;2624,-480;Inherit;False;Property;_RGSplit;RGSplit;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;4;1696,-672;Inherit;True;Property;_TextureSample0;Texture Sample 0;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;13;-1840,-1168;Inherit;False;Property;_Center;Center;1;0;Create;True;0;0;0;False;0;False;0,0;319.5,1112.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-1584,-1152;Inherit;False;Center;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;14;-1840,-1024;Inherit;False;Property;_Size;Size;2;0;Create;True;0;0;0;False;0;False;0,0;639,655;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;-1568,-1024;Inherit;False;Size;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;24;560,-560;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;26;560,-320;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;27;-80,-304;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;18;-1200,-448;Inherit;False;False;False;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;30;-1200,-352;Inherit;False;False;False;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-944,-336;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;29;-656,-208;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-864,-176;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;7;1008,-544;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;42;64,-656;Inherit;False;41;Size;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1168,-160;Inherit;False;40;Center;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;28;-352,-80;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;43;-704,-80;Inherit;False;41;Size;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;47;-32,656;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;49;-1152,512;Inherit;False;False;False;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;50;-1152,608;Inherit;False;False;False;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-896,624;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;52;-608,752;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-816,784;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;54;1056,416;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;57;-1120,800;Inherit;False;40;Center;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;48;-288,848;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-544,880;Inherit;False;41;Size;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;46;608,640;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;59;-768,1008;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;61;320,688;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-896,1184;Inherit;False;41;Size;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-112,336;Inherit;False;41;Size;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;45;288,400;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Compare;58;-352,1120;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-608,1200;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-1,-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;36;1968,288;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;39;1376,384;Inherit;True;Property;_TextureSample1;Texture Sample 0;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;37;1440,224;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;38;1776,352;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;3696,-528;Float;False;True;-1;2;ASEMaterialInspector;0;2;Extract Segment Of RT;32120270d1b3a8746af2aca8bc749736;True;Custom RT Update;0;0;Custom RT Update;1;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;0;;0;0;Standard;0;0;1;True;False;;False;0
Node;AmplifyShaderEditor.LinearToGammaNode;66;2912,-560;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GammaToLinearNode;67;2928,-416;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;68;3248,-560;Inherit;False;Property;_ColorSpaceConvert;ColorSpaceConvert;4;0;Create;True;0;0;0;False;0;False;0;1;1;True;;KeywordEnum;3;LinearToGamma;Raw;GammaToLinear;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
WireConnection;5;0;3;0
WireConnection;35;0;4;0
WireConnection;35;1;36;0
WireConnection;4;0;3;0
WireConnection;4;1;7;0
WireConnection;40;0;13;0
WireConnection;41;0;14;0
WireConnection;24;0;42;0
WireConnection;24;2;18;0
WireConnection;26;0;27;0
WireConnection;26;2;18;0
WireConnection;27;0;29;0
WireConnection;27;1;28;0
WireConnection;18;0;5;0
WireConnection;30;0;5;0
WireConnection;31;0;30;0
WireConnection;29;0;31;0
WireConnection;29;1;32;0
WireConnection;32;0;44;0
WireConnection;7;0;24;0
WireConnection;7;1;26;0
WireConnection;28;0;43;0
WireConnection;47;0;52;0
WireConnection;47;1;48;0
WireConnection;49;0;5;0
WireConnection;50;0;5;0
WireConnection;51;0;50;0
WireConnection;52;0;51;0
WireConnection;52;1;53;0
WireConnection;53;0;57;0
WireConnection;54;0;45;0
WireConnection;54;1;46;0
WireConnection;48;0;56;0
WireConnection;46;0;61;0
WireConnection;46;2;49;0
WireConnection;61;0;47;0
WireConnection;61;1;58;0
WireConnection;45;0;55;0
WireConnection;45;2;49;0
WireConnection;58;0;59;2
WireConnection;58;2;63;0
WireConnection;63;0;62;0
WireConnection;36;0;38;0
WireConnection;39;0;3;0
WireConnection;39;1;54;0
WireConnection;38;0;37;2
WireConnection;38;2;39;1
WireConnection;38;3;39;2
WireConnection;0;0;68;0
WireConnection;66;0;35;0
WireConnection;67;0;35;0
WireConnection;68;1;66;0
WireConnection;68;0;35;0
WireConnection;68;2;67;0
ASEEND*/
//CHKSM=545A3116FA1651D8CB8AD28DFD6698A72629894F