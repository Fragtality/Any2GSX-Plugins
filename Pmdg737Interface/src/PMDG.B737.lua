UseVar("L:switch_752_73X", "Number")
UseVar("L:switch_868_73X", "Number")
UseVar("L:NGXWheelChocks", "Number")
UseVar("L:7X7X_AirCond_Door", "Number")
UseVar("L:7X7X_Refuel_Door", "Number")
UseVar("L:7X7X_Lav_Door", "Number")
UseVar("L:7X7X_Water_Door", "Number")
UseVar("L:AirStairs", "Number")
UseEvent("#70384")
UseEvent("#70500")
SubBus("PlaneToTablet", BroadcastFlag.JS, "OnPlaneToTablet")
SubBus("TabletToPlane", BroadcastFlag.WASM, "OnTabletToPlane")

local aircraft = GetAircraftPlugin()
local GsxController = GetGsxController()

local EfbData = {}
local HasEfbImportedFlightPlan = false
local HasReceivedData = false
local lastQueryTime = 0
local powerRequested = nil
local pcaRequested = nil
local defaultRequestMessage = '{"data":{"%s":1},"message_tag":"%s","tablet_side":"%s"}'
local PmdgVehicleKeys = {
    aft_cargo = "aft_cargo",
    aft_galley = "aft_galley",
    cabin_cleaning = "cabin_cleaning",
    fuel_truck = "fuel_truck",
    fwd_cargo = "fwd_cargo",
    fwd_galley = "fwd_galley",
    lavatory_service = "lavatory_service",
    maintenance_van = "maintenance_van",
    potable_water = "potable_water",
    stairs_1l = "stairs_1l",
    stairs_2l = "stairs_2l"
}

local EventBase = 69632
local EvtLeftSingle = 0x20000000
local EvtRightSingle = 0x80000000

local DoorState = {
    OPEN = 100,
    CLOSED = 0,
}
local Doors = {}
local DoorArmTarget = false

function GetSettingAdvAutomation()
    return false
end

function GetHasFuelSync()
    return true
end

function GetCanSetPayload()
    return true
end

function GetHasFobSaveRestore()
    return true
end

function GetHasChocks()
    return true
end

function GetHasPca()
    return true
end

function GetHasGpuInternal()
    return true
end

function GetGpuRequireChocks()
    return true
end

function GetIsCargo()
    return MatchAircraftString("BDSF") or MatchAircraftString("BCF")
end

function GetPcaRequirePower()
    return true
end

function GetEquipmentPca()
    if pcaRequested == nil then
        return ReadVar("L:7X7X_AirCond_Door") ~=0
    else
        return pcaRequested
    end
end

function SetEquipmentPca(state, force)
    local pca = GetEquipmentPca()
    if (state and pca) or (not state and not pca) then
        return
    end

    pcaRequested = state
    SendRequest("air_cond_unit", "ground_conn")
    QueryState()
end

function GetEquipmentChocks()
    return ReadVar("L:NGXWheelChocks") ~=0
end

function SetEquipmentChocks(state, force)
    if aircraft.PowerAvail then
        return
    end

    local chocks = GetEquipmentChocks()
    if (state and chocks) or (not state and not chocks) then
        return
    end

    return SendRequest("wheel_chocks", "ground_conn")
end

function GetExternalPowerAvailable()
    if powerRequested == nil then
        return aircraft.PowerAvail
    else
        return powerRequested
    end
end

function SetEquipmentPower(state, force)
    if (aircraft.PowerAvail and not state) or (not aircraft.PowerAvail and state) or force then
        powerRequested = state
        SendRequest("ground_power", "ground_conn")
        QueryState()
    end
end

function CheckConnected(str)
    return string.find(str, "RELEASE", 1, true)
end

function MonitorEquipment()
    if pcaRequested ~= nil and HasReceivedData then
        if pcaRequested == CheckConnected(EfbData.ground_conn.air_conditioning_unit) then
            pcaRequested = nil
        end
    end
    if powerRequested ~= nil and HasReceivedData then
        if powerRequested == CheckConnected(EfbData.ground_conn.ground_power_state) then
            powerRequested = nil
        end
    end
end

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and HasEfbImportedFlightPlan
end

function GetSmartButtonRequest()
   return aircraft.AvionicPowered and (ReadVar("L:switch_752_73X") ~= 0 or ReadVar("L:switch_868_73X") ~= 0)
end

