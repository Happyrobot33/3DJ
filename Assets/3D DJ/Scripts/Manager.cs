
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
