$currentDir = $pwd.Path
$pathProfile = Resolve-Path "PMDG.737-Profile.json"
$versionProfile = "0.1.0"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfile "PMDG 737" "PMDG 737 (All Variants)" "Profile for Automation and Volume-Control for the PMDG B737.\r\nIMPORTANT: Usage of GSX' internal Aircraft Profile is adviced.\r\nNOTE: The SmartButton is mapped to the 'GRD CALL' Button in the Overhead." "FatGingerHead" "$versionProfile" "0.4.3"

cd $currentDir