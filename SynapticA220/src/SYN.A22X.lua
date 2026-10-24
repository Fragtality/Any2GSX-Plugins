UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:A22X AC Ess Bus Voltage", "Volts")
UseVar("L:A22X APU RPM", "Number")
UseVar("L:A22X APU Bleed Off", "Number")
UseVar("L:A22X Passenger Count", "Number")
UseVar("L:A22X Mech Call", "Number")
UseVar("L:A22X RDC Powered", "Number")
UseVar("PAYLOAD STATION WEIGHT:3", "Kilograms") --FWD Pax
UseVar("PAYLOAD STATION WEIGHT:4", "Kilograms") --FWD Cargo
UseVar("PAYLOAD STATION WEIGHT:5", "Kilograms") --AFT Pax
UseVar("PAYLOAD STATION WEIGHT:6", "Kilograms") --AFT Cargo

for i = 0, 7 do
    UseVar("COVER ON:" .. tostring(i), "Bool")
end

SubVar("L:A22X RDC Powered", "MonitorRDCPower", "Number")
SubVar("L:A22X External Power In Use", "MonitorExtPower", "Number")

local aircraft = GetAircraftPlugin()
local gsxController = GetGsxController()
local RDCPowered = ReadVar("L:A22X RDC Powered") == 1
local fuelCorrected = true
local fuelToCorrectAmountKg = 0
local safeToRemoveExtPower = true
local pendingRemoval = false
local lastDisconnectTime = 0
local flightplanRequested = false
local subbedToFlightplanCommBusEvent = false

aircraft.InteractivePointAdd(0) --L1
aircraft.InteractivePointAdd(4) --AFT Cargo
aircraft.InteractivePointAdd(5) --FWD Cargo

function RemoveCovers()
    if not (GetPluginSetting("Covers.RemoveStartup") and gsxController.IsMsfs2024) then
        return
    end

    for i = 0, 7 do
        if ReadVar("COVER ON:" .. tostring(i)) then
            WriteVar("COVER ON:" .. tostring(i), 0)
        end
    end
end

function SetPaxStations(paxCount, payloadPaxKg)
    WriteVar("L:A22X Passenger Count", paxCount)
    WriteVar("PAYLOAD STATION WEIGHT:3", payloadPaxKg / 2)
    WriteVar("PAYLOAD STATION WEIGHT:5", payloadPaxKg / 2)
end

function SetCargoStations(payloadCargoKg)
    WriteVar("PAYLOAD STATION WEIGHT:4", payloadCargoKg * 0.395161)
    WriteVar("PAYLOAD STATION WEIGHT:6", payloadCargoKg * 0.604839)
end

function MonitorRDCPower(RDCState)
    if RDCState == 1 then
        RDCPowered = true
        if not fuelCorrected then
            Log("Setting fuel on power-up")
            SetFuelOnBoardKg(fuelToCorrectAmountKg, fuelToCorrectAmountKg)
            fuelCorrected = true
        end
    else
        RDCPowered = false
    end
end

function CheckExtPowerSafe()
    if os.time() - lastDisconnectTime < 6.9 then
        return
    end

    if not aircraft.PowerConnected then
        safeToRemoveExtPower = true

        if pendingRemoval then
            Log("Removing external power")
            pendingRemoval = false
            SetEquipmentPower(false, true)
        end
    end
end

function MonitorExtPower(extPwrState)
    if not GetPluginSetting("ExtPwr.FaultProtection") then
        safeToRemoveExtPower = true
        return
    end

    if extPwrState == 1 then
        safeToRemoveExtPower = false
        pendingRemoval = false
    else
        safeToRemoveExtPower = false
        lastDisconnectTime = os.time()
        RunAfter(7000, "CheckExtPowerSafe()")
    end
end

function SubToFlightplanCommBusEvent()
    if not subbedToFlightplanCommBusEvent and not flightplanRequested then
        Log("Subscribed to Flightplan CommBus Event")
        subbedToFlightplanCommBusEvent = true
        SubBus("A220.Flight Plan Request", 2, "OnFlightplanRequest")
    end
end

function UnsubFromFlightplanCommBusEvent()
    if subbedToFlightplanCommBusEvent then
        Log("Unsubscribed from Flightplan CommBus Event")
        subbedToFlightplanCommBusEvent = false
        UnsubBus("A220.Flight Plan Request")
    end
end

function OnFlightplanRequest(evt, data)
    -- Log("Received CommBus Event: " .. evt .. " with data: " .. data)
    if string.find(data, "UplinkFlightPlan", 1, true) then
        Log("Flightplan Uplink detected")
        flightplanRequested = true
        UnsubFromFlightplanCommBusEvent()
    end
end

function OnAutomationStateChange(state)
    if state == 1 then --Prep phase
        RemoveCovers()
        SubToFlightplanCommBusEvent()
    elseif state == 2 or state == 3 then --Departure/Pushback phase
        UnsubFromFlightplanCommBusEvent()
    elseif state == 7 then               --Arrival phase
        safeToRemoveExtPower = true
        pendingRemoval = false
        lastDisconnectTime = 0
        flightplanRequested = false
        SubToFlightplanCommBusEvent()
    end
