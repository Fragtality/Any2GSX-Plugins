using CFIT.AppFramework.ResourceStores;
using CFIT.AppLogger;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public enum PmdgCargoLight
    {
        Ceiling = 1121,
        Sidewall = 1122,
        ExtCam = 1123,
        SillLoad = 1124,
    }

    public class Pmdg777CargoLight(Pmdg777Aircraft aircraft, PmdgCargoLight id, double onState = 100)
    {
        protected virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        protected virtual SimStore SimStore => Aircraft.SimStore;
        public virtual PmdgCargoLight Id { get; } = id;
        public virtual double OnState { get; } = onState;

        public virtual string GetVariable()
        {
            return $"L:switch_{(int)Id}_a";
        }

        public virtual string GetEvent()
        {
            return Pmdg777Aircraft.GetEventName((int)Id);
        }

        public virtual bool GetOn()
        {
            return SimStore[GetVariable()]?.GetNumber() == OnState;
        }

        public virtual bool GetOff()
        {
            return !GetOn();
        }

        public virtual Task Toggle()
        {
            return SimStore[GetEvent()]!?.WriteValue(Pmdg777Aircraft.EvtLeftSingle);
        }

        public virtual Task TurnOn()
        {
            if (GetOff())
            {
                Logger.Debug($"Turning on Lights {Id}");
                return Toggle();
            }

            return Task.CompletedTask;
        }

        public virtual Task TurnOff()
        {
            if (GetOn())
            {
                Logger.Debug($"Turning off Lights {Id}");
                return Toggle();
            }

            return Task.CompletedTask;
        }
    }
}
