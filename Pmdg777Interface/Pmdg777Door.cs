using CFIT.AppLogger;
using System;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public enum PmdgDoorState
    {
        Open = 0,
        Closed = 1,
        ClosedArmed = 2,
        Closing = 3,
        Opening = 4,
    }

    public enum DoorMonitorAction
    {
        Unmonitored = 0,
        Monitored = 1,
        KeepClosed = 2,
    }

    public enum PmdgDoorIndex
    {
        Pax1L = 0,
        Pax1R = 1,
        Pax2L = 2,
        Pax2R = 3,
        Pax3L = 4,
        Pax3R = 5,
        Pax4L = 6,
        Pax4R = 7,
        Pax5L = 8,
        Pax5R = 9,
        CargoFwd = 10,
        CargoAft = 11,
        CargoMain = 12,
        CargoBulk = 13,
        Avionics = 14,
        EEAccess = 15,
    }

    public enum PmdgCargoLight
    {
        Ceiling = 1121,
        Sidewall = 1122,
        ExtCam = 1123,
        SillLoad = 1124,
    }

    public class Pmdg777Door(Pmdg777Aircraft aircraft, PmdgDoorIndex index, int evtCode, DoorMonitorAction monitoring = DoorMonitorAction.Monitored)
    {
        protected virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        protected virtual PMDG_777X_Data PMDG_777X_Data => Aircraft.PMDG_777X_Data;
        public virtual PmdgDoorIndex Index { get; } = index;
        public virtual int EventCode { get; } = evtCode;
        public virtual PmdgDoorState State => (PmdgDoorState)PMDG_777X_Data.DOOR_state[(int)Index];
        public virtual PmdgDoorState Target { get; set; } = PmdgDoorState.ClosedArmed;
        public virtual DoorMonitorAction Monitoring { get; set; } = monitoring;
        public virtual int DefaultInhibitTime { get; set; } = 1500;
        protected virtual DateTime InhibitTime { get; set; } = DateTime.MinValue;
        public virtual bool IsInhibited => DateTime.Now < InhibitTime;
        public virtual bool IsMoving => IsDoorMoving(State);
        public virtual bool IsClosed => IsDoorClosed(State);
        public virtual bool IsOpen => IsDoorOpen(State);

        public virtual void InhibitUpdates(int ms = -1)
        {
            InhibitTime = DateTime.Now + TimeSpan.FromMilliseconds(ms < 0 ? DefaultInhibitTime : ms);
        }

        public virtual async Task SendDoorCode()
        {
            Logger.Information($"Operating Door {Index}");
            string evt = Pmdg777Aircraft.GetEventName(EventCode);
            Logger.Debug($"Sending Door Event: {EventCode} -> {evt}");
            await Aircraft.SimStore[evt]!?.WriteValue(Pmdg777Aircraft.EvtLeftSingle); ;
        }

        public virtual void SetDoor(PmdgDoorState target)
        {
            if (IsDoorMoving(State))
            {
                Logger.Debug($"Door {Index} already moving");
                Target = target;
                InhibitUpdates(5000);
            }
            else if ((State == PmdgDoorState.Closed && target == PmdgDoorState.ClosedArmed)
                  || (State == PmdgDoorState.ClosedArmed && target == PmdgDoorState.Closed))
            {
                Target = target;
            }
            else if (State != target && Target != target && (target == PmdgDoorState.Open || target == PmdgDoorState.Closed))
            {
                Target = target;
                InhibitUpdates();
            }
        }

        public virtual void ToggleDoor()
        {
            if (IsMoving)
                return;

            if (IsClosed)
                SetDoor(PmdgDoorState.Open);
            else
                SetDoor(PmdgDoorState.Closed);
        }

        public static bool IsDoorMoving(PmdgDoorState state)
        {
            return state == PmdgDoorState.Closing || state == PmdgDoorState.Opening;
        }

        public static bool IsDoorClosed(PmdgDoorState state)
        {
            return state == PmdgDoorState.Closed || state == PmdgDoorState.ClosedArmed || state == PmdgDoorState.Closing;
        }

        public static bool IsDoorOpen(PmdgDoorState state)
        {
            return state == PmdgDoorState.Open || state == PmdgDoorState.Opening;
        }
    }
}
