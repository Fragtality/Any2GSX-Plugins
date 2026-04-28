local aircraft = GetAircraftPlugin()
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("L:INI_MAIN_CARGO_DOOR_TGT", "Number")
SubVar("L:INI_MAIN_CARGO_DOOR", "OnMainCargoDoor", "Number")
UseVar("L:A300_MAIN_CARGO_LOADER_LIGHTS_CMD", "Number")
UseVar("L:INI_FUEL_REQ", "Number")
UseVar("L:INI_FUEL_ON_BOARD", "Number")
UseVar("L:INI_IS_PAX", "Number")
UseVar("L:FSDT_GSX_SETTINGS_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SETTINGS_DETECT_CUST_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_DETECT_CUST_REFUEL", "Number")
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
UseVar("INTERACTIVE POINT GOAL:10", "percent over 100") --Bulk @ Pax

function GetIsCargo()
    return ReadVar("L:INI_IS_PAX") == 0 and ReadVar("L:INI_FUEL_ON_BOARD") > 0
end

function GetReadyDepartureServices()
    return GetAvionicPowered() and aircraft.LightNav == true and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0
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

function OnDoorTrigger(door, trigger)
    local profile = GetSettingProfile()
    if door == 9 and trigger == true and GetIsCargo() == true and profile.DoorCargoHandling == true then
        Log("MainCargo trigger")
        local target = ReadVar("L:INI_MAIN_CARGO_DOOR_TGT") > 0
        if target == false then
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 1)
        else
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 0)
        end
    end
end

local MainCargoDoorLights = false

function SetMainCargoDoorLights(target)
    if MainCargoDoorLights ~= target then
        Log("Cargo Lights Toggle")
       WriteVar("L:A300_MAIN_CARGO_LOADER_LIGHTS_CMD", 1)
       MainCargoDoorLights = target
    end
end

function OnMainCargoDoor(position)
    if position > 0.68 then
        SetMainCargoDoorLights(true)
    elseif position < 0.67 then
        SetMainCargoDoorLights(false)
    end
end

function SetFuelOnBoardKg(fuelOnBoardKg, targetKg)
    WriteVar("L:INI_FUEL_REQ", fuelOnBoardKg)
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
        payloadPaxKg = 0
        payloadCargoKg = 0
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
end

function SetCargoDoors(state, force)
    if not GetIsCargo() and not state and ReadVar("INTERACTIVE POINT GOAL:10") > 0 then
        WriteVar("INTERACTIVE POINT GOAL:10", 0)
    end
end

function BoardActive(paxTarget, cargoTargetKg)
    payloadPaxKg = 0
    payloadCargoKg = 0
    RemoveCargoModel()
end

function BoardChangePax(paxOnBoard, weightPerPaxKg, paxTarget)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function BoardChangeCargo(progressLoad, cargoOnBoardKg, cargoPlannedKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
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

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()

    local profile = GetSettingProfile()
    if GetIsCargo() == true and profile.DoorCargoHandling == true and not profile.DoorsCargoKeepOpenOnDetachBoard then
        local door = ReadVar("L:INI_MAIN_CARGO_DOOR_TGT") > 0
        if door == true then
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 0)
        end
    end
end

function DeboardChangePax(paxOnBoard, gsxTotal, weightPerPaxKg)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
    if GetIsCargo() and cargoModelSet and progressUnload <= GetPluginSetting("CargoUnsetValue") then
        RemoveCargoModel()
    end
end

function DeboardCompleted()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()

    local profile = GetSettingProfile()
    if GetIsCargo() == true and profile.DoorCargoHandling == true and not profile.DoorsCargoKeepOpenOnDetachDeboard then
        local door = ReadVar("L:INI_MAIN_CARGO_DOOR_TGT") > 0
        if door == true then
            WriteVar("L:INI_MAIN_CARGO_DOOR_TGT", 0)
        end
    end
end