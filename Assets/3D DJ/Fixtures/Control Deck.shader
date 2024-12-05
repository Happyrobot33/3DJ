// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Control Deck"
{
	Properties
	{
		_VideoTexture("Video Texture", 2D) = "white" {}
		_StaticWebpage("Static Webpage", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _VideoTexture;
		uniform sampler2D _StaticWebpage;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Albedo = (( i.uv_texcoord.y >= 0.58 && i.uv_texcoord.y <= 0.78 ) ? tex2D( _VideoTexture, ((float2( 0,0 ) + (i.uv_texcoord - float2( 0,0 )) * (float2( 2.5,4 ) - float2( 0,0 )) / (float2( 1,1 ) - float2( 0,0 )))*1.0 + float2( 0,-2.2 )) ) :  tex2D( _StaticWebpage, (float2( 0,0 ) + (i.uv_texcoord - float2( 0,0 )) * (float2( 2.5,1.25 ) - float2( 0,0 )) / (float2( 1,1 ) - float2( 0,0 ))) ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1;-1232,48;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;11;-368,192;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;576,-16;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Control Deck;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SamplerNode;13;-448,368;Inherit;True;Property;_TextureSample1;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;7;-816,64;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;2.5,4;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;15;-1056,592;Inherit;True;Property;_StaticWebpage;Static Webpage;1;0;Create;True;0;0;0;False;0;False;a0b2ab247e7198a439682ab027f8e4d2;8bef6179fcd26aa4c89b766c6b95490a;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TFHCRemapNode;14;-816,368;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;2.5,1.25;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;3;-304,-176;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;16;-576,-64;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;12;160,80;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.58;False;2;FLOAT;0.78;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;6;-1088,-416;Inherit;True;Property;_VideoTexture;Video Texture;0;0;Create;True;0;0;0;False;0;False;20ea8c25d5668274cb0e6cadbf680aad;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector2Node;18;-768,-80;Inherit;False;Constant;_Vector0;Vector 0;3;0;Create;True;0;0;0;False;0;False;0,-2.2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
WireConnection;11;0;1;0
WireConnection;0;0;12;0
WireConnection;13;0;15;0
WireConnection;13;1;14;0
WireConnection;7;0;1;0
WireConnection;14;0;1;0
WireConnection;3;0;6;0
WireConnection;3;1;16;0
WireConnection;16;0;7;0
WireConnection;16;2;18;0
WireConnection;12;0;11;1
WireConnection;12;3;3;0
WireConnection;12;4;13;0
ASEEND*/
//CHKSM=1108109B35E305F4386ADBBFBDDBD5BCE83E8B52