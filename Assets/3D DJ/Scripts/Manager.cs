
using System;
using System.Diagnostics;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public enum Mode
{
    Record,
    Playback
}

public class Manager : UdonSharpBehaviour
{
    public GameObject Recorder;
    public Material DataInput;
    public Material SourceSwitcher;
    public Vector2Int UVPositionTopLeft;
    //TODO: Should make these render texture type but I want to do some testing so they arent for now
    public Texture VideoTexture;
    public RenderTexture RecordTexture;
    public float scaleOffset = 0;

    private VRCPlayerApi player;
    private Camera[] Cameras;
    private Mode mode = Mode.Playback;
    void Start()
    {
        player = Networking.LocalPlayer;

        //get all the children cameras of the recorder
        Cameras = Recorder.GetComponentsInChildren<Camera>();

        SwitchToPlayback();
    }

    public override void PostLateUpdate()
    {
        if (mode == Mode.Record)
        {
            //get the player position
            Vector3 playerPos = player.GetPosition();

            //get the players head
            Vector3 headPos = player.GetBonePosition(HumanBodyBones.Head);

            //determine the midpoint between the player and the head
            Vector3 recorderPos = (playerPos + headPos) / 2;

            //move the recorder to the player position
            Recorder.transform.position = recorderPos;

            //set the rotation to the player rotation + 45 on the y axis
            Recorder.transform.rotation = Quaternion.Euler(0, player.GetRotation().eulerAngles.y + 45, 0);

            //determine the scale by getting the distance between the player and the head on the y axis
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

    public void SwitchToPlayback()
    {
        SetupSource(VideoTexture, UVPositionTopLeft, new Vector2Int(RecordTexture.width, RecordTexture.height));
        //disable the recorder
        Recorder.SetActive(false);
        mode = Mode.Playback;
    }

    public void SwitchToRecord()
    {
        Recorder.SetActive(true);
        SetupSource(RecordTexture, Vector2Int.zero, new Vector2Int(RecordTexture.width, RecordTexture.height));
        mode = Mode.Record;
    }

    private void SetupSource(Texture source, Vector2Int topLeft, Vector2Int size)
    {
        //setup the source switcher to be based on the uv position info
        Vector2 center = new Vector2(topLeft.x + size.x / 2, topLeft.y + size.y / 2);
        SourceSwitcher.SetVector("_Center", center);
        SourceSwitcher.SetVector("_Size", new Vector2(size.x, size.y));
        SourceSwitcher.SetTexture("_RT", source);
    }
}
