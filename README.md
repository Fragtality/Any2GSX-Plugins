# Any2GSX-Plugins

Plugin Repository for [Any2GSX](https://github.com/Fragtality/Any2GSX) containing Aircraft Plugins, Channel Files and preconfigured Profiles.
<br/><br/>

## 1 - Installing Plugins / Channels / Profiles

Use the Plugin View ('Available from GitHub') of the Any2GSX App to install Plugins / Channels / Profiles from this Repository!<br/>

<br/><br/>

## 2 - Available Aircraft Plugins

### 2.1 - Plugins

| Aircraft | Author | Description |
| :-------------- | :---------: | :----------- |
| Fenix A320 | Fragtality | Complete & progressive Fuel, Payload, Door and Equipment Sync. (And other Fenix2GSX Stuff) |
| iniBuilds A300-600 | Fragtality | Complete & progressive Fuel, Payload and Equipment Sync. Can control the Main Cargo Door & Lights and the visual Cargo Model on the Freighter. |
| iniBuilds A330 | Fragtality | Complete & progressive Fuel, Payload Sync. Limited Equipment Sync. Door-Sync fixing L1/L2 and L4 randomly opening for no Reason. |
| iniBuilds A340 | Fragtality | Complete & progressive Fuel, Payload and Equipment Sync. Door-Sync through GSX. |
| iniBuilds A350 | Fragtality | Complete & progressive Fuel, Payload and Equipment Sync (overriding iniBuilds' Integration). Door-Sync for L2. |
| PMDG B777 | Fragtality | Complete & progressive Fuel, Payload, Door and Equipment Sync. Also controls Cargo Bay Lights on the Freigher. |

<br/><br/>

### 2.2 - NOTAMs (Known Issues)

#### PMDG.B777

In some Cases the DataBroadcast wasn't enabled although configured in the 777_Options.ini File (e.g. after an Update for the Aircraft). Try to remove it, load the Sim/Aircraft and and then reenable it in the ini File (after closing the Sim).<br/>
Generally other Addons that read/use GSX' Total (Target) Passenger Number (`FSDT_GSX_NUMPASSENGERS`) may show weird Behavior or Numbers - PMDG is still writing to this GSX Variable in a non-standard Way. No Workaround - it has to be solved by PMDG being consistent about removing their GSX Integration.

<br/>

#### INI.A306

The iniBuilds EFB won't Update the MACZFW when Fuel/Payload is synced through the Plugin. There is no Workaround available and no Solution in sight.

<br/>

#### INI.A340

Even when iniBuilds Integration is disabled in the EFB, it will still reset Fuel/Payload when the respective GSX Service is reported as completed.<br/>
Simbrief Payload NEEDS to be imported in the EFB (Payload & Fueling -> Import all from Simbrief)!<br/>
It is recommended to disable the App Options to round up Fuel and randomize Pax Numbers - the Aircraft will override them anyway.

<br/><br/>

## 3 - Available Channel Definitions

| Aircraft | Author | Description |
| :-------------- | :---------: | :----------- |
| Fenix A320 | Fragtality | CPT and FO ACP from VHF1 to PA |
| FlyByWire A32NX | Fragtality | CPT and FO ACP with VHF, VOR and MKR |
| FlyByWire A380X | Fragtality | CPT and FO ACP from VHF1 over TEL to PA |
| iFly 737 | FatGingerHead | CPT and FO ACP from VHF1 to PA |
| iniBuilds A300-600 | Fragtality | CPT and FO ACP from VHF1 to PA |
| iniBuilds A330 | Fragtality | CPT and FO ACP from VHF1 to PA |
| iniBuilds A340 | Fragtality | CPT and FO ACP from VHF1 to PA |
| iniBuilds A350 | Fragtality | CPT and FO ACP from VHF1 over TEL to CAB |

<br/><br/>

## 4 - Available Aircraft Profiles

| Aircraft | Author | Description |
| :-------------- | :---------: | :----------- |
| Fenix A320 Native | Fragtality | Profile to enhance Fenix native Integration (so use the EFB to load via GSX!) and Volume Control (not using the FNX.A320 Plugin) |
| Fenix A320 PilotsDeck | Fragtality | Profile only enabling PilotsDeck Integration on the Fenix |
| FlyByWire A32NX | Fragtality | Profile enabling GSX Automation & Volume Control for the A320. Fuel, Payload and Equipment is perfectly handled by the Aircraft itself! (All other Aircraft Developers: Do *THAT* first, then build the Automation on Top) |
| FlyByWire A380X | Fragtality | Profile enabling GSX Automation & Volume Control for the A380. Fuel, Payload and Equipment is perfectly handled by the Aircraft itself! (All other Aircraft Developers: Do *THAT* first, then build the Automation on Top) |
| iFly 737 | FatGingerHead | Profile for Automation and Volume-Control for the iFLY B737. It has 0 Integration, Fuel and Payload need to be set manually and separately (!!) when the GSX Services run. |

<br/><br/>

## 4 - What about ... ?

### PMDG B737

Don't have any Hope about that. To develop a Plugin for that Aircraft I would need Access to it. And PMDG **consistently refuses to answer any Questions / Requests** for a free (time-limited) Copy - you don't even get an Answer at all. After 1 Forum-PM and two Support Tickets that is (it's not that I didn't try)!<br/>
And I on the other Side refuse to take a 737 as Donation - it just isn't right that existing Customers need to buy the Aircraft again from their own Money to support a Freeware Developer doing something for the Community.

<br/><br/>

### Deeper Integration with iniBuilds Aircrafts

Don't hope for anything. Or count on the Fact that I can continue "trick" the native Integration of the A350 in the Future. (so far, so good - knock on wood!)<br/>
iniBuilds just doesn't show any Interest for an Exchange on a technical Developer-to-Developer Level. When asking how to get in Touch with the Developers, the Discord Mods send you to Support and Support then parks your Ticket and you never hear anything back. On 2 Attempts.

<br/><br/>

### iniBuilds A340

While the Devs don't seem that open, the Folks at the Store/Sales Side are really great!
Upon asking if they could provide a free and time-limited Copy of the A340 to create a Plugin for A2G, I had the Aircraft on my Account within 1 Business-Day!<br/>
Thanks iniBuilds (Store/Sales Staff) for making that possible! :heart:

<br/><br/>

### FSLabs

Nothing planned or in sight. Even slightly weirder as with PMDG or iniBuilds because one of their Employees *approached me* for an updated PilotsDeck Profile and wanted to check for Copy/License for me ... and never got back on that :flushed:<br/>
Leaving that aside, it would still be questionable if and what I could achieve since their existing GSX Integration seems pretty 'strict' on how it wants to be used. Or if there is Way to work around that.

<br/><br/>
