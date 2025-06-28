using System.Runtime.InteropServices;

namespace Pmdg777Interface
{
    public enum PMDG_777X_ID
    {
        DATA_REQUEST = 10,
        PMDG_777X_DATA_ID = 0x504D4447,
        PMDG_777X_DATA_DEFINITION = 0x504D4448,
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 4)]
    public struct PMDG_777X_Data
    {
        ////////////////////////////////////////////
        // Controls and indicators
        ////////////////////////////////////////////

        // Overhead Mapublic intenance Panel
        //------------------------------------------

        // Backup Window Heat
        //[MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.byte, SizeConst = 2)]
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ICE_WindowHeatBackUp_Sw_OFF;

        // Standby Power
        public byte ELEC_StandbyPowerSw;              // 0: OFF  1: AUTO  2: BAT

        // Flight Controls
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] FCTL_WingHydValve_Sw_SHUT_OFF;  // left/right/center	
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] FCTL_TailHydValve_Sw_SHUT_OFF;  // left/right/center	
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] FCTL_annunTailHydVALVE_CLOSED;  // left/right/center	
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] FCTL_annunWingHydVALVE_CLOSED;  // left/right/center	
        public byte FCTL_PrimFltComputersSw_AUTO;      // true: AUTO  false: DISC
        public byte FCTL_annunPrimFltComputersDISC;

        // APU MAint
        public byte APU_Power_Sw_TEST;

        // EEC MAint
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_EECPower_Sw_TEST;

        // ELECTRICAL
        public byte ELEC_TowingPower_Sw_BATT;
        public byte ELEC_annunTowingPowerON_BATT;

        // CARGO TEMP SELECTORS
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_CargoTemp_Selector;            // aft / bulk  0=OFF  1=LOW  2=HIGH   AFT/BULK
        public byte AIR_CargoTemp_MainDeckFwd_Sel;        // 0: C ... 60: W
        public byte AIR_CargoTemp_MainDeckAft_Sel;        // 0: C ... 60: W
        public byte AIR_CargoTemp_LowerFwd_Sel;           // 0: C ... 60: W
        public byte AIR_CargoTemp_LowerAft_Sel;           // 0: C ... 60: W  67: HEAT H  70: HEAT OFF  73: HEAT L


        // Overhead Panel
        //------------------------------------------

        // ADIRU
        public byte ADIRU_Sw_On;
        public byte ADIRU_annunOFF;
        public byte ADIRU_annunON_BAT;

        // Flight Controls
        public byte FCTL_ThrustAsymComp_Sw_AUTO;
        public byte FCTL_annunThrustAsymCompOFF;

        // Electrical
        public byte ELEC_CabUtilSw;
        public byte ELEC_annunCabUtilOFF;
        public byte ELEC_IFEPassSeatsSw;
        public byte ELEC_annunIFEPassSeatsOFF;
        public byte ELEC_Battery_Sw_ON;
        public byte ELEC_annunBattery_OFF;
        public byte ELEC_annunAPU_GEN_OFF;
        public byte ELEC_APUGen_Sw_ON;
        public byte ELEC_APU_Selector;                    // 0: OFF  1: ON  2: START	
        public byte ELEC_annunAPU_FAULT;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_BusTie_Sw_AUTO;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunBusTieISLN;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_ExtPwrSw;                  // primary/secondary - MOMENTARY SWITCHES
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunExtPowr_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunExtPowr_AVAIL;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_Gen_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunGenOFF;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_BackupGen_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunBackupGenOFF;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_IDGDiscSw;                 // MOMENTARY SWITCHES
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ELEC_annunIDGDiscDRIVE;

        // Wiper Selectors
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] WIPERS_Selector;                   // left/right   0: OFF  1: public int  2: LOW  3:HIGH

        // Emergency Lights
        public byte LTS_EmerLightsSelector;               // 0: OFF  1: ARMED  2: ON

        // Service public interphone
        public byte COMM_ServiceInterphoneSw;

        // Passenger Oxygen
        public byte OXY_PassOxygen_Sw_On;
        public byte OXY_annunPassOxygenON;

        // Window Heat
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
        public byte[] ICE_WindowHeat_Sw_ON;           // L-Side/L-Fwd/R-Fwd/R-Side
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
        public byte[] ICE_annunWindowHeatINOP;            // L-Side/L-Fwd/R-Fwd/R-Side

        // Hydraulics
        public byte HYD_RamAirTurbineSw;
        public byte HYD_annunRamAirTurbinePRESS;
        public byte HYD_annunRamAirTurbineUNLKD;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_PrimaryEngPump_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_PrimaryElecPump_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_DemandElecPump_Selector;       // 0: OFF  1: AUTO  2: ON
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_DemandAirPump_Selector;        // 0: OFF  1: AUTO  2: ON
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_annunPrimaryEngPumpFAULT;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_annunPrimaryElecPumpFAULT;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_annunDemandElecPumpFAULT;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] HYD_annunDemandAirPumpFAULT;

        // Passenger Signs
        public byte SIGNS_NoSmokingSelector;          // 0: OFF  1: AUTO   2: ON
        public byte SIGNS_SeatBeltsSelector;          // 0: OFF  1: AUTO   2: ON

        // Flight Deck Lights
        public byte LTS_DomeLightKnob;                    // Position 0...100
        public byte LTS_CircuitBreakerKnob;               // Position 0...100
        public byte LTS_OvereadPanelKnob;             // Position 0...100
        public byte LTS_GlareshieldPNLlKnob;          // Position 0...100
        public byte LTS_GlareshieldFLOODKnob;         // Position 0...100
        public byte LTS_Storm_Sw_ON;
        public byte LTS_MasterBright_Sw_ON;
        public byte LTS_MasterBrigntKnob;             // Position 0...100
        public byte LTS_IndLightsTestSw;              // 0: TEST  1: BRT  2: DIM

        // Exterior Lights
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] LTS_LandingLights_Sw_ON;            // Left/Right/Nose 
        public byte LTS_Beacon_Sw_ON;
        public byte LTS_NAV_Sw_ON;
        public byte LTS_Logo_Sw_ON;
        public byte LTS_Wing_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] LTS_RunwayTurnoff_Sw_ON;
        public byte LTS_Taxi_Sw_ON;
        public byte LTS_Strobe_Sw_ON;

        // Engine, APU and Cargo Fire
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_CargoFire_Sw_Arm;          // FWD/AFT
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_annunCargoFire;                // FWD/AFT
        public byte FIRE_CargoFireDisch_Sw;                // MOMENTARY SWITCH
        public byte FIRE_annunCargoDISCH;
        public byte FIRE_FireOvhtTest_Sw;              // MOMENTARY SWITCH
        public byte FIRE_APUHandle;                       // 0: IN (NORMAL)  1: PULLED OUT  2: TURNED LEFT  3: TURNED RIGHT  (2 & 3 ane momnentary positions)
        public byte FIRE_APUHandleUnlock_Sw;           // MOMENTARY SWITCH resets when handle pulled
        public byte FIRE_annunAPU_BTL_DISCH;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_EngineHandleIlluminated;
        public byte FIRE_APUHandleIlluminated;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_EngineHandleIsUnlocked;
        public byte FIRE_APUHandleIsUnlocked;
        public byte FIRE_annunMainDeckCargoFire;
        public byte FIRE_annunCargoDEPR;               // DEPR light in DEPR/DISCH guarded switch

        // Engine
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_EECMode_Sw_NORM;                // left / right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_Start_Selector;                // left / right  0: START  1: NORM
        public byte ENG_Autostart_Sw_ON;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_annunALTN;
        public byte ENG_annunAutostartOFF;

        // Fuel
        public byte FUEL_CrossFeedFwd_Sw;
        public byte FUEL_CrossFeedAft_Sw;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_PumpFwd_Sw;                    // left fwd / right fwd
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_PumpAft_Sw;                    // left aft / right aft
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_PumpCtr_Sw;                    // ctr left / ctr right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_JettisonNozle_Sw;          // left / right
        public byte FUEL_JettisonArm_Sw;
        public byte FUEL_FuelToRemain_Sw_Pulled;
        public byte FUEL_FuelToRemain_Selector;           // 0: DECR  1: Neutral  2: INCR
        public byte FUEL_annunFwdXFEED_VALVE;
        public byte FUEL_annunAftXFEED_VALVE;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_annunLOWPRESS_Fwd;         // left fwd / right fwd
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_annunLOWPRESS_Aft;         // left aft / right aft
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_annunLOWPRESS_Ctr;         // ctr left / ctr right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FUEL_annunJettisonNozleVALVE;   // left / right
        public byte FUEL_annunArmFAULT;

        // Anti-Ice
        public byte ICE_WingAntiIceSw;                    // 0: OFF  1: AUTO  2: ON
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ICE_EngAntiIceSw;              // 0: OFF  1: AUTO  2: ON


        // Air Conditioning
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_Pack_Sw_AUTO;               // left / right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_TrimAir_Sw_On;              // left / right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_RecircFan_Sw_On;                // upper / lower	
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_TempSelector;              // flt deck / cabin  0: C ... 60: W ... 70: MAN (flt deck only)  	
        public byte AIR_AirCondReset_Sw_Pushed;            // MOMENTARY action		
        public byte AIR_EquipCooling_Sw_AUTO;
        public byte AIR_Gasper_Sw_On;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_annunPackOFF;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_annunTrimAirFAULT;
        public byte AIR_annunEquipCoolingOVRD;
        public byte AIR_AltnVentSw_ON;
        public byte AIR_annunAltnVentFAULT;
        public byte AIR_MainDeckFlowSw_NORM;           // M/D FLOW  true: NORM  false: HIGH

        // Bleed Air
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_EngBleedAir_Sw_AUTO;            // left engine / right engine
        public byte AIR_APUBleedAir_Sw_AUTO;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_IsolationValve_Sw;          // left / right 
        public byte AIR_CtrIsolationValve_Sw;          // left / right 
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_annunEngBleedAirOFF;               // left engine / right engine
        public byte AIR_annunAPUBleedAirOFF;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_annunIsolationValveCLOSED;  // left / right 
        public byte AIR_annunCtrIsolationValveCLOSED;


        // Pressurization
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_OutflowValve_Sw_AUTO;       // fwd / aft
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_OutflowValveManual_Selector;   // fwd / aft   0: OPEN  1: Neutral  2: CLOSE
        public byte AIR_LdgAlt_Sw_Pulled;
        public byte AIR_LdgAlt_Selector;              // 0: DECR  1: Neutral  2: INCR
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_annunOutflowValve_MAN;      // fwd / aft



        // Forward panel
        //------------------------------------------

        // Center 
        public byte GEAR_Lever;                           // 0: UP  1: DOWN
        public byte GEAR_LockOvrd_Sw;                  // MOMENTARY SWITCH (resets when gear lever moved)
        public byte GEAR_AltnGear_Sw_DOWN;
        public byte GPWS_FlapInhibitSw_OVRD;
        public byte GPWS_GearInhibitSw_OVRD;
        public byte GPWS_TerrInhibitSw_OVRD;
        public byte GPWS_RunwayOvrdSw_OVRD;
        public byte GPWS_GSInhibit_Sw;
        public byte GPWS_annunGND_PROX_top;
        public byte GPWS_annunGND_PROX_bottom;
        public byte BRAKES_AutobrakeSelector;         // 0: RTO  1: OFF  2: DISARM   3: "1" ... 5: MAX AUTO

        // Standby - ISFD  (all are MOMENTARY action switches)
        public byte ISFD_Baro_Sw_Pushed;
        public byte ISFD_RST_Sw_Pushed;
        public byte ISFD_Minus_Sw_Pushed;
        public byte ISFD_Plus_Sw_Pushed;
        public byte ISFD_APP_Sw_Pushed;
        public byte ISFD_HP_IN_Sw_Pushed;

        // Left 
        public byte ISP_Nav_L_Sw_CDU;
        public byte ISP_DsplCtrl_L_Sw_Altn;
        public byte ISP_AirDataAtt_L_Sw_Altn;
        public byte DSP_InbdDspl_L_Selector;          //0: ND  1: NAV  2: MFD  3: EICAS
        public byte EFIS_HdgRef_Sw_Norm;
        public byte EFIS_annunHdgRefTRUE;
        public int BRAKES_BrakePressNeedle;            // Value 0...100 (corresponds to 0...4000 PSI)
        public byte BRAKES_annunBRAKE_SOURCE;

        // Right 
        public byte ISP_Nav_R_Sw_CDU;
        public byte ISP_DsplCtrl_R_Sw_Altn;
        public byte ISP_AirDataAtt_R_Sw_Altn;
        public byte ISP_FMC_Selector;                 //0: LEFT   1: AUTO  2: RIGHT
        public byte DSP_InbdDspl_R_Selector;          //0: EICAS  1: MFD   2: ND  3: PFD

        // Left & Right Sidewalls
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_ShoulderHeaterKnob;            // Left / Right  Position 0...100
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] AIR_FootHeaterSelector;            // Left / Right  0: OFF  1: LOW  2: HIGH
        public byte LTS_LeftFwdPanelPNLKnob;          // Position 0...100
        public byte LTS_LeftFwdPanelFLOODKnob;            // Position 0...100
        public byte LTS_LeftOutbdDsplBRIGHTNESSKnob;  // Position 0...100
        public byte LTS_LeftInbdDsplBRIGHTNESSKnob;       // Position 0...100

        public byte LTS_RightFwdPanelPNLKnob;         // Position 0...100
        public byte LTS_RightFwdPanelFLOODKnob;           // Position 0...100	
        public byte LTS_RightInbdDsplBRIGHTNESSKnob;  // Position 0...100
        public byte LTS_RightOutbdDsplBRIGHTNESSKnob; // Position 0...100


        // Chronometers (Left / Right)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] CHR_Chr_Sw_Pushed;              // MOMENTARY SWITCH
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] CHR_TimeDate_Sw_Pushed;         // MOMENTARY SWITCH
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] CHR_TimeDate_Selector;         // 0: UTC  1: MAN
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] CHR_Set_Selector;              // 0: RUN  1: HLDY  2: MM  3: HD
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] CHR_ET_Selector;                   // 0: RESET (MOMENTARY spring-loaded to HLD)  1: HLD  2: RUN


        // Glareshield
        //------------------------------------------

        // EFIS switches (left / right)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_MinsSelBARO;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_BaroSelHPA;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_VORADFSel1;                   // 0: VOR  1: OFF  2: ADF
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_VORADFSel2;                   // 0: VOR  1: OFF  2: ADF
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_ModeSel;                  // 0: APP  1: VOR  2: MAP  3: PLAN
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_RangeSel;                 // 0: 10 ... 6: 640
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_MinsKnob;                 // 0..99
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_BaroKnob;                 // 0..99

        // EFIS MOMENTARY action (left / right)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_MinsRST_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_BaroSTD_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_ModeCTR_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_RangeTFC_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_WXR_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_STA_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_WPT_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_ARPT_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_DATA_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_POS_Sw_Pushed;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_TERR_Sw_Pushed;

        // MCP - Variables
        public float MCP_IASMach;                      // Mach if < 10.0
        public byte MCP_IASBlank;
        public ushort MCP_Heading;
        public ushort MCP_Altitude;
        public short MCP_VertSpeed;
        public float MCP_FPA;
        public byte MCP_VertSpeedBlank;

        // MCP - Switches
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] MCP_FD_Sw_On;                   // left / right
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] MCP_ATArm_Sw_On;                    // left / right
        public byte MCP_BankLimitSel;                 // 0: AUTO  1: 5  2: 10 ... 5: 25
        public byte MCP_AltIncrSel;                        // false: AUTO  true: 1000
        public byte MCP_DisengageBar;
        public byte MCP_Speed_Dial;                       // 0 ... 99
        public byte MCP_Heading_Dial;                 // 0 ... 99
        public byte MCP_Altitude_Dial;                    // 0 ... 99
        public byte MCP_VS_Wheel;                     // 0 ... 99

        public byte MCP_HDGDial_Mode;                 // 0: Dial shows HDG, 1: Dial shows TRK
        public byte MCP_VSDial_Mode;                  // 0: Dial shows VS, 1: Dial shows FPA

        // MCP - MOMENTARY action switches
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] MCP_AP_Sw_Pushed;               // left / right
        public byte MCP_CLB_CON_Sw_Pushed;
        public byte MCP_AT_Sw_Pushed;
        public byte MCP_LNAV_Sw_Pushed;
        public byte MCP_VNAV_Sw_Pushed;
        public byte MCP_FLCH_Sw_Pushed;
        public byte MCP_HDG_HOLD_Sw_Pushed;
        public byte MCP_VS_FPA_Sw_Pushed;
        public byte MCP_ALT_HOLD_Sw_Pushed;
        public byte MCP_LOC_Sw_Pushed;
        public byte MCP_APP_Sw_Pushed;
        public byte MCP_Speeed_Sw_Pushed;
        public byte MCP_Heading_Sw_Pushed;
        public byte MCP_Altitude_Sw_Pushed;
        public byte MCP_IAS_MACH_Toggle_Sw_Pushed;
        public byte MCP_HDG_TRK_Toggle_Sw_Pushed;
        public byte MCP_VS_FPA_Toggle_Sw_Pushed;

        // MCP - Annunciator lights
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] MCP_annunAP;                        // left / right
        public byte MCP_annunAT;
        public byte MCP_annunLNAV;
        public byte MCP_annunVNAV;
        public byte MCP_annunFLCH;
        public byte MCP_annunHDG_HOLD;
        public byte MCP_annunVS_FPA;
        public byte MCP_annunALT_HOLD;
        public byte MCP_annunLOC;
        public byte MCP_annunAPP;

        // Display Select Panel	- These are all MOMENTARY SWITCHES
        public byte DSP_L_INBD_Sw;
        public byte DSP_R_INBD_Sw;
        public byte DSP_LWR_CTR_Sw;
        public byte DSP_ENG_Sw;
        public byte DSP_STAT_Sw;
        public byte DSP_ELEC_Sw;
        public byte DSP_HYD_Sw;
        public byte DSP_FUEL_Sw;
        public byte DSP_AIR_Sw;
        public byte DSP_DOOR_Sw;
        public byte DSP_GEAR_Sw;
        public byte DSP_FCTL_Sw;
        public byte DSP_CAM_Sw;
        public byte DSP_CHKL_Sw;
        public byte DSP_COMM_Sw;
        public byte DSP_NAV_Sw;
        public byte DSP_CANC_RCL_Sw;
        public byte DSP_annunL_INBD;
        public byte DSP_annunR_INBD;
        public byte DSP_annunLWR_CTR;

        // Master Warning/Caution
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] WARN_Reset_Sw_Pushed;           // MOMENTARY action
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] WARN_annunMASTER_WARNING;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] WARN_annunMASTER_CAUTION;


        // Forward Aisle Stand Panel
        //------------------------------------------

        public byte ISP_DsplCtrl_C_Sw_Altn;
        public byte LTS_UpperDsplBRIGHTNESSKnob;      // Position 0...100
        public byte LTS_LowerDsplBRIGHTNESSKnob;      // Position 0...100
        public byte EICAS_EventRcd_Sw_Pushed;          // MOMENTARY action		

        // CDU (Left/Right/Center)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_annunEXEC;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_annunDSPY;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_annunFAIL;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_annunMSG;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_annunOFST;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] CDU_BrtKnob;                       // 0: DecreasePosition 1: Neutral  2: Increase


        // Control Stand
        //------------------------------------------

        public byte FCTL_AltnFlaps_Sw_ARM;
        public byte FCTL_AltnFlaps_Control_Sw;            // 0: RET  1: OFF  2: EXT
        public byte FCTL_StabCutOutSw_C_NORMAL;
        public byte FCTL_StabCutOutSw_R_NORMAL;
        public byte FCTL_AltnPitch_Lever;             // 0: NOSE DOWN  1: NEUTRAL  2: NOSE UP
        public byte FCTL_Speedbrake_Lever;                // Position 0...100  0: DOWN,  25: ARMED, 26...100: DEPLOYED 
        public byte FCTL_Flaps_Lever;                 // 0: UP  1: 1  2: 5  3: 15  4: 20  5: 25  6: 30 	
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_FuelControl_Sw_RUN;
        public byte BRAKES_ParkingBrakeLeverOn;


        // Aft Aisle Stand Panel
        //------------------------------------------

        // Audio Control Panels								// Comm Systems: 0=VHFL 1=VHFC 2=VHFR 3=FLT 4=CAB 5=PA 6=HFL 7=HFR 8=SAT1 9=SAT2 10=SPKR 11=VOR/ADF 12=APP
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] COMM_SelectedMic;              // array: 0=capt, 1=F/O, 2=observer  values: 0..9 (VHF..SAT2) as listed above; -1 if no MIC is selected
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public ushort[] COMM_ReceiverSwitches;            // array: 0=capt, 1=F/O, 2=observer.  Bit mask for selected receivers with bits indicating: 0=VHFL 1=VHFC 2=VHFR 3=FLT 4=CAB 5=PA 6=HFL 7=HFR 8=SAT1 9=SAT2 10=SPKR 11=VOR/ADF 12=APP
        public byte COMM_OBSAudio_Selector;               // 0: CAPT  1: NORMAL  2: F/O

        // Radio Control Panels								// arrays: 0=capt, 1=F/O, 2=observer

        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] COMM_SelectedRadio;                // 0: VHFL  1: VHFC  2: VHFL  3: HFL  5: HFR (4 not used)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] COMM_RadioTransfer_Sw_Pushed;   // MOMENTARY action
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] COMM_RadioPanelOff;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] COMM_annunAM;

        // TCAS Panel
        public byte XPDR_XpndrSelector_R;              // true: R     false: L
        public byte XPDR_AltSourceSel_ALTN;                // true: ALTN  false: NORM  
        public byte XPDR_ModeSel;                     // 0: STBY  1: ALT RPTG OFF  2: XPNDR  3: TA ONLY  4: TA/RA
        public byte XPDR_Ident_Sw_Pushed;              // MOMENTARY action

        // Engine Fire 
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_EngineHandle;             // ENG 1/ENG2   0: IN (NORMAL)  1: PULLED OUT  2: TURNED LEFT  3: TURNED RIGHT  (2 & 3 are momenentary positions)
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_EngineHandleUnlock_Sw;     // ENG 1/ENG2   MOMENTARY SWITCH resets when handle pulled
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] FIRE_annunENG_BTL_DISCH;            // ENG 1/ENG2

        // Aileron & Rudder Trim
        public byte FCTL_AileronTrim_Switches;            // 0: LEFT WING DOWN  1: NEUTRAL  2: RIGHT WING DOWN (both switches move together)
        public byte FCTL_RudderTrim_Knob;             // 0: NOSE LEFT  1: NEUTRAL  2: NOSE RIGHT
        public byte FCTL_RudderTrimCancel_Sw_Pushed;   // MOMENTARY action

        // Evacuation Panel
        public byte EVAC_Command_Sw_ON;
        public byte EVAC_PressToTest_Sw_Pressed;
        public byte EVAC_HornSutOff_Sw_Pulled;
        public byte EVAC_LightIlluminated;


        // Aisle Stand PNL/FLOOD & Floor lights
        public byte LTS_AisleStandPNLKnob;                // Position 0...100
        public byte LTS_AisleStandFLOODKnob;          // Position 0...100
        public byte LTS_FloorLightsSw;                    // 0: BRT  1: OFF  2: DIM


        // Door state
        // Possible values are, 0: open, 1: closed, 2: closed and armed, 3: closing, 4: opening.
        // The array contains these doors:
        //  0: Entry 1L,
        //  1: Entry 1R,
        //  2: Entry 2L,
        //  3: Entry 2R,
        //  4: Entry 3L,				(This is the door aft of the wing. It is marked 4L on -300)
        //  5: Entry 3R,		
        //  6: Entry 4L,				(marked 5L on -300)
        //  7: Entry 4R,
        //  8: Entry 5L,
        //  9: Entry 5R,
        // 10: Cargo Fwd,
        // 11: Cargo Aft,
        // 12: Cargo Main,				(Freighter)
        // 13: Cargo Bulk,
        // 14: Avionics Access,
        // 15: EE Access
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
        public byte[] DOOR_state;
        public byte DOOR_CockpitDoorOpen;

        // Additional variables
        //------------------------------------------

        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] ENG_StartValve;                 // true: valve open
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public float[] AIR_DuctPress;                 // PSI
        public float FUEL_QtyCenter;                       // LBS
        public float FUEL_QtyLeft;                     // LBS
        public float FUEL_QtyRight;                        // LBS
        public float FUEL_QtyAux;                      // LBS
        public byte IRS_aligned;                       // at least one IRU is aligned

        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_BaroMinimumsSet;           // left/right control panel. Note: check EFIS_MinsSelBARO[2] to determine if the active minimums is BARO or RADIO
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public int[] EFIS_BaroMinimums;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public byte[] EFIS_RadioMinimumsSet;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public int[] EFIS_RadioMinimums;

        // Display formats selected on the display units
        // Values are:
        // 	0:	Off,
        // 	1:	Blank,
        // 	2:	PFD,
        // 	3:	ND,
        // 	4:	EICAS,
        // 	5:	ENG,
        // 	6:	STAT,
        // 	7:	CHKL,
        // 	8:	COMM,
        // 	9:	CAM,
        // 10:	ELEC,
        // 11:	HYD,
        // 12:	FUEL,
        // 13:	AIR,
        // 14:	DOOR,
        // 15:	GEAR,
        // 16:	FCTL
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 6)]
        public byte[] EFIS_Display;                  // Display units:  0: Capt outboard, 1: Capt inboard, 2: Upper, 3: Lower, 4: FO Inboard, 5: FO Outboard

        public byte AircraftModel;                        // 1: -200  2: -200ER  3: -300  4: -200LR  5: 777F  6: -300ER
        public byte WeightInKg;                            // false: LBS  true: KG
        public byte GPWS_V1CallEnabled;                    // GPWS V1 call-out option enabled
        public byte GroundConnAvailable;               // can connect/disconnect ground air/electrics

        public byte FMC_TakeoffFlaps;                 // degrees, 0 if not set
        public byte FMC_V1;                               // knots, 0 if not set
        public byte FMC_VR;                               // knots, 0 if not set
        public byte FMC_V2;                               // knots, 0 if not set
        public ushort FMC_ThrustRedAlt;                    // 1: FLAPS 1,  5: FLAPS 5,  otherwise altitude in ft
        public ushort FMC_AccelerationAlt;             // ft
        public ushort FMC_EOAccelerationAlt;               // ft
        public byte FMC_LandingFlaps;                 // degrees, 0 if not set
        public byte FMC_LandingVREF;                  // knots, 0 if not set
        public ushort FMC_CruiseAlt;                       // ft, 0 if not set
        public short FMC_LandingAltitude;              // ft; -32767 if not available
        public ushort FMC_TransitionAlt;                   // ft
        public ushort FMC_TransitionLevel;             // ft
        public byte FMC_PerfInputComplete;
        public float FMC_DistanceToTOD;                    // nm; 0.0 if passed, negative if n/a
        public float FMC_DistanceToDest;                   // nm; negative if n/a
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 9)]
        public char[] FMC_flightNumber;
        public byte WheelChocksSet;
        public byte APURunning;

        // FMC thrust limit mode
        // Values are:
        //  0:  TO,
        //  1:  TO 1,
        //  2:  TO 2,
        //  3:  TO B,
        //  4:  CLB,
        //  5:  CLB 1,
        //  6:  CLB 2,
        //  7:  CRZ,
        //  8:  CON,
        //  9:  G/A,
        // 10:  D-TO,
        // 11:  D-TO 1,
        // 12:  D-TO 2,
        // 13:  A-TO,
        // 14:  A-TO 1,
        // 15:  A-TO 2,
        // 16:  A-TO B
        public byte FMC_ThrustLimitMode;

        // Normal checklist completion status
        // Array elements are:
        // 	0:  PREFLIGHT,
        // 	1:  BEFORE_START,
        // 	2:  BEFORE_TAXI,
        // 	3:  BEFORE_TAKEOFF,
        // 	4:  AFTER_TAKEOFF,
        // 	5:  DESCENT,
        // 	6:  APPROACH,
        // 	7:  LANDING,
        // 	8:  SHUTDOWN,
        // 	9:  SECURE

        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 10)]
        public byte[] ECL_ChecklistComplete;

        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 84)]
        public byte[] reserved;
    }
}
