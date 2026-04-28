local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
UseVar("L:INI_REFUEL_IN_PROGRESS", "Number")
UseVar("L:INI_REFUELING_DOOR_POSITION", "Number")
UseVar("L:INI_DEP_ICAO_EFB", "Number")
UseVar("L:INI_ARR_ICAO_EFB", "Number")
UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_AC_LIGHTS_FAILURE", "Number")
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
UseVar("L:FSDT_GSX_REFUELING_STATE", "Number")
UseVar("L:FSDT_GSX_SETTINGS_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_PROGRESS_REFUEL", "Number")
UseVar("L:FSDT_GSX_SETTINGS_DETECT_CUST_REFUEL", "Number")
UseVar("L:FSDT_GSX_SET_DETECT_CUST_REFUEL", "Number")
UseVar("L:INI_FUEL_WEIGHT_CENTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_CENTER2", "Number")
UseVar("L:INI_FUEL_WEIGHT_LEFT_INNER", "Number")
UseVar("L:INI_FUEL_WEIGHT_LEFT_OUTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", "Number")
UseVar("L:INI_FUEL_WEIGHT_RIGHT_OUTER", "Number")
UseVar("L:INI_FUEL_WEIGHT_TRIM", "Number")
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
SubVar("PAYLOAD STATION WEIGHT:3", "OnPayloadChange", "Kilogram")

function BeforeWalkaroundSkip()
    CheckSetCovers()
end

function CheckSetCovers()
    if GetPluginSetting("Covers.RemoveStartup") and ReadVar("L:INI_COVERS_ENABLED") ~= 0 then
        SendInput("common_a340_cfm_cover_1_a340_cfm_cover_1", 1)
    end
end

function GetIsCargo()
    return MatchAircraftString("Freighter")
end

function GetReadyDepartureServices()
    return aircraft.AvionicPowered and aircraft.LightNav and ReadVar("L:INI_DEP_ICAO_EFB") > 0 and ReadVar("L:INI_ARR_ICAO_EFB") > 0
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

function SetEquipmentPower(state, force)
    if GetExternalPowerConnected() and -not state and -not force then
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
    return ReadVar("L:INI_CHOCKS_ENABLED") == 1
end

function SetEquipmentChocks(state, force)
    local chockSet = GetEquipmentChocks()
    if state ~= chockSet or force then
        SendInput("unknown_chock", 1)
    end
end

function GetHasPca()
    return true
end

function GetEquipmentPca()
    return ReadVar("L:INI_ACU_AVAIL") > 0
end

function SetEquipmentPca(state, force)
    if not state and not aircraft.IsApuRunning and not aircraft.IsApuBleedOn and not force then
        return
    end

    if state then
        WriteVar("L:INI_ACU_AVAIL", 1)
    else
        WriteVar("L:INI_ACU_AVAIL", 0)
    end
end

function GetEngine1()
    return ReadVar("ENG COMBUSTION:1") ~= 0 or ReadVar("ENG COMBUSTION:2") ~= 0
end

function GetEngine2()
    return ReadVar("ENG COMBUSTION:3") ~= 0 or ReadVar("ENG COMBUSTION:4") ~= 0
end

function GetTankKg(name)
    if type == nil then
        type = "QUANTITY"
    end
    return ReadVar("L:INI_FUEL_WEIGHT_" .. name)
end

function GetCenterTankKg()
    return ReadVar("L:INI_FUEL_WEIGHT_CENTER") + ReadVar("L:INI_FUEL_WEIGHT_CENTER2")
end

local maxAux = 3000.0
local maxMain = 34140.0
local minMain = 4500.0
local trimMain = 15240.0
local minTrim = 2400.0
local maxTrim = 5020.0
local maxCenters = 33900.0

local tankAux = 0
local tankMain = 3040
local tankCenters = 0
local tankTrim = 0

