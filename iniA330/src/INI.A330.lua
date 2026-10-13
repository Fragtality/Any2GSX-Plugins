local aircraft = GetAircraftPlugin()
UseVar("L:INI_EFB_FUEL_LOAD_REQ", "Number")
UseVar("L:INI_EFB_IS_REFUELING", "Number")
UseVar("L:INI_EFB_IS_LOADING", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_GEN_EXT_A_ONLINE", "Number")
UseVar("L:INI_GEN_EXT_B_ONLINE", "Number")
UseVar("L:INI_CPT_INT_RAD_SWITCH", "Number")
UseVar("L:INI_FO_INT_RAD_SWITCH", "Number")
UseVar("EMPTY WEIGHT", "Kilogram")
UseVar("COVER ON:0", "Bool") --Chocks
UseVar("COVER ON:1", "Bool") --Engines
UseVar("COVER ON:2", "Bool") --Pitot
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseEvent("INIB.SET_FUEL")
UseEvent("INIB.SET_ZFW")
UseInput("unknown_cover_left")
UseInput("unknown_pitot_covers")
UseInput("unknown_chocks")
aircraft.InteractivePointAdd(4) --Bulk

local lastArrivalIcao = 0

local payloadPaxKg = 0
local payloadCargoKg = 0

function BeforeWalkaroundSkip()
    CheckSetCovers()
end

function CheckSetCovers()
    if ReadVar("COVER ON:1") > 0 then
        WriteInput("unknown_cover_left", 1)
    end
    if ReadVar("COVER ON:2") > 0 then
        WriteInput("unknown_pitot_covers", 1)
    end
end

function GetIsCargo()
    return MatchAircraftString("P2F")
end

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") ~= lastArrivalIcao
end

function GetSmartButtonRequest()
   return ReadVar("L:INI_CPT_INT_RAD_SWITCH") == 2 or ReadVar("L:INI_FO_INT_RAD_SWITCH") == 2
end

function GetExternalPowerConnected()
    return ReadVar("L:INI_GEN_EXT_A_ONLINE") == 1 or ReadVar("L:INI_GEN_EXT_B_ONLINE") == 1
end

function ResetSmartButton()
    WriteVar("L:INI_CPT_INT_RAD_SWITCH", 1)
    WriteVar("L:INI_FO_INT_RAD_SWITCH", 1)
end

function GetHasFuelSync()
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
    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    else
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function GetHasChocks()
    return true
end

function GetEquipmentChocks()
    return ReadVar("COVER ON:0") == 1
end

function SetEquipmentChocks(state, force)
    local chockSet = GetEquipmentChocks()
    if state ~= chockSet or force then
        WriteInput("unknown_chocks", 1)
    end
end

function OnCouatlStarted()
    if GetIsCargo() then
        SetGenericSetting("Aircraft.DoorPreferred", 1)
    else
        SetGenericSetting("Aircraft.DoorPreferred", 2)
    end
end

function SetFuelOnBoardKg(fuelKg, targetKg)
    WriteVar("L:INI_EFB_FUEL_LOAD_REQ", 1)
    WriteEvent("INIB.SET_FUEL", fuelKg)
end

function SetPayloadStations()
    local zfwTarget = ReadVar("EMPTY WEIGHT") + payloadPaxKg + payloadCargoKg
    WriteEvent("INIB.SET_ZFW", zfwTarget)
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
    if setTarget then
        SetFuelOnBoardKg(fuelTargetKg)
    end

    RunAfter(1000, "WriteVar('L:INI_EFB_IS_REFUELING', 0)")
end

function SetPaxOnBoard(paxOnBoard, weightPerPaxKg, paxTarget)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function SetCargoOnBoard(cargoOnBoardKg, cargoTargetKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function BoardActive(paxTarget, cargoTargetKg)
    payloadPaxKg = 0
    payloadCargoKg = 0
    WriteVar("L:INI_EFB_IS_LOADING", 1)
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    SetPaxOnBoard(paxTarget, weightPerPaxKg, paxTarget)
    SetCargoOnBoard(cargoTargetKg, cargoTargetKg)
    RunAfter(1000, "WriteVar('L:INI_EFB_IS_LOADING', 0)")
end

function OnAutomationStateChange(state)
    if state == 1 or state == 2 then --prep/departure
       CheckSetCovers()
    elseif state == 5 then --flight
        lastArrivalIcao = ReadVar("L:INI_ARR_ICAO_EFB")
    end
end

function IsDoorCustom(gsxDoor)
    return gsxDoor == 9 and not GetIsCargo()
end

function GetDoorCustom(aircraftDoor)
    local cargo = GetIsCargo()
    if (aircraftDoor == 19 and not cargo) or (aircraftDoor == 20 and cargo) then
        return aircraft.GetInteractivePoint(4)
    else
        return false
    end
end

function SetDoorCustom(aircraftDoor, target)
    local cargo = GetIsCargo()
    if (aircraftDoor == 19 and not cargo) or (aircraftDoor == 20 and cargo) then
        aircraft.SetInteractivePoint(4, target)
    end
end

function SetCargoDoorBulk(target)
    aircraft.SetInteractivePoint(4, target)
end

function GetCargoDoorBulk()
    return aircraft.GetInteractivePoint(4)
end