local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
UseVar("L:INI_REFUEL_IN_PROGRESS", "Number")
UseVar("L:INI_REFUELING_DOOR_POSITION", "Number")
UseVar("L:INI_Refuel_Door", "Number")
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_GEN_EXT_A_ONLINE", "Number")
UseVar("L:INI_GEN_EXT_B_ONLINE", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:INI_ACU_AVAIL", "Number")
UseVar("L:INI_COVERS_ENABLED", "Number")
UseVar("L:INI_SLIDES_REQ", "Number")
UseVar("L:INI_DOOR0_ARMED", "Number")
UseVar("L:INI_Potable_Water_Door", "Number")
UseVar("L:INI_Waste_Water_Door", "Number")
UseVar("L:INI_CPT_INT_RAD_SWITCH", "Number")
UseVar("L:INI_FO_INT_RAD_SWITCH", "Number")
UseVar("L:INI_FUEL_WEIGHT_CENTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_CENTER2", "Number")
UseVar("L:INI_FUEL_WEIGHT_LEFT_INNER", "Number")
UseVar("L:INI_FUEL_WEIGHT_LEFT_OUTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", "Number")
UseVar("L:INI_FUEL_WEIGHT_RIGHT_OUTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_TRIM", "Number")
UseVar("FUEL TANK LEFT MAIN QUANTITY", "gallons") -- left inner
UseVar("FUEL TANK LEFT AUX QUANTITY", "gallons") -- left outer
UseVar("FUEL TANK RIGHT MAIN QUANTITY", "gallons") -- right inner
UseVar("FUEL TANK RIGHT AUX QUANTITY", "gallons") -- right outer
UseVar("FUEL TANK CENTER QUANTITY", "gallons") -- 1/2 center
UseVar("FUEL TANK CENTER2 QUANTITY", "gallons") -- 1/2 center
UseVar("FUEL TANK EXTERNAL1 QUANTITY", "gallons") --trim
UseVar("PAYLOAD STATION WEIGHT:1", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:2", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:3", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:4", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:5", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:6", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:7", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:8", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:9", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:10", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:11", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:12", "Kilogram")
UseVar("PAYLOAD STATION WEIGHT:13", "Kilogram")
UseVar("ENG COMBUSTION:1", "Bool")
UseVar("ENG COMBUSTION:2", "Bool")
UseVar("ENG COMBUSTION:3", "Bool")
UseVar("ENG COMBUSTION:4", "Bool")
UseVar("L:FSDT_GSX_REFUELING_STATE", "Number")
UseVar("L:INI_GSX_INTEG_ENABLED", "Number")
UseVar("L:INI_ATC_MSG_SOUND", "Number")
UseVar("FUEL TOTAL QUANTITY WEIGHT", "Kilogram")
SubVar("TOTAL WEIGHT", "OnTotalWeightChange", "Kilogram")
UseInput("common_a340_cfm_cover_1_a340_cfm_cover_1")
UseInput("unknown_chock")
aircraft.InteractivePointAdd(10) --Bulk

local isGsxBoarding = false
local isGsxRefuel = false
local lastArrivalIcao = 0

local maxAux = 3000.025 * 2.0
local maxMain = 34140.025 * 2.0
local maxTrim = 5020.05
local maxCenters = 33900.05
local mainStage1 = 9000.05
local mainStage2 = 30500.05
local mainStage3 = 67200.05
local centerStage1 = 2600.05
local trimStage1 = 2400.05
local maxTankTotal = maxCenters + maxMain + maxAux + maxTrim

local lastFuelTargetKg = 0
local paxBoardDone = false
local payloadPaxKg = 0
local cargoBoardDone = false
local payloadCargoKg = 0
local lastTotalWeightKg = 0

function CheckIniConfig()
    if ReadVar("L:INI_GSX_INTEG_ENABLED") ~= 0 then
        Log("Setting INI Variable 'INI_GSX_INTEG_ENABLED' to '0'")
        WriteVar("L:INI_GSX_INTEG_ENABLED", 0)
    end
end

function BeforeWalkaroundSkip()
    CheckSetCovers()
end

function CheckSetCovers()
    if GetPluginSetting("Covers.RemoveStartup") and ReadVar("L:INI_COVERS_ENABLED") ~= 0 then
        WriteInput("common_a340_cfm_cover_1_a340_cfm_cover_1", 1)
    end
end

function GetIsCargo()
    return MatchAircraftString("Freighter")
end

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") ~= lastArrivalIcao
end

function GetSmartButtonRequest()
   return aircraft.AvionicPowered and (ReadVar("L:INI_CPT_INT_RAD_SWITCH") == 0 or ReadVar("L:INI_FO_INT_RAD_SWITCH") == 0)
end

function ResetSmartButton()
    WriteVar("L:INI_CPT_INT_RAD_SWITCH", 1)
    WriteVar("L:INI_FO_INT_RAD_SWITCH", 1)
end

function GetExternalPowerConnected()
    return ReadVar("L:INI_GEN_EXT_A_ONLINE") == 1 or ReadVar("L:INI_GEN_EXT_B_ONLINE") == 1
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

function GetTarget(target)
    if target then
        return 1
    else
        return 0
    end
end

function SetEquipmentPower(state, force)
    WriteVar("L:INI_GPU_AVAIL", GetTarget(state))
end

function GetHasChocks()
    return true
end

function GetEquipmentChocks()
    return ReadVar("L:INI_CHOCKS_ENABLED") == 1
end

function SetEquipmentChocks(state, force)
    local chockSet = GetEquipmentChocks()
    if state ~= chockSet or force then
        WriteInput("unknown_chock", 1)
    end
end

function GetHasPca()
    return true
end

function GetEquipmentPca()
    return ReadVar("L:INI_ACU_AVAIL") > 0
end

function SetEquipmentPca(state, force)
    WriteVar("L:INI_ACU_AVAIL", GetTarget(state))
end

function GetEngine1()
    return ReadVar("ENG COMBUSTION:1") ~= 0 or ReadVar("ENG COMBUSTION:2") ~= 0
end

function GetEngine2()
    return ReadVar("ENG COMBUSTION:3") ~= 0 or ReadVar("ENG COMBUSTION:4") ~= 0
end

function OnCouatlStarted()
    if GetIsCargo() then
        SetGenericSetting("Aircraft.DoorPreferred", 1)
    else
        SetGenericSetting("Aircraft.DoorPreferred", 2)
    end
end

function SetTanks(wingMain, wingAux, centers, trim)
    if isGsxRefuel then
        WriteVar("FUEL TANK LEFT AUX QUANTITY", (wingAux / 2.0) / FuelWeightKgPerGallon())
        WriteVar("FUEL TANK RIGHT AUX QUANTITY", (wingAux / 2.0) / FuelWeightKgPerGallon())

        WriteVar("FUEL TANK LEFT MAIN QUANTITY", (wingMain / 2.0) / FuelWeightKgPerGallon())
        WriteVar("FUEL TANK RIGHT MAIN QUANTITY", (wingMain / 2.0) / FuelWeightKgPerGallon())

        WriteVar("FUEL TANK CENTER QUANTITY", (centers / 2.0) / FuelWeightKgPerGallon())
        WriteVar("FUEL TANK CENTER2 QUANTITY", (centers / 2.0) / FuelWeightKgPerGallon())

        WriteVar("FUEL TANK EXTERNAL1 QUANTITY", trim / FuelWeightKgPerGallon())
    else
        WriteVar("L:INI_FUEL_WEIGHT_LEFT_OUTER", wingAux / 2.0)
        WriteVar("L:INI_FUEL_WEIGHT_RIGHT_OUTER", wingAux / 2.0)

        WriteVar("L:INI_FUEL_WEIGHT_LEFT_INNER", wingMain / 2.0)
        WriteVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", wingMain / 2.0)

        WriteVar("L:INI_FUEL_WEIGHT_CENTER", centers / 2.0)
        WriteVar("L:INI_FUEL_WEIGHT_CENTER2", centers / 2.0)

        WriteVar("L:INI_FUEL_WEIGHT_TRIM", trim)
    end
end

function SetFuelOnBoardKg(fuelOnBoardKg, fuelTargetKg)
    local mainTanks = 0
    local auxTanks = 0
    local centerTanks = 0
    local trimTanks = 0

    if fuelOnBoardKg >= maxTankTotal then
        centerTanks = maxCenters
        mainTanks = maxMain
        auxTanks = maxAux
        trimTanks = maxTrim
    elseif fuelOnBoardKg < mainStage1 then
        centerTanks = 0
        mainTanks = fuelOnBoardKg
        auxTanks = 0
        trimTanks = 0
    elseif fuelOnBoardKg < (mainStage1 + maxAux) then
        fuelOnBoardKg = fuelOnBoardKg - mainStage1
        centerTanks = 0
        mainTanks = mainStage1
        auxTanks = fuelOnBoardKg
        trimTanks = 0
    elseif fuelOnBoardKg < (mainStage2 + maxAux) then
        fuelOnBoardKg = fuelOnBoardKg - maxAux
        centerTanks = 0
        mainTanks = fuelOnBoardKg
        auxTanks = maxAux
        trimTanks = 0
    elseif fuelOnBoardKg < (mainStage2 + maxAux + trimStage1) then
        fuelOnBoardKg = fuelOnBoardKg - mainStage2 - maxAux
        centerTanks = 0
        mainTanks = mainStage2
        auxTanks = maxAux
        trimTanks = fuelOnBoardKg
    elseif fuelOnBoardKg < (mainStage3 + maxAux + trimStage1) then
        fuelOnBoardKg = fuelOnBoardKg - maxAux - trimStage1
        centerTanks = 0
        mainTanks = fuelOnBoardKg
        auxTanks = maxAux
        trimTanks = trimStage1
    elseif fuelOnBoardKg < (mainStage3 + maxAux + trimStage1 + centerStage1) then
        fuelOnBoardKg = fuelOnBoardKg - mainStage3 - maxAux - trimStage1
        centerTanks = fuelOnBoardKg
        mainTanks = mainStage3
        auxTanks = maxAux
        trimTanks = trimStage1
    elseif fuelOnBoardKg < maxTankTotal then
        fuelOnBoardKg = fuelOnBoardKg - mainStage3 - maxAux - trimStage1 - centerStage1
        centerTanks = math.min(centerStage1 + (fuelOnBoardKg * 0.90), maxCenters)
        mainTanks = math.min(mainStage3 + (fuelOnBoardKg * 0.04), maxMain)
        auxTanks = maxAux
        trimTanks = math.min(trimStage1 + (fuelOnBoardKg * 0.09), maxTrim)
    end

    --Log("Aux: " .. tostring(auxTanks) .. " | Main: " .. tostring(mainTanks) .. " | Center: " .. tostring(centerTanks) .. " | trimTank: " .. tostring(trimTanks))
    lastFuelTargetKg = fuelTargetKg
    SetTanks(mainTanks, auxTanks, centerTanks, trimTanks)
    Sleep(50)
    lastTotalWeightKg = ReadVar("TOTAL WEIGHT")
end

function RefuelActive()
    lastFuelTargetKg = 0
    isGsxRefuel = true
end

function OnRefuelHoseConnection(connected)
    WriteVar("L:INI_REFUEL_IN_PROGRESS", GetTarget(connected))
end

function GetPanelRefuel()
    return ReadVar("L:INI_REFUELING_DOOR_POSITION") > 0 or ReadVar("L:INI_REFUEL_IN_PROGRESS") > 0
end

function SetPanelRefuel(target)
    if ReadVar("L:INI_REFUELING_DOOR_POSITION") > 0 ~= target then
        Log("Setting Refuel Panel to " .. target)
        WriteVar("L:INI_REFUELING_DOOR_POSITION", GetTarget(target))
    end
    if not target and ReadVar("L:INI_REFUEL_IN_PROGRESS") > 0 ~= target then
        Log("Setting Refuel Message to " .. target)
        WriteVar("L:INI_REFUEL_IN_PROGRESS", GetTarget(target))
    end
end

function RefuelStop(fuelTargetKg, setTarget)
    if setTarget then
        Log("setTarget on RefuelStop")
        SetFuelOnBoardKg(fuelTargetKg, fuelTargetKg)
        Sleep(1000)
    end

    lastFuelTargetKg = fuelTargetKg
    lastTotalWeightKg = ReadVar("TOTAL WEIGHT")
    isGsxRefuel = false
    SendFuelingCompleted()
end

function RefuelCompleted()
    if isGsxRefuel then
        isGsxRefuel = false
        SendFuelingCompleted()
    end
end

function SetPayloadStations()
    local payloadTotalKg = payloadPaxKg + payloadCargoKg
    WriteVar("PAYLOAD STATION WEIGHT:1", 75)
    WriteVar("PAYLOAD STATION WEIGHT:2", 75)
    WriteVar("PAYLOAD STATION WEIGHT:3", payloadTotalKg * 0.0307)
    WriteVar("PAYLOAD STATION WEIGHT:4", payloadTotalKg * 0.0307)
    WriteVar("PAYLOAD STATION WEIGHT:5", payloadTotalKg * 0.0538)
    WriteVar("PAYLOAD STATION WEIGHT:6", payloadTotalKg * 0.0538)
    WriteVar("PAYLOAD STATION WEIGHT:7", payloadTotalKg * 0.0538)
    WriteVar("PAYLOAD STATION WEIGHT:8", payloadTotalKg * 0.0655)
    WriteVar("PAYLOAD STATION WEIGHT:9", payloadTotalKg * 0.0655)
    WriteVar("PAYLOAD STATION WEIGHT:10", payloadTotalKg * 0.0655)
    WriteVar("PAYLOAD STATION WEIGHT:11", payloadTotalKg * 0.2929)
    WriteVar("PAYLOAD STATION WEIGHT:12", payloadTotalKg * 0.242)
    WriteVar("PAYLOAD STATION WEIGHT:13", payloadTotalKg * 0.0449)
    Sleep(50)
    lastTotalWeightKg = ReadVar("TOTAL WEIGHT")
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function SetPaxOnBoard(paxOnBoard, weightPerPaxKg, paxTarget)
    payloadPaxKg = paxOnBoard * weightPerPaxKg
    SetPayloadStations()
    if isGsxBoarding and paxOnBoard >= paxTarget then
        paxBoardDone = true
    end

    if isGsxBoarding and cargoBoardDone and paxBoardDone then
        isGsxBoarding = false
        SendBoardingCompleted()
    end
end

function SetCargoOnBoard(cargoOnBoardKg, cargoTargetKg)
    payloadCargoKg = cargoOnBoardKg
    SetPayloadStations()
    if isGsxBoarding and cargoOnBoardKg >= cargoTargetKg then
        cargoBoardDone = true
    end

    if isGsxBoarding and cargoBoardDone and paxBoardDone then
        isGsxBoarding = false
        SendBoardingCompleted()
    end
end

function BoardActive(paxTarget, cargoTargetKg)
    payloadPaxKg = 0
    payloadCargoKg = 0
    paxBoardDone = false
    cargoBoardDone = false
    isGsxBoarding = true
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()

    if isGsxBoarding then
        paxBoardDone = true
        cargoBoardDone = true
        isGsxBoarding = false
        SendBoardingCompleted()
    end

    RunAfter(1000, "CheckTotalWeight()")
end

function SendFuelingCompleted()
    Log("SendFuelingCompleted")
    SendBus("FuelingCompleted", "", 2)
end

function SendBoardingCompleted()
    Log("SendBoardingCompleted")
    SendBus("BoardingCompleted", "", 2)
end

function DeboardCompleted()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
end

function CheckTotalWeight()
    OnTotalWeightChange(ReadVar("TOTAL WEIGHT"))
end

function OnTotalWeightChange(totalWeightKg)
    if not GetPluginSetting("Fix.PayloadReset") then
        return
    end

    local state = gsxController.AutomationController.State
    local currentFobKg = ReadVar("FUEL TOTAL QUANTITY WEIGHT")

    if (state == 2 or state == 3) and not isGsxBoarding and math.abs(lastTotalWeightKg - totalWeightKg) >= 1000 and math.abs(lastFuelTargetKg - currentFobKg) < 100 then
        Log("Fixing Payload Reset - last " .. tostring(lastTotalWeightKg) .. "kg vs current " .. tostring(totalWeightKg) .. "kg")
        Info("INI.A340: Payload Reset was fixed")
        SetPayloadStations()
    end

    if (state == 2 or state == 3) and not isGsxRefuel and math.abs(lastFuelTargetKg - currentFobKg) >= 1000 then
        Log("Fixing Fuel Reset - last " .. tostring(lastFuelTargetKg) .. "kg vs current " .. tostring(currentFobKg) .. "kg")
        Info("INI.A340: Fuel Reset was fixed")
        SetFuelOnBoardKg(lastFuelTargetKg, lastFuelTargetKg)
    end

    if not isGsxBoarding then
        lastTotalWeightKg = totalWeightKg
    end
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
        SetDoorArmState(false)
        CheckSetCovers()
        CheckIniConfig()
    elseif state == 4 then --taxiout
        SetDoorArmState(true)
        isGsxBoarding = false
        isGsxRefuel = false
    elseif state == 5 then --flight
        lastArrivalIcao = ReadVar("L:INI_ARR_ICAO_EFB")
        isGsxBoarding = false
        isGsxRefuel = false
    elseif state == 7 then --arrival
        SetDoorArmState(false)
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

function GetPanelLavatory()
    return ReadVar("L:INI_Waste_Water_Door") > 0
end

function SetPanelLavatory(target)
    if GetPanelLavatory() ~= target then
        Log("Setting Lavatory Panel to " .. target)
        WriteVar("L:INI_Waste_Water_Door", GetTarget(target))
    end
end

function GetPanelWater()
    return ReadVar("L:INI_Potable_Water_Door") > 0
end

function SetPanelWater(target)
    if GetPanelWater() ~= target then
        Log("Setting Water Panel to " .. target)
        WriteVar("L:INI_Potable_Water_Door", GetTarget(target))
    end
end

function IsDoorCustom(gsxDoor)
    return gsxDoor == 9 and not GetIsCargo()
end

function GetDoorCustom(aircraftDoor)
    local cargo = GetIsCargo()
    if (aircraftDoor == 19 and not cargo) or (aircraftDoor == 20 and cargo) then
        return aircraft.GetInteractivePoint(10)
    else
        return false
    end
end

function SetDoorCustom(aircraftDoor, target)
    local cargo = GetIsCargo()
    if (aircraftDoor == 19 and not cargo) or (aircraftDoor == 20 and cargo) then
        aircraft.SetInteractivePoint(10, target)
    end
end

function SetCargoDoorBulk(target)
    aircraft.SetInteractivePoint(10, target)
end

function GetCargoDoorBulk()
    return aircraft.GetInteractivePoint(10)
end

function NotifyCockpit(notification)
    if notification == 1 then
        WriteVar("L:INI_ATC_MSG_SOUND", 1)
        Sleep(100)
        WriteVar("L:INI_ATC_MSG_SOUND", 0)
    end
end