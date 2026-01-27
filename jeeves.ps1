<#
.SYNOPSIS
    Jeeves - OpenCode Container Management Helper

.DESCRIPTION
    A PowerShell script for managing the OpenCode (jeeves) Docker container.
    This script provides convenient commands to build, start, stop, and interact
    with the containerized OpenCode environment.

    The script can be invoked from any directory as it maps the current working
    directory (pwd) to /proj inside the container.

.PARAMETER Command
    The command to execute (build, start, stop, restart, rm, shell, logs, status, clean, help)

.PARAMETER NoCache
    Build without using Docker cache (valid for 'build' command)

.PARAMETER Desktop
    Build desktop binaries (valid for 'build' command)

.PARAMETER Clean
    Perform a clean start: stops, removes container/image, rebuilds from scratch, then starts (valid for 'start' command)

.PARAMETER Remove
    Also remove the container after stopping (valid for 'stop' command)

.PARAMETER Force
    Force stop the container using SIGKILL instead of SIGTERM (valid for 'stop' command)

.EXAMPLE
    .\jeeves.ps1 build
    Build the Docker image using cache

.EXAMPLE
    .\jeeves.ps1 build --no-cache --desktop
    Clean build with desktop binaries

.EXAMPLE
    .\jeeves.ps1 start --clean
    Clean rebuild and start the container

.EXAMPLE
    .\jeeves.ps1 stop --force --remove
    Force stop and remove container

.EXAMPLE
    .\jeeves.ps1 shell
    Attach to the container shell

.NOTES
    File Name      : jeeves.ps1
    Author         : OpenCode
    Prerequisite   : Docker must be installed and running
    Platform       : Cross-platform (Windows, Linux, macOS)

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

<#
.SYNOPSIS
    Validates Docker daemon is running

.DESCRIPTION
    Checks if Docker daemon is available and running. Exits with error
    if Docker is not available.
#>
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

<#
.SYNOPSIS
    Script-wide configuration variables

.DESCRIPTION
    Centralized configuration for Docker image names, tags, ports, and paths.
    These variables are prefixed with $Script: to make them available to all functions.
#>
$Script:IMAGE_NAME = "jeeves"
$Script:IMAGE_TAG = "latest"
$Script:CONTAINER_NAME = "jeeves"
$Script:DOCKERFILE_PATH = Join-Path $PSScriptRoot "Dockerfile.jeeves"
$Script:BUILD_CONTEXT = $PSScriptRoot
$Script:HOST_PORT = 3333
$Script:CONTAINER_PORT = 3333
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
        "$($userHome)/.config/opencode:/home/jeeves/.config/opencode:rw"
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
    $tmpPath = Join-Path $PSScriptRoot ".tmp"
    
    if (-not (Test-Path $tmpPath)) {
        New-Item -ItemType Directory -Path $tmpPath -Force | Out-Null
        Write-Log "Created .tmp directory for compose files" -trace
    }
    
    # Ensure .gitignore exists and contains .tmp
    $gitignorePath = Join-Path $PSScriptRoot ".gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath
        if ($gitignoreContent -notcontains ".tmp/") {
            Add-Content -Path $gitignorePath -Value "`n.tmp/" -Encoding UTF8
            Write-Log "Added .tmp/ to .gitignore" -trace
        }
    }
    
    # Ensure .dockerignore exists and contains .tmp
    $dockerignorePath = Join-Path $PSScriptRoot ".dockerignore"
    if (Test-Path $dockerignorePath) {
        $dockerignoreContent = Get-Content $dockerignorePath
        if ($dockerignoreContent -notcontains ".tmp/") {
            Add-Content -Path $dockerignorePath -Value "`n.tmp/" -Encoding UTF8
            Write-Log "Added .tmp/ to .dockerignore" -trace
        }
    }
}

<#
.SYNOPSIS
    Generates Docker Compose configuration file

