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
        public override bool IsConnected => Module?.ReceivedDataValid == true && EfbManager?.IsConnected == true;
        public virtual Pmdg777Plugin Plugin => AppPlugin.Instance as Pmdg777Plugin;
        public virtual Pmdg777Module Module => Plugin?.SimConnectModule as Pmdg777Module;
        public virtual Pmdg777EfbManager EfbManager { get; }
        public virtual Pmdg777Cdu CDU { get; }
        public virtual Pmdg777DoorManager DoorManager { get; }
        public virtual PMDG_777X_Data PMDG_777X_Data => Module.PMDG_777X_Data;
        public virtual bool WeightInKg => PMDG_777X_Data.WeightInKg != 0;
        public override DisplayUnit UnitAircraft => Module?.ReceivedDataValid == true && !WeightInKg ? DisplayUnit.LB : DisplayUnit.KG;
        public virtual ISimResourceSubscription SubRotorBrake { get; protected set; }
        public virtual ISimResourceSubscription SubDoorMainCargo { get; protected set; }
        public virtual AutomationState AutomationState => GsxController.IAutomationController.State;
        public virtual bool DoorArmTarget { get; protected set; } = true;
        protected virtual bool MicIntSwitchTriggered { get; set; } = false;
        protected virtual bool ResetPayloadDone { get; set; } = false;
        protected virtual bool FirstRun { get; set; } = true;
        protected virtual bool ApplyCrewToCargo { get; set; } = false;

        public Pmdg777Aircraft(IAppResources appResources) : base(appResources)
        {
            EfbManager = new(appResources, this);
            CDU = new(this);
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

        protected override async Task DoInit()
        {
            SimStore.AddVariable(PmdgConstants.VarSwitchMicIntCpt).OnReceived += OnMicIntSwitch;
            SimStore.AddVariable(PmdgConstants.VarSwitchMicIntFo).OnReceived += OnMicIntSwitch;
            SimStore.AddVariable(PmdgConstants.VarEquipAirCond);
            SimStore.AddVariable(PmdgConstants.VarEquipGpu);
            SimStore.AddVariable(PmdgConstants.VarAircraftPowered);
            SubDoorMainCargo = SimStore.AddVariable(PmdgConstants.VarDoorMain);
            SubDoorMainCargo.OnReceived += DoorManager.OnDoorMainCargo;

            SimStore.AddVariable(PmdgConstants.VarGsxAutoEquip);
            SimStore.AddVariable(PmdgConstants.VarGsxAutoDoors);
            SimStore.AddVariable(PmdgConstants.VarGsxAutoFuel);
            SimStore.AddVariable(PmdgConstants.VarGsxAutoPayload);
            SimStore.AddVariable(PmdgConstants.VarGsxReadProgFuel);
            SimStore.AddVariable(PmdgConstants.VarGsxSetProgFuel);
            SimStore.AddVariable(PmdgConstants.VarGsxReadCustFuel);
            SimStore.AddVariable(PmdgConstants.VarGsxSetCustFuel);

            SubRotorBrake = SimStore.AddEvent("ROTOR_BRAKE");

            foreach (var door in DoorManager.Doors)
                SimStore.AddEvent($"#{Pmdg777Aircraft.EventBase + door.Value.EventCode}");
            foreach (var light in DoorManager.CargoLights)
            {
                SimStore.AddVariable($"L:switch_{(int)light}_a");
                SimStore.AddEvent(GetEventName((int)light));
            }

            GsxController.GetService(GsxServiceType.Boarding).OnStateChanged += OnBoardState;
            GsxController.GetService(GsxServiceType.Deboarding).OnStateChanged += OnDeboardState;

            await CommBus.RegisterCommBus("PlaneToTablet", BroadcastFlag.JS, EfbManager.OnCommBusEvent);
        }

        protected override async Task DoStop()
        {
            SimStore[PmdgConstants.VarSwitchMicIntCpt].OnReceived -= OnMicIntSwitch;
            SimStore[PmdgConstants.VarSwitchMicIntFo].OnReceived -= OnMicIntSwitch;
            SimStore.Remove(PmdgConstants.VarSwitchMicIntCpt);
            SimStore.Remove(PmdgConstants.VarEquipAirCond);
            SimStore.Remove(PmdgConstants.VarEquipGpu);
            SimStore.Remove(PmdgConstants.VarAircraftPowered);

            SubDoorMainCargo.OnReceived -= DoorManager.OnDoorMainCargo;
            SubDoorMainCargo.Unsubscribe();

            SimStore.Remove(PmdgConstants.VarGsxAutoEquip);
            SimStore.Remove(PmdgConstants.VarGsxAutoDoors);
            SimStore.Remove(PmdgConstants.VarGsxAutoFuel);
            SimStore.Remove(PmdgConstants.VarGsxAutoPayload);
            SimStore.Remove(PmdgConstants.VarGsxReadProgFuel);
            SimStore.Remove(PmdgConstants.VarGsxSetProgFuel);
            SimStore.Remove(PmdgConstants.VarGsxReadCustFuel);
            SimStore.Remove(PmdgConstants.VarGsxSetCustFuel);

            SubRotorBrake?.Unsubscribe();

            foreach (var door in DoorManager.Doors)
                SimStore.Remove(GetEventName(door.Value.EventCode));
            foreach (var light in DoorManager.CargoLights)
            {
                SimStore.Remove($"L:switch_{(int)light}_a");
                SimStore.Remove(GetEventName((int)light));
            }

            GsxController.GetService(GsxServiceType.Boarding).OnStateChanged -= OnBoardState;
            GsxController.GetService(GsxServiceType.Deboarding).OnStateChanged -= OnDeboardState;

            await CommBus.UnregisterCommBus("PlaneToTablet", BroadcastFlag.JS, EfbManager.OnCommBusEvent);
        }

        public override async Task OnCouatlStarted()
        {
            var variable = SimStore[PmdgConstants.VarGsxAutoEquip];
            if (variable.GetNumber() != 0)
            {
                Logger.Debug($"Disabling GSX Automation ({variable.Name})");
                await variable.WriteValue(0);
            }

            variable = SimStore[PmdgConstants.VarGsxAutoDoors];
            if (variable.GetNumber() != 0)
            {
                Logger.Debug($"Disabling GSX Automation ({variable.Name})");
                await variable.WriteValue(0);
            }

            if (HasEfbWeightBalance())
            {
                variable = SimStore[PmdgConstants.VarGsxAutoFuel];
                if (variable.GetNumber() != 0)
                {
                    Logger.Debug($"Disabling GSX Automation ({variable.Name})");
                    await variable.WriteValue(0);
                }

                variable = SimStore[PmdgConstants.VarGsxAutoPayload];
                if (variable.GetNumber() != 0)
                {
                    Logger.Debug($"Disabling GSX Automation ({variable.Name})");
                    await variable.WriteValue(0);
                }

                variable = SimStore[PmdgConstants.VarGsxReadProgFuel];
                if (variable.GetNumber() > 0)
                {
                    Logger.Debug($"Resetting GSX Setting {PmdgConstants.VarGsxSetProgFuel}");
                    await SimStore[PmdgConstants.VarGsxSetProgFuel].WriteValue(-1);
                }

                variable = SimStore[PmdgConstants.VarGsxReadCustFuel];
                if (variable.GetNumber() > 0)
                {
                    Logger.Debug($"Resetting GSX Setting {PmdgConstants.VarGsxSetCustFuel}");
                    await SimStore[PmdgConstants.VarGsxSetCustFuel].WriteValue(-1);
                }
            }
        }

        public override async Task RunInterval()
        {
            if (FirstRun)
            {
                DoorManager.InitDoors();
                FirstRun = false;
            }

            await EfbManager.CheckEfb();
            await DoorManager.CheckDoors();
            await Task.Delay(25);
        }

        public override async Task CheckConnection()
        {
            if (Module.ReceivedDataValid)
                await EfbManager.CheckConnection();
        }

        protected override Task<bool> GetIsCargo()
        {
            return Task.FromResult(AircraftString.Contains("PMDG 777F", StringComparison.InvariantCultureIgnoreCase));
        }

        public override Task<bool> GetHasFuelSynch()
        {
            return Task.FromResult(HasEfbWeightBalance());
        }

        public override Task<bool> GetCanSetPayload()
        {
            return Task.FromResult(true);
        }

        public override Task<bool> GetHasFobSaveRestore()
        {
            return Task.FromResult(true);
        }

        public virtual bool HasEfbWeightBalance()
        {
            return true;
        }

        public override async Task SetPayloadEmpty()
        {
            try
            {
                while (!IsConnected && IsExecutionAllowed)
                    await Task.Delay(500, Token);

                if (HasEfbWeightBalance())
                    await EfbManager.SetPayloadEmpty();
                else
                    await CDU.SetPayloadEmpty();

                ResetPayloadDone = true;
            }
            catch (Exception ex)
            {
                if (ex is not TaskCanceledException)
                    Logger.LogException(ex);
            }
        }

        public override async Task SetFuelOnBoardKg(double fuelKg)
        {
            if (HasEfbWeightBalance())
                await EfbManager.SetFuelOnBoardKg(fuelKg);
            else
                await CDU.SetFuelOnBoardKg(fuelKg); 
        }

        public override async Task RefuelTick(double stepKg, double fuelOnBoardKg)
        {
            if (HasEfbWeightBalance())
                await EfbManager.SetFuelOnBoardKg(fuelOnBoardKg);
        }

        public override async Task BoardChangePax(int paxOnBoard, double weightPerPaxKg)
        {
            if (HasEfbWeightBalance())
                await EfbManager.SetPaxOnBoard(paxOnBoard);
        }

        public override async Task BoardCompleted(int paxTarget, double weightPerPaxKg, double cargoTargetKg)
        {
            await base.BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg);
            await BoardChangePax(paxTarget, weightPerPaxKg);
            await BoardChangeCargo(100, cargoTargetKg);
        }

        public override async Task DeboardCompleted()
        {
            await base.DeboardCompleted();
            await DeboardChangePax(0, Flightplan.CountPax, Flightplan.WeightPerPaxKg);
            await DeboardChangeCargo(0, 0);
        }

        public override Task SetCargoCrew(int paxOnBoard, double weightPerPaxKg)
        {
            base.SetCargoCrew(paxOnBoard, weightPerPaxKg);
            ApplyCrewToCargo = true;
            return Task.CompletedTask;
        }

        public override async Task DeboardChangePax(int paxOnBoard, int gsxTotal, double weightPerPaxKg)
        {
            if (HasEfbWeightBalance())
                await EfbManager.SetPaxOnBoard(paxOnBoard);
        }

        public override async Task BoardChangeCargo(int progressLoad, double cargoOnBoardKg)
        {
            if (HasEfbWeightBalance())
            {
                if (ApplyCrewToCargo)
                    cargoOnBoardKg += AppResources.IFlightplan.WeightPaxKg;
                await EfbManager.SetCargoOnBoard(cargoOnBoardKg);
            }
        }

        public override async Task DeboardChangeCargo(int progressUnload, double cargoOnBoardKg)
        {
            if (HasEfbWeightBalance())
                await EfbManager.SetCargoOnBoard(cargoOnBoardKg);
        }
        
        public override async Task OnAutomationStateChange(AutomationState state)
        {
            if (state == AutomationState.Preparation)
            {
                await DoorDisarmAll();
            }
            if (state == AutomationState.Departure || state == AutomationState.Arrival)
            {
                ApplyCrewToCargo = false;
                await DoorDisarmAll();
            }
            else if (state == AutomationState.TaxiOut)
            {
                await DoorArmAll();
            }
            else if (state == AutomationState.Flight)
            {
                DoorManager.SetAll(PmdgDoorState.ClosedArmed);
                ApplyCrewToCargo = false;
            }
            else if (state == AutomationState.TurnAround)
            {
                EfbManager.ResetState();
                ApplyCrewToCargo = false;
            }
        }

        public override async Task PushStateChange(GsxServiceState state)
        {
            if (state == GsxServiceState.Active)
                await DoorArmAll();
        }

        public override async Task PushOperationChange(int status)
        {
            if (GsxController.GetService(GsxServiceType.Pushback).State >= GsxServiceState.Requested &&  status > 1 && status <= 4)
                await DoorArmAll();
        }

        protected virtual void OnMicIntSwitch(ISimResourceSubscription sub, object data)
        {
            if (sub.GetNumber() == 100)
                MicIntSwitchTriggered = true;
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

        protected virtual async Task DoorArmAll()
        {
            if (!DoorArmTarget || DoorManager.HasUnarmedDoors())
            {
                Logger.Debug($"Arm Doors");
                await EfbManager.SendRequest("arm_all", "doors");
                DoorArmTarget = true;
                DoorManager.ArmAll();
            }
        }

        protected virtual async Task DoorDisarmAll()
        {
            if (DoorArmTarget)
            {
                Logger.Debug($"Disarm Doors");
                await EfbManager.SendRequest("disarm_all", "doors");
                DoorArmTarget = false;
                DoorManager.DisarmAll();
            }
        }

        protected override Task<bool> GetHasOpenDoors()
        {
            foreach (var door in PMDG_777X_Data.DOOR_state)
            {
                if (door == 0 || door == 4)
                    return Task.FromResult(true);
            }

            return Task.FromResult(false);
        }

        public override async Task DoorsAllClose()
        {
            Logger.Debug($"DoorsAllClose");
            await EfbManager.SendRequest("close_all", "doors");
            DoorManager.SetAll(PmdgDoorState.Closed);
        }

        public override Task OnDoorTrigger(GsxDoor door, bool trigger)
        {
            DoorManager.OnDoorTrigger(door, trigger);
            return Task.CompletedTask;
        }

        public override Task OnJetwayChange(GsxServiceState state)
        {;
            DoorManager.OnJetwayChange(state);
            return Task.CompletedTask;
        }

        public override Task OnStairChange(GsxServiceState state)
        {
            DoorManager.OnStairChange(state);
            return Task.CompletedTask;
        }

        protected virtual Task OnBoardState(IGsxService boardService)
        {
            DoorManager.OnBoardState(boardService);
            return Task.CompletedTask;
        }

        protected virtual Task OnDeboardState(IGsxService deboardService)
        {
            DoorManager.OnDeboardState(deboardService);
            return Task.CompletedTask;
        }

        protected override Task<bool> GetAvionicPowered()
        {
            return Task.FromResult(SimStore[PmdgConstants.VarAircraftPowered]?.GetNumber() > 0);
        }

        protected override Task<bool> GetExternalPowerAvailable()
        {
            bool powerConnected = GetExternalPowerConnected().Result;
            if (EfbManager.CheckGpuType() == false && !powerConnected)
                return Task.FromResult(false);

            return Task.FromResult(GetExternalPowerAvailableRaw() || powerConnected || EfbManager.CheckExternalConnected());
        }

        protected virtual bool GetExternalPowerAvailableRaw()
        {
            return PMDG_777X_Data.ELEC_annunExtPowr_AVAIL[0] > 0 || PMDG_777X_Data.ELEC_annunExtPowr_AVAIL[1] > 0;
        }

        protected override Task<bool> GetExternalPowerConnected()
        {
            return Task.FromResult(PMDG_777X_Data.ELEC_annunExtPowr_ON[0] > 0 || PMDG_777X_Data.ELEC_annunExtPowr_ON[1] > 0);
        }

        public override Task<bool> GetHasGpuInternal()
        {
            return Task.FromResult(true);
        }

        public override async Task SetEquipmentPower(bool state, bool force = false)
        {
            bool connected = GetExternalPowerConnected().Result;
            if (!state && !force && connected)
                return;

            bool? result = EfbManager.CheckGpuType();            
            bool avail = GetExternalPowerAvailableRaw();
            if (AutomationState == AutomationState.Preparation && result == false)
            {
                if (!connected && avail)
                    await EfbManager.SendRequest("ground_power", "ground_conn");
                if (!EfbManager.IsRequestPending)
                    await EfbManager.SendRequest("ground_power_type", "ground_conn");
            }
            else if ((state && avail) || (!state && !avail))
                return;
            
            if (result == true || force)
                await EfbManager.SendRequest("ground_power", "ground_conn");
        }

        public override Task<bool> GetHasChocks()
        {
            return Task.FromResult(true);
        }

        protected override Task<bool> GetEquipmentChocks()
        {
            return Task.FromResult(PMDG_777X_Data.WheelChocksSet > 0);
        }

        protected override Task<bool> GetBrakeSet()
        {
            return Task.FromResult(PMDG_777X_Data.BRAKES_ParkingBrakeLeverOn > 0);
        }

        public override async Task SetEquipmentChocks(bool state, bool force = false)
        {
            if (!state && !force && !GetBrakeSet().Result)
                return;

            if (GetExternalPowerAvailable().Result)
                return;

            if ((state && GetEquipmentChocks().Result) || (!state && !GetEquipmentChocks().Result))
                return;

            await EfbManager.SendRequest("wheel_chocks", "ground_conn");
        }

        protected override Task<bool> GetApuRunning()
        {
            return Task.FromResult(PMDG_777X_Data.APURunning > 0);
        }

        protected override Task<bool> GetApuBleedOn()
        {
            return Task.FromResult(PMDG_777X_Data.AIR_annunAPUBleedAirOFF == 0 && PMDG_777X_Data.AIR_APUBleedAir_Sw_AUTO > 0);
        }

        public override Task<bool> GetHasPca()
        {
            return Task.FromResult(true);
        }

        protected override Task<bool> GetEquipmentPca()
        {
            return Task.FromResult(SimStore[PmdgConstants.VarEquipAirCond]?.GetNumber() > 0);
        }

        public override async Task SetEquipmentPca(bool state, bool force = false)
        {
            if (!state && !force && !GetApuRunning().Result && !GetApuBleedOn().Result)
                return;

            if ((state && GetEquipmentPca().Result) || (!state && !GetEquipmentPca().Result))
                return;

            await EfbManager.SendRequest("air_cond_unit", "ground_conn");
        }

        protected override Task<bool> GetLightNav()
        {
            return Task.FromResult(PMDG_777X_Data.LTS_NAV_Sw_ON > 0);
        }

        protected override Task<bool> GetLightBeacon()
        {
            return Task.FromResult(PMDG_777X_Data.LTS_Beacon_Sw_ON > 0);
        }

        protected override Task<bool> GetReadyDepartureServices()
        {
            return Task.FromResult(GetReadyDepartureServicesRaw() && ResetPayloadDone);
        }

        protected virtual bool GetReadyDepartureServicesRaw()
        {
            if (HasEfbWeightBalance())
                return GetAvionicPowered().Result && EfbManager.HasEfbImportedFlightPlan;
            else
                return GetAvionicPowered().Result && PMDG_777X_Data.ELEC_CabUtilSw > 0;
        }
    }
}
