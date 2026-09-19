UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:A22X AC Ess Bus Voltage", "Volts")
UseVar("L:A22X Flight Plan Modified", "Number")
UseVar("L:A22X APU RPM", "Number")
UseVar("L:A22X APU Bleed Off", "Number")
UseVar("L:A22X Passenger Count", "Number")
UseVar("L:A22X Mech Call", "Number")
UseVar("PAYLOAD STATION WEIGHT:3", "Kilograms") --FWD Pax
UseVar("PAYLOAD STATION WEIGHT:4", "Kilograms") --FWD Cargo
UseVar("PAYLOAD STATION WEIGHT:5", "Kilograms") --AFT Pax
UseVar("PAYLOAD STATION WEIGHT:6", "Kilograms") --AFT Cargo
for i = 0, 7 do
    UseVar("COVER ON:" .. tostring(i), "Bool")
    UseVar("INTERACTIVE POINT GOAL:" .. tostring(i), "Percent over 100") --1L/1R/2L/2R/AC/FC/OWL/OWR
end

SubVar("L:A22X RDC Powered", "MonitorRDCPower", "Number")
SubVar("L:A22X External Power In Use", "MonitorExtPower", "Number")
SubVar("INTERACTIVE POINT GOAL:0", "MonitorDoor1L", "Percent over 100")
SubVar("INTERACTIVE POINT GOAL:4", "MonitorDoorAftCargo", "Percent over 100")
SubVar("INTERACTIVE POINT GOAL:5", "MonitorDoorFwdCargo", "Percent over 100")

local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
local RDCPowered = false
local fuelCorrected = true
local fuelCorrectedAmountKg = 0
local safeToRemoveExtPower = true
local inhibitDoor1L = false
local inhibitDoorCargoAft = false
local inhibitDoorCargoFwd = false

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

function GetInteractivePoint(index)
    return ReadVar("INTERACTIVE POINT GOAL:" .. tostring(index))
end

function SetInteractivePoint(index, value)
    return WriteVar("INTERACTIVE POINT GOAL:" .. tostring(index), value)
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
            SetFuelOnBoardKg(fuelCorrectedAmountKg, fuelCorrectedAmountKg)
            fuelCorrected = true
        end
    else
        RDCPowered = false
    end
end

function CheckExtPowerSafe()
    if not aircraft.PowerConnected then
        safeToRemoveExtPower = true
    end
end

function MonitorExtPower(extPwrState)
    if not GetPluginSetting("ExtPwr.FaultProtection") then
        return
    end

    if extPwrState == 1 then
        safeToRemoveExtPower = false
    else
        RunAfter(7000, "CheckExtPowerSafe()")
    end
end

function InhibitDoor(door, state)
    if (door & 0x1) ~= 0 then
        inhibitDoorCargoAft = state
    end
    if (door & 0x2) ~= 0 then
        inhibitDoorCargoFwd = state
    end
    if (door & 0x4) ~= 0 then
        inhibitDoor1L = state
    end
end

function MonitorDoor1L(state)
    if state < 1 and inhibitDoor1L then
        SetInteractivePoint(0, 1)
    end
end

function MonitorDoorAftCargo(state)
    if state < 1 and inhibitDoorCargoAft then
        SetInteractivePoint(4, 1)
    end
end

function MonitorDoorFwdCargo(state)
    if state < 1 and inhibitDoorCargoFwd then
        SetInteractivePoint(5, 1)
    end
end

function OnAutomationStateChange(state)
    if state == 1 or state == 2 then
        RemoveCovers()
    elseif state > 3 and state < 7 then
        InhibitDoor(7, false)
    end
end

function GetReadyDepartureServices()
    return GetAvionicPowered() and aircraft.LightNav and ReadVar("L:A22X Flight Plan Modified") > 0
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
    return ReadVar("L:A22X APU RPM") > 99 and ReadVar("L:A22X APU Bleed Off") == 0
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

function SetExternalPowerAvailable(state)
    if aircraft.PowerConnected and not state then
        return
    end

    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    elseif safeToRemoveExtPower then
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function SetEquipmentPower(state, force)
    if aircraft.PowerConnected and not state and not force then
        return
    end

    if state then
        WriteVar("L:INI_GPU_AVAIL", 1)
    elseif safeToRemoveExtPower or force then
        WriteVar("L:INI_GPU_AVAIL", 0)
    end
end

function SetEquipmentChocks(state, force)
    if not aircraft.ParkingBrake and not state and not force then
        return
    end

    if state then
        WriteVar("L:INI_CHOCKS_ENABLED", 1)
    else
        WriteVar("L:INI_CHOCKS_ENABLED", 0)
    end
end

function GetHasOpenDoors()
    for i = 0, 7 do
        if GetInteractivePoint(i) > 0 then
            return true
        end
    end

    return false
end

function SetCargoDoors(state, force)
    if state then
        if GetInteractivePoint(4) ~= 1 then
            SetInteractivePoint(4, 1)
        end
        if GetInteractivePoint(5) ~= 1 then
            SetInteractivePoint(5, 1)
        end
    else
        if GetInteractivePoint(4) ~= 0 then
            InhibitDoor(1, false)
            SetInteractivePoint(4, 0)
        end
        if GetInteractivePoint(5) ~= 0 then
            InhibitDoor(2, false)
            SetInteractivePoint(5, 0)
        end
    end
end

function DoorsAllClose()
    InhibitDoor(7, false)
    for i = 0, 7 do
        if GetInteractivePoint(i) > 0 then
            SetInteractivePoint(i, 0)
        end
    end
end

function OnLoaderAttached(door, attached)
    --door{8,7}->index{4,5}
    local index = 12 - door
    local inhibitIndex = index - 3

    if attached then
        InhibitDoor(inhibitIndex, true)
        SetInteractivePoint(index, 1)
    else
        InhibitDoor(inhibitIndex, false)
        SetInteractivePoint(index, 0)
    end
end

function OnJetwayStateChange(state, DoorPaxHandling)
    if not DoorPaxHandling then
        return
    end

    if state == 5 then
        InhibitDoor(4, true)
        SetInteractivePoint(0, 1)
    else
        InhibitDoor(4, false)
        SetInteractivePoint(0, 0)
    end
end

function OnStairStateChange(state, DoorStairHandling)
    if not DoorStairHandling then
        return
    end

    if state == 5 then
        InhibitDoor(4, true)
        SetInteractivePoint(0, 1)
    else
        InhibitDoor(4, false)
        SetInteractivePoint(0, 0)
    end
end

function SetFuelOnBoardKg(fuelOnBoardKg, targetKg)
    if not RDCPowered then
        fuelCorrected = false
        fuelCorrectedAmountKg = fuelOnBoardKg
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