function SetTanks(wingMain, wingAux, centers, trim)
    tankAux = math.min(wingAux, maxAux)
    WriteVar("L:INI_FUEL_WEIGHT_LEFT_OUTER", tankAux)
    WriteVar("L:INI_FUEL_WEIGHT_RIGHT_OUTER", tankAux)

    tankMain = math.min(wingMain, maxMain)
    WriteVar("L:INI_FUEL_WEIGHT_LEFT_INNER", tankMain)
    WriteVar("L:INI_FUEL_WEIGHT_RIGHT_INNER", tankMain)

    tankCenters = math.min(centers, maxCenters)
    WriteVar("L:INI_FUEL_WEIGHT_CENTER", tankCenters / 2.0)
    WriteVar("L:INI_FUEL_WEIGHT_CENTER2", tankCenters / 2.0)

    tankTrim = math.min(trim, maxTrim)
    WriteVar("L:INI_FUEL_WEIGHT_TRIM", tankTrim)

    -- Log("tankAux: " .. tostring(tankAux) .. " | tankMain: " .. tostring(tankMain) .. " | tankCenters: " .. tostring(tankCenters) .. " | tankTrim: " .. tostring(tankTrim))
end

function RefuelTick(isFuelInc, stepKg, fuelOnBoardKg, fuelTargetKg)
    local distMain = 0
    local distAux = 0
    local distCenter = 0
    local distTrim = 0
    -- Log("Tick - Step: " .. tostring(stepKg) .. " | FOB: " ..tostring(fuelOnBoardKg))
    if tankMain < minMain then -- filling main tanks only until 4500kg each
        distMain = 1
    elseif tankAux < maxAux then -- filling aux + main tanks until 3000kg aux
        distMain = 0.1
        distAux = 0.9
    elseif tankMain < trimMain then -- filling main tanks only until 15240kg each
        distMain = 1
    elseif tankTrim < minTrim then -- filling trim tank additionally until 2400kg
        distMain = 0.85
        distTrim = 0.15
    elseif tankMain < maxMain then -- filling main tanks only until 34140kg each
        distMain = 1
    else -- filling center and trim until full (96/4 % split)
        distCenter = 0.96
        distTrim = 0.04
    end

    -- Log("distAux: " .. tostring(distAux) .. " | distMain: " .. tostring(distMain) .. " | distCenter: " .. tostring(distCenter) .. " | distTrim: " .. tostring(distTrim))
    local halfStep = stepKg / 2.0
    SetTanks(tankMain + (halfStep * distMain), tankAux + (halfStep * distAux), tankCenters + (stepKg * distCenter), tankTrim + (stepKg * distTrim))
end

function SetFuelOnBoardKg(fuelOnBoardKg, fuelTargetKg)
    local wingMain = 0
    local wingAux = 0
    local centers = 0
    local trim = 0
    if fuelOnBoardKg < (minMain * 2.0) then -- filling main tanks only until 4500kg each
        wingMain = math.min((fuelOnBoardKg / 2.0), minMain)
        wingAux = 0
        centers = 0
        trim = 0
    elseif fuelOnBoardKg < ((minMain * 2.0) + (maxAux * 2.0)) then -- filling aux tanks only until 3000kg each
        wingMain = minMain
        wingAux = math.max(((fuelOnBoardKg - (minMain * 2.0)) / 2.0), 0)
        wingAux = math.min(wingAux, maxAux)
        centers = 0
        trim = 0
    elseif fuelOnBoardKg < ((trimMain * 2.0) + (maxAux * 2.0)) then -- filling main tanks only until 15240kg each
        wingMain = math.max(((fuelOnBoardKg - (maxAux * 2.0)) / 2.0), minMain)
        wingMain = math.min(wingMain, trimMain)
        wingAux = maxAux
        centers = 0
        trim = 0
    elseif fuelOnBoardKg < ((trimMain * 2.0) + (maxAux * 2.0) + minTrim) then -- filling trim tank additionally until 2400kg
        wingAux = maxAux
        local remain = math.max((fuelOnBoardKg - (trimMain * 2.0) - (maxAux * 2.0)), 0)
        wingMain = trimMain + (remain * 0.85)
        trim = math.min(remain * 0.15, minTrim)
        centers = 0
    elseif fuelOnBoardKg < ((maxMain * 2.0) + (maxAux * 2.0) + minTrim) then -- filling main tanks only until 34140kg each
        wingMain = math.max(((fuelOnBoardKg - (maxAux * 2.0) - minTrim) / 2.0), trimMain)
        wingMain = math.min(wingMain, maxMain)
        wingAux = maxAux
        trim = minTrim
        centers = 0
    else -- filling center and trim until full (96/4 % split)
        wingMain = maxMain
        wingAux = maxAux
        local centerTrim = fuelOnBoardKg - (maxMain * 2.0) - (maxAux * 2.0) - minTrim
        centers = math.max(0, centerTrim * 0.96)
        centers = math.min(centers, maxCenters)
        trim = math.max(minTrim, minTrim + (centerTrim * 0.04))
        trim = math.min(trim, maxTrim)
    end
    -- Log("Aux: " .. tostring(wingAux) .. " | Main: " .. tostring(wingMain) .. " | Center: " .. tostring(centers) .. " | Trim: " .. tostring(trim))
    SetTanks(wingMain, wingAux, centers, trim)
