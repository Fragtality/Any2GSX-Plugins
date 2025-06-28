$currentDir = $pwd.Path
$pathChannel = Resolve-Path "FNX.A320.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir