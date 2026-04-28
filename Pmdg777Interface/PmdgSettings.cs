using Any2GSX.PluginInterface;

namespace Pmdg777Interface
{
    public static class PmdgSettings
    {
        public static readonly PluginSetting ClearVehicles = new()
        {
            Key = "ClearVehicles",
            Type = PluginSettingType.Bool
        };
        public static readonly PluginSetting ChangePowerType = new()
        {
            Key = "ChangePowerType",
            Type = PluginSettingType.Bool
        };
        public static readonly PluginSetting CargoLights = new()
        {
            Key = "CargoLights",
            Type = PluginSettingType.Bool
        };
        public static readonly PluginSetting OperateBulk = new()
        {
            Key = "OperateBulk",
            Type = PluginSettingType.Bool
        };
    }
}
