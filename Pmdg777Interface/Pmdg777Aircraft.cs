using Any2GSX.PluginInterface;
using Any2GSX.PluginInterface.Interfaces;
using CFIT.AppLogger;
using CFIT.SimConnectLib.SimResources;
using System;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777Aircraft : AircraftBase
    {
        public const int EventBase = 69632;
        public const int EvtLeftSingle = 0x20000000;
        public override bool IsConnected => ReceivedDataValid && EfbManager?.IsConnected == true;
        public virtual bool ReceivedDataValid => Module?.ReceivedDataValid == true;
        public virtual Pmdg777Plugin Plugin => AppPlugin.Instance as Pmdg777Plugin;
        public virtual Pmdg777Module Module => Plugin?.SimConnectModule as Pmdg777Module;
        public virtual Pmdg777EfbManager EfbManager { get; }
        public virtual Pmdg777DoorManager DoorManager { get; }
        public virtual PMDG_777X_Data PMDG_777X_Data => Module?.PMDG_777X_Data ?? new();
        public virtual ISimResourceSubscription SubRotorBrake { get; protected set; }
        public virtual AutomationState AutomationState => GsxController.IAutomationController.State;
        public virtual bool DoorArmTarget { get; protected set; } = true;
        protected virtual bool MicIntSwitchTriggered { get; set; } = false;
        protected virtual bool FirstRun { get; set; } = true;
        protected virtual bool LastModuleState { get; set; } = false;
        protected virtual bool LastWalkaround { get; set; } = true;
        protected virtual DateTime TimeNextDataToggle { get; set; } = DateTime.MaxValue;

        public virtual bool IsWeightInKg => PMDG_777X_Data.WeightInKg != 0;
        public virtual bool IsCargo => AircraftString?.Contains("PMDG 777F", StringComparison.InvariantCultureIgnoreCase) ?? false;
        public virtual bool AvionicsPowered => SimStore[PmdgConstants.VarAircraftPowered]?.GetNumber() > 0;
        public virtual bool PowerAvailable => PMDG_777X_Data.ELEC_annunExtPowr_AVAIL[0] > 0 || PMDG_777X_Data.ELEC_annunExtPowr_AVAIL[1] > 0;
        public new bool PowerConnected => PMDG_777X_Data.ELEC_annunExtPowr_ON[0] > 0 || PMDG_777X_Data.ELEC_annunExtPowr_ON[1] > 0;
        public virtual bool BrakesSet => PMDG_777X_Data.BRAKES_ParkingBrakeLeverOn > 0;
        public virtual bool EquipChocks => PMDG_777X_Data.WheelChocksSet > 0;
        public virtual bool EquipPca => SimStore[PmdgConstants.VarEquipAirCond]?.GetNumber() > 0;
        public new bool ApuRunning => PMDG_777X_Data.APURunning > 0;
        public new bool ApuBleedOn => PMDG_777X_Data.AIR_annunAPUBleedAirOFF == 0 && PMDG_777X_Data.AIR_APUBleedAir_Sw_AUTO > 0;
        public new bool LightNav => PMDG_777X_Data.LTS_NAV_Sw_ON > 0;
        public new bool LightBeacon => PMDG_777X_Data.LTS_Beacon_Sw_ON > 0;

        public Pmdg777Aircraft(IAppResources appResources) : base(appResources)
        {
            EfbManager = new(appResources, this);
            DoorManager = new(this);
        }

        public static int CalcEventCode(int code)
        {
            return EventBase + code;
        }

        public static string GetEventName(int code)
        {
            return $"#{EventBase + code}";
        }

        public static DateTime GetTime(int delay = 5)
        {
            return DateTime.Now + TimeSpan.FromSeconds(delay);
        }

        protected override Task DoInit()
        {
            SimStore.AddVariable(PmdgConstants.VarSwitchMicIntCpt)?.OnReceived += OnMicIntSwitch;
            SimStore.AddVariable(PmdgConstants.VarSwitchMicIntFo)?.OnReceived += OnMicIntSwitch;
            SimStore.AddVariable(PmdgConstants.VarEquipAirCond);
            SimStore.AddVariable(PmdgConstants.VarEquipGpu);
            SimStore.AddVariable(PmdgConstants.VarAircraftPowered);

            SubRotorBrake = SimStore.AddEvent("ROTOR_BRAKE");
            SimStore.AddEvent(PmdgConstants.EvtToggleLightTest); //Light Test

            foreach (var door in DoorManager.Doors)
                SimStore.AddEvent($"#{EventBase + door.Value.EventCode}");
            foreach (var light in DoorManager.CargoLights.Values)
            {
                SimStore.AddVariable(light.GetVariable());
                SimStore.AddEvent(light.GetEvent());
            }

            GsxController.GetService(GsxServiceType.Boarding).OnStateChanged += OnBoardState;
            GsxController.GetService(GsxServiceType.Deboarding).OnStateChanged += OnDeboardState;
            GsxController.GetService(GsxServiceType.Catering).OnStateChanged += OnCateringState;

            return CommBus.RegisterCommBus("PlaneToTablet", BroadcastFlag.JS, EfbManager.OnCommBusEvent);
        }

        protected override Task DoStop()
        {
            SimStore[PmdgConstants.VarSwitchMicIntCpt]?.OnReceived -= OnMicIntSwitch;
            SimStore[PmdgConstants.VarSwitchMicIntFo]?.OnReceived -= OnMicIntSwitch;
            SimStore.Remove(PmdgConstants.VarSwitchMicIntCpt);
            SimStore.Remove(PmdgConstants.VarEquipAirCond);
            SimStore.Remove(PmdgConstants.VarEquipGpu);
            SimStore.Remove(PmdgConstants.VarAircraftPowered);

            SubRotorBrake?.Unsubscribe();

            foreach (var door in DoorManager.Doors)
                SimStore.Remove(GetEventName(door.Value.EventCode));
            foreach (var light in DoorManager.CargoLights.Values)
            {
                SimStore.Remove(light.GetVariable());
                SimStore.Remove(light.GetEvent());
            }

            GsxController.GetService(GsxServiceType.Boarding).OnStateChanged -= OnBoardState;
            GsxController.GetService(GsxServiceType.Deboarding).OnStateChanged -= OnDeboardState;
            GsxController.GetService(GsxServiceType.Catering).OnStateChanged -= OnCateringState;

            return CommBus.UnregisterCommBus("PlaneToTablet", BroadcastFlag.JS, EfbManager.OnCommBusEvent);
        }

        public override async Task RunInterval()
        {
            if (FirstRun)
            {
                DoorManager.InitDoors();
                FirstRun = false;
            }

            if ((!ReceivedDataValid || !EfbManager.IsConnected) && (AutomationState < AutomationState.TaxiOut || AutomationState > AutomationState.TaxiIn))
                await EfbManager.CheckConnection();
            else
            {
                await EfbManager.CheckEfb();
                await DoorManager.CheckDoors();
            }
        }

        public override async Task CheckConnection()
        {
            if (!GsxController.IsWalkaround && LastWalkaround)
                TimeNextDataToggle = GetTime();
            LastWalkaround = GsxController.IsWalkaround;

            if (ReceivedDataValid && !LastModuleState)
                EfbManager.TimeNextUpdateToggle = GetTime(FirstRun ? 10 : 5);
            LastModuleState = ReceivedDataValid;

            if (ReceivedDataValid && !EfbManager.IsConnected)
                await EfbManager.CheckConnection();
            else if (!ReceivedDataValid && Module != null && !GsxController.IsWalkaround && TimeNextDataToggle < DateTime.Now && (AutomationState < AutomationState.TaxiOut || AutomationState > AutomationState.TaxiIn))
            {
                Logger.Debug("Toggle Light Test to trigger ClientData Update");
                await SimStore[PmdgConstants.EvtToggleLightTest].WriteValue(0x00004000);
                await Task.Delay(250);
                await SimStore[PmdgConstants.EvtToggleLightTest].WriteValue(0x00002000);
                TimeNextDataToggle = GetTime();
            }
        }

        public override Task<bool> GetSettingAdvAutomation()
        {
            return Task.FromResult(false);
        }

        public override Task<bool> GetIsCargo()
        {
            return Task.FromResult(IsCargo);
        }

        public override Task<bool> GetHasFuelSync()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetCanSetPayload()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetHasFobSaveRestore()
        {
            return Task.FromResult(true);
        }

        public override Task<DisplayUnit> GetAircraftUnits()
        {
            return Task.FromResult(Module?.ReceivedDataValid == true && !IsWeightInKg ? DisplayUnit.LB : DisplayUnit.KG);
        }

        public override Task SetPayloadEmpty()
        {
            return EfbManager.SetPayloadEmpty();
        }

        public override Task SetFuelOnBoardKg(double fuelKg, double targetKg)
        {
            return EfbManager.SetFuelOnBoardKg(fuelKg);
        }

        public override Task SetCargoOnBoard(double cargoOnBoardKg, double cargoTargetKg)
        {
            return EfbManager.SetCargoOnBoard(cargoOnBoardKg);
        }

        public override Task SetPaxOnBoard(int paxOnBoard, double weightPerPaxKg, int paxTarget)
        {
            return EfbManager.SetPaxOnBoard(paxOnBoard);
        }

        public override async Task OnAutomationStateChange(AutomationState state)
        {
            if (state == AutomationState.SessionStart)
            {
                if (DoorManager.HasOpenDoors())
                {
                    await DoorManager.DoorsAllClose();
                    await DoorDisarmAll();
                }
            }
            if (state == AutomationState.Preparation)
            {
                await DoorDisarmAll();
                if (GsxController.HasGateJetway && GsxController.JetwayState == GsxServiceState.Active)
                {
                    if (DoorManager.GetDoor(GsxDoor.PaxDoor2).IsMoving)
                        await Task.Delay(5000, Token);
                    await DoorManager.OnJetwayStateChange(GsxServiceState.Active, ISettingProfile.DoorPaxHandling);
                }
            }
            else if (state == AutomationState.Departure || state == AutomationState.Arrival)
            {
                await DoorDisarmAll();
            }
            else if (state == AutomationState.TaxiOut)
            {
                await DoorArmAll();
            }
            else if (state == AutomationState.Flight)
            {
                EfbManager.ResetFlight();
            }
            else if (state == AutomationState.TurnAround)
            {
                await DoorDisarmAll();
            }
        }

        public override Task PushStateChange(GsxServiceState state)
        {
            if (state == GsxServiceState.Active)
                return DoorArmAll();
            else
                return Task.CompletedTask;
        }

        public override Task PushOperationChange(int status)
        {
            if (status >= 1 && status <= 4)
                return DoorArmAll();
            else
                return Task.CompletedTask;
        }

        protected virtual Task OnMicIntSwitch(ISimResourceSubscription sub, object data)
        {
            if (sub.GetNumber() == 100)
            {
                Logger.Debug($"Received MicInt Trigger");
                MicIntSwitchTriggered = true;
            }

            return Task.CompletedTask;
        }

        public override Task<bool> GetSmartButtonRequest()
        {
            return Task.FromResult(MicIntSwitchTriggered);
        }

        public override Task ResetSmartButton()
        {
            MicIntSwitchTriggered = false;
            return Task.CompletedTask;
        }

        public virtual Task DoorArmAll()
        {
            if (!DoorArmTarget || DoorManager.HasUnarmedDoors())
            {
                Logger.Debug($"Arm Doors");
                DoorArmTarget = true;
                return EfbManager.SendRequest("arm_all", "doors");
            }

            return Task.CompletedTask;
        }

        public virtual Task DoorDisarmAll()
        {
            if (DoorArmTarget || DoorManager.HasArmedDoors())
            {
                Logger.Debug($"Disarm Doors");
                DoorArmTarget = false;
                return EfbManager.SendRequest("disarm_all", "doors");
            }

            return Task.CompletedTask;
        }

        public override Task<bool> GetHasOpenDoors()
        {
            return Task.FromResult(DoorManager.HasOpenDoors());
        }

        public override Task DoorsAllClose()
        {
            if (DoorManager.HasOpenDoors())
            {
                Logger.Debug($"DoorsAllClose");
                return DoorManager.DoorsAllClose();
            }
            else
                return Task.CompletedTask;
        }

        public override Task SetCargoDoors(bool state, bool force = false)
        {
            return DoorManager.SetCargoDoors(state, force);
        }

        public override Task OnDoorTrigger(GsxDoor door, bool trigger)
        {
            return DoorManager.OnDoorTrigger(door, trigger);
        }

        public override Task OnLoaderAttached(GsxDoor door, bool attached)
        {
            return DoorManager.OnLoaderAttached(door, attached);
        }

        public override Task OnJetwayStateChange(GsxServiceState state, bool paxDoorAllowed)
        {
            return DoorManager.OnJetwayStateChange(state, paxDoorAllowed);
        }

        public override Task OnStairStateChange(GsxServiceState state, bool paxDoorAllowed)
        {
            return DoorManager.OnStairStateChange(state, paxDoorAllowed);
        }

        public override Task OnStairOperationChange(GsxServiceState state, bool paxDoorAllowed)
        {
            if (state == GsxServiceState.Completing)
                return DoorManager.OnStairStateChange(GsxServiceState.Requested, paxDoorAllowed);
            else
                return Task.CompletedTask;
        }

        protected virtual Task OnBoardState(IGsxService boardService)
        {
            return DoorManager.OnBoardState(boardService);
        }

        protected virtual Task OnDeboardState(IGsxService deboardService)
        {
            return DoorManager.OnDeboardState(deboardService);
        }

        protected virtual Task OnCateringState(IGsxService cateringService)
        {
            return DoorManager.OnCateringState(cateringService);
        }

        protected virtual bool IsAvionicsPowered()
        {
            return AvionicsPowered || ApuRunning || PowerConnected || Engine1 || Engine2;
        }

        public override Task<bool> GetAvionicPowered()
        {
            return Task.FromResult(IsAvionicsPowered());
        }

        public override Task<bool> GetExternalPowerAvailable()
        {
            if (!EfbManager.CheckGpuType() && !PowerConnected)
                return Task.FromResult(false);

            return Task.FromResult(PowerAvailable || PowerConnected || EfbManager?.CheckExternalConnected() == true);
        }

        public override Task<bool> GetExternalPowerConnected()
        {
            return Task.FromResult(PowerConnected);
        }

        public override Task<bool> GetHasGpuInternal()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetGpuRequireChocks()
        {
            return Task.FromResult(true);
        }

        public override async Task SetEquipmentPower(bool state, bool force = false)
        {
            if ((!state && !force && PowerConnected) || !IsConnected)
                return;

            if (!PowerConnected && state && !EfbManager.CheckGpuType())
            {
                if (PowerAvailable)
                {
                    await EfbManager.ToggleGpu();
                    await Task.Delay(150);
                }

                if (!await EfbManager.CycleGpu())
                {
                    Logger.Debug($"GPU Type not found after {Pmdg777EfbManager.GpuMaxAttempts} Attempts");
                    await EfbManager.ToggleGpu();
                }
            }
            else if (!PowerConnected && ((state && !PowerAvailable) || (!state && PowerAvailable)))
            {
                await EfbManager.ToggleGpu();
            }
            else if (!state && PowerConnected && force)
            {
                await EfbManager.ToggleGpu();
            }
        }

        public override Task<bool> GetHasChocks()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetEquipmentChocks()
        {
            return Task.FromResult(EquipChocks);
        }

        public override Task<bool> GetBrakeSet()
        {
            return Task.FromResult(BrakesSet);
        }

        public override Task SetEquipmentChocks(bool state, bool force = false)
        {
            if (!state && !force && !BrakesSet)
                return Task.CompletedTask;

            if (PowerAvailable)
                return Task.CompletedTask;

            if ((state && EquipChocks) || (!state && !EquipChocks))
                return Task.CompletedTask;

            return EfbManager.SendRequest("wheel_chocks", "ground_conn");
        }

        public override Task<bool> GetApuRunning()
        {
            return Task.FromResult(ApuRunning);
        }

        public override Task<bool> GetApuBleedOn()
        {
            return Task.FromResult(ApuRunning && ApuBleedOn);
        }

        public override Task<bool> GetHasPca()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetEquipmentPca()
        {
            return Task.FromResult(EquipPca);
        }

        public override Task SetEquipmentPca(bool state, bool force = false)
        {
            if (!state && !force && !ApuRunning && !ApuBleedOn)
                return Task.CompletedTask;

            if ((state && EquipPca) || (!state && !EquipPca))
                return Task.CompletedTask;

            return EfbManager.SendRequest("air_cond_unit", "ground_conn");
        }

        public override Task<bool> GetLightNav()
        {
            return Task.FromResult(IsAvionicsPowered() && LightNav);
        }

        public override Task<bool> GetLightBeacon()
        {
            return Task.FromResult(IsAvionicsPowered() && LightBeacon);
        }

        public override Task<bool> GetReadyDepartureServices()
        {
            return Task.FromResult(IsAvionicsPowered() && EfbManager.HasEfbImportedFlightPlan);
        }

        public override Task OnFlightplanUnload()
        {
            EfbManager.HasEfbImportedFlightPlan = false;
            EfbManager.WasEfbFlightPlanSynced = true;
            return Task.CompletedTask;
        }
    }
}
