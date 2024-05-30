
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace com.happyrobot33.holographicreprojector
{
    //TODO: This whole system doesnt work right now because the shader doesnt fully work
    public class AttachExportBoxToHead : UdonSharpBehaviour
    {
        private Vector3 staticPosition;
        public Quaternion staticRotation;
        private bool OnHead = false;
        void Start()
        {
            //save the world position of the object we are attached to, but actually copy it instead of referencing it
            staticPosition = transform.position;
            staticRotation = transform.rotation;
        }

        public override void PostLateUpdate()
        {
            //if we are attached to the head, set our position to the head
            if (OnHead)
            {
                transform.position = Networking.LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
                transform.rotation = Networking.LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation;
            }
            else
            {
                transform.position = staticPosition;
                transform.rotation = staticRotation;
            }
        }

        public void AttachToHead()
        {
            //check if the local player is in VR. if not, dont let them do this
            if (!Networking.LocalPlayer.IsUserInVR())
            {
                return;
            }
            //toggle the attachment to the head
            OnHead = !OnHead;
        }
    }
}
