
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class RigidbodySleepLock : UdonSharpBehaviour
{
    public float checkRate = 5.0f;
    private Rigidbody rb;
    private Vector3 savedPosition;
    private Quaternion savedRotation;
    const float threshold = 0.1f; //needs to be this close to actually check for sleeping, as otherwise holding it will also count as the rigidbody sleeping
    void Start()
    {
        //save default rotation
        savedPosition = transform.localPosition;
        savedRotation = transform.localRotation;

        rb = GetComponent<Rigidbody>();
        SendCustomEventDelayedSeconds(nameof(_Coroutine), checkRate);
    }

    public void _Coroutine()
    {
        //check if the rigidbody is sleeping
        if (
            Networking.IsOwner(Networking.LocalPlayer, gameObject)
            && rb.IsSleeping()
            && Vector3.Distance(transform.localPosition, savedPosition) < threshold
        )
        {
            //lock the object to the saved position
            transform.localPosition = savedPosition;
            transform.localRotation = savedRotation;
        }

        SendCustomEventDelayedSeconds(nameof(_Coroutine), checkRate);
    }
}
