// Upgrade NOTE: upgraded instancing buffer 'DebugHeightmap' to new syntax.

// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DebugHeightmap"
{
	Properties
	{
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 32
		_TessMin( "Tess Min Distance", Float ) = 10
		_TessMax( "Tess Max Distance", Float ) = 25
		[NoScaleOffset]_Depth("Depth", 2D) = "white" {}
		[NoScaleOffset]_Color("Color", 2D) = "white" {}
		_BlockSelect("Block Select", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "Tessellation.cginc"
		#pragma target 4.6
		#pragma multi_compile_instancing
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows vertex:vertexDataFunc tessellate:tessFunction 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Depth;
		uniform sampler2D _Color;
		uniform float _TessValue;
		uniform float _TessMin;
		uniform float _TessMax;

		UNITY_INSTANCING_BUFFER_START(DebugHeightmap)
			UNITY_DEFINE_INSTANCED_PROP(float2, _BlockSelect)
#define _BlockSelect_arr DebugHeightmap
		UNITY_INSTANCING_BUFFER_END(DebugHeightmap)

		float4 tessFunction( appdata_full v0, appdata_full v1, appdata_full v2 )
		{
			return UnityDistanceBasedTess( v0.vertex, v1.vertex, v2.vertex, _TessMin, _TessMax, _TessValue );
		}

		void vertexDataFunc( inout appdata_full v )
		{
			float2 temp_output_4_0 = ( float2( 1,1 ) / float2( 3,2 ) );
			float2 _BlockSelect_Instance = UNITY_ACCESS_INSTANCED_PROP(_BlockSelect_arr, _BlockSelect);
			float2 uv_TexCoord2 = v.texcoord.xy * temp_output_4_0 + ( temp_output_4_0 * _BlockSelect_Instance );
			float3 ase_vertexNormal = v.normal.xyz;
			v.vertex.xyz += ( (0.0 + (tex2Dlod( _Depth, float4( uv_TexCoord2, 0, 0.0) ).r - 0.0) * (0.1 - 0.0) / (1.0 - 0.0)) * ase_vertexNormal );
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 temp_output_4_0 = ( float2( 1,1 ) / float2( 3,2 ) );
			float2 _BlockSelect_Instance = UNITY_ACCESS_INSTANCED_PROP(_BlockSelect_arr, _BlockSelect);
			float2 uv_TexCoord2 = i.uv_texcoord * temp_output_4_0 + ( temp_output_4_0 * _BlockSelect_Instance );
			float4 tex2DNode1 = tex2D( _Color, uv_TexCoord2 );
			o.Albedo = tex2DNode1.rgb;
			o.Emission = tex2DNode1.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.SimpleDivideOpNode;4;-192,-48;Inherit;False;2;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;5;-544,-32;Inherit;False;Constant;_BlockCount;Block Count;1;0;Create;True;0;0;0;False;0;False;3,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;-48,128;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;7;-432,192;Inherit;False;InstancedProperty;_BlockSelect;Block Select;7;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;208,-48;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.3333333,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;8;144,-640;Inherit;True;Property;_Color;Color;6;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;40d4c212118c5b545bb60be32058e0d1;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;3;144,208;Inherit;True;Property;_Depth;Depth;5;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;2fc056076e63f5f49849b667613db859;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;1;784,-272;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;624,144;Inherit;True;Property;_TextureSample1;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalVertexDataNode;12;800,-64;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1984,-224;Float;False;True;-1;6;ASEMaterialInspector;0;0;Standard;DebugHeightmap;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;0;32;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;0;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;1408,0;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;19;1056,128;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.1;False;1;FLOAT;0
WireConnection;4;1;5;0
WireConnection;6;0;4;0
WireConnection;6;1;7;0
WireConnection;2;0;4;0
WireConnection;2;1;6;0
WireConnection;1;0;8;0
WireConnection;1;1;2;0
WireConnection;9;0;3;0
WireConnection;9;1;2;0
WireConnection;0;0;1;0
WireConnection;0;2;1;0
WireConnection;0;11;11;0
WireConnection;11;0;19;0
WireConnection;11;1;12;0
WireConnection;19;0;9;1
ASEEND*/
//CHKSM=47086DA36CCF85A2C1D845ECFA02D3642D9D7A79