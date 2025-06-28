using Any2GSX.PluginInterface;
using Any2GSX.PluginInterface.Interfaces;
using System;

namespace Pmdg777Interface
{
    public class Pmdg777Plugin(IAppResources appResources) : AppPlugin(appResources)
    {
        public override string Id => "PMDG.B777";

        public override PluginType Type => PluginType.BinaryV1;

        public override Type GetAircraftInterface(string aircraftString)
        {
            return typeof(Pmdg777Aircraft);
        }

        public override Type SimConnectModuleType => typeof(Pmdg777Module);
    }
}
