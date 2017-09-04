task Pack -Description "Create a NuGet package" {
	New-Directory "$artifact_dir"

	$csproj = "$(Join-Path "$project_dir" "$project_name.csproj")"
	Assert (Test-Path $csproj) "Could not find '$project_name.csproj'"
						
	exec { & $nuget pack "$csproj" -BasePath "$project_dir" -OutputDirectory "$build_output_dir" -Prop OutputPath="$output_dir" -Symbols -Version $git_version.NuGetVersion  }
}
