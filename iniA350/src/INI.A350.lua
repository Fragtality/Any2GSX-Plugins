local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
UseEvent("INIB.SET_FUEL")
UseEvent("INIB.SET_ZFW")
UseVar("L:INI_START_TURNAROUND", "Number")
UseVar("L:INI_EFB_IS_REFUELING", "Number")
UseVar("L:INI_REFUEL_IN_PROGRESS", "Number")
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
UseVar("L:INI_FUEL_WEIGHT_CENTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_CENTER2", "Number")
UseVar("L:INI_FUEL_WEIGHT_LEFT_INNER", "Number")
UseVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", "Number")
UseVar("FUEL TANK LEFT MAIN QUANTITY", "gallons") -- left inner
UseVar("FUEL TANK RIGHT MAIN QUANTITY", "gallons") -- right inner
UseVar("FUEL TANK CENTER QUANTITY", "gallons") -- 1/2 center
UseVar("FUEL TANK CENTER2 QUANTITY", "gallons") -- 1/2 center
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
UseVar("L:INI_ATC_MSG_SOUND", "Number")
UseVar("L:FSDT_GSX_NUMPASSENGERS_BOARDING_TOTAL", "Number")
aircraft.InteractivePointAdd(10) --Bulk

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

local lastArrivalIcao = 0

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") ~= lastArrivalIcao
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
    if state then
        WriteVar("L:INI_ACU_AVAIL", 1)
    else
        WriteVar("L:INI_ACU_AVAIL", 0)
    end
end

local wingMax = 46980.02
local centerMax = 63543.01

function SetFuelOnBoardKg(fuelKg, targetKg)
    local wingMain = 0
    local centers = 0
    if fuelKg < wingMax then
        wingMain = fuelKg
    else
        wingMain = wingMax
        centers = math.min(fuelKg - wingMax, centerMax)
    end

    if gsxController.GetService(2).State == 5 then
        WriteVar("FUEL TANK LEFT MAIN QUANTITY", (wingMain / 2.0) / FuelWeightKgPerGallon())
        WriteVar("FUEL TANK RIGHT MAIN QUANTITY", (wingMain / 2.0) / FuelWeightKgPerGallon())

        WriteVar("FUEL TANK CENTER QUANTITY", (centers / 2.0) / FuelWeightKgPerGallon())
        WriteVar("FUEL TANK CENTER2 QUANTITY", (centers / 2.0) / FuelWeightKgPerGallon())
    else
        WriteVar("L:INI_FUEL_WEIGHT_LEFT_INNER", wingMain / 2.0)
        WriteVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", wingMain / 2.0)

        WriteVar("L:INI_FUEL_WEIGHT_CENTER", centers / 2.0)
        WriteVar("L:INI_FUEL_WEIGHT_CENTER2", centers / 2.0)
    end
end

function OnRefuelHoseConnection(connected)
    WriteVar("L:INI_REFUEL_IN_PROGRESS", GetTarget(connected))
end

function GetPanelRefuel()
    return ReadVar("L:INI_EFB_IS_REFUELING") > 0
end

function SetPanelRefuel(target)
   if GetPanelRefuel() ~= target then
        Log("Setting Refuel Panel to " .. target)
        WriteVar("L:INI_EFB_IS_REFUELING", GetTarget(target))
    end
end

function GetPanelRefuelOperator()
    return ReadVar("L:INI_Refuel_Door") > 0
end

function SetPanelRefuelOperator(target)
    if GetPanelRefuelOperator() ~= target then
        Log("Setting Refuel Operator Panel to " .. target)
        WriteVar("L:INI_Refuel_Door", GetTarget(target))
    end
end

function RefuelCompleted()
    WriteVar("L:FSDT_GSX_REFUELING_STATE", 6)
end

local payloadPaxKg = 0
local payloadCargoKg = 0

function SetPayloadStations()
    local payloadTotalKg = payloadPaxKg + payloadCargoKg
    local zfw = aircraft.WeightEmptyKg + payloadTotalKg
    WriteEvent("INIB.SET_ZFW", zfw)
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function SyncPayloadStations()
    payloadPaxKg = ReadVar("L:INI_PAX_BUSSINESS") + ReadVar("L:INI_PAX_ECONOMY_1") + ReadVar("L:INI_PAX_ECONOMY_2")
    payloadCargoKg = ReadVar("L:INI_CARGO_FWD_BAGGAGE_KG") + ReadVar("L:INI_CARGO_AFT_BAGGAGE_KG") + ReadVar("L:INI_CARGO_BULK_BAGGAGE_KG")
end

function BoardActive(paxTarget, cargoTargetKg)
    WriteVar("L:FSDT_GSX_NUMPASSENGERS_BOARDING_TOTAL", 1)
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    WriteVar("L:FSDT_GSX_BOARDING_STATE", 6)
    Sleep(250)

    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()
end

function GenerateLoadsheetFinal()
    SendBus("BoardingCompleted", "", 2)
end

function DeboardChangePax(paxOnBoard, gsxTotal, weightPerPaxKg)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
end

function DeboardChangeCargo(progressUnload, cargoOnBoardKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
end

function DeboardRequested()
    SyncPayloadStations()
end

function DeboardCompleted()
    RunAfter(1500, "SetTurn()")
end

function SetTurn()
    WriteVar("L:INI_START_TURNAROUND", 1)
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
    elseif state == 5 then --flight
        lastArrivalIcao = ReadVar("L:INI_ARR_ICAO_EFB")
    elseif state == 7 then --arrival
        SetDoorArmState(false)
    end
end

function PushOperationChange(status)
    if status == 3 or status == 4 then
        SetDoorArmState(true)
    end
end

function GetTarget(target)
    if target then
        return 1
    else
        return 0
    end
end

function GetPanelLavatory()
    return ReadVar("L:INI_Waste_Water_Door") > 0
end

function SetPanelLavatory(target)
    if GetPanelRefuelOperator() ~= target then
        Log("Setting Lavatory Panel to " .. target)
        WriteVar("L:INI_Waste_Water_Door", GetTarget(target))
    end
end

function GetPanelWater()
    return ReadVar("L:INI_Potable_Water_Door") > 0
end

function SetPanelWater(target)
    if GetPanelRefuelOperator() ~= target then
        Log("Setting Water Panel to " .. target)
        WriteVar("L:INI_Potable_Water_Door", GetTarget(target))
    end
end

function IsDoorCustom(gsxDoor)
    return gsxDoor == 9
end

function GetDoorCustom(aircraftDoor)
    if aircraftDoor == 19 then
        return aircraft.GetInteractivePoint(10)
    else
        return false
    end
end

function SetDoorCustom(aircraftDoor, target)
    if aircraftDoor == 19 then
        aircraft.SetInteractivePoint(10, target)
    end
end

function NotifyCockpit(notification)
    if notification == 1 then
        WriteVar("L:INI_ATC_MSG_SOUND", 1)
        Sleep(100)
        WriteVar("L:INI_ATC_MSG_SOUND", 0)
    end
end