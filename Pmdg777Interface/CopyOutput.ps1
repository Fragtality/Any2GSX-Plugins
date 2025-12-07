# POST
# pwsh -ExecutionPolicy Unrestricted -file "$(ProjectDir)CopyOutput.ps1" $(Configuration) $(SolutionDir) $(ProjectDir) "Any2GSX"

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
	$appFolderName = $args[3]
	$pathBase = (Resolve-Path (Join-Path $pathBase "..")).Path

	$dllPath = Join-Path $pathProject (Join-Path (Join-Path "bin" $buildConfiguration) "\net10.0-windows10.0.17763.0\win-x64\Pmdg777Interface.dll")
	$manifestPath = Join-Path $pathProject (Join-Path (Join-Path "bin" $buildConfiguration) "\net10.0-windows10.0.17763.0\win-x64\manifest.json")		
	$destPath = Join-Path $pathProject "publish"

	Copy-Item -Path $dllPath -Destination $destPath -Force | Out-Null
	Copy-Item -Path $manifestPath -Destination $destPath -Force | Out-Null

	Write-Host "SUCCESS: Copy complete!"
	exit 0
}
catch {
	Write-Host "FAILED: Exception in CopyOutput.ps1!"
	cd $pathBase
	exit -1
}