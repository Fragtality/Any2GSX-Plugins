UseVar("L:INI_GPU_AVAIL", "Number")
UseVar("L:INI_CHOCKS_ENABLED", "Number")
UseVar("L:A22X AC Ess Bus Voltage", "Volts")
UseVar("L:A22X Flight Plan Modified", "Number")
UseVar("L:A22X APU RPM", "Number")              --Actually N1
UseVar("L:A22X APU Bleed Off", "Number")
UseVar("L:A22X Passenger Count", "Number")      --unused?
UseVar("L:A22X Mech Call", "Number")
UseVar("PAYLOAD STATION WEIGHT:3", "Kilograms") --FWD Pax
UseVar("PAYLOAD STATION WEIGHT:4", "Kilograms") --FWD Cargo
UseVar("PAYLOAD STATION WEIGHT:5", "Kilograms") --AFT Pax
UseVar("PAYLOAD STATION WEIGHT:6", "Kilograms") --AFT Cargo
for i = 0, 7 do
    UseVar("COVER ON:" .. tostring(i), "Bool")
end
for i = 0, 7 do
    UseVar("INTERACTIVE POINT GOAL:" .. tostring(i), "percent over 100")
end
UseVar("L:A22x RDC Powered", "Number")
UseVar("L:A22X External Power In Use", "Number")
SubVar("L:A22X RDC Powered", "SetCorrectFuel", "Number")
SubVar("L:A22X External Power In Use", "MonitorExtPower", "Number")


local gsxController = GetGsxController()
local aircraft = GetAircraftPlugin()
local fuelCorrected = false
local initialFuelTarget = 0
local safeToRemoveExtPower = false

function RemoveCovers()
    if not GetPluginSetting("Covers.RemoveStartup") then
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
    Log("Set Interactive Point #" .. tostring(index) .. " to Target " .. tostring(value))
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

function SetCorrectFuel()
    if ReadVar("L:A22X RDC Powered") ~= 1 or fuelCorrected then
        return
    end
    local state = gsxController.AutomationState
    if aircraft.FuelOnBoardKg ~= initialFuelTarget and (state == 1 or state == 2) then
        fuelCorrected = true
        SetFuelOnBoardKg(initialFuelTarget, initialFuelTarget)
    end
end

function MonitorExtPower()
    if ReadVar("L:A22X External Power In Use") == 1 then
        safeToRemoveExtPower = false
    else
        Sleep(7000)
        safeToRemoveExtPower = true
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

function BeforeWalkaroundSkip()
    RemoveCovers()
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
    elseif safeToRemoveExtPower then
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
    local stage = gsxController.AutomationState
    if stage > 2 and stage < 8 and state and not force then
        return
    end

    if state then
        if GetInteractivePoint(4) ~= 1 then
            SetInteractivePoint(4, 1)
        end
        if GetInteractivePoint(5) ~= 1 then
            SetInteractivePoint(5, 1)
        end
    else
        if GetInteractivePoint(4) ~= 0 then
            SetInteractivePoint(4, 0)
        end
        if GetInteractivePoint(5) ~= 0 then
            SetInteractivePoint(5, 0)
        end
    end
end

function DoorsAllClose()
    for i = 0, 7 do
        if GetInteractivePoint(i) > 0 then
            SetInteractivePoint(i, 0)
        end
    end
end

function SetFuelOnBoardKg(fuelOnBoardKg, targetKg)
    if ReadVar("L:A22X RDC Powered") ~= 1 then
        fuelCorrected = false
        initialFuelTarget = fuelOnBoardKg
        return
    end
    fuelCorrected = true
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