function ResetSmartButton()
    if ReadVar("L:switch_752_73X") ~= 0 then
        WritePmdgEvent(752, EvtRightSingle)
        Sleep(50)
        WritePmdgEvent(752, EvtRightSingle)
    end

    if ReadVar("L:switch_868_73X") ~= 0 then
        WritePmdgEvent(868, EvtRightSingle)
        Sleep(50)
        WritePmdgEvent(868, EvtRightSingle)
    end
end

function GetIsConnected()
    return HasReceivedData
end

function QueryState()
    Log("Query State")
    SendToPlane('{"message_tag":"query_state","data":{"request":"yes"},"tablet_side":"CA"}', true)
end

function GetWalkaround()
    return GsxController.IsWalkaround or not GsxController.IsSessionReady
end

function CheckConnection()
    if not GetWalkaround() and LastWalkaround then
        lastQueryTime = os.time()
    end
    LastWalkaround = GetWalkaround()

    if LastWalkaround and GetPluginSetting("FixChocks") == true and not aircraft.AvionicPowered and not GetEquipmentChocks() then
        Log("Fix Chocks in Walkaround")
        WriteVar("L:NGXWheelChocks", 1)
    end

    if not HasReceivedData and os.time() - lastQueryTime >= 5 then
        QueryState()
        lastQueryTime = os.time()
    end
end

function OnPlaneToTablet(evt, data)
    -- Log(tostring(evt) .. " - " .. tostring(data))
    local node = ToJsonNode(data)
    if node["message_tag"] ~= nil then
        if node["autocruise"] ~= nil then
            if not HasReceivedData then
                Log("Received EFB Data")
                lastQueryTime = math.maxinteger
            end
            HasReceivedData = true
            EfbData = node
            -- UpdateDoors()
        end
    end
end

function OnTabletToPlane(evt, data)
    -- Log(tostring(evt) .. " - " .. tostring(data))
    local node = ToJsonNode(data)
    if not HasEfbImportedFlightPlan and node["message_tag"] ~= nil and node.message_tag == "simbrief_data" and node["data"] ~= nil and node.data["dept_icao"] then
        HasEfbImportedFlightPlan = true
    end
end

function RunInterval()
    if HasReceivedData and GsxController.IsOnGround then
        MonitorDoors()
        MonitorEquipment()
        if GetPluginSetting("ClearVehicles") then
            CheckVehicles()
        end
    end
end

function OnAutomationStateChange(state)
    if state == AutomationState.SessionStart then
        if GsxController.IsOnGround and not aircraft.Engine1 and not aircraft.Engine2 then
            DoorDisarmAll()
        end
    elseif state == AutomationState.Preparation then
        DoorDisarmAll()
    elseif state == AutomationState.Departure then
        DoorDisarmAll()
    elseif state == AutomationState.TaxiOut then
        DoorArmAll()
    elseif state == AutomationState.Flight then
        HasEfbImportedFlightPlan = false
        pcaRequested = nil
        powerRequested = nil
    elseif state == AutomationState.Arrival then
        DoorDisarmAll()
    elseif state == AutomationState.TurnAround then
        DoorDisarmAll()
    end
end

function GetTarget(target)
    if target then
        return 1
    else
        return 0
    end
end

function GetPanelRefuel()
    return ReadVar("L:7X7X_Refuel_Door") ~= 0
end

function SetPanelRefuel(target)
    WriteVar("L:7X7X_Refuel_Door", GetTarget(target))
end

function GetPanelLavatory()
    return ReadVar("L:7X7X_Lav_Door") ~= 0
end

function SetPanelLavatory(target)
    WriteVar("L:7X7X_Lav_Door", GetTarget(target))
end

function GetPanelWater()
    return ReadVar("L:7X7X_Water_Door") ~= 0
end

function SetPanelWater(target)
    WriteVar("L:7X7X_Water_Door", GetTarget(target))
end

function CreateDoor(aircraftDoor, event, variable, isCargo)
    return  {
        aircraftDoor = aircraftDoor,
        event = event,
        variable = variable,
        variableArm = variable .. "FLAG",
        targetState = false,
        lastChange = 0,
        isCargo = isCargo
    }
end

