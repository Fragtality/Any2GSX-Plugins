$currentDir = $pwd.Path
$pathChannel = Resolve-Path "src\INI.A306.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir