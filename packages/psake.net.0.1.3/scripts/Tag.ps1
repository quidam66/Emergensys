Task Tag -Description "Create a git tag named after the artifact version" {
	"Tagging version $($git_version.SemVer)"
	
	# This will throw an error if git isn't available
	Get-Command git | Out-Null

	# Download updates from the remote repository
	exec { git fetch --tags --quiet }
	
	exec { if (git log ..origin) { throw "Upstream changes yet to be applied locally" } }
	# This can be achieved also using 'git cherry'
	exec { if (git log origin..) { throw "Changes yet to be applied to upstream" } }
	
	if(git show-ref --verify --quiet -- "refs/tags/$($git_version.SemVer)") { throw "Tag $($git_version.SemVer) already exists" }

	exec { git tag $git_version.SemVer }
}