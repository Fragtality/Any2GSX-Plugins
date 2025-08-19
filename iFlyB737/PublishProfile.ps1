$currentDir = $pwd.Path
$pathProfile = Resolve-Path "IFLY.737-Profile.json"
$versionProfile = "0.1.0"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfile "iFLY 737" "iFLY 737 MAX8" "Profile for Automation and Volume-Control for the iFLY B737.\r\nIMPORTANT: Set a lower than planned Fuel Amount before starting the Departure Services, else the Fuel Service isn't called with iFly's default of 50% FOB.\r\nThe SmartButton is mapped to the INT/RAD Switch on the Captain's ACP." "FatGingerHead" "$versionProfile" "0.1.9"

cd $currentDir