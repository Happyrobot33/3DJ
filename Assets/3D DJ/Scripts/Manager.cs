
using System;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;
using VRC.SDK3.Components;

namespace com.happyrobot33.holographicreprojector
{
    using TMPro;


#if !COMPILER_UDONSHARP && UNITY_EDITOR
    using UdonSharpEditor;
    using UnityEditor;
    //custom editor to have a button to cycle the player
    [CustomEditor(typeof(Manager))]
    public class ManagerEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            EditorGUI.BeginChangeCheck();

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
            }

            Manager manager = (Manager)target;

            if (GUILayout.Button(manager.DeveloperMode ? "Exit Developer Mode" : "Enter Developer Mode"))
            {
                manager.DeveloperMode = !manager.DeveloperMode;
            }

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Record"))
            {
                manager.SwitchSourceToRecord();
            }

            if (GUILayout.Button("Playback"))
            {
                manager.SwitchSourceToPlayback();
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Edit Data"))
            {
                manager.CurrentlyEditingArea = Areas.Data;
            }
            if (GUILayout.Button("Edit Color"))
            {
                manager.CurrentlyEditingArea = Areas.Color;
            }
            if (GUILayout.Button("Edit Depth"))
            {
                manager.CurrentlyEditingArea = Areas.Depth;
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

    [AttributeUsage(AttributeTargets.Field)]
    public class DeveloperOnly : PropertyAttribute { }

    public enum Mode
    {
        Record,
        Playback
    }

    public enum Anchor
    {
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    public enum Areas
    {
        Color,
        Depth,
        Data
    }

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class Manager : UdonSharpBehaviour
    {
        [DeveloperOnly]
        public GameObject Recorder;
        [DeveloperOnly]
        public Material DataInput;
        [DeveloperOnly]
        public Material[] playbackMaterials;
        public RenderTexture VideoTexture;

        [Header("Color:")]
        [DeveloperOnly]
        public RenderTexture ColorTexture;
        public Vector2Int ColorTextureSize;
        public Anchor ColorAnchor;
        public Vector2Int ColorUVPosition;
        [DeveloperOnly]
        public Material ColorExtractMaterial;
        [DeveloperOnly]
        public CustomRenderTexture ColorExtractTexture;

        [Header("Depth:")]
        [DeveloperOnly]
        public RenderTexture DepthTexture;
        public Vector2Int DepthTextureSize;
        public Anchor DepthAnchor;
        public Vector2Int DepthUVPosition;
        [DeveloperOnly]
        public Material DepthExtractMaterial;
        [DeveloperOnly]
        public CustomRenderTexture DepthExtractTexture;

        [Header("Data:")]
        [DeveloperOnly]
        public RenderTexture DataTexture;
        public Vector2Int DataTextureSize;
        public Anchor DataAnchor;
        public Vector2Int DataUVPosition;
        [DeveloperOnly]
        public Material DataExtractMaterial;
        [DeveloperOnly]
        public CustomRenderTexture DataExtractTexture;

        /// <summary>
        /// The texture that the 3DJ system is creating
        /// </summary>
        [DeveloperOnly]
        public CustomRenderTexture RecordTexture;
        [DeveloperOnly]
        public Slider OffsetSlider;
        [DeveloperOnly]
        public TMP_Dropdown PlayerDropdown;

        private VRCPlayerApi playerToRecord;
        private Camera[] Cameras;
        private Mode mode = Mode.Playback;

        #region Inspector Variables
        [Header("Preview Textures")]
        public Texture PreviewLayoutTexture;
        [DeveloperOnly]
        public bool DeveloperMode;
        [DeveloperOnly]
        public Areas CurrentlyEditingArea;
        #endregion
        void Start()
        {
            playerToRecord = Networking.LocalPlayer;

            //get all the children cameras of the recorder
            Cameras = Recorder.GetComponentsInChildren<Camera>();

            SwitchSourceToPlayback();

            //make sure the recorder is off
            Recorder.SetActive(false);
        }

        void Update()
        {
            if (mode == Mode.Record)
            {
                //get the player position
                Vector3 playerPos = playerToRecord.GetPosition();

                //get the players head
                Vector3 headPos = playerToRecord.GetBonePosition(HumanBodyBones.Head);

                //add the offset to the head position
                headPos.y += OffsetSlider.value;

                //determine the midpoint between the player and the head
                Vector3 recorderPos = (playerPos + headPos) / 2;

                //move the recorder to the player position
                Recorder.transform.position = recorderPos;

                //set the rotation to the player rotation + 45 on the y axis
                Recorder.transform.rotation = Quaternion.Euler(0, playerToRecord.GetRotation().eulerAngles.y + 45, 0);

                //determine the scale by getting the distance between the player and the head on the y axis
                //TODO: Make based on the players size too, instead of just being based on the world
                float scale = Math.Abs(playerPos.y - headPos.y) / 2;

                //set the scale of the recorder
                Recorder.transform.localScale = new Vector3(scale, scale, scale);

                //setup the camera properties
                foreach (Camera cam in Cameras)
                {
                    cam.orthographicSize = scale;
                    cam.nearClipPlane = 0;
                    cam.farClipPlane = scale * 2;
                }

                //set the material variables
                DataInput.SetVector("_Position", recorderPos);
                DataInput.SetFloat("_Scale", scale * 2);
                DataInput.SetFloat("_Rotation", playerToRecord.GetRotation().eulerAngles.y + 45);
            }
        }

        public void ToggleRecordSystem()
        {
            Recorder.SetActive(!Recorder.activeSelf);

            if (Recorder.activeSelf)
            {
                mode = Mode.Record;
            }
            else
            {
                mode = Mode.Playback;
            }
        }

        public void ToggleHolographic()
        {
            //toggle the holographic effect
            const string keyword = "_HoloAffect";

            foreach (Material mat in playbackMaterials)
            {
                mat.SetFloat(keyword, mat.GetFloat(keyword) == 0 ? 1 : 0);
            }
        }

        public void SwitchSourceToPlayback()
        {
            SetupRenderTextureExtractionZones(VideoTexture);
            //disable the recorder
            //Recorder.SetActive(false);
            //mode = Mode.Playback;
        }

        private void SetupRenderTextureExtractionZones(Texture source)
        {
            SetupSource(source, ColorExtractMaterial, CalculateTopLeftUV(this, ColorAnchor, ColorUVPosition, ColorTexture), new Vector2Int(ColorTexture.width, ColorTexture.height));
            SetupSource(source, DepthExtractMaterial, CalculateTopLeftUV(this, DepthAnchor, DepthUVPosition, DepthTexture), new Vector2Int(DepthTexture.width, DepthTexture.height));
            SetupSource(source, DataExtractMaterial, CalculateTopLeftUV(this, DataAnchor, DataUVPosition, DataTexture), new Vector2Int(DataTexture.width, DataTexture.height));

        }

        public void SwitchSourceToRecord()
        {
            //Recorder.SetActive(true);
            SetupRenderTextureExtractionZones(RecordTexture);
        }

        public void PlayerDropdownUpdate()
        {
            //get the player index
            int playerIndex = PlayerDropdown.value;

            //get the player list
            VRCPlayerApi[] players = VRCPlayerApi.GetPlayers(new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()]);

            //get the player
            playerToRecord = players[playerIndex];
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            //clear
            PlayerDropdown.ClearOptions();

            //rebuild the list
            VRCPlayerApi[] players = VRCPlayerApi.GetPlayers(new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()]);
            TMP_Dropdown.OptionData[] options = new TMP_Dropdown.OptionData[players.Length];
            for (int i = 0; i < players.Length; i++)
            {
                options[i] = new TMP_Dropdown.OptionData(players[i].displayName);
            }

            PlayerDropdown.AddOptions(options);

            CheckDropdownSelection(players);
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            //REMEMBER, The player leaving is STILL in the player list, so we need to remove them inside here
            //clear
            PlayerDropdown.ClearOptions();

            //rebuild the list
            VRCPlayerApi[] players = VRCPlayerApi.GetPlayers(new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()]);

            //create a new list with the player removed
            VRCPlayerApi[] realPlayersList = new VRCPlayerApi[players.Length - 1];
            for (int i = 0, j = 0; i < players.Length; i++)
            {
                if (players[i] == player)
                {
                    continue;
                }
                realPlayersList[j] = players[i];
                j++;
            }
            players = realPlayersList;

            TMP_Dropdown.OptionData[] options = new TMP_Dropdown.OptionData[players.Length];
            for (int i = 0; i < players.Length; i++)
            {
                options[i] = new TMP_Dropdown.OptionData(players[i].displayName);
            }

            PlayerDropdown.AddOptions(options);

            //CheckDropdownSelection(players);
            PlayerDropdown.SetValueWithoutNotify(0);

            if (player == playerToRecord)
            {
                playerToRecord = players[0];
            }
        }

        /// <summary>
        /// Check the dropdown selection and re-select the player that was previously selected
        /// </summary>
        private void CheckDropdownSelection(VRCPlayerApi[] players)
        {
            //re-select the player that was previously selected
            bool broke = false;
            for (int i = 0; i < players.Length; i++)
            {
                if (players[i].displayName == playerToRecord.displayName)
                {
                    PlayerDropdown.value = i;
                    broke = true;
                    break;
                }
            }
            //if (!broke)
            //{
            //    playerToRecord = players[0];
           // }
        }


        private void SetupSource(Texture source, Material extractor, Vector2Int topLeft, Vector2Int size)
        {
            //setup the source switcher to be based on the uv position info
            Vector2 center = new Vector2(topLeft.x + (float)size.x / 2, topLeft.y + (float)size.y / 2);
            extractor.SetVector("_Center", center);
            extractor.SetVector("_Size", new Vector2(size.x, size.y));
            extractor.SetTexture("_RT", source);
        }

        /// <summary>
        /// Calculate the top left UV position based on the anchor
        /// </summary>
        internal static Vector2Int CalculateTopLeftUV(Manager manager, Anchor anchor, Vector2Int position, Texture texture)
        {
            Vector2Int topLeft = Vector2Int.zero;

            switch (anchor)
            {
                case Anchor.TopLeft:
                    topLeft = new Vector2Int(position.x, position.y);
                    break;
                case Anchor.TopRight:
                    topLeft = new Vector2Int(manager.VideoTexture.width - texture.width - position.x, position.y);
                    break;
                case Anchor.BottomLeft:
                    topLeft = new Vector2Int(position.x, manager.VideoTexture.height - texture.height - position.y);
                    break;
                case Anchor.BottomRight:
                    topLeft = new Vector2Int(manager.VideoTexture.width - texture.width - position.x, manager.VideoTexture.height - texture.height - position.y);
                    break;
            }

            return topLeft;
        }
    }
}
