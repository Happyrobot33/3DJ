
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
    using UnityEngine.Rendering.PostProcessing;
    using VRC.SDK3.Data;


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
        Data,
        None
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
        public Anchor ColorAnchor;
        public Vector2Int ColorTextureSize;
        public Vector2Int ColorUVPosition;
        [DeveloperOnly]
        public Material ColorExtractMaterial;
        [DeveloperOnly]
        public CustomRenderTexture ColorExtractTexture;

        [Header("Depth:")]
        [DeveloperOnly]
        public RenderTexture DepthTexture;
        public Anchor DepthAnchor;
        public Vector2Int DepthTextureSize;
        public Vector2Int DepthUVPosition;
        [DeveloperOnly]
        public Material DepthExtractMaterial;
        [DeveloperOnly]
        public CustomRenderTexture DepthExtractTexture;

        [Header("Data:")]
        [DeveloperOnly]
        public RenderTexture DataTexture;
        public Anchor DataAnchor;
        public Vector2Int DataTextureSize;
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

            EnforceCameraAspectRatio();
            SetupGlobalTextures();
        }

        public void SetupGlobalTextures()
        {
            //initialize the global textures
            VRCShader.SetGlobalTexture(VRCShader.PropertyToID("_Udon_3DJ_Color"), ColorExtractTexture);
            VRCShader.SetGlobalTexture(VRCShader.PropertyToID("_Udon_3DJ_Depth"), DepthExtractTexture);
            VRCShader.SetGlobalTexture(VRCShader.PropertyToID("_Udon_3DJ_Data"), DataExtractTexture);
        }


        public Vector3 RotatePointAroundPivot(Vector3 point, Vector3 pivot, Vector3 angles)
        {
            return Quaternion.Euler(angles) * (point - pivot) + pivot;
        }

        private void FromPoints(Vector3[] points, float radius)
        {
            float minX = float.PositiveInfinity;
            float maxX = float.NegativeInfinity;
            float minY = float.PositiveInfinity;
            float maxY = float.NegativeInfinity;
            float minZ = float.PositiveInfinity;
            float maxZ = float.NegativeInfinity;
            for (int i = 0; i < points.Length; i++)
            {
                Vector3 vertex = points[i];

                // Check for maximum
                if (vertex.x + radius > maxX)
                {
                    maxX = vertex.x + radius;
                }
                if (vertex.y + radius > maxY)
                {
                    maxY = vertex.y + radius;
                }
                if (vertex.z + radius > maxZ)
                {
                    maxZ = vertex.z + radius;
                }
                // Check for Minimum
                if (vertex.x - radius < minX)
                {
                    minX = vertex.x - radius;
                }
                if (vertex.y - radius < minY)
                {
                    minY = vertex.y - radius;
                }
                if (vertex.z - radius < minZ)
                {
                    minZ = vertex.z - radius;
                }
            }
            minBound = new Vector3(minX, minY, minZ);
            maxBound = new Vector3(maxX, maxY, maxZ);


            //since we can only render a cube shape, make all side lengths equal to the longest side, while keeping the center the same
            float longestSide = Math.Max(maxX - minX, Math.Max(maxY - minY, maxZ - minZ));
            centerBound = new Vector3((maxBound.x + minBound.x) / 2, (maxBound.y + minBound.y) / 2, (maxBound.z + minBound.z) / 2);
            minBound = centerBound - new Vector3(longestSide / 2, longestSide / 2, longestSide / 2);
            maxBound = centerBound + new Vector3(longestSide / 2, longestSide / 2, longestSide / 2);
        }

        Vector3 minBound = new Vector3();
        Vector3 maxBound = new Vector3();
        Vector3 centerBound = new Vector3();

        private Vector3 rotationNullifiedBonePosition(HumanBodyBones bone, VRCPlayerApi player)
        {
            //we want to undo the rotation of the player, so we can get the bone position in world space as if the player is always facing forward
            Vector3 bonePos = player.GetBonePosition(bone);
            Vector3 playerPos = player.GetPosition();
            Vector3 playerRot = player.GetRotation().eulerAngles;

            //undo the rotation of the player
            bonePos = RotatePointAroundPivot(bonePos, playerPos, new Vector3(0, -playerRot.y - 45, 0));

            return bonePos;
        }

        private float remapToScaledPlayer(float input)
        {
            //we are assuming a normal player is 1 meter tall for all values inputted into here
            //so we need to scale the input to the player size

            float percentage = playerToRecord.GetAvatarEyeHeightAsMeters();

            return input * percentage;
        }
        void Update()
        {
            if (mode == Mode.Record)
            {
                //get the player position
                Vector3 playerPos = playerToRecord.GetPosition();
                Vector3[] points = GeneratePositionArray();

                //get the min and max bounds
                //TODO: Expose radius as a slider
                FromPoints(points, remapToScaledPlayer(0.125f));

                //move the recorder to the player position rotated around the player
                Vector3 recordCenter = RotatePointAroundPivot(centerBound, playerPos, new Vector3(0, playerToRecord.GetRotation().eulerAngles.y + 45, 0));
                Recorder.transform.position = recordCenter;

                //set the rotation to the player rotation + 45 on the y axis
                Recorder.transform.rotation = Quaternion.Euler(0, playerToRecord.GetRotation().eulerAngles.y + 45, 0);

                //determine the scale by getting the distance between the player and the head on the y axis
                float scale = (maxBound.y - minBound.y) / 2;

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
                DataInput.SetVector("_Position", recordCenter);
                DataInput.SetFloat("_Scale", scale * 2);
                DataInput.SetFloat("_Rotation", playerToRecord.GetRotation().eulerAngles.y + 45);
            }
        }

        private Vector3[] GeneratePositionArray()
        {
            //encapsulate some positions
            //build up a list of points
            DataList points = new DataList();
            points.Add(new DataToken(rotationNullifiedBonePosition(HumanBodyBones.Head, playerToRecord) + new Vector3(0, remapToScaledPlayer(OffsetSlider.value), 0)));
            
            for (int i = 0; i < (int)HumanBodyBones.LastBone; i++)
            {
                //skip the head
                if (i == (int)HumanBodyBones.Head)
                {
                    continue;
                }

                //check to make sure the position isnt 0,0,0
                if (playerToRecord.GetBonePosition((HumanBodyBones)i) == Vector3.zero)
                {
                    continue;
                }

                points.Add(new DataToken(rotationNullifiedBonePosition((HumanBodyBones)i, playerToRecord)));
            }
            
            //convert the list to an array
            DataToken[] tokens = points.ToArray();
            Vector3[] positions = new Vector3[tokens.Length];
            for (int i = 0; i < tokens.Length; i++)
            {
                positions[i] = (Vector3)tokens[i].Reference;
            }

            return positions;
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

        public void SetupRenderTextureExtractionZones(Texture source = null)
        {
            SetupSource(ColorExtractMaterial, CalculateTopLeftUV(this, ColorAnchor, ColorUVPosition, ColorTexture), new Vector2Int(ColorTexture.width, ColorTexture.height), source);
            SetupSource(DepthExtractMaterial, CalculateTopLeftUV(this, DepthAnchor, DepthUVPosition, DepthTexture), new Vector2Int(DepthTexture.width, DepthTexture.height), source);
            SetupSource(DataExtractMaterial, CalculateTopLeftUV(this, DataAnchor, DataUVPosition, DataTexture), new Vector2Int(DataTexture.width, DataTexture.height), source);

        }

        public void SwitchSourceToRecord()
        {
            //Recorder.SetActive(true);
            SetupRenderTextureExtractionZones(RecordTexture);
        }

        public void EnforceCameraAspectRatio()
        {
            //ensure all the cameras under us are locked to 1:1 aspect ratio, as otherwise they will try to automatically update and fuck things up
            Camera[] cams = Recorder.GetComponentsInChildren<Camera>();
            foreach (Camera cam in cams)
            {
                cam.aspect = 1;
            }
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


        private void SetupSource(Material extractor, Vector2Int topLeft, Vector2Int size, Texture source = null)
        {
            //setup the source switcher to be based on the uv position info
            Vector2 center = new Vector2(topLeft.x + (float)size.x / 2, topLeft.y + (float)size.y / 2);
            extractor.SetVector("_Center", center);
            extractor.SetVector("_Size", new Vector2(size.x, size.y));
            if (source != null)
            {
                extractor.SetTexture("_RT", source);
            }
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
