$currentDir = $pwd.Path
$pathChannel320 = Resolve-Path "FBW.A320.json"
$pathChannel380 = Resolve-Path "FBW.A380.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel320
.\AddChannelToRepo.ps1 $pathChannel380

cd $currentDir