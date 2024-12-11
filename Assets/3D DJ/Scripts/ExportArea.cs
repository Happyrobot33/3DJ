using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace com.happyrobot33.holographicreprojector
{
    public class ExportArea : UdonSharpBehaviour
    {
        public Camera cam;

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (player.isLocal)
            {
                cam.enabled = true;
            }
        }

        public override void OnPlayerTriggerExit(VRCPlayerApi player)
        {
            if (player.isLocal)
            {
                cam.enabled = false;
            }
        }
    }
}
