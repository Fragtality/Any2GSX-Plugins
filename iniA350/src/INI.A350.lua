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
UseVar("L:INI_GEN_EXT_A_ONLINE", "Number")
UseVar("L:INI_GEN_EXT_B_ONLINE", "Number")
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
UseVar("L:FSDT_GSX_REFUELING_STATE", "Number")
UseVar("L:FSDT_GSX_BOARDING_STATE", "Number")
UseVar("L:FSDT_GSX_DEBOARDING_STATE", "Number")
UseVar("L:INI_GSX_INTEG_ENABLED", "Number")
UseVar("L:INI_Potable_Water_Door", "Number")
UseVar("L:INI_Waste_Water_Door", "Number")
UseVar("L:INI_Refuel_Door", "Number")
UseVar("INTERACTIVE POINT OPEN:2", "percent over 100") --2L
for i = 0, 10 do
    UseVar("INTERACTIVE POINT GOAL:"..tostring(i), "percent over 100")
end

function BeforeWalkaroundSkip()
    if not gsxController.IsMsfs2024 then
        return
    end
    CheckSetCovers()
    Sleep(250)
end

function CheckSetCovers()
    if not GetPluginSetting("Covers.RemoveStartup") then
        return
    end
    Log("Removing Pitot & Engine Covers")

    if gsxController.IsMsfs2024 then
        if ReadVar("COVER ON:1") then
            WriteVar("COVER ON:1", 0)
        end
        if ReadVar("COVER ON:2") then
            WriteVar("COVER ON:2", 0)
        end
    else
        if ReadVar("L:INI_COVERS_ENABLED") > 0 then
            WriteVar("L:INI_COVERS_ENABLED", 0)
        end
    end
end

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0
end

function GetSmartButtonRequest()
   return aircraft.AvionicPowered and (ReadVar("L:INI_RMP_INT_RAD_1") == 0 or ReadVar("L:INI_RMP_INT_RAD_2") == 0)
end

function ResetSmartButton()
    WriteVar("L:INI_RMP_INT_RAD_1", 1)
    WriteVar("L:INI_RMP_INT_RAD_2", 1)
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

function GetHasChocks()
    return true
end

function GetEquipmentChocks()
    return ReadVar("L:INI_CHOCKS_ENABLED") > 0
end

function SetEquipmentChocks(state, force)
    if aircraft.ParkingBrake == false and not state and not force then
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
    if not state and not aircraft.ApuRunning and not aircraft.ApuBleedOn and not force then
        return
    end

    if state then
        WriteVar("L:INI_ACU_AVAIL", 1)
    else
        WriteVar("L:INI_ACU_AVAIL", 0)
    end
end

function SetFuelOnBoardKg(fuelKg, targetKg)
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
    Log("tick")
    Sleep(500)
    Log("tock")
    SetPanelRefuel(false)
end

function SetPanelRefuel(target)
    local value = 0
    if target then
        value = 1
    end

    if ReadVar("L:INI_EFB_IS_REFUELING") ~= value then
        Log("Setting Refuel Door to " .. value)
        WriteVar("L:INI_EFB_IS_REFUELING", value)
    end

    if ReadVar("L:INI_Refuel_Door") ~= value then
        Log("Setting Refuel Panel Message to " .. value)
        SendInput("common_a350_refuel_door_a350_refuel_door", 1)
    end
end

local boardWasOverriden = false

function BoardActive(paxTarget, cargoTargetKg)
    if not GetPluginSetting("Override.Payload") then
        Log("Using native Board Payload Sync")
        return
    else
        Log("Using Any2GSX Payload Sync on Boarding")
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

function BoardChangePax(paxOnBoard, weightPerPaxKg, paxTarget)
    if not GetPluginSetting("Override.Payload") then
        return
    end

    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function BoardChangeCargo(progressLoad, cargoOnBoardKg, cargoPlannedKg)
    if not GetPluginSetting("Override.Payload") then
        return
    end

    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    if not GetPluginSetting("Override.Payload") then
        return
    end

    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()
end

function DeboardChangePax(paxOnBoard, gsxTotal, weightPerPaxKg)
    if not GetPluginSetting("Override.Payload") then
        return
    end
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    if not GetPluginSetting("Override.Payload") then
        return
    end
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

local deboardWasOverriden = false

function DeboardRequested()
    DeboardActive()
end

function DeboardActive()
    if not GetPluginSetting("Override.Payload") then
        Log("Using native Deboard Payload Sync")
        return
    elseif not deboardWasOverriden then
        Log("Using Any2GSX Payload Sync on Deboarding")
    end

    if deboardWasOverriden then
        return
    end
    deboardWasOverriden = true

    gsxController.GetService(7).StateOverride = 5
    WriteVar("L:FSDT_GSX_DEBOARDING_STATE", 2)
end

function DeboardCompleted()
    if not GetPluginSetting("Override.Deboard") then
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
        if gsxController.IsOnGround then
            SetDoorArmState(false)
        end
        CheckSetCovers()
        if ReadVar("L:INI_GSX_INTEG_ENABLED") > 0 then
            Log("Disable native Menu Integration")
            WriteVar("L:INI_GSX_INTEG_ENABLED", 0)
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
    if trigger and door == 2 and ReadVar("INTERACTIVE POINT OPEN:2") < 0.5 then
        SetInteractivePoint(2, 1)
    end
end

function CheckSetL2(state)
    local isOpen = ReadVar("INTERACTIVE POINT OPEN:2") >= 0.5
    if state == 5 and not isOpen then
        SetInteractivePoint(2, 1)
    elseif state ~= 5 and isOpen then
        SetInteractivePoint(2, 0)
    end
end

function OnStairStateChange(state, paxDoorAllowed)
    if not paxDoorAllowed then
        return
    end

    CheckSetL2(state)
end

function OnStairOperationChange(state, paxDoorAllowed)
    if state == 7 and paxDoorAllowed then --completing
        CheckSetL2(4)
    end
end

function GetInteractivePoint(index)
    return ReadVar("INTERACTIVE POINT GOAL:"..tostring(index))
end

function SetInteractivePoint(index, value)
    Log("Set Interactive Point #" .. tostring(index) .. " to Target " .. tostring(value))
    return WriteVar("INTERACTIVE POINT GOAL:"..tostring(index), value)
end

function GetHasOpenDoors()
    for i = 0, 10 do
        if GetInteractivePoint(i) > 0 then
            return true
        end
    end

    if ReadVar("L:INI_Potable_Water_Door") > 0 then
        return true
    end

    if ReadVar("L:INI_Waste_Water_Door") > 0 then
        return true
    end

    if ReadVar("L:INI_EFB_IS_REFUELING") > 0 then
        return true
    end

    if ReadVar("L:INI_Refuel_Door") > 0 then
        return true
    end

    return false
end

function DoorsAllClose()
    for i = 0, 10 do
        if GetInteractivePoint(i) > 0 then
            SetInteractivePoint(i, 0)
        end
    end

    if ReadVar("L:INI_Potable_Water_Door") > 0 then
        WriteVar("L:INI_Potable_Water_Door", 0)
    end

    if ReadVar("L:INI_Waste_Water_Door") > 0 then
        WriteVar("L:INI_Waste_Water_Door", 0)
    end

    if ReadVar("L:INI_EFB_IS_REFUELING") > 0 then
        WriteVar("L:INI_EFB_IS_REFUELING", 0)
    end

    if ReadVar("L:INI_Refuel_Door") > 0 then
        SendInput("common_a350_refuel_door_a350_refuel_door", 1)
    end
end