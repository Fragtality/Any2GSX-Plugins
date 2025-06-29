$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A350.lua" -Destination "publish\INI.A350.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A350.json" -Destination "publish\INI.A350.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\a350" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a350-900" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a350-900-ulr" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a350-1000" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\iniA350" "INI.A350"

cd $currentDir