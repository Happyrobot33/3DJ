using System;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;
using VRC.SDK3.Components;

namespace com.happyrobot33.holographicreprojector
{
    using Texel;
    using TMPro;
    using UnityEditor;
    using UnityEngine.Rendering.PostProcessing;
    using VRC.SDK3.Data;

    public class DeveloperOnlyAttribute : PropertyAttribute { }
#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomPropertyDrawer(typeof(DeveloperOnlyAttribute))]
    public class DeveloperOnly : PropertyDrawer
    {
        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            //get the manager developer only flag
            Manager manager = GameObject.Find(Manager.MANAGERNAME).GetComponent<Manager>();
            if (!manager.DeveloperMode)
            {
                return 0;
            }
            return EditorGUI.GetPropertyHeight(property, label, true);
        }

        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            //get the manager developer only flag
            Manager manager = GameObject.Find(Manager.MANAGERNAME).GetComponent<Manager>();
            if (!manager.DeveloperMode)
            {
                return;
            }
            EditorGUI.PropertyField(position, property, label, true);
        }
    }
#endif

    public enum Source
    {
        Record,
        Playback
    }

    public enum TextureAnchor
    {
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    public enum AreaType
    {
        Color,
        Depth,
        Data,
        None
    }

    public enum ManagerCallback
    {
        recordedPlayerChanged,
        globalPlaybackChanged,
        localPlaybackChanged,
        blackoutChanged,
        playerHeadOffsetChanged,
        sourceChanged,
        accessControlChanged
    }

    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class Manager : CallbackUdonSharpBehaviour<ManagerCallback>
    {
        public const string MANAGERNAME = "3DJManager";

        [DeveloperOnly]
        public GameObject Recorder;

        [DeveloperOnly]
        public Material DataInput;

        [DeveloperOnly]
        public GameObject mainPlaybackCube;

        /// <summary>
        /// This is stupid but this is the equivalent of local playback control, but it needs to be a object due to ownership issues
        /// </summary>
        [DeveloperOnly]
        public GameObject localPlaybackParentObject;
        public RenderTexture VideoTexture;
        public AccessControl accessControl;

        [DeveloperOnly]
        public string worldID;

        [Header("Color:")]
        [DeveloperOnly]
        public RenderTexture ColorTexture;
        public TextureAnchor ColorAnchor;
        public Vector2Int ColorTextureSize;
        public Vector2Int ColorUVPosition;

        [DeveloperOnly]
        public Material ColorExtractMaterial;

        [DeveloperOnly]
        public CustomRenderTexture ColorExtractTexture;
        [DeveloperOnly]
        public CustomRenderTexture UpscaledColorTexture;

        [Header("Depth:")]
        [DeveloperOnly]
        public RenderTexture DepthTexture;
        public TextureAnchor DepthAnchor;
        public Vector2Int DepthTextureSize;
        public Vector2Int DepthUVPosition;

        [DeveloperOnly]
        public Material DepthExtractMaterial;

        [DeveloperOnly]
        public CustomRenderTexture DepthExtractTexture;

        [Header("Data:")]
        [DeveloperOnly]
        public RenderTexture DataTexture;
        public TextureAnchor DataAnchor;
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

        private VRCPlayerApi _playerToRecord;
        public VRCPlayerApi playerToRecord
        {
            get { return _playerToRecord; }
            set
            {
                //if its the same value do nothing
                if (value == _playerToRecord)
                {
                    return;
                }
                _playerToRecord = value;
                playerToRecordName = value.displayName;
                //run the callback
                RunCallback(ManagerCallback.recordedPlayerChanged);
            }
        }

        [UdonSynced]
        [FieldChangeCallback(nameof(playerToRecordName))]
        private string _playerToRecordName;
        public string playerToRecordName
        {
            get { return _playerToRecordName; }
            set
            {
                //if its the same value do nothing
                if (value == _playerToRecordName)
                {
                    return;
                }
                _playerToRecordName = value;
                //we need to find the player by their name
                VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
                VRCPlayerApi.GetPlayers(players);
                foreach (VRCPlayerApi player in players)
                {
                    if (player.displayName == value)
                    {
                        playerToRecord = player;
                        break;
                    }
                }
                //check if we own the object
                if (Networking.GetOwner(gameObject) == Networking.LocalPlayer)
                {
                    //Debug.Log($"Requesting serialization for {nameof(playerToRecordName)}");
                    RequestSerialization();
                }
            }
        }
        private Camera[] Cameras;
        private Source _mode = Source.Playback;
        public Source mode
        {
            get { return _mode; }
            set
            {
                _mode = value;
                RunCallback(ManagerCallback.sourceChanged);
            }
        }

        [UdonSynced]
        [FieldChangeCallback(nameof(playerHeadOffset))]
        private float _playerHeadOffset = 0.0f;
        public float playerHeadOffset
        {
            get { return _playerHeadOffset; }
            set
            {
                //check if the value has changed
                if (value == _playerHeadOffset)
                {
                    return;
                }

                _playerHeadOffset = value;
                RunCallback(ManagerCallback.playerHeadOffsetChanged);

                //check if we own the object
                if (Networking.GetOwner(gameObject) == Networking.LocalPlayer)
                {
                    //Debug.Log($"Requesting serialization for {nameof(playerToRecordName)}");
                    RequestSerialization();
                }
            }
        }

        /// <summary>
        /// If the playback is visible globally across the instance. Used to disable playback if the instance is the one recording
        /// </summary>
        [UdonSynced]
        [FieldChangeCallback(nameof(globalPlayback))]
        private bool _globalPlayback = true;
        public bool globalPlayback
        {
            get { return _globalPlayback; }
            set
            {
                //check if the value has changed
                if (value == _globalPlayback)
                {
                    return;
                }

                _globalPlayback = value;
                RunCallback(ManagerCallback.globalPlaybackChanged);
                //check if we own the object
                if (Networking.GetOwner(gameObject) == Networking.LocalPlayer)
                {
                    //Debug.Log($"Requesting serialization for {nameof(playerToRecordName)}");
                    RequestSerialization();
                }
            }
        }

        [UdonSynced]
        [FieldChangeCallback(nameof(blackout))]
        private bool _blackout = false;
        public bool blackout
        {
            get { return _blackout; }
            set
            {
                //check if the value has changed
                if (value == _blackout)
                {
                    return;
                }

                _blackout = value;
                RunCallback(ManagerCallback.blackoutChanged);
                //check if we own the object
                if (Networking.GetOwner(gameObject) == Networking.LocalPlayer)
                {
                    //Debug.Log($"Requesting serialization for {nameof(playerToRecordName)}");
                    RequestSerialization();
                }
            }
        }

        public bool localPlayback
        {
            get { return localPlaybackParentObject.activeSelf; }
            set
            {
                localPlaybackParentObject.SetActive(value);
                RunCallback(ManagerCallback.localPlaybackChanged);
            }
        }

        #region Auto Player Setup System
        //this is so that when a designated player joins, it will automatically set the mode to record and place them into the station
        [DeveloperOnly]
        [Header("Auto Player Setup System")]
        public VRC.SDK3.Components.VRCStation station;
        public string[] designatedPlayerNames;
        /// <summary>
        /// If the system should automatically setup the specific player when they join
        /// </summary>
        public bool autoPlayerSetupEnabled = false;
        /// <summary>
        /// If the system should automatically disable/enable global playback when the designated player joins/leaves
        /// </summary>
        public bool allowAutoGlobalPlaybackSwitch = false;
        #endregion

        #region Inspector Variables
        [Header("Preview Textures")]
        public Texture PreviewLayoutTexture;

        [DeveloperOnly]
        public bool DeveloperMode;

        [DeveloperOnly]
        public AreaType CurrentlyEditingArea;
        #endregion
        void Start()
        {
            //self tag
            gameObject.name = MANAGERNAME;

            //make our playback cube always at 0,0,0
            mainPlaybackCube.transform.position = Vector3.zero;

            playerToRecord = Networking.LocalPlayer;

            //get all the children cameras of the recorder
            Cameras = Recorder.GetComponentsInChildren<Camera>();

            SetSource(Source.Playback);

            //make sure the recorder is off
            Recorder.SetActive(false);

            _EnforceCameraAspectRatio();
            _SetupGlobalTextures();
        }

        public void _SetupGlobalTextures()
        {
            //initialize the global textures
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Color"),
                ColorExtractTexture
            );
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Color_Upscaled"),
                UpscaledColorTexture
            );
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Depth"),
                DepthExtractTexture
            );
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Data"),
                DataExtractTexture
            );
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Raw_Input"),
                VideoTexture
            );
            VRCShader.SetGlobalTexture(
                VRCShader.PropertyToID("_Udon_3DJ_Raw_Output"),
                RecordTexture
            );

            //convert to float array
            float[] worldIDArray = new float[32];
            //world IDs are only ever made up of lowercase letters and numbers
            //we want to convert these to a simple discrete ammount of values
            for (int i = 0; i < worldID.Length; i++)
            {
                //worldIDArray[i] = worldID[i];
                if (worldID[i] >= '0' && worldID[i] <= '9')
                {
                    worldIDArray[i] = worldID[i] - '0';
                }
                else
                {
                    worldIDArray[i] = worldID[i] - 'a' + 10;
                }

                //remap to be 0 to 1
                const int totalPossibleValues = '9' - '0' + 'z' - 'a' + 1;
                worldIDArray[i] /= totalPossibleValues;
            }
            VRCShader.SetGlobalFloatArray(VRCShader.PropertyToID("_Udon_WorldID"), worldIDArray);
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
            centerBound = new Vector3(
                (maxBound.x + minBound.x) / 2,
                (maxBound.y + minBound.y) / 2,
                (maxBound.z + minBound.z) / 2
            );
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
            bonePos = RotatePointAroundPivot(
                bonePos,
                playerPos,
                new Vector3(0, -playerRot.y - 45, 0)
            );

            return bonePos;
        }

        private float remapToScaledPlayer(float input)
        {
            //we are assuming a normal player is 1 meter tall for all values inputted into here
            //so we need to scale the input to the player size

            float percentage = playerToRecord.GetAvatarEyeHeightAsMeters();

            return input * percentage;
        }

        [HideInInspector]
        public bool playerHasAccess = false;
        void Update()
        {
            //check if the player has access control
            if (accessControl != null)
            {
                bool prevAccess = playerHasAccess;
                playerHasAccess = accessControl._HasAccess(Networking.LocalPlayer);
                if (prevAccess != playerHasAccess)
                {
                    RunCallback(ManagerCallback.accessControlChanged);
                }
            }

            //playback cube visibility
            mainPlaybackCube.SetActive(globalPlayback);
            _ConfigureShaderForPlayback();

            if (mode == Source.Record)
            {
                //check if the player is valid, if not do nothing
                if (playerToRecord == null || !Utilities.IsValid(playerToRecord))
                {
                    return;
                }

                //get the player position
                Vector3 playerPos = playerToRecord.GetPosition();
                Vector3[] points = _GeneratePositionArray();

                //get the min and max bounds
                //TODO: Expose radius as a slider
                FromPoints(points, remapToScaledPlayer(0.125f));

                //move the recorder to the player position rotated around the player
                Vector3 recordCenter = RotatePointAroundPivot(
                    centerBound,
                    playerPos,
                    new Vector3(0, playerToRecord.GetRotation().eulerAngles.y + 45, 0)
                );
                Recorder.transform.position = recordCenter;

                //set the rotation to the player rotation + 45 on the y axis
                Recorder.transform.rotation = Quaternion.Euler(
                    0,
                    playerToRecord.GetRotation().eulerAngles.y + 45,
                    0
                );

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

        public void _ConfigureShaderForPlayback()
        {
            //set global boolean for shaders for if playback is active
            bool playbackActive =
                globalPlayback
                && localPlayback /*  && mode == Source.Playback */
            ;
            VRCShader.SetGlobalFloat(
                VRCShader.PropertyToID("_Udon_3DJ_PlaybackActive"),
                playbackActive ? 1 : 0
            );

            VRCShader.SetGlobalFloat(
                VRCShader.PropertyToID("_Udon_3DJ_Blackout"),
                blackout ? 1 : 0
            );
        }

        private Vector3[] _GeneratePositionArray()
        {
            //encapsulate some positions
            //build up a list of points
            DataList points = new DataList();
            points.Add(
                new DataToken(
                    rotationNullifiedBonePosition(HumanBodyBones.Head, playerToRecord)
                        + new Vector3(0, remapToScaledPlayer(playerHeadOffset), 0)
                )
            );

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

                points.Add(
                    new DataToken(rotationNullifiedBonePosition((HumanBodyBones)i, playerToRecord))
                );
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

        public void SetSource(Source source)
        {
            mode = source;
            switch (source)
            {
                case Source.Playback:
                    SetupRenderTextureExtractionZones(VideoTexture);
                    Recorder.SetActive(false);
                    break;
                case Source.Record:
                    SetupRenderTextureExtractionZones(RecordTexture);
                    Recorder.SetActive(true);
                    break;
            }
        }

        public void _ToggleGlobalPlayback()
        {
            if (!accessControl._HasAccess(Networking.LocalPlayer))
            {
                return;
            }

            globalPlayback = !globalPlayback;
        }

        public void _ToggleBlackout()
        {
            if (!accessControl._HasAccess(Networking.LocalPlayer))
            {
                return;
            }

            blackout = !blackout;
        }

        public void _ToggleLocalPlayback()
        {
            localPlayback = !localPlayback;
        }

        public void SetupRenderTextureExtractionZones(Texture source = null)
        {
            SetupSource(
                ColorExtractMaterial,
                CalculateTopLeftUV(this, ColorAnchor, ColorUVPosition, ColorTexture),
                new Vector2Int(ColorTexture.width, ColorTexture.height),
                source
            );
            SetupSource(
                DepthExtractMaterial,
                CalculateTopLeftUV(this, DepthAnchor, DepthUVPosition, DepthTexture),
                new Vector2Int(DepthTexture.width, DepthTexture.height),
                source
            );
            SetupSource(
                DataExtractMaterial,
                CalculateTopLeftUV(this, DataAnchor, DataUVPosition, DataTexture),
                new Vector2Int(DataTexture.width, DataTexture.height),
                source
            );
        }

        public void _EnforceCameraAspectRatio()
        {
            //ensure all the cameras under us are locked to 1:1 aspect ratio, as otherwise they will try to automatically update and fuck things up
            Camera[] cams = Recorder.GetComponentsInChildren<Camera>();
            foreach (Camera cam in cams)
            {
                cam.aspect = 1;
            }
        }

        public void ChangePlayer(VRCPlayerApi player)
        {
            //only allow if the local player is allowed to
            if (!accessControl._HasAccess(Networking.LocalPlayer))
            {
                return;
            }

            //reset the player offset height
            playerHeadOffset = 0f;
            playerToRecord = player;
        }

        public void SetPlayerHeadOffset(float offset)
        {
            if (!accessControl._HasAccess(Networking.LocalPlayer))
            {
                return;
            }

            playerHeadOffset = offset;
        }

        public bool _TakeOwnership()
        {
            if (!accessControl._HasAccess(Networking.LocalPlayer))
            {
                return false;
            }

            //check if already owner, to avoid log spam
            if (Networking.GetOwner(gameObject) == Networking.LocalPlayer)
            {
                return true;
            }

            Networking.SetOwner(Networking.LocalPlayer, gameObject);
            return true;
        }

        public bool _HasAccess(VRCPlayerApi player)
        {
            return accessControl._HasAccess(player);
        }

        public bool IsDesignatedPlayer(VRCPlayerApi player)
        {
            foreach (string name in designatedPlayerNames)
            {
                if (player.displayName == name)
                {
                    return true;
                }
            }

            return false;
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (player == playerToRecord)
            {
                //set to local player
                ChangePlayer(Networking.LocalPlayer);
            }

            //if the player that left was the designated player
            if (IsDesignatedPlayer(player))
            {
                if (allowAutoGlobalPlaybackSwitch)
                {
                    //re-enable it since the player left
                    globalPlayback = true;
                }
            }
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            //if the player that joined was the designated player
            if (IsDesignatedPlayer(player))
            {
                if (allowAutoGlobalPlaybackSwitch)
                {
                    //disable it since the player joined
                    globalPlayback = false;
                }

                if (autoPlayerSetupEnabled)
                {
                    //force the user into the station. Can only do this for the local player
                    if (Networking.LocalPlayer == player)
                    {
                        //station.UseStation(player);
                        SendCustomEventDelayedSeconds(nameof(_DelayedStationUse), 1);

                        //switch us into record mode
                        SetSource(Source.Record);
                    }
                }
            }
        }

        public void _DelayedStationUse()
        {
            station.UseStation(Networking.LocalPlayer);
        }

        private void SetupSource(
            Material extractor,
            Vector2Int topLeft,
            Vector2Int size,
            Texture source = null
        )
        {
            //setup the source switcher to be based on the uv position info
            Vector2 center = new Vector2(
                topLeft.x + (float)size.x / 2,
                topLeft.y + (float)size.y / 2
            );
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
        public static Vector2Int CalculateTopLeftUV(
            Manager manager,
            TextureAnchor anchor,
            Vector2Int position,
            Texture texture
        )
        {
            Vector2Int topLeft = Vector2Int.zero;

            switch (anchor)
            {
                case TextureAnchor.TopLeft:
                    topLeft = new Vector2Int(position.x, position.y);
                    break;
                case TextureAnchor.TopRight:
                    topLeft = new Vector2Int(
                        manager.VideoTexture.width - texture.width - position.x,
                        position.y
                    );
                    break;
                case TextureAnchor.BottomLeft:
                    topLeft = new Vector2Int(
                        position.x,
                        manager.VideoTexture.height - texture.height - position.y
                    );
                    break;
                case TextureAnchor.BottomRight:
                    topLeft = new Vector2Int(
                        manager.VideoTexture.width - texture.width - position.x,
                        manager.VideoTexture.height - texture.height - position.y
                    );
                    break;
            }

            return topLeft;
        }
    }
}