.DESCRIPTION
    Creates a docker-compose.yml file in the .tmp directory with resolved paths,
    proper service dependencies, and Browserless integration. Preserves all existing
    dynamic path resolution logic from Get-UserMountSpec().

.NOTES
    Generated file includes jeeves and browserless services with proper networking,
    health checks, and resource limits as specified in the PRD.
#>
function New-DockerComposeFile {
    $mountSpec = Get-UserMountSpec
    $tmpPath = Join-Path $PSScriptRoot ".tmp"
    
    $composeContent = @"
services:
  jeeves:
    build:
      context: ..
      dockerfile: Dockerfile.jeeves
    environment:
      - BROWSERLESS_URL=http://browserless:3000
    depends_on:
      browserless:
        condition: service_healthy
    volumes:
      - $($mountSpec.WorkspaceMount)`n
"@
    
    foreach ($configMount in $mountSpec.ConfigMounts) {
        $composeContent += "      - $configMount`n"
    }
    
    if ($mountSpec.UserFlag) {
        $userSpec = $mountSpec.UserFlag -replace '--user ', ''
        $composeContent += "    user: $userSpec`n"
    }
    
    $composeContent += @"
    ports:
      - "3333:3333"
    networks:
      - jeeves-network

  browserless:
    image: ghcr.io/browserless/chromium:latest
    environment:
      - MAX_CONCURRENT_SESSIONS=10
      - DEFAULT_BLOCK_ADS=true
      - FUNCTION_ENABLED=true
      - TOKEN=1234
    ports:
      - "3334:3000"
    networks:
      - jeeves-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/docs"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'

networks:
  jeeves-network:
    driver: bridge
