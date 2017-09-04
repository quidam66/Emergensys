Task Build -Description "Build the solution; create a Octopus Deploy package or zip artifact if required" {
	$sln = "$(Join-Path "$solution_dir" "$solution_name.sln")"
	$csproj = "$(Join-Path "$project_dir" "$project_name.csproj")"
	$version = $git_version.AssemblySemVer
	
	Assert (Test-Path "$sln") "Cannot not find solution '$sln'"
	Assert (Test-Path "$csproj") "Cannot find project '$csproj'"

	if (Assert-IsWebProject $csproj) {
		Write-Host "Building '$solution_name' solution`r`n"
		exec { msbuild "$sln" /p:Configuration=$config /p:DebugSymbols=false /p:DebugType=none /p:Platform="Any Cpu" /p:WebProjectOutputDir="$output_dir" /p:OutDir="$(Join-Path "$output_dir" "bin\")" /p:RunOctoPack=$run_octopack /p:OctoPackPublishPackageToFileShare="$build_output_dir" /p:OctoPackPackageVersion=$version /verbosity:quiet }
	}
	elseif (Assert-IsConsoleProject $csproj) {
		Write-Host "Building '$solution_name' solution`r`n"
		exec { msbuild "$sln" /p:Configuration=$config /p:DebugSymbols=false /p:DebugType=none /p:Platform="Any Cpu" /p:OutputPath="$output_dir" /p:RunOctoPack=$run_octopack /p:OctoPackPublishPackageToFileShare="$build_output_dir" /p:OctoPackPackageVersion=$version /verbosity:quiet }
	}
	elseif (Assert-IsLibraryProject $csproj) {
		Write-Host "Building '$solution_name' solution`r`n"
		exec { msbuild "$sln" /p:Configuration=$config /p:DebugSymbols=true /p:DebugType=pdbonly /p:Platform="Any Cpu" /p:OutputPath="$output_dir" /verbosity:quiet }
	}
	else {
		Write-Host -ForegroundColor Red "Could not build '$solution_name'; unable to identify project type"
		exit 1
	}
	
	$project_build_output = $(Join-Path "$project_dir" "$output_dir")
	Copy-Item "$project_build_output" "$artifact_dir" -Recurse -Force
	
	if ($zip_artifact) {
		$7za = Join-Path (Get-PackageDir "$solution_packages_config" "$packages_dir" "7-Zip.CommandLine") "tools\7za.exe"
		$zipFile = "$(Join-Path "$build_output_dir" "$project_name").$($version).zip"
		$include = "-ir!" + "$(Join-Path "$artifact_dir" "*")"
		"Creating archive '$zipFile'"
		exec { & "$7za" u -tzip "$zipFile" $include -mx9 | Out-Null }
	}
}