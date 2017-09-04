Task Clean -Description "Delete all intermediate and build output files" {
	if (Test-Path $build_output_dir) {
		"Cleaning '$build_output_dir'"
		Remove-Directory "$(Join-Path "$build_output_dir" "*")"
	}
	"Cleaning '$solution_dir'"
	Remove-Directory "$(Join-Path "$solution_dir" "*\bin")"
	Remove-Directory "$(Join-Path "$solution_dir" "*\obj")"
	Remove-Directory "$(Join-Path "$(Join-Path "$solution_dir" "*")" "$output_dir")"
}