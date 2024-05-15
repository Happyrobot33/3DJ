// Upgrade NOTE: upgraded instancing buffer 'DebugCameraView' to new syntax.

// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DebugCameraView"
{
	Properties
	{
		[NoScaleOffset]_ReferenceMap("Reference Map", 2D) = "white" {}
		_BlockSelect("Block Select", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma multi_compile_instancing
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _ReferenceMap;

		UNITY_INSTANCING_BUFFER_START(DebugCameraView)
			UNITY_DEFINE_INSTANCED_PROP(float2, _BlockSelect)
#define _BlockSelect_arr DebugCameraView
		UNITY_INSTANCING_BUFFER_END(DebugCameraView)

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 temp_output_10_0 = ( float2( 1,1 ) / float2( 3,2 ) );
			float2 _BlockSelect_Instance = UNITY_ACCESS_INSTANCED_PROP(_BlockSelect_arr, _BlockSelect);
			float2 uv_TexCoord8 = i.uv_texcoord * temp_output_10_0 + ( temp_output_10_0 * _BlockSelect_Instance );
			float4 tex2DNode2 = tex2D( _ReferenceMap, uv_TexCoord8 );
			o.Albedo = tex2DNode2.rgb;
			o.Emission = tex2DNode2.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.SamplerNode;2;-608,-128;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;208,-128;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;DebugCameraView;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;8;-1088,-32;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.3333333,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;1;-2128,-288;Inherit;True;Property;_ReferenceMap;Reference Map;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleDivideOpNode;10;-1491.797,-32.86288;Inherit;False;2;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;9;-1840,-16;Inherit;False;Constant;_BlockCount;Block Count;1;0;Create;True;0;0;0;False;0;False;3,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-1344,144;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;6;-1728,208;Inherit;False;InstancedProperty;_BlockSelect;Block Select;1;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
WireConnection;2;0;1;0
WireConnection;2;1;8;0
WireConnection;0;0;2;0
WireConnection;0;2;2;0
WireConnection;8;0;10;0
WireConnection;8;1;11;0
WireConnection;10;1;9;0
WireConnection;11;0;10;0
WireConnection;11;1;6;0
ASEEND*/
//CHKSM=F2D855C9F31D3A0009E678184EBA6C724628058C