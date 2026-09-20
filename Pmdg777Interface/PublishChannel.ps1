$currentDir = $pwd.Path
$pathChannel = Resolve-Path "publish\PMDG.B777.json"

cd ..\dist
.\AddChannelToRepo.ps1 $pathChannel

cd $currentDir