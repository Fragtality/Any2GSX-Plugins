$currentDir = $pwd.Path
$pathChannel = Resolve-Path "src\SYN.A22X.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir