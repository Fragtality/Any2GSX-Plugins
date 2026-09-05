$currentDir = $pwd.Path
Copy-Item -Path "src\manifest.json" -Destination "publish\manifest.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\SYN.A22X.lua" -Destination "publish\SYN.A22X.lua" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\SYN.A22X.json" -Destination "publish\SYN.A22X.json" -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "src\synaptic_a220" -Destination "publish" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

cd ..
.\PackagePluginToDist.ps1 "Release" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins" "C:\Users\Fragtality\source\repos\Any2GSX-Plugins\SynapticA220" "SYN.A220"

cd $currentDir