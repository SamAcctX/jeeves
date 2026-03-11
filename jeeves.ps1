<#
.SYNOPSIS
    Jeeves - OpenCode Container Management Helper

.DESCRIPTION
    A PowerShell script for managing multiple concurrent OpenCode (jeeves) Docker
    containers. Each project directory gets its own container instance named after
    the directory (e.g., jeeves-myproject). Ports are auto-assigned starting from
    3333 to avoid conflicts between instances.

    The script can be invoked from any directory as it maps the current working
    directory (pwd) to /proj inside the container.

.PARAMETER Command
    The command to execute (build, start, stop, restart, rm, shell, logs, status, list, clean, help)

.PARAMETER NoCache
    Build without using Docker cache (valid for 'build' command)

.PARAMETER Desktop
    Build desktop binaries (valid for 'build' command)

.PARAMETER InstallClaudeCode
    Install Claude Code in the container (valid for 'build' command)

.PARAMETER Clean
    Perform a clean start: stops, removes container/image, rebuilds from scratch, then starts (valid for 'start' command)

.PARAMETER Port
    Use a specific host port for the web UI (valid for 'start' command, default: auto-assign from 3333)

.PARAMETER Ports
    Extra port mappings as comma-separated host:container pairs (valid for 'start' command)

.PARAMETER Remove
    Also remove the container after stopping (valid for 'stop' command)

.PARAMETER Force
    Force stop the container using SIGKILL instead of SIGTERM (valid for 'stop' command)

.PARAMETER Dind
    Enable Docker-in-Docker (DinD) support (valid for 'start', 'restart' commands)

.PARAMETER All
    Operate on all jeeves instances (valid for 'clean', 'status' commands)

.PARAMETER Image
    Also remove the shared Docker image (valid for 'clean' command)

.EXAMPLE
    .\jeeves.ps1 start
    Start the container for the current directory (auto-assign port)

.EXAMPLE
    .\jeeves.ps1 start --port 3334 --ports 3000:3000
    Start with specific port and extra port mappings

.EXAMPLE
    .\jeeves.ps1 list
    Show all running jeeves instances

.EXAMPLE
    .\jeeves.ps1 clean --all --image
    Remove all jeeves containers and the shared image

.NOTES
    File Name      : jeeves.ps1
    Author         : OpenCode
    Prerequisite   : Docker must be installed and running
    Platform       : Cross-platform (Windows, Linux, macOS)

    Multi-Container Model:
    - Container names are derived from the current directory (jeeves-<folder>)
    - Ports auto-increment from 3333 to avoid conflicts
    - The Docker image (jeeves:latest) is shared across all instances
    - Each instance has its own compose file in .tmp/<slug>/

    UID/GID Mapping:
    - On Linux/macOS: Uses $env:UID and $env:GID if available
    - On Windows: Defaults to UID=1000, GID=1000
    - This ensures proper file permissions for mounted volumes
#>

