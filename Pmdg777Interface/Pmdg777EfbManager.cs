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
        public static string DefaultRequestFormat { get; } = "{{\"data\":{{\"{0}\":1}},\"message_tag\":\"{1}\",\"tablet_side\":\"{2}\"}}";

        public virtual async Task CheckEfb()
        {
            if (SettingProfile.HasSetting<bool>(PmdgSettings.OptionClearVehicles, out bool clearVehicles) && clearVehicles)
                await CheckVehicles();
        }

        public virtual void ResetState()
        {
            HasEfbImportedFlightPlan = false;
        }

        public virtual async Task CheckConnection()
        {
            if (!IsConnected && !IsRequestPending)
                await ToggleEfbUpdate();
        }

        protected virtual async Task CheckVehicles()
        {
            if (IsRequestPending || !(AutomationState == AutomationState.SessionStart
                || AutomationState == AutomationState.Preparation
                || AutomationState == AutomationState.Departure
                || AutomationState == AutomationState.Arrival
                || AutomationState == AutomationState.TurnAround))
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

        protected virtual async Task CheckVehicle(string vehicle)
        {
            if (EfbData.vehicles.HasProperty<string>($"{vehicle}_state", out string vehicleText))
            {
                if (CheckTextConnected(vehicleText))
                    await ToggleVehicle(vehicle);
            }
        }

        public virtual bool CheckExternalConnected()
        {
            return CheckTextConnected(EfbData.ground_conn.ground_power_state);
        }

        public static bool CheckTextConnected(string text)
        {
            return text == "RELEASE" || text == "CONNECTING";
        }

        public virtual async Task SendPayloadData(JsonObject data)
        {
            await SendToPlane("{\"message_tag\":\"wb_payload\",\"data\":" + data.ToJsonString() + ",\"tablet_side\":\"CA\"}");
        }

        public virtual async Task SetPayloadEmpty()
        {
            JsonObject payloadData = new()
            {
                ["overall_load_level_percent"] = 0
            };
            await SendPayloadData(payloadData);
        }

        public virtual async Task SetFuelOnBoardKg(double fuelKg)
        {
            int fuel = (int)AppResources.WeightConverter.ToLb(fuelKg);
            var payloadData = new JsonObject()
            {
                ["fuel_total_lbs"] = fuel
            };
            await SendPayloadData(payloadData);
        }

        public virtual async Task SetPaxOnBoard(int paxOnBoard)
        {
            var payloadData = new JsonObject()
            {
                ["pax_count_total"] = paxOnBoard
            };
            await SendPayloadData(payloadData);
        }

        public virtual async Task SetCargoOnBoard(double cargoOnBoardKg)
        {
            int cargo = (int)AppResources.WeightConverter.ToLb(cargoOnBoardKg);
            var payloadData = new JsonObject()
            {
                ["cargo_weight_total"] = cargo
            };
            await SendPayloadData(payloadData);
        }

        public virtual bool? CheckGpuType()
        {
            if (!IsConnected)
                return null;

            if (SettingProfile.HasSetting<bool>(PmdgSettings.OptionChangePowerType, out bool checkPower) && !checkPower)
                return true;

            if (GsxController.HasGateJetway && EfbData.ground_conn.ground_power_type != "DUAL JETWAY PLUGS")
                return false;
            if (!GsxController.HasGateJetway && EfbData.ground_conn.ground_power_type != "DUAL GPU PLUGS")
                return false;

            return true;
        }

        public virtual async Task ToggleVehicle(string vehicle)
        {
            await SendRequest(vehicle, "ground_vehicles");
            IsRequestPending = true;
        }

        public virtual void OnCommBusEvent(string @event, string data)
        {
            try
            {
                if (@event == "PlaneToTablet")
                {
                    JsonNode node = JsonNode.Parse(data);
                    //Logger.Debug($"PlaneToTablet: {data}");
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
                        }
                        else
                            Logger.Debug($"Received unknown PlaneToTablet Event: {data}");
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

        public virtual async Task SendToPlane(string data)
        {
            Logger.Verbose($"Sending to Plane: {data}");
            await CommBus.SendCommBus("TabletToPlane", data, BroadcastFlag.WASM);
        }

        public virtual async Task SendRequest(string request, string tag, string side = "CA")
        {
            await SendToPlane(string.Format(DefaultRequestFormat, request, tag, side));
        }

        public virtual async Task ToggleEfbUpdate()
        {
            Logger.Debug($"Toggle EFB Update");
            await SendToPlane("{\"message_tag\":\"query_state\",\"data\":{\"request\":\"yes\"},\"tablet_side\":\"CA\"}");
        }

        public virtual async Task ChangeGroundPowerType()
        {
            await SendRequest("ground_power_type", "ground_conn");
            IsRequestPending = true;
        }
    }
}
