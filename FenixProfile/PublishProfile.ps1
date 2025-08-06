$currentDir = $pwd.Path
$pathProfileDeck = Resolve-Path "FNX.PilotsDeck.json"
$pathProfileNative = Resolve-Path "FNX.Native.json"
$versionProfile = "0.1.2"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfileDeck "Fenix - PilotsDeck only" "Fenix A320 (all Variants)" "Profile enabling only PilotsDeck Support (to be used together with Fenix2GSX)" "Fragtality" "$versionProfile" "0.1.1"
.\AddProfileToRepo.ps1 $pathProfileNative "Fenix - Native" "Fenix A320 (all Variants)" "Profile enhancing Fenix' native GSX Integration with Automation and Volume Control" "Fragtality" "$versionProfile" "0.1.1"

cd $currentDir