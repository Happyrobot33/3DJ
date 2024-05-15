// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Chaperone"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.01
		_Outline("Outline", 2D) = "white" {}
		_Color("Color", Color) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float2 uv_texcoord;
			float eyeDepth;
		};

		uniform float4 _Color;
		uniform sampler2D _Outline;
		uniform float4 _Outline_ST;
		uniform float _Cutoff = 0.01;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Emission = _Color.rgb;
			o.Alpha = 1;
			float2 uv_Outline = i.uv_texcoord * _Outline_ST.xy + _Outline_ST.zw;
			float cameraDepthFade6 = (( i.eyeDepth -_ProjectionParams.y - 0.0 ) / 1.0);
			float clampResult13 = clamp( (1.0 + (cameraDepthFade6 - 0.0) * (0.0 - 1.0) / (1.0 - 0.0)) , 0.0 , 1.0 );
			float2 break19_g1 = ( i.uv_texcoord * float2( 10,13 ) );
			float temp_output_20_0_g1 = ( break19_g1.x * 1.5 );
			float2 appendResult14_g1 = (float2(temp_output_20_0_g1 , ( break19_g1.y + ( ( floor( temp_output_20_0_g1 ) % 2.0 ) * 0.5 ) )));
			float2 break12_g1 = abs( ( ( appendResult14_g1 % float2( 1,1 ) ) - float2( 0.5,0.5 ) ) );
			float smoothstepResult1_g1 = smoothstep( 0.0 , 0.2 , ( abs( ( max( ( ( break12_g1.x * 1.5 ) + break12_g1.y ) , ( break12_g1.y * 2.0 ) ) - 1.0 ) ) * 2.0 ));
			clip( ( tex2D( _Outline, uv_Outline ).a + (( clampResult13 >= 0.01 && clampResult13 <= 0.02 ) ? 1.0 :  ( (1.0 + (smoothstepResult1_g1 - 0.0) * (0.0 - 1.0) / (1.0 - 0.0)) * clampResult13 ) ) ) - _Cutoff );
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.FunctionNode;3;-896.2598,222.0629;Inherit;False;Hex Lattice;-1;;1;56d977fb137832a498dced8436cf6708;0;3;3;FLOAT2;10,13;False;2;FLOAT;1;False;4;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;5;-618.686,208.9113;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-865.8045,-142.6973;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;12;-446.5266,-327.5906;Inherit;False;Property;_Color;Color;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.3202362,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;1;-1228.371,-208.4258;Inherit;True;Property;_Outline;Outline;1;0;Create;True;0;0;0;False;0;False;None;269081054c2f7b448a7ffa6561cdec1b;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;923.6316,18.82802;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Chaperone;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0.01;True;True;0;True;TransparentCutout;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleAddOpNode;4;444.8093,159.9131;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;13;-295.7192,437.9229;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;9;-558.5959,420.13;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-89.6149,195.3395;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;32;201.8054,326.8395;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.01;False;2;FLOAT;0.02;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CameraDepthFade;6;-1012.78,435.6363;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
WireConnection;5;0;3;0
WireConnection;2;0;1;0
WireConnection;0;2;12;0
WireConnection;0;10;4;0
WireConnection;4;0;2;4
WireConnection;4;1;32;0
WireConnection;13;0;9;0
WireConnection;9;0;6;0
WireConnection;8;0;5;0
WireConnection;8;1;13;0
WireConnection;32;0;13;0
WireConnection;32;4;8;0
ASEEND*/
//CHKSM=BC3CE3D47E26F1267C419A2954690492EA010201