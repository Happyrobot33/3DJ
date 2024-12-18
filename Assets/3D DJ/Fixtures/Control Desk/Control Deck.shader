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
		_DataInfo("Data Info", Vector) = (0,0,1,0)
		_RecordOutput("Record Output", 2D) = "white" {}
		_PlaybackInput("Playback Input", 2D) = "white" {}
		_DepthInfo("Depth Info", Vector) = (0,0,1,0)
		_ColorInfo("Color Info", Vector) = (0,0,1,0)
		_RecordInfo("Record Info", Vector) = (0,0,1,0)
		_RecordInfo1("Record Info", Vector) = (0,0,1,0)
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
		uniform float3 _DataInfo;
		uniform sampler2D _Udon_3DJ_Data;
		uniform float3 _DepthInfo;
		uniform sampler2D _Udon_3DJ_Depth;
		uniform float3 _ColorInfo;
		uniform sampler2D _Udon_3DJ_Color;
		uniform float3 _RecordInfo;
		uniform sampler2D _RecordOutput;
		uniform float3 _RecordInfo1;
		uniform sampler2D _PlaybackInput;
		uniform sampler2D _Metallic;
		uniform float4 _Metallic_ST;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			o.Normal = UnpackNormal( tex2D( _Normal, uv_Normal ) );
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			o.Albedo = tex2D( _MainTex, uv_MainTex ).rgb;
			float2 uv_Emission = i.uv_texcoord * _Emission_ST.xy + _Emission_ST.zw;
			float4 tex2DNode9 = tex2D( _Emission, uv_Emission );
			float2 temp_output_6_0_g4 = (i.uv3_texcoord3*_DataInfo.z + _DataInfo.xy);
			float2 break10_g4 = temp_output_6_0_g4;
			float2 temp_output_6_0_g5 = (i.uv3_texcoord3*_DepthInfo.z + _DepthInfo.xy);
			float2 break10_g5 = temp_output_6_0_g5;
			float2 temp_output_6_0_g7 = (i.uv3_texcoord3*_ColorInfo.z + _ColorInfo.xy);
			float2 break10_g7 = temp_output_6_0_g7;
			float2 temp_output_6_0_g8 = (i.uv3_texcoord3*_RecordInfo.z + _RecordInfo.xy);
			float2 break10_g8 = temp_output_6_0_g8;
			float2 temp_output_6_0_g9 = (i.uv3_texcoord3*_RecordInfo1.z + _RecordInfo1.xy);
			float2 break10_g9 = temp_output_6_0_g9;
			o.Emission = ( i.uv3_texcoord3.x >= 0.0 ? ( tex2DNode9 + ( (( break10_g4.y >= 0.0 && break10_g4.y <= 1.0 ) ? (( break10_g4.x >= 0.0 && break10_g4.x <= 1.0 ) ? tex2D( _Udon_3DJ_Data, temp_output_6_0_g4 ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g5.y >= 0.0 && break10_g5.y <= 1.0 ) ? (( break10_g5.x >= 0.0 && break10_g5.x <= 1.0 ) ? tex2D( _Udon_3DJ_Depth, temp_output_6_0_g5 ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g7.y >= 0.0 && break10_g7.y <= 1.0 ) ? (( break10_g7.x >= 0.0 && break10_g7.x <= 1.0 ) ? tex2D( _Udon_3DJ_Color, temp_output_6_0_g7 ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g8.y >= 0.0 && break10_g8.y <= 1.0 ) ? (( break10_g8.x >= 0.0 && break10_g8.x <= 1.0 ) ? tex2D( _RecordOutput, temp_output_6_0_g8 ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) + (( break10_g9.y >= 0.0 && break10_g9.y <= 1.0 ) ? (( break10_g9.x >= 0.0 && break10_g9.x <= 1.0 ) ? tex2D( _PlaybackInput, temp_output_6_0_g9 ) :  float4( 0,0,0,0 ) ) :  float4( 0,0,0,0 ) ) ) ) : tex2DNode9 ).rgb;
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
Node;AmplifyShaderEditor.SamplerNode;4;-1024,-852;Inherit;True;Property;_MainTex;MainTex;4;0;Create;True;0;0;0;False;0;False;-1;None;e379f79bf757bda4eb4a2ca051a55f15;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-1024,-656;Inherit;True;Property;_Emission;Emission;7;0;Create;True;0;0;0;False;0;False;-1;None;d0e5e6af062a54343a40eaaff0bf61e7;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;5;-1024,-464;Inherit;True;Property;_Metallic;Metallic;5;0;Create;True;0;0;0;False;0;False;-1;None;d0e0f0dc61625dc43af16b69c2f37cb6;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-1024,-272;Inherit;True;Property;_Normal;Normal;6;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;526d49fc30cb23a459dca89710678c4f;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;832,-416;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Control Deck;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleAddOpNode;23;-16,144;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;22;224,-96;Inherit;False;3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-384,272;Inherit;False;5;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;28;-992,272;Inherit;False;Map Texture To Area;-1;;5;3d39dafb5f2f01f46b87415ff8f5ece3;0;4;1;SAMPLER2D;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;33;-1312,128;Inherit;False;Property;_DataInfo;Data Info;8;0;Create;True;0;0;0;False;0;False;0,0,1;-1.81,-2.51,4;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;34;-1312,272;Inherit;False;Property;_DepthInfo;Depth Info;11;0;Create;True;0;0;0;False;0;False;0,0,1;-1.81,-1.31,4;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;2;-1696,-96;Inherit;False;Global Textures;0;;6;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.FunctionNode;29;-992,416;Inherit;False;Map Texture To Area;-1;;7;3d39dafb5f2f01f46b87415ff8f5ece3;0;4;1;SAMPLER2D;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;35;-1312,416;Inherit;False;Property;_ColorInfo;Color Info;12;0;Create;True;0;0;0;False;0;False;0,0,1;-1.81,-0.22,4;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;39;-1744,784;Inherit;True;Property;_PlaybackInput;Playback Input;10;0;Create;True;0;0;0;False;0;False;None;c85db324de6a20b498f02da4037d95fe;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;37;-992,608;Inherit;False;Map Texture To Area;-1;;8;3d39dafb5f2f01f46b87415ff8f5ece3;0;4;1;SAMPLER2D;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;38;-1312,608;Inherit;False;Property;_RecordInfo;Record Info;13;0;Create;True;0;0;0;False;0;False;0,0,1;-2.91,-0.22,4;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;40;-992,816;Inherit;False;Map Texture To Area;-1;;9;3d39dafb5f2f01f46b87415ff8f5ece3;0;4;1;SAMPLER2D;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;41;-1312,816;Inherit;False;Property;_RecordInfo1;Record Info;14;0;Create;True;0;0;0;False;0;False;0,0,1;-0.25,-2.63,4;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;36;-1744,592;Inherit;True;Property;_RecordOutput;Record Output;9;0;Create;True;0;0;0;False;0;False;None;86309c450e338be458544111d4f51804;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;27;-992,128;Inherit;False;Map Texture To Area;-1;;4;3d39dafb5f2f01f46b87415ff8f5ece3;0;4;1;SAMPLER2D;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-1728,320;Inherit;False;2;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
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
WireConnection;11;0;27;0
WireConnection;11;1;28;0
WireConnection;11;2;29;0
WireConnection;11;3;37;0
WireConnection;11;4;40;0
WireConnection;28;1;2;5
WireConnection;28;3;1;0
WireConnection;28;4;34;0
WireConnection;28;5;34;3
WireConnection;29;1;2;6
WireConnection;29;3;1;0
WireConnection;29;4;35;0
WireConnection;29;5;35;3
WireConnection;37;1;36;0
WireConnection;37;3;1;0
WireConnection;37;4;38;0
WireConnection;37;5;38;3
WireConnection;40;1;39;0
WireConnection;40;3;1;0
WireConnection;40;4;41;0
WireConnection;40;5;41;3
WireConnection;27;1;2;0
WireConnection;27;3;1;0
WireConnection;27;4;33;0
WireConnection;27;5;33;3
ASEEND*/
//CHKSM=3CBC7C67A48EB4494A8C013C294228CB113ECDB6