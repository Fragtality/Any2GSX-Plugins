local aircraft = GetAircraftPlugin()
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("L:INI_MAIN_CARGO_DOOR_TGT", "Number")
SubVar("L:INI_MAIN_CARGO_DOOR", "CheckMainCargoDoorLights", "Number")
UseVar("L:INI_POTENTIOMETER_93", "Number")
UseVar("L:INI_FUEL_ON_BOARD", "Number")
UseVar("L:INI_IS_REFUELING", "Number")
UseVar("L:INI_Fuel_Panel", "Number")
UseVar("L:INI_IS_PAX", "Number")
UseVar("L:INI_AC_ESSENTIAL_BUS_POWERED", "Number")
UseVar("L:INI_dc_essential_on_battery", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CPT_VOICE_IDENT_SWITCH", "Number")
UseVar("L:INI_FO_VOICE_IDENT_SWITCH", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:INI_COVERS_ENABLED", "Number")
UseVar("L:INI_SLIDE_L1", "Number")
UseVar("L:INI_SLIDE_L2", "Number")
UseVar("L:INI_SLIDE_L4", "Number")
UseVar("PAYLOAD STATION WEIGHT:1", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:2", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:3", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:4", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:5", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:6", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:7", "kilogram")
UseVar("PAYLOAD STATION WEIGHT:8", "kilogram")
UseVar("L:INI_LOAD_HUMANITARIAN_SHOW", "Number")
UseVar("L:INI_LOAD_AEROPARTS_SHOW", "Number")
UseVar("L:INI_LOAD_NORMAL_SHOW", "Number")
UseVar("L:INI_LOAD_POSTAL_SHOW", "Number")
UseVar("L:INI_LOAD_RACING_SHOW", "Number")
UseVar("L:INI_LOAD_HORSES_SHOW", "Number")
UseVar("L:INI_REFUEL_TGT", "Number")
UseEvent("INIB.SET_FUEL")
aircraft.InteractivePointAdd(10) --Bulk @ Pax
aircraft.InteractivePointAdd(7) --Bulk @ Freighter

function GetIsCargo()
    return ReadVar("L:INI_IS_PAX") == 0 and ReadVar("L:INI_FUEL_ON_BOARD") > 0
end

local lastArrivalIcao = 0

function GetReadyDepartureServices()
    return GetAvionicPowered() and aircraft.LightNav == true and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") ~= lastArrivalIcao
end

function GetSmartButtonRequest()
   return ReadVar("L:INI_CPT_VOICE_IDENT_SWITCH") == 1 or ReadVar("L:INI_FO_VOICE_IDENT_SWITCH") == 1
end

function ResetSmartButton()
    WriteVar("L:INI_CPT_VOICE_IDENT_SWITCH", 0)
    WriteVar("L:INI_FO_VOICE_IDENT_SWITCH", 0)
end

function GetAvionicPowered()
    return ReadVar("L:INI_AC_ESSENTIAL_BUS_POWERED") == 1 and ReadVar("L:INI_dc_essential_on_battery") == 0
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

function GetHasGpuInternal()
    return true
end

function GetHasChocks()
    return true
end

function GetEquipmentChocks()
    return ReadVar("L:INI_CHOCKS_ENABLED") > 0
end

function SetEquipmentPower(state, force)
    if aircraft.PowerConnected == true and -not state and -not force then
        return
    end

    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    else
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function SetEquipmentChocks(state, force)
    if aircraft.ParkingBrake == false and -not state and -not force then
        return
    end

    if state then
        WriteVar("L:INI_CHOCKS_ENABLED", 1)
    else
        WriteVar("L:INI_CHOCKS_ENABLED", 0)
    end
end

function BeforeWalkaroundSkip()
    RemoveCovers()
end

function HandleWalkaroundEquipment()
    RemoveCovers()
end

function IsDoorCustom(gsxDoor)
    if gsxDoor == 9 and GetIsCargo() then
        return true
    else
        return false
    end
end

function SetDoorCustom(aircraftDoor, target)
    if aircraftDoor == 20 and GetIsCargo() == true then
        Log("MainCargo Door toggle")
        if target then
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 1)
        else
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 0)
        end
    end
end

function GetDoorCustom(aircraftDoor)
    if aircraftDoor == 20 and GetIsCargo() == true then
        return ReadVar("L:INI_MAIN_CARGO_DOOR_TGT") > 0
    else
        return false
    end
end

function SetCargoDoorBulk(target)
    local index = 10
    if GetIsCargo() then
        index = 7
    end

    aircraft.SetInteractivePoint(index, target)
end

function GetCargoDoorBulk()
    local index = 10
    if GetIsCargo() then
        index = 7
    end

    return aircraft.GetInteractivePoint(index)
end

function SetMainCargoDoorLights(target)
    if MainCargoDoorLights ~= target then
       Log("Cargo Lights Toggle")
       if target then
            WriteVar("L:INI_POTENTIOMETER_93", 100)
       else
            WriteVar("L:INI_POTENTIOMETER_93", 0)
       end
       MainCargoDoorLights = target
    end
end

function CheckMainCargoDoorLights()
    local position = ReadVar("L:INI_MAIN_CARGO_DOOR")
    if position > 0.68 then
        SetMainCargoDoorLights(true)
    elseif position < 0.67 then
        SetMainCargoDoorLights(false)
    end
end

function GetPanelRefuel()
    return ReadVar("L:INI_IS_REFUELING") > 0
end

function SetPanelRefuel(target)
    if GetPanelRefuel() ~= target then
        local value = 0
        if target then
            value = 1
        end
        Log("Setting Refuel Panel to " .. value)
        WriteVar("L:INI_IS_REFUELING", value)
    end
