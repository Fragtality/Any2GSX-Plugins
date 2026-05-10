$currentDir = $pwd.Path
$pathChannel = Resolve-Path "PMDG.737.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir