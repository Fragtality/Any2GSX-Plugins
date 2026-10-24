# Changelog

## [27421ae] - 2026-10-24

### FNX.A320
- Changed the initial Payload call to also reset the EFB Boarding State to 'notStarted' (preventing false-positive Skips of the Departure Phase)
- Changed EFB Settings for GSX to only be check & set when the Automation was enabled for the A2G Profile
- Updated for Fenix V3
  - Removed Payload-Sync - handled by the Plane
  - Removed Fuel-Sync - handled by the Plane and (Rate via EFB)
  - Removed Option for Refuel via Panel - every Refuel is now operating the Panel
  - Plugin will still on assist in certain Cases, like
	- Setting planned Fuel or Payload when it doesn't match (i.e. GSX is restarted or Service aborted)
	- Setting planned Fuel - 1000kg when a Defuel is needed
  - Removed Door-Sync on Loaders for Cargo Doors - handled by the Plane, Open/Close on State changed still available
  - Removed Door-Sync for Pax Door on Jetway (for Stairs still handled)
- Changed SmartButton Trigger: Only the INT Position triggers now (with Avionics Powered)
- Improved / Changed Syncing between App and EFB Flightplan Weights
- Updated for Plugin Interface Changes
  - Moved Custom Stair Logic to App
- Updated .NET Packages

### PMDG.B777
- Fixed Arming of Doors when the Tug attaches during Boarding
- Updated for Plugin Interface Changes
- Updated .NET Packages

### SYN.A220
- Updated to latest plugin interface
- Improved external power handling

### PMDG.B737
- Initial Release of the B737 Plugin - with Fuel-, Payload-, Equip- and Door-Sync!

<br/><br/>

## [38a8367] - 2026-10-13

### FNX.A320
- Updated for new Plugin Interface
  - Some of the Door Logic removed - now commonly handled in the App
  - Door Mapping adapted to generic Plugin Options
- Added Condition to Ready Departure Check that the loaded OFP (EFB) has a different Id than the last (hopefully preventing external EFB Clients to trigger the Departure with the old/same OFP)

### PMDG.B777
- Updated for new Plugin Interface
  - Some of the Door Logic removed - now commonly handled in the App
  - Door Mapping adapted to generic Plugin Options
  - Option for Front Catering removed - now handled by generic Plugin Options
  - Option for Bulk Door removed - now handled by generic Plugin Option
  - Added Handling of Refuel/Water/Lav Panels  
- Added Door Monitor to retry Doors that did not open/close on the first Attempt
- Added an Option for the Cabin Light Fix (via Battery Alternator Event) and moved it to be triggered in the Preparation Phase
- Removed L:PowerOn from Avionic Powered Check (was redundant and triggered false-positives)
- Fixed a possible Race-Condition where the Light-Test could trigger the Pushback Phase through Beacon On
- Updated SimConnect SDK

### INI.A306
- Updated for new Plugin Interface
  - Some of the Door Logic removed - now commonly handled in the App
  - Improved Handling of Refuel Panels
- Board/Deboard now use the SetPaxOnBoard and SetCargoOnBoard Methods (i.e. to set Payload when Boarding was completed early)
- Added Condition to Ready Departure Check that the Arrival ICAO has to be different than the last 
	
### INI.A350
- Updated for new Plugin Interface
  - Some of the Door Logic removed - now commonly handled in the App
  - Door Mapping adapted to generic Plugin Options
  - Improved Handling of Refuel/Water/Lav Panels and Messages
  - Added Handling of Bulk Cargo Door
- Removed override Payload Plugin Option and Payload Sync on Boarding (native cannot be overwritten anymore)
  - Payload Sync on Deboarding still provided through the Plugin
- Added Call to iniBuilds' Start Turaround Variable once Deboard is completed to clear EFB SeatMap/Weights (and other Stuff)
- Changed Payload Method to use iniBuild SimEvent
- Changed Fuel Method to directly manipulating the Tanks, removing the Need to override GSX' Service State
  - The Refuel Door is therefor now controlled through the Plane, opening when the Truck arrives and closing when completed
- Added Fallback to send Loadsheet (if not happened through Boarding completed)
- Added Condition to Ready Departure Check that the Arrival ICAO has to be different than the last 
- Added Cockpit Notification when Preparation has finished (playing ATC MSG Sound)

### INI.A340
- Updated for new Plugin Interface
  - Improved Handling of Refuel/Water/Lav Panels and Messages
  - Added Handling of Bulk Cargo Door
- Reworked Distribution Logic for Fuel-Sync
- Added Condition to Ready Departure Check that the Arrival ICAO has to be different than the last 
- Reworked Fuel/Payload Fixes (the A340 just loooooves to reset it)
- Added Cockpit Notification when Preparation has finished (playing ATC MSG Sound)

