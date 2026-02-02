local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
UseVar("L:INI_FUEL_REQ", "Number")
UseVar("L:INI_EFB_IS_REFUELING", "Number")
UseVar("L:FSDT_GSX_SETTINGS_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SETTINGS_DETECT_CUST_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_DETECT_CUST_REFUEL", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:INI_ACU_AVAIL", "Number")
UseVar("L:INI_ELEC_AC_ESS_SHED_BUS_IS_POWERED", "Number")
UseVar("L:INI_GEN_EXT_A_ONLINE", "Number")
UseVar("L:INI_GEN_EXT_B_ONLINE", "Number")
UseVar("L:INI_AIR_BLEED_APU", "Number")
UseVar("L:INI_APU_AVAILABLE", "Number")
UseVar("L:INI_RMP_INT_RAD_1", "Number")
UseVar("L:INI_RMP_INT_RAD_2", "Number")
UseVar("L:INI_PAX_BUSSINESS", "Number")
UseVar("L:INI_PAX_ECONOMY_1", "Number")
UseVar("L:INI_PAX_ECONOMY_2", "Number")
UseVar("L:INI_CARGO_FWD_BAGGAGE_KG", "Number")
UseVar("L:INI_CARGO_AFT_BAGGAGE_KG", "Number")
UseVar("L:INI_CARGO_BULK_BAGGAGE_KG", "Number")
if gsxController.IsMsfs2024 then
   UseVar("COVER ON:1", "Bool") --Engines
   UseVar("COVER ON:2", "Bool") --Pitot
else
    UseVar("L:INI_COVERS_ENABLED", "Number")
end
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("L:INI_SLIDES_REQ", "Number")
UseVar("L:INI_DOOR0_ARMED", "Number")
UseVar("INTERACTIVE POINT GOAL:9", "percent over 100") --4L
UseVar("INTERACTIVE POINT OPEN:9", "percent over 100")
UseVar("L:FSDT_GSX_REFUELING_STATE", "Number")
UseVar("L:FSDT_GSX_BOARDING_STATE", "Number")
UseVar("L:FSDT_GSX_DEBOARDING_STATE", "Number")

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
    if not gsxController.IsMsfs2024 then
        return
    end

    if not GetSetting("INI.350.Option.Covers.RemoveStartup") then
        return
    end

    Info("Removing Pitot & Engine Covers in Walkaround")
    if ReadVar("COVER ON:1") then
        WriteVar("COVER ON:1", 0)
    end
    if ReadVar("COVER ON:2") then
        WriteVar("COVER ON:2", 0)
    end
    Sleep(250)
end

function GetReadyDepartureServices()
    return GetAvionicPowered() and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0
end

function GetSmartButtonRequest()
   return GetAvionicPowered() and (ReadVar("L:INI_RMP_INT_RAD_1") == 0 or ReadVar("L:INI_RMP_INT_RAD_2") == 0)
end

function ResetSmartButton()
    WriteVar("L:INI_RMP_INT_RAD_1", 1)
    WriteVar("L:INI_RMP_INT_RAD_2", 1)
end

function GetExternalPowerAvailable()
    return ReadVar("L:INI_GPU_AVAIL") > 0
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

function GetAvionicPowered()
    return ReadVar("L:INI_ELEC_AC_ESS_SHED_BUS_IS_POWERED") > 0
end

function GetExternalPowerConnected()
    return ReadVar("L:INI_GEN_EXT_A_ONLINE") > 0 or ReadVar("L:INI_GEN_EXT_B_ONLINE") > 0
end

function GetHasGpuInternal()
    return true
end

function SetEquipmentPower(state, force)
    if GetExternalPowerConnected() and not state and not force then
        return
    end

    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    else
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function GetApuRunning()
    return ReadVar("L:INI_APU_AVAILABLE") > 0
end

function GetApuBleedOn()
    return ReadVar("L:INI_AIR_BLEED_APU") > 0
end

function GetHasChocks()
    return true
end

function GetEquipmentChocks()
    return ReadVar("L:INI_CHOCKS_ENABLED") > 0
end

function SetEquipmentChocks(state, force)
    if aircraft.IsBrakeSet == false and not state and not force then
        return
    end

    if state then
        WriteVar("L:INI_CHOCKS_ENABLED", 1)
    else
        WriteVar("L:INI_CHOCKS_ENABLED", 0)
    end
end

function GetHasPca()
    return true
end

function GetEquipmentPca()
    return ReadVar("L:INI_ACU_AVAIL") > 0
end

function SetEquipmentPca(state, force)
    if not state and not GetApuRunning() and not GetApuBleedOn() and not force then
        return
    end

    if state then
        WriteVar("L:INI_ACU_AVAIL", 1)
    else
        WriteVar("L:INI_ACU_AVAIL", 0)
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
    WriteVar("L:INI_PAX_ECONOMY_1", payloadTotalKg * 0.1300)
    WriteVar("L:INI_PAX_ECONOMY_2", payloadTotalKg * 0.1585)
    WriteVar("L:INI_CARGO_FWD_BAGGAGE_KG", payloadTotalKg * 0.3356)
    WriteVar("L:INI_CARGO_AFT_BAGGAGE_KG", payloadTotalKg * 0.275)
    WriteVar("L:INI_CARGO_BULK_BAGGAGE_KG", payloadTotalKg * 0.0517)
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

local refuelWasOverridden = false

function RefuelActive()
    if refuelWasOverridden then
        return
    end
    refuelWasOverridden = true

    gsxController.GetService(2).StateOverride = 5
    WriteVar("L:FSDT_GSX_REFUELING_STATE", 2)

    if gsxController.HasUndergroundRefuel then
        RunAfter(81000, "SetFuelDoor(1)")
    else
        RunAfter(25000, "SetFuelDoor(1)")
    end
end

function SetFuelDoor(target)
    WriteVar("L:INI_EFB_IS_REFUELING", target)
    SendInput("common_a350_refuel_door_a350_refuel_door", 1)
end

function RefuelStop(fuelTargetKg, setTarget)
    if setTarget then
        SetFuelOnBoardKg(fuelTargetKg)
    end

    if gsxController.HasUndergroundRefuel then
        RunAfter(32000, "SetFuelDoor(0)")
    else
        RunAfter(44000, "SetFuelDoor(0)")
    end
end

local boardWasOverriden = false

function BoardActive(paxTarget, cargoTargetKg)
    if not GetSetting("INI.350.Option.Override.Board") then
        Log("Using native Board Payload Synch")
        return
    else
        Log("Using Any2GSX Payload Synch on Boarding")
    end

    if boardWasOverriden then
        return
    end
    boardWasOverriden = true

    gsxController.GetService(4).StateOverride = 5
    WriteVar("L:FSDT_GSX_BOARDING_STATE", 2)

    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function BoardChangePax(paxOnBoard, weightPerPaxKg)
    if not GetSetting("INI.350.Option.Override.Board") then
        return
    end

    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function BoardChangeCargo(progressLoad, cargoOnBoardKg)
    if not GetSetting("INI.350.Option.Override.Board") then
        return
    end

    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    if not GetSetting("INI.350.Option.Override.Board") then
        return
    end

    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()
end

function DeboardChangePax(paxOnBoard, gsxTotal, weightPerPaxKg)
    if not GetSetting("INI.350.Option.Override.Deboard") then
        return
    end
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    if not GetSetting("INI.350.Option.Override.Deboard") then
        return
    end
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

local deboardWasOverriden = false

function DeboardActive()
    if not GetSetting("INI.350.Option.Override.Deboard") then
        Log("Using native Deboard Payload Synch")
        return
    else
        Log("Using Any2GSX Payload Synch on Deboarding")
    end

    if deboardWasOverriden then
        return
    end
    deboardWasOverriden = true

    gsxController.GetService(7).StateOverride = 5
    WriteVar("L:FSDT_GSX_DEBOARDING_STATE", 2)
end

function DeboardCompleted()
    if not GetSetting("INI.350.Option.Override.Deboard") then
        return
    end

    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function SetDoorArmState(armed)
    local isArmed = ReadVar("L:INI_DOOR0_ARMED") > 0
    if (isArmed and not armed) or (not isArmed and armed) then
        Log("Requesting Toggle on Door Armed State")
        WriteVar("L:INI_SLIDES_REQ", 1)
    end
end

function OnAutomationStateChange(state)
    if state == 1 or state == 2 then --prep/departure
        deboardWasOverriden = false
        SetDoorArmState(false)
        if GetSetting("INI.350.Option.Covers.RemoveStartup") then
            WriteVar("L:INI_COVERS_ENABLED", 0)
        end
    elseif state == 4 then --taxiout
        SetDoorArmState(true)
        refuelWasOverridden = false
        boardWasOverriden = false
    elseif state == 5 then --flight
        refuelWasOverridden = false
        boardWasOverriden = false
    elseif state == 7 then --arrival
    SetDoorArmState(false)
	elseif state == 8 then --turn
        deboardWasOverriden = false
    end
end

function PushOperationChange(status)
    if status == 3 or status == 4 then
        SetDoorArmState(true)
    end
end

function OnDoorTrigger(door, trigger)
    if trigger and door == 4 then
        if ReadVar("INTERACTIVE POINT OPEN:9") >= 0.5 then
            WriteVar("INTERACTIVE POINT GOAL:9", 0)
        else
            WriteVar("INTERACTIVE POINT GOAL:9", 1)
        end
    end
end

function OnStairChange(state)
    local isOpen = ReadVar("INTERACTIVE POINT GOAL:9") > 0
    if state == 5 and not isOpen then
        WriteVar("INTERACTIVE POINT GOAL:9", 1)
    elseif state ~= 5 and isOpen then
        WriteVar("INTERACTIVE POINT GOAL:9", 0)
    end
end