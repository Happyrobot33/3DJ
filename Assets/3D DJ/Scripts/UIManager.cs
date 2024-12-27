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

        public Button globalPlaybackButton;
        public Button localPlaybackButton;

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

        public void PopulatePlayerDropdown()
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

            //make sure manager is populated
            if (manager == null)
            {
                return;
            }

            if (manager.playerToRecord != null)
            {
                //set the value to the currently selected player
                foreach (VRCPlayerApi player in players)
                {
                    if (player == manager.playerToRecord)
                    {
                        playerDropdown.SetValueWithoutNotify(System.Array.IndexOf(players, player));
                        return;
                    }
                }
            }
            else
            {
                playerDropdown.SetValueWithoutNotify(0);
            }
        }

        public void DelayedSearch()
        {
            manager = GameObject.Find(Manager.MANAGERNAME).GetComponent<Manager>();

            //subscribe to events
            manager.AddCallback(
                ManagerCallback.recordedPlayerChanged,
                this,
                nameof(PopulatePlayerDropdown)
            );
            manager.AddCallback(
                ManagerCallback.playerHeadOffsetChanged,
                this,
                nameof(UpdateSlider)
            );
            manager.AddCallback(ManagerCallback.sourceChanged, this, nameof(UpdateSource));
            manager.AddCallback(
                ManagerCallback.globalPlaybackChanged,
                this,
                nameof(UpdateButtonColors)
            );
            manager.AddCallback(
                ManagerCallback.localPlaybackChanged,
                this,
                nameof(UpdateButtonColors)
            );

            UpdateButtonColors();

            manager.AddCallback(
                ManagerCallback.accessControlChanged,
                this,
                nameof(UpdateInteractibility)
            );

            UpdateInteractibility();
        }

        public void UpdateInteractibility()
        {
            slider.interactable = manager.playerHasAccess;
            playerDropdown.interactable = manager.playerHasAccess;
            //sourceDropdown.interactable = manager.playerHasAccess;
            globalPlaybackButton.interactable = manager.playerHasAccess;
            //localPlaybackButton.interactable = manager.playerHasAccess;
        }

        public void UpdateButtonColors()
        {
            //set the button background colors
            if (manager.globalPlayback)
            {
                globalPlaybackButton.GetComponent<Image>().color = Color.green;
            }
            else
            {
                globalPlaybackButton.GetComponent<Image>().color = Color.red;
            }

            if (manager.localPlayback)
            {
                localPlaybackButton.GetComponent<Image>().color = Color.green;
            }
            else
            {
                localPlaybackButton.GetComponent<Image>().color = Color.red;
            }
        }

        public void SliderUpdated()
        {
            TakeOwnership();
            manager.SetPlayerHeadOffset(slider.value);
        }

        public void UpdateSlider()
        {
            //causes ownership loops that break networking
            //slider.value = manager.playerHeadOffset;
            slider.SetValueWithoutNotify(manager.playerHeadOffset);
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
                case (int)Source.Record:
                    manager.SetSource(Source.Record);
                    break;
                case (int)Source.Playback:
                    manager.SetSource(Source.Playback);
                    break;
            }
            TakeOwnership();
        }

        public void UpdateSource()
        {
            sourceDropdown.SetValueWithoutNotify((int)manager.mode);
        }
    }
}
