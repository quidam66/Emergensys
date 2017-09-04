# Executed at the solution level; not dependent on project
# It runs:
# - the first time a package is installed in a solution
# - every time the solution is opened (Package Manager Console window has to be open at the same time for the script to run)

param($installPath, $toolsPath, $package)

# $installPath	the path to the directory where the package is installed
# $toolsPath	the path to the tools directory in $installPath
# $package		a reference to the package object

Add-Type -AssemblyName NugetConsole.Host.PowerShell

function Add-File {	
	param($projectItems, [string]$source, [string]$destination, [bool]$override)

	$fileName = Split-Path -Path $destination -Leaf
	
	if ((-not (Test-Path $destination)) -or ((Test-Path $destination) -and $override)) {
		Write-Host "Copying '$fileName'."
		Copy-Item $source $destination | Out-Null
	}

	if($($buildProjectItems.GetEnumerator() | Where { $_.FileNames(1) -eq $destination }) -eq $null) {
		Write-Host "Adding to the solution '$fileName'."
		$buildProjectItems.AddFromFile($destination) | Out-Null
	}
}

function Remove-FileFromProject {
	param($projectItem, [string]$file)

	if($projectItem -ne $null) {
		Write-Host "Deleting from the solution '$($projectItem.Name)'."
		$projectItem.Delete() | Out-Null
	}
}

function Install-PackageIntoProject {
	param([string]$projectName, [string]$projectFullName, [string]$packageId, [bool]$developmentDependency)

	Write-Host "Attempting to resolve '$packageId' for $projectName."

	if (-not (Get-Package -ProjectName $projectName -Filter $packageId)) {
		Install-Package $packageId -ProjectName $projectName
		if ($developmentDependency) {
			Write-Host "Set '$packageId' as development dependency for $projectName."
			$packagesConfig = Join-Path (Split-Path $projectFullName -Parent) "packages.config"
			[xml]$packagesXml = Get-Content $packagesConfig
			$packagesXml.packages.package | Where { $_.id -eq $packageId } | ForEach { $_.SetAttribute("developmentDependency", "true") }
			$packagesXml.Save($packagesConfig)
		}
		return $true
	}
	return $false
}

function Get-Interface {
    param($object, [type]$interfaceType)
    
    [NuGetConsole.Host.PowerShell.Implementation.PSTypeWrapper]::GetInterface($object, $interfaceType)
}

function Get-VSService {
    param([type]$serviceType, [type]$interfaceType)
 
    $service = [Microsoft.VisualStudio.Shell.Package]::GetGlobalService($serviceType)

    if ($service -and $interfaceType) {
        $service = Get-Interface $service $interfaceType
    }
 
    $service
}

function Enable-PackageRestoreIfNotAlreadyEnabled {
	$componentService = Get-VSService ([Microsoft.VisualStudio.ComponentModelHost.SComponentModel]) ([Microsoft.VisualStudio.ComponentModelHost.IComponentModel])
	$packageSourceProvider = $componentService.GetService([NuGet.VisualStudio.IVsPackageSourceProvider])
	$packageSourceProvider.ActivePackageSource = [NuGet.VisualStudio.AggregatePackageSource]::Instance
	$packageRestoreManager = $componentService.GetService([NuGet.VisualStudio.IPackageRestoreManager])

	if (-not $packageRestoreManager.IsCurrentSolutionEnabledForRestore) {
		Write-Host "Enabling Package Restore."
		$packageRestoreManager.EnableCurrentSolutionForRestore($false)
	}
}

function Update-AssemblyInfo {
	param($projectItem)
	
	Write-Host "Comment out AssemblyInfo version for $($projectItem.ProjectName)."
	$projectDir = Split-Path "$($projectItem.FullName)" -Parent
	Get-ChildItem $projectDir -Recurse -Filter "*AssemblyInfo.cs" | Remove-AssemblyVersion
}

function Remove-AssemblyVersion {
	$fileName = $input.FullName
	$newFileContent = Get-Content "$fileName" | ForEach-Object {
		% { if (($_ -match "AssemblyVersion" -or $_ -match "AssemblyFileVersion" -or $_ -match "AssemblyInformationalVersionAttribute") -and -not $_.StartsWith("//")) { 
				$_ -replace ".+", "//$_" 
			} else { 
				$_ 
			}
		}
	}
	Set-Content "$fileName" $newFileContent
}

$solutionDir = Resolve-Path .
$nugetDir = Join-Path $solutionDir ".nuget"
$packagesConfig = Join-Path $nugetDir "packages.config"

if (Test-Path $packagesConfig) {
	[xml]$packagesXml = Get-Content $packagesConfig

	# To prevent NuGet Package Manager from running this for every version of the package that happens to be in the packages folder
	if (($packagesXml.packages.package | Where { $_.id -eq $package.Id -and $_.version -eq $package.Version }) -ne $null) {
		Write-Host "Initializing '$($package.Id) $($package.Version)'."

		Import-Module (Join-Path $installPath "Functions.psm1")

		$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
		$solutionName = ($solution.Properties | Where { $_.Name -eq "Name" }).Value
		$buildProject = $solution.Projects | Where { $_.Name -eq ".build" }
		$buildDir = Join-Path $solutionDir ".build"
		
		# Add '.build' solution folder if it does not already exist
		if ($buildProject -eq $null) {
            $buildProject = $solution.AddSolutionFolder(".build")
		}

		Enable-PackageRestoreIfNotAlreadyEnabled
		
		# Remove NuGet.exe from the solution
		$nugetProject = $solution.Projects | Where { $_.Name -eq ".nuget" }
		Remove-FileFromProject ($nugetProject.ProjectItems | Where { $_.Name -eq "NuGet.exe" }) (Join-Path $nugetDir "NuGet.exe")

		# Change NuGet.targets to download NuGet.exe if it does not already exist
		$nugetTargetsFile = Join-Path $nugetDir "NuGet.targets"
		$nugetTargets = [xml](Get-Content $nugetTargetsFile)
		$nugetTargets.Project.PropertyGroup[0].DownloadNuGetExe.InnerText = "true"
		$nugetTargets.Save($nugetTargetsFile)

		$buildProjectItems = Get-Interface $buildProject.ProjectItems ([EnvDTE.ProjectItems])
		
		# Add solution build scripts
		Add-File $buildProjectItems (Join-Path $installPath "init\psake.bat") $(Join-Path $solutionDir "psake.bat") $true
		Add-File $buildProjectItems (Join-Path $installPath "init\tasks.ps1") $(Join-Path $solutionDir "tasks.ps1") $false
		
		# Install GitVersion MSBuild task for each C# project
		Write-Host "`r"
		$solution.Projects | Where { $_.Type -eq "C#" } | ForEach { if(Install-PackageIntoProject $_.ProjectName $_.FullName "GitVersionTask" $true) { Update-AssemblyInfo $_; Write-Host "`r" } }
	}
} else {
	Write-Host -ForegroundColor Red "ERROR: Cannot find solution 'packages.config'."
}