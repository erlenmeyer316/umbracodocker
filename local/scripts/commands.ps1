[CmdletBinding()]
Param(
      [Parameter(Mandatory=$false)][switch]$build=$false,
      [Parameter(Mandatory=$false)][switch]$up=$false,
      [Parameter(Mandatory=$false)][switch]$down=$false,
      [Parameter(Mandatory=$false)][switch]$cycle=$false,
      [Parameter(Mandatory=$false)][switch]$resetDb=$false,
      [Parameter(Mandatory=$false)][switch]$printVars=$false,
      [Parameter(ValueFromRemainingArguments)][string[]]$arguments
    )

[string]$CallingPath = Get-Location
[string]$ScriptFullPath = $PSCommandPath
[string]$ScriptDirectory = $PSScriptRoot
[string]$LocalDirectory = Split-Path -Path ($ScriptDirectory) -Parent
[string]$ProjectDirectory = Split-Path -Path ($LocalDirectory) -Parent
[string]$SourceDirectory = Get-ChildItem -Path $ProjectDirectory -Directory | Where-Object {$_.Name -eq "src"}
[string]$EnvFilePath = "$LocalDirectory/.env"

function _Bold{
    param (
        [Parameter()][string]$text
    )
    return (("**$($text)**" | ConvertFrom-MarkDown -AsVt100EncodedString).VT100EncodedString).Replace("`n", '')
}

function _GetEnvValue([string]$varName){
    # ensure the .env file exists
    if (Test-Path $EnvFilePath) {
        # loop through each line
        Get-Content $EnvFilePath | ForEach-Object {
            # Ignore commented out variables
            if($_ -notmatch "#" ){
                # if the line contains a key/pair
                if($_ -match "=" ) {
                    $split = $_.Split("=", 2)
                    $name = $split[0].Trim()
                    $value = $split[1].Trim()
                    if($name -match $varName) {
                        return $value
                    }
                }
            }
            
        }
    } 
    return ""
}


function _StartDocker {
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Host "Starting Docker..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        while (-not (Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue)) {
            Write-Host "Waiting for Docker to start..."
            Start-Sleep -Seconds 5
        }
        Write-Host "Docker has started!"
        $attempts = 0
        do {
            docker ps -a 2>&1>$null
            if ($?) {
                Write-Host "Docker is ready!"
                return $true
            }
            $attempts++    
            Write-Host "Waiting for Docker to be ready..."
            Start-Sleep -Seconds 5
        } while ($attempts -le 10)
        
        Write-Host "Something went wrong."
        exit 1
        
    }
}

function Usage {    
    Write-Output "Usage: $ScriptFullPath [-command command] "
    Write-Output "Commands:"
    Write-Output "  $(_Bold("help")) - shows this help text"
    Write-Output "  $(_Bold("build")) - build the docker containers for this project"
    Write-Output "  $(_Bold("up")) - start the docker containers for this project"
    Write-Output "  $(_Bold("down")) - stop the docker containers for this project"
    exit 1
}

function Build([string[]]$options) {
    Set-Location $LocalDirectory

    if([string]::IsNullOrEmpty($options)){
         docker-compose build 
    } else {
         docker-compose -f "$($LocalDirectory)/docker-compose.yaml" build $($options -split '\s+')
    }
    
    Set-Location $CallingPath
}

function Up([string[]]$options) {
    Set-Location $LocalDirectory
   
    if ($options -notcontains "-d" -and $options -notcontains "--detach"){
        $options += "--detach"
    }

    docker-compose --file "$($LocalDirectory)/docker-compose.yaml" up $($options -split '\s+')
    
    Set-Location $CallingPath
}

function Down([string[]]$options) {
    Set-Location $LocalDirectory

    if ($options.count -lt 1){
        $options += "--remove-orphans"
    }

    docker-compose --file "$($LocalDirectory)/docker-compose.yaml" down $($options -split '\s+')

    Set-Location $CallingPath
}

function ResetDatabase{
    [string]$composeProjectName = _GetEnvValue "COMPOSE_PROJECT_NAME"
    [string]$volumeName = _GetEnvValue "MSSQL_SERVER_VOLUME_NAME"
    
    if([string]::IsNullOrEmpty($composeProjectName) -or [string]::IsNullOrEmpty($volumeName)){
         Write-Host "Missing environment variables."
         exit
    }
    Down
    docker volume rm $($composeProjectName.Trim() + "__" + $volumeName.Trim())    
}

function PrintVars{
    Write-Output "CallingPath=$CallingPath"
    Write-Output "ScriptFullPath=$ScriptFullPath"
    Write-Output "ScriptDirectory=$ScriptDirectory"
    Write-Output "LocalDirectory=$LocalDirectory"
    Write-Output "ProjectDirectory=$ProjectDirectory"
    Write-Output "SourceDirectory=$SourceDirectory"
    # ensure the .env file exists
    if (Test-Path $EnvFilePath) {
        # loop through each line
        Get-Content $EnvFilePath | ForEach-Object {
            # Ignore commented out variables
            if($_ -notmatch "#" ){
                # if the line contains a key/pair
                if($_ -match "=" ) {
                    $split = $_.Split("=", 2)
                    $name = $split[0].Trim()
                    $value = $split[1].Trim()
                    Write-Output "$name=$value"
                }
            }
            
        }
    } else {
        Write-Warning "'.env' file not found."
    }
}

if ($printVars){
    PrintVars
} elseif ($build) {
    _StartDocker
    Build $arguments
} elseif ($down) {
    _StartDocker
    Down $arguments
} elseif ($up) {
    _StartDocker
    Up $arguments
} elseif ($cycle) {
    _StartDocker
    Down
    Build --no-cache
    Up
} elseif($resetDb){
    _StartDocker
    ResetDatabase
}
else {
    Usage
}