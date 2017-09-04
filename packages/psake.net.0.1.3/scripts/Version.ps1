Task Version -Description "Display an overview of Semantic Version information" {
	Write-Host "Branch:`t`t`t$($git_version.BranchName)"
	Write-Host "Version:`t`t$($git_version.AssemblySemVer)"
	Write-Host "File Version:`t`t$($git_version.AssemblyFileSemVer)"
	Write-Host "Informational Version:`t$($git_version.InformationalVersion)"
	Write-Host "NuGet Version:`t`t$($git_version.NuGetVersion)"
}