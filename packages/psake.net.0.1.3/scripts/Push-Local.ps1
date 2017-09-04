Task Push-Local -Description "Push the NuGet package(s) to the local NuGet feed" {
	$packages = Get-ChildItem "$(Join-Path "$build_output_dir" "*")" -Include *.nupkg

	New-Directory "$local_nuget_feed"

	exec { Push-Packages -nuget $nuget -packages $packages -source "$local_nuget_feed" }
}