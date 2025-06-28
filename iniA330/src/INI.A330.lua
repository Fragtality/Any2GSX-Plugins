local aircraft = GetAircraftPlugin()
UseVar("L:INI_FUEL_REQ", "Number")
UseVar("L:INI_EFB_IS_REFUELING", "Number")
UseVar("L:FSDT_GSX_SETTINGS_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SETTINGS_DETECT_CUST_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_DETECT_CUST_REFUEL", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CPT_INT_RAD_SWITCH", "Number")
UseVar("L:INI_FO_INT_RAD_SWITCH", "Number")
UseVar("L:INI_PAX_BUSSINESS", "Number")
UseVar("L:INI_PAX_ECONOMY_1", "Number")
UseVar("L:INI_PAX_ECONOMY_2", "Number")
UseVar("L:INI_CARGO_FWD_BAGGAGE_KG", "Number")
UseVar("L:INI_CARGO_AFT_BAGGAGE_KG", "Number")
UseVar("L:INI_CARGO_BULK_BAGGAGE_KG", "Number")
UseVar("COVER ON:0", "Bool") --Chocks
UseVar("COVER ON:1", "Bool") --Engines
UseVar("COVER ON:2", "Bool") --Pitot
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("INTERACTIVE POINT GOAL:0", "percent over 100") --1L
UseVar("INTERACTIVE POINT GOAL:10", "percent over 100") --2L
UseVar("INTERACTIVE POINT GOAL:2", "percent over 100") --4L
SubEvent("TOGGLE_JETWAY", "OnJetwayToggle")

function OnCouatlStarted()
    if ReadVar("L:FSDT_GSX_SETTINGS_PROGRESS_REFUEL") == 1 then
        Log("Disabling progressive Refuel")
        WriteVar("L:FSDT_GSX_SET_PROGRESS_REFUEL", -1)
    end

    if ReadVar("L:FSDT_GSX_SETTINGS_DETECT_CUST_REFUEL") == 1 then
        Log("Disabling custom Fuel Detection")
        WriteVar("L:FSDT_GSX_SET_DETECT_CUST_REFUEL", -1)
    end
end

function BeforeWalkaroundSkip()
    if not GetSetting("INI.330.Option.Chocks.RemoveStartup") then
        return
    end

    Info("Removing Chocks & Covers in Walkaround")
    Sleep(250)
    if aircraft.IsBrakeSet == true then
        Info("Set Parking Brake before removing Chocks")
        SendInput("airliner_parkingbrake", 1)
    end

    if ReadVar("COVER ON:1") then
        SendInput("unknown_cover_left", 1)
    end
    if ReadVar("COVER ON:2") then
        SendInput("unknown_pitot_covers", 1)
    end
    if ReadVar("COVER ON:0") then
        SendInput("unknown_chocks", 1)
    end
    Sleep(250)
end

function GetIsCargo()
    return MatchAircraftString("P2F")
end

function GetReadyDepartureServices()
    return aircraft.IsAvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0
end

function GetSmartButtonRequest()
   return ReadVar("L:INI_CPT_INT_RAD_SWITCH") == 2 or ReadVar("L:INI_FO_INT_RAD_SWITCH") == 2
end

function ResetSmartButton()
    WriteVar("L:INI_CPT_INT_RAD_SWITCH", 1)
    WriteVar("L:INI_FO_INT_RAD_SWITCH", 1)
end

function GetExternalPowerAvailable()
    return ReadVar("L:INI_GPU_AVAIL") == 1
end

function GetHasFuelSynch()
    return true
end

function GetHasFobSaveRestore()
    return true
end

function GetCanSetPayload()
    return true
end

function GetHasGpuInternal()
    return true
end

function SetEquipmentPower(state, force)
    if aircraft.IsExternalPowerConnected == true and -not state and -not force then
        return
    end

    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    else
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function GetHasChocks()
    local state = AutomationState()
    if state == 3 and GetSetting("INI.330.Option.Chocks.RemovePush") then
        return true
    elseif state == 7 and GetSetting("INI.330.Option.Chocks.PlaceArrival") then
        return true
    else
        return false
    end
end

function GetEquipmentChocks()
    return ReadVar("COVER ON:0") == 1
end

function SetEquipmentChocks(state, force)
    local chockSet = GetEquipmentChocks()
    if state ~= chockSet or force then
        Info("Toggle Chocks in Walkaround")
        local gsxController = GetGsxController()
        if gsxController.IsWalkaround == false then
            ToggleWalkaround()
        end

        if state then
            WriteVar("COVER ON:0", 1)
        else
            WriteVar("COVER ON:0", 0)
        end

        if gsxController.IsWalkaround == true then
            ToggleWalkaround()
        end
    end
end

function SetFuelOnBoardKg(fuelKg)
    WriteVar("L:INI_FUEL_REQ", fuelKg)
end

local payloadPaxKg = 0
local payloadCargoKg = 0

function SetPayloadStations()
    local payloadTotalKg = payloadPaxKg + payloadCargoKg
    WriteVar("L:INI_PAX_BUSSINESS", payloadTotalKg * 0.0492)
    WriteVar("L:INI_PAX_ECONOMY_1", payloadTotalKg * 0.13)
    WriteVar("L:INI_PAX_ECONOMY_2", payloadTotalKg * 0.1585)
    WriteVar("L:INI_CARGO_FWD_BAGGAGE_KG", payloadTotalKg * 0.3357)
    WriteVar("L:INI_CARGO_AFT_BAGGAGE_KG", payloadTotalKg * 0.275)
    WriteVar("L:INI_CARGO_BULK_BAGGAGE_KG", payloadTotalKg * 0.0516)
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function RefuelStart(fuelTargetKg)
    WriteVar("L:INI_EFB_IS_REFUELING", 1)
end

function RefuelStop(fuelTargetKg, setTarget)
    WriteVar("L:INI_EFB_IS_REFUELING", 0)
end

function BoardActive(paxTarget, cargoTargetKg)
    payloadPaxKg = 0
    payloadCargoKg = 0
end

function BoardChangePax(paxOnBoard, weightPerPaxKg)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function BoardChangeCargo(progressLoad, cargoOnBoardKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()
end

function DeboardChangePax(paxOnBoard, gsxTotal, weightPerPaxKg)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function DeboardCompleted()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function GetInteractivePoint(index)
    return ReadVar("INTERACTIVE POINT GOAL:"..tostring(index))
end

function SetInteractivePoint(index, value)
    Log("Set Interactive Point #" .. tostring(index) .. " to Target " .. tostring(value))
    return WriteVar("INTERACTIVE POINT GOAL:"..tostring(index), value)
end

local jetwayEvaluated = false
local jetwayDoor = 0

function OnAutomationStateChange(state)
    if state == 4 or state == 5 then
        jetwayEvaluated = false
        jetwayDoor = 0
    end
end

function OnJetwayChange(state)
    if GetIsCargo() then
        return
    end

    if state == 5 then
        if not jetwayEvaluated then
            if GetInteractivePoint(0) == 1 then
                jetwayDoor = 0
            else
                jetwayDoor = 10
            end
            jetwayEvaluated = true
            Log("Using Interactive Point #" .. tostring(jetwayDoor) .. " for Jetway Door")
        end

        if GetInteractivePoint(jetwayDoor) == 0 then
            Log("Toggle Jetway Door on Jetway Change (open)")
            SetInteractivePoint(jetwayDoor, 1)
        end
    elseif state ~= 5 and GetInteractivePoint(jetwayDoor) ~= 0 then
        Log("Toggle Jetway Door on Jetway Change (close)")
        SetInteractivePoint(jetwayDoor, 0)
    end
end

local inhibitDoor = false
function OnDoorTrigger(door, trigger)
    if door == 1 then
        Log("trigger")
        Log(trigger)
        Log(jetwayDoor)
        if trigger and jetwayDoor ~= 0 then
            inhibitDoor = true
        elseif not trigger and inhibitDoor and jetwayDoor ~= 0 then
            inhibitDoor = false
        end
    end
end

function OnJetwayToggle(evtData)
    local gsxController = GetGsxController()
    if jetwayEvaluated and jetwayDoor == 10 and gsxController.JetwayState == 5 then
        Log("Toggle Jetway Door on Toggle Event (close)")
        SetInteractivePoint(jetwayDoor, 0)
    end
end

function RunInterval()
    local gsxController = GetGsxController()
    if GetIsCargo() or gsxController.HasGateJetway == false then
        return
    end

    local state = AutomationState()
    --correct Doors with Jetway in Prep/Depart/Push/Arrival/Turn
    if state == 1 or state == 2 or state == 3 or state == 7 or state == 8 then
        local profile = GetSettingProfile()
        if profile.DoorStairHandling == false then
            return
        end

        local gsxController = GetGsxController()
        local stair = gsxController.StairsState
        local doorOpen = GetInteractivePoint(2) == 1

        if doorOpen and stair ~= 5 then
            Log("Correcting Door L4 (close)")
            SetInteractivePoint(2, 0)
        elseif not doorOpen and stair == 5 and state ~= 3 then
            Log("Correcting Door L4 (open)")
            SetInteractivePoint(2, 1)
        end

        doorOpen = GetInteractivePoint(0) == 1
        if doorOpen and gsxController.HasGateJetway and not inhibitDoor and jetwayDoor ~= 0 then
            Log("Correcting Door L1 (close)")
            SetInteractivePoint(0, 0)
        end

        doorOpen = GetInteractivePoint(10) == 1
        if doorOpen and gsxController.HasGateJetway and jetwayDoor ~= 10 then
            Log("Correcting Door L2 (close)")
            SetInteractivePoint(10, 0)
        end
    end
end