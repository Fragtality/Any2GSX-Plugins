$currentDir = $pwd.Path
$pathProfile = Resolve-Path "PMDG.737-Profile.json"
$versionProfile = "0.2.0"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfile "PMDG 737" "PMDG 737 (All Variants)" "Profile for Automation and Volume-Control for the PMDG B737.\r\nIMPORTANT: Usage of GSX' internal Aircraft Profile is adviced.\r\nNOTE: Use 'GRD CALL' Button to trigger Departure Services (after the Aircraft is powered and NAV Lights on)!\r\nThe SmartButton is now mapped to the R/T I/C switch on the Radio Panel!" "FatGingerHead" "$versionProfile" "0.4.10"

cd $currentDir