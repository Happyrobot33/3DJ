// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Control Deck"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Metallic("Metallic", 2D) = "black" {}
		[Normal]_Normal("Normal", 2D) = "bump" {}
		_Emission("Emission", 2D) = "black" {}
		[HideInInspector] _texcoord3( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
			float2 uv3_texcoord3;
		};

		uniform sampler2D _Normal;
		uniform float4 _Normal_ST;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform sampler2D _Emission;
		uniform float4 _Emission_ST;
		uniform sampler2D _Udon_3DJ_Data;
		uniform sampler2D _Udon_3DJ_Raw_Output;
		uniform sampler2D _Udon_3DJ_Raw_Input;
		uniform sampler2D _Udon_3DJ_Depth;
		uniform sampler2D _Udon_3DJ_Color;
		uniform sampler2D _Udon_3DJ_Color_Upscaled;
		uniform sampler2D _Metallic;
		uniform float4 _Metallic_ST;


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

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			o.Normal = UnpackNormal( tex2D( _Normal, uv_Normal ) );
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			o.Albedo = tex2D( _MainTex, uv_MainTex ).rgb;
			float2 uv_Emission = i.uv_texcoord * _Emission_ST.xy + _Emission_ST.zw;
			float4 tex2DNode9 = tex2D( _Emission, uv_Emission );
			float2 temp_output_6_0_g70 = (i.uv3_texcoord3*3.0 + ( float2( 0,1 ) * float2( -1,-1 ) ));
			float2 break10_g70 = temp_output_6_0_g70;
			float2 temp_output_6_0_g63 = (i.uv3_texcoord3*3.0 + ( float2( 0,2 ) * float2( -1,-1 ) ));
			float2 break10_g63 = temp_output_6_0_g63;
			float2 temp_output_6_0_g64 = (i.uv3_texcoord3*3.0 + ( float2( 1,2 ) * float2( -1,-1 ) ));
			float2 break10_g64 = temp_output_6_0_g64;
			float2 temp_output_6_0_g68 = (i.uv3_texcoord3*3.0 + ( float2( 1,1 ) * float2( -1,-1 ) ));
			float2 break10_g68 = temp_output_6_0_g68;
			float2 temp_output_6_0_g69 = (i.uv3_texcoord3*3.0 + ( float2( 2,1 ) * float2( -1,-1 ) ));
			float2 break10_g69 = temp_output_6_0_g69;
			float2 temp_output_6_0_g65 = (i.uv3_texcoord3*3.0 + ( float2( 0,0 ) * float2( -1,-1 ) ));
			float2 break10_g65 = temp_output_6_0_g65;
			float2 temp_output_6_0_g66 = (i.uv3_texcoord3*3.0 + ( float2( 1,0 ) * float2( -1,-1 ) ));
			float2 break10_g66 = temp_output_6_0_g66;
			float2 temp_output_6_0_g67 = (i.uv3_texcoord3*3.0 + ( float2( 2,0 ) * float2( -1,-1 ) ));
			float2 break10_g67 = temp_output_6_0_g67;
			float2 temp_output_6_0_g71 = (i.uv3_texcoord3*3.0 + ( float2( 2,2 ) * float2( -1,-1 ) ));
			float2 break10_g71 = temp_output_6_0_g71;
			float3 hsvTorgb1_g75 = RGBToHSV( (( break10_g71.y >= 0.0 && break10_g71.y <= 1.0 ) ? (( break10_g71.x >= 0.0 && break10_g71.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Color_Upscaled, float4( temp_output_6_0_g71, 0, 8.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ).rgb );
			float3 hsvTorgb2_g75 = HSVToRGB( float3(hsvTorgb1_g75.x,hsvTorgb1_g75.y,(0.5 + (hsvTorgb1_g75.z - 0.0) * (1.0 - 0.5) / (1.0 - 0.0))) );
			o.Emission = ( i.uv3_texcoord3.x >= 0.0 ? ( tex2DNode9 + ( (( break10_g70.y >= 0.0 && break10_g70.y <= 1.0 ) ? (( break10_g70.x >= 0.0 && break10_g70.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Data, float4( temp_output_6_0_g70, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g63.y >= 0.0 && break10_g63.y <= 1.0 ) ? (( break10_g63.x >= 0.0 && break10_g63.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Raw_Output, float4( temp_output_6_0_g63, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g64.y >= 0.0 && break10_g64.y <= 1.0 ) ? (( break10_g64.x >= 0.0 && break10_g64.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Raw_Input, float4( temp_output_6_0_g64, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g68.y >= 0.0 && break10_g68.y <= 1.0 ) ? (( break10_g68.x >= 0.0 && break10_g68.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Depth, float4( temp_output_6_0_g68, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g69.y >= 0.0 && break10_g69.y <= 1.0 ) ? (( break10_g69.x >= 0.0 && break10_g69.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Color, float4( temp_output_6_0_g69, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + ( (( break10_g65.y >= 0.0 && break10_g65.y <= 1.0 ) ? (( break10_g65.x >= 0.0 && break10_g65.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Data, float4( temp_output_6_0_g65, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) * float4( 1,0,0,0 ) ) + ( (( break10_g66.y >= 0.0 && break10_g66.y <= 1.0 ) ? (( break10_g66.x >= 0.0 && break10_g66.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Data, float4( temp_output_6_0_g66, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) * float4( 0,1,0,0 ) ) + ( (( break10_g67.y >= 0.0 && break10_g67.y <= 1.0 ) ? (( break10_g67.x >= 0.0 && break10_g67.x <= 1.0 ) ? tex2Dlod( _Udon_3DJ_Data, float4( temp_output_6_0_g67, 0, 0.0) ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) * float4( 0,0,1,0 ) ) + float4( ( hsvTorgb2_g75 * (( break10_g71.y >= 0.0 && break10_g71.y <= 1.0 ) ? (( break10_g71.x >= 0.0 && break10_g71.x <= 1.0 ) ? 1.0 :  0.0 ) :  0.0 ) ) , 0.0 ) ) ) : tex2DNode9 ).rgb;
			float2 uv_Metallic = i.uv_texcoord * _Metallic_ST.xy + _Metallic_ST.zw;
			float4 tex2DNode5 = tex2D( _Metallic, uv_Metallic );
			o.Metallic = tex2DNode5.r;
			o.Smoothness = tex2DNode5.a;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.SamplerNode;4;-1024,-852;Inherit;True;Property;_MainTex;MainTex;7;0;Create;True;0;0;0;False;0;False;-1;None;e379f79bf757bda4eb4a2ca051a55f15;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-1024,-656;Inherit;True;Property;_Emission;Emission;10;0;Create;True;0;0;0;False;0;False;-1;None;d0e5e6af062a54343a40eaaff0bf61e7;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;5;-1024,-464;Inherit;True;Property;_Metallic;Metallic;8;0;Create;True;0;0;0;False;0;False;-1;None;d0e0f0dc61625dc43af16b69c2f37cb6;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-1024,-272;Inherit;True;Property;_Normal;Normal;9;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;526d49fc30cb23a459dca89710678c4f;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;832,-416;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Control Deck;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleAddOpNode;23;-16,144;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;22;224,-96;Inherit;False;3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;2;-2011.94,112.2328;Inherit;False;Global Textures;0;;11;5151b2ab862399e41a33b2b14a355044;0;0;6;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6;SAMPLER2D;11;SAMPLER2D;7;SAMPLER2D;9
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-2030,347.2;Inherit;False;2;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;86;-1290.815,59.41876;Inherit;False;Constant;_Vector0;Vector 0;5;0;Create;True;0;0;0;False;0;False;0,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;87;-1294.815,268.4188;Inherit;False;Constant;_Vector1;Vector 0;5;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;88;-1300.815,429.4188;Inherit;False;Constant;_Vector2;Vector 0;5;0;Create;True;0;0;0;False;0;False;1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;89;-1289.815,605.4188;Inherit;False;Constant;_Vector3;Vector 0;5;0;Create;True;0;0;0;False;0;False;2,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;90;-1280.815,816.4188;Inherit;False;Constant;_Vector4;Vector 0;5;0;Create;True;0;0;0;False;0;False;0,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;91;-1266.815,973.4188;Inherit;False;Constant;_Vector5;Vector 0;5;0;Create;True;0;0;0;False;0;False;1,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;92;-1245.815,1328.419;Inherit;False;Constant;_Vector6;Vector 0;5;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;93;-1277.815,1565.419;Inherit;False;Constant;_Vector7;Vector 0;5;0;Create;True;0;0;0;False;0;False;2,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;94;-1288.815,1749.419;Inherit;False;Constant;_Vector8;Vector 0;5;0;Create;True;0;0;0;False;0;False;2,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;95;-1893.166,876.3801;Inherit;False;Constant;_Size;Size;5;0;Create;True;0;0;0;False;0;False;3;0;3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-285,279;Inherit;False;9;9;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-690.7252,278.9362;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-692.7252,411.9362;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,1,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-700.7252,557.9362;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;110;-983.7672,789.949;Inherit;False;Map Texture To Area;-1;;63;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;111;-983.7671,974.5486;Inherit;False;Map Texture To Area;-1;;64;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;112;-991.6001,213.2;Inherit;False;Map Texture To Area;-1;;65;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;113;-1012.843,392.9209;Inherit;False;Map Texture To Area;-1;;66;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;114;-1007.843,563.9209;Inherit;False;Map Texture To Area;-1;;67;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;115;-993.1043,1329.07;Inherit;False;Map Texture To Area;-1;;68;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;116;-984.7507,1536.299;Inherit;False;Map Texture To Area;-1;;69;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;117;-990.6599,40.93863;Inherit;False;Map Texture To Area;-1;;70;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;118;-982.1895,1751.124;Inherit;False;Map Texture To Area;-1;;71;3d39dafb5f2f01f46b87415ff8f5ece3;0;5;1;SAMPLER2D;0;False;14;FLOAT;8;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;2;FLOAT;18;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;-434.9656,1765.716;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;123;-679.4854,1800.666;Inherit;False;Brightness Equalize;-1;;75;3cff8996ac8f314489f1f0f7859c2aa6;0;1;4;FLOAT3;0,0,0;False;1;FLOAT3;0
WireConnection;0;0;4;0
WireConnection;0;1;6;0
WireConnection;0;2;22;0
WireConnection;0;3;5;1
WireConnection;0;4;5;4
WireConnection;23;0;9;0
WireConnection;23;1;11;0
WireConnection;22;0;1;1
WireConnection;22;2;23;0
WireConnection;22;3;9;0
WireConnection;11;0;117;0
WireConnection;11;1;110;0
WireConnection;11;2;111;0
WireConnection;11;3;115;0
WireConnection;11;4;116;0
WireConnection;11;5;105;0
WireConnection;11;6;106;0
WireConnection;11;7;107;0
WireConnection;11;8;119;0
WireConnection;105;0;112;0
WireConnection;106;0;113;0
WireConnection;107;0;114;0
WireConnection;110;1;2;9
WireConnection;110;3;1;0
WireConnection;110;4;90;0
WireConnection;110;5;95;0
WireConnection;111;1;2;7
WireConnection;111;3;1;0
WireConnection;111;4;91;0
WireConnection;111;5;95;0
WireConnection;112;1;2;0
WireConnection;112;3;1;0
WireConnection;112;4;87;0
WireConnection;112;5;95;0
WireConnection;113;1;2;0
WireConnection;113;3;1;0
WireConnection;113;4;88;0
WireConnection;113;5;95;0
WireConnection;114;1;2;0
WireConnection;114;3;1;0
WireConnection;114;4;89;0
WireConnection;114;5;95;0
WireConnection;115;1;2;5
WireConnection;115;3;1;0
WireConnection;115;4;92;0
WireConnection;115;5;95;0
WireConnection;116;1;2;6
WireConnection;116;3;1;0
WireConnection;116;4;93;0
WireConnection;116;5;95;0
WireConnection;117;1;2;0
WireConnection;117;3;1;0
WireConnection;117;4;86;0
WireConnection;117;5;95;0
WireConnection;118;1;2;11
WireConnection;118;3;1;0
WireConnection;118;4;94;0
WireConnection;118;5;95;0
WireConnection;119;0;123;0
WireConnection;119;1;118;18
WireConnection;123;4;118;0
ASEEND*/
//CHKSM=14D6AE499A3D597AA5DE3911AE6E8C08AED78F94