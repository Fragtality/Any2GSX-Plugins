using Any2GSX.PluginInterface.Interfaces;
using CFIT.AppFramework.ResourceStores;
using CFIT.AppLogger;
using CFIT.AppTools;
using CFIT.SimConnectLib.SimResources;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777DoorManager(Pmdg777Aircraft aircraft)
    {
        public virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        public virtual SimStore SimStore => Aircraft?.SimStore;
        public virtual IGsxController GsxController => Aircraft?.GsxController;
        public virtual bool IsCargo => Aircraft.IsCargo;
        public virtual ISettingProfile SettingProfile => Aircraft?.AppResources?.ISettingProfile;
        public virtual PMDG_777X_Data PMDG_777X_Data => Aircraft.PMDG_777X_Data;
        public virtual Pmdg777EfbData EfbData => Aircraft?.EfbManager?.EfbData;
        public virtual ConcurrentDictionary<PmdgDoorIndex, Pmdg777Door> Doors { get; } = new()
        {
            { PmdgDoorIndex.Pax1L, new(aircraft, PmdgDoorIndex.Pax1L, 14011, DoorMonitorAction.Monitored) },
            { PmdgDoorIndex.Pax1R, new(aircraft, PmdgDoorIndex.Pax1R, 14012, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Pax2L, new(aircraft, PmdgDoorIndex.Pax2L, 14013, DoorMonitorAction.Monitored) },
            { PmdgDoorIndex.Pax2R, new(aircraft, PmdgDoorIndex.Pax2R, 14014, DoorMonitorAction.Monitored) },
            { PmdgDoorIndex.Pax3L, new(aircraft, PmdgDoorIndex.Pax3L, 14015, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Pax3R, new(aircraft, PmdgDoorIndex.Pax3R, 14016, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Pax4L, new(aircraft, PmdgDoorIndex.Pax4L, 14017, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Pax4R, new(aircraft, PmdgDoorIndex.Pax4R, 14018, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Pax5L, new(aircraft, PmdgDoorIndex.Pax5L, 14019, DoorMonitorAction.Monitored) },
            { PmdgDoorIndex.Pax5R, new(aircraft, PmdgDoorIndex.Pax5R, 14020, DoorMonitorAction.Monitored) },
            { PmdgDoorIndex.CargoFwd, new(aircraft, PmdgDoorIndex.CargoFwd, 14021, DoorMonitorAction.Monitored) { DefaultInhibitTime = 5000 } },
            { PmdgDoorIndex.CargoAft, new(aircraft, PmdgDoorIndex.CargoAft, 14022, DoorMonitorAction.Monitored) { DefaultInhibitTime = 5000 } },
            { PmdgDoorIndex.CargoMain, new(aircraft, PmdgDoorIndex.CargoMain, 14023, DoorMonitorAction.Monitored) { DefaultInhibitTime = 10000 } },
            { PmdgDoorIndex.CargoBulk, new(aircraft, PmdgDoorIndex.CargoBulk, 14024, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.Avionics, new(aircraft, PmdgDoorIndex.Avionics, 14025, DoorMonitorAction.KeepClosed) },
            { PmdgDoorIndex.EEAccess, new(aircraft, PmdgDoorIndex.EEAccess, 14026, DoorMonitorAction.KeepClosed) },
        };
        public virtual List<PmdgCargoLight> CargoLights { get; } = new()
        {
            { PmdgCargoLight.Ceiling },
            { PmdgCargoLight.Sidewall },
            { PmdgCargoLight.ExtCam },
            { PmdgCargoLight.SillLoad },
        };
        public virtual ConcurrentDictionary<GsxDoor, PmdgDoorIndex> DoorMapping { get; } = new()
        {
            { GsxDoor.PaxDoor1, PmdgDoorIndex.Pax1L },
            { GsxDoor.PaxDoor2, PmdgDoorIndex.Pax2L },
            { GsxDoor.PaxDoor3, PmdgDoorIndex.Pax4L },
            { GsxDoor.PaxDoor4, PmdgDoorIndex.Pax5L },
            { GsxDoor.ServiceDoor1, PmdgDoorIndex.Pax2R },
            { GsxDoor.ServiceDoor2, PmdgDoorIndex.Pax5R },
            { GsxDoor.CargoDoor1, PmdgDoorIndex.CargoFwd },
            { GsxDoor.CargoDoor2, PmdgDoorIndex.CargoAft },
            { GsxDoor.CargoDoor3Main, PmdgDoorIndex.CargoMain },
        };

        public virtual void InitDoors()
        {
            Logger.Debug("Initializing Doors");
            if (Aircraft.AircraftString.Contains("200", System.StringComparison.InvariantCultureIgnoreCase))
            {
                DoorMapping[GsxDoor.ServiceDoor1] = PmdgDoorIndex.Pax1R;
                Doors[PmdgDoorIndex.Pax1R].Monitoring = DoorMonitorAction.Monitored;
                Doors[PmdgDoorIndex.Pax2R].Monitoring = DoorMonitorAction.KeepClosed;
                DoorMapping[GsxDoor.ServiceDoor2] = PmdgDoorIndex.Pax4R;
                Doors[PmdgDoorIndex.Pax4R].Monitoring = DoorMonitorAction.Monitored;
                Doors[PmdgDoorIndex.Pax5R].Monitoring = DoorMonitorAction.KeepClosed;
                DoorMapping[GsxDoor.PaxDoor4] = PmdgDoorIndex.Pax4L;
            }

            if (!Aircraft.IsCargo)
                Doors[PmdgDoorIndex.CargoMain].Monitoring = DoorMonitorAction.Unmonitored;
            else
            {
                DoorMapping[GsxDoor.ServiceDoor1] = PmdgDoorIndex.Pax1R;
                Doors[PmdgDoorIndex.Pax1R].Monitoring = DoorMonitorAction.Monitored;
                Doors[PmdgDoorIndex.Pax2R].Monitoring = DoorMonitorAction.KeepClosed;
                Doors[PmdgDoorIndex.Pax4R].Monitoring = DoorMonitorAction.KeepClosed;
            }
        }

        public virtual async Task CheckDoors()
        {
            foreach (var door in Doors.Values)
            {
                if (door.IsInhibited || door.Monitoring == DoorMonitorAction.Unmonitored)
                    continue;

                if (door.Monitoring == DoorMonitorAction.KeepClosed && door.State == PmdgDoorState.Open)
                {
                    Logger.Debug($"Keeping Door {door.Index} closed");
                    await door.SendDoorCode();
                }
                else if (door.Target != door.State && !door.IsMoving)
                {
                    if ((door.Target == PmdgDoorState.ClosedArmed && door.State == PmdgDoorState.Closed)
                     || (door.Target == PmdgDoorState.Closed && door.State == PmdgDoorState.ClosedArmed))
                    {
                        door.Target = door.State;
                        Logger.Debug($"Update armed State for Door {door.Index}");
                    }
                    else
                    {
                        Logger.Debug($"{door.Index}: Target State ({door.Target}) different to current State ({door.State}) - trigger Door");
                        await door.SendDoorCode();
                        if (door.Index == PmdgDoorIndex.CargoMain)
                            door.InhibitUpdates(7500);
                    }
                }
            }

            if (Aircraft.DoorArmTarget && HasUnarmedDoors())
                await Aircraft.EfbManager.SendRequest("arm_all", "doors");

            if (Aircraft.AutomationState == AutomationState.Preparation || Aircraft.AutomationState == AutomationState.Departure || Aircraft.AutomationState == AutomationState.Arrival)
                SyncDoorToService();
            if (IsCargo && (Aircraft.AutomationState == AutomationState.Preparation || Aircraft.AutomationState == AutomationState.Departure || Aircraft.AutomationState == AutomationState.Pushback
                || Aircraft.AutomationState == AutomationState.Arrival || Aircraft.AutomationState == AutomationState.TurnAround))
                SyncCargoLights();
        }

        protected virtual bool IsLightSyncAllowed()
        {
            return Aircraft.ISettingProfile.HasSetting<bool>(PmdgSettings.OptionCargoLights, out bool cargoLights) && cargoLights;
        }

        protected virtual void ToggleCargoLight(PmdgCargoLight light)
        {
            if (!CargoLights.Contains(light))
                return;

            SimStore[Pmdg777Aircraft.GetEventName((int)light)]!?.WriteValue(Pmdg777Aircraft.EvtLeftSingle);
        }

        protected virtual void SyncCargoLights()
        {
            if (Doors[PmdgDoorIndex.CargoFwd].State == PmdgDoorState.Opening || Doors[PmdgDoorIndex.CargoAft].State == PmdgDoorState.Opening
                || Doors[PmdgDoorIndex.CargoMain].State == PmdgDoorState.Opening)
            {
                if (GetCargoLight(PmdgCargoLight.Sidewall) != 100)
                {
                    Logger.Debug($"Turning on Lights {PmdgCargoLight.Sidewall}");
                    ToggleCargoLight(PmdgCargoLight.Sidewall);
                }
            }
            else if (Doors[PmdgDoorIndex.CargoMain].State == PmdgDoorState.Closing)
            {
                if (GetCargoLight(PmdgCargoLight.Sidewall) != 0)
                {
                    Logger.Debug($"Turning off Lights {PmdgCargoLight.Sidewall}");
                    ToggleCargoLight(PmdgCargoLight.Sidewall);
                }
            }
        }

        protected virtual int GetCargoLight(PmdgCargoLight light)
        {
            return (int)(SimStore[$"L:switch_{(int)light}_a"]!?.GetNumber() ?? 0.0);
        }

        protected virtual void SyncDoorToService()
        {
            if (GsxController.HasGateJetway)
            {
                SyncDoorToService(Doors[PmdgDoorIndex.Pax2L], GsxController.GetService(GsxServiceType.Jetway));
                if (!IsCargo)
                    SyncDoorToService(Doors[DoorMapping[GsxDoor.PaxDoor4]], GsxController.GetService(GsxServiceType.Stairs));
            }
            else
            {
                SyncDoorToService(Doors[PmdgDoorIndex.Pax1L], GsxController.GetService(GsxServiceType.Stairs));
                if (!IsCargo)
                {                    
                    SyncDoorToService(Doors[PmdgDoorIndex.Pax2L], GsxController.GetService(GsxServiceType.Stairs));
                    SyncDoorToService(Doors[DoorMapping[GsxDoor.PaxDoor4]], GsxController.GetService(GsxServiceType.Stairs));
                }
            }
        }

        public static void SyncDoorToService(Pmdg777Door door, IGsxService service)
        {
            if (door.IsInhibited)
                return;

            if (service.State == GsxServiceState.Active && !door.IsOpen)
                door.SetDoor(PmdgDoorState.Open);
            else if (service.State != GsxServiceState.Active && door.IsOpen)
                door.SetDoor(PmdgDoorState.Closed);
        }

        public virtual void SetAll(PmdgDoorState target)
        {
            foreach (var door in Doors.Values)
            {
                door.Target = target;
                door.InhibitUpdates();
            }
        }

        public virtual void DisarmAll()
        {
            foreach (var door in Doors.Values)
            {
                if (door.State == PmdgDoorState.ClosedArmed)
                {
                    door.Target = PmdgDoorState.Closed;
                    door.InhibitUpdates();
                }
            }
        }

        public virtual bool HasUnarmedDoors()
        {
            return Doors.Values.Any(d => d.State != PmdgDoorState.ClosedArmed);
        }

        public virtual void ArmAll()
        {
            foreach (var door in Doors.Values)
            {
                if (door.State == PmdgDoorState.Closed || door.State == PmdgDoorState.Closing)
                {
                    door.Target = PmdgDoorState.ClosedArmed;
                    door.InhibitUpdates();
                }
            }
        }

        public virtual void OnDoorMainCargo(ISimResourceSubscription sub, object data)
        {
            bool doorOpen = sub?.GetNumber() == 100;

            if (doorOpen && GetCargoLight(PmdgCargoLight.SillLoad) != 0)
            {
                Logger.Debug($"Turning on Lights {PmdgCargoLight.SillLoad}");
                ToggleCargoLight(PmdgCargoLight.SillLoad);
            }
            else if (!doorOpen && GetCargoLight(PmdgCargoLight.SillLoad) != 100)
            {
                Logger.Debug($"Turning off Lights {PmdgCargoLight.SillLoad}");
                ToggleCargoLight(PmdgCargoLight.SillLoad);
            }
        }

        public virtual void OnBoardState(IGsxService boardService)
        {
            DoorMonitorAction action;
            if ((boardService.State == GsxServiceState.Active || boardService.State == GsxServiceState.Requested) || !SettingProfile.DoorCargoHandling)
                action = DoorMonitorAction.Unmonitored;
            else
            {
                action = DoorMonitorAction.Monitored;
                Doors[PmdgDoorIndex.CargoFwd].Target = PmdgDoorState.Closed;
                Doors[PmdgDoorIndex.CargoAft].Target = PmdgDoorState.Closed;
                if (IsCargo)
                    Doors[PmdgDoorIndex.CargoMain].Target = PmdgDoorState.Closed;
            }

            Doors[PmdgDoorIndex.CargoFwd].Monitoring = action;
            Doors[PmdgDoorIndex.CargoAft].Monitoring = action;
            if (IsCargo)
                Doors[PmdgDoorIndex.CargoMain].Monitoring = action;

            if (IsCargo && IsLightSyncAllowed())
            {
                if (boardService.IsRunning)
                {
                    if (GetCargoLight(PmdgCargoLight.Ceiling) != 100)
                    {
                        Logger.Debug($"Turning on Lights {PmdgCargoLight.Ceiling}");
                        ToggleCargoLight(PmdgCargoLight.Ceiling);
                    }
                    if (GetCargoLight(PmdgCargoLight.ExtCam) != 100)
                    {
                        Logger.Debug($"Turning on Lights {PmdgCargoLight.ExtCam}");
                        ToggleCargoLight(PmdgCargoLight.ExtCam);
                    }
                }
                else
                {
                    if (GetCargoLight(PmdgCargoLight.Ceiling) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.Ceiling}");
                        ToggleCargoLight(PmdgCargoLight.Ceiling);
                    }
                    if (GetCargoLight(PmdgCargoLight.Sidewall) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.Sidewall}");
                        ToggleCargoLight(PmdgCargoLight.Sidewall);
                    }
                    if (GetCargoLight(PmdgCargoLight.ExtCam) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.ExtCam}");
                        ToggleCargoLight(PmdgCargoLight.ExtCam);
                    }
                }
            }
        }

        public virtual void OnDeboardState(IGsxService deboardService)
        {
            DoorMonitorAction action;
            if ((deboardService.State == GsxServiceState.Active || deboardService.State == GsxServiceState.Requested) || !SettingProfile.DoorCargoHandling)
                action = DoorMonitorAction.Unmonitored;
            else
            {
                action = DoorMonitorAction.Monitored;
                Doors[PmdgDoorIndex.CargoFwd].Target = PmdgDoorState.Closed;
                Doors[PmdgDoorIndex.CargoAft].Target = PmdgDoorState.Closed;
                if (IsCargo)
                    Doors[PmdgDoorIndex.CargoMain].Target = PmdgDoorState.Closed;
            }

            Doors[PmdgDoorIndex.CargoFwd].Monitoring = action;
            Doors[PmdgDoorIndex.CargoAft].Monitoring = action;
            if (IsCargo)
                Doors[PmdgDoorIndex.CargoMain].Monitoring = action;

            if (IsCargo && IsLightSyncAllowed())
            {
                if (deboardService.IsRunning)
                {
                    if (GetCargoLight(PmdgCargoLight.Ceiling) != 100)
                    {
                        Logger.Debug($"Turning on Lights {PmdgCargoLight.Ceiling}");
                        ToggleCargoLight(PmdgCargoLight.Ceiling);
                    }
                    if (GetCargoLight(PmdgCargoLight.ExtCam) != 100)
                    {
                        Logger.Debug($"Turning on Lights {PmdgCargoLight.ExtCam}");
                        ToggleCargoLight(PmdgCargoLight.ExtCam);
                    }
                }
                else
                {
                    if (GetCargoLight(PmdgCargoLight.Ceiling) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.Ceiling}");
                        ToggleCargoLight(PmdgCargoLight.Ceiling);
                    }
                    if (GetCargoLight(PmdgCargoLight.Sidewall) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.Sidewall}");
                        ToggleCargoLight(PmdgCargoLight.Sidewall);
                    }
                    if (GetCargoLight(PmdgCargoLight.ExtCam) != 0)
                    {
                        Logger.Debug($"Turning off Lights {PmdgCargoLight.ExtCam}");
                        ToggleCargoLight(PmdgCargoLight.ExtCam);
                    }
                }
            }
        }

        public virtual void OnDoorTrigger(GsxDoor door, bool trigger)
        {
            if (trigger)
            {
                if (door == GsxDoor.ServiceDoor1 || door == GsxDoor.ServiceDoor2)
                {
                    if (SettingProfile.DoorServiceHandling)
                    {
                        Doors[DoorMapping[GsxDoor.ServiceDoor1]].ToggleDoor();
                        if (!IsCargo)
                            Doors[DoorMapping[GsxDoor.ServiceDoor2]].ToggleDoor();
                    }
                    else
                    {
                        Doors[DoorMapping[GsxDoor.ServiceDoor1]].Monitoring = DoorMonitorAction.Unmonitored;
                        if (!IsCargo)
                            Doors[DoorMapping[GsxDoor.ServiceDoor2]].Monitoring = DoorMonitorAction.Unmonitored;
                    }
                }

                if (IsCargo && door == GsxDoor.CargoDoor3Main && SettingProfile.DoorCargoHandling)
                {
                    var pmdgDoor = Doors[DoorMapping[GsxDoor.CargoDoor3Main]];
                    if (pmdgDoor.IsClosed)
                        pmdgDoor.SetDoor(PmdgDoorState.Open);
                    else
                        pmdgDoor.SetDoor(PmdgDoorState.Closed);
                    Doors[PmdgDoorIndex.CargoMain].Monitoring = DoorMonitorAction.Monitored;
                }
                else
                    Doors[PmdgDoorIndex.CargoMain].Monitoring = DoorMonitorAction.Unmonitored;
            }
        }

        public virtual void OnJetwayChange(GsxServiceState state)
        {
            if (!IsCargo && state == GsxServiceState.Active)
                Doors[DoorMapping[GsxDoor.PaxDoor2]].SetDoor(PmdgDoorState.Open);
        }

        public virtual void OnStairChange(GsxServiceState state)
        {
            if (!SettingProfile.DoorStairHandling)
            {
                Doors[DoorMapping[GsxDoor.PaxDoor1]].Monitoring = DoorMonitorAction.Unmonitored;
                Doors[DoorMapping[GsxDoor.PaxDoor2]].Monitoring = DoorMonitorAction.Unmonitored;
                Doors[DoorMapping[GsxDoor.PaxDoor4]].Monitoring = DoorMonitorAction.Unmonitored;
                return;
            }
            else
            {
                Doors[DoorMapping[GsxDoor.PaxDoor1]].Monitoring = DoorMonitorAction.Monitored;
                Doors[DoorMapping[GsxDoor.PaxDoor2]].Monitoring = DoorMonitorAction.Monitored;
                Doors[DoorMapping[GsxDoor.PaxDoor4]].Monitoring = DoorMonitorAction.Monitored;
            }

            var target = state == GsxServiceState.Active ? PmdgDoorState.Open : PmdgDoorState.Closed;
            if (!IsCargo)
            {
                Doors[DoorMapping[GsxDoor.PaxDoor4]].SetDoor(target);

                if (!Aircraft.GsxController.HasGateJetway)
                {
                    Doors[DoorMapping[GsxDoor.PaxDoor1]].SetDoor(target);
                    Doors[DoorMapping[GsxDoor.PaxDoor2]].SetDoor(target);
                }
            }
            else
            {
                Doors[DoorMapping[GsxDoor.PaxDoor1]].SetDoor(target);
            }
        }
    }
}
