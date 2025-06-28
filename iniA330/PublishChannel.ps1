$currentDir = $pwd.Path
$pathChannel = Resolve-Path "src\INI.A330.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir