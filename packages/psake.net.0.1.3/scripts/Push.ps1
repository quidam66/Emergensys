Task Push -Depends Tag -Description "Push the NuGet package(s) to nuget.org (a symbol package will be detected and pushed to symbolsource.org automatically); only allowed from the master branch" {
	Assert ($git_version.BranchName -eq "master") "Push to nuget.org can only be done from master branch"

	$packages = Get-ChildItem "$(Join-Path "$build_output_dir" "*")" -Include *.nupkg

	if ([String]::IsNullOrWhiteSpace($nuget_api_key)) {
		exec { Push-Packages -nuget $nuget -packages $packages }
	} else {
		exec { Push-Packages -nuget $nuget -packages $packages -api_key $nuget_api_key }
	}

	"Git pushing $($git_version.SemVer) tag to origin..."
	exec { git pull --quiet }
	exec { git push origin $git_version.SemVer }
}