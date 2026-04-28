using Any2GSX.PluginInterface.Interfaces;
using CFIT.AppFramework.ResourceStores;
using CFIT.AppLogger;
using CFIT.AppTools;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777DoorManager(Pmdg777Aircraft aircraft)
    {
        public virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        public virtual Pmdg777EfbManager EfbManager => Aircraft?.EfbManager;
        public virtual SimStore SimStore => Aircraft?.SimStore;
        public virtual IGsxController GsxController => Aircraft?.GsxController;
        public virtual bool IsCargo => Aircraft.IsCargo;
        public virtual bool IsStateValid => Aircraft.IsConnected && GsxController.AutomationState > AutomationState.SessionStart && (GsxController.AutomationState < AutomationState.TaxiOut || GsxController.AutomationState > AutomationState.TaxiIn);
        public virtual ISettingProfile SettingProfile => Aircraft?.AppResources?.ISettingProfile;
        public virtual ConcurrentDictionary<PmdgDoorIndex, Pmdg777Door> Doors { get; } = new()
        {
            { PmdgDoorIndex.Pax1L, new(aircraft, PmdgDoorIndex.Pax1L, 14011) },
            { PmdgDoorIndex.Pax1R, new(aircraft, PmdgDoorIndex.Pax1R, 14012) },
            { PmdgDoorIndex.Pax2L, new(aircraft, PmdgDoorIndex.Pax2L, 14013) },
            { PmdgDoorIndex.Pax2R, new(aircraft, PmdgDoorIndex.Pax2R, 14014) },
            { PmdgDoorIndex.Pax3L, new(aircraft, PmdgDoorIndex.Pax3L, 14015) },
            { PmdgDoorIndex.Pax3R, new(aircraft, PmdgDoorIndex.Pax3R, 14016) },
            { PmdgDoorIndex.Pax4L, new(aircraft, PmdgDoorIndex.Pax4L, 14017) },
            { PmdgDoorIndex.Pax4R, new(aircraft, PmdgDoorIndex.Pax4R, 14018) },
            { PmdgDoorIndex.Pax5L, new(aircraft, PmdgDoorIndex.Pax5L, 14019) },
            { PmdgDoorIndex.Pax5R, new(aircraft, PmdgDoorIndex.Pax5R, 14020) },
            { PmdgDoorIndex.CargoFwd, new(aircraft, PmdgDoorIndex.CargoFwd, 14021) },
            { PmdgDoorIndex.CargoAft, new(aircraft, PmdgDoorIndex.CargoAft, 14022) },
            { PmdgDoorIndex.CargoMain, new(aircraft, PmdgDoorIndex.CargoMain, 14023) },
            { PmdgDoorIndex.CargoBulk, new(aircraft, PmdgDoorIndex.CargoBulk, 14024) },
            { PmdgDoorIndex.Avionics, new(aircraft, PmdgDoorIndex.Avionics, 14025) },
            { PmdgDoorIndex.EEAccess, new(aircraft, PmdgDoorIndex.EEAccess, 14026) },
        };
        public virtual ConcurrentDictionary<PmdgCargoLight, Pmdg777CargoLight> CargoLights { get; } = new()
        {
            { PmdgCargoLight.Ceiling, new(aircraft,PmdgCargoLight.Ceiling) },
            { PmdgCargoLight.Sidewall, new(aircraft, PmdgCargoLight.Sidewall) },
            { PmdgCargoLight.ExtCam, new(aircraft, PmdgCargoLight.ExtCam) },
            { PmdgCargoLight.SillLoad, new(aircraft, PmdgCargoLight.SillLoad, 0) },
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
            { GsxDoor.CargoDoor3Main, PmdgDoorIndex.CargoBulk },
        };

        public virtual Pmdg777Door GetDoor(GsxDoor door)
        {
            return Doors[DoorMapping[door]];
        }

        public virtual void InitDoors()
        {
            string variant = "";
            if (Aircraft.IsCargo)
            {
                variant = "777F";

                Doors[PmdgDoorIndex.Pax2L].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax3L].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax4L].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax5L].IsAvailable = false;

                DoorMapping[GsxDoor.ServiceDoor1] = PmdgDoorIndex.Pax1R;
                Doors[PmdgDoorIndex.Pax2R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax3R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax4R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax5R].IsAvailable = false;

                DoorMapping[GsxDoor.CargoDoor3Main] = PmdgDoorIndex.CargoMain;
            }
            else if (Aircraft.AircraftString.Contains("200", System.StringComparison.InvariantCultureIgnoreCase))
            {
                variant = "200";
                DoorMapping[GsxDoor.PaxDoor4] = PmdgDoorIndex.Pax4L;
                Doors[PmdgDoorIndex.Pax5L].IsAvailable = false;


                DoorMapping[GsxDoor.ServiceDoor1] = PmdgDoorIndex.Pax1R;
                DoorMapping[GsxDoor.ServiceDoor2] = PmdgDoorIndex.Pax4R;
                Doors[PmdgDoorIndex.Pax5R].IsAvailable = false;

                Doors[PmdgDoorIndex.CargoMain].IsAvailable = false;
            }
            else if (Aircraft.AircraftString.Contains("300", System.StringComparison.InvariantCultureIgnoreCase))
            {
                variant = "300";

                Doors[PmdgDoorIndex.CargoMain].IsAvailable = false;
            }

            Logger.Information($"Mapped Doors for Variant: {variant}");
        }

        public virtual async Task CheckDoors()
        {
            if (!IsStateValid)
                return;

            if (Aircraft.DoorArmTarget && HasUnarmedDoors())
                await Aircraft.EfbManager.SendRequest("arm_all", "doors");

            if (IsCargo)
                await SyncCargoLights();
        }

        protected virtual bool IsLightSyncAllowed()
        {
            return Aircraft.ISettingProfile.GetSetting(PmdgSettings.CargoLights) && IsStateValid;
        }

        protected virtual async Task SyncCargoLights()
        {
            var main = Doors[PmdgDoorIndex.CargoMain];
            var sill = CargoLights[PmdgCargoLight.SillLoad];
            if (main.IsFullyOpen && sill.GetOff())
                await sill.TurnOn();
            else if (main.IsFullyClosed && sill.GetOn())
                await sill.TurnOff();

            if ((GsxController.AutomationState == AutomationState.Departure || GsxController.AutomationState == AutomationState.Arrival)
                && (Doors[PmdgDoorIndex.CargoFwd].IsFullyOpen || Doors[PmdgDoorIndex.CargoAft].IsFullyOpen || Doors[PmdgDoorIndex.CargoMain].IsFullyOpen))
                await CargoLights[PmdgCargoLight.Sidewall].TurnOn();

            if ((GsxController.AutomationState == AutomationState.Pushback || GsxController.AutomationState == AutomationState.TurnAround)
                && CargoLights.Values.Any(cl => cl.GetOn())
                && Doors.Values.Where(d => d.IsCargoDoor).All(d => d.IsFullyClosed))
            {
                foreach (var item in CargoLights.Values)
                    if (item.Id != PmdgCargoLight.SillLoad)
                        await item.TurnOff();
            }
            else if ((GsxController.AutomationState == AutomationState.Departure || GsxController.AutomationState == AutomationState.Arrival)
                && CargoLights.Values.Any(cl => cl.GetOff())
                && Doors.Values.Where(d => d.IsCargoDoor).All(d => d.IsFullyOpen))
            {
                foreach (var item in CargoLights.Values)
                    if (item.Id != PmdgCargoLight.SillLoad)
                        await item.TurnOn();
            }
        }

        public virtual Task DoorsAllClose()
        {
            return EfbManager.SendRequest("close_all", "doors");
        }

        public virtual async Task SetCargoDoors(bool state, bool force = false)
        {
            await Doors[PmdgDoorIndex.CargoFwd].SetDoor(state);
            await Doors[PmdgDoorIndex.CargoAft].SetDoor(state);
            if (Aircraft.ISettingProfile.GetSetting(PmdgSettings.OperateBulk))
                await Doors[PmdgDoorIndex.CargoBulk].SetDoor(state);
            if (IsCargo)
                await Doors[PmdgDoorIndex.CargoMain].SetDoor(state);
        }

        public virtual bool HasArmedDoors()
        {
            return Doors.Values.Any(d => d.IsPaxDoor && d.IsArmed);
        }

        public virtual bool HasUnarmedDoors()
        {
            return Doors.Values.Any(d => d.IsPaxDoor && !d.IsArmed);
        }

        public virtual bool HasOpenDoors()
        {
            return Doors.Values.Any(d => d.IsOpen);
        }

        public virtual async Task OnBoardState(IGsxService boardService)
        {
            if (IsCargo && IsLightSyncAllowed())
            {
                if (boardService.IsRunning)
                {
                    await CargoLights[PmdgCargoLight.Ceiling].TurnOn();
                    await CargoLights[PmdgCargoLight.ExtCam].TurnOn();
                }
                else
                {
                    if (!SettingProfile.DoorsCargoKeepOpenOnDetachBoard)
                    {
                        await CargoLights[PmdgCargoLight.Ceiling].TurnOff();
                        await CargoLights[PmdgCargoLight.Sidewall].TurnOff();
                        await CargoLights[PmdgCargoLight.ExtCam].TurnOff();
                    }
                }
            }
        }

        public virtual async Task OnDeboardState(IGsxService deboardService)
        {
            if (IsCargo && IsLightSyncAllowed())
            {
                if (deboardService.IsRunning)
                {
                    await CargoLights[PmdgCargoLight.Ceiling].TurnOn();
                    await CargoLights[PmdgCargoLight.ExtCam].TurnOn();
                }
                else
                {
                    if (!SettingProfile.DoorsCargoKeepOpenOnDetachDeboard)
                    {
                        await CargoLights[PmdgCargoLight.Ceiling].TurnOff();
                        await CargoLights[PmdgCargoLight.Sidewall].TurnOff();
                        await CargoLights[PmdgCargoLight.ExtCam].TurnOff();
                    }
                }
            }
        }

        public virtual async Task OnCateringState(IGsxService cateringService)
        {
            if (SettingProfile.DoorServiceHandling && !cateringService.IsRunning && IsStateValid)
            {
                Pmdg777Door pmdgDoor = GetDoor(GsxDoor.ServiceDoor1);
                if (pmdgDoor.IsOpen && !pmdgDoor.IsMoving)
                    await pmdgDoor.SetDoor(PmdgDoorState.Closed);

                pmdgDoor = GetDoor(GsxDoor.ServiceDoor2);
                if (pmdgDoor.IsOpen && !pmdgDoor.IsMoving)
                    await pmdgDoor.SetDoor(PmdgDoorState.Closed);
            }
        }

        public virtual async Task OnDoorTrigger(GsxDoor door, bool trigger)
        {
            if (!IsStateValid)
                return;

            Pmdg777Door pmdgDoor = GetDoor(door);
            if (trigger && !IGsxController.IsCargoDoor(door))
            {
                if (GsxController.HasGateJetway && door == GsxDoor.PaxDoor2)
                {
                    if (pmdgDoor.IsClosed && GsxController.JetwayState == GsxServiceState.Active)
                        await pmdgDoor.ToggleDoor();
                }
                else if (!GsxController.HasGateJetway && IGsxController.IsPaxDoor(door))
                {
                    if (pmdgDoor.IsClosed && GsxController.StairsState == GsxServiceState.Active)
                        await pmdgDoor.ToggleDoor();
                }
                else
                    await pmdgDoor.ToggleDoor();
            }
        }

        public virtual Task OnLoaderAttached(GsxDoor door, bool attached)
        {
            if (!IsStateValid)
                return Task.CompletedTask;

            Pmdg777Door pmdgDoor = GetDoor(door);

            return pmdgDoor.SetDoor(attached ? PmdgDoorState.Open : PmdgDoorState.Closed);
        }

        public virtual Task OnJetwayStateChange(GsxServiceState state, bool paxDoorAllowed)
        {
            if (!IsCargo && paxDoorAllowed)
            {
                if (state == GsxServiceState.Active)
                    return GetDoor(GsxDoor.PaxDoor2).SetDoor(PmdgDoorState.Open);
                else
                    return GetDoor(GsxDoor.PaxDoor2).SetDoor(PmdgDoorState.Closed);
            }

            return Task.CompletedTask;
        }

        public virtual async Task OnStairStateChange(GsxServiceState state, bool paxDoorAllowed)
        {
            if (!IsStateValid || !paxDoorAllowed)
                return;

            if (HasArmedDoors() && state == GsxServiceState.Active)
                await Aircraft.DoorDisarmAll();

            var target = state == GsxServiceState.Active ? PmdgDoorState.Open : PmdgDoorState.Closed;
            if (!IsCargo)
            {
                await GetDoor(GsxDoor.PaxDoor4).SetDoor(target);

                if (!Aircraft.GsxController.HasGateJetway)
                {
                    await GetDoor(GsxDoor.PaxDoor1).SetDoor(target);
                    await GetDoor(GsxDoor.PaxDoor2).SetDoor(target);
                }
            }
            else
            {
                await GetDoor(GsxDoor.PaxDoor1).SetDoor(target);
            }
        }
    }
}