"@
    
    # Write to .tmp directory
    $composeFile = Join-Path $tmpPath "docker-compose.yml"
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

    # Add build arguments - these shouldn't be needed anymore at build-time
    #$userIds = Get-UserIds
    #$buildArgs += "--build-arg", "UID=$($userIds.UID)"
    #$buildArgs += "--build-arg", "GID=$($userIds.GID)"

    if ($Desktop) {
        Write-Log "Building with desktop support..." -warning
        $buildArgs += "--build-arg", "BUILD_DESKTOP=true"
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
    # Check if docker-compose.yml exists (new method) or fall back to docker (old method)
    $composeFile = Join-Path $PSScriptRoot ".tmp\docker-compose.yml"
    if (Test-Path $composeFile) {
        # Use docker compose to find jeeves container
        $composePs = & docker compose -f $composeFile ps -q jeeves 2>$null
        if ($composePs) {
            return $composePs.Trim()
        }
        return $null
    } else {
        # Legacy single container method
        $containerId = docker ps -q -f "name=${Script:CONTAINER_NAME}"
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
        [switch]$Desktop
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
    Build-Image -NoCache:$NoCache -Desktop:$Desktop

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

    # Check if docker-compose.yml exists (new method) or fall back to docker (old method)
    $composeFile = Join-Path $PSScriptRoot ".tmp\docker-compose.yml"
    if (Test-Path $composeFile) {
        if (-not $SkipStop) {
            Write-Log "Removing services using Docker Compose..." -debug
            & docker compose -f $composeFile down -v --remove-orphans
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Services removed" -success
            }
        }
    } else {
        # Legacy single container method
        if (-not $SkipStop) {
            Ensure-ContainerStopped -Force:$Force
        } else {
            $runningContainer = Get-ContainerId
            if ($runningContainer) {
                Write-Log "Container '${Script:CONTAINER_NAME}' is running; cannot remove it while active" -error
                return
            }
        }

        $allContainers = docker ps -a -q -f "name=${Script:CONTAINER_NAME}"
        if (-not $allContainers) {
            Write-Log "No container instances found for '${Script:CONTAINER_NAME}'" -trace
            return
        }

        Write-Log "Removing container: ${Script:CONTAINER_NAME}" -debug

        # Initialize rmArgs array with base command and mandatory flags
        $rmArgs = @(
            "rm"
        )

        # Add all containers to remove
        if ($allContainers) {
            $rmArgs += $allContainers
        }

        # Execute the command using splatting operator
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
        [switch]$NoCache
    )

    Ensure-ImageExists -ForceRebuild:$ForceRebuild -NoCache:$NoCache

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
    param([switch]$Clean)

    if ($Clean) {
        Write-Log "Clean start requested..." -warning
        Ensure-ContainerNotPresent -Force
        Remove-Image
        Build-Image -NoCache -Clean
    } else {
        Ensure-ImageExists
    }

    $existingContainer = Get-ContainerId
    if ($existingContainer) {
        Write-Log "Container '${Script:CONTAINER_NAME}' is already running" -warning
        return
    }

    Ensure-ContainerNotPresent -SkipStop

    Write-Log "Starting container services..." -debug

    # 1. Ensure .tmp directory exists and is properly ignored
    Initialize-TemporaryDirectory

    # 2. Generate docker-compose.yml with resolved paths
    $composeFile = New-DockerComposeFile

    # 3. Run docker compose instead of docker run
    & docker compose -f $composeFile up -d

    # 4. Handle errors and cleanup if needed
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to start services" -error
        exit 1
    }

    Write-Log "Services started successfully" -success
    Write-Log "Access the web UI at: http://localhost:${Script:HOST_PORT}" -info
    Write-Log "Browserless available at: http://localhost:3334?TOKEN=1234" -info
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

    # Check if docker-compose.yml exists (new method) or fall back to docker (old method)
    $composeFile = Join-Path $PSScriptRoot ".tmp\docker-compose.yml"
    if (Test-Path $composeFile) {
        Write-Log "Stopping services using Docker Compose..." -debug
        & docker compose -f $composeFile down

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Services stopped" -success
        } else {
            Write-Log "Failed to stop services using Docker Compose, falling back to Docker" -warning
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
        $containerId
        "/bin/bash"
    )
    
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
    # Check if docker-compose.yml exists (new method) or fall back to docker (old method)
    $composeFile = Join-Path $PSScriptRoot ".tmp\docker-compose.yml"
    if (Test-Path $composeFile) {
        Write-Log "Showing logs for all services..." -debug
        & docker compose -f $composeFile logs -f
    } else {
        $containerId = Get-ContainerId
        if (-not $containerId) {
            Write-Log "Container '${Script:CONTAINER_NAME}' is not running. Start it with: jeeves start" -error
            exit 1
        }

        # Initialize logsArgs array with base command and mandatory flags
        $logsArgs = @(
            "logs"
            "-f"
            $containerId
        )

        # Execute the command using splatting operator
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
    Write-Log "=== Jeeves Service Status ===" -debug

    # Check if docker-compose.yml exists (new method) or fall back to docker (old method)
    $composeFile = Join-Path $PSScriptRoot ".tmp\docker-compose.yml"
    if (Test-Path $composeFile) {
        Write-Log "Using Docker Compose services:" -info
        & docker compose -f $composeFile ps

        # Additional status information
        Write-Log "" -info
        Write-Log "Web UI: http://localhost:${Script:HOST_PORT}" -trace
        Write-Log "Browserless: http://localhost:3000" -trace
    } else {
        # Legacy single container status
        $containerId = Get-ContainerId
        if ($containerId) {
            Write-Log "Status: Running" -success
            Write-Log "Container ID: $containerId" -trace
            Write-Log "Web UI: http://localhost:${Script:HOST_PORT}" -trace
        } else {
            # Initialize psArgs array with base command and mandatory flags
            $psArgs = @(
                "ps"
                "-a"
                "-q"
                "-f", "name=${Script:CONTAINER_NAME}"
            )

            # Execute the command using splatting operator
            $stoppedContainer = docker @psArgs
            if ($stoppedContainer) {
                Write-Log "Status: Stopped" -info
            } else {
                Write-Log "Status: Not created" -info
            }
        }
    }

    # Check image status
    $imagesArgs = @(
        "images"
        "-q", "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    )

    $imageExists = docker @imagesArgs
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
    Write-Log "Removing image: ${Script:IMAGE_NAME}:${Script:IMAGE_TAG}" -debug

    $imageExists = docker images -q "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    if (-not $imageExists) {
        Write-Log "Image not found" -warning
        return
    }

    Ensure-ContainerNotPresent -Force

    # Initialize rmiArgs array with base command and mandatory flags
    $rmiArgs = @(
        "rmi"
        "${Script:IMAGE_NAME}:${Script:IMAGE_TAG}"
    )
    
    # Execute the command using splatting operator
    docker @rmiArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Image removed" -success
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

Commands:
  build     Build the Docker image (stops container if running)
  start     Start the container (builds image if needed)
  stop      Stop the container
  restart   Restart the container (builds image if needed)
  rm        Remove the container (stops if running)
  shell     Attach to the container shell (builds and starts if needed)
  logs      Show container logs
  status    Show container and image status
  clean     Remove container and image

Options:
  --help       Show detailed help for a command
  --no-cache   Build without using cache (build command)
  --desktop    Build desktop binaries (build command)
  --clean      Clean start: rebuild everything (start command)
  --remove     Also remove container (stop command)
  --force      Force stop container (stop command)

Aliases:
  b -> build
  up -> start
  down -> stop
  attach, sh -> shell
  st, ps -> status

Examples:
  jeeves build              # Build the image
  jeeves build --no-cache   # Clean build without cache
  jeeves build --desktop    # Build with desktop support
  jeeves start              # Start the container
  jeeves start --clean      # Clean rebuild and start
  jeeves shell              # Enter the container
  jeeves logs               # View logs
  jeeves stop               # Stop the container
  jeeves stop --remove      # Stop and remove container
  jeeves stop --force       # Force stop
  jeeves clean              # Remove everything

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
    Builds the jeeves Docker image from the Dockerfile located in the
    Dockerfiles/jeeves directory. The image includes OpenCode CLI, TUI,
    and Web UI tools along with CUDA support and development dependencies.

USAGE:
    jeeves build [options]

OPTIONS:
    --no-cache   Build without using Docker's layer cache
                 This forces a complete rebuild of all layers, useful for
                 ensuring a clean build or troubleshooting build issues.

    --desktop    Build desktop binaries (Linux, Windows)
                 Includes the OpenCode desktop application (Tauri-based)
                 in the image. This significantly increases build time.

    --help       Show this help message

EXAMPLES:
    jeeves build
    jeeves build --no-cache
    jeeves build --desktop
    jeeves build --no-cache --desktop

NOTES:
    - The build uses UID/GID arguments for proper file permissions
    - Build context is: ./Dockerfiles/jeeves
    - Image will be tagged as: jeeves:latest
    - Desktop builds can take 30+ minutes due to cross-compilation
    - Container will be stopped before rebuilding if running
"@
        }
        "start" {
@"
Jeeves start - Start the Container

DESCRIPTION:
    Starts the jeeves container with the current working directory mounted
    to /proj inside the container. This allows you to work on files
    in your current directory from within the container.

USAGE:
    jeeves start [options]

OPTIONS:
    --clean      Perform a clean start
                 Stops the container if running, removes the container,
                 removes the image, rebuilds from scratch (--no-cache),
                 and then starts the container.

    --help       Show this help message

EXAMPLES:
    jeeves start
    jeeves start --clean

NOTES:
- Port 3333 on host maps to port 3333 in container
- Current directory (pwd) is mounted to /proj
- Container name: jeeves
- Web UI available at: http://localhost:3333
- Container runs in detached mode (background)
"@
        }
        "stop" {
@"
Jeeves stop - Stop the Container

DESCRIPTION:
    Stops the jeeves container if running. By default, performs a graceful
    shutdown using SIGTERM. If the container is not running, this command
    exits gracefully. Optionally force kills with SIGKILL and/or removes
    the container after stopping.

USAGE:
    jeeves stop [options]

OPTIONS:
    --remove     Remove the container after stopping
                 Deletes the container from Docker. Container state will
                 be lost, but the Docker image remains intact.

    --force      Force stop using SIGKILL
                 Immediately terminates the container without allowing
                 for graceful shutdown. Useful if the container is stuck.

    --help       Show this help message

EXAMPLES:
    jeeves stop
    jeeves stop --remove
    jeeves stop --force
    jeeves stop --force --remove

NOTES:
    - Default: Graceful shutdown with docker stop
    - With --force: Immediate termination with docker kill
    - With --remove: Container is deleted after stopping
    - To rebuild after removal, use: jeeves build
"@
        }
        "restart" {
@"
Jeeves restart - Restart the Container

DESCRIPTION:
    Stops and immediately starts the container. Useful for applying changes
    that don't require a full rebuild, such as environment variable changes
    or when troubleshooting.

USAGE:
    jeeves restart

EXAMPLES:
    jeeves restart

NOTES:
- Equivalent to: jeeves stop && jeeves start
- Builds image if missing before starting
- Container data in /proj is preserved
- Container name and configuration remain the same
"@
        }
        "rm" {
@"
Jeeves rm - Remove the Container

DESCRIPTION:
    Removes the jeeves container from Docker. If the container is running,
    it will be stopped first. The container's state will be lost, but the
    Docker image remains intact.

USAGE:
    jeeves rm

EXAMPLES:
    jeeves rm

NOTES:
    - Stops container if running
    - Removes container from Docker
    - Docker image is NOT removed (use 'clean' command)
    - To start again, use: jeeves start
    - To rebuild image, use: jeeves build
"@
        }
        "shell" {
@"
Jeeves shell - Attach to Container Shell

DESCRIPTION:
    Opens an interactive bash shell inside the running container. This allows
    you to execute commands directly within the container environment.

USAGE:
    jeeves shell

EXAMPLES:
    jeeves shell

NOTES:
- Builds image and starts container if not running
- Opens an interactive bash shell
- Your current directory is available at /proj
- OpenCode CLI is available as 'opencode'
- Type 'exit' to leave the shell
- Tmux auto-attaches for persistent sessions
- Hint:  Use the Shift/Option key interact with the terminal outside of tmux, useful for copy-paste and keyboard shortcuts
"@
        }
        "logs" {
@"
Jeeves logs - View Container Logs

DESCRIPTION:
    Displays the container's stdout/stderr logs and follows new output in
    real-time. Shows all output from the OpenCode Web UI service.

USAGE:
    jeeves logs

EXAMPLES:
    jeeves logs

NOTES:
    - Container must be running
    - Shows logs from OpenCode Web UI (port 3333)
    - Follows new output in real-time
    - Press Ctrl+C to exit log viewer
    - Logs include web server activity and errors
"@
        }
        "status" {
@"
Jeeves status - Show Container and Image Status

DESCRIPTION:
    Displays the current state of the jeeves container and image.
    Shows whether the container is running, stopped, or not created,
    and whether the Docker image exists.

USAGE:
    jeeves status

EXAMPLES:
    jeeves status

NOTES:
    - Shows container status (running/stopped/not created)
    - Shows container ID if running
    - Shows Web UI URL if running
    - Shows Docker image existence status
    - Useful for troubleshooting connectivity issues
"@
        }
        "clean" {
@"
Jeeves clean - Remove Container and Image

DESCRIPTION:
    Removes both the container and the Docker image. This completely removes
    jeeves from Docker, freeing up disk space and requiring a rebuild to
    use again.

USAGE:
    jeeves clean

EXAMPLES:
    jeeves clean

NOTES:
    - Stops container if running
    - Removes container from Docker
    - Removes Docker image from local registry
    - To use again, you must run: jeeves build
    - Destructive operation - cannot be undone
    - Useful for freeing disk space or complete reset
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
╚═══════════════════════════════════════════════════════════════╝

Select an option:
"@

    $menuOptions = @(
        @{ Key = "1"; Label = "Build image"; Action = "build" }
        @{ Key = "2"; Label = "Start container"; Action = "start" }
        @{ Key = "3"; Label = "Stop container"; Action = "stop" }
        @{ Key = "4"; Label = "Restart container"; Action = "restart" }
        @{ Key = "5"; Label = "Remove container"; Action = "rm" }
        @{ Key = "6"; Label = "Attach to shell"; Action = "shell" }
        @{ Key = "7"; Label = "View logs"; Action = "logs" }
        @{ Key = "8"; Label = "Show status"; Action = "status" }
        @{ Key = "9"; Label = "Clean (remove all)"; Action = "clean" }
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
        } else {
            return $matchedOption.Action
        }
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-Menu
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
        [switch]$Clean,

        [Parameter(Mandatory = $false)]
        [switch]$Remove,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Validate Docker is available
    Test-DockerDaemon

    # Handle --help flag for specific command help
    if ($Help -and $Command -ne "") {
        Show-CommandHelp $Command
        exit 0
    }

    # If no command provided, show interactive menu
    if ($Command -eq "") {
        $selectedCommand = Show-Menu

        # Map menu selection back to command
        switch -Regex ($selectedCommand) {
            "^(build)$" { Build-Image -NoCache:$NoCache -Desktop:$Desktop }
            "^(start)$" { Start-Container -Clean:$Clean }
            "^(stop)$" { Stop-Container -Force:$Force -Remove:$Remove }
            "^(restart)$" { Stop-Container; Ensure-ImageExists -NoCache:$NoCache -Desktop:$Desktop; Start-Container }
            "^(rm)$" { Remove-Container }
            "^(shell)$" { Enter-Shell }
            "^(logs)$" { Show-Logs }
            "^(status)$" { Show-Status }
            "^(clean)$" { Remove-Container; Remove-Image }
        }
        exit 0
    }

    # Command dispatcher for direct command invocation
    switch -Regex ($Command) {
        "^(build|b)$" {
            if ($Help) { Show-CommandHelp "build"; exit 0 }
            Build-Image -NoCache:$NoCache -Desktop:$Desktop
        }
        "^(start|up)$" {
            if ($Help) { Show-CommandHelp "start"; exit 0 }
            Start-Container -Clean:$Clean
        }
        "^(stop|down)$" {
            if ($Help) { Show-CommandHelp "stop"; exit 0 }
            Stop-Container -Force:$Force -Remove:$Remove
        }
        "^(restart)$" {
            if ($Help) { Show-CommandHelp "restart"; exit 0 }
            Stop-Container; Ensure-ImageExists -NoCache:$NoCache -Desktop:$Desktop; Start-Container
        }
        "^(rm|remove)$" {
            if ($Help) { Show-CommandHelp "rm"; exit 0 }
            Remove-Container
        }
        "^(shell|attach|sh)$" {
            if ($Help) { Show-CommandHelp "shell"; exit 0 }
            Enter-Shell
        }
        "^(logs|log)$" {
            if ($Help) { Show-CommandHelp "logs"; exit 0 }
            Show-Logs
        }
        "^(status|st|ps)$" {
            if ($Help) { Show-CommandHelp "status"; exit 0 }
            Show-Status
        }
        "^(clean)$" {
            if ($Help) { Show-CommandHelp "clean"; exit 0 }
            Remove-Container; Remove-Image
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
