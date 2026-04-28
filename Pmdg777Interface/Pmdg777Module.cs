using CFIT.AppLogger;
using CFIT.SimConnectLib;
using CFIT.SimConnectLib.Modules;
using Microsoft.FlightSimulator.SimConnect;
using System;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777Module(SimConnectManager manager, object moduleParams, bool wasRegisteredBefore) : SimConnectModule(manager, moduleParams, wasRegisteredBefore)
    {
        protected virtual bool ClientDataAreaCreated { get; set; } = false;
        public virtual bool ReceivedDataValid { get; protected set; } = false;
        protected virtual bool FirstReceive { get; set; } = true;
        public virtual PMDG_777X_Data PMDG_777X_Data { get; protected set; } = new();

        protected override void SetModuleParams(object moduleParams)
        {

        }

        public override Task<int> CheckResources()
        {
            return Task.FromResult(0);
        }

        public override Task CheckState()
        {
            return Task.CompletedTask;
        }

        public override Task ClearUnusedResources(bool clearAll)
        {
            return Task.CompletedTask;
        }

        public override void RegisterModule()
        {
            Manager.OnOpen += OnOpen;
        }

        public override Task OnOpen(SIMCONNECT_RECV_OPEN evtData)
        {
            Manager.OnClientData += OnClientData;
            return CreateDataAreaDefaultChannel();
        }

        public override Task UnregisterModule(bool disconnect)
        {
            if (disconnect && Manager.IsReceiveRunning)
            {
                Manager.OnClientData -= OnClientData;
                return Call(sc => sc.RequestClientData(PMDG_777X_ID.PMDG_777X_DATA_ID,
                            PMDG_777X_ID.DATA_REQUEST,
                            PMDG_777X_ID.PMDG_777X_DATA_DEFINITION,
                            SIMCONNECT_CLIENT_DATA_PERIOD.NEVER,
                            SIMCONNECT_CLIENT_DATA_REQUEST_FLAG.DEFAULT,
                            0,
                            0,
                            0));
            }
            else
                return Task.CompletedTask;
        }

        protected virtual async Task CreateDataAreaDefaultChannel()
        {
            //DATA
            if (!ClientDataAreaCreated && !WasRegisteredBefore)
            {
                await Call(sc => sc.MapClientDataNameToID("PMDG_777X_Data", PMDG_777X_ID.PMDG_777X_DATA_ID));

                await Call(sc => sc.AddToClientDataDefinition(PMDG_777X_ID.PMDG_777X_DATA_DEFINITION, 0, (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(PMDG_777X_Data)), 0, 0));
            }

            await Call(sc => sc.RegisterStruct<SIMCONNECT_RECV_CLIENT_DATA, PMDG_777X_Data>(PMDG_777X_ID.PMDG_777X_DATA_DEFINITION));

            await Call(sc => sc.RequestClientData(PMDG_777X_ID.PMDG_777X_DATA_ID,
                        PMDG_777X_ID.DATA_REQUEST,
                        PMDG_777X_ID.PMDG_777X_DATA_DEFINITION,
                        SIMCONNECT_CLIENT_DATA_PERIOD.VISUAL_FRAME,
                        SIMCONNECT_CLIENT_DATA_REQUEST_FLAG.CHANGED,
                        0,
                        0,
                        0));

            ClientDataAreaCreated = true;
        }

        protected virtual Task OnClientData(SIMCONNECT_RECV_CLIENT_DATA evtData)
        {
            try
            {
                if (Manager.Config.VerboseLogging)
                    Logger.Verbose($"dwRequestID {evtData.dwRequestID} dwDefineID {evtData.dwDefineID} dwentrynumber {evtData.dwentrynumber} dwObjectID {evtData.dwObjectID} dwID {evtData.dwID}");


                if (evtData.dwRequestID == (uint)PMDG_777X_ID.DATA_REQUEST && evtData?.dwData?.Length > 0)
                {
                    PMDG_777X_Data = (PMDG_777X_Data)(evtData.dwData[0]);
                    ReceivedDataValid = PMDG_777X_Data.AircraftModel > 0 || PMDG_777X_Data.FUEL_QtyLeft > 0;
                    if (FirstReceive)
                    {
                        if (!ReceivedDataValid)
                            Logger.Warning($"PMDG Broadcast Data not valid");
                        else
                            Logger.Debug($"Receiving PMDG Broadcast Data - AircraftModel: {PMDG_777X_Data.AircraftModel}");
                        FirstReceive = false;
                    }
                }
                else
                {
                    Logger.Verbose($"Received unknown Event! (dwID {evtData?.dwID} | dwDefineID {evtData?.dwDefineID} | dwRequestID {evtData?.dwRequestID} | dwData {evtData?.dwData[0]?.GetType().Name})");
                }
            }
            catch (Exception ex)
            {
                Logger.LogException(ex);
            }

            return Task.CompletedTask;
        }
    }
}