function Write-Log {
    param(
        [string]$message,
        [switch]$info,
        [switch]$trace,
        [switch]$error,
        [switch]$warning,
        [switch]$success,
        [switch]$debug
    )
    $timestamp = ((Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff").toString() + ": ")
    
    # Determine colors based on switches
    $foregroundColor = $null
    if ($error) {
        $foregroundColor = "Red"
    } elseif ($warning) {
        $foregroundColor = "Yellow"
    } elseif ($success) {
        $foregroundColor = "Green"
    } elseif ($info) {
        $foregroundColor = "White"
    } elseif ($trace) {
        $foregroundColor = "Gray"
    } elseif ($debug) {
        $foregroundColor = "Cyan"
    }
    
    Write-Host -ForegroundColor $foregroundColor ($timestamp + $message)
}

function Normalize-Arguments {
    param(
        [string[]]$Arguments
    )

    if (-not $Arguments) {
        return @()
    }

    $helpAliases = @("-h", "-?")

    $normalizedArgs = foreach ($arg in $Arguments) {
        if ($helpAliases -contains $arg) {
            '-Help'
            continue
        }

        if ($arg -match '^--(.+)$') {
            $parts = $Matches[1] -split '[-_]'
            $normalizedName = ($parts | ForEach-Object {
                if ($_.Length -gt 0) {
                    $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
                } else {
                    ""
                }
            }) -join ''

            "-$normalizedName"
        } else {
            $arg
        }
    }

    if ($normalizedArgs.Count -gt 0) {
        $normalizedArgs = @($normalizedArgs)
        for ($index = 0; $index -lt $normalizedArgs.Count; $index++) {
            $normalizedArgs[$index] = [string]$normalizedArgs[$index]
        }

        $firstArg = [string]$normalizedArgs[0]
        if (-not $firstArg.StartsWith('-')) {
            $commandValue = $firstArg
            $remainingArgs = if ($normalizedArgs.Count -gt 1) { $normalizedArgs[1..($normalizedArgs.Count - 1)] } else { @() }
            $normalizedArgs = @('-Command', $commandValue) + $remainingArgs
        }
    }

    return $normalizedArgs
}

function Build-MainParameterHashtable {
    param(
        [string[]]$NormalizedArgs
    )

    $mainParams = @{}
    $i = 0
    while ($i -lt $NormalizedArgs.Count) {
        $token = $NormalizedArgs[$i]
        if ($token -match '^-(.+)$') {
            $paramName = $Matches[1]
            $nextIndex = $i + 1
            $value = $true

            if ($nextIndex -lt $NormalizedArgs.Count -and -not $NormalizedArgs[$nextIndex].StartsWith('-')) {
                $value = $NormalizedArgs[$nextIndex]
                $i++
            }

            $mainParams[$paramName] = $value
        }
        $i++
    }

    return $mainParams
}

$ErrorActionPreference = "Stop"

function Test-DockerDaemon {
    try {
        $null = docker version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Error: Docker daemon is not running or not available." -error
            Write-Log "Please start Docker and try again." -info
            exit 1
        }
    }
    catch {
        Write-Log "Error: Docker is not installed or not in PATH." -error
        Write-Log "Please install Docker and try again." -info
        exit 1
    }
}

function Get-ProjectSlug {
    $currentPath = (Get-Location).Path

    $leafName = Split-Path -Leaf $currentPath

    if (-not $leafName -or $leafName -eq [System.IO.Path]::DirectorySeparatorChar -or $leafName -eq "/" -or $leafName -eq "\") {
        Write-Log "Cannot determine project name from root directory '$currentPath'." -error
        Write-Log "Please run jeeves from within a project directory." -info
        exit 1
    }

    $slug = $leafName.ToLower() -replace '[^a-z0-9]', '-'
    $slug = $slug -replace '-+', '-'
    $slug = $slug.Trim('-')

    if (-not $slug) {
        Write-Log "Cannot derive a valid project slug from directory '$leafName'." -error
        Write-Log "Please run jeeves from a directory with alphanumeric characters in its name." -info
        exit 1
    }

    return $slug
}

function Get-ProjectComposePath {
    $slugDir = Join-Path $PSScriptRoot ".tmp"
    $slugDir = Join-Path $slugDir $Script:PROJECT_SLUG
    return Join-Path $slugDir "docker-compose.yml"
}

function Get-AllJeevesContainers {
    $raw = docker ps -a --filter "label=jeeves.managed=true" --format "{{.Names}}`t{{.Status}}`t{{.Label `"jeeves.project`"}}`t{{.Label `"jeeves.directory`"}}`t{{.Ports}}" 2>$null
    if (-not $raw) {
        return @()
    }

    $containers = @()
    foreach ($line in $raw -split "`n") {
        $line = $line.Trim()
        if (-not $line) { continue }
        $parts = $line -split "`t"
        $containers += @{
            Name      = $parts[0]
            Status    = $parts[1]
            Project   = $parts[2]
            Directory = $parts[3]
            Ports     = $parts[4]
        }
    }

    return $containers
}

function Get-NextAvailablePort {
    param(
        [int]$StartPort = 3333
    )

    $usedPorts = @()
    $allContainers = Get-AllJeevesContainers
    foreach ($container in $allContainers) {
        if ($container.Ports -match '(\d+)->3333') {
            $usedPorts += [int]$Matches[1]
        }
    }

    $port = $StartPort
    while ($usedPorts -contains $port) {
        $port++
        if ($port -gt 65535) {
            Write-Log "No available ports found starting from $StartPort" -error
            exit 1
        }
    }

    return $port
}

function Get-PortFromComposeFile {
    $composePath = Get-ProjectComposePath
    if (-not (Test-Path $composePath)) {
        return $null
    }

    $content = Get-Content $composePath -Raw
    if ($content -match '"(\d+):3333"') {
        return [int]$Matches[1]
    }

    return $null
}

function Test-SlugCollision {
    $allContainers = Get-AllJeevesContainers
    $currentDir = (Get-Location).Path -replace '\\', '/'

    foreach ($container in $allContainers) {
        $containerDir = $container.Directory -replace '\\', '/'
        if ($container.Project -eq $Script:PROJECT_SLUG -and $containerDir -ne $currentDir) {
            Write-Log "Slug collision detected: project slug '$($Script:PROJECT_SLUG)' is already in use by:" -error
            Write-Log "  Container: $($container.Name)" -error
            Write-Log "  Directory: $($container.Directory)" -error
            Write-Log "  Current:   $currentDir" -error
            Write-Log "Two different directories resolve to the same container name." -info
            Write-Log "Rename one of the directories to avoid this conflict." -info
            exit 1
        }
    }
}

$Script:IMAGE_NAME = "jeeves"
$Script:IMAGE_TAG = "latest"
$Script:PROJECT_SLUG = Get-ProjectSlug
$Script:CONTAINER_NAME = "jeeves-$Script:PROJECT_SLUG"
$Script:DOCKERFILE_PATH = Join-Path $PSScriptRoot "Dockerfile.jeeves"
$Script:BUILD_CONTEXT = $PSScriptRoot
$Script:DEFAULT_PORT = 3333
$Script:WORKSPACE_MOUNT = "$(Get-Location):/proj:rw"

<#
.SYNOPSIS
    Retrieves the current user's UID and GID for proper file permissions

.DESCRIPTION
    Gets the UID and GID from environment variables (Linux/macOS) or falls back
    to defaults (Windows). This ensures that files created in the container
    have proper ownership on the host system.

.OUTPUTS
    Hashtable with keys 'UID' and 'GID'

.NOTES
    - Linux/macOS: Uses $env:UID and $env:GID if available
    - Windows: Defaults to UID=1000, GID=1000
    - GID defaults to UID value if not specified
#>

<#
.SYNOPSIS
    Gets user and mount specifications for Docker container

.DESCRIPTION
    Determines the appropriate --user flag and mount specification based on the
    platform and UID/GID availability. Emits --user only when an explicit UID is
    provided and it differs from the Windows default of 1000 to avoid permission
    conflicts when Windows credentials are used.

.OUTPUTS
    Hashtable with keys 'UserFlag' and 'MountSpec'

.NOTES
    - Only adds --user when UID is explicitly supplied and not 1000 (Windows default)
    - Windows default behavior omits --user to prevent permission issues
    - GID defaults to UID when not explicitly provided
    - All platforms: Mounts workspace with explicit rw mode
#>
function Get-UserIds {
    $uid = $env:UID
    $gid = $env:GID

    if (-not $uid) {
        $uid = 1000
    }
    if (-not $gid) {
        $gid = $uid
    }

    return @{ UID = $uid; GID = $gid }
}

function Get-UserHomeDirectory {
    # Cross-platform way to get the user's home directory
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        return $env:USERPROFILE
    } else {
        return $env:HOME
    }
}

function Get-UserMountSpec {
    $ids = Get-UserIds
    $explicitUid = $env:UID
    $userHome = Get-UserHomeDirectory

    # Create config mount specifications
    $configMounts = @(
        "$($userHome)/.claude:/home/jeeves/.claude:rw",
        "$($userHome)/.config/opencode:/home/jeeves/.config/opencode:rw",
        "$($userHome)/.opencode:/home/jeeves/.opencode:rw",
        "$($userHome)/.local/share/opencode:/home/jeeves/.local/share/opencode:rw"
    )

    if ($explicitUid -and $explicitUid -ne "1000") {
        return @{
            UserFlag = "--user `"$($ids.UID):$($ids.GID)`""
            WorkspaceMount = "$(Get-Location):/proj:rw"
            ConfigMounts = $configMounts
        }
    } else {
        return @{
            UserFlag = ""
            WorkspaceMount = "$(Get-Location):/proj:rw"
            ConfigMounts = $configMounts
        }
    }
}

<#
.SYNOPSIS
    Initializes the temporary directory for Docker Compose files

.DESCRIPTION
    Creates the .tmp directory if it doesn't exist and ensures .gitignore
    and .dockerignore files contain the .tmp/ entry to prevent temporary
    files from being committed or included in builds.

.NOTES
    This function is called before generating docker-compose.yml files
    to ensure proper temporary file management.
#>
function Initialize-TemporaryDirectory {
    $tmpBase = Join-Path $PSScriptRoot ".tmp"
    $slugDir = Join-Path $tmpBase $Script:PROJECT_SLUG

    if (-not (Test-Path $slugDir)) {
        New-Item -ItemType Directory -Path $slugDir -Force | Out-Null
        Write-Log "Created .tmp/$($Script:PROJECT_SLUG) directory for compose files" -trace
    }

    $scriptGitignorePath = Join-Path $PSScriptRoot ".gitignore"
    if (Test-Path $scriptGitignorePath) {
        $gitignoreContent = Get-Content $scriptGitignorePath
        if ($gitignoreContent -notcontains ".tmp/") {
            Add-Content -Path $scriptGitignorePath -Value "`n.tmp/" -Encoding UTF8
            Write-Log "Added .tmp/ to script .gitignore" -trace
        }
    }

    $scriptDockerignorePath = Join-Path $PSScriptRoot ".dockerignore"
    if (Test-Path $scriptDockerignorePath) {
        $dockerignoreContent = Get-Content $scriptDockerignorePath
        if ($dockerignoreContent -notcontains ".tmp/") {
            Add-Content -Path $scriptDockerignorePath -Value "`n.tmp/" -Encoding UTF8
            Write-Log "Added .tmp/ to script .dockerignore" -trace
        }
    }
}

<#
.SYNOPSIS
    Generates Docker Compose configuration file

.DESCRIPTION
    Creates a docker-compose.yml file in the .tmp directory with resolved paths,
    proper service dependencies. Preserves all existing
    dynamic path resolution logic from Get-UserMountSpec().

.NOTES
    Generated file includes jeeves services with proper networking,
    health checks, and resource limits as specified in the PRD.
#>
function New-DockerComposeFile {
    param(
        [switch]$Dind,
        [int]$Port = 0,
        [string]$ExtraPorts = ""
    )

    if ($Port -eq 0) {
        $Port = $Script:DEFAULT_PORT
    }

    $mountSpec = Get-UserMountSpec
    $currentDir = (Get-Location).Path
    $networkName = "jeeves-$($Script:PROJECT_SLUG)-network"

    $composeContent = @"
services:
  jeeves:
    build:
      context: ../..
      dockerfile: Dockerfile.jeeves
    image: jeeves:latest
    container_name: $($Script:CONTAINER_NAME)
    runtime: nvidia
    shm_size: "2gb"
    gpus: all
    labels:
      - "jeeves.managed=true"
      - "jeeves.project=$($Script:PROJECT_SLUG)"
      - "jeeves.directory=$($currentDir -replace '\\', '/')"
    environment:
      - NVIDIA_DRIVER_CAPABILITIES=all
      - CUDA_VISIBLE_DEVICES=all
      - PLAYWRIGHT_MCP_HEADLESS=1
      - PLAYWRIGHT_MCP_BROWSER=chromium
      - PLAYWRIGHT_MCP_NO_SANDBOX=1
      - PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1
      - OPENCODE_ENABLE_EXA=false
"@

    if ($Dind) {
        $composeContent += "`n      - ENABLE_DIND=true"
    }

    try {
        $gitName = git config --global user.name
        $gitEmail = git config --global user.email
        if ($gitName) {
            $composeContent += "`n      - GIT_AUTHOR_NAME=$gitName"
        }
        if ($gitEmail) {
            $composeContent += "`n      - GIT_AUTHOR_EMAIL=$gitEmail"
        }
    } catch {
        Write-Log "Warning: Could not read host git config" -warning
    }

    $composeContent += "`n    volumes:`n      - $($mountSpec.WorkspaceMount)`n"

    foreach ($configMount in $mountSpec.ConfigMounts) {
        $composeContent += "      - $configMount`n"
    }

    if ($mountSpec.UserFlag) {
        $userSpec = $mountSpec.UserFlag -replace '--user ', ''
        $composeContent += "    user: $userSpec`n"
    }

    if ($Dind) {
        $composeContent += "    privileged: true`n"
    }

    $composeContent += "    ports:`n"
    $composeContent += "      - `"$($Port):3333`"`n"

    if ($ExtraPorts) {
        $mappings = $ExtraPorts -split ','
        foreach ($mapping in $mappings) {
            $mapping = $mapping.Trim()
            if ($mapping) {
                $composeContent += "      - `"$mapping`"`n"
            }
        }
    }

    $composeContent += @"
    networks:
      - $networkName

networks:
  $($networkName):
    driver: bridge
"@

    $composeFile = Get-ProjectComposePath
    $composeContent | Out-File -FilePath $composeFile -Encoding UTF8
    Write-Log "Generated docker-compose.yml: $composeFile" -trace

    return $composeFile
}

<#
.SYNOPSIS
    Validates that the Dockerfile exists

.DESCRIPTION
    Checks if the Dockerfile exists at the configured path. Exits with error
    if the file is not found.

.OUTPUTS
    Boolean true if Dockerfile exists
#>
function Test-Dockerfile {
    if (-not (Test-Path $Script:DOCKERFILE_PATH)) {
        Write-Error "Dockerfile not found at: $Script:DOCKERFILE_PATH"
        exit 1
    }
    return $true
}

<#
.SYNOPSIS
    Builds the Docker image

.DESCRIPTION
    Constructs and executes a Docker build command with appropriate build arguments.
    Supports building with or without cache, and optionally includes desktop binaries.

.PARAMETER NoCache
    If specified, builds without using Docker's layer cache

    .PARAMETER Desktop
    If specified, sets BUILD_DESKTOP=true to include desktop binary builds

    .PARAMETER InstallClaudeCode
    If specified, sets INSTALL_CLAUDE_CODE=true to install Claude Code in the container

    .PARAMETER Clean
    If specified, performs a clean build by removing existing containers and images first

.EXAMPLE
    Build-Image

.EXAMPLE
    Build-Image -NoCache

.EXAMPLE
    Build-Image -Desktop

.EXAMPLE
    Build-Image -Clean
#>
function Build-Image {
    param(
        [switch]$NoCache,
        [switch]$Desktop,
        [switch]$InstallClaudeCode,
        [switch]$Clean
    )

    Write-Log "Building Docker image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" -debug
    Test-Dockerfile

    if ($Clean) {
        Ensure-ContainerStopped
    }

    # Initialize buildArgs array with base command and mandatory flags
    $buildArgs = @(
        "build"
    )

    # Add optional flags only when they contain data
    if ($NoCache -or $Clean) {
        $buildArgs += "--no-cache"
        if ($Clean) {
            Write-Log "Performing clean build (stopping container, no cache)..." -warning
        } else {
            Write-Log "Performing clean build (no cache)..." -warning
        }
    }

    if ($Desktop) {
        Write-Log "Building with desktop support..." -warning
        $buildArgs += "--build-arg", "BUILD_DESKTOP=true"
    }

    if ($InstallClaudeCode) {
        Write-Log "Installing Claude Code in container..." -warning
        $buildArgs += "--build-arg", "INSTALL_CLAUDE_CODE=true"
    }

    # Add remaining mandatory flags
    $buildArgs += "-f"
	$buildArgs += "$Script:DOCKERFILE_PATH"
    
	$buildArgs += "-t"
	$buildArgs += "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    
	$buildArgs += "$Script:BUILD_CONTEXT"

	Write-Log -trace "Dockerfile path: $Script:DOCKERFILE_PATH"
    Write-Log -trace "Build Context: $Script:BUILD_CONTEXT"
    Write-Log -trace "Final Arguments: $($buildArgs -join ' ')"

    # 5. Execute using the Call Operator (&) and splatting (@)
    & docker @buildArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Image built successfully" -success
    }
}

<#
.SYNOPSIS
    Gets the container ID if it's running

.DESCRIPTION
    Queries Docker for a container with the configured name that is currently running.

.OUTPUTS
    String containing the container ID, or $null if not running
#>
function Get-ContainerId {
    $composeFile = Get-ProjectComposePath
    if (Test-Path $composeFile) {
        $composePs = & docker compose -f $composeFile ps -q jeeves 2>$null
        if ($composePs) {
            return $composePs.Trim()
        }
        return $null
    } else {
        $containerId = docker ps -q -f "name=^${Script:CONTAINER_NAME}$"
        if (-not $containerId) {
            return $null
        }
        return $containerId
    }
}

<#
.SYNOPSIS
    Docker helper utilities
.DESCRIPTION
    Inspect image/container state and perform prerequisite actions before executing commands.
#>
function Get-ImageId {
    $imageId = docker images -q "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    if (-not $imageId) {
        return $null
    }

    return $imageId.Trim()
}