end

function GetReadyDepartureServices()
    return GetAvionicPowered() and aircraft.LightNav and flightplanRequested
end

function GetSmartButtonRequest()
    return GetAvionicPowered() and ReadVar("L:A22X Mech Call") > 0
end

function ResetSmartButton()
    WriteVar("L:A22X Mech Call", 0)
end

function GetAvionicPowered()
    return ReadVar("L:A22X AC Ess Bus Voltage") > 109
end

function GetApuRunning()
    return ReadVar("L:A22X APU RPM") > 99
end

function GetApuBleedOn()
    return GetApuRunning() and ReadVar("L:A22X APU Bleed Off") == 0
end

function GetExternalPowerAvailable()
    if pendingRemoval then
        return false
    end

    return ReadVar("L:INI_GPU_AVAIL") > 0
end

function GetHasFobSaveRestore()
    return true
end

function GetHasFuelSync()
    return true
end

function GetCanSetPayload()
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
    if state then
        pendingRemoval = false
        WriteVar("L:INI_GPU_AVAIL", 1)
    elseif safeToRemoveExtPower or force then
        pendingRemoval = false
        WriteVar("L:INI_GPU_AVAIL", 0)
    else
        Log("Blocking external power removal for 7 seconds")
        pendingRemoval = true
    end
end

function SetEquipmentChocks(state, force)
    if state then
        WriteVar("L:INI_CHOCKS_ENABLED", 1)
    else
        WriteVar("L:INI_CHOCKS_ENABLED", 0)
    end
end

function GetAircraftDefaultDoor(gsxDoor)
    if gsxDoor == GsxDoor.PaxDoor1 then
        return AircraftDoor.L1
    elseif gsxDoor == GsxDoor.PaxDoor4 then
        return AircraftDoor.L2
    elseif gsxDoor == GsxDoor.ServiceDoor1 then
        return AircraftDoor.R1
    elseif gsxDoor == GsxDoor.ServiceDoor2 then
        return AircraftDoor.R2
    elseif gsxDoor == GsxDoor.CargoDoor1 then
        return AircraftDoor.CargoFront
    elseif gsxDoor == GsxDoor.CargoDoor2 then
        return AircraftDoor.CargoRear
    else
        return AircraftDoor.None
    end
end

function IsDoorCustom(gsxDoor)
    if gsxDoor == 1 or gsxDoor >= 7 then
        return true
    else
        return false
    end
end

function SetDoorCustom(aircraftDoor, target)
    local index = -1
    local door = nil
    if aircraftDoor == 1 then --L1
        door = "L1"
        index = 0
    elseif aircraftDoor == 17 then --FWD Cargo
        door = "FWD Cargo"
        index = 5
    elseif aircraftDoor == 18 then --AFT Cargo
        door = "AFT Cargo"
        index = 4
    end

    if index >= 0 then
        Info((target and "Opening " or "Closing ") .. door .. " door")
        aircraft.SetInteractivePoint(index, target)
    end
end

function GetDoorCustom(aircraftDoor)
    local index = -1
    if aircraftDoor == 1 then      --L1
        index = 0
    elseif aircraftDoor == 17 then --FWD Cargo
        index = 5
    elseif aircraftDoor == 18 then --AFT Cargo
        index = 4
    end

    if index >= 0 then
        return aircraft.GetInteractivePoint(index)
    else
        return false
    end
end

function SetFuelOnBoardKg(fuelOnBoardKg, targetKg)
    if not RDCPowered then
        Log("Deferred FuelEvent")
        fuelCorrected = false
        fuelToCorrectAmountKg = fuelOnBoardKg
        return
    end

    local payload = '{"fuelAmountInKg": ' .. math.floor(fuelOnBoardKg + 0.5) .. '}'
    SendBus("FuelEvent", payload, 2)
end

function SetPayloadEmpty()
    SetPaxStations(0, 0)
    SetCargoStations(0)
end

function SetPaxOnBoard(paxOnBoard, weightPerPaxKg, paxTarget)
    SetPaxStations(paxOnBoard, paxOnBoard * weightPerPaxKg)
end

function SetCargoOnBoard(cargoOnBoardKg, cargoTargetKg)
    SetCargoStations(cargoOnBoardKg)
end

function BoardActive(paxTarget, cargoTargetKg)
    SetPayloadEmpty()
end

function OnFlightplanImport(ofp)
    if GetPluginSetting("PaxWeight.OvrdPaxWeight") then
        Log("Updated flightplan passenger weight")
        aircraft.Flightplan.UpdatePassengerWeight(79.3786)
        Log("Updated flightplan aircraft OEW")
        aircraft.Flightplan.UpdateEmptyOperatingWeightKg(aircraft.Flightplan.AircraftEmptyOewKg + 154.22128)
    end
end