### INI.A330
- Updated for new Plugin Interface
  - Added Handling of Bulk Cargo Door
  - Removed additional Door Checks
- Changed Fuel and Payload Methods to use iniBuild SimEvents
- Added Condition to Ready Departure Check that the Arrival ICAO has to be different than the last 

### SYN.A220
- Updated for new Plugin Interface
- Improved Detection of FMS Flightplan Import
- Removed L1 Door Inhibition
- Improved Workaround for the EFB ignoring Simbrief Weights for Pax and Empty

<br/><br/>

## [e19593d] - 2026-09-20

### SYN.A220
- Updated included GSX Profile

### PMDG.B777
- Added Channel File for Audio Control (CPT, FO)
- Volume via custom L-Vars (so only controllable through external Apps, i.e. PilotsDeck)
- Mute uses Cockpit Controls

<br/><br/>

## [b38811d] - 2026-09-19

### SYN.A220
- Added Override Pax Weight option (ensures Pax Count on EFB matches Any2GSX and GSX)

<br/><br/>

## [131cc2e] - 2026-09-19

### INI.A306
- Changed Cargo Loader Light Handling on Freighter
- Toggle Refuel Cover and Panel during Refueling
- Optimized Refuel-Sync (closer to internal prog. Refuel)
- Improved Engine Cover Removal

### SYN.A220
- Added door sync for 1L & cargo doors
- Added option to toggle ExtPwr fault protection
- Updated channel definitions to allow mute functionality (aircraft v.1.0.9a or above required)

<br/><br/>

## [0c543bd] - 2026-09-13

### PMDG.B777
- Updated NuGet Packages / Plugin Interface

### FNX.A320
- Updated NuGet Packages / Plugin Interface

<br/><br/>

## [002b0b5] - 2026-09-05

### SYN.A220
- Added Plugin for Synaptics/iniBuilds A220 (Contributed by bork)

<br/><br/>

## [c9e8915] - 2026-08-24

### PMDG.B777
- Updated NuGet Packages / Plugin Interface

### FNX.A320
- Updated NuGet Packages / Plugin Interface

<br/><br/>

<br/><br/>

## [ce6c6c7] - 2026-07-16

### PMDG.B777
- Updated NuGet Packages / Plugin Interface

### FNX.A320
- Updated NuGet Packages / Plugin Interface

<br/><br/>

## [fffd959] - 2026-07-12

### PMDG.B737
- Profile Updated (GRD CALL for Departure Trigger, R/T I/C for SmartButton)

<br/><br/>

## [f72e989] - 2026-06-11

### PMDG.B777
- Updated NuGet Packages / Plugin Interface

### FNX.A320
- Updated NuGet Packages / Plugin Interface

<br/><br/>

## [65df5f4] - 2026-06-08

### FNX.A320
- Fixed Pax Diff Sync via API

<br/><br/>

## [a3c51f5] - 2026-05-31

### PMDG.B777
- Updated Plugin Interface

### FNX.A320
- Updated Plugin Interface
- Added Sync of Fuel & Pax Planned from App to EFB

<br/><br/>

## [335fe12] - 2026-05-23

### PMDG.B777
- Updated Plugin Interface

### FNX.A320
- Updated Plugin Interface

<br/><br/>

## [e55ba15] - 2026-05-17

### PMDG.B777
- Automatically detecting available Stairs for Door Control
  - Mapping continues to be fixed: L1 => Front, L2 => Middle, L4 (200) / L5 (300) => Rear
- Added GSX Aircraft Profile for 200 Variants, fixing wrong preferred Exit in internal Profile

<br/><br/>

## [83e59d3] - 2026-05-17

### PMDG.B777
- Updated Plugin Interface

### FNX.A320
- Updated Plugin Interface

<br/><br/>

## [341feed] - 2026-05-16

### PMDG.B777
- Added Battery-Alternator Workaround for Cabin Lights
- Fixed wrong default Mapping for Front Catering Truck on the 300

### FNX.A320
- Removed Option for L2 Door on Stairs - now detected automatically through Stair Vehicle State

<br/><br/>

## [38af399] - 2026-05-15

### FNX.A320
- Fixed Payload-Sync on Deboard (maybe finally? :sob:)
- Added Option to enabled/disable Suppression of Deboard Dialog (and Arrival ACARS)
- Fixed Deserialization of EFB Timestamp
- Updated PluginInterface

### PMDG.B777
- Updated PluginInterface

<br/><br/>

## [a9a4be2] - 2026-05-10

### PMDG.B737
- Added PMDG 737 Profile for Automation & Volume-Control (Contributed by FatGingerHead)

