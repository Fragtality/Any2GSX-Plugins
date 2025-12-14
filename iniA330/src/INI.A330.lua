local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
UseVar("FUEL TANK LEFT AUX QUANTITY", "gallons")
UseVar("FUEL TANK LEFT MAIN QUANTITY", "gallons")
UseVar("FUEL TANK RIGHT MAIN QUANTITY", "gallons")
UseVar("FUEL TANK RIGHT AUX QUANTITY", "gallons")
UseVar("FUEL TANK EXTERNAL1 QUANTITY", "gallons")
UseVar("CG PERCENT", "percent")
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
    Info("Removing Covers in Walkaround")
    Sleep(250)

    if ReadVar("COVER ON:1") ~= 0 then
        SendInput("unknown_cover_left", 1)
    end
    if ReadVar("COVER ON:2") ~= 0    then
        SendInput("unknown_pitot_covers", 1)
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
    return true
end

function GetEquipmentChocks()
    return ReadVar("COVER ON:0") == 1
end

function SetEquipmentChocks(state, force)
    local chockSet = GetEquipmentChocks()
    if state ~= chockSet or force then
        SendInput("unknown_chocks", 1)
    end
end

function GetTankKg(name, type)
    if type == nil then
        type = "QUANTITY"
    end
    return ReadVar("FUEL TANK " .. name .. " " .. type) * FuelWeightKgPerGallon()
end

function SetTankKg(name, value)
    return WriteVar("FUEL TANK " .. name .. " QUANTITY", value / FuelWeightKgPerGallon())
end

function SetTanks(leftAux, leftMain, rightMain, rightAux, trim)
    local scalar = FuelWeightKgPerGallon()
    WriteVar("FUEL TANK LEFT AUX QUANTITY", leftAux / scalar)
    WriteVar("FUEL TANK LEFT MAIN QUANTITY", leftMain / scalar)
    WriteVar("FUEL TANK RIGHT MAIN QUANTITY", rightMain / scalar)
    WriteVar("FUEL TANK RIGHT AUX QUANTITY", rightAux / scalar)
    WriteVar("FUEL TANK EXTERNAL1 QUANTITY", trim / scalar)
end

local initialFobSet = false
local maxAux = 2891.0
local maxMain = 32967.0
local minMain = 4500.0
local trimMain = 15360.0
local minTrim = 2400.0
local maxTrim = 4889.7

function SetFuelOnBoardKg(fuelKg)
    if not initialFobSet and gsxController.GetService(2).State >= 4 then
        initialFobSet = true
    end

    local rightMain = 0
    local rightAux = 0
    local trim = 0
    if initialFobSet then
        local cg = ReadVar("CG PERCENT")
        if fuelKg < (minMain * 2.0) then -- filling main tanks only until 4500kg each
            rightMain = math.min((fuelKg / 2.0) + 0.5, minMain + 0.5)
            rightAux = 0
            trim = 0
        elseif fuelKg < ((minMain * 2.0) + (maxAux * 2.0)) then -- filling aux tanks only until 2891kg each
            rightMain = minMain + 0.5
            rightAux = math.max(((fuelKg - (minMain * 2.0)) / 2.0) + 0.5, 0)
            rightAux = math.min(rightAux, maxAux)
            trim = 0
        elseif fuelKg < ((trimMain * 2.0) + (maxAux * 2.0)) then -- filling main tanks only until 15360kg each
            rightMain = math.max(((fuelKg - (maxAux * 2.0)) / 2.0) + 0.5, minMain + 0.5)
            rightMain = math.min(rightMain, trimMain + 0.5)
            rightAux = maxAux + 0.5
            trim = 0
        elseif fuelKg < ((trimMain * 2.0) + (maxAux * 2.0) + minTrim) then -- filling trim tank only until 2400kg
            rightMain = trimMain + 0.5--math.max(((fuelKg - (maxAux * 2.0)) / 2.0) + 0.5, minMain)
            rightAux = maxAux + 0.5
            trim = math.max((fuelKg - (trimMain * 2.0) - (maxAux * 2.0)), 0)
            trim = math.min(trim, minTrim)
        elseif fuelKg < ((maxMain * 2.0) + (maxAux * 2.0) + minTrim) then -- filling main tanks only until 32960kg each
            rightMain = math.max(((fuelKg - (maxAux * 2.0) - minTrim) / 2.0) + 0.5, trimMain + 0.5)
            rightMain = math.min(rightMain, maxMain + 0.5)
            rightAux = maxAux + 0.5
            trim = minTrim
        else -- filling trim until 4780kg
            rightMain = maxMain + 0.5
            rightAux = maxAux + 0.5
            trim = math.max(fuelKg - (maxMain * 2.0) + (maxAux * 2.0), minTrim)
            trim = math.min(trim, maxTrim)
        end

        if cg < 24.1 and rightMain >= trimMain then
            Log("CG/Trim correction")
            trim = trim + 100
        end
    else
        rightMain = (fuelKg / 2.0) + 0.5
        initialFobSet = true
    end

    --Log("Aux: " .. tostring(rightAux) .. " | Main: " .. tostring(rightMain) .. " | Trim: " .. tostring(trim))
    SetTanks(rightAux, rightMain, rightMain, rightAux, trim)
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