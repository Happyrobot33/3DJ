using UnityEngine;
using UnityEditor;

public class SaveRenderTextureToFile {
    [MenuItem("Assets/Save RenderTexture to file")]
    public static void SaveRTToFile()
    {
        RenderTexture rt = Selection.activeObject as RenderTexture;

        RenderTexture.active = rt;
        //use a unorm texture format
        Texture2D tex = new Texture2D(rt.width, rt.height, TextureFormat.RGBAFloat, false);
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        RenderTexture.active = null;

        //convert linear to srgb in the texture
        for (int i = 0; i < tex.width; i++)
        {
            for (int j = 0; j < tex.height; j++)
            {
                Color c = tex.GetPixel(i, j);
                c.r = Mathf.LinearToGammaSpace(c.r);
                c.g = Mathf.LinearToGammaSpace(c.g);
                c.b = Mathf.LinearToGammaSpace(c.b);
                tex.SetPixel(i, j, c);
            }
        }

        byte[] bytes;
        bytes = tex.EncodeToPNG();
        
        string path = AssetDatabase.GetAssetPath(rt) + ".png";
        System.IO.File.WriteAllBytes(path, bytes);
        AssetDatabase.ImportAsset(path);
        Debug.Log("Saved to " + path);
    }

    [MenuItem("Assets/Save RenderTexture to file", true)]
    public static bool SaveRTToFileValidation()
    {
        return Selection.activeObject is RenderTexture;
    }
}