function Ensure-ImageExists {
    param(
        [switch]$ForceRebuild,
        [switch]$NoCache,
        [switch]$Desktop,
        [switch]$InstallClaudeCode
    )

    if ($ForceRebuild) {
        Write-Log "Force rebuild requested for ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" -warning
        Remove-Image
    }

    $imageId = Get-ImageId
    if ($imageId) {
        Write-Log "Image ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} already exists (ID: $imageId)" -trace
        return $imageId
    }

    Write-Log "Image ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} not found; building now..." -debug
    Build-Image -NoCache:$NoCache -Desktop:$Desktop -InstallClaudeCode:$InstallClaudeCode

    return Get-ImageId
}

function Ensure-ContainerStopped {
    param([switch]$Force)

    $containerId = Get-ContainerId
    if (-not $containerId) {
        Write-Log "Container '${Script:CONTAINER_NAME}' is not running" -trace
        return
    }

    Write-Log "Stopping container: ${Script:CONTAINER_NAME}" -debug
    
    # Initialize stopArgs array with base command and mandatory flags
    $stopArgs = @(
        $containerId
    )

    # Use if statements to handle the Force parameter
    if ($Force) {
        $stopArgs = @("kill") + $stopArgs
        Write-Log "Force stopping container..." -debug
    } else {
        $stopArgs = @("stop") + $stopArgs
        Write-Log "Gracefully stopping container..." -debug
    }

    # Execute the command using splatting operator
    docker @stopArgs

    if ($LASTEXITCODE -eq 0) {
        if ($Force) {
            Write-Log "Container force stopped" -success
        } else {
            Write-Log "Container stopped" -success
        }
    }
}

