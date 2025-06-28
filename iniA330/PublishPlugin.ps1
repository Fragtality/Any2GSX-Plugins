$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A330.lua" -Destination "publish\INI.A330.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\INI.A330.json" -Destination "publish\INI.A330.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\microsoft-a330" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\IniA330" "INI.A330"

cd $currentDir