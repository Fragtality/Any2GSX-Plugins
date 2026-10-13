using Any2GSX.PluginInterface.Interfaces;
using Any2GSX.PluginInterface.Interfaces.GSX;
using CFIT.AppFramework.ResourceStores;
using CFIT.AppLogger;
using CFIT.AppTools;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
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
        public virtual ConcurrentDictionary<PmdgDoorIndex, bool> DoorTargetMonitor { get; } = [];
        public virtual DateTime NextDoorCheck { get; protected set; } = DateTime.MaxValue;
        public const int DoorInterval = 15000;
        public virtual ConcurrentDictionary<PmdgCargoLight, Pmdg777CargoLight> CargoLights { get; } = new()
        {
            { PmdgCargoLight.Ceiling, new(aircraft,PmdgCargoLight.Ceiling) },
            { PmdgCargoLight.Sidewall, new(aircraft, PmdgCargoLight.Sidewall) },
            { PmdgCargoLight.ExtCam, new(aircraft, PmdgCargoLight.ExtCam) },
            { PmdgCargoLight.SillLoad, new(aircraft, PmdgCargoLight.SillLoad, 0) },
        };
        public virtual ConcurrentDictionary<AircraftDoor, PmdgDoorIndex> DoorMappingPmdg { get; } = new()
        {
            { AircraftDoor.L1, PmdgDoorIndex.Pax1L },
            { AircraftDoor.L2, PmdgDoorIndex.Pax2L },
            { AircraftDoor.L3, PmdgDoorIndex.Pax3L },
            { AircraftDoor.L4, PmdgDoorIndex.Pax4L },
            { AircraftDoor.L5, PmdgDoorIndex.Pax5L },
            { AircraftDoor.R1, PmdgDoorIndex.Pax1R },
            { AircraftDoor.R2, PmdgDoorIndex.Pax2R },
            { AircraftDoor.R3, PmdgDoorIndex.Pax3R },
            { AircraftDoor.R4, PmdgDoorIndex.Pax4R },
            { AircraftDoor.R5, PmdgDoorIndex.Pax5R },
            { AircraftDoor.CargoFront, PmdgDoorIndex.CargoFwd },
            { AircraftDoor.CargoRear, PmdgDoorIndex.CargoAft },
            { AircraftDoor.CargoMain, PmdgDoorIndex.CargoMain },
            { AircraftDoor.CargoBulk, PmdgDoorIndex.CargoBulk },
        };
        public virtual ConcurrentDictionary<GsxVehicleLocation, bool> StairsAvailable { get; } = new()
        {
            { GsxVehicleLocation.Front, false },
            { GsxVehicleLocation.Middle, false },
            { GsxVehicleLocation.Rear, false },
        };

        public virtual Pmdg777Door GetDoor(AircraftDoor aircraftDoor)
        {
            return Doors[DoorMappingPmdg[aircraftDoor]];
        }

        public virtual async Task<AircraftDoor> GetDefaultDoor(GsxDoor gsxDoor)
        {
            if (Aircraft.AircraftString.Contains("300", System.StringComparison.InvariantCultureIgnoreCase))
            {
                return gsxDoor switch
                {
                    GsxDoor.PaxDoor1 => AircraftDoor.L1,
                    GsxDoor.PaxDoor2 => AircraftDoor.L2,
                    GsxDoor.PaxDoor3 => AircraftDoor.L4,
                    GsxDoor.PaxDoor4 => AircraftDoor.L5,
                    GsxDoor.ServiceDoor1 => AircraftDoor.R2,
                    GsxDoor.ServiceDoor2 => AircraftDoor.R5,
                    GsxDoor.CargoDoor1 => AircraftDoor.CargoFront,
                    GsxDoor.CargoDoor2 => AircraftDoor.CargoRear,
                    GsxDoor.CargoDoor3Main => AircraftDoor.CargoBulk,
                    _ => AircraftDoor.L1,
                };
            }
            else
                return await Aircraft.MapDoorDefaults(gsxDoor);
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

                Doors[PmdgDoorIndex.Pax2R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax3R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax4R].IsAvailable = false;
                Doors[PmdgDoorIndex.Pax5R].IsAvailable = false;
            }
            else if (Aircraft.AircraftString.Contains("200", System.StringComparison.InvariantCultureIgnoreCase))
            {
                variant = "200";

                Doors[PmdgDoorIndex.Pax5L].IsAvailable = false;

                Doors[PmdgDoorIndex.Pax5R].IsAvailable = false;

                Doors[PmdgDoorIndex.CargoMain].IsAvailable = false;
            }
            else if (Aircraft.AircraftString.Contains("300", System.StringComparison.InvariantCultureIgnoreCase))
            {
                variant = "300";

                Doors[PmdgDoorIndex.CargoMain].IsAvailable = false;
            }

            Logger.Information($"Configured Doors for Variant: {variant}");
        }

        public virtual async Task CheckDoors()
        {
            if (!IsStateValid)
                return;

            if (Aircraft.DoorArmTarget && HasUnarmedDoors())
                await Aircraft.EfbManager.SendRequest("arm_all", "doors");

            if (IsCargo)
                await SyncCargoLights();

            if (Aircraft.GsxController.IsOnGround)
                await CheckDoorMonitor();
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

        public virtual async Task CheckDoorMonitor()
        {
            if (NextDoorCheck < DateTime.Now)
            {
                List<PmdgDoorIndex> removeList = [];
                foreach (var doorTarget in DoorTargetMonitor)
                {
                    var door = Doors[doorTarget.Key];
                    if ((door.IsClosed && doorTarget.Value) || (door.IsOpen && !doorTarget.Value))
                    {
                        Logger.Information($"Toogle Door {door.Index} - not at expected Target State");
                        await door.ToggleDoor();
                    }
                    else
                        removeList.Add(doorTarget.Key);
                }

                foreach (var door in removeList)
                    DoorTargetMonitor.TryRemove(door, out _);

                if (!DoorTargetMonitor.IsEmpty)
                    NextDoorCheck = DateTime.Now + TimeSpan.FromMilliseconds(DoorInterval);
                else
                    NextDoorCheck = DateTime.MaxValue;
            }
        }

        public virtual Task SetDoor(AircraftDoor aircraftDoor, bool target)
        {
            var index = DoorMappingPmdg[aircraftDoor];

            if (!DoorTargetMonitor.TryAdd(index, target))
                DoorTargetMonitor[index] = target;
            NextDoorCheck = DateTime.Now + TimeSpan.FromMilliseconds(DoorInterval);

            return Doors[index].SetDoor(target);
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
                    if (HasArmedDoors())
                        await Aircraft.DoorDisarmAll();

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
                    if (HasArmedDoors())
                        await Aircraft.DoorDisarmAll();

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
    }
}
