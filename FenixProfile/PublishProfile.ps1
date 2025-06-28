$currentDir = $pwd.Path
$pathProfileDeck = Resolve-Path "FNX.PilotsDeck.json"
$pathProfileNative = Resolve-Path "FNX.Native.json"

cd ..\dist
.\AddProfileToRepo.ps1 $pathProfileDeck "Fenix - PilotsDeck only" "Fenix A320 (all Variants)" "Profile enabling only PilotsDeck Support (to be used together with Fenix2GSX)" "Fragtality" "0.1.0" "0.1.0"
.\AddProfileToRepo.ps1 $pathProfileNative "Fenix - Native" "Fenix A320 (all Variants)" "Profile enhancing Fenix' native GSX Integration with Automation and Volume Control" "Fragtality" "0.1.0" "0.1.0"

cd $currentDir