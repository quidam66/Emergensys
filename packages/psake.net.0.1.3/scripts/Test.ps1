Task Test -Description "Run all tests" {
	New-Directory $test_results_dir

	$tests_object = New-Object PSObject -Property @{ 
		OutputDir = "$output_dir";
		PackagesDir = "$packages_dir";
		SolutionPackagesConfig = "$solution_packages_config";
		TestProjects = $test_projects;
		TestResultsDir = "$test_results_dir";
		Framework = $psake.context.config.framework;
	}
	
	exec { Invoke-Tests $tests_object }
}

Task UnitTest -Description "Run unit tests only" {
	New-Directory $test_results_dir

	$tests_object = New-Object PSObject -Property @{
		OutputDir = "$output_dir";
		PackagesDir = "$packages_dir";
		SolutionPackagesConfig = "$solution_packages_config";
		TestProjects = $test_projects | Where-Object { $_.Name.EndsWith("UnitTests") };
		TestResultsDir = "$test_results_dir";
		Framework = $psake.context.config.framework;
	}

	exec { Invoke-Tests $tests_object }
}

Task IntegrationTest -Description "Run integration tests only" {
	New-Directory $test_results_dir

	$tests_object = New-Object PSObject -Property @{
		OutputDir = "$output_dir";
		PackagesDir = "$packages_dir";
		SolutionPackagesConfig = "$solution_packages_config";
		TestProjects = $test_projects | Where-Object { $_.Name.EndsWith("IntegrationTests") };
		TestResultsDir = "$test_results_dir";
		Framework = $psake.context.config.framework;
	}

	exec { Invoke-Tests $tests_object }
}

Task AcceptanceTest -Description "Run acceptance tests only" {
	New-Directory $test_results_dir

	$tests_object = New-Object PSObject -Property @{
		OutputDir = "$output_dir";
		PackagesDir = "$packages_dir";
		SolutionPackagesConfig = "$solution_packages_config";
		TestProjects = $test_projects | Where-Object { $_.Name.EndsWith("AcceptanceTests") };
		TestResultsDir = "$test_results_dir";
		Framework = $psake.context.config.framework;
	}

	exec { Invoke-Tests $tests_object }
}