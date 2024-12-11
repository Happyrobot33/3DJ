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
        public TMP_Dropdown dropdown;
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
            PopulateDropdown();
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            //we delay 1 frame here so the player list is actually correct
            SendCustomEventDelayedFrames(nameof(PopulateDropdown), 1);
        }

        private void PopulateDropdown()
        {
            //update the dropdown
            dropdown.ClearOptions();
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);
            string[] options = new string[players.Length];
            for (int i = 0; i < players.Length; i++)
            {
                options[i] = players[i].displayName;
            }
            dropdown.AddOptions(options);

            dropdown.SetValueWithoutNotify(0);
        }

        public void DelayedSearch()
        {
            manager = GameObject.Find(Manager.MANAGERNAME).GetComponent<Manager>();
        }

        public void SliderUpdated()
        {
            manager.playerHeadOffset = slider.value;
        }

        public void PlayerDropdownUpdated()
        {
            //find the player with that name
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);

            manager.ChangePlayer(players[dropdown.value]);
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
        }
    }
}