function Ensure-ContainerNotPresent {
    param(
        [switch]$Force,
        [switch]$SkipStop
    )

    $composeFile = Get-ProjectComposePath
    if (Test-Path $composeFile) {
        if (-not $SkipStop) {
            Write-Log "Removing services for '${Script:CONTAINER_NAME}' using Docker Compose..." -debug
            & docker compose -f $composeFile down -v --remove-orphans
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Services removed for '${Script:CONTAINER_NAME}'" -success
            }
        }
    } else {
        if (-not $SkipStop) {
            Ensure-ContainerStopped -Force:$Force
        } else {
            $runningContainer = Get-ContainerId
            if ($runningContainer) {
                Write-Log "Container '${Script:CONTAINER_NAME}' is running; cannot remove it while active" -error
                return
            }
        }

        $allContainers = docker ps -a -q -f "name=^${Script:CONTAINER_NAME}$"
        if (-not $allContainers) {
            Write-Log "No container instances found for '${Script:CONTAINER_NAME}'" -trace
            return
        }

        Write-Log "Removing container: ${Script:CONTAINER_NAME}" -debug

        $rmArgs = @("rm")
        if ($allContainers) {
            $rmArgs += $allContainers
        }

        docker @rmArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Container removed" -success
        }
    }
}

function Ensure-ContainerRunning {
    param(
        [switch]$AutoStart = $true,
        [switch]$ForceRebuild,
        [switch]$NoCache,
        [switch]$InstallClaudeCode
    )

    Ensure-ImageExists -ForceRebuild:$ForceRebuild -NoCache:$NoCache -InstallClaudeCode:$InstallClaudeCode

    $containerId = Get-ContainerId
    if ($containerId) {
        return $containerId
    }

    if (-not $AutoStart) {
        Write-Log "Services are not running. Start them with: jeeves start" -error
        return $null
    }

    Start-Container

    $containerId = Get-ContainerId
    if (-not $containerId) {
        Write-Log "Failed to start services" -error
        exit 1
    }

    return $containerId
}

<#
.SYNOPSIS
    Starts the Jeeves container

.DESCRIPTION
    Starts a new container instance with volume mounting from the current directory.
    Ensures prerequisites (image exists, stale containers removed) before launching.
    Clean starts rebuild the image from scratch without using Docker's cache.

.PARAMETER Clean
    If specified, performs a clean start by stopping/removing containers and images,
    rebuilding without cache, and then starting the container.

.NOTES
    - Clean start removes any existing container and the image before rebuilding.
    - Clean start rebuilds the image without Docker cache to guarantee a fresh build.
    - Maps current directory to /proj in the container
    - Exposes port 3333 for the OpenCode Web UI
    - Container runs in detached mode (-d flag)
#>
function Start-Container {
    param(
        [switch]$Clean,
        [switch]$Dind,
        [int]$Port = 0,
        [string]$ExtraPorts = ""
    )

    if ($Clean) {
        Write-Log "Clean start requested for '${Script:CONTAINER_NAME}'..." -warning
        Ensure-ContainerNotPresent -Force
        Remove-Image
        Build-Image -NoCache -Clean
    } else {
        Ensure-ImageExists
    }

    Test-SlugCollision

    $existingContainer = Get-ContainerId
    if ($existingContainer) {
        Write-Log "Container '${Script:CONTAINER_NAME}' is already running" -warning
        return
    }

    Ensure-ContainerNotPresent -SkipStop

    if ($Port -eq 0) {
        $existingPort = Get-PortFromComposeFile
        if ($existingPort) {
            $Port = $existingPort
        } else {
            $Port = Get-NextAvailablePort
        }
    }

    Write-Log "Starting '${Script:CONTAINER_NAME}' on port $Port..." -debug

    Initialize-TemporaryDirectory

    $composeFile = New-DockerComposeFile -Dind:$Dind -Port $Port -ExtraPorts $ExtraPorts

    & docker compose -f $composeFile up -d

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to start services for '${Script:CONTAINER_NAME}'" -error
        exit 1
    }

    Write-Log "Container '${Script:CONTAINER_NAME}' started successfully" -success
    Write-Log "Access the web UI at: http://localhost:$Port" -info
}

<#
.SYNOPSIS
    Stops the container if running

.DESCRIPTION
    Gracefully stops the container using SIGTERM, or forcefully using SIGKILL.
    Handles non-running containers gracefully. Optionally removes the container
    after stopping.

.PARAMETER Force
    If specified, uses docker kill (SIGKILL) instead of docker stop (SIGTERM)

.PARAMETER Remove
    If specified, removes the container after stopping

.EXAMPLE
    Stop-Container

.EXAMPLE
    Stop-Container -Force -Remove
#>
function Stop-Container {
    param(
        [switch]$Force,
        [switch]$Remove
    )

    $containerId = Get-ContainerId
    if (-not $containerId) {
        Write-Log "Container '${Script:CONTAINER_NAME}' is not running" -warning
        return
    }

    $composeFile = Get-ProjectComposePath
    if (Test-Path $composeFile) {
        Write-Log "Stopping '${Script:CONTAINER_NAME}' using Docker Compose..." -debug
        & docker compose -f $composeFile down

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Container '${Script:CONTAINER_NAME}' stopped" -success
        } else {
            Write-Log "Failed to stop via Docker Compose, falling back to Docker" -warning
            Ensure-ContainerStopped -Force:$Force
        }
    } else {
        Ensure-ContainerStopped -Force:$Force
    }

    if ($Remove) {
        Ensure-ContainerNotPresent -SkipStop -Force:$Force
    }
}

<#
.SYNOPSIS
    Restarts the container without recreating it

.DESCRIPTION
    Restarts the container using docker compose restart (or docker restart for legacy),
    which preserves container state. If the container is not running, it will be started.
    Ensures the image exists before attempting to restart.

.PARAMETER Dind
    If specified, ensures the container is started with Docker-in-Docker support

.PARAMETER NoCache
    If specified and image needs to be built, builds without cache

.PARAMETER Desktop
    If specified and image needs to be built, builds with desktop support

.PARAMETER InstallClaudeCode
    If specified and image needs to be built, installs Claude Code

.EXAMPLE
    Restart-Container

.EXAMPLE
    Restart-Container -Dind
#>
function Restart-Container {
    param(
        [switch]$Dind,
        [switch]$NoCache,
        [switch]$Desktop,
        [switch]$InstallClaudeCode,
        [int]$Port = 0,
        [string]$ExtraPorts = ""
    )

    Ensure-ImageExists -NoCache:$NoCache -Desktop:$Desktop -InstallClaudeCode:$InstallClaudeCode

    $containerId = Get-ContainerId
    $composeFile = Get-ProjectComposePath
    $usingCompose = Test-Path $composeFile

    if ($containerId) {
        Write-Log "Restarting container '${Script:CONTAINER_NAME}'..." -debug

        if ($usingCompose) {
            & docker compose -f $composeFile restart jeeves

            if ($LASTEXITCODE -eq 0) {
                Write-Log "Container '${Script:CONTAINER_NAME}' restarted successfully" -success
            } else {
                Write-Log "Failed to restart via docker compose, falling back to docker restart" -warning
                docker restart $containerId
            }
        } else {
            docker restart $containerId

            if ($LASTEXITCODE -eq 0) {
                Write-Log "Container '${Script:CONTAINER_NAME}' restarted successfully" -success
            }
        }
    } else {
        Write-Log "Container '${Script:CONTAINER_NAME}' is not running, starting it..." -warning
        Start-Container -Dind:$Dind -Port $Port -ExtraPorts $ExtraPorts
    }
}

<#
.SYNOPSIS
    Removes the container

.DESCRIPTION
    Ensures the container is stopped and removed before performing destructive cleanup.

.NOTES
    This operation is destructive. The container state will be lost.
#>
function Remove-Container {
    Ensure-ContainerNotPresent -Force
}

<#
.SYNOPSIS
    Attaches to the container shell

.DESCRIPTION
    Opens an interactive bash shell inside the running container.
    The container will be automatically started if needed.

.EXCEPTION
    Exits with error if container cannot be started

.NOTES
    Uses `docker exec -it` for an interactive TTY session
