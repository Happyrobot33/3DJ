// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "HoloEmitterFixture"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_FadeoutWidth("Fadeout Width", Float) = 5
		_Metallic("Metallic", 2D) = "white" {}
		[Toggle(_LIMITBEAMDISTANCE_ON)] _LimitBeamDistance("Limit Beam Distance", Float) = 0
		_BeamLength("Beam Length", Float) = 2
		_MaxTransmitterDistance("Max Transmitter Distance", Float) = 5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" "DisableBatching" = "True" "IsEmissive" = "true"  }
		Cull Off
		AlphaToMask On
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
		#pragma shader_feature_local _LIMITBEAMDISTANCE_ON

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
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform sampler2D _Metallic;
		uniform float4 _Metallic_ST;
		uniform float _MaxTransmitterDistance;
		uniform float _FadeoutWidth;


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


		float3 ASESafeNormalize(float3 inVec)
		{
			float dp3 = max(1.175494351e-38, dot(inVec, inVec));
			return inVec* rsqrt(dp3);
		}


		float MyCustomExpression15_g469( float x )
		{
			 if ((x < 0.0f || x > 0.0f || x == 0.0f))
			{
			return x;
			}
			return 0;
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
			float3 _ObjectSpaceForward = float3(0,0,1);
			sampler2D Texture1_g465 = _Udon_3DJ_Data;
			float4 TexelSize1_g465 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult7_g464 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( ( _Udon_3DJ_Data_TexelSize.w / 3.0 ) * 2.0 )));
			float2 StripStart1_g465 = appendResult7_g464;
			int StripWidth1_g465 = 20;
			int PixelSize1_g465 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g465 = BinaryStripToInt( Texture1_g465 , TexelSize1_g465 , StripStart1_g465 , StripWidth1_g465 , PixelSize1_g465 );
			float3 temp_cast_1 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position166 = ( ( localBinaryStripToInt1_g465 - temp_cast_1 ) / float3( 100,100,100 ) );
			float3 worldToObj92 = mul( unity_WorldToObject, float4( DJ_Position166, 1 ) ).xyz;
			float3 normalizeResult363 = ASESafeNormalize( cross( _ObjectSpaceForward , worldToObj92 ) );
			float3 temp_output_1_0_g469 = worldToObj92;
			float3 temp_output_2_0_g469 = _ObjectSpaceForward;
			float dotResult3_g469 = dot( temp_output_1_0_g469 , temp_output_2_0_g469 );
			float x15_g469 = acos( ( dotResult3_g469 / ( length( temp_output_1_0_g469 ) * length( temp_output_2_0_g469 ) ) ) );
			float localMyCustomExpression15_g469 = MyCustomExpression15_g469( x15_g469 );
			float temp_output_275_0 = localMyCustomExpression15_g469;
			float temp_output_285_0 = radians( 55.0 );
			float clampResult283 = clamp( temp_output_275_0 , -temp_output_285_0 , temp_output_285_0 );
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 rotatedValue77 = RotateAroundAxis( float3( 0,0,0 ), ase_vertex3Pos, normalizeResult363, clampResult283 );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 rotatedValue323 = RotateAroundAxis( float3( 0,0,0 ), ase_vertexNormal, normalizeResult363, clampResult283 );
			float3x3 Rotated_Fixture_Vertice_Positions235 = float3x3(rotatedValue77, rotatedValue323, float3( 0,0,0 ));
			float3 ase_parentObjectScale = (1.0/float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ));
			float temp_output_276_0 = ( _BeamLength / ase_parentObjectScale.x );
			float3 objToWorld248 = mul( unity_ObjectToWorld, float4( ase_vertex3Pos, 1 ) ).xyz;
			float mulTime109 = _Time.y * ( v.ase_vertexId * 0.001 );
			float decodeFloatRGBA307 = DecodeFloatRGBA( float4( ase_vertex3Pos , 0.0 ) );
			float temp_output_261_0 = ( decodeFloatRGBA307 * 10.0 );
			float mulTime118 = _Time.y * temp_output_261_0;
			float3 objToWorld316 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float decodeFloatRGBA317 = DecodeFloatRGBA( float4( objToWorld316 , 0.0 ) );
			float mulTime120 = _Time.y * ( temp_output_261_0 * decodeFloatRGBA317 );
			float3 appendResult105 = (float3(sin( ( objToWorld248.x + mulTime109 ) ) , cos( ( objToWorld248.y + mulTime118 ) ) , sin( ( objToWorld248.z + mulTime120 ) )));
			float3 Random_Position_In_Unit_Cube236 = appendResult105;
			sampler2D Texture1_g466 = _Udon_3DJ_Data;
			float4 TexelSize1_g466 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult25_g464 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( _Udon_3DJ_Data_TexelSize.w / 3.0 )));
			float2 StripStart1_g466 = appendResult25_g464;
			int StripWidth1_g466 = 20;
			int PixelSize1_g466 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g466 = BinaryStripToInt( Texture1_g466 , TexelSize1_g466 , StripStart1_g466 , StripWidth1_g466 , PixelSize1_g466 );
			float3 break17_g464 = ( localBinaryStripToInt1_g466 / float3( 100,100,1 ) );
			float DJ_Scale194 = break17_g464.y;
			float3 rotatedValue136 = RotateAroundAxis( float3( 0,0,0 ), ( Random_Position_In_Unit_Cube236 * ( DJ_Scale194 * 0.5 ) ), float3( 0,1,0 ), 45.0 );
			float3 worldToObj68 = mul( unity_WorldToObject, float4( ( DJ_Position166 + rotatedValue136 ), 1 ) ).xyz;
			float3 normalizeResult45 = normalize( worldToObj68 );
			#ifdef _LIMITBEAMDISTANCE_ON
				float3 staticSwitch230 = ( normalizeResult45 * temp_output_276_0 );
			#else
				float3 staticSwitch230 = worldToObj68;
			#endif
			float3 Beam_End_Point232 = ( temp_output_276_0 < length( worldToObj68 ) ? staticSwitch230 : worldToObj68 );
			float3x3 temp_output_79_0 = ( v.color.r == 1.0 ? Rotated_Fixture_Vertice_Positions235 : ( v.color.g == 1.0 ? float3x3(Beam_End_Point232, ase_vertexNormal, float3( 0,0,0 )) : float3x3(ase_vertex3Pos, ase_vertexNormal, float3( 0,0,0 )) ) );
			float3 temp_cast_5 = (sqrt( -1.0 )).xxx;
			v.vertex.xyz = ( v.color.b == 0.0 ? temp_output_79_0[0] : temp_cast_5 );
			v.vertex.w = 1;
			v.normal = temp_output_79_0[1];
			float4 ase_screenPos = ComputeScreenPos( UnityObjectToClipPos( v.vertex ) );
			o.screenPosition = ase_screenPos;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 hsvTorgb289 = RGBToHSV( tex2Dlod( _Udon_3DJ_Color, float4( i.uv_texcoord, 0, 8.0) ).rgb );
			float3 hsvTorgb290 = HSVToRGB( float3(hsvTorgb289.x,hsvTorgb289.y,(0.5 + (hsvTorgb289.z - 0.0) * (1.0 - 0.5) / (1.0 - 0.0))) );
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float temp_output_100_0 = ( i.vertexColor.g > 0.0 ? 0.0 : 1.0 );
			float4 lerpResult70 = lerp( float4( hsvTorgb290 , 0.0 ) , tex2D( _MainTex, uv_MainTex ) , temp_output_100_0);
			o.Albedo = lerpResult70.rgb;
			float3 lerpResult311 = lerp( hsvTorgb290 , float3( 0,0,0 ) , temp_output_100_0);
			o.Emission = lerpResult311;
			float2 uv_Metallic = i.uv_texcoord * _Metallic_ST.xy + _Metallic_ST.zw;
			float4 tex2DNode308 = tex2D( _Metallic, uv_Metallic );
			float lerpResult312 = lerp( 0.0 , tex2DNode308.r , temp_output_100_0);
			o.Metallic = lerpResult312;
			float lerpResult310 = lerp( 0.0 , tex2DNode308.a , temp_output_100_0);
			o.Smoothness = lerpResult310;
			float4 ase_screenPos = i.screenPosition;
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float2 clipScreen133 = ase_screenPosNorm.xy * _ScreenParams.xy;
			float dither133 = Dither8x8Bayer( fmod(clipScreen133.x, 8), fmod(clipScreen133.y, 8) );
			sampler2D Texture1_g465 = _Udon_3DJ_Data;
			float4 TexelSize1_g465 = _Udon_3DJ_Data_TexelSize;
			float2 appendResult7_g464 = (float2(( _Udon_3DJ_Data_TexelSize.z / ( 20 + 1 ) ) , ( ( _Udon_3DJ_Data_TexelSize.w / 3.0 ) * 2.0 )));
			float2 StripStart1_g465 = appendResult7_g464;
			int StripWidth1_g465 = 20;
			int PixelSize1_g465 = (int)( _Udon_3DJ_Data_TexelSize.z / 20 );
			float3 localBinaryStripToInt1_g465 = BinaryStripToInt( Texture1_g465 , TexelSize1_g465 , StripStart1_g465 , StripWidth1_g465 , PixelSize1_g465 );
			float3 temp_cast_4 = (pow( 2.0 , 19.0 )).xxx;
			float3 DJ_Position166 = ( ( localBinaryStripToInt1_g465 - temp_cast_4 ) / float3( 100,100,100 ) );
			float3 worldToObj92 = mul( unity_WorldToObject, float4( DJ_Position166, 1 ) ).xyz;
			float3 temp_output_1_0_g469 = worldToObj92;
			float3 _ObjectSpaceForward = float3(0,0,1);
			float3 temp_output_2_0_g469 = _ObjectSpaceForward;
			float dotResult3_g469 = dot( temp_output_1_0_g469 , temp_output_2_0_g469 );
			float x15_g469 = acos( ( dotResult3_g469 / ( length( temp_output_1_0_g469 ) * length( temp_output_2_0_g469 ) ) ) );
			float localMyCustomExpression15_g469 = MyCustomExpression15_g469( x15_g469 );
			float temp_output_275_0 = localMyCustomExpression15_g469;
			float temp_output_285_0 = radians( 55.0 );
			float In_Ball_Frustrum357 = ( temp_output_275_0 > temp_output_285_0 ? 0.0 : 1.0 );
			float3 objToWorld142 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float clampResult345 = clamp( (1.0 + (distance( DJ_Position166 , objToWorld142 ) - ( _MaxTransmitterDistance - _FadeoutWidth )) * (0.0 - 1.0) / (_MaxTransmitterDistance - ( _MaxTransmitterDistance - _FadeoutWidth ))) , 0.0 , 1.0 );
			dither133 = step( dither133, ( i.vertexColor.g > 0.0 ? ( In_Ball_Frustrum357 == 1.0 ? ( (1.0 + (i.vertexColor.g - 0.0) * (0.0 - 1.0) / (1.0 - 0.0)) * clampResult345 ) : 0.0 ) : 1.0 ) );
			o.Alpha = dither133;
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
Node;AmplifyShaderEditor.CommentaryNode;354;398,-866;Inherit;False;1988;1109;Texture Assignment;16;289;100;221;291;290;305;73;288;287;309;70;308;310;312;311;348;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;353;-1890,1054;Inherit;False;2517.7;847.7729;Ball Rotation;19;88;94;92;91;282;323;53;324;77;325;235;285;284;283;275;357;358;363;364;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;352;-4594,158;Inherit;False;2404;667;Find random position in the 3DJ Cube;21;118;120;114;240;242;105;246;250;251;109;257;263;113;252;261;262;248;316;317;307;236;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;351;-3298,-1090;Inherit;False;2996;923;Calculate the end position of the beam vertex;17;68;102;99;67;136;135;134;127;237;97;230;45;46;47;276;267;232;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;350;-994,126;Inherit;False;612;323;Comment;4;166;193;194;223;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;349;2062,430;Inherit;False;1156;867;Vertex Transformations Combining;10;234;233;326;331;322;28;79;321;82;48;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;347;1390,1390;Inherit;False;2706.464;846.5671;Beam Transparency and distance limiting;16;343;346;130;335;345;133;344;141;333;334;142;140;138;355;356;359;;1,1,1,1;0;0
Node;AmplifyShaderEditor.VectorFromMatrixNode;328;3659.429,939.6053;Inherit;False;Row;0;1;0;FLOAT3x3;1,0,0,0,1,1,1,0,1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VectorFromMatrixNode;329;3660.429,1086.605;Inherit;False;Row;1;1;0;FLOAT3x3;1,0,0,1,1,1,1,0,1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;4399,646;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;HoloEmitterFixture;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;False;True;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0;True;True;0;True;TransparentCutout;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Absolute;0;;15;-1;-1;-1;0;True;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.FunctionNode;330;3987.154,928.4512;Inherit;False;VertexClip;-1;;463;6b01c471edbbafc45b3ee035e6cf458a;0;3;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexColorNode;144;3598.817,738.4725;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DistanceOpNode;138;1776,1696;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;1488,1712;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;142;1472,1808;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;334;1744,1968;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;333;1472,2000;Inherit;False;Property;_FadeoutWidth;Fadeout Width;10;0;Create;True;0;0;0;False;0;False;5;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;141;1440,2096;Inherit;False;Property;_MaxTransmitterDistance;Max Transmitter Distance;14;0;Create;True;0;0;0;False;0;False;5;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;344;2704,1632;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;345;2496,1680;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;335;2160,1664;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;130;1984,1440;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;346;2304,1456;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;234;2288,1184;Inherit;False;235;Rotated Fixture Vertice Positions;1;0;OBJECT;;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.GetLocalVarNode;233;2112,688;Inherit;False;232;Beam End Point;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.MatrixFromVectors;326;2432,688;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;331;2112,784;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.MatrixFromVectors;322;2544,864;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.Compare;28;2768,704;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;3;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.Compare;79;3040,784;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;3;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;321;2304,1008;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;82;2304,848;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;48;2240,480;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;166;-624,336;Inherit;False;DJ Position;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;193;-624,176;Inherit;False;DJ Rotation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;194;-624,256;Inherit;False;DJ Scale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;223;-944,208;Inherit;False;Get DJ Data;4;;464;fd74dea831d77af4ea5f66eb0518196e;0;1;14;SAMPLER2D;;False;3;FLOAT;31;FLOAT;32;FLOAT3;13
Node;AmplifyShaderEditor.TransformPositionNode;68;-2016,-656;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;102;-2224,-640;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;99;-752,-688;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;67;-2640,-608;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;136;-2480,-368;Inherit;False;False;4;0;FLOAT3;0,1,0;False;1;FLOAT;45;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-2976,-304;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-3248,-304;Inherit;False;194;DJ Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-2720,-352;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;237;-3072,-400;Inherit;False;236;Random Position In Unit Cube;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LengthOpNode;97;-1120,-656;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;230;-1136,-1040;Inherit;False;Property;_LimitBeamDistance;Limit Beam Distance;12;0;Create;True;0;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;45;-1568,-1040;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-1360,-1040;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-1808,-976;Inherit;False;Property;_BeamLength;Beam Length;13;0;Create;True;0;0;0;False;0;False;2;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;276;-1536,-928;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;267;-1792,-896;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;232;-544,-672;Inherit;False;Beam End Point;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;118;-3664,560;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;120;-3664,640;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;114;-3168,480;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;240;-3168,560;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;242;-3168,640;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;105;-2800,528;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;246;-3360,480;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;250;-3360,576;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;251;-3360,672;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;109;-3664,480;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexIdVariableNode;257;-4368,208;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;263;-3936,400;Inherit;False;2;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;-4224,576;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;252;-4528,304;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;261;-3936,512;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;262;-3936,624;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;248;-3680,320;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;316;-4544,640;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DecodeFloatRGBAHlpNode;317;-4256,672;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DecodeFloatRGBAHlpNode;307;-4240,416;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;236;-2496,560;Inherit;False;Random Position In Unit Cube;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-1840,1152;Inherit;False;166;DJ Position;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;94;-1024,1136;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;92;-1520,1104;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;53;-1019,1565;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalVertexDataNode;324;-1023.058,1716.773;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.MatrixFromVectors;325;76.11084,1374.608;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;235;289.7,1377.9;Inherit;False;Rotated Fixture Vertice Positions;-1;True;1;0;FLOAT3x3;0,0,0,0,1,1,1,0,1;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.RadiansOpNode;285;-1002,1443;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;284;-816,1440;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;283;-648,1388;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;289;1232,-752;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Compare;100;2000,0;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;221;464,-816;Inherit;False;Global Textures;0;;468;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.TexCoordVertexDataNode;291;448,-672;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.HSVToRGBNode;290;1792,-720;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0.5;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TFHCRemapNode;305;1520,-624;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.5;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;73;832,-768;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;8;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;288;1456,-192;Inherit;True;Property;_TextureSample2;Texture Sample 2;9;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;287;1200,-192;Inherit;True;Property;_MainTex;MainTex;9;0;Create;True;0;0;0;False;0;False;None;e9eca9cbecbc3d64dbfe7689f0ec8f0d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;309;1168,-384;Inherit;True;Property;_Metallic;Metallic;11;0;Create;True;0;0;0;False;0;False;None;3029791699c97fa4eaf396272a8eccf5;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.LerpOp;70;2208,-64;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;308;1536,-384;Inherit;True;Property;_TextureSample3;Texture Sample 2;9;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;310;2208,-208;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;312;2208,-368;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;311;2208,80;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexColorNode;348;1552,16;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DitheringNode;133;3520,1552;Inherit;False;1;False;4;0;FLOAT;0;False;1;SAMPLER2D;;False;2;FLOAT4;0,0,0,0;False;3;SAMPLERSTATE;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;343;3248,1552;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StickyNoteNode;356;2928,1824;Inherit;False;252;152;New Note;;1,1,1,1;Discard the beams entirely if they are out of the frustrum of the ball;0;0
Node;AmplifyShaderEditor.RangedFloatNode;282;-1200,1440;Inherit;False;Constant;_MaxAngle;Max Angle;8;0;Create;True;0;0;0;False;0;False;55;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;358;-592,1120;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;357;-368,1152;Inherit;False;In Ball Frustrum;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;359;2672,1536;Inherit;False;357;In Ball Frustrum;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;355;2976,1600;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;77;-278,1298;Inherit;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;50;False;2;FLOAT3;0,0,0;False;3;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;323;-280.928,1452.079;Inherit;False;False;4;0;FLOAT3;1,0,0;False;1;FLOAT;50;False;2;FLOAT3;0,0,0;False;3;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;363;-640,1280;Inherit;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StickyNoteNode;364;-800,1168;Inherit;False;150;100;New Note;;1,1,1,1;This normalize is here to remove nans;0;0
Node;AmplifyShaderEditor.FunctionNode;275;-1060,1305;Inherit;False;AngleBetweenVectors;-1;;469;764081594a5aa0b4d9781b5f2fcaa355;0;2;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;91;-1504,1360;Inherit;False;Constant;_ObjectSpaceForward;Object Space Forward;5;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
WireConnection;328;0;79;0
WireConnection;329;0;79;0
WireConnection;0;0;70;0
WireConnection;0;2;311;0
WireConnection;0;3;312;0
WireConnection;0;4;310;0
WireConnection;0;9;133;0
WireConnection;0;11;330;0
WireConnection;0;12;329;0
WireConnection;330;4;144;3
WireConnection;330;6;328;0
WireConnection;138;0;140;0
WireConnection;138;1;142;0
WireConnection;334;0;141;0
WireConnection;334;1;333;0
WireConnection;344;0;346;0
WireConnection;344;1;345;0
WireConnection;345;0;335;0
WireConnection;335;0;138;0
WireConnection;335;1;334;0
WireConnection;335;2;141;0
WireConnection;346;0;130;2
WireConnection;326;0;233;0
WireConnection;326;1;331;0
WireConnection;322;0;82;0
WireConnection;322;1;321;0
WireConnection;28;0;48;2
WireConnection;28;2;326;0
WireConnection;28;3;322;0
WireConnection;79;0;48;1
WireConnection;79;2;234;0
WireConnection;79;3;28;0
WireConnection;166;0;223;13
WireConnection;193;0;223;31
WireConnection;194;0;223;32
WireConnection;68;0;102;0
WireConnection;102;0;67;0
WireConnection;102;1;136;0
WireConnection;99;0;276;0
WireConnection;99;1;97;0
WireConnection;99;2;230;0
WireConnection;99;3;68;0
WireConnection;136;3;127;0
WireConnection;135;0;134;0
WireConnection;127;0;237;0
WireConnection;127;1;135;0
WireConnection;97;0;68;0
WireConnection;230;1;68;0
WireConnection;230;0;46;0
WireConnection;45;0;68;0
WireConnection;46;0;45;0
WireConnection;46;1;276;0
WireConnection;276;0;47;0
WireConnection;276;1;267;1
WireConnection;232;0;99;0
WireConnection;118;0;261;0
WireConnection;120;0;262;0
WireConnection;114;0;246;0
WireConnection;240;0;250;0
WireConnection;242;0;251;0
WireConnection;105;0;114;0
WireConnection;105;1;240;0
WireConnection;105;2;242;0
WireConnection;246;0;248;1
WireConnection;246;1;109;0
WireConnection;250;0;248;2
WireConnection;250;1;118;0
WireConnection;251;0;248;3
WireConnection;251;1;120;0
WireConnection;109;0;263;0
WireConnection;263;0;257;0
WireConnection;263;1;113;0
WireConnection;261;0;307;0
WireConnection;262;0;261;0
WireConnection;262;1;317;0
WireConnection;248;0;252;0
WireConnection;317;0;316;0
WireConnection;307;0;252;0
WireConnection;236;0;105;0
WireConnection;94;0;91;0
WireConnection;94;1;92;0
WireConnection;92;0;88;0
WireConnection;325;0;77;0
WireConnection;325;1;323;0
WireConnection;235;0;325;0
WireConnection;285;0;282;0
WireConnection;284;0;285;0
WireConnection;283;0;275;0
WireConnection;283;1;284;0
WireConnection;283;2;285;0
WireConnection;289;0;73;0
WireConnection;100;0;348;2
WireConnection;290;0;289;1
WireConnection;290;1;289;2
WireConnection;290;2;305;0
WireConnection;305;0;289;3
WireConnection;73;0;221;6
WireConnection;73;1;291;0
WireConnection;288;0;287;0
WireConnection;70;0;290;0
WireConnection;70;1;288;0
WireConnection;70;2;100;0
WireConnection;308;0;309;0
WireConnection;310;1;308;4
WireConnection;310;2;100;0
WireConnection;312;1;308;1
WireConnection;312;2;100;0
WireConnection;311;0;290;0
WireConnection;311;2;100;0
WireConnection;133;0;343;0
WireConnection;343;0;130;2
WireConnection;343;2;355;0
WireConnection;358;0;275;0
WireConnection;358;1;285;0
WireConnection;357;0;358;0
WireConnection;355;0;359;0
WireConnection;355;2;344;0
WireConnection;77;0;363;0
WireConnection;77;1;283;0
WireConnection;77;3;53;0
WireConnection;323;0;363;0
WireConnection;323;1;283;0
WireConnection;323;3;324;0
WireConnection;363;0;94;0
WireConnection;275;1;92;0
WireConnection;275;2;91;0
ASEEND*/
//CHKSM=EF9A0A94F940129BFE9A58D6C9941A1EE9564560