// Upgrade NOTE: upgraded instancing buffer 'CameraShader' to new syntax.

// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Camera Shader"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Metallic("Metallic", 2D) = "black" {}
		[Normal]_Normal("Normal", 2D) = "bump" {}
		_Emission("Emission", 2D) = "black" {}
		_BlockSelect("Block Select", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord3( "", 2D ) = "white" {}
		[HideInInspector] _texcoord4( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 4.6
		#pragma multi_compile_instancing
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 

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
			float4 ase_texcoord4 : TEXCOORD4;
		};
		struct Input
		{
			float2 uv_texcoord;
			float2 uv3_texcoord3;
			float2 ase_texcoord5;
			float2 uv4_texcoord4;
		};

		uniform sampler2D _Udon_3DJ_Depth;
		uniform sampler2D _Normal;
		uniform sampler2D _MainTex;
		uniform sampler2D _Emission;
		uniform sampler2D _Udon_3DJ_Color;
		uniform sampler2D _Metallic;

		UNITY_INSTANCING_BUFFER_START(CameraShader)
			UNITY_DEFINE_INSTANCED_PROP(float4, _Normal_ST)
#define _Normal_ST_arr CameraShader
			UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
#define _MainTex_ST_arr CameraShader
			UNITY_DEFINE_INSTANCED_PROP(float4, _Emission_ST)
#define _Emission_ST_arr CameraShader
			UNITY_DEFINE_INSTANCED_PROP(float4, _Metallic_ST)
#define _Metallic_ST_arr CameraShader
			UNITY_DEFINE_INSTANCED_PROP(float2, _BlockSelect)
#define _BlockSelect_arr CameraShader
		UNITY_INSTANCING_BUFFER_END(CameraShader)

		void vertexDataFunc( inout appdata_full_custom v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float2 temp_output_30_0 = ( float2( 1,1 ) / float2( 3,2 ) );
			float2 _BlockSelect_Instance = UNITY_ACCESS_INSTANCED_PROP(_BlockSelect_arr, _BlockSelect);
			float2 temp_output_32_0 = ( temp_output_30_0 * _BlockSelect_Instance );
			float2 temp_output_56_0 = (v.ase_texcoord4.xy*temp_output_30_0 + temp_output_32_0);
			float3 ase_vertexNormal = v.normal.xyz;
			v.vertex.xyz += ( v.ase_texcoord4.xy.x > 0.0 ? ( (0.0 + (tex2Dlod( _Udon_3DJ_Depth, float4( temp_output_56_0, 0, 0.0) ).r - 0.0) * (0.1 - 0.0) / (1.0 - 0.0)) * ase_vertexNormal ) : float3( 0,0,0 ) );
			v.vertex.w = 1;
			o.ase_texcoord5 = v.ase_texcoord4;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 _Normal_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_Normal_ST_arr, _Normal_ST);
			float2 uv_Normal = i.uv_texcoord * _Normal_ST_Instance.xy + _Normal_ST_Instance.zw;
			o.Normal = UnpackNormal( tex2D( _Normal, uv_Normal ) );
			float4 _MainTex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST);
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST_Instance.xy + _MainTex_ST_Instance.zw;
			o.Albedo = tex2D( _MainTex, uv_MainTex ).rgb;
			float4 _Emission_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_ST_arr, _Emission_ST);
			float2 uv_Emission = i.uv_texcoord * _Emission_ST_Instance.xy + _Emission_ST_Instance.zw;
			float2 temp_output_30_0 = ( float2( 1,1 ) / float2( 3,2 ) );
			float2 _BlockSelect_Instance = UNITY_ACCESS_INSTANCED_PROP(_BlockSelect_arr, _BlockSelect);
			float2 temp_output_32_0 = ( temp_output_30_0 * _BlockSelect_Instance );
			float2 temp_output_56_0 = (i.ase_texcoord5.xy*temp_output_30_0 + temp_output_32_0);
			o.Emission = ( tex2D( _Emission, uv_Emission ) + ( i.uv3_texcoord3.x > 0.0 ? tex2D( _Udon_3DJ_Color, (i.uv3_texcoord3*temp_output_30_0 + temp_output_32_0) ) : float4( 0,0,0,0 ) ) + ( i.ase_texcoord5.xy.x > 0.0 ? tex2D( _Udon_3DJ_Color, temp_output_56_0 ) : float4( 0,0,0,0 ) ) + ( i.uv4_texcoord4.x > 0.0 ? tex2D( _Udon_3DJ_Depth, (i.uv4_texcoord4*temp_output_30_0 + temp_output_32_0) ) : float4( 0,0,0,0 ) ) ).rgb;
			float4 _Metallic_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_Metallic_ST_arr, _Metallic_ST);
			float2 uv_Metallic = i.uv_texcoord * _Metallic_ST_Instance.xy + _Metallic_ST_Instance.zw;
			float4 tex2DNode2 = tex2D( _Metallic, uv_Metallic );
			o.Metallic = tex2DNode2.r;
			o.Smoothness = tex2DNode2.a;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.SamplerNode;1;-2435.544,-724.2338;Inherit;True;Property;_MainTex;MainTex;4;0;Create;True;0;0;0;False;0;False;-1;None;98a3ba5a6c2fd01499ef73b56e41f38c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-2435.544,-336.2339;Inherit;True;Property;_Metallic;Metallic;5;0;Create;True;0;0;0;False;0;False;-1;None;2549447bd7455334a88f64b4ef7830b6;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;3;-2435.544,-144.2339;Inherit;True;Property;_Normal;Normal;6;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;8a3b9a49e0c8cbc4fa6f9bcb70214367;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-2440.726,-528.7339;Inherit;True;Property;_Emission;Emission;7;0;Create;True;0;0;0;False;0;False;-1;None;21b051f41ebda8942931dccacc7e84c0;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;30;-2824.766,413.2988;Inherit;False;2;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-2830.766,558.2988;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;31;-3047.766,398.2988;Inherit;False;Constant;_BlockCount;Block Count;1;0;Create;True;0;0;0;False;0;False;3,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TFHCRemapNode;42;-1152.939,1024.541;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;27;-1801.451,487.9058;Inherit;True;Property;_TextureSample1;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;22;-326.6279,126.5661;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;6;-1792.726,221.2661;Inherit;True;Property;_TextureSample0;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;34;-3049.245,537.7335;Inherit;False;InstancedProperty;_BlockSelect;Block Select;8;0;Create;True;0;0;0;False;0;False;0,0;2,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;28;-2470.451,507.9058;Inherit;False;3;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;47;-2476.829,651.5425;Inherit;False;4;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;52;-1798.158,889.8614;Inherit;True;Property;_TextureSample2;Texture Sample 0;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;58;-1795.428,688.3066;Inherit;True;Property;_TextureSample3;Texture Sample 0;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;7;-1128.726,63.26606;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-2472.726,351.2661;Inherit;False;2;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;56;-2163.371,656.9496;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;60;-2171.809,499.9486;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;61;-2168.809,334.9486;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-844.939,849.5406;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;40;-1215.709,826.2153;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;193.7,90.7;Float;False;True;-1;6;ASEMaterialInspector;0;0;Standard;Camera Shader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;0;32;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.Compare;48;-1115.801,222.5354;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;4;-2599.726,131.2661;Inherit;False;Global Textures;0;;6;5151b2ab862399e41a33b2b14a355044;0;0;3;SAMPLER2D;0;SAMPLER2D;5;SAMPLER2D;6