end

function GetPanelRefuelOperator()
    return ReadVar("L:INI_Fuel_Panel") > 0
end

function SetPanelRefuelOperator(target)
   if GetPanelRefuelOperator() ~= target then
        local value = 0
        if target then
            value = 1
        end
        Log("Setting Refuel Operator Panel to " .. value)
        WriteVar("L:INI_Fuel_Panel", value)
    end
end

function RefuelStart(fuelTargetKg)
    WriteVar("L:INI_REFUEL_TGT", fuelTargetKg)
end

function SetFuelOnBoardKg(fuelOnBoardKg, targetKg)
    WriteEvent("INIB.SET_FUEL", fuelOnBoardKg)
end

local payloadPaxKg = 0
local payloadCargoKg = 0
local cargoModelSet = false

function SetPayloadStations()
    local payloadTotalKg = payloadPaxKg + payloadCargoKg
    WriteVar("PAYLOAD STATION WEIGHT:6", payloadTotalKg * 0.333333)
    WriteVar("PAYLOAD STATION WEIGHT:7", payloadTotalKg * 0.333333)
    WriteVar("PAYLOAD STATION WEIGHT:8", payloadTotalKg * 0.333333)
end

function SetInitialStations()
    WriteVar("PAYLOAD STATION WEIGHT:1", 81.646)
    WriteVar("PAYLOAD STATION WEIGHT:2", 84.368)
    WriteVar("PAYLOAD STATION WEIGHT:3", 0)
    WriteVar("PAYLOAD STATION WEIGHT:4", 0)
    WriteVar("PAYLOAD STATION WEIGHT:5", 0)
end

function OnAutomationStateChange(state)
    if state == 0 then
        RemoveCovers()
    elseif state == 1 then
        RemoveCovers()
        CheckMainCargoDoorLights()
        payloadPaxKg = 0
        payloadCargoKg = 0
    elseif state == 5 then
        lastArrivalIcao = ReadVar("L:INI_ARR_ICAO_EFB")
    end
end

function RemoveCovers()
    if ReadVar("L:INI_COVERS_ENABLED") > 0 then
        WriteVar("L:INI_COVERS_ENABLED", 0)
    end
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetInitialStations()
    SetPayloadStations()
    RemoveCargoModel()
end

function RemoveCargoModel()
    if GetIsCargo() and GetPluginSetting("CargoModel") >= 0 then
        WriteVar("L:INI_LOAD_HUMANITARIAN_SHOW", 0)
        WriteVar("L:INI_LOAD_AEROPARTS_SHOW", 0)
        WriteVar("L:INI_LOAD_NORMAL_SHOW", 0)
        WriteVar("L:INI_LOAD_POSTAL_SHOW", 0)
        WriteVar("L:INI_LOAD_RACING_SHOW", 0)
        WriteVar("L:INI_LOAD_HORSES_SHOW", 0)
        cargoModelSet = false
    end
end

function OnStairStateChange(state, paxDoorAllowed)
    if (state == 1 or state == 3 or state == 4 or state == 5) then
        if ReadVar("L:INI_SLIDE_L1") > 0 then
            Log("Stowing Slides on L1")
            WriteVar("L:INI_SLIDE_L1", 0)
        end
        if ReadVar("L:INI_SLIDE_L4") > 0 then
            Log("Stowing Slides on L4")
            WriteVar("L:INI_SLIDE_L4", 0)
        end
    end

    return false
end

function OnJetwayStateChange(state, paxDoorAllowed)
    if (state == 1 or state == 3 or state == 4 or state == 5) then
        if ReadVar("L:INI_SLIDE_L1") > 0 then
            Log("Stowing Slides on L1")
            WriteVar("L:INI_SLIDE_L1", 0)
        end
        if ReadVar("L:INI_SLIDE_L2") > 0 then
            Log("Stowing Slides on L2")
            WriteVar("L:INI_SLIDE_L2", 0)
        end
    end

    return false
end

function BoardActive(paxTarget, cargoTargetKg)
    payloadPaxKg = 0
    payloadCargoKg = 0
    CheckMainCargoDoorLights()
    RemoveCargoModel()
end

function SetPaxOnBoard(paxOnBoard, weightPerPaxKg, paxTarget)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function SetCargoOnBoard(cargoOnBoardKg, cargoTargetKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function BoardChangeCargo(progressLoad, cargoOnBoardKg, cargoPlannedKg)
    SetCargoOnBoard(cargoOnBoardKg, cargoPlannedKg)
    if GetIsCargo() and not cargoModelSet and progressLoad >= GetPluginSetting("CargoSetValue") then
        local modelTarget = GetPluginSetting("CargoModel")
        if modelTarget == 0 then
            WriteVar("L:INI_LOAD_NORMAL_SHOW", 1)
        elseif modelTarget == 1 then
            WriteVar("L:INI_LOAD_POSTAL_SHOW", 1)
        elseif modelTarget == 2 then
            WriteVar("L:INI_LOAD_HUMANITARIAN_SHOW", 1)
        elseif modelTarget == 3 then
            WriteVar("L:INI_LOAD_AEROPARTS_SHOW", 1)
        elseif modelTarget == 4 then
            WriteVar("L:INI_LOAD_RACING_SHOW", 1)
        elseif modelTarget == 5 then
            WriteVar("L:INI_LOAD_HORSES_SHOW", 1)
        end
        cargoModelSet = true
    end
end

function DeboardActive()
    CheckMainCargoDoorLights()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    SetCargoOnBoard(cargoOnBoardKg, 0)
    if GetIsCargo() and cargoModelSet and progressUnload <= GetPluginSetting("CargoUnsetValue") then
        RemoveCargoModel()
    end
end