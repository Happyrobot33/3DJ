using System;
using UnityEngine;

namespace com.happyrobot33.holographicreprojector
{
#if !COMPILER_UDONSHARP && UNITY_EDITOR
    using UdonSharpEditor;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine.SceneManagement;
    using VRC.Core;

    //custom editor to have a button to cycle the player

    [CustomEditor(typeof(Manager))]
    public class ManagerEditor : Editor
    {
        //subscribe a function to EditorApplication.update
        [InitializeOnLoadMethod]
        private static void SubscribeToEditorUpdate()
        {
            //TODO: This kind of sucks ass tbh
            EditorApplication.update += Update;
        }

        private static void Update()
        {
            //find any 3dj managers
            Manager[] managers = FindObjectsOfType<Manager>();
            foreach (Manager manager in managers)
            {
                manager._SetupGlobalTextures();
                manager._EnforceCameraAspectRatio();
            }
        }

        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            EditorGUI.BeginChangeCheck();

            Manager manager = (Manager)target;

            if (GUILayout.Button("Import World ID"))
            {
                PipelineManager pipelineManager = GameObject.FindObjectOfType<PipelineManager>();
                string worldId = pipelineManager.blueprintId;
                //strip it down to remove wrld_ and all -
                worldId = worldId.Replace("wrld_", "");
                worldId = worldId.Replace("-", "");

                manager.worldID = worldId;

                //save prefab
                ApplyInstanceOverride(manager);
            }

