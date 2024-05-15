// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Debug"
{
	Properties
	{
		[NoScaleOffset]_ColorAlpha("Color/Alpha", 2D) = "white" {}
		[NoScaleOffset]_Depth("Depth", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _ColorAlpha;
		uniform sampler2D _Depth;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 temp_output_18_0 = (float2( 0,0 ) + (i.uv_texcoord - float2( 0,0 )) * (float2( 1,1 ) - float2( 0,0 )) / (float2( 0.1666667,1 ) - float2( 0,0 )));
			float4 tex2DNode1 = tex2D( _ColorAlpha, temp_output_18_0 );
			float4 break6 = tex2DNode1;
			float4 color9 = IsGammaSpace() ? float4(1,0,0,0) : float4(1,0,0,0);
			float4 color11 = IsGammaSpace() ? float4(0,1,0,0) : float4(0,1,0,0);
			float4 color14 = IsGammaSpace() ? float4(0,0,1,0) : float4(0,0,1,0);
			o.Emission = ( (( i.uv_texcoord.x >= 0.0 && i.uv_texcoord.x <= 0.1666667 ) ? tex2DNode1 :  float4( 0,0,0,0 ) ) + ( (( i.uv_texcoord.x >= 0.1666667 && i.uv_texcoord.x <= 0.3333333 ) ? break6.r :  0.0 ) * color9 ) + ( (( i.uv_texcoord.x >= 0.3333333 && i.uv_texcoord.x <= 0.5 ) ? break6.g :  0.0 ) * color11 ) + ( (( i.uv_texcoord.x >= 0.5 && i.uv_texcoord.x <= 0.6666667 ) ? break6.b :  0.0 ) * color14 ) + (( i.uv_texcoord.x >= 0.6666667 && i.uv_texcoord.x <= 0.8333333 ) ? break6.a :  0.0 ) + (( i.uv_texcoord.x >= 0.8333333 && i.uv_texcoord.x <= 1.0 ) ? tex2D( _Depth, temp_output_18_0 ).r :  0.0 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;255.4949,556.0044;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;278.816,967.8681;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;288.8865,1415.721;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;9;-71.80981,393.989;Inherit;False;Constant;_Red;Red;1;0;Create;True;0;0;0;False;0;False;1,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;11;-48.48867,805.8527;Inherit;False;Constant;_Green;Green;1;0;Create;True;0;0;0;False;0;False;0,1,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;14;-38.41828,1253.706;Inherit;False;Constant;_Blue;Blue;1;0;Create;True;0;0;0;False;0;False;0,0,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;7;667.1745,798.1315;Inherit;False;6;6;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1138.781,742.3099;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Debug;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SamplerNode;1;-1091.332,249.4108;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-1706.888,611.6309;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCCompareWithRange;5;-74.43384,206.3461;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1666667;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;10;-65.63214,597.5571;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.1666667;False;2;FLOAT;0.3333333;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;13;-42.311,1009.421;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.3333333;False;2;FLOAT;0.5;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;16;-32.24062,1457.274;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.6666667;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;17;-27.90446,1696.735;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.6666667;False;2;FLOAT;0.8333333;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;19;-32.44989,1908.087;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.8333333;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;21;-680.7333,1657.97;Inherit;True;Property;_TextureSample1;Texture Sample 1;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;6;-636.8041,331.7115;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TexturePropertyNode;2;-2181.523,354.2213;Inherit;True;Property;_ColorAlpha;Color/Alpha;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;d5eade7947abe2d4ea65c23f9a0c12b3;d5eade7947abe2d4ea65c23f9a0c12b3;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;20;-1094.89,1696.288;Inherit;True;Property;_Depth;Depth;1;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;283657a5e09fe4444882d8963bc94119;283657a5e09fe4444882d8963bc94119;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TFHCRemapNode;18;-1369.405,373.1136;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0.1666667,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
WireConnection;8;0;10;0
WireConnection;8;1;9;0
WireConnection;12;0;13;0
WireConnection;12;1;11;0
WireConnection;15;0;16;0
WireConnection;15;1;14;0
WireConnection;7;0;5;0
WireConnection;7;1;8;0
WireConnection;7;2;12;0
WireConnection;7;3;15;0
WireConnection;7;4;17;0
WireConnection;7;5;19;0
WireConnection;0;2;7;0
WireConnection;1;0;2;0
WireConnection;1;1;18;0
WireConnection;5;0;3;1
WireConnection;5;3;1;0
WireConnection;10;0;3;1
WireConnection;10;3;6;0
WireConnection;13;0;3;1
WireConnection;13;3;6;1
WireConnection;16;0;3;1
WireConnection;16;3;6;2
WireConnection;17;0;3;1
WireConnection;17;3;6;3
WireConnection;19;0;3;1
WireConnection;19;3;21;1
WireConnection;21;0;20;0
WireConnection;21;1;18;0
WireConnection;6;0;1;0
WireConnection;18;0;3;0
ASEEND*/
//CHKSM=F043732AB3E46E1BEBF9226E00DD69C611B3C373