#>
function Enter-Shell {
    param([switch]$New, [switch]$Raw, [switch]$Zsh)

    if ($New) {
        Write-Log "--new flag set: stopping and removing existing container..." -warning
        Ensure-ContainerNotPresent -Force
    }

    $rawContainerOutput = @(Ensure-ContainerRunning)
    $containerId = $rawContainerOutput |
        ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ -match '^[0-9a-f]{12,64}$' } |
        Select-Object -Last 1

    if (-not $containerId) {
        $containerId = $rawContainerOutput |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { $_ } |
            Select-Object -Last 1
    }

    if (-not $containerId) {
        Write-Log "Unable to determine running container ID." -error
        exit 1
    }

    Write-Log "Attaching to container shell for container $containerId ..." -debug
    
    # Initialize execArgs array with base command and mandatory flags
    $execArgs = @(
        "exec"
        "-it"
    )
    
    if ($Raw) {
        $execArgs += "-e"
        $execArgs += "DISABLE_TMUX=1"
    }
    
    $execArgs += $containerId
    
    if ($Zsh) {
        $execArgs += "/bin/zsh"
    } else {
        $execArgs += "/bin/bash"
    }
    
    # Execute the command using splatting operator
    & docker @execArgs
}

<#
.SYNOPSIS
    Displays and follows container logs

.DESCRIPTION
    Shows the container's stdout/stderr logs and follows new output in real-time.
    Ensures prerequisites are met but does not auto start the container.

.EXCEPTION
    Exits with error if container is not running

.NOTES
    Uses `docker logs -f` for continuous log following
    Press Ctrl+C to exit log viewing
#>
function Show-Logs {
    $composeFile = Get-ProjectComposePath
    if (Test-Path $composeFile) {
        Write-Log "Showing logs for '${Script:CONTAINER_NAME}'..." -debug
        & docker compose -f $composeFile logs -f
    } else {
        $containerId = Get-ContainerId
        if (-not $containerId) {
            Write-Log "Container '${Script:CONTAINER_NAME}' is not running. Start it with: jeeves start" -error
            exit 1
        }

        $logsArgs = @(
            "logs"
            "-f"
            $containerId
        )

        docker @logsArgs
    }
}

<#
.SYNOPSIS
    Displays container and image status

.DESCRIPTION
    Shows the current state of the container (running, stopped, or not created)
    and whether the Docker image exists.

.OUTPUTS
    Formatted status information to the console
#>
function Show-Status {
    param([switch]$All)

    if ($All) {
        Show-ListAll
        return
    }

    Write-Log "=== Jeeves Status: ${Script:CONTAINER_NAME} ===" -debug

    $composeFile = Get-ProjectComposePath
    if (Test-Path $composeFile) {
        & docker compose -f $composeFile ps

        $port = Get-PortFromComposeFile
        if ($port) {
            Write-Log "" -info
            Write-Log "Web UI: http://localhost:$port" -trace
        }
    } else {
        $containerId = Get-ContainerId
        if ($containerId) {
            Write-Log "Status: Running" -success
            Write-Log "Container ID: $containerId" -trace
        } else {
            $psArgs = @(
                "ps"
                "-a"
                "-q"
                "-f", "name=^${Script:CONTAINER_NAME}$"
            )

            $stoppedContainer = docker @psArgs
            if ($stoppedContainer) {
                Write-Log "Status: Stopped" -info
            } else {
                Write-Log "Status: Not created" -info
            }
        }
    }

    $imageExists = docker images -q "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    if ($imageExists) {
        Write-Log "Image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} (exists)" -trace
    } else {
        Write-Log "Image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} (not found)" -error
    }
}

function Show-ListAll {
    Write-Log "=== All Jeeves Instances ===" -debug

    $allContainers = Get-AllJeevesContainers

    if ($allContainers.Count -eq 0) {
        Write-Log "No jeeves containers found" -info
        return
    }

    $headerFormat = "{0,-20} {1,-25} {2,-8} {3,-15} {4}"
    Write-Host ($headerFormat -f "PROJECT", "CONTAINER", "PORT", "STATUS", "DIRECTORY") -ForegroundColor Cyan
    Write-Host ($headerFormat -f "-------", "---------", "----", "------", "---------") -ForegroundColor Gray

    foreach ($container in $allContainers) {
        $port = "-"
        if ($container.Ports -match '(\d+)->3333') {
            $port = $Matches[1]
        }

        $statusShort = if ($container.Status -match '(Up|Exited|Created)') { $Matches[1] } else { $container.Status }

        $color = if ($statusShort -eq "Up") { "Green" } elseif ($statusShort -eq "Exited") { "Yellow" } else { "Gray" }

        Write-Host ($headerFormat -f $container.Project, $container.Name, $port, $statusShort, $container.Directory) -ForegroundColor $color
    }

    $imageExists = docker images -q "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    Write-Host ""
    if ($imageExists) {
        Write-Log "Image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} (exists)" -trace
    } else {
        Write-Log "Image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG} (not found)" -error
    }
}

<#
.SYNOPSIS
    Removes the Docker image

.DESCRIPTION
    Deletes the Jeeves Docker image from the local Docker registry.
    The container will be stopped and removed first if present.

.NOTES
    This operation is destructive. The image will need to be rebuilt.
#>
function Remove-Image {
    param([switch]$Force)

    Write-Log "Removing image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" -debug

    $imageExists = docker images -q "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    if (-not $imageExists) {
        Write-Log "Image not found" -warning
        return
    }

    $allContainers = Get-AllJeevesContainers
    $otherContainers = @($allContainers | Where-Object { $_.Project -ne $Script:PROJECT_SLUG })

    if ($otherContainers.Count -gt 0 -and -not $Force) {
        Write-Log "Cannot remove shared image: other jeeves containers exist:" -error
        foreach ($c in $otherContainers) {
            Write-Log "  $($c.Name) ($($c.Status)) - $($c.Directory)" -warning
        }
        Write-Log "Stop/remove those containers first, or use --force to remove anyway." -info
        return
    }

    Ensure-ContainerNotPresent -Force

    $rmiArgs = @(
        "rmi"
        "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    )

    docker @rmiArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Image removed" -success
    }
}

function Remove-AllContainers {
    $allContainers = Get-AllJeevesContainers
    if ($allContainers.Count -eq 0) {
        Write-Log "No jeeves containers found" -info
        return
    }

    foreach ($container in $allContainers) {
        Write-Log "Removing container: $($container.Name)..." -debug
        docker rm -f $container.Name 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Removed $($container.Name)" -success
        }

        $slugDir = Join-Path $PSScriptRoot ".tmp"
        $slugDir = Join-Path $slugDir $container.Project
        $composeInDir = Join-Path $slugDir "docker-compose.yml"
        if (Test-Path $composeInDir) {
            & docker compose -f $composeInDir down -v --remove-orphans 2>$null
        }
    }
}

<#
.SYNOPSIS
    Displays general help information

.DESCRIPTION
    Shows a summary of all available commands, options, and examples.
