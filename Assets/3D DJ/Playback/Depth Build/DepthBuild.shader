// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DepthBuild"
{
	Properties
	{
		[Toggle]_Sobel("Sobel", Float) = 1
		_SobelThickness("Sobel Thickness", Float) = 0.001
		_SobelThreshold("Sobel Threshold", Float) = 0.1
		[Toggle]_UVPixelation("UV Pixelation", Float) = 0
		[Toggle]_LockPosition("Lock Position", Float) = 0
		[Toggle]_LockRotation("Lock Rotation", Float) = 0
		[Toggle]_ObjectRelevantMode("Object Relevant Mode", Float) = 0
		[Toggle]_FadeWhenNear("Fade When Near", Float) = 1
		[Toggle]_HoloAffect("Holo Affect", Float) = 0
		[KeywordEnum(Standard,Normals,NoDeformation,VertexPosition,FaceIndex)] _Mode("Mode", Float) = 0
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
		#pragma shader_feature_local _MODE_STANDARD _MODE_NORMALS _MODE_NODEFORMATION _MODE_VERTEXPOSITION _MODE_FACEINDEX
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			float4 screenPosition;
			float eyeDepth;
		};

		uniform float _ObjectRelevantMode;
		uniform float _LockRotation;
		uniform sampler2D _Udon_3DJ_Data;
		float4 _Udon_3DJ_Data_TexelSize;
		uniform float _LockPosition;
		uniform sampler2D _Udon_3DJ_Depth;
		uniform float _UVPixelation;
		uniform float4 _Udon_3DJ_Depth_ST;
		float4 _Udon_3DJ_Depth_TexelSize;
		uniform float _Sobel;
		uniform float _SobelThickness;
		uniform float _SobelThreshold;
		uniform float _HoloAffect;
		uniform sampler2D _Udon_3DJ_Color;
		uniform float4 _Udon_3DJ_Color_ST;
		uniform float _FadeWhenNear;


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


		float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RGBToHSV(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
			float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
			float d = q.x - min( q.w, q.y );
			float e = 1.0e-10;
			return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
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
			sampler2D Texture1_g400 = _Udon_3DJ_Data;
			float4 TexelSize1_g400 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult25_g398 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( _Udon_3DJ_Data_TexelSize.w / 3.0 )));
			float2 StripStart1_g400 = appendResult25_g398;
			int StripWidth1_g400 = 20;
			int PixelSize1_g400 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g400 = BinaryStripToInt( Texture1_g400 , TexelSize1_g400 , StripStart1_g400 , StripWidth1_g400 , PixelSize1_g400 );
			float3 break17_g398 = ( localBinaryStripToInt1_g400 / float3( 100,100,1 ) );
			float DJ_Rotation536 = (( _LockRotation )?( 0.0 ):( break17_g398.x ));
			sampler2D Texture1_g399 = _Udon_3DJ_Data;
			float4 TexelSize1_g399 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult7_g398 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( ( _Udon_3DJ_Data_TexelSize.w / 3.0 ) * 2.0 )));
			float2 StripStart1_g399 = appendResult7_g398;
			int StripWidth1_g399 = 20;
			int PixelSize1_g399 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g399 = BinaryStripToInt( Texture1_g399 , TexelSize1_g399 , StripStart1_g399 , StripWidth1_g399 , PixelSize1_g399 );
			float3 temp_cast_2 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position548 = (( _LockPosition )?( float3( 0,0,0 ) ):( ( ( localBinaryStripToInt1_g399 - temp_cast_2 ) / float3( 100,100,100 ) ) ));
			float2 uv_Udon_3DJ_Depth = v.texcoord.xy * _Udon_3DJ_Depth_ST.xy + _Udon_3DJ_Depth_ST.zw;
			float pixelWidth306 =  1.0f / _Udon_3DJ_Depth_TexelSize.z;
			float pixelHeight306 = 1.0f / _Udon_3DJ_Depth_TexelSize.w;
			half2 pixelateduv306 = half2((int)(uv_Udon_3DJ_Depth.x / pixelWidth306) * pixelWidth306, (int)(uv_Udon_3DJ_Depth.y / pixelHeight306) * pixelHeight306);
			float4 tex2DNode2 = tex2Dlod( _Udon_3DJ_Depth, float4( (( _UVPixelation )?( pixelateduv306 ):( uv_Udon_3DJ_Depth )), 0, 0.0) );
			float Raw_Depth_Map503 = ( tex2DNode2.r > 0.007843138 ? tex2DNode2.r : 0.0 );
			sampler2D Depth66 = _Udon_3DJ_Depth;
			float2 UV66 = (( _UVPixelation )?( pixelateduv306 ):( uv_Udon_3DJ_Depth ));
			float Thickness66 = _SobelThickness;
			float localSobel66 = Sobel66( Depth66 , UV66 , Thickness66 );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 temp_output_7_0 = ( ase_vertexNormal * ( Raw_Depth_Map503 - 1.0 ) );
			#if defined(_MODE_STANDARD)
				float3 staticSwitch676 = temp_output_7_0;
			#elif defined(_MODE_NORMALS)
				float3 staticSwitch676 = temp_output_7_0;
			#elif defined(_MODE_NODEFORMATION)
				float3 staticSwitch676 = float3( 0,0,0 );
			#elif defined(_MODE_VERTEXPOSITION)
				float3 staticSwitch676 = temp_output_7_0;
			#elif defined(_MODE_FACEINDEX)
				float3 staticSwitch676 = temp_output_7_0;
			#else
				float3 staticSwitch676 = temp_output_7_0;
			#endif
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 temp_cast_3 = (sqrt( -1.0 )).xxx;
			float3 Finalized_Geometry552 = ( ( ( Raw_Depth_Map503 - (( _Sobel )?( ( localSobel66 > _SobelThreshold ? 1.0 : 0.0 ) ):( 0.0 )) ) > 0.0 ? 0.0 : 1.0 ) == 0.0 ? ( staticSwitch676 + ase_vertex3Pos ) : temp_cast_3 );
			float DJ_Scale538 = break17_g398.y;
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
			float2 uv_Udon_3DJ_Color = i.uv_texcoord * _Udon_3DJ_Color_ST.xy + _Udon_3DJ_Color_ST.zw;
			float4 tex2DNode84 = tex2D( _Udon_3DJ_Color, uv_Udon_3DJ_Color );
			float3 Color_Map556 = (tex2DNode84).rgb;
			float4 appendResult656 = (float4(Color_Map556 , 1.0));
			float4 color643 = IsGammaSpace() ? float4(0,1,0.9797904,0.7490196) : float4(0,1,0.9546406,0.7490196);
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = i.worldNormal;
			float fresnelNdotV669 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode669 = ( 0.0 + 1.0 * pow( max( 1.0 - fresnelNdotV669 , 0.0001 ), 5.0 ) );
			float4 temp_cast_0 = (2.0).xxxx;
			float4 clampResult672 = clamp( ( color643 + ( fresnelNode669 * color643 ) ) , float4( 0,0,0,0 ) , temp_cast_0 );
			float mulTime616 = _Time.y * 0.008;
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float4 transform604 = mul(unity_ObjectToWorld,ase_vertex4Pos);
			float temp_output_588_0 = ( ( ( ( mulTime616 + transform604.y ) % 0.01 ) * 100.0 ) > 0.5 ? 1.0 : 0.0 );
			float clampResult625 = clamp( temp_output_588_0 , 0.0 , 1.0 );
			float temp_output_630_0 = ( clampResult625 * 0.07843138 );
			float3 hsvTorgb627 = RGBToHSV( Color_Map556 );
			float3 hsvTorgb628 = HSVToRGB( float3(( temp_output_630_0 + hsvTorgb627.x ),hsvTorgb627.y,hsvTorgb627.z) );
			float4 appendResult652 = (float4(hsvTorgb628 , (1.0 + (temp_output_630_0 - 0.0) * (0.0 - 1.0) / (1.0 - 0.0))));
			float3 temp_output_453_0 = ((( _HoloAffect )?( ( clampResult672 * appendResult652 ) ):( appendResult656 ))).rgb;
			float3 temp_output_82_0_g379 = ( ase_worldPos - _WorldSpaceCameraPos );
			float3 temp_output_78_0_g379 = cross( ddy( temp_output_82_0_g379 ) , ddx( temp_output_82_0_g379 ) );
			float3 normalizeResult87_g379 = ASESafeNormalize( temp_output_78_0_g379 );
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			ase_vertexNormal = normalize( ase_vertexNormal );
			float4 color697 = IsGammaSpace() ? float4(1,0,0.8401976,0) : float4(1,0,0.6742168,0);
			float4 color698 = IsGammaSpace() ? float4(1,0.4090407,0,0) : float4(1,0.1392928,0,0);
			float4 color696 = IsGammaSpace() ? float4(0.4763684,0,1,0) : float4(0.1928163,0,1,0);
			float4 color695 = IsGammaSpace() ? float4(0,1,0.002788067,0) : float4(0,1,0.0002157947,0);
			float4 color692 = IsGammaSpace() ? float4(1,0,0,0) : float4(1,0,0,0);
			float4 color694 = IsGammaSpace() ? float4(0,0.1812067,1,0) : float4(0,0.02754834,1,0);
			float4 FaceIndex682 = (( ase_vertexNormal.x >= -0.5 && ase_vertexNormal.x <= 0.5 ) ? (( ase_vertexNormal.y >= -0.5 && ase_vertexNormal.y <= 0.5 ) ? (( ase_vertexNormal.z >= -0.5 && ase_vertexNormal.z <= 0.5 ) ? float4( 0,0,0,0 ) :  ( ase_vertexNormal.z < 0.0 ? color697 : color698 ) ) :  ( ase_vertexNormal.y < 0.0 ? color696 : color695 ) ) :  ( ase_vertexNormal.x < 0.0 ? color692 : color694 ) );
			#if defined(_MODE_STANDARD)
				float4 staticSwitch675 = float4( temp_output_453_0 , 0.0 );
			#elif defined(_MODE_NORMALS)
				float4 staticSwitch675 = float4( normalizeResult87_g379 , 0.0 );
			#elif defined(_MODE_NODEFORMATION)
				float4 staticSwitch675 = float4( temp_output_453_0 , 0.0 );
			#elif defined(_MODE_VERTEXPOSITION)
				float4 staticSwitch675 = float4( ase_vertex3Pos , 0.0 );
			#elif defined(_MODE_FACEINDEX)
				float4 staticSwitch675 = FaceIndex682;
			#else
				float4 staticSwitch675 = float4( temp_output_453_0 , 0.0 );
			#endif
			o.Emission = staticSwitch675.rgb;
			float4 ase_screenPos = i.screenPosition;
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float2 clipScreen474 = ase_screenPosNorm.xy * _ScreenParams.xy;
			float dither474 = Dither8x8Bayer( fmod(clipScreen474.x, 8), fmod(clipScreen474.y, 8) );
			float Alpha_Map502 = tex2DNode84.a;
			float2 uv_Udon_3DJ_Depth = i.uv_texcoord * _Udon_3DJ_Depth_ST.xy + _Udon_3DJ_Depth_ST.zw;
			float pixelWidth306 =  1.0f / _Udon_3DJ_Depth_TexelSize.z;
			float pixelHeight306 = 1.0f / _Udon_3DJ_Depth_TexelSize.w;
			half2 pixelateduv306 = half2((int)(uv_Udon_3DJ_Depth.x / pixelWidth306) * pixelWidth306, (int)(uv_Udon_3DJ_Depth.y / pixelHeight306) * pixelHeight306);
			float4 tex2DNode2 = tex2D( _Udon_3DJ_Depth, (( _UVPixelation )?( pixelateduv306 ):( uv_Udon_3DJ_Depth )) );
			float Raw_Depth_Map503 = ( tex2DNode2.r > 0.007843138 ? tex2DNode2.r : 0.0 );
			float Final_Geometry_Alpha632 = ( Alpha_Map502 > 0.03921569 ? Alpha_Map502 : ( Raw_Depth_Map503 > 0.03921569 ? 1.0 : 0.0 ) );
			float cameraDepthFade634 = (( i.eyeDepth -_ProjectionParams.y - 0.0 ) / 0.3);
			float clampResult635 = clamp( (( _FadeWhenNear )?( ( Final_Geometry_Alpha632 * cameraDepthFade634 ) ):( Final_Geometry_Alpha632 )) , 0.0 , 1.0 );
			dither474 = step( dither474, ( (( _HoloAffect )?( ( clampResult672 * appendResult652 ) ):( appendResult656 )).a * clampResult635 ) );
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
				float3 worldNormal : TEXCOORD4;
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
				o.worldNormal = worldNormal;
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
				surfIN.worldNormal = IN.worldNormal;
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
Node;AmplifyShaderEditor.CommentaryNode;172;-4240,816;Inherit;False;2073.453;597.2609;Outline Trimming;8;66;70;94;67;77;95;432;555;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;508;2064,1552;Inherit;False;2694.573;926.3879;De-Link Object Scale;16;539;553;549;529;527;528;526;515;512;511;536;568;538;548;567;731;;1,1,1,1;0;0
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
Node;AmplifyShaderEditor.GetLocalVarNode;537;2112,1808;Inherit;False;538;DJ Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;528;2944,1696;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RadiansOpNode;527;3120,1600;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;529;2928,1600;Inherit;False;536;DJ Rotation;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;549;3104,1792;Inherit;False;548;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;573;4432,1440;Inherit;False;552;Finalized Geometry;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;553;2224,1600;Inherit;False;552;Finalized Geometry;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;539;2544,1680;Inherit;False;538;DJ Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;522;3904,1840;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectScaleNode;524;4208,1936;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;523;4496,1872;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;569;4896,1568;Inherit;False;Property;_ObjectRelevantMode;Object Relevant Mode;15;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleRemainderNode;587;4224,-224;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;589;4448,-224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;592;3872,-224;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.PosVertexDataNode;598;3232,-224;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;604;3584,-224;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;619;4080,-224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;623;4032,-400;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;621;5136,-256;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;626;5344,-240;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;620;4416,-464;Inherit;True;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;625;5568,-256;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;588;4752,-224;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;624;4768,-464;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;627;5536,-80;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;629;5920,-144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;506;2784,448;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;633;5440,1104;Inherit;False;632;Final Geometry Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;636;5968,1248;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;631;6320,1184;Inherit;False;Property;_FadeWhenNear;Fade When Near;16;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CameraDepthFade;634;5472,1264;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;0.3;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-4032,1248;Inherit;False;Property;_SobelThickness;Sobel Thickness;10;0;Create;True;0;0;0;False;0;False;0.001;0.001;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;70;-3024,1104;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;94;-3296,1104;Inherit;False;Property;_Sobel;Sobel;9;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;77;-3472,1072;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;95;-3648,1296;Inherit;False;Property;_SobelThreshold;Sobel Threshold;11;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;432;-2736,1168;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;138;-2688,1680;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;139;-2704,1520;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-2400,1584;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;555;-3264,1008;Inherit;False;503;Raw Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;308;-5536,1184;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexelSizeNode;307;-5536,1312;Inherit;False;-1;1;0;SAMPLER2D;;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;456;-4976,1296;Inherit;False;Property;_UVPixelation;UV Pixelation;12;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;554;-2992,1632;Inherit;False;503;Raw Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;559;-5200,1920;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;84;-5504,1920;Inherit;True;Property;_TextureSample1;Texture Sample 1;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;502;-4976,2016;Inherit;False;Alpha Map;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;556;-4976,1920;Inherit;False;Color Map;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCPixelate;306;-5216,1360;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;462;-1392,1280;Inherit;False;VertexClip;-1;;377;6b01c471edbbafc45b3ee035e6cf458a;0;3;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;616;3600,-336;Inherit;False;1;0;FLOAT;0.008;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;645;3328,-336;Inherit;False;Constant;_HoloScrollSpeed;Holo Scroll Speed;16;0;Create;True;0;0;0;False;0;False;0.008;0.008;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;635;6688,1184;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DitheringNode;474;7376,1184;Inherit;False;1;False;4;0;FLOAT;0;False;1;SAMPLER2D;;False;2;FLOAT4;0,0,0,0;False;3;SAMPLERSTATE;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;649;6800,944;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;655;7088,1184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;652;6464,-64;Inherit;False;COLOR;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;656;6912.797,-206.4306;Inherit;False;COLOR;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;630;5776,-256;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.07843138;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;659;7280,-160;Inherit;False;Property;_HoloAffect;Holo Affect;17;0;Create;True;0;0;0;False;0;False;0;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;557;5248,-32;Inherit;False;556;Color Map;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;644;7024,-80;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;647;6624,-448;Inherit;False;556;Color Map;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.HSVToRGBNode;628;6112,-80;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TFHCRemapNode;658;6128,-272;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;643;6112,-448;Inherit;False;Constant;_HoloColor;HoloColor;16;0;Create;True;0;0;0;False;0;False;0,1,0.9797904,0.7490196;0,1,0.9797904,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;670;6560,-320;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;672;6704,-224;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;673;6448,-176;Inherit;False;Constant;_Float0;Float 0;17;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;669;5840,-816;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;671;6096,-784;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;676;-2144,1408;Inherit;False;Property;_Keyword0;Keyword 0;18;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;675;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;420;-2112,1632;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;9056,1008;Float;False;True;-1;5;ASEMaterialInspector;0;0;Unlit;DepthBuild;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0;True;True;0;True;TransparentCutout;;Geometry;ForwardOnly;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;0;10;10;25;False;1;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0.77;0,0,0,0;VertexScale;True;False;Cylindrical;False;True;Absolute;0;;19;-1;-1;-1;0;True;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.ComponentMaskNode;453;7664,576;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;675;8080,608;Inherit;False;Property;_Mode;Mode;18;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;5;Standard;Normals;NoDeformation;VertexPosition;FaceIndex;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;677;7680,784;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;101;7648,688;Inherit;False;World Normal Face;-1;;379;8ad4248928242e14ab87cd99e6913c33;1,86,1;0;1;FLOAT3;30
Node;AmplifyShaderEditor.GetLocalVarNode;683;7664,960;Inherit;False;682;FaceIndex;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;694;6688,2512;Inherit;False;Constant;_Color1;Color 0;15;0;Create;True;0;0;0;False;0;False;0,0.1812067,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;692;6688,2336;Inherit;False;Constant;_Color0;Color 0;15;0;Create;True;0;0;0;False;0;False;1,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;696;6688,2688;Inherit;False;Constant;_Color3;Color 0;15;0;Create;True;0;0;0;False;0;False;0.4763684,0,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;695;6688,2864;Inherit;False;Constant;_Color2;Color 0;15;0;Create;True;0;0;0;False;0;False;0,1,0.002788067,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;693;7248,2368;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;697;6688,3040;Inherit;False;Constant;_Color4;Color 0;15;0;Create;True;0;0;0;False;0;False;1,0,0.8401976,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;698;6688,3216;Inherit;False;Constant;_Color5;Color 0;15;0;Create;True;0;0;0;False;0;False;1,0.4090407,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;699;7248,2528;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;691;7248,2208;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;682;8512,2176;Inherit;False;FaceIndex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;707;8192,2176;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;0.5;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;708;7952,2352;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;0.5;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;709;7568,2528;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;0.5;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;503;-4784,1760;Inherit;False;Raw Depth Map;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;505;2544,432;Inherit;True;503;Raw Depth Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;501;3036,255;Inherit;True;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;632;3440,320;Inherit;False;Final Geometry Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;504;2544,240;Inherit;True;502;Alpha Map;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;566;2304,384;Inherit;False;Constant;_TransparencyBlackThreshold;TransparencyBlackThreshold;6;0;Create;True;0;0;0;False;0;False;0.03921569;0.03921569;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;725;-5056.483,1737.272;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;726;-5370.483,1624.272;Inherit;False;Constant;_DepthThreshold;DepthThreshold;14;0;Create;True;0;0;0;False;0;False;0.007843138;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;536;3520,2096;Inherit;False;DJ Rotation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;568;3120,2096;Inherit;False;Property;_LockRotation;Lock Rotation;14;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;538;3536,2192;Inherit;False;DJ Scale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;548;3552,2272;Inherit;False;DJ Position;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;567;3232,2272;Inherit;False;Property;_LockPosition;Lock Position;13;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;732;-5872,1696;Inherit;False;Global Textures;0;;397;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.SamplerNode;2;-5504,1728;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;731;2768,2112;Inherit;False;Get DJ Data;4;;398;fd74dea831d77af4ea5f66eb0518196e;0;1;14;SAMPLER2D;;False;3;FLOAT;31;FLOAT;32;FLOAT3;13
Node;AmplifyShaderEditor.SimpleAddOpNode;424;-1782.9,1408.2;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;552;-853.0531,1276.013;Inherit;False;Finalized Geometry;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;687;6720,2112;Inherit;True;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;66;-3744,1120;Inherit;False; static float2 sobelSamplePoints[9] = {$	float2(-1, 1), float2(0, 1), float2(1, 1),$	float2(-1, 0), float2(0, 0), float2(1, 0),$	float2(-1, -1), float2(0, -1), float2(1, -1)$}@$$static float sobelXMatrix[9] = {$	1, 0, -1,$	2, 0, -2,$	1, 0, -1$}@$$static float sobelYMatrix[9] = {$	1, 2, 1,$	0, 0, 0,$	-1, -2, -1$}@$$float2 sobel = 0@$for (int i = 0@ i < 9@ i++) {$	float depth = tex2Dlod(Depth, float4(UV + sobelSamplePoints[i] * Thickness, 0.0, 0.0)).r@$	sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i])@$}$return length(sobel)@;1;Create;3;True;Depth;SAMPLER2D;0,0,0;In;;Inherit;False;True;UV;FLOAT2;0,0;In;;Inherit;False;True;Thickness;FLOAT;0;In;;Inherit;False;Sobel;True;False;0;;False;3;0;SAMPLER2D;0,0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT;0
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
WireConnection;528;0;515;0
WireConnection;528;1;525;0
WireConnection;527;0;529;0
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
WireConnection;627;0;557;0
WireConnection;629;0;630;0
WireConnection;629;1;627;1
WireConnection;506;0;505;0
WireConnection;506;1;566;0
WireConnection;636;0;633;0
WireConnection;636;1;634;0
WireConnection;631;0;633;0
WireConnection;631;1;636;0
WireConnection;70;0;555;0
WireConnection;70;1;94;0
WireConnection;94;1;77;0
WireConnection;77;0;66;0
WireConnection;77;1;95;0
WireConnection;432;0;70;0
WireConnection;138;0;554;0
WireConnection;7;0;139;0
WireConnection;7;1;138;0
WireConnection;308;2;732;5
WireConnection;307;0;732;5
WireConnection;456;0;308;0
WireConnection;456;1;306;0
WireConnection;559;0;84;0
WireConnection;84;0;732;6
WireConnection;502;0;84;4
WireConnection;556;0;559;0
WireConnection;306;0;308;0
WireConnection;306;1;307;3
WireConnection;306;2;307;4
WireConnection;462;4;432;0
WireConnection;462;6;424;0
WireConnection;616;0;645;0
WireConnection;635;0;631;0
WireConnection;474;0;655;0
WireConnection;649;0;659;0
WireConnection;655;0;649;3
WireConnection;655;1;635;0
WireConnection;652;0;628;0
WireConnection;652;3;658;0
WireConnection;656;0;647;0
WireConnection;630;0;625;0
WireConnection;659;0;656;0
WireConnection;659;1;644;0
WireConnection;644;0;672;0
WireConnection;644;1;652;0
WireConnection;628;0;629;0
WireConnection;628;1;627;2
WireConnection;628;2;627;3
WireConnection;658;0;630;0
WireConnection;670;0;643;0
WireConnection;670;1;671;0
WireConnection;672;0;670;0
WireConnection;672;2;673;0
WireConnection;671;0;669;0
WireConnection;671;1;643;0
WireConnection;676;1;7;0
WireConnection;676;0;7;0
WireConnection;676;3;7;0
WireConnection;676;4;7;0
WireConnection;0;2;675;0
WireConnection;0;9;474;0
WireConnection;0;11;569;0
WireConnection;453;0;659;0
WireConnection;675;1;453;0
WireConnection;675;0;101;30
WireConnection;675;2;453;0
WireConnection;675;3;677;0
WireConnection;675;4;683;0
WireConnection;693;0;687;2
WireConnection;693;2;696;0
WireConnection;693;3;695;0
WireConnection;699;0;687;3
WireConnection;699;2;697;0
WireConnection;699;3;698;0
WireConnection;691;0;687;1
WireConnection;691;2;692;0
WireConnection;691;3;694;0
WireConnection;682;0;707;0
WireConnection;707;0;687;1
WireConnection;707;3;708;0
WireConnection;707;4;691;0
WireConnection;708;0;687;2
WireConnection;708;3;709;0
WireConnection;708;4;693;0
WireConnection;709;0;687;3
WireConnection;709;4;699;0
WireConnection;503;0;725;0
WireConnection;501;0;504;0
WireConnection;501;1;566;0
WireConnection;501;2;504;0
WireConnection;501;3;506;0
WireConnection;632;0;501;0
WireConnection;725;0;2;1
WireConnection;725;1;726;0
WireConnection;725;2;2;1
WireConnection;536;0;568;0
WireConnection;568;0;731;31
WireConnection;538;0;731;32
WireConnection;548;0;567;0
WireConnection;567;0;731;13
WireConnection;2;0;732;5
WireConnection;2;1;456;0
WireConnection;424;0;676;0
WireConnection;424;1;420;0
WireConnection;552;0;462;0
WireConnection;66;0;732;5
WireConnection;66;1;456;0
WireConnection;66;2;67;0
ASEEND*/
//CHKSM=BEC2B19B282CE2492BD38687576B3B013906FDD1