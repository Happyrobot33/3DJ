// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "HoloEmitterFixture"
{
	Properties
	{
		_BeamLength("Beam Length", Float) = 2
		_MaxTransmitterDistance("Max Transmitter Distance", Float) = 5
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
		#pragma target 3.0

		struct appdata_full_custom
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			float4 texcoord3 : TEXCOORD3;
			float4 color : COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
			uint ase_vertexId : SV_VertexID;
		};
		struct Input
		{
			float2 uv_texcoord;
			float4 vertexColor : COLOR;
			float4 screenPosition;
		};

		uniform sampler2D _Udon_3DJ_Data;
		float4 _Udon_3DJ_Data_TexelSize;
		uniform float _BeamLength;
		uniform sampler2D _Udon_3DJ_Color;
		uniform float4 _Udon_3DJ_Color_ST;
		uniform sampler2D _Udon_3DJ_Depth;
		uniform float4 _Udon_3DJ_Depth_ST;
		uniform float _MaxTransmitterDistance;


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


		void vertexDataFunc( inout appdata_full_custom v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 _Vector0 = float3(0,0,1);
			sampler2D Texture1_g452 = _Udon_3DJ_Data;
			float4 TexelSize1_g452 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult7_g451 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( ( _Udon_3DJ_Data_TexelSize.w / 3.0 ) * 2.0 )));
			float2 StripStart1_g452 = appendResult7_g451;
			int StripWidth1_g452 = 20;
			int PixelSize1_g452 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g452 = BinaryStripToInt( Texture1_g452 , TexelSize1_g452 , StripStart1_g452 , StripWidth1_g452 , PixelSize1_g452 );
			float3 temp_cast_1 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position166 = ( ( localBinaryStripToInt1_g452 - temp_cast_1 ) / float3( 100,100,100 ) );
			float3 worldToObj92 = mul( unity_WorldToObject, float4( DJ_Position166, 1 ) ).xyz;
			float3 temp_output_1_0_g379 = worldToObj92;
			float3 temp_output_2_0_g379 = _Vector0;
			float dotResult3_g379 = dot( temp_output_1_0_g379 , temp_output_2_0_g379 );
			float temp_output_89_0 = acos( ( dotResult3_g379 / ( length( temp_output_1_0_g379 ) * length( temp_output_2_0_g379 ) ) ) );
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 rotatedValue77 = RotateAroundAxis( float3( 0,0,0 ), ase_vertex3Pos, normalize( cross( _Vector0 , worldToObj92 ) ), temp_output_89_0 );
			float temp_output_112_0 = ( v.ase_vertexId * 0.001 );
			float mulTime109 = _Time.y * temp_output_112_0;
			float temp_output_122_0 = ( temp_output_112_0 * 0.0 );
			float mulTime118 = _Time.y * temp_output_122_0;
			float mulTime120 = _Time.y * ( temp_output_122_0 * 5.0 );
			float3 appendResult105 = (float3(sin( mulTime109 ) , sin( mulTime118 ) , sin( mulTime120 )));
			float3 rotatedValue136 = RotateAroundAxis( float3( 0,0,0 ), ( appendResult105 * ( (0) * 0.5 ) ), float3( 0,1,0 ), 45.0 );
			float3 worldToObj68 = mul( unity_WorldToObject, float4( ( DJ_Position166 + rotatedValue136 ), 1 ) ).xyz;
			float3 normalizeResult45 = normalize( worldToObj68 );
			v.vertex.xyz = ( v.color.r == 1.0 ? rotatedValue77 : ( v.color.g == 1.0 ? ( _BeamLength < length( worldToObj68 ) ? ( normalizeResult45 * _BeamLength ) : worldToObj68 ) : ase_vertex3Pos ) );
			v.vertex.w = 1;
			float4 ase_screenPos = ComputeScreenPos( UnityObjectToClipPos( v.vertex ) );
			o.screenPosition = ase_screenPos;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 color71 = IsGammaSpace() ? float4(0,0,0,1) : float4(0,0,0,1);
			float4 color126 = IsGammaSpace() ? float4(1,1,1,1) : float4(1,1,1,1);
			float2 uv_Udon_3DJ_Color = i.uv_texcoord * _Udon_3DJ_Color_ST.xy + _Udon_3DJ_Color_ST.zw;
			float2 uv_Udon_3DJ_Depth = i.uv_texcoord * _Udon_3DJ_Depth_ST.xy + _Udon_3DJ_Depth_ST.zw;
			float4 lerpResult145 = lerp( color126 , tex2D( _Udon_3DJ_Color, uv_Udon_3DJ_Color ) , tex2D( _Udon_3DJ_Depth, uv_Udon_3DJ_Depth ).r);
			float4 lerpResult70 = lerp( color71 , lerpResult145 , ( i.vertexColor.g > 0.0 ? 1.0 : 0.0 ));
			o.Albedo = lerpResult70.rgb;
			o.Emission = lerpResult70.rgb;
			float4 ase_screenPos = i.screenPosition;
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float2 clipScreen133 = ase_screenPosNorm.xy * _ScreenParams.xy;
			float dither133 = Dither8x8Bayer( fmod(clipScreen133.x, 8), fmod(clipScreen133.y, 8) );
			sampler2D Texture1_g452 = _Udon_3DJ_Data;
			float4 TexelSize1_g452 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult7_g451 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( ( _Udon_3DJ_Data_TexelSize.w / 3.0 ) * 2.0 )));
			float2 StripStart1_g452 = appendResult7_g451;
			int StripWidth1_g452 = 20;
			int PixelSize1_g452 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g452 = BinaryStripToInt( Texture1_g452 , TexelSize1_g452 , StripStart1_g452 , StripWidth1_g452 , PixelSize1_g452 );
			float3 temp_cast_3 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position166 = ( ( localBinaryStripToInt1_g452 - temp_cast_3 ) / float3( 100,100,100 ) );
			float3 objToWorld142 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float3 worldToObj92 = mul( unity_WorldToObject, float4( DJ_Position166, 1 ) ).xyz;
			float3 temp_output_1_0_g379 = worldToObj92;
			float3 _Vector0 = float3(0,0,1);
			float3 temp_output_2_0_g379 = _Vector0;
			float dotResult3_g379 = dot( temp_output_1_0_g379 , temp_output_2_0_g379 );
			float temp_output_89_0 = acos( ( dotResult3_g379 / ( length( temp_output_1_0_g379 ) * length( temp_output_2_0_g379 ) ) ) );
			float temp_output_131_0 = ( i.vertexColor.g == 0.0 ? 1.0 : 0.0 );
			dither133 = step( dither133, ( _MaxTransmitterDistance > distance( DJ_Position166 , objToWorld142 ) ? ( degrees( temp_output_89_0 ) < 50.0 ? (1.0 + (i.vertexColor.g - 0.0) * (0.0 - 1.0) / (1.0 - 0.0)) : temp_output_131_0 ) : temp_output_131_0 ) );
			o.Alpha = ( i.vertexColor.b == 0.0 ? dither133 : 0.0 );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows vertex:vertexDataFunc 

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
			#pragma target 3.0
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
				float2 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full_custom v )
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
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
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
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
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
Node;AmplifyShaderEditor.Compare;79;1312,960;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;53;-64,1664;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;89;-16,1520;Inherit;False;AngleBetweenVectors;-1;;379;764081594a5aa0b4d9781b5f2fcaa355;0;2;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;91;-400,1568;Inherit;False;Constant;_Vector0;Vector 0;5;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;92;-416,1312;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CrossProductOpNode;94;80,1344;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;45;0,608;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;68;-400,608;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;208,608;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-96,736;Inherit;False;Property;_BeamLength;Beam Length;10;0;Create;True;0;0;0;False;0;False;2;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;97;-64,832;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;99;368,720;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;28;1104,880;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;82;816,1056;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;100;1344,592;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;125;1632,848;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;71;464,352;Inherit;False;Constant;_Color1;Color 0;4;0;Create;True;0;0;0;False;0;False;0,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;102;-576,608;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;105;-1088,688;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;109;-1632,672;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;114;-1360,672;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;118;-1632,752;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;119;-1360,752;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;120;-1632,832;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;121;-1360,832;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;123;-1920,896;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-1920,784;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;48;784,864;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RotateAboutAxisNode;77;576,1600;Inherit;False;True;4;0;FLOAT3;1,0,0;False;1;FLOAT;96.34;False;2;FLOAT3;0,0,0;False;3;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;131;1872,1104;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-848,720;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-992,928;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;136;-672,832;Inherit;False;False;4;0;FLOAT3;0,1,0;False;1;FLOAT;45;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DegreesOpNode;132;1952,864;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;129;2160,880;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;50;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DitheringNode;133;2928,848;Inherit;False;1;False;4;0;FLOAT;0;False;1;SAMPLER2D;;False;2;FLOAT4;0,0,0,0;False;3;SAMPLERSTATE;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;138;2144,1360;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;142;1840,1472;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;141;2144,784;Inherit;False;Property;_MaxTransmitterDistance;Max Transmitter Distance;11;0;Create;True;0;0;0;False;0;False;5;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;3520,624;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;HoloEmitterFixture;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0.5;True;True;0;True;TransparentCutout;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Absolute;0;;0;-1;-1;-1;0;True;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.Compare;137;2560,896;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;50;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;130;1552,1088;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;144;2896,1008;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;143;3248,864;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;70;1552,528;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;145;992,16;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;126;592,-320;Inherit;False;Constant;_Color2;Color 0;4;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;73;448,-112;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;147;448,112;Inherit;True;Property;_TextureSample1;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;-1920,672;Inherit;False;2;2;0;INT;1;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;-2192,768;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexIdVariableNode;158;-2160,624;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.GetLocalVarNode;67;-832,592;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-1264,928;Inherit;False;-1;;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-736,1360;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;1856,1376;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;166;192,464;Inherit;False;DJ Position;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;193;192,304;Inherit;False;DJ Rotation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;194;192,384;Inherit;False;DJ Scale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;221;48,-96;Inherit;False;Global Textures;1;;449;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.FunctionNode;222;0,144;Inherit;False;Global Textures;1;;450;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.FunctionNode;223;-128,336;Inherit;False;Get DJ Data;5;;451;fd74dea831d77af4ea5f66eb0518196e;0;1;14;SAMPLER2D;;False;3;FLOAT;31;FLOAT;32;FLOAT3;13
WireConnection;79;0;48;1
WireConnection;79;2;77;0
WireConnection;79;3;28;0
WireConnection;89;1;92;0
WireConnection;89;2;91;0
WireConnection;92;0;88;0
WireConnection;94;0;91;0
WireConnection;94;1;92;0
WireConnection;45;0;68;0
WireConnection;68;0;102;0
WireConnection;46;0;45;0
WireConnection;46;1;47;0
WireConnection;97;0;68;0
WireConnection;99;0;47;0
WireConnection;99;1;97;0
WireConnection;99;2;46;0
WireConnection;99;3;68;0
WireConnection;28;0;48;2
WireConnection;28;2;99;0
WireConnection;28;3;82;0
WireConnection;100;0;48;2
WireConnection;125;0;48;2
WireConnection;102;0;67;0
WireConnection;102;1;136;0
WireConnection;105;0;114;0
WireConnection;105;1;119;0
WireConnection;105;2;121;0
WireConnection;109;0;112;0
WireConnection;114;0;109;0
WireConnection;118;0;122;0
WireConnection;119;0;118;0
WireConnection;120;0;123;0
WireConnection;121;0;120;0
WireConnection;123;0;122;0
WireConnection;122;0;112;0
WireConnection;77;0;94;0
WireConnection;77;1;89;0
WireConnection;77;3;53;0
WireConnection;131;0;130;2
WireConnection;127;0;105;0
WireConnection;127;1;135;0
WireConnection;135;0;134;0
WireConnection;136;3;127;0
WireConnection;132;0;89;0
WireConnection;129;0;132;0
WireConnection;129;2;125;0
WireConnection;129;3;131;0
WireConnection;133;0;137;0
WireConnection;138;0;140;0
WireConnection;138;1;142;0
WireConnection;0;0;70;0
WireConnection;0;2;70;0
WireConnection;0;9;143;0
WireConnection;0;11;79;0
WireConnection;137;0;141;0
WireConnection;137;1;138;0
WireConnection;137;2;129;0
WireConnection;137;3;131;0
WireConnection;143;0;144;3
WireConnection;143;2;133;0
WireConnection;70;0;71;0
WireConnection;70;1;145;0
WireConnection;70;2;100;0
WireConnection;145;0;126;0
WireConnection;145;1;73;0
WireConnection;145;2;147;1
WireConnection;73;0;221;6
WireConnection;147;0;222;5
WireConnection;112;0;158;0
WireConnection;112;1;113;0
WireConnection;166;0;223;13
WireConnection;193;0;223;31
WireConnection;194;0;223;32
ASEEND*/
//CHKSM=604EF4BDAA6F7CD34EEFCD1751F35016967AC507