            //draw the default inspector
            //DrawDefaultInspector();
            System.Reflection.FieldInfo[] fields = target.GetType().GetFields(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
            foreach (var field in fields)
            {
                if (field.GetCustomAttributes(typeof(DeveloperOnly), true).Length == 0)
                {
                    EditorGUILayout.PropertyField(serializedObject.FindProperty(field.Name), true);
                }
                else if (((Manager)target).DeveloperMode)
                {
                    EditorGUILayout.PropertyField(serializedObject.FindProperty(field.Name), true);
                }

                //make sure headers work
                if (field.GetCustomAttributes(typeof(HeaderAttribute), true).Length > 0)
                {
                    EditorGUILayout.Space();
                    //check for specific headers
                    Areas possibleArea = Areas.None;
                    switch (field.Name)
                    {
                        case nameof(Manager.ColorTexture):
                            possibleArea = Areas.Color;
                            break;
                        case nameof(Manager.DepthTexture):
                            possibleArea = Areas.Depth;
                            break;
                        case nameof(Manager.DataTexture):
                            possibleArea = Areas.Data;
                            break;
                    }

                    if (possibleArea != Areas.None)
                    {
                        //begin horizontal
                        EditorGUILayout.BeginHorizontal();
                    }
                    
                    //render the text
                    EditorGUILayout.LabelField(((HeaderAttribute)field.GetCustomAttributes(typeof(HeaderAttribute), true)[0]).header, EditorStyles.boldLabel);

                    if (possibleArea != Areas.None)
                    {
                        if (GUILayout.Button("Visualize"))
                        {
                            manager.CurrentlyEditingArea = possibleArea;
                            ApplyInstanceOverride(manager);
                        }

                        //end horizontal
                        EditorGUILayout.EndHorizontal();
                    }
                }
            }

            if (GUILayout.Button(manager.DeveloperMode ? "Exit Developer Mode" : "Enter Developer Mode"))
            {
                manager.DeveloperMode = !manager.DeveloperMode;
                ApplyInstanceOverride(manager);
            }

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Record"))
            {
                manager.SetSource(Source.Record);
                ApplyInstanceOverride(manager);
            }

            if (GUILayout.Button("Playback"))
            {
                manager.SetSource(Source.Playback);
                ApplyInstanceOverride(manager);
            }
            EditorGUILayout.EndHorizontal();

            if (GUILayout.Button("Setup all render internals"))
            {
                UpdateAllTextureInternals(manager);
            }

            try
            {
    #region Video region management

                //determine the aspect ratio of the video texture
                float videoPlayerAspect = manager.VideoTexture.width / (float)manager.VideoTexture.height;

                //display a box with the aspect ratio
                Rect videoRect = GUILayoutUtility.GetAspectRect(videoPlayerAspect);

                GUIStyle rtStyle = new GUIStyle("box");
                //make content have 0 padding
                rtStyle.padding = new RectOffset(0, 0, 0, 0);

                //show a box in it, with the texture as the content
                GUI.Box(videoRect, manager.PreviewLayoutTexture, rtStyle);

                //display another box inside the first box based on the UVPositionTopLeft and UVPositionSize
                /* Rect recordRect = new Rect(videoRect.x + videoRect.width * manager.UVPosition.x / manager.VideoTexture.width,
                    videoRect.y + videoRect.height * manager.UVPosition.y / manager.VideoTexture.height,
                    videoRect.width * UVSize.x / manager.VideoTexture.width,
                    videoRect.height * UVSize.y / manager.VideoTexture.height); */

                Vector2Int topLeft = Manager.CalculateTopLeftUV(manager, manager.ColorAnchor, manager.ColorUVPosition, manager.ColorTexture);
                DrawRTArea(manager, manager.ColorExtractTexture, videoRect, rtStyle, topLeft, manager.CurrentlyEditingArea == Areas.Color);

                topLeft = Manager.CalculateTopLeftUV(manager, manager.DepthAnchor, manager.DepthUVPosition, manager.DepthTexture);
                DrawRTArea(manager, manager.DepthExtractTexture, videoRect, rtStyle, topLeft, manager.CurrentlyEditingArea == Areas.Depth);

                topLeft = Manager.CalculateTopLeftUV(manager, manager.DataAnchor, manager.DataUVPosition, manager.DataTexture);
                DrawRTArea(manager, manager.DataExtractTexture, videoRect, rtStyle, topLeft, manager.CurrentlyEditingArea == Areas.Data);
    #endregion

    #region Debug Information
                //calculate the cell size based on horizontal width / 3
                /* int cellSize = UVSize.x / 3;
                EditorGUILayout.LabelField(string.Format("Cell Size: {0}x{0}", cellSize)); */
    #endregion
            }
            catch (Exception e)
            {
                GUILayout.Label("Error: " + e.Message);
                //Debug.LogError(e);
            }

            /* #region Render texture management
            //watch for changes on the UVSize variable
            if (EditorGUI.EndChangeCheck() || GUILayout.Button("Force Update"))
            {
                //determine the aspect ratio of the record texture
                const int recordSystemBaseWidth = 639;
                const int recordSystemBaseHeight = 655;
                const float recordSystemAspect = recordSystemBaseWidth / (float)recordSystemBaseHeight;

                //make sure the uvsize is divisible by 3 horizontally
                if (manager.UVSize.x % 3 != 0)
                {
                    manager.UVSize = new Vector2Int(manager.UVSize.x + (3 - manager.UVSize.x % 3), manager.UVSize.y);
                }

                //update the height based on the aspect ratio
                manager.UVSize.y = (int)(manager.UVSize.x / recordSystemAspect);

                //now we need to update all of the render textures to match
                manager.RecordTexture.Release();
                manager.RecordTexture.width = manager.UVSize.x;
                manager.RecordTexture.height = manager.UVSize.y;

                serializedObject.ApplyModifiedProperties();
            }
            //#endregion */

            if (EditorGUI.EndChangeCheck())
            {
                serializedObject.ApplyModifiedProperties();
                UpdateAllTextureInternals(manager);
            }
        }

        private static void ApplyInstanceOverride(UnityEngine.Object obj)
        {
            PrefabUtility.RecordPrefabInstancePropertyModifications(obj);
            EditorUtility.SetDirty(obj);
        }

