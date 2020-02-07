using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class LightShadowMap : MonoBehaviour {
    public Camera m_Camera;
    public Material m_DepthMat;
    public RenderTexture m_RenderTexture;

    List<Renderer> m_Render = new List<Renderer>();

    public static LightShadowMap instance;

    public GameObject go;
    public int size;
    
    void Awake()
    {
        instance = this;
    }

    void Destroy()
    {
        instance = null;
    }
	// 设置阴影图的尺寸
	void Start () {

        SetRender(go, size);

    }

    public void SetRender(GameObject go, int size)
    {
        //DestorySelf();
        if (m_Camera != null)
        {
            m_Camera.GetComponent<Camera>().enabled = true;
            m_Camera.depthTextureMode = DepthTextureMode.Depth;

            int textureSize = size;
            if (m_RenderTexture == null)
            {
                m_RenderTexture = new RenderTexture(textureSize, textureSize, 0, RenderTextureFormat.ARGB32);
                m_RenderTexture.name = "shadowTexture" + GetInstanceID();
                m_RenderTexture.isPowerOfTwo = true;
                m_RenderTexture.hideFlags = HideFlags.DontSave;
            }
            m_Camera.targetTexture = m_RenderTexture;
        }

        // MeshRenderer[] Renders = go.transform.GetComponentsInChildren<MeshRenderer>();
        // foreach (MeshRenderer smr in Renders)
        // {
        //     m_Render.Add(smr);
        // }

        SkinnedMeshRenderer[] Renders = go.transform.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (SkinnedMeshRenderer smr in Renders)
        {
            m_Render.Add(smr);
        }
    }

    void Update()
    {
        if (m_Render.Count == 0)
            return;
        //将投影从物体坐标系转换到世界坐标系
        Matrix4x4 matVP = GL.GetGPUProjectionMatrix(GetComponent<Camera>().projectionMatrix, true) * GetComponent<Camera>().worldToCameraMatrix;
        foreach (Renderer smr in m_Render)
        {
            if (smr == null)
                return;
            foreach (Material mm in smr.materials)
            {
                mm.SetMatrix("_ShadowMatrix", matVP);
                mm.SetTexture("_ShadowTexture", m_RenderTexture);
            }
        }
    }

    // public void DestorySelf()
    // {
    //     m_Render.Clear();
    //     //m_Render = null;
    //     if (m_RenderTexture != null)
    //     {
    //         Destroy(m_RenderTexture);
    //         m_RenderTexture = null;
    //     }
    //     if(m_Camera != null)
    //         m_Camera.GetComponent<Camera>().enabled = false;
    // }

    //从相机复制深度图
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (m_DepthMat != null)
        {
            Graphics.Blit(source, destination, m_DepthMat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    // void OnDestroy()
    // {
    //     DestorySelf();
    // }
}