<br/><br/>

## [55b5d09] - 2026-05-07

### ALL
- Preset/Override new Prog Refuel Plugin Option 

<br/><br/>

## [08f391e] - 2026-05-02

### PMDG.B777
- Workaround for PMDG Chocks not applied in Walkaround
- Open Doors for Stairs on Preparation Phase (i.e. Stairs where connected in Walkaround)
- Fixed RefuelStair being reset when Profile is loaded again
- Updated Libraries & SimConnect

### FNX.A320
- Fixed deboarded Pax not reflected in EFB
- Changed: EFB Phase is now set to 'Completed' (instead of 'Arrived') when shutting down the Engines
- Improved Timing for Chock-Reset while Repositioning
- Fixed Generic IsCargo Option not available in Plugin Options
- Updated Libraries

### INI.A306
- Fixed RefuelStair & UseFuelDialog being reset when Profile is loaded again
- Hide preconfigured Generic Plugin Variables

### INI.A330
- Fixed default Profile overriding Timeout for 'Attempt to connect Stairs while Refuel'
  - Existing Profiles need to be manually set to 60s
- Fixed RefuelStair being reset when Profile is loaded again
- Hide preconfigured Generic Plugin Variables
- Tip: Removing the Plugin Default Profile before updating/installing the Plugin will set the mentioned Settings as adviced (but also reset every customization made to it)

### INI.A340
- Revised Plugin NOTAMs (and Readme) on Importance to import the Simbrief Weights in the EFB
- Revised default Profile Settings to disable Fuel Round Up and Randomize Pax Numbers
- Fixed default Profile overriding Timeout for 'Attempt to connect Stairs while Refuel'
  - Existing Profiles need to be manually set to 60s
- Fixed RefuelStair being set by default Profile
  - Existing Profiles need to disable the 'Refuel on Left/Port Side' Plugin Option manually
  - Only disable if the GSX Aircraft Profile used does have Fuel on the Right/Star Side!
- Hide preconfigured Generic Plugin Variables
- Tip: Removing the Plugin Default Profile before updating/installing the Plugin will set the mentioned Settings as adviced (but also reset every customization made to it)

### INI.A350
- Fixed UseFuelDialog being reset when Profile is loaded again
- Hide preconfigured Generic Plugin Variables

<br/><br/>

## [2b2a6d3] - 2026-04-30

### PMDG.B777
- Fixing GPU Connection ... AGAIN :sob:
- Fixed Door Trigger closing rear Stair Door (on Jetway Stands)
- Added Option to change internal Mapping for Front Catering/Service Door

### INI.A340
- Fixed Typo on Aircraft Properties in SetEquipmentPca Function

<br/><br/>

## [a862ad2] - 2026-04-28

### FNX.A320
- Reimplementation of Fenix2GSX as Plugin with 99% Feature Parity
- Improved EFB Connection, needing less Requests
- Improved EFB Reset Handling for Arrival / Turnaround
  - The Plugin will automatically set the EFB "Arrived" Phase on Engine Shutdown (to prevent the Deboard Popup)
  - When Deboarding is requested, the EFB is (re)set to "Completed" so it is prepared for the next Import
- The Plugin is not meant for 'hybrid' Scenarios (using Fenix' native Integration) - continue to use the existing Profiles for that

### PMDG.B777
- Adapted Plugin to the new Plugin Interface and Features
- Removed Workaround Code for PMDG's Door Integration
- The Plugin can now fully and directly control all Doors to its full Extent
- Improved Reliability on the GPU Type Selection
- Improved Reliability in Connection to PMDG SDK/UFT
  - The Plugin might use the Test Light Switch to trigger Updates of PMDG's Cliend Data Area (aka SDK)

### INI.A306
- Adapted Plugin to the new Plugin Interface
- Fix/Workaround for Bulk Door not being closed by GSX

### INI.A330
- Adapted Plugin to the new Plugin Interface
- Improved Handling of Cover Removal
- Removed the included GSX Aircraft Profiles (use GSX internal or follow Guidance on Settings)

### INI.A340
- Adapted Plugin to the new Plugin Interface

### INI.A350
- Adapted Plugin to the new Plugin Interface
- Removed the included GSX Aircraft Profiles (use Developer-provided and disable 'Default Fuel System')
- Changed Door-Stair Handling for the Developer-provided Profile (operates L2 now instead of L4)
- Setting for native Board and Deboard override merged to one Setting "Payload override"
- Changed Handling of the Refuel Panel
- Automatically disable native GSX Menu Integration on Session Start
- Implemented Interface Functions to close all Doors on Loadsheet/Push

<br/><br/>