        private static void UpdateAllTextureInternals(Manager manager)
        {
            manager.RecordTexture.ClearUpdateZones();
            CustomRenderTextureUpdateZone[] zones = new CustomRenderTextureUpdateZone[3];

            //depth
            zones[0] = new CustomRenderTextureUpdateZone()
            {
                updateZoneCenter = (Vector2)Manager.CalculateTopLeftUV(manager, manager.DepthAnchor, manager.DepthUVPosition, manager.DepthTexture) + new Vector2(manager.DepthTextureSize.x / 2, manager.DepthTextureSize.y / 2),
                updateZoneSize = new Vector2(manager.DepthTextureSize.x, manager.DepthTextureSize.y),
                passIndex = 0
            };

            //color
            zones[1] = new CustomRenderTextureUpdateZone()
            {
                updateZoneCenter = (Vector2)Manager.CalculateTopLeftUV(manager, manager.ColorAnchor, manager.ColorUVPosition, manager.ColorTexture) + new Vector2(manager.ColorTextureSize.x / 2, manager.ColorTextureSize.y / 2),
                updateZoneSize = new Vector2(manager.ColorTextureSize.x, manager.ColorTextureSize.y),
                passIndex = 1
            };

            //data
            zones[2] = new CustomRenderTextureUpdateZone()
            {
                updateZoneCenter = (Vector2)Manager.CalculateTopLeftUV(manager, manager.DataAnchor, manager.DataUVPosition, manager.DataTexture) + new Vector2(manager.DataTextureSize.x / 2, manager.DataTextureSize.y / 2),
                updateZoneSize = new Vector2(manager.DataTextureSize.x, manager.DataTextureSize.y),
                passIndex = 2
            };

            manager.RecordTexture.SetUpdateZones(zones);

            //set resolution to match what the playback will look like
            manager.RecordTexture.Release();
            manager.RecordTexture.width = manager.VideoTexture.width;
            manager.RecordTexture.height = manager.VideoTexture.height;
            //unrelease it
            manager.RecordTexture.Initialize();

            manager.ColorTexture.Release();
            manager.ColorTexture.width = manager.ColorTextureSize.x;
            manager.ColorTexture.height = manager.ColorTextureSize.y;
            manager.ColorTexture.Create();

            manager.DepthTexture.Release();
            manager.DepthTexture.width = manager.DepthTextureSize.x;
            manager.DepthTexture.height = manager.DepthTextureSize.y;
            manager.DepthTexture.Create();

            manager.DataTexture.Release();
            manager.DataTexture.width = manager.DataTextureSize.x;
            manager.DataTexture.height = manager.DataTextureSize.y;
            manager.DataTexture.Create();

            //setup the individual internal render textures for playback
            manager.ColorExtractTexture.Release();
            manager.ColorExtractTexture.width = manager.ColorTexture.width;
            manager.ColorExtractTexture.height = manager.ColorTexture.height;
            manager.ColorExtractTexture.Initialize();

            manager.DepthExtractTexture.Release();
            manager.DepthExtractTexture.width = manager.DepthTexture.width;
            manager.DepthExtractTexture.height = manager.DepthTexture.height;
            manager.DepthExtractTexture.Initialize();

            manager.DataExtractTexture.Release();
            manager.DataExtractTexture.width = manager.DataTexture.width;
            manager.DataExtractTexture.height = manager.DataTexture.height;
            manager.DataExtractTexture.Initialize();

            manager.SetupRenderTextureExtractionZones();

            manager._EnforceCameraAspectRatio();

            manager._SetupGlobalTextures();
        }

        private Vector2Int DrawRTArea(Manager manager, Texture texture, Rect ParentRect, GUIStyle imageStyle, Vector2Int topLeft, bool showHandles)
        {
            Vector2Int innerTextureSize = new Vector2Int(texture.width, texture.height);
            Vector2Int outerTextureSize = new Vector2Int(manager.VideoTexture.width, manager.VideoTexture.height);
            Rect innerRect = new Rect(ParentRect.x + ParentRect.width * topLeft.x / manager.VideoTexture.width,
                ParentRect.y + ParentRect.height * topLeft.y / manager.VideoTexture.height,
                ParentRect.width * innerTextureSize.x / manager.VideoTexture.width,
                ParentRect.height * innerTextureSize.y / manager.VideoTexture.height);

            Rect pixelBasedRecordRect = CreatePixelBasedRect(topLeft, innerTextureSize);
            Rect pixelBasedOuterRect = CreatePixelBasedRect(Vector2Int.zero, outerTextureSize);

            //show a box in it, with a outline and text in it
            GUI.Box(innerRect, texture, imageStyle);

            int handleThickness = 5;
            GUIStyle handleStyle = new GUIStyle("box");
            handleStyle.normal.background = EditorGUIUtility.whiteTexture;

            if (showHandles)
            {
                //draw a dot at the corners
                CornerDots(innerRect, handleThickness);

                //display text on all 4 sides of the record box that shows its width and height
                EdgeSizeLabels(innerTextureSize, innerRect);

                //Offset Lines
                DrawOffsetLines(pixelBasedRecordRect, pixelBasedOuterRect, ParentRect, innerRect, handleThickness, handleStyle);
            }
            return innerTextureSize;
        }

