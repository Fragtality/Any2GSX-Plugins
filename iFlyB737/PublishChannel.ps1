$currentDir = $pwd.Path
$pathChannel = Resolve-Path "IFLY.737.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir