# Changelog

### PMDG.B777
- Fixing GPU Connection ... AGAIN :sob:
- Fixed Door Trigger closing rear Stair Door (on Jetway Stands)
- Added Option to change internal Mapping for Front Catering/Service Door

### INI.A340
- Fixed Typo on Aircraft Properties in SetEquipmentPca Function


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

