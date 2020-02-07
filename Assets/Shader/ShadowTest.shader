// Unlit shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "ShadowTest/Texture" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_ShadowOffset("ShadowOffset",float) = 0.03
	_ShadowTexture("Shadow Texture", 2D) = "white" {}
}

SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 100
	
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float4 shadowMatrix : TEXCOORD1;//v2f结构体添加投影矩阵
				UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform float _ShadowOffset;
			uniform float4x4 _ShadowMatrix;
			uniform sampler2D _ShadowTexture;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				float4x4 mvp = mul(_ShadowMatrix, unity_ObjectToWorld);
				//顶点的投影矩阵转换到世界空间下计算
				o.shadowMatrix = mul(mvp, float4(v.vertex.xyz, 1));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				UNITY_APPLY_FOG(i.fogCoord, col);
				UNITY_OPAQUE_ALPHA(col.a);

				float4 uvPos = i.shadowMatrix;
				uvPos.x = uvPos.x * 0.5f + uvPos.w * 0.5f;//变换到[0,w]
				uvPos.y = uvPos.y * 0.5f + uvPos.w * 0.5f;//变换到[0,w]

#if UNITY_UV_STARTS_AT_TOP	  //Dx like
				uvPos.y = uvPos.w - uvPos.y;
#endif

				float depth = DecodeFloatRGBA(tex2D(_ShadowTexture, uvPos.xy / uvPos.w));//从深度图中取出深度
				float depthPixel = uvPos.z / uvPos.w;//从实际的camera中渲染出深度


#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
													 //GL 的处理方式
				depthPixel = depthPixel * 0.5f + 0.5f;
#else
													 //DX 的处理方式
				depthPixel = depthPixel;
#endif

				//比较深度信息，为了避免阴影的斑点，添加一个0.7的偏移（投影的生成）
				//DX以及GL移动平台的起始坐标不同，所以要分开处理。
				float shadowCol = 1.0f;
#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
				if (depthPixel - depth > _ShadowOffset)
					shadowCol = 0.7;
#else
				if (depthPixel - depth < -_ShadowOffset)
					shadowCol = 0.7;
#endif
				
				col *= shadowCol;

				return col;
			}
		ENDCG
	}
}
Fallback "Mobile/Diffuse"
}