function GetAircraftDefaultDoor(gsxDoor)
    if gsxDoor == GsxDoor.PaxDoor1 then
        return AircraftDoor.L1
    elseif gsxDoor == GsxDoor.PaxDoor4 then
        return AircraftDoor.L2
    elseif gsxDoor == GsxDoor.ServiceDoor1 then
        return AircraftDoor.R1
    elseif gsxDoor == GsxDoor.ServiceDoor2 then
        return AircraftDoor.R2
    elseif gsxDoor == GsxDoor.CargoDoor1 then
        return AircraftDoor.CargoFront
    elseif gsxDoor == GsxDoor.CargoDoor2 then
        return AircraftDoor.CargoRear
    elseif gsxDoor == GsxDoor.CargoDoor3Main and GetIsCargo() then
        return AircraftDoor.CargoMain
    else
        return AircraftDoor.None
    end
end

function InitDoors()
    Doors[AircraftDoor.L1] = CreateDoor(AircraftDoor.L1, 14005, "L:FWDLEFTCABINDOOR", false)
    Doors[AircraftDoor.R1] = CreateDoor(AircraftDoor.R1, 14006, "L:FWDRIGHTCABINDOOR", false)
    Doors[AircraftDoor.L2] = CreateDoor(AircraftDoor.L2, 14007, "L:AFTLEFTCABINDOOR", false)
    Doors[AircraftDoor.R2] = CreateDoor(AircraftDoor.R2, 14008, "L:AFTRIGHTCABINDOOR", false)
    Doors[AircraftDoor.CargoFront] = CreateDoor(AircraftDoor.CargoFront, 14013, "L:FwdLwrCargoDoor", true)
    Doors[AircraftDoor.CargoRear] = CreateDoor(AircraftDoor.CargoRear, 14014, "L:AftLwrCargoDoor", true)

    if GetIsCargo() then
        Doors[AircraftDoor.CargoMain] = CreateDoor(AircraftDoor.CargoMain, 14015, "L:MainCargoDoor", true)
    end

    for _, door in pairs(Doors) do
        UseVar(door.variable, "Number")
        UseVar(door.variableArm, "Number")
        UseEvent(GetEventName(door.event))
    end
    Log("PMDG Doors initialized")
end

function MonitorDoors()
    local timeNow = os.time()
    for _, pmdgDoor in pairs(Doors) do
        if pmdgDoor.lastChange ~= 0 then
            local notMatching = ((IsPmdgDoorOpen(pmdgDoor) and not pmdgDoor.targetState) or (IsPmdgDoorClosed(pmdgDoor) and pmdgDoor.targetState))
            local diff = timeNow - pmdgDoor.lastChange
            if notMatching and not IsPmdgDoorMoving(pmdgDoor) and diff >= 10 then
                Info(string.format("Toogle Door %s - not at expected Target State", tostring(AircraftDoor[pmdgDoor.aircraftDoor])))
                SetPmdgDoor(pmdgDoor, pmdgDoor.targetState)
            elseif not IsPmdgDoorMoving(pmdgDoor) and diff >= 10 then
                pmdgDoor.lastChange = 0
            end
        end
    end
end

function GetEventName(event)
    return string.format("#%s", tostring(EventBase + event))
end

function WritePmdgEvent(event, value)
    if value == nil then
        value = EvtLeftSingle
    end
    WriteEvent(GetEventName(event), value)
end

function SetPmdgDoor(pmdgDoor, targetState)
    Info(string.format("Operating Door %s", tostring(AircraftDoor[pmdgDoor.aircraftDoor])))
    WritePmdgEvent(pmdgDoor.event)
    Doors[pmdgDoor.aircraftDoor].targetState = targetState
    Doors[pmdgDoor.aircraftDoor].lastChange = os.time()
end

function ReadPmdgDoor(pmdgDoor)
    return ReadVar(pmdgDoor.variable)
end

function IsPmdgDoorClosed(pmdgDoor)
    return ReadPmdgDoor(pmdgDoor) == DoorState.CLOSED
end

function IsPmdgDoorOpen(pmdgDoor)
    return ReadPmdgDoor(pmdgDoor) == DoorState.OPEN
end

function IsPmdgDoorMoving(pmdgDoor)
    local value = ReadPmdgDoor(pmdgDoor)
    return value > DoorState.CLOSED and value < DoorState.OPEN
end

function IsDoorCustom(gsxDoor)
    return true
end

function SetDoorCustom(aircraftDoor, target)
    local pmdgDoor = Doors[aircraftDoor]
    if pmdgDoor == nil then
        Log(string.format("Door %s is not mapped", tostring(AircraftDoor[aircraftDoor])))
    elseif target and IsPmdgDoorClosed(pmdgDoor) then
        SetPmdgDoor(pmdgDoor, target)
    elseif not target and IsPmdgDoorOpen(pmdgDoor) then
        SetPmdgDoor(pmdgDoor, target)
    end
