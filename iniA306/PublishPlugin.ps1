$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A306.lua" -Destination "publish\INI.A306.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A306.json" -Destination "publish\INI.A306.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\a300-600" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a306f" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a306f-pw" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a306r" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\inibuilds-aircraft-a306r-pw" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\IniA306" "INI.A306"

cd $currentDir