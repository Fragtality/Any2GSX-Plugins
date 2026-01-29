$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A340.lua" -Destination "publish\INI.A340.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A340.json" -Destination "publish\INI.A340.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-a340" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\IniA340" "INI.A340"

cd $currentDir