end

local refuelWasOverridden = false

function RefuelActive()
    if refuelWasOverridden then
        return
    end
    refuelWasOverridden = true

    gsxController.GetService(2).StateOverride = 5
    WriteVar("L:FSDT_GSX_REFUELING_STATE", 2)
end

function SetPanelRefuel(target)
    WriteVar("L:INI_REFUELING_DOOR_POSITION", target and 1 or 0)
end

function RefuelStart(fuelTargetKg)
    WriteVar("L:INI_REFUEL_IN_PROGRESS", 1)

    tankAux = GetTankKg("RIGHT_OUTER")
    tankMain = GetTankKg("RIGHT_INNER")
    tankCenters = GetTankKg("CENTER") * 2.0
    tankTrim = GetTankKg("TRIM")
end

function RefuelStop(fuelTargetKg, setTarget)
    if setTarget then
        SetFuelOnBoardKg(fuelTargetKg)
    end

    WriteVar("L:INI_REFUEL_IN_PROGRESS", 0)
end

local payloadPaxKg = 0
local payloadCargoKg = 0
local boardCompleted = false

function SetPayloadStations()
    local payloadTotalKg = payloadPaxKg + payloadCargoKg
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
end

function SetPayloadEmpty()
    payloadPaxKg = 0
    payloadCargoKg = 0
    SetPayloadStations()
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
    boardCompleted = false
end

function BoardCompleted(paxTarget, weightPerPaxKg, cargoTargetKg)
    payloadPaxKg = paxTarget * weightPerPaxKg
    payloadCargoKg = cargoTargetKg
    SetPayloadStations()
    boardCompleted = true
end

function OnPayloadChange(load)
    local phase = gsxController.AutomationController.State
    if GetPluginSetting("Fix.PayloadReset") and boardCompleted and load < 1 and (phase == 2 or phase == 3) then
        Log("Fixing Payload Reset")
        SetPayloadStations()
    end
end

function DeboardCompleted()
    payloadPaxKg = 0
    payloadCargoKg = 0
    boardCompleted = false
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
        SetDoorArmState(false)
        CheckSetCovers()
    elseif state == 4 then --taxiout
        SetDoorArmState(true)
        refuelWasOverridden = false
        boardCompleted = false
    elseif state == 5 then --flight
        refuelWasOverridden = false
        boardCompleted = false
    elseif state == 7 then --arrival
        refuelWasOverridden = false
        boardCompleted = false
        SetDoorArmState(false)
    end
end

function SetPanelWater(target)
    local door = ReadVar("L:INI_Potable_Water_Door")
    if (door == 0 and target) or (door == 1 and not target) then
        Log("Toggle Water Door")
        SendInput("common_pot_water_door_pot_water_door", 1)
    end
end

function SetPanelLavatory(target)
    local door = ReadVar("L:INI_Waste_Water_Door")
    if (door == 0 and target) or (door == 1 and not target) then
        Log("Toggle Waste Door")
        SendInput("common_waste_door_waste_door", 1)
    end
end