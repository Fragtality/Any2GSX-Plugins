# POST
# pwsh -ExecutionPolicy Unrestricted -file "$(SolutionDir)PackagePluginToDist.ps1" $(Configuration) $(SolutionDir) $(ProjectDir) "<PLUGIN>"

if ($args[0] -eq "*Undefined*") {
	exit 0
}

if ($args[1] -eq "*Undefined*") {
	exit 0
}

try {
	$buildConfiguration = $args[0]
	$pathBase = $args[1]
	$pathProject = $args[2]
	$pluginName = $args[3]

	$pathDistFolder = Join-Path $pathBase "dist"
	$pathDistPluginFolder = Join-Path $pathDistFolder "plugins"
	
	$pathPublish = Join-Path $pathProject "publish"
	$zipName = ($pluginName + ".zip")
	$zipPath = Join-Path $pathDistPluginFolder $zipName
	Remove-Item $zipPath -ErrorAction SilentlyContinue | Out-Null
	& "C:\Program Files\7-Zip\7z.exe" a -tzip $zipPath ($pathPublish + "\*") | Out-Null

	cd $pathDistFolder
	.\AddPluginToRepo.ps1 $zipName (Join-Path $pathPublish "manifest.json")

	Write-Host "SUCCESS: Packaging complete!"
	exit 0
}
catch {
	Write-Host "FAILED: Exception in PackagePluginToDist.ps1!"
	cd $pathBase
	exit -1
}