#>
function Show-Help {
    Write-Host @"
Jeeves - OpenCode Container Management Helper

Usage: jeeves <command> [options]

  Jeeves supports multiple concurrent containers, one per project directory.
  Container names are derived from the current directory (e.g., jeeves-myproject).
  Ports are auto-assigned starting from 3333.

Commands:
  build     Build the Docker image (shared across all instances)
  start     Start the container for the current directory
  stop      Stop the container for the current directory
  restart   Restart the container for the current directory
  rm        Remove the container for the current directory
  shell     Attach to the container shell (builds and starts if needed)
  logs      Show container logs for the current directory
  status    Show status for the current directory's container
  list      List all running jeeves instances
  clean     Remove container (and optionally image)

Options:
  --help                Show detailed help for a command
  --no-cache            Build without using cache (build command)
  --desktop             Build desktop binaries (build command)
  --install-claude-code Install Claude Code in container (build command)
  --clean               Clean start: rebuild everything (start command)
  --port <n>            Use specific host port (start command)
  --ports <mappings>    Extra port mappings, e.g. 3000:3000,8080:8080 (start command)
  --remove              Also remove container (stop command)
  --force               Force stop container (stop command)
  --new                 Stop and remove container before shell (shell command)
  --zsh                 Use zsh shell instead of bash (shell command)
  --dind                Enable Docker-in-Docker support (start command)
  --all                 Operate on all instances (clean, status)
  --image               Also remove shared Docker image (clean command)

Aliases:
  b -> build
  up -> start
  down -> stop
  attach, sh -> shell
  st -> status
  ls, ps -> list

Examples:
  jeeves build                           # Build the image
  jeeves start                           # Start (auto-assign port)
  jeeves start --port 3334               # Start on specific port
  jeeves start --ports 3000:3000         # Start with extra port mappings
  jeeves start --clean                   # Clean rebuild and start
  jeeves shell                           # Enter the container
  jeeves list                            # Show all running instances
  jeeves stop                            # Stop this project's container
  jeeves clean                           # Remove this project's container
  jeeves clean --image                   # Remove container + shared image
  jeeves clean --all                     # Remove all jeeves containers
  jeeves status --all                    # Show all instances

For detailed help on a specific command, use: jeeves <command> --help
"@ -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Displays detailed help for a specific command

.DESCRIPTION
    Shows comprehensive help information including description, usage,
    options, and examples for the specified command.

.PARAMETER CommandName
    The command to show help for

.EXAMPLE
    Show-CommandHelp "build"
#>
function Show-CommandHelp {
    param([string]$CommandName)

    $helpText = switch ($CommandName) {
        "build" {
@"
Jeeves build - Build the Docker Image

DESCRIPTION:
    Builds the jeeves Docker image. The image is shared across all
    jeeves container instances. Includes OpenCode CLI, TUI, Web UI
    tools along with CUDA support and development dependencies.

USAGE:
    jeeves build [options]

OPTIONS:
    --no-cache            Build without Docker's layer cache
    --desktop             Build desktop binaries (Linux, Windows)
    --install-claude-code Install Claude Code in the container
    --help                Show this help message

EXAMPLES:
    jeeves build
    jeeves build --no-cache
    jeeves build --desktop
    jeeves build --no-cache --desktop --install-claude-code

NOTES:
    - Image is tagged as jeeves:latest and shared by all instances
    - Desktop builds can take 30+ minutes
    - Running containers are stopped before rebuilding
"@
        }
        "start" {
@"
Jeeves start - Start the Container

DESCRIPTION:
    Starts a jeeves container for the current working directory, mounted
    to /proj inside the container. The container is named based on the
    current directory (e.g., jeeves-myproject). Ports are auto-assigned
    starting from 3333.

USAGE:
    jeeves start [options]

OPTIONS:
    --clean               Clean start: stop, remove, rebuild, then start
    --dind                Enable Docker-in-Docker (DinD) support
    --port <n>            Use a specific host port instead of auto-assign
    --ports <mappings>    Extra port mappings (e.g., 3000:3000,8080:8080)
    --help                Show this help message

EXAMPLES:
    jeeves start
    jeeves start --port 3334
    jeeves start --ports 3000:3000,8080:8080
    jeeves start --clean
    jeeves start --dind

NOTES:
    - Container name: jeeves-<folder-name>
    - Port auto-increments from 3333 if already in use
    - Current directory (pwd) is mounted to /proj
    - Multiple instances can run concurrently from different directories
    - Web UI available at: http://localhost:<assigned-port>
"@
        }
        "stop" {
@"
Jeeves stop - Stop the Container

DESCRIPTION:
    Stops the jeeves container for the current directory. Only affects
    the container associated with this directory.

USAGE:
    jeeves stop [options]

OPTIONS:
    --remove     Remove the container after stopping
    --force      Force stop using SIGKILL
    --help       Show this help message

EXAMPLES:
    jeeves stop
    jeeves stop --remove
    jeeves stop --force
    jeeves stop --force --remove

NOTES:
    - Only stops this project's container (jeeves-<folder-name>)
    - Other running jeeves instances are not affected
    - Default: Graceful shutdown with docker stop
"@
        }
        "restart" {
@"
Jeeves restart - Restart the Container

DESCRIPTION:
    Restarts the container for the current directory using docker compose
    restart, preserving container state. If not running, starts it.

USAGE:
    jeeves restart [options]

OPTIONS:
    --dind                Enable Docker-in-Docker support
    --port <n>            Use specific port (only when starting fresh)
    --ports <mappings>    Extra port mappings (only when starting fresh)
    --no-cache            Build without cache (if image needs building)
    --desktop             Build desktop binaries (if image needs building)
    --install-claude-code Install Claude Code (if image needs building)
    --help                Show this help message

EXAMPLES:
    jeeves restart
    jeeves restart --dind

NOTES:
    - Uses docker compose restart (faster, preserves state)
    - If not running, starts container normally
    - Port/extra ports only apply when starting from scratch
"@
        }
        "rm" {
@"
Jeeves rm - Remove the Container

DESCRIPTION:
    Removes the jeeves container for the current directory. Stops the
    container first if running. The shared Docker image is not removed.

USAGE:
    jeeves rm

EXAMPLES:
    jeeves rm

NOTES:
    - Only removes this project's container
    - Docker image is NOT removed (use 'clean --image')
    - Other running instances are not affected
"@
        }
        "shell" {
@"
Jeeves shell - Attach to Container Shell

DESCRIPTION:
    Opens an interactive shell inside the running container for the
    current directory. Builds and starts the container if needed.

USAGE:
    jeeves shell [options]

OPTIONS:
    --new        Stop and remove container before entering (fresh start)
    --zsh        Use zsh shell instead of bash
    --raw        Disable tmux auto-attach
    --help       Show this help message

EXAMPLES:
    jeeves shell
    jeeves shell --new
    jeeves shell --zsh

NOTES:
    - Your current directory is available at /proj
    - Type 'exit' to leave the shell
    - Tmux auto-attaches for persistent sessions
    - Use Shift/Option key to interact outside tmux
"@
        }
        "logs" {
@"
Jeeves logs - View Container Logs

DESCRIPTION:
    Displays logs for the current directory's container and follows
    new output in real-time.

USAGE:
    jeeves logs

EXAMPLES:
    jeeves logs

NOTES:
    - Container must be running
    - Shows logs for this project's container only
    - Press Ctrl+C to exit log viewer
"@
        }
        "status" {
@"
Jeeves status - Show Container Status

DESCRIPTION:
    Displays the current state of this project's container. Use --all
    to show all running jeeves instances (same as 'jeeves list').

USAGE:
    jeeves status [options]

OPTIONS:
    --all        Show all jeeves instances instead of just this project

EXAMPLES:
    jeeves status
    jeeves status --all

NOTES:
    - Shows container status for current directory
    - Shows assigned port and Web UI URL
    - Use 'jeeves list' for a quick view of all instances
"@
        }
        "list" {
@"
Jeeves list - List All Jeeves Instances

DESCRIPTION:
    Shows all running and stopped jeeves containers across all projects.
    Displays project name, container name, port, status, and source
    directory for each instance.

USAGE:
    jeeves list

ALIASES:
    jeeves ls
    jeeves ps

EXAMPLES:
    jeeves list

NOTES:
    - Shows all containers with the jeeves.managed label
    - Useful for finding which ports are in use
    - Useful for identifying containers before running 'clean --all'
"@
        }
        "clean" {
@"
Jeeves clean - Remove Container and Optionally Image

DESCRIPTION:
    Removes the container for the current directory. Optionally removes
    all jeeves containers and/or the shared Docker image.

USAGE:
    jeeves clean [options]

OPTIONS:
    --image      Also remove the shared Docker image
    --all        Remove ALL jeeves containers (not just this project)
    --force      Force image removal even if other containers exist
    --help       Show this help message

EXAMPLES:
    jeeves clean                   # Remove this project's container
    jeeves clean --image           # Remove container + shared image
    jeeves clean --all             # Remove all jeeves containers
    jeeves clean --all --image     # Remove everything

NOTES:
    - Default: only removes this project's container
    - Image removal warns if other containers still exist
    - Use --force to override image removal safety check
    - Destructive operation - cannot be undone
"@
        }
        default {
            "No detailed help available for command: $CommandName"
        }
    }

    Write-Host $helpText
}

<#
.SYNOPSIS
    Displays an interactive menu for command selection

.DESCRIPTION
    Presents a numbered menu of available commands when no arguments are
    provided. The user can select an option by number, letter, or keyword.

.NOTES
    Menu includes options for all commands plus help and abort
#>
function Show-Menu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                Jeeves - Claude/OpenCode Helper                ║
║                   Container Management Menu                   ║
║              Project: $($Script:PROJECT_SLUG.PadRight(40))║
╚═══════════════════════════════════════════════════════════════╝

Select an option:
"@

    $menuOptions = @(
        @{ Key = "1"; Label = "Build image (with options)"; Action = "build-menu" }
        @{ Key = "2"; Label = "Start container (with options)"; Action = "start-menu" }
        @{ Key = "3"; Label = "Stop container (with options)"; Action = "stop-menu" }
        @{ Key = "4"; Label = "Restart container"; Action = "restart" }
        @{ Key = "5"; Label = "Remove container"; Action = "rm" }
        @{ Key = "6"; Label = "Attach to shell (with options)"; Action = "shell-menu" }
        @{ Key = "7"; Label = "View logs"; Action = "logs" }
        @{ Key = "8"; Label = "Show status (this project)"; Action = "status" }
        @{ Key = "9"; Label = "List all running instances"; Action = "list" }
        @{ Key = "C"; Label = "Clean (with options)"; Action = "clean-menu" }
        @{ Key = "H"; Label = "Help"; Action = "help" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $menuOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $menuOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "help") {
            Show-Help
            Read-Host "`nPress Enter to continue"
            Show-Menu
        } elseif ($matchedOption.Action -eq "build-menu") {
            Show-BuildMenu
        } elseif ($matchedOption.Action -eq "start-menu") {
            Show-StartMenu
        } elseif ($matchedOption.Action -eq "stop-menu") {
            Show-StopMenu
        } elseif ($matchedOption.Action -eq "shell-menu") {
            Show-ShellMenu
        } elseif ($matchedOption.Action -eq "clean-menu") {
            Show-CleanMenu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-Menu
    }
}

function Show-BuildMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                Jeeves - Build Image Options                   ║
╚═══════════════════════════════════════════════════════════════╝

Select build options:
"@

    $buildOptions = @(
        @{ Key = "1"; Label = "Default build"; Action = "build" }
        @{ Key = "2"; Label = "Build without cache"; Action = "build-nocache" }
        @{ Key = "3"; Label = "Build with desktop support"; Action = "build-desktop" }
        @{ Key = "4"; Label = "Build with Claude Code"; Action = "build-claude" }
        @{ Key = "5"; Label = "Build without cache + desktop"; Action = "build-nocache-desktop" }
        @{ Key = "6"; Label = "Build without cache + Claude Code"; Action = "build-nocache-claude" }
        @{ Key = "7"; Label = "Build with desktop + Claude Code"; Action = "build-desktop-claude" }
        @{ Key = "8"; Label = "Build without cache + desktop + Claude Code"; Action = "build-all" }
        @{ Key = "B"; Label = "Back to main menu"; Action = "back" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $buildOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $buildOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "back") {
            Show-Menu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-BuildMenu
    }
}

function Show-StartMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║              Jeeves - Start Container Options                  ║
║              Project: $($Script:PROJECT_SLUG.PadRight(40))║
╚═══════════════════════════════════════════════════════════════╝

Select start options:
"@

    $startOptions = @(
        @{ Key = "1"; Label = "Start (auto-assign port)"; Action = "start" }
        @{ Key = "2"; Label = "Start with DinD"; Action = "start-dind" }
        @{ Key = "3"; Label = "Start with custom port"; Action = "start-custom-port" }
        @{ Key = "4"; Label = "Start with extra port mappings"; Action = "start-extra-ports" }
        @{ Key = "5"; Label = "Clean start (rebuild & start)"; Action = "start-clean" }
        @{ Key = "6"; Label = "Clean start with DinD"; Action = "start-clean-dind" }
        @{ Key = "B"; Label = "Back to main menu"; Action = "back" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $startOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $startOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "back") {
            Show-Menu
        } elseif ($matchedOption.Action -eq "start-custom-port") {
            $portInput = Read-Host "Enter port number (default: 3333)"
            if (-not $portInput) { $portInput = "3333" }
            $Script:MenuPort = [int]$portInput
            return "start-port"
        } elseif ($matchedOption.Action -eq "start-extra-ports") {
            return Show-ExtraPortsMenu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-StartMenu
    }
}

function Show-ExtraPortsMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║              Jeeves - Extra Port Mappings                      ║
║              Project: $($Script:PROJECT_SLUG.PadRight(40))║
╚═══════════════════════════════════════════════════════════════╝

Select port mapping preset or enter custom:
"@

    $portOptions = @(
        @{ Key = "1"; Label = "Node.js (3000:3000)"; Mapping = "3000:3000" }
        @{ Key = "2"; Label = "Vite/React (5173:5173)"; Mapping = "5173:5173" }
        @{ Key = "3"; Label = "Next.js (3000:3000)"; Mapping = "3000:3000" }
        @{ Key = "4"; Label = "Django (8000:8000)"; Mapping = "8000:8000" }
        @{ Key = "5"; Label = "Flask (5000:5000)"; Mapping = "5000:5000" }
        @{ Key = "6"; Label = "Rails (3000:3000)"; Mapping = "3000:3000" }
        @{ Key = "7"; Label = "Custom (enter your own)"; Mapping = "" }
        @{ Key = "B"; Label = "Back to start menu"; Mapping = "back" }
        @{ Key = "0"; Label = "Exit"; Mapping = "exit" }
    )

    foreach ($option in $portOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $portOptions | Where-Object {
        $_.Key -eq $selection
    }

    if ($matchedOption) {
        if ($matchedOption.Mapping -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Mapping -eq "back") {
            return Show-StartMenu
        } elseif ($matchedOption.Mapping -eq "") {
            $customPorts = Read-Host "Enter port mappings (e.g. 8080:8080,3000:3000)"
            $Script:MenuExtraPorts = $customPorts
        } else {
            $Script:MenuExtraPorts = $matchedOption.Mapping
        }
        return "start-extra"
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return Show-ExtraPortsMenu
    }
}

function Show-StopMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                Jeeves - Stop Container Options                ║
╚═══════════════════════════════════════════════════════════════╝

Select stop options:
"@

    $stopOptions = @(
        @{ Key = "1"; Label = "Graceful stop"; Action = "stop" }
        @{ Key = "2"; Label = "Stop and remove container"; Action = "stop-remove" }
        @{ Key = "3"; Label = "Force stop"; Action = "stop-force" }
        @{ Key = "4"; Label = "Force stop and remove"; Action = "stop-force-remove" }
        @{ Key = "B"; Label = "Back to main menu"; Action = "back" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $stopOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $stopOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "back") {
            Show-Menu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-StopMenu
    }
}

function Show-ShellMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                Jeeves - Shell Options                         ║
╚═══════════════════════════════════════════════════════════════╝

Select shell options:
"@

    $shellOptions = @(
        @{ Key = "1"; Label = "Attach to bash shell (tmux)"; Action = "bash-shell" }
        @{ Key = "2"; Label = "Attach to bash shell (no tmux)"; Action = "bash-shell-raw" }
        @{ Key = "3"; Label = "Attach to zsh shell (tmux)"; Action = "zsh-shell" }
        @{ Key = "4"; Label = "Attach to zsh shell (no tmux)"; Action = "zsh-shell-raw" }
        @{ Key = "B"; Label = "Back to main menu"; Action = "back" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $shellOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $shellOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "back") {
            Show-Menu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-ShellMenu
    }
}

function Show-CleanMenu {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║              Jeeves - Clean Options                            ║
║              Project: $($Script:PROJECT_SLUG.PadRight(40))║
╚═══════════════════════════════════════════════════════════════╝

Select clean option:
"@

    $cleanOptions = @(
        @{ Key = "1"; Label = "Remove this project's container"; Action = "clean-container" }
        @{ Key = "2"; Label = "Remove this project's container + shared image"; Action = "clean-container-image" }
        @{ Key = "3"; Label = "Remove ALL jeeves containers"; Action = "clean-all" }
        @{ Key = "4"; Label = "Remove ALL jeeves containers + shared image"; Action = "clean-all-image" }
        @{ Key = "B"; Label = "Back to main menu"; Action = "back" }
        @{ Key = "0"; Label = "Exit"; Action = "exit" }
    )

    foreach ($option in $cleanOptions) {
        $padding = " " * (4 - $option.Key.Length)
        Write-Host "  [$($option.Key)]$padding$($option.Label)"
    }

    Write-Host ""
    $selection = Read-Host "Enter selection"

    $matchedOption = $cleanOptions | Where-Object {
        $_.Key -eq $selection -or
        $_.Action -eq $selection.ToLower()
    }

    if ($matchedOption) {
        if ($matchedOption.Action -eq "exit") {
            Write-Host "Exiting..." -ForegroundColor Gray
            exit 0
        } elseif ($matchedOption.Action -eq "back") {
            Show-Menu
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-CleanMenu
    }
}

<#
.SYNOPSIS
    Main command dispatcher

.DESCRIPTION
    Routes commands to their respective functions and handles the
    interactive menu when no command is specified.
#>
function Main {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$Command = "",

        [Parameter(Mandatory = $false)]
        [switch]$Help,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$Desktop,

        [Parameter(Mandatory = $false)]
        [switch]$InstallClaudeCode,

        [Parameter(Mandatory = $false)]
        [switch]$Clean,

        [Parameter(Mandatory = $false)]
        [switch]$Remove,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$New,

        [Parameter(Mandatory = $false)]
        [switch]$Dind,

        [Parameter(Mandatory = $false)]
        [switch]$Raw,

        [Parameter(Mandatory = $false)]
        [switch]$Zsh,

        [Parameter(Mandatory = $false)]
        [int]$Port = 0,

        [Parameter(Mandatory = $false)]
        [string]$Ports = "",

        [Parameter(Mandatory = $false)]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [switch]$Image
    )

    Test-DockerDaemon

    if ($Help -and $Command -ne "") {
        Show-CommandHelp $Command
        exit 0
    }

    if ($Command -eq "") {
        $selectedCommand = Show-Menu

        switch -Regex ($selectedCommand) {
            "^(build)$" { Build-Image -NoCache:$false -Desktop:$false -InstallClaudeCode:$false }
            "^(build-nocache)$" { Build-Image -NoCache:$true -Desktop:$false -InstallClaudeCode:$false }
            "^(build-desktop)$" { Build-Image -NoCache:$false -Desktop:$true -InstallClaudeCode:$false }
            "^(build-claude)$" { Build-Image -NoCache:$false -Desktop:$false -InstallClaudeCode:$true }
            "^(build-nocache-desktop)$" { Build-Image -NoCache:$true -Desktop:$true -InstallClaudeCode:$false }
            "^(build-nocache-claude)$" { Build-Image -NoCache:$true -Desktop:$false -InstallClaudeCode:$true }
            "^(build-desktop-claude)$" { Build-Image -NoCache:$false -Desktop:$true -InstallClaudeCode:$true }
            "^(build-all)$" { Build-Image -NoCache:$true -Desktop:$true -InstallClaudeCode:$true }

            "^(start)$" { Start-Container -Clean:$false -Dind:$false }
            "^(start-dind)$" { Start-Container -Clean:$false -Dind:$true }
            "^(start-port)$" { Start-Container -Clean:$false -Dind:$false -Port $Script:MenuPort }
            "^(start-extra)$" { Start-Container -Clean:$false -Dind:$false -ExtraPorts $Script:MenuExtraPorts }
            "^(start-clean)$" { Start-Container -Clean:$true -Dind:$false }
            "^(start-clean-dind)$" { Start-Container -Clean:$true -Dind:$true }

            "^(stop)$" { Stop-Container -Force:$false -Remove:$false }
            "^(stop-remove)$" { Stop-Container -Force:$false -Remove:$true }
            "^(stop-force)$" { Stop-Container -Force:$true -Remove:$false }
            "^(stop-force-remove)$" { Stop-Container -Force:$true -Remove:$true }

            "^(restart)$" { Restart-Container -Dind:$Dind -NoCache:$NoCache -Desktop:$Desktop -InstallClaudeCode:$InstallClaudeCode }
            "^(rm)$" { Remove-Container }

            "^(bash-shell)$" { Enter-Shell -New:$false -Raw:$false -Zsh:$false }
            "^(bash-shell-raw)$" { Enter-Shell -New:$false -Raw:$true -Zsh:$false }
            "^(zsh-shell)$" { Enter-Shell -New:$false -Raw:$false -Zsh:$true }
            "^(zsh-shell-raw)$" { Enter-Shell -New:$false -Raw:$true -Zsh:$true }

            "^(logs)$" { Show-Logs }
            "^(status)$" { Show-Status }
            "^(list)$" { Show-ListAll }

            "^(clean-container)$" { Remove-Container }
            "^(clean-container-image)$" { Remove-Container; Remove-Image -Force }
            "^(clean-all)$" { Remove-AllContainers }
            "^(clean-all-image)$" { Remove-AllContainers; Remove-Image -Force }
        }
        exit 0
    }

    switch -Regex ($Command) {
        "^(build|b)$" {
            if ($Help) { Show-CommandHelp "build"; exit 0 }
            Build-Image -NoCache:$NoCache -Desktop:$Desktop -InstallClaudeCode:$InstallClaudeCode -Clean:$Clean
        }
        "^(start|up)$" {
            if ($Help) { Show-CommandHelp "start"; exit 0 }
            Start-Container -Clean:$Clean -Dind:$Dind -Port $Port -ExtraPorts $Ports
        }
        "^(stop|down)$" {
            if ($Help) { Show-CommandHelp "stop"; exit 0 }
            Stop-Container -Force:$Force -Remove:$Remove
        }
        "^(restart)$" {
            if ($Help) { Show-CommandHelp "restart"; exit 0 }
            Restart-Container -Dind:$Dind -NoCache:$NoCache -Desktop:$Desktop -InstallClaudeCode:$InstallClaudeCode -Port $Port -ExtraPorts $Ports
        }
        "^(rm|remove)$" {
            if ($Help) { Show-CommandHelp "rm"; exit 0 }
            Remove-Container
        }
        "^(shell|attach|sh)$" {
            if ($Help) { Show-CommandHelp "shell"; exit 0 }
            Enter-Shell -New:$New -Raw:$Raw -Zsh:$Zsh
        }
        "^(logs|log)$" {
            if ($Help) { Show-CommandHelp "logs"; exit 0 }
            Show-Logs
        }
        "^(status|st)$" {
            if ($Help) { Show-CommandHelp "status"; exit 0 }
            Show-Status -All:$All
        }
        "^(list|ls|ps)$" {
            if ($Help) { Show-CommandHelp "list"; exit 0 }
            Show-ListAll
        }
        "^(clean)$" {
            if ($Help) { Show-CommandHelp "clean"; exit 0 }
            if ($All) {
                Remove-AllContainers
            } else {
                Remove-Container
            }
            if ($Image) {
                Remove-Image -Force:$Force
            }
        }
        "^(help|h|\?|)$" { Show-Help }
        default {
            Write-Log "Unknown command: $Command" -error
            Show-Help
            exit 1
        }
    }
}

$NormalizedArgs = Normalize-Arguments $args
$MainParameters = Build-MainParameterHashtable -NormalizedArgs $NormalizedArgs
Main @MainParameters
