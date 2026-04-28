using CFIT.AppLogger;
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

    public class Pmdg777Door(Pmdg777Aircraft aircraft, PmdgDoorIndex index, int evtCode)
    {
        protected virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        protected virtual PMDG_777X_Data PMDG_777X_Data => Aircraft?.Module?.PMDG_777X_Data ?? new();
        public virtual PmdgDoorIndex Index { get; } = index;
        public virtual int EventCode { get; } = evtCode;
        public virtual PmdgDoorState State => (PmdgDoorState)PMDG_777X_Data.DOOR_state[(int)Index];
        public virtual bool IsAvailable { get; set; } = true;
        public virtual bool IsMoving => State == PmdgDoorState.Closing || State == PmdgDoorState.Opening;
        public virtual bool IsClosed => State == PmdgDoorState.Closed || State == PmdgDoorState.ClosedArmed || State == PmdgDoorState.Closing;
        public virtual bool IsFullyClosed => State == PmdgDoorState.Closed || State == PmdgDoorState.ClosedArmed;
        public virtual bool IsArmed => State == PmdgDoorState.ClosedArmed;
        public virtual bool IsOpen => State == PmdgDoorState.Open || State == PmdgDoorState.Opening;
        public virtual bool IsFullyOpen => State == PmdgDoorState.Open;
        public virtual bool IsPaxDoor => IsAvailable && Index <= PmdgDoorIndex.Pax5R;
        public virtual bool IsCargoDoor => IsAvailable && Index >= PmdgDoorIndex.CargoFwd && Index <= PmdgDoorIndex.CargoBulk;

        public virtual Task SendDoorCode()
        {
            Logger.Information($"Operating Door {Index} (current State: {State})");
            string evt = Pmdg777Aircraft.GetEventName(EventCode);
            Logger.Debug($"Sending Door Event: {EventCode} -> {evt}");
            return Aircraft.SimStore[evt]?.WriteValue(Pmdg777Aircraft.EvtLeftSingle);
        }

        public virtual Task SetDoor(bool state)
        {
            return SetDoor(state ? PmdgDoorState.Open : PmdgDoorState.Closed);
        }

        public virtual Task SetDoor(PmdgDoorState target)
        {
            if (IsMoving)
            {
                Logger.Debug($"Door {Index} already moving");
            }
            else if (target == PmdgDoorState.Closed && State == PmdgDoorState.ClosedArmed)
            {
                Logger.Debug($"Door {Index} already armed");
            }
            else if (State != target)
            {
                return SendDoorCode();
            }

            return Task.CompletedTask;
        }

        public virtual Task ToggleDoor()
        {
            if (IsMoving)
                return Task.CompletedTask;

            if (IsClosed)
                return SetDoor(PmdgDoorState.Open);
            else
                return SetDoor(PmdgDoorState.Closed);
        }
    }
}
