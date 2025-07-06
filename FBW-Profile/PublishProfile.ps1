$currentDir = $pwd.Path
$pathProfile320 = Resolve-Path "FBW.A320-Profile.json"
$pathProfile380 = Resolve-Path "FBW.A380-Profile.json"
$versionProfile = "0.1.1"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfile320 "FlyByWire A320" "FBW A320 (stable/dev)" "Profile for Automation and Volume-Control on the FBW A320.\r\nImport the Flightplan in the MCDU to trigger Departure Services.\r\nDon't forget to power on the EFB first!\r\nThe SmartButton is mapped to the MECH Call Button on the Overhead." "Fragtality" "$versionProfile" "0.1.1"
.\AddProfileToRepo.ps1 $pathProfile380 "FlyByWire A380" "FBW A380 (stable/dev)" "Profile for Automation and Volume-Control on the FBW A380.\r\nImport the Flightplan in the MCDU to trigger Departure Services.\r\nDon't forget to power on the EFB first!\r\nThe SmartButton is mapped to the INT/RAD Switch on the ACP (Captain)." "Fragtality" "$versionProfile" "0.1.1"

cd $currentDir