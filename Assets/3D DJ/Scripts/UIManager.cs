using TMPro;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;
using static TMPro.TMP_Dropdown;
using VRC.SDK3.Components;

namespace com.happyrobot33.holographicreprojector
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class UIManager : UdonSharpBehaviour
    {
        private Manager manager;
        public Slider slider;
        public TMP_Dropdown playerDropdown;
        public TMP_Dropdown sourceDropdown;

        void Start()
        {
            SendCustomEventDelayedFrames(nameof(DelayedSearch), 1);

            //setup source dropdown
            sourceDropdown.ClearOptions();
            string[] options = new string[] { "Record", "Playback" };
            sourceDropdown.AddOptions(options);
            sourceDropdown.SetValueWithoutNotify(1);
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            PopulatePlayerDropdown();
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            //we delay 1 frame here so the player list is actually correct
            SendCustomEventDelayedFrames(nameof(PopulatePlayerDropdown), 1);
        }

        private void PopulatePlayerDropdown()
        {
            //update the dropdown
            playerDropdown.ClearOptions();
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);
            string[] options = new string[players.Length];
            for (int i = 0; i < players.Length; i++)
            {
                options[i] = players[i].displayName;
            }
            playerDropdown.AddOptions(options);

            playerDropdown.SetValueWithoutNotify(0);
        }

        public void DelayedSearch()
        {
            manager = GameObject.Find(Manager.MANAGERNAME).GetComponent<Manager>();
        }

        public void SliderUpdated()
        {
            manager.SetPlayerHeadOffset(slider.value);
            TakeOwnership();
        }

        public void TakeOwnership()
        {
            manager._TakeOwnership();
        }

        public void ToggleGlobalPlayback()
        {
            manager._ToggleGlobalPlayback();
            TakeOwnership();
        }

        public void ToggleLocalPlayback()
        {
            manager._ToggleLocalPlayback();
        }

        public void PlayerDropdownUpdated()
        {
            //find the player with that name
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);

            manager.ChangePlayer(players[playerDropdown.value]);
            TakeOwnership();
        }

        public void SourceUpdated()
        {
            switch (sourceDropdown.value)
            {
                case 0:
                    manager.SetSource(Source.Record);
                    break;
                case 1:
                    manager.SetSource(Source.Playback);
                    break;
            }
            TakeOwnership();
        }
    }
}
