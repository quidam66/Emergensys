Task Set-NuGetApiKey -Description "Save an API key for nuget.org and SymbolSource" {
	Assert ([String]::IsNullOrWhiteSpace($nuget_api_key)) "An API key for nuget.org and SymbolSource has already been defined"

	$api_key = Read-Host "Please enter the API key for nuget.org and SymbolSource"

	exec { & $nuget setApiKey $api_key }
}