end

function GetDoorCustom(aircraftDoor)
    local door = Doors[aircraftDoor]
    local result = false
    if door == nil then
        Log(string.format("Door %s is not mapped", tostring(AircraftDoor[aircraftDoor])))
        result = false
    else
         result = IsPmdgDoorOpen(door)
    end

    return result
end

function HasUnarmedDoors()
    for _, pmdgDoor in pairs(Doors) do
        if not pmdgDoor.isCargo and ReadVar(pmdgDoor.variableArm) == 0 and IsPmdgDoorClosed(pmdgDoor) then
            return true
        end
    end

    return false
end

function HasArmedDoors()
    for _, pmdgDoor in pairs(Doors) do
        if not pmdgDoor.isCargo and ReadVar(pmdgDoor.variableArm) == 100 and IsPmdgDoorClosed(pmdgDoor) then
            return true
        end
    end

    return false
end

function DoorArmAll()
    if not DoorArmTarget or HasUnarmedDoors() then
        Log("Arm Doors")
        DoorArmTarget = true
        return SendRequest("arm_all", "doors")
    end
end

function DoorDisarmAll()
    if not DoorArmTarget or HasArmedDoors() then
        Log("Disarm Doors")
        DoorArmTarget = false
        return SendRequest("disarm_all", "doors")
    end
end

function CloseAllCustomDoors()
    SendRequest("close_all", "doors")
    Sleep(500)
end

function GetHasAirStairForward()
    return true
end

function GetAirStairForward()
    return ReadVar("L:AirStairs") ~= 0
end

function SetHasAirStairForward(target)
    local airstairs = GetAirStairForward()
    if (target and airstairs) or (not target and not airstairs) then
        return
    end

    WritePmdgEvent(14017)
    Sleep(150)
    SetDoorCustom(AircraftDoor.L1, target)
end

function PushStateChange(state)
    if state == GsxServiceState.Active then
        DoorArmAll()
    end
end

function PushOperationChange(status)
    if GsxController.GetService(GsxServiceType.Pushback).State == GsxServiceState.Active and status >= 1 and status <= 4 then
        DoorArmAll()
    end
end

function BoardRequested(paxTarget, cargoTargetKg)
    if HasArmedDoors() then
        DoorDisarmAll()
    end
end

function DeboardRequested()
    if HasArmedDoors() then
        DoorDisarmAll()
    end
end

function SetFuelOnBoardKg(fuelKg, targetKg)
    local payloadData =
    {
        fuel_total_lbs = WeightToLb(fuelKg)
    }
    return SendPayloadData(payloadData)
end

function SetPayloadEmpty()
    local payloadData =
    {
        overall_load_level_percent = 0
    }
    SendPayloadData(payloadData)
end

function SetCargoOnBoard(cargoOnBoardKg, cargoTargetKg)
    local payloadData =
    {
        cargo_weight_total = WeightToLb(cargoOnBoardKg)
    }
    return SendPayloadData(payloadData)
end

function SetPaxOnBoard(paxOnBoard, weightPerPaxKg, paxTarget)
    local payloadData =
    {
        pax_count_total = paxOnBoard
    }
    return SendPayloadData(payloadData)
end

function SendPayloadData(payloadData)
    SendToPlane(string.format('{"message_tag":"wb_payload","data":%s,"tablet_side":"CA"}', ToJsonString(payloadData)))
end

function CheckVehicles()
    if EfbData["vehicles"] ~= nil then
        local vehicles = EfbData.vehicles
        local changed = false
        for _, key in pairs(PmdgVehicleKeys) do
            local verhicleState = string.format("%s_state", key)
            if vehicles[verhicleState] ~= nil and string.find(vehicles[verhicleState], "RELEASE", 1, true) then
                SendRequest(key, "ground_vehicles")
                changed = true
            end
        end

        if changed then
            Sleep(150)
            QueryState()
        end
    end
end

function SendRequest(request, tag, side)
    if not side then
        side = "CA"
    end

    local json = string.format(defaultRequestMessage, request, tag, side)
    return SendToPlane(json)
end

function SendToPlane(json, noSleep)
    SendBus("TabletToPlane", json, BroadcastFlag.WASM)
    if noSleep == nil then
        Sleep(100)
    end

    Log("Sent: " .. json)
end

InitDoors()