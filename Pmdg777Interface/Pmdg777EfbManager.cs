using Any2GSX.PluginInterface.Interfaces;
using CFIT.AppLogger;
using CFIT.AppTools;
using System;
using System.Text.Json.Nodes;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777EfbManager(IAppResources appResources, Pmdg777Aircraft aircraft)
    {
        public virtual IAppResources AppResources { get; } = appResources;
        public virtual ISettingProfile SettingProfile => AppResources.ISettingProfile;
        public virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        public virtual ICommBus CommBus => AppResources.ICommBus;
        public virtual IGsxController GsxController => AppResources.IGsxController;
        public virtual AutomationState AutomationState => GsxController.IAutomationController.State;
        public virtual Pmdg777EfbData EfbData { get; protected set; } = new();
        public virtual bool IsConnected => EfbData?.ground_conn != null && EfbData?.autocruise != null;
        public virtual bool IsRequestPending { get; set; } = false;
        public virtual bool HasEfbImportedFlightPlan { get; set; } = false;
        public virtual bool WasEfbFlightPlanSynced { get; set; } = true;
        public static string DefaultRequestFormat { get; } = "{{\"data\":{{\"{0}\":1}},\"message_tag\":\"{1}\",\"tablet_side\":\"{2}\"}}";
        public virtual DateTime TimeNextUpdateToggle { get; set; } = DateTime.MaxValue;
        public virtual int GpuSetAttempts { get; set; } = 0;
        public const int GpuMaxAttempts = 10;

        public virtual async Task CheckEfb()
        {
            if (SettingProfile.GetSetting(PmdgSettings.ClearVehicles))
                await CheckVehicles();

            if (HasEfbImportedFlightPlan && !WasEfbFlightPlanSynced && !Aircraft.Flightplan.IsLoaded
                && AutomationState < AutomationState.Pushback && AutomationState > AutomationState.TaxiIn)
            {
                Logger.Debug($"Trigger OFP Import in App");
                await Aircraft.Flightplan.ImportOfp();
            }
            WasEfbFlightPlanSynced = true;
        }

        public virtual void ResetFlight()
        {
            WasEfbFlightPlanSynced = true;
        }

        public virtual async Task CheckConnection()
        {
            if (!IsConnected && !IsRequestPending && !GsxController.IsWalkaround && TimeNextUpdateToggle < DateTime.Now)
            {
                await ToggleEfbUpdate();
                TimeNextUpdateToggle = Pmdg777Aircraft.GetTime();
            }
            else if (IsConnected)
                TimeNextUpdateToggle = DateTime.MinValue;
        }

        protected virtual async Task CheckVehicles()
        {
            if (IsRequestPending || !Aircraft.DoorManager.IsStateValid)
                return;

            if (EfbData?.vehicles != null && IsConnected && !IsRequestPending)
            {
                await CheckVehicle("aft_cargo");
                await CheckVehicle("aft_galley");
                await CheckVehicle("bulk_cargo");
                await CheckVehicle("cabin_cleaning");
                await CheckVehicle("fuel_truck");
                await CheckVehicle("fwd_cargo");
                await CheckVehicle("fwd_galley");
                await CheckVehicle("lavatory_service");
                await CheckVehicle("maintenance_van");
                await CheckVehicle("potable_water");
                await CheckVehicle("stairs_1l");
                await CheckVehicle("stairs_2l");
            }
        }

        protected virtual Task CheckVehicle(string vehicle)
        {
            if (EfbData?.vehicles?.HasProperty<string>($"{vehicle}_state", out string vehicleText) == true)
            {
                if (CheckTextConnected(vehicleText))
                    return ToggleVehicle(vehicle);
            }

            return Task.CompletedTask;
        }

        public virtual bool CheckExternalConnected()
        {
            return CheckTextConnected(EfbData?.ground_conn?.ground_power_state);
        }

        public static bool CheckTextConnected(string text)
        {
            return text?.Contains("RELEASE", StringComparison.InvariantCultureIgnoreCase) == true || text?.Contains("CONNECTING", StringComparison.InvariantCultureIgnoreCase) == true;
        }

        public virtual Task SendPayloadData(JsonObject data)
        {
            return SendToPlane("{\"message_tag\":\"wb_payload\",\"data\":" + data.ToJsonString() + ",\"tablet_side\":\"CA\"}");
        }

        public virtual Task SetPayloadEmpty()
        {
            JsonObject payloadData = new()
            {
                ["overall_load_level_percent"] = 0
            };
            return SendPayloadData(payloadData);
        }

        public virtual Task SetFuelOnBoardKg(double fuelKg)
        {
            int fuel = (int)AppResources.WeightConverter.ToLb(fuelKg);
            var payloadData = new JsonObject()
            {
                ["fuel_total_lbs"] = fuel
            };
            return SendPayloadData(payloadData);
        }

        public virtual Task SetPaxOnBoard(int paxOnBoard)
        {
            var payloadData = new JsonObject()
            {
                ["pax_count_total"] = paxOnBoard
            };
            return SendPayloadData(payloadData);
        }

        public virtual Task SetCargoOnBoard(double cargoOnBoardKg)
        {
            int cargo = (int)AppResources.WeightConverter.ToLb(cargoOnBoardKg);
            var payloadData = new JsonObject()
            {
                ["cargo_weight_total"] = cargo
            };
            return SendPayloadData(payloadData);
        }

        public virtual bool CheckGpuType()
        {
            if (!IsConnected)
                return false;

            if (!SettingProfile.GetSetting(PmdgSettings.ChangePowerType))
                return true;

            if (GsxController.HasGateJetway && EfbData.IsGpuDual && EfbData.IsGpuJetway)
                return true;
            if (!GsxController.HasGateJetway && EfbData.IsGpuDual && EfbData.IsGpuCart)
                return true;

            return GpuSetAttempts >= GpuMaxAttempts;
        }

        public virtual async Task<bool> CycleGpu()
        {
            if (!SettingProfile.GetSetting(PmdgSettings.ChangePowerType))
                return false;

            await SendRequest("ground_power_type", "ground_conn");
            GpuSetAttempts++;
            return GpuSetAttempts < GpuMaxAttempts;
        }

        public virtual Task ToggleGpu()
        {
            return SendRequest("ground_power", "ground_conn");
        }

        public virtual Task ToggleVehicle(string vehicle)
        {
            IsRequestPending = true;
            return SendRequest(vehicle, "ground_vehicles");
        }

        public virtual void OnCommBusEvent(string @event, string data)
        {
            try
            {
                if (@event == "PlaneToTablet")
                {
                    JsonNode node = JsonNode.Parse(data);
                    if (Aircraft.Config.LogLevel == LogLevel.Verbose)
                        Logger.Verbose($"PlaneToTablet: {data}");
                    bool hasTag = node["message_tag"] != null;
                    if (hasTag && node["autocruise"] != null)
                    {
                        bool last = IsConnected;
                        EfbData = Pmdg777EfbData.Serialize(data);
                        if (IsConnected && !last)
                            Logger.Debug("Received first EFB Data");
                        IsRequestPending = false;
                    }
                    else if (hasTag)
                    {
                        if ((node["message_tag"]!.ToString() == "ping" || node["message_tag"]!.ToString() == "ping_ok"))
                            Logger.Verbose($"Received Plane Ping");
                        else if (node["message_tag"]!.ToString() == "simbrief_fetch_result" && node["data"]!["result"]!.ToString() == "200")
                        {
                            Logger.Debug("EFB has imported Flightplan!");
                            HasEfbImportedFlightPlan = true;
                            WasEfbFlightPlanSynced = false;
                        }
                        else
                            Logger.Verbose($"Received unknown PlaneToTablet Event: {data}");
                    }
                    else
                    {
                        Logger.Debug($"Received unknown PlaneToTablet Event (no Tag!): {data}");
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.LogException(ex);
            }
        }

        public virtual Task SendToPlane(string data)
        {
            Logger.Verbose($"Sending to Plane: {data}");
            return CommBus.SendCommBus("TabletToPlane", data, BroadcastFlag.WASM);
        }

        public virtual Task SendRequest(string request, string tag, string side = "CA")
        {
            return SendToPlane(string.Format(DefaultRequestFormat, request, tag, side));
        }

        public virtual Task ToggleEfbUpdate()
        {
            Logger.Debug($"Toggle EFB Update");
            return SendToPlane("{\"message_tag\":\"query_state\",\"data\":{\"request\":\"yes\"},\"tablet_side\":\"CA\"}");
        }

        public virtual Task ChangeGroundPowerType()
        {
            IsRequestPending = true;
            return SendRequest("ground_power_type", "ground_conn");
        }
    }
}
