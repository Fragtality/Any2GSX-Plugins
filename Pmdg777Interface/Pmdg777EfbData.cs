using System.Text.Json;
using System.Text.Json.Nodes;

namespace Pmdg777Interface
{
    public class Pmdg777EfbData
    {
#pragma warning disable IDE1006
        public virtual JsonNode autocruise { get; set; } = null;
        public virtual JsonNode doors { get; set; }
        public virtual Pmdg777EfbGroundConn ground_conn { get; set; }
        public virtual JsonNode ground_maint { get; set; }
        public virtual JsonNode ground_ops { get; set; }
        public virtual string message_tag { get; set; }
        public virtual JsonNode pushback { get; set; }
        public virtual string tablet_side { get; set; }
        public virtual Pmdg777EfbVehicles vehicles { get; set; }

        public static Pmdg777EfbData Serialize(string json)
        {
            return JsonSerializer.Deserialize<Pmdg777EfbData>(json);
        }

        public static Pmdg777EfbData Serialize(JsonNode node)
        {
            return JsonSerializer.Deserialize<Pmdg777EfbData>(node);
        }
    }

    public class Pmdg777EfbGroundConn
    {
        public virtual string air_conditioning_unit { get; set; }
        public virtual bool air_conditioning_unit_enabled { get; set; }
        public virtual string air_start_unit { get; set; }
        public virtual bool air_start_unit_enabled { get; set; }
        public virtual bool chocks_set { get; set; }
        public virtual string ground_power_state { get; set; }
        public virtual bool ground_power_state_enabled { get; set; }
        public virtual string ground_power_type { get; set; }
        public virtual bool ground_power_type_enabled { get; set; }
        public virtual bool is_chockable { get; set; }
        public virtual string jetway { get; set; }
        public virtual bool jetway_enabled { get; set; }
        public virtual string passenger_entry { get; set; }
    }

    public class Pmdg777EfbVehicles
    {
        public virtual string aft_cargo_state { get; set; }
        public virtual bool aft_cargo_state_enabled { get; set; }
        public virtual string aft_galley_state { get; set; }
        public virtual bool aft_galley_state_enabled { get; set; }
        public virtual string bulk_cargo_state { get; set; }
        public virtual bool bulk_cargo_state_enabled { get; set; }
        public virtual string cabin_cleaning_state { get; set; }
        public virtual bool cabin_cleaning_state_enabled { get; set; }
        public virtual string fuel_truck_state { get; set; }
        public virtual bool fuel_truck_state_enabled { get; set; }
        public virtual string fwd_cargo_state { get; set; }
        public virtual bool fwd_cargo_state_enabled { get; set; }
        public virtual string fwd_galley_state { get; set; }
        public virtual bool fwd_galley_state_enabled { get; set; }
        public virtual bool is_chockable { get; set; }
        public virtual string lavatory_service_state { get; set; }
        public virtual bool lavatory_service_state_enabled { get; set; }
        public virtual string maintenance_van_state { get; set; }
        public virtual bool maintenance_van_state_enabled { get; set; }
        public virtual string potable_water_state { get; set; }
        public virtual bool potable_water_state_enabled { get; set; }
        public virtual string stairs_1l_state { get; set; }
        public virtual bool stairs_1l_state_enabled { get; set; }
        public virtual string stairs_2l_state { get; set; }
        public virtual bool stairs_2l_state_enabled { get; set; }
    }
#pragma warning restore IDE1006
}
