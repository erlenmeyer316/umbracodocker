# Environment Variables
[string]$UUID = Get-Date -Format "MMddyyyy_HHmmss"
[string]$ScriptDirectory = $PSScriptRoot
[string]$ParentDirectory = Split-Path -Path ($ScriptDirectory) -Parent
[string]$SourceRepository = "https://github.com/erlenmeyer316/umbracodocker.git"


# create workspace
Write-Host "UUID: $UUID"
[string]$workspace = "$($ParentDirectory)\integration-workspace\integration_$($UUID)"
Write-Host "Creating workspce $workspace"
New-Item -ItemType Directory -Path $workspace | Out-Null
Set-Location $workspace

# clone source repository to local workspace
Write-Host "Cloning $SourceRepository"
[string]$SourceWorkspacePath = "$($workspace)\source-repo"
git clone $SourceRepository $SourceWorkspacePath

# prune merged branches
Write-Host "TODO: Pruning merged branches"

# Source ini file
[string]$ProjectName = "umbracodocker"
[string]$SourceDockerFilesPath = "build"
[string]$DeploymentRepository = "https://github.com/erlenmeyer316/dicki-deploy.git"
[string]$DeploymentRootKustomizationPath = "production/kustomization.yaml"
[string]$DeploymentManifestBasesFolder = "bases"
[string]$DeploymentManifestOverlayFolder = "overlays"
[string]$DeploymentManifestTemplateFolder = "templates"
[string]$DeploymentManifestsSecrets = "secrets.json"
[string]$ContainerRegistryUrl = ""
[string]$RestoreDevFromProd = ""

# clone deployment repository to local workspace
Write-Host "Cloning $DeploymentRepository"
[string]$DeploymentWorkspacePath = "$($workspace)\deployment-repo"
git clone $DeploymentRepository $DeploymentWorkspacePath

# loop through each branch in repository
$branches = git branch --list
foreach ($branch in $branches) {
  $branchName = $branch.Trim()
    if ($branchName) {
    Write-Host "Processing branch: $branchName"
    # check out the branch
    git checkout $branchName

    # get the sha of the head commit
    $headSHA = @(git rev-parse HEAD)
    # get the latest tag of the head commit

    # set the commit tag

    # get the built tag if it exists

    # get the integrated tag if it exists

    # build images if no built tag

    # create deploy overlay if no integrated tag
    
    # update deploy overlay if integrated tag AND no built tag
  }
}

# remove deploy overlays that don't have matching branches in source repository
# commit deploy repo

# reset the workspace
Write-Host "Removing workspce $workspace"
Set-Location $ScriptDirectory
Remove-Item -Path $workspace -Recurse -Force | Out-Null