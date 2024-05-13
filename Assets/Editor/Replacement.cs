using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Replacement : MonoBehaviour
{
    [MenuItem("Tools/ReplacementShader")]
    static void ReplacementShader()
    {
        GameObject[] objs = Selection.gameObjects;
        foreach (GameObject obj in objs)
        {
            //get the camera component
            Camera cam = obj.GetComponent<Camera>();
            if (cam != null)
            {
                //replace with unity standard
                Shader shader = Shader.Find("zwriteforce");
                //set the replacement shader
                cam.SetReplacementShader(shader, "");
            }
        }
    }
}
