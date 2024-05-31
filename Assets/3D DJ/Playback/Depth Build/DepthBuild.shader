// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DepthBuild"
{
	Properties
	{
		[NoScaleOffset][SingleLineTexture]_Color("Color", 2D) = "white" {}
		[NoScaleOffset][SingleLineTexture]_Depth("Depth", 2D) = "white" {}
		[NoScaleOffset][SingleLineTexture]_Data("Data", 2D) = "white" {}
		[Toggle]_NormalsDebug("Normals Debug", Float) = 0
		[Toggle]_Deform("Deform", Float) = 1
		[Toggle]_Sobel("Sobel", Float) = 1
		_SobelThickness("Sobel Thickness", Float) = 0.001
		_SobelThreshold("Sobel Threshold", Float) = 0.1
		_BlackThreshold("BlackThreshold", Float) = 0.01
		[Toggle]_UVPixelation("UV Pixelation", Float) = 0
		[Toggle]_LockPosition("Lock Position", Float) = 0
		[Toggle]_LockRotation("Lock Rotation", Float) = 0
		[Toggle]_ObjectRelevantMode("Object Relevant Mode", Float) = 0
		[Toggle]_FadeWhenNear("Fade When Near", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		AlphaToMask On
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 4.5
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float4 screenPosition;
			float eyeDepth;
		};

		uniform float _ObjectRelevantMode;
		uniform float _LockRotation;
		uniform sampler2D _Data;
		float4 _Data_TexelSize;
		uniform float _LockPosition;
		uniform sampler2D _Depth;
		uniform float _UVPixelation;
		uniform float4 _Depth_ST;
		float4 _Depth_TexelSize;
		uniform float _Sobel;
		uniform float _SobelThickness;
		uniform float _SobelThreshold;
		uniform float _Deform;
		uniform float _NormalsDebug;
		uniform sampler2D _Color;
		uniform float _FadeWhenNear;
		uniform float _BlackThreshold;


		float3 BinaryStripToInt( sampler2D Texture, float4 TexelSize, float2 StripStart, int StripWidth, int PixelSize )
		{
			 float3 totalValue = 0;
			for(int e = 0; e < StripWidth; e++)
			{
			float2 pixelCoord = StripStart;
			pixelCoord.x = StripStart.x + (e * PixelSize);
			float2 pixelUV = (pixelCoord + 0.5f) * TexelSize.xy;
			//float3 pixelValue = Texture.SampleLod(Texture, float4(pixelUV, 0.0, 0.0));
			float3 pixelValue = tex2Dlod(Texture, float4(pixelUV, 0.0, 0.0));
			if (pixelValue.r >= 0.5f)
			{
			totalValue.r += pow(2, e);
			}
			if (pixelValue.g >= 0.5f)
			{
			totalValue.g += pow(2, e);
			}
			if (pixelValue.b >= 0.5f)
			{
			totalValue.b += pow(2, e);
			}
			}
			return totalValue;
		}


		float Sobel66( sampler2D Depth, float2 UV, float Thickness )
		{
			 static float2 sobelSamplePoints[9] = {
				float2(-1, 1), float2(0, 1), float2(1, 1),
				float2(-1, 0), float2(0, 0), float2(1, 0),
				float2(-1, -1), float2(0, -1), float2(1, -1)
			};
			static float sobelXMatrix[9] = {
				1, 0, -1,
				2, 0, -2,
				1, 0, -1
			};
			static float sobelYMatrix[9] = {
				1, 2, 1,
				0, 0, 0,
				-1, -2, -1
			};
			float2 sobel = 0;
			for (int i = 0; i < 9; i++) {
				float depth = tex2Dlod(Depth, float4(UV + sobelSamplePoints[i] * Thickness, 0.0, 0.0)).r;
				sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);
			}
			return length(sobel);
		}


		float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
		{
			original -= center;
			float C = cos( angle );
			float S = sin( angle );
			float t = 1 - C;
			float m00 = t * u.x * u.x + C;
			float m01 = t * u.x * u.y - S * u.z;
			float m02 = t * u.x * u.z + S * u.y;
			float m10 = t * u.x * u.y + S * u.z;
			float m11 = t * u.y * u.y + C;
			float m12 = t * u.y * u.z - S * u.x;
			float m20 = t * u.x * u.z - S * u.y;
			float m21 = t * u.y * u.z + S * u.x;
			float m22 = t * u.z * u.z + C;
			float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
			return mul( finalMatrix, original ) + center;
		}


		float3 ASESafeNormalize(float3 inVec)
		{
			float dp3 = max(1.175494351e-38, dot(inVec, inVec));
			return inVec* rsqrt(dp3);
		}


		inline float Dither8x8Bayer( int x, int y )
		{
			const float dither[ 64 ] = {
				 1, 49, 13, 61,  4, 52, 16, 64,
				33, 17, 45, 29, 36, 20, 48, 32,
				 9, 57,  5, 53, 12, 60,  8, 56,
				41, 25, 37, 21, 44, 28, 40, 24,
				 3, 51, 15, 63,  2, 50, 14, 62,
				35, 19, 47, 31, 34, 18, 46, 30,
				11, 59,  7, 55, 10, 58,  6, 54,
				43, 27, 39, 23, 42, 26, 38, 22};
			int r = y * 8 + x;
			return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			sampler2D Texture1_g376 = _Data;
			float4 TexelSize1_g376 = _Data_TexelSize;
			float2 StripStart1_g376 = float2( 4,4 );
			int StripWidth1_g376 = 20;
			int PixelSize1_g376 = 8;
			float3 localBinaryStripToInt1_g376 = BinaryStripToInt( Texture1_g376 , TexelSize1_g376 , StripStart1_g376 , StripWidth1_g376 , PixelSize1_g376 );
			float3 break532 = ( localBinaryStripToInt1_g376 / float3( 100,100,1 ) );
			float DJ_Rotation536 = (( _LockRotation )?( 0.0 ):( break532.x ));
			sampler2D Texture1_g375 = _Data;
			float4 TexelSize1_g375 = _Data_TexelSize;
			float2 StripStart1_g375 = float2( 4,12 );
			int StripWidth1_g375 = 20;
			int PixelSize1_g375 = 8;
			float3 localBinaryStripToInt1_g375 = BinaryStripToInt( Texture1_g375 , TexelSize1_g375 , StripStart1_g375 , StripWidth1_g375 , PixelSize1_g375 );
			float3 temp_cast_0 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position548 = (( _LockPosition )?( float3( 0,0,0 ) ):( ( ( localBinaryStripToInt1_g375 - temp_cast_0 ) / float3( 100,100,100 ) ) ));
			float2 uv_Depth = v.texcoord.xy * _Depth_ST.xy + _Depth_ST.zw;
			float pixelWidth306 =  1.0f / _Depth_TexelSize.z;
			float pixelHeight306 = 1.0f / _Depth_TexelSize.w;
			half2 pixelateduv306 = half2((int)(uv_Depth.x / pixelWidth306) * pixelWidth306, (int)(uv_Depth.y / pixelHeight306) * pixelHeight306);
			float Depth_Map503 = tex2Dlod( _Depth, float4( (( _UVPixelation )?( pixelateduv306 ):( uv_Depth )), 0, 0.0) ).r;
			sampler2D Depth66 = _Depth;
			float2 UV66 = (( _UVPixelation )?( pixelateduv306 ):( uv_Depth ));
			float Thickness66 = _SobelThickness;
			float localSobel66 = Sobel66( Depth66 , UV66 , Thickness66 );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 temp_cast_1 = (sqrt( -1.0 )).xxx;
			float3 Finalized_Geometry552 = ( ( ( Depth_Map503 - (( _Sobel )?( ( localSobel66 > _SobelThreshold ? 1.0 : 0.0 ) ):( 0.0 )) ) > 0.0 ? 0.0 : 1.0 ) == 0.0 ? ( (( _Deform )?( ( ase_vertexNormal * ( Depth_Map503 - 1.0 ) ) ):( float3( 0,0,0 ) )) + ase_vertex3Pos ) : temp_cast_1 );
			float DJ_Scale538 = break532.y;
			float3 rotatedValue526 = RotateAroundAxis( DJ_Position548, ( ( Finalized_Geometry552 * DJ_Scale538 ) + DJ_Position548 ), float3( 0,1,0 ), radians( DJ_Rotation536 ) );
			float3 objToWorld522 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float4 transform520 = mul(unity_WorldToObject,float4( ( rotatedValue526 - objToWorld522 ) , 0.0 ));
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			v.vertex.xyz = (( _ObjectRelevantMode )?( float4( Finalized_Geometry552 , 0.0 ) ):( ( transform520 + float4( ( objToWorld522 / ase_objectScale ) , 0.0 ) ) )).xyz;
			v.vertex.w = 1;
			float4 ase_screenPos = ComputeScreenPos( UnityObjectToClipPos( v.vertex ) );
			o.screenPosition = ase_screenPos;
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 uv_Color84 = i.uv_texcoord;
			float4 tex2DNode84 = tex2D( _Color, uv_Color84 );
			float3 Color_Map556 = (tex2DNode84).rgb;
			float3 ase_worldPos = i.worldPos;
			float3 temp_output_82_0_g374 = ( ase_worldPos - _WorldSpaceCameraPos );
			float3 temp_output_78_0_g374 = cross( ddy( temp_output_82_0_g374 ) , ddx( temp_output_82_0_g374 ) );
			float3 normalizeResult87_g374 = ASESafeNormalize( temp_output_78_0_g374 );
			float3 temp_output_102_0 = (( _NormalsDebug )?( normalizeResult87_g374 ):( (Color_Map556).xyz ));
			o.Emission = temp_output_102_0;
			float4 ase_screenPos = i.screenPosition;
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float2 clipScreen474 = ase_screenPosNorm.xy * _ScreenParams.xy;
			float dither474 = Dither8x8Bayer( fmod(clipScreen474.x, 8), fmod(clipScreen474.y, 8) );
			float Alpha_Map502 = tex2DNode84.a;
			float2 uv_Depth = i.uv_texcoord * _Depth_ST.xy + _Depth_ST.zw;
			float pixelWidth306 =  1.0f / _Depth_TexelSize.z;
			float pixelHeight306 = 1.0f / _Depth_TexelSize.w;
			half2 pixelateduv306 = half2((int)(uv_Depth.x / pixelWidth306) * pixelWidth306, (int)(uv_Depth.y / pixelHeight306) * pixelHeight306);
			float Depth_Map503 = tex2D( _Depth, (( _UVPixelation )?( pixelateduv306 ):( uv_Depth )) ).r;
			float Final_Geometry_Alpha632 = ( Alpha_Map502 > _BlackThreshold ? Alpha_Map502 : ( Depth_Map503 > _BlackThreshold ? 1.0 : 0.0 ) );
			float cameraDepthFade634 = (( i.eyeDepth -_ProjectionParams.y - 0.0 ) / 0.3);
			float clampResult635 = clamp( (( _FadeWhenNear )?( ( Final_Geometry_Alpha632 * cameraDepthFade634 ) ):( Final_Geometry_Alpha632 )) , 0.0 , 1.0 );
			dither474 = step( dither474, clampResult635 );
			o.Alpha = dither474;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows exclude_path:deferred vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			AlphaToMask Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack2.xyzw = customInputData.screenPosition;
				o.customPack1.z = customInputData.eyeDepth;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.screenPosition = IN.customPack2.xyzw;
				surfIN.eyeDepth = IN.customPack1.z;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.CommentaryNode;172;-1556.254,847.7728;Inherit;False;2073.453;597.2609;Outline Trimming;8;66;70;94;67;77;95;432;555;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-1346.383,1294.148;Inherit;False;Property;_SobelThickness;Sobel Thickness;6;0;Create;True;0;0;0;False;0;False;0.001;0.001;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;70;-345.4992,1144.155;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;94;-614.7399,1144.909;Inherit;False;Property;_Sobel;Sobel;5;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;77;-792.6415,1115.171;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;95;-975.8925,1332.034;Inherit;False;Property;_SobelThreshold;Sobel Threshold;7;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;432;-56.85941,1208.266;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;143;503.0409,1514.053;Inherit;False;Property;_Deform;Deform;4;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;420;528.7499,1625.52;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;138;-5.655613,1716.57;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;139;-22.52252,1555.125;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;274.118,1622.481;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;424;778.2564,1559.839;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;508;2064,1552;Inherit;False;2656.647;2166.576;De-Link Object Scale;13;549;540;539;529;528;527;526;515;512;511;510;509;553;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;509;2592,2976;Inherit;False;2079.695;621.78;Rotation and Scale;10;568;533;560;531;538;530;535;536;534;532;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;510;2576,2304;Inherit;False;2091.201;609.1387;Position Data;9;548;545;541;547;546;543;544;542;567;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;511;3872,1584;Inherit;False;844.2227;536.0916;Bring Back To Object;6;524;523;522;521;520;519;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;512;2096,1760;Inherit;False;682.4991;314.1565;Align Origin To Floor;5;537;525;518;517;516;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;515;2736,1584;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;516;2320,1808;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;517;2480,1808;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;518;2656,1856;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;519;4016,1632;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldToObjectTransfNode;520;4208,1632;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;521;4560,1648;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;525;2432,1952;Inherit;False;548;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;526;3520,1648;Inherit;False;False;4;0;FLOAT3;0,1,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;532;3584,3056;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.IntNode;534;2640,3184;Inherit;False;Constant;_StripLength1;StripLength;8;0;Create;True;0;0;0;False;0;False;20;0;False;0;1;INT;0
Node;AmplifyShaderEditor.GetLocalVarNode;537;2112,1808;Inherit;False;538;DJ Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;542;3312,2512;Inherit;False;False;2;0;FLOAT;2;False;1;FLOAT;19;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;544;3744,2352;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;100,100,100;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;462;1280,1312;Inherit;False;VertexClip;-1;;372;6b01c471edbbafc45b3ee035e6cf458a;0;3;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;552;1600,1312;Inherit;False;Finalized Geometry;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;555;-592,1040;Inherit;False;503;Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;543;3504,2352;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IntNode;546;2688,2528;Inherit;False;Constant;_StripLength;StripLength;8;0;Create;True;0;0;0;False;0;False;20;0;False;0;1;INT;0
Node;AmplifyShaderEditor.IntNode;535;2672,3280;Inherit;False;Constant;_PixelSize1;Pixel Size;8;0;Create;True;0;0;0;False;0;False;8;0;False;0;1;INT;0
Node;AmplifyShaderEditor.Vector2Node;530;2640,3040;Inherit;False;Constant;_Vector2;Vector 0;11;0;Create;True;0;0;0;False;0;False;4,4;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;541;2640,2352;Inherit;False;Constant;_Vector1;Vector 0;11;0;Create;True;0;0;0;False;0;False;4,12;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.FunctionNode;101;4304,1040;Inherit;False;World Normal Face;-1;;374;8ad4248928242e14ab87cd99e6913c33;1,86,1;0;1;FLOAT3;30
Node;AmplifyShaderEditor.ComponentMaskNode;559;-2528,1776;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;556;-2304,1776;Inherit;False;Color Map;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;2;-2832,1584;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;463;-3200,1584;Inherit;True;Property;_Depth;Depth;1;2;[NoScaleOffset];[SingleLineTexture];Create;True;0;0;0;False;0;False;283657a5e09fe4444882d8963bc94119;d5eade7947abe2d4ea65c23f9a0c12b3;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TextureCoordinatesNode;308;-2864,1216;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexelSizeNode;307;-2864,1344;Inherit;False;-1;1;0;SAMPLER2D;;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;456;-2304,1328;Inherit;False;Property;_UVPixelation;UV Pixelation;9;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCPixelate;306;-2544,1392;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;84;-2832,1776;Inherit;True;Property;_TextureSample1;Texture Sample 1;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;545;3040,2352;Inherit;False;Binary To Int;-1;;375;55f49686de3e34b43b433d705b23ee3e;0;4;2;SAMPLER2D;0;False;5;FLOAT2;0,0;False;6;INT;0;False;7;INT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;531;3408,3040;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;100,100,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;533;3056,3056;Inherit;False;Binary To Int;-1;;376;55f49686de3e34b43b433d705b23ee3e;0;4;2;SAMPLER2D;0;False;5;FLOAT2;0,0;False;6;INT;0;False;7;INT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;502;-2304,1872;Inherit;False;Alpha Map;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;528;2944,1696;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RadiansOpNode;527;3120,1600;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;529;2928,1600;Inherit;False;536;DJ Rotation;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;549;3104,1792;Inherit;False;548;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;548;4304,2352;Inherit;False;DJ Position;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;536;4320,3040;Inherit;False;DJ Rotation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;538;4336,3136;Inherit;False;DJ Scale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;560;4320,3232;Inherit;False;Settings;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;568;3920,3040;Inherit;False;Property;_LockRotation;Lock Rotation;12;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;567;3984,2352;Inherit;False;Property;_LockPosition;Lock Position;10;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;573;4432,1440;Inherit;False;552;Finalized Geometry;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;81;-3200,1776;Inherit;True;Property;_Color;Color;0;2;[NoScaleOffset];[SingleLineTexture];Create;True;1;Input Render Textures;0;0;False;0;False;d5eade7947abe2d4ea65c23f9a0c12b3;d5eade7947abe2d4ea65c23f9a0c12b3;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.IntNode;547;2720,2656;Inherit;False;Constant;_PixelSize;Pixel Size;8;0;Create;True;0;0;0;False;0;False;8;0;False;0;1;INT;0
Node;AmplifyShaderEditor.TexturePropertyNode;540;2128,2752;Inherit;True;Property;_Data;Data;2;2;[NoScaleOffset];[SingleLineTexture];Create;True;0;0;0;False;0;False;b638e271c536ea24cb3cf67f3d34c317;b638e271c536ea24cb3cf67f3d34c317;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.CustomExpressionNode;66;-1070.159,1157.916;Inherit;False; static float2 sobelSamplePoints[9] = {$	float2(-1, 1), float2(0, 1), float2(1, 1),$	float2(-1, 0), float2(0, 0), float2(1, 0),$	float2(-1, -1), float2(0, -1), float2(1, -1)$}@$$static float sobelXMatrix[9] = {$	1, 0, -1,$	2, 0, -2,$	1, 0, -1$}@$$static float sobelYMatrix[9] = {$	1, 2, 1,$	0, 0, 0,$	-1, -2, -1$}@$$float2 sobel = 0@$for (int i = 0@ i < 9@ i++) {$	float depth = tex2Dlod(Depth, float4(UV + sobelSamplePoints[i] * Thickness, 0.0, 0.0)).r@$	sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i])@$}$return length(sobel)@;1;Create;3;True;Depth;SAMPLER2D;0,0,0;In;;Inherit;False;True;UV;FLOAT2;0,0;In;;Inherit;False;True;Thickness;FLOAT;0;In;;Inherit;False;Sobel;True;False;0;;False;3;0;SAMPLER2D;0,0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;503;-1664,1616;Inherit;True;Depth Map;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;557;4016,992;Inherit;False;556;Color Map;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;453;4320,928;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;553;2224,1600;Inherit;False;552;Finalized Geometry;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;554;-320,1664;Inherit;False;503;Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;539;2544,1680;Inherit;False;538;DJ Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;522;3904,1840;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectScaleNode;524;4208,1936;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;523;4496,1872;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;569;4896,1568;Inherit;False;Property;_ObjectRelevantMode;Object Relevant Mode;13;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleRemainderNode;587;4224,-224;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;589;4448,-224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;592;3872,-224;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.PosVertexDataNode;598;3232,-224;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;604;3584,-224;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;619;4080,-224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;616;3600,-336;Inherit;False;1;0;FLOAT;0.008;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;623;4032,-400;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;621;5136,-256;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;626;5344,-240;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;620;4416,-464;Inherit;True;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;625;5568,-256;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;588;4752,-224;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;624;4768,-464;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;630;5776,-256;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.07843138;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;627;5536,-80;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.HSVToRGBNode;628;6112,-80;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;629;5920,-144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;7328,1008;Float;False;True;-1;5;ASEMaterialInspector;0;0;Unlit;DepthBuild;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0;True;True;0;True;TransparentCutout;;Geometry;ForwardOnly;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;0;10;10;25;False;1;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0.77;0,0,0,0;VertexScale;True;False;Cylindrical;False;True;Absolute;0;;11;-1;-1;-1;0;True;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.ToggleSwitchNode;102;4592,944;Inherit;True;Property;_NormalsDebug;Normals Debug;3;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;501;3008,320;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;505;2544,432;Inherit;True;503;Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;506;2784,448;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;504;2544,240;Inherit;True;502;Alpha Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;566;2304,384;Inherit;False;Property;_BlackThreshold;BlackThreshold;8;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;633;5440,1104;Inherit;False;632;Final Geometry Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;636;5968,1248;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;632;3440,320;Inherit;False;Final Geometry Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;631;6320,1184;Inherit;False;Property;_FadeWhenNear;Fade When Near;14;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;635;6688,1184;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DitheringNode;474;6992,1216;Inherit;False;1;False;4;0;FLOAT;0;False;1;SAMPLER2D;;False;2;FLOAT4;0,0,0,0;False;3;SAMPLERSTATE;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CameraDepthFade;634;5472,1264;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;0.3;False;1;FLOAT;0;False;1;FLOAT;0
WireConnection;70;0;555;0
WireConnection;70;1;94;0
WireConnection;94;1;77;0
WireConnection;77;0;66;0
WireConnection;77;1;95;0
WireConnection;432;0;70;0
WireConnection;143;1;7;0
WireConnection;138;0;554;0
WireConnection;7;0;139;0
WireConnection;7;1;138;0
WireConnection;424;0;143;0
WireConnection;424;1;420;0
WireConnection;515;0;553;0
WireConnection;515;1;539;0
WireConnection;516;0;537;0
WireConnection;517;1;516;0
WireConnection;518;0;517;0
WireConnection;518;1;525;0
WireConnection;519;0;526;0
WireConnection;519;1;522;0
WireConnection;520;0;519;0
WireConnection;521;0;520;0
WireConnection;521;1;523;0
WireConnection;526;1;527;0
WireConnection;526;2;549;0
WireConnection;526;3;528;0
WireConnection;532;0;531;0
WireConnection;544;0;543;0
WireConnection;462;4;432;0
WireConnection;462;6;424;0
WireConnection;552;0;462;0
WireConnection;543;0;545;0
WireConnection;543;1;542;0
WireConnection;559;0;84;0
WireConnection;556;0;559;0
WireConnection;2;0;463;0
WireConnection;2;1;456;0
WireConnection;308;2;463;0
WireConnection;307;0;463;0
WireConnection;456;0;308;0
WireConnection;456;1;306;0
WireConnection;306;0;308;0
WireConnection;306;1;307;3
WireConnection;306;2;307;4
WireConnection;84;0;81;0
WireConnection;545;2;540;0
WireConnection;545;5;541;0
WireConnection;545;6;546;0
WireConnection;545;7;547;0
WireConnection;531;0;533;0
WireConnection;533;2;540;0
WireConnection;533;5;530;0
WireConnection;533;6;534;0
WireConnection;533;7;535;0
WireConnection;502;0;84;4
WireConnection;528;0;515;0
WireConnection;528;1;525;0
WireConnection;527;0;529;0
WireConnection;548;0;567;0
WireConnection;536;0;568;0
WireConnection;538;0;532;1
WireConnection;560;0;532;2
WireConnection;568;0;532;0
WireConnection;567;0;544;0
WireConnection;66;0;463;0
WireConnection;66;1;456;0
WireConnection;66;2;67;0
WireConnection;503;0;2;1
WireConnection;453;0;557;0
WireConnection;523;0;522;0
WireConnection;523;1;524;0
WireConnection;569;0;521;0
WireConnection;569;1;573;0
WireConnection;587;0;619;0
WireConnection;589;0;587;0
WireConnection;592;0;604;0
WireConnection;604;0;598;0
WireConnection;619;0;616;0
WireConnection;619;1;592;1
WireConnection;623;0;604;0
WireConnection;623;2;616;0
WireConnection;621;0;624;0
WireConnection;621;1;588;0
WireConnection;626;0;621;0
WireConnection;620;0;623;0
WireConnection;625;0;588;0
WireConnection;588;0;589;0
WireConnection;624;0;620;0
WireConnection;630;0;625;0
WireConnection;627;0;102;0
WireConnection;628;0;629;0
WireConnection;628;1;627;2
WireConnection;628;2;627;3
WireConnection;629;0;630;0
WireConnection;629;1;627;1
WireConnection;0;2;102;0
WireConnection;0;9;474;0
WireConnection;0;11;569;0
WireConnection;102;0;453;0
WireConnection;102;1;101;30
WireConnection;501;0;504;0
WireConnection;501;1;566;0
WireConnection;501;2;504;0
WireConnection;501;3;506;0
WireConnection;506;0;505;0
WireConnection;506;1;566;0
WireConnection;636;0;633;0
WireConnection;636;1;634;0
WireConnection;632;0;501;0
WireConnection;631;0;633;0
WireConnection;631;1;636;0
WireConnection;635;0;631;0
WireConnection;474;0;635;0
ASEEND*/
//CHKSM=67296E5812A820304C4AD69E6ACBD19B21122A84