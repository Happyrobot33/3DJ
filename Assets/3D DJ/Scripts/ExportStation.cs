using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace com.happyrobot33.holographicreprojector
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ExportStation : UdonSharpBehaviour
    {
        public Camera cam;
        public Transform playerFollowPosition;
        private bool inStation = false;

        public override void Interact()
        {
            VRCStation station = GetComponent<VRCStation>();
            station.UseStation(Networking.LocalPlayer);
        }

        public override void OnStationEntered(VRCPlayerApi player)
        {
            //only run if local player
            if (!player.isLocal)
                return;

            inStation = true;
            //enable the camera
            cam.enabled = true;
        }

        void Update()
        {
            if (inStation)
            {
                //constantly move ourselves to the recorder
                transform.position = playerFollowPosition.position;
            }
        }

        public override void OnStationExited(VRCPlayerApi player)
        {
            //only run if local player
            if (!player.isLocal)
                return;

            inStation = false;
            //disable the camera
            cam.enabled = false;

            //get the station
            VRCStation station = GetComponent<VRCStation>();
            transform.position = station.stationExitPlayerLocation.position;
        }
    }
}
