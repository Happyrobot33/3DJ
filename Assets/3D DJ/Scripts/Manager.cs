
using System;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace com.happyrobot33.holographicreprojector
{

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

            #region Video region management
            //calculate the UV size
            Vector2Int UVSize = new Vector2Int(manager.RecordTexture.width, manager.RecordTexture.height);

            //determine the aspect ratio of the video texture
            float videoPlayerAspect = manager.VideoTexture.width / (float)manager.VideoTexture.height;

            //display a box with the aspect ratio
            Rect videoRect = GUILayoutUtility.GetAspectRect(videoPlayerAspect);

            GUIStyle imageStyle = new GUIStyle("box");
            //make content have 0 padding
            imageStyle.padding = new RectOffset(0, 0, 0, 0);

            //show a box in it, with the texture as the content
            GUI.Box(videoRect, manager.PreviewLayoutTexture, imageStyle);

            //display another box inside the first box based on the UVPositionTopLeft and UVPositionSize
            /* Rect recordRect = new Rect(videoRect.x + videoRect.width * manager.UVPosition.x / manager.VideoTexture.width,
                videoRect.y + videoRect.height * manager.UVPosition.y / manager.VideoTexture.height,
                videoRect.width * UVSize.x / manager.VideoTexture.width,
                videoRect.height * UVSize.y / manager.VideoTexture.height); */

            Vector2Int topLeft = Manager.CalculateTopLeftUV(manager);
            Rect recordRect = new Rect(videoRect.x + videoRect.width * topLeft.x / manager.VideoTexture.width,
                videoRect.y + videoRect.height * topLeft.y / manager.VideoTexture.height,
                videoRect.width * UVSize.x / manager.VideoTexture.width,
                videoRect.height * UVSize.y / manager.VideoTexture.height);

            //get the record rect in terms of the video textures pixels
            Rect pixelBasedRecordRect = new Rect(topLeft.x, topLeft.y, UVSize.x, UVSize.y);

            //show a box in it, with a outline and text in it
            GUI.Box(recordRect, manager.PreviewSystemTexture, imageStyle);

            int handleThickness = 5;
            GUIStyle handleStyle = new GUIStyle("box");
            handleStyle.normal.background = EditorGUIUtility.whiteTexture;

            //draw a dot at the corners
            Handles.DrawSolidDisc(new Vector3(recordRect.xMin, recordRect.yMin, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(recordRect.xMax, recordRect.yMin, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(recordRect.xMin, recordRect.yMax, 0), Vector3.forward, handleThickness);
            Handles.DrawSolidDisc(new Vector3(recordRect.xMax, recordRect.yMax, 0), Vector3.forward, handleThickness);


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

            //display text on all 4 sides of the record box that shows its width and height
            Handles.Label(new Vector3(recordRect.center.x, recordRect.yMin, 0), UVSize.x.ToString(), labelStyle);
            Handles.Label(new Vector3(recordRect.xMin, recordRect.center.y, 0), UVSize.y.ToString(), labelStyle);
            Handles.Label(new Vector3(recordRect.center.x, recordRect.yMax, 0), UVSize.x.ToString(), labelStyle);
            Handles.Label(new Vector3(recordRect.xMax, recordRect.center.y, 0), UVSize.y.ToString(), labelStyle);

            //draw a line starting from the upper edge of the video vertically, but the record box horizontally, to the top left of the record box
            Rect topVerticalOffsetRect = DrawLine(new Vector2(recordRect.xMin, videoRect.yMin), new Vector2(recordRect.xMin, recordRect.yMin), handleThickness, handleStyle);
            //draw a line starting from the left edge of the video horizontally, but the record box vertically, to the top left of the record box
            Rect leftHorizontalOffsetRect = DrawLine(new Vector2(videoRect.xMin, recordRect.yMin), new Vector2(recordRect.xMin, recordRect.yMin), handleThickness, handleStyle);
            Rect rightHorizontalOffsetRect = DrawLine(new Vector2(videoRect.xMax, recordRect.yMax), new Vector2(recordRect.xMax, recordRect.yMax), handleThickness, handleStyle);
            Rect bottomVerticalOffsetRect = DrawLine(new Vector2(recordRect.xMax, videoRect.yMax), new Vector2(recordRect.xMax, recordRect.yMax), handleThickness, handleStyle);
            //display text boxes at the two offset lines
            if (pixelBasedRecordRect.yMin != 0) Handles.Label(new Vector3(topVerticalOffsetRect.center.x, topVerticalOffsetRect.center.y, 0), pixelBasedRecordRect.yMin.ToString(), labelStyle);
            if (pixelBasedRecordRect.xMin != 0) Handles.Label(new Vector3(leftHorizontalOffsetRect.center.x, leftHorizontalOffsetRect.center.y, 0), pixelBasedRecordRect.xMin.ToString(), labelStyle);
            if (pixelBasedRecordRect.xMax != manager.VideoTexture.width) Handles.Label(new Vector3(rightHorizontalOffsetRect.center.x, rightHorizontalOffsetRect.center.y, 0), pixelBasedRecordRect.xMax.ToString(), labelStyle);
            if (pixelBasedRecordRect.yMax != manager.VideoTexture.height) Handles.Label(new Vector3(bottomVerticalOffsetRect.center.x, bottomVerticalOffsetRect.center.y, 0), pixelBasedRecordRect.yMax.ToString(), labelStyle);
            #endregion

            #region Debug Information
            //calculate the cell size based on horizontal width / 3
            int cellSize = UVSize.x / 3;
            EditorGUILayout.LabelField(string.Format("Cell Size: {0}x{0}", cellSize));
            #endregion

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
            }
        }

        private Rect DrawLine(Vector2 start, Vector2 end, int thickness, GUIStyle style)
        {
            Vector2 delta = end - start;
            float angle = Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg;
            float length = delta.magnitude;

            Rect rect = new Rect(start.x, start.y - thickness / 2, length, thickness);

            GUIUtility.RotateAroundPivot(angle, start);
            GUI.Box(rect, GUIContent.none, style);
            GUIUtility.RotateAroundPivot(-angle, start);

            //return a rect that has opposite corners at the start and end
            return new Rect(Mathf.Min(start.x, end.x), Mathf.Min(start.y, end.y), Mathf.Abs(start.x - end.x), Mathf.Abs(start.y - end.y));
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

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class Manager : UdonSharpBehaviour
    {
        [DeveloperOnly]
        public GameObject Recorder;
        [DeveloperOnly]
        public Material DataInput;
        [DeveloperOnly]
        public Material SourceSwitcher;
        public Vector2Int UVPosition;
        public Anchor UVAnchor;

        /// <summary>
        /// The texture that the video player is creating
        /// </summary>
        public RenderTexture VideoTexture;

        /// <summary>
        /// The texture that the 3DJ system is creating
        /// </summary>
        public RenderTexture RecordTexture;
        [DeveloperOnly]
        public Slider OffsetSlider;

        private VRCPlayerApi player;
        private Camera[] Cameras;
        private Mode mode = Mode.Playback;

        #region Inspector Variables
        [Header("Preview Textures")]
        public Texture PreviewLayoutTexture;
        public Texture PreviewSystemTexture;
        [DeveloperOnly]
        public bool DeveloperMode;
        #endregion
        void Start()
        {
            player = Networking.LocalPlayer;

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
                Vector3 playerPos = player.GetPosition();

                //get the players head
                Vector3 headPos = player.GetBonePosition(HumanBodyBones.Head);

                //add the offset to the head position
                headPos.y += OffsetSlider.value;

                //determine the midpoint between the player and the head
                Vector3 recorderPos = (playerPos + headPos) / 2;

                //move the recorder to the player position
                Recorder.transform.position = recorderPos;

                //set the rotation to the player rotation + 45 on the y axis
                Recorder.transform.rotation = Quaternion.Euler(0, player.GetRotation().eulerAngles.y + 45, 0);

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
                DataInput.SetFloat("_Rotation", player.GetRotation().eulerAngles.y + 45);
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

        public void SwitchSourceToPlayback()
        {
            SetupSource(VideoTexture, CalculateTopLeftUV(this), new Vector2Int(RecordTexture.width, RecordTexture.height));
            //disable the recorder
            //Recorder.SetActive(false);
            //mode = Mode.Playback;
        }

        public void SwitchSourceToRecord()
        {
            //Recorder.SetActive(true);
            SetupSource(RecordTexture, Vector2Int.zero, new Vector2Int(RecordTexture.width, RecordTexture.height));
            //mode = Mode.Record;
        }

        public void CyclePlayer()
        {
            //get player list
            VRCPlayerApi[] players = VRCPlayerApi.GetPlayers(new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()]);

            //get the current player index
            int index = Array.IndexOf(players, player);

            //get the next player
            player = players[(index + 1) % players.Length];
        }

        private void SetupSource(Texture source, Vector2Int topLeft, Vector2Int size)
        {
            //setup the source switcher to be based on the uv position info
            Vector2 center = new Vector2(topLeft.x + size.x / 2, topLeft.y + size.y / 2);
            SourceSwitcher.SetVector("_Center", center);
            SourceSwitcher.SetVector("_Size", new Vector2(size.x, size.y));
            SourceSwitcher.SetTexture("_RT", source);
        }

        /// <summary>
        /// Calculate the top left UV position based on the anchor
        /// </summary>
        internal static Vector2Int CalculateTopLeftUV(Manager manager)
        {
            Vector2Int topLeft = Vector2Int.zero;

            switch (manager.UVAnchor)
            {
                case Anchor.TopLeft:
                    topLeft = new Vector2Int(manager.UVPosition.x, manager.UVPosition.y);
                    break;
                case Anchor.TopRight:
                    topLeft = new Vector2Int(manager.VideoTexture.width - manager.RecordTexture.width - manager.UVPosition.x, manager.UVPosition.y);
                    break;
                case Anchor.BottomLeft:
                    topLeft = new Vector2Int(manager.UVPosition.x, manager.VideoTexture.height - manager.RecordTexture.height - manager.UVPosition.y);
                    break;
                case Anchor.BottomRight:
                    topLeft = new Vector2Int(manager.VideoTexture.width - manager.RecordTexture.width - manager.UVPosition.x, manager.VideoTexture.height - manager.RecordTexture.height - manager.UVPosition.y);
                    break;
            }

            return topLeft;
        }
    }
}
