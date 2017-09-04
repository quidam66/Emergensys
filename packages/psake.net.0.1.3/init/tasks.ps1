# Needed because running 'psake.bat -doc' result in $psake.build_success being false
$psake.build_success = $true

properties {
	. $(Get-DefaultPropertiesFile)
}

Import-DefaultTasks Version, Clean, Build, Test

Task Default -Depends Clean, Build, Test