
function Get-PackageDir {
	param([string]$packages_config, [string]$packages_dir, [string]$package_name, [Parameter(Mandatory=$false)][bool]$error_if_not_found=$true)

	[xml]$packagesXml = Get-Content $packages_config
	$package = $packagesXml.packages.package | Where { $_.id -eq $package_name }

	if ($package -ne $null) {
		return Join-Path $packages_dir ($package.id + '.' + $package.version)
	} elseif ($error_if_not_found) {
		Write-Host -ForegroundColor Red "ERROR: Cannot find package '$package_name'."
		exit 1;
	}
	
	return Join-Path $packages_dir $package_name
}

function Get-TestProjectsFromSolution {
	param([string]$solution_dir, [string]$solution_name)

	$solution = "$(Join-Path "$solution_dir" "$solution_name").sln"
	If(Test-Path "$solution") {
		$projects = @()
			Get-Content "$solution" |
			Select-String 'Project\(' |
				ForEach {
					$projectParts = $_ -Split '[,=]' | ForEach { $_.Trim('[ "{}]') };
					if($projectParts[2].EndsWith(".csproj") -and ($projectParts[1].EndsWith("Tests"))) {
						$projectPathParts = $projectParts[2].Split("\")
						$projects += New-Object PSObject -Property @{
							Name = $projectParts[1];
							File = $projectPathParts[-1];
							Directory = Join-Path "$solution_dir" $projectParts[2].Replace("\$($projectPathParts[-1])", "");
						}
					}
				}
		return $projects
	}
}

function Import-DefaultTasks {
	param([string[]]$tasks)

	foreach($task in $tasks) {
		$taskFile = Join-Path "$PSScriptRoot" "scripts\$task.ps1"
		Assert (Test-Path $taskFile) "Could not find '$task' BuildAutomation task"
		Include $taskFile
	}
}

function Get-DefaultPropertiesFile {
	$propertiesFile = Join-Path "$PSScriptRoot" "scripts\Properties.ps1"
	Assert (Test-Path $propertiesFile) "Could not find BuildAutomation properties"
	return $propertiesFile
}

function New-Directory {
	param([string]$dir)

	if (-not (Test-Path "$dir")) { New-Item -ItemType Directory -Path "$dir" -Force | Out-Null }
}

function Push-Packages {
	[CmdletBinding(DefaultParameterSetName="DefaultPushSource")] 
	param(
		[Parameter(Mandatory=$true,Position=0)]
		[string]$nuget,
		
		[Parameter(Mandatory=$true,Position=1)]
		[string[]]$packages,

		[Parameter(Mandatory=$true,ParameterSetName="DefaultPushSourceWithKey",Position=2)]
		[Parameter(Mandatory=$true,ParameterSetName="Server",Position=2)]
		[string]$api_key,
		
		[Parameter(Mandatory=$true,ParameterSetName="Server",Position=3)]
		[Parameter(Mandatory=$true,ParameterSetName="Folder",Position=2)]
		[string]$source
	)

	foreach($package in $packages) {
		switch ($psCmdlet.ParameterSetName) {
			"DefaultPushSource"  { exec { & $nuget push "$package" -NonInteractive } }
			"DefaultPushSourceWithKey" { exec { & $nuget push "$package" $api_key -NonInteractive } }
			"Folder"  { exec { & $nuget push "$package" -Source $source -NonInteractive } }
			"Server" { exec { & $nuget push "$package" $api_key -Source $source -NonInteractive } }
		}
	}
}

function Remove-Directory {
	param([string]$path)

	Remove-Item "$path" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

function Assert-IsWebProject {
	param([string]$csproj)

	(((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path "$csproj") -ne $null) -and ((Select-String -pattern "<OutputType>WinExe</OutputType>" -path "$csproj") -eq $null))
}

function Assert-IsConsoleProject {
	param([string]$csproj)

	(((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path "$csproj") -eq $null) -and ((Select-String -pattern "<OutputType>Exe</OutputType>" -path "$csproj") -ne $null))
}

function Assert-IsLibraryProject {
	param([string]$csproj)

	(((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path "$csproj") -eq $null) -and ((Select-String -pattern "<OutputType>Library</OutputType>" -path "$csproj") -ne $null))
}

function Get-FrameworkVersion {
	param([string]$framework)

	($framework -split "^((?:\d+\.\d+)(?:\.\d+){0,1})(x86|x64){0,1}$")[1]
}

function Invoke-Tests {
	param([PSCustomObject]$test_object)

	if($test_object.TestProjects -eq $null -or $test_object.TestProjects.Count -eq 0) { Write-Host "No test projects were found" }
	
	$framework_version = Get-FrameworkVersion $test_object.Framework

	$mspec = Join-Path (Get-PackageDir "$($test_object.SolutionPackagesConfig)" "$($test_object.PackagesDir)" "Machine.Specifications.Runner.Console" $false) "tools\mspec-clr4.exe"
	$nunit = Join-Path (Get-PackageDir "$($test_object.SolutionPackagesConfig)" "$($test_object.PackagesDir)" "NUnit.Runners" $false) "tools\nunit-console.exe"
	$xunit = Join-Path (Get-PackageDir "$($test_object.SolutionPackagesConfig)" "$($test_object.PackagesDir)" "xunit.runner.console" $false) "tools\xunit.console.exe"
	
	$mspec_test_assemblies = @()
	$nunit_test_assemblies = @()
	$xunit_test_assemblies = @()

	foreach ($test_project in $test_object.TestProjects) {
		$outputPath = Join-Path "$($test_project.Directory)" "$($test_object.OutputDir)"
		$assembliesPath = @{$true=(Join-Path "$outputPath" "bin");$false=$outputPath}[(Test-Path (Join-Path "$outputPath" "bin"))]
		$tests_found = $false
			
		if (Test-Path "$(Join-Path "$assembliesPath" "Machine.Specifications.dll")") {
			Assert (Test-Path $mspec) "Missing solution package 'Machine.Specifications.Runner.Console'"
			$mspec_test_assemblies += Join-Path "$assembliesPath" "$($test_project.Name).dll"
			$tests_found = $true
		}
			
		if (Test-Path "$(Join-Path "$assembliesPath" "nunit.framework.dll")") {
			Assert (Test-Path $nunit) "Missing solution package 'NUnit.Runners'"
			$nunit_test_assemblies += Join-Path "$assembliesPath" "$($test_project.Name).dll"
			$tests_found = $true
		}

		if (Test-Path "$(Join-Path "$assembliesPath" "xunit.core.dll")") {
			Assert (Test-Path $xunit) "Missing solution package 'xunit.runner.console'"
			$xunit_test_assemblies += Join-Path "$assembliesPath" "$($test_project.Name).dll"
			$tests_found = $true
		}

		if(-Not $tests_found) {
			Write-Host "No tests found in $($test_project.Name)"
		}
	}

	if($mspec_test_assemblies.Length -gt 0) {
		"`r`nRunning MSpec Tests"
		exec { & $mspec --xml "$(Join-Path "$($test_object.TestResultsDir)" "MSpec.xml")" --silent ""$($mspec_test_assemblies -Join """ """)"" }
	}
	
	if($nunit_test_assemblies.Length -gt 0) {
		"`r`nRunning NUnit Tests"
		exec { & $nunit /work:"$($test_object.TestResultsDir)" /result:"NUnit.xml" /nologo /nodots /framework:"net-$framework_version" ""$($nunit_test_assemblies -Join """ """)"" }
	}
	
	if($xunit_test_assemblies.Length -gt 0) {
		"`r`nRunning xUnit.net Tests"
		exec { & $xunit ""$($xunit_test_assemblies -Join """ """)"" -nologo -quiet -xml "$(Join-Path "$($test_object.TestResultsDir)" "xUnit.xml")" }
	}
}