Node;AmplifyShaderEditor.Compare;29;-1121.451,427.9058;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;79;-491.655,744.0926;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
WireConnection;30;1;31;0
WireConnection;32;0;30;0
WireConnection;32;1;34;0
WireConnection;42;0;52;1
WireConnection;27;0;4;5
WireConnection;27;1;60;0
WireConnection;22;0;9;0
WireConnection;22;1;7;0
WireConnection;22;2;48;0
WireConnection;22;3;29;0
WireConnection;6;0;4;6
WireConnection;6;1;61;0
WireConnection;52;0;4;5
WireConnection;52;1;56;0
WireConnection;58;0;4;6
WireConnection;58;1;56;0
WireConnection;7;0;5;1
WireConnection;7;2;6;0
WireConnection;56;0;47;0
WireConnection;56;1;30;0
WireConnection;56;2;32;0
WireConnection;60;0;28;0
WireConnection;60;1;30;0
WireConnection;60;2;32;0
WireConnection;61;0;5;0
WireConnection;61;1;30;0
WireConnection;61;2;32;0
WireConnection;41;0;42;0
WireConnection;41;1;40;0
WireConnection;0;0;1;0
WireConnection;0;1;3;0
WireConnection;0;2;22;0
WireConnection;0;3;2;1
WireConnection;0;4;2;4
WireConnection;0;11;79;0
WireConnection;48;0;47;1
WireConnection;48;2;58;0
WireConnection;29;0;28;1
WireConnection;29;2;27;0
WireConnection;79;0;47;1
WireConnection;79;2;41;0
ASEEND*/
//CHKSM=C8C7C74166C776B495F8EBC6A4992BAD3D59220D