        private static Rect CreatePixelBasedRect(Vector2Int topLeft, Vector2Int TextureSize)
        {


            //get the record rect in terms of the video textures pixels
            return new Rect(topLeft.x, topLeft.y, TextureSize.x, TextureSize.y);
        }


        static GUIStyle labelStyle
        {
            get
            {
                GUIStyle labelStyle = new GUIStyle(EditorStyles.whiteLabel);
                //centered
                labelStyle.alignment = TextAnchor.MiddleCenter;
                //full white
                labelStyle.normal.textColor = Color.white;
                //black background
                Texture2D background = new Texture2D(1, 1);
                background.SetPixel(0, 0, Color.black);
                background.Apply();
                labelStyle.normal.background = background;

                //font size
                labelStyle.fontSize = 15;
                return labelStyle;
            }
        }


        private void DrawOffsetLines(Rect pixelBasedInnerRect, Rect pixelBasedOuterRect, Rect parentRect, Rect innerRect, int handleThickness, GUIStyle handleStyle)
        {
            if (innerRect.yMin != parentRect.yMin)
            {
                DrawLine(new Vector2(innerRect.xMin, parentRect.yMin), new Vector2(innerRect.xMin, innerRect.yMin), handleThickness, handleStyle, pixelBasedInnerRect.yMin.ToString());
            }
            if (innerRect.xMin != parentRect.xMin)
            {
                DrawLine(new Vector2(parentRect.xMin, innerRect.yMin), new Vector2(innerRect.xMin, innerRect.yMin), handleThickness, handleStyle, pixelBasedInnerRect.xMin.ToString());
            }

            if (innerRect.xMax != parentRect.xMax)
            {
                DrawLine(new Vector2(parentRect.xMax, innerRect.yMax), new Vector2(innerRect.xMax, innerRect.yMax), handleThickness, handleStyle, (pixelBasedOuterRect.xMax - pixelBasedInnerRect.xMax).ToString());
            }

            if (innerRect.yMax != parentRect.yMax)
            {
                DrawLine(new Vector2(innerRect.xMax, parentRect.yMax), new Vector2(innerRect.xMax, innerRect.yMax), handleThickness, handleStyle, (pixelBasedOuterRect.yMax - pixelBasedInnerRect.yMax).ToString());
            }
        }


        private static void EdgeSizeLabels(Vector2Int size, Rect rect)
        {
            Handles.Label(new Vector3(rect.center.x, rect.yMin, 0), size.x.ToString(), labelStyle);
            Handles.Label(new Vector3(rect.xMin, rect.center.y, 0), size.y.ToString(), labelStyle);
            Handles.Label(new Vector3(rect.center.x, rect.yMax, 0), size.x.ToString(), labelStyle);
            Handles.Label(new Vector3(rect.xMax, rect.center.y, 0), size.y.ToString(), labelStyle);
        }


        private static void CornerDots(Rect rect, int handleThickness)
        {
            Handles.DrawSolidDisc(new Vector3(rect.xMin, rect.yMin, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(rect.xMax, rect.yMin, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(rect.xMin, rect.yMax, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(rect.xMax, rect.yMax, 0), Vector3.forward, handleThickness);
        }

        private Rect DrawLine(Vector2 start, Vector2 end, int thickness, GUIStyle style, string text)
        {
            Vector2 delta = end - start;
            float angle = Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg;
            float length = delta.magnitude;

            Rect rect = new Rect(start.x, start.y - thickness / 2, length, thickness);

            GUIUtility.RotateAroundPivot(angle, start);
            GUI.Box(rect, GUIContent.none, style);
            GUIUtility.RotateAroundPivot(-angle, start);

            //return a rect that has opposite corners at the start and end
            Rect finalrect = new Rect(Mathf.Min(start.x, end.x), Mathf.Min(start.y, end.y), Mathf.Abs(start.x - end.x), Mathf.Abs(start.y - end.y));

            if (!string.IsNullOrEmpty(text))
            {
                Handles.Label(new Vector3(finalrect.center.x, finalrect.center.y, 0), text, labelStyle);
            }

            return finalrect;
        }
    }
#endif
}
