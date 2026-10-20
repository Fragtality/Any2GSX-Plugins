$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\PMDG.B737.lua" -Destination "publish\PMDG.B737.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\PMDG.737.json" -Destination "publish\PMDG.737.json" -Force -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\Pmdg737Interface" "PMDG.B737"

cd $currentDir