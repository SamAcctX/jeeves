#!/bin/bash

# DOCKER SAFETY NOTICE:
# This script is designed to run during Docker container startup.
# It must NEVER exit with a non-zero status code, as that would
# prevent the container from starting. All errors are logged but
# the script always exits 0.

# Skill Dependencies Installation Script
# Discovers skills, parses dependencies, and installs required packages

# Don't use set -e - we need to handle errors gracefully for Docker
# set -euo pipefail  # REMOVED for Docker safety

# Docker safety - never exit with error
docker_cleanup() {
    local exit_code=$?
    # Clean up temp files
    cleanup_temp_dir
    if [[ $exit_code -ne 0 ]]; then
        echo -e "\033[0;31m[install-skill-deps] [ERROR] Script exited with code $exit_code - forcing exit 0 for Docker safety\033[0m" >&2
    fi
    # Always exit 0
    exit 0
}
trap docker_cleanup EXIT

trap 'echo -e "\033[0;31m[install-skill-deps] [ERROR] Interrupted by signal\033[0m" >&2; exit 0' INT TERM HUP

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_NAME="install-skill-deps"

# Color codes for terminal output (if terminal supports colors)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Python parser script path - derive from script location
readonly SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly PARSER_SCRIPT="$SCRIPT_DIR/parse_skill_deps.py"

# Temporary files
readonly TEMP_DIR="/tmp/${SCRIPT_NAME}-$$"

# Error tracking arrays
declare -a FAILED_APT=()
declare -a FAILED_PIP=()
declare -a FAILED_NPM=()

# Error message tracking (stores error context for failed packages)
declare -a FAILED_APT_MSGS=()
declare -a FAILED_PIP_MSGS=()
declare -a FAILED_NPM_MSGS=()

# Global package arrays
declare -a ALL_APT_PACKAGES=()
declare -a ALL_PIP_PACKAGES=()
declare -a ALL_NPM_PACKAGES=()

# Deduplicated package arrays
declare -a UNIQUE_APT=()
declare -a UNIQUE_PIP=()
declare -a UNIQUE_NPM=()

# Statistics counters
TOTAL_SKILLS=0
SKILLS_WITH_DEPS=0
TOTAL_APT=0
TOTAL_PIP=0
TOTAL_NPM=0
INSTALLED_APT=0
INSTALLED_PIP=0
INSTALLED_NPM=0

# Command-line flags
VERBOSE=false
DRY_RUN=false

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() { echo -e "${BLUE}[${SCRIPT_NAME}] [INFO]${NC} $1"; }
log_error() { echo -e "${RED}[${SCRIPT_NAME}] [ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[${SCRIPT_NAME}] [SUCCESS]${NC} $1"; }
log_verbose() { if [ "$VERBOSE" = true ]; then echo -e "${BLUE}[${SCRIPT_NAME}] [VERBOSE]${NC} $1"; fi }
log_warning() { echo -e "${YELLOW}[${SCRIPT_NAME}] [WARNING]${NC} $1"; }

# ============================================================================
# CLI INTERFACE
# ============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Discover skills, parse dependencies from SKILL.md files, and install required packages.

OPTIONS:
    -h, --help      Show this help message and exit
    -v, --verbose   Enable verbose logging
    -d, --dry-run   Show what would be installed without installing

EXAMPLES:
    $0                      # Run with defaults
    $0 --verbose            # Enable verbose output
    $0 --dry-run            # Preview what would be installed
    $0 -v -d                # Verbose dry-run
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_usage; exit 0 ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -d|--dry-run) DRY_RUN=true; shift ;;
            -*) log_error "Unknown option: $1"; show_usage; exit 0 ;;
            *) log_error "Unexpected argument: $1"; show_usage; exit 0 ;;
        esac
    done
    log_verbose "Arguments parsed: VERBOSE=$VERBOSE, DRY_RUN=$DRY_RUN"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

command_exists() { command -v "$1" >/dev/null 2>&1; }

cleanup_temp_dir() {
    if [ -d "$TEMP_DIR" ]; then
        log_verbose "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
    log_info "Checking dependencies..."
    local missing=()
    if ! command_exists python3; then missing+=("python3"); fi
    if ! command_exists pip3; then missing+=("pip3"); fi
    if ! command_exists npm; then missing+=("npm"); fi
    if [ ! -f "$PARSER_SCRIPT" ]; then missing+=("parse_skill_deps.py"); fi
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_warning "Continuing anyway - some features may not work"
        return 0
    fi
    log_success "All dependencies are available"
}

# ============================================================================
# SKILL DISCOVERY
# ============================================================================

declare -a SKILL_FILES=()

discover_skills() {
    log_info "Discovering skills from search paths..."
    SKILL_FILES=()
    local seen_paths=""

    for skill_path in "$HOME/.claude/skills" "$HOME/.config/opencode/skills" "/proj/.claude/skills" "/proj/.opencode/skill" "/proj/.opencode/skills"; do
        if [ -d "$skill_path" ]; then
            for skill_file in "$skill_path"/*/SKILL.md; do
                if [ -f "$skill_file" ] && [[ ! "$seen_paths" =~ "$skill_file" ]]; then
                    SKILL_FILES+=("$skill_file")
                    seen_paths="$seen_paths|$skill_file"
                fi
            done
        fi
    done

    TOTAL_SKILLS=${#SKILL_FILES[@]}
    if [ $TOTAL_SKILLS -eq 0 ]; then
        log_warning "No SKILL.md files found in any search path"
        return 1
    fi
    log_success "Discovered $TOTAL_SKILLS skill file(s)"
    return 0
}

# ============================================================================
# SKILL PARSING
# ============================================================================

parse_all_skills() {
    log_info "Parsing skill dependencies..."
    mkdir -p "$TEMP_DIR"
    local first=true
    local combined_deps="${TEMP_DIR}/combined_deps.json"
    echo '[' > "$combined_deps"

    for skill_file in "${SKILL_FILES[@]}"; do
        log_verbose "Parsing: $skill_file"
        local skill_dir=$(dirname "$skill_file")
        local deps
        if deps=$(python3 "$PARSER_SCRIPT" --skill-path "$skill_dir" --verbose 2>/dev/null); then
            [ "$first" = false ] && echo ',' >> "$combined_deps"
            first=false
            echo "$deps" >> "$combined_deps"
            log_verbose "Successfully parsed: $skill_file"
        else
            log_warning "Failed to parse: $skill_file"
        fi
    done

    echo ']' >> "$combined_deps"
    log_success "Parsed all skill files"
    return 0
}

# ============================================================================
# PACKAGE DEDUPLICATION
# ============================================================================

deduplicate_packages() {
    log_info "Deduplicating package lists..."
    local combined_deps="${TEMP_DIR}/combined_deps.json"

    if [ ! -f "$combined_deps" ]; then
        log_warning "No parsed dependencies to process"
        return 1
    fi

    ALL_APT_PACKAGES=()
    ALL_PIP_PACKAGES=()
    ALL_NPM_PACKAGES=()

    if command_exists jq; then
        while IFS= read -r pkg; do
            [ -n "$pkg" ] && ALL_APT_PACKAGES+=("$pkg")
        done < <(jq -r '.[].summary.all_apt[]?' "$combined_deps" 2>/dev/null)
        while IFS= read -r pkg; do
            [ -n "$pkg" ] && ALL_PIP_PACKAGES+=("$pkg")
        done < <(jq -r '.[].summary.all_pip[]?' "$combined_deps" 2>/dev/null)
        while IFS= read -r pkg; do
            [ -n "$pkg" ] && ALL_NPM_PACKAGES+=("$pkg")
        done < <(jq -r '.[].summary.all_npm[]?' "$combined_deps" 2>/dev/null)
        SKILLS_WITH_DEPS=$(jq '[.[].summary.skills_with_deps] | add' "$combined_deps" 2>/dev/null || echo 0)
    else
        while IFS= read -r pkg; do [ -n "$pkg" ] && ALL_APT_PACKAGES+=("$pkg"); done < <(grep -oP '"all_apt":\s*\[\K[^\]]*' "$combined_deps" | tr ',' '\n' | sed 's/[" ]//g' | grep -v '^$')
        while IFS= read -r pkg; do [ -n "$pkg" ] && ALL_PIP_PACKAGES+=("$pkg"); done < <(grep -oP '"all_pip":\s*\[\K[^\]]*' "$combined_deps" | tr ',' '\n' | sed 's/[" ]//g' | grep -v '^$')
        while IFS= read -r pkg; do [ -n "$pkg" ] && ALL_NPM_PACKAGES+=("$pkg"); done < <(grep -oP '"all_npm":\s*\[\K[^\]]*' "$combined_deps" | tr ',' '\n' | sed 's/[" ]//g' | grep -v '^$')
        SKILLS_WITH_DEPS=0
    fi

    deduplicate_apt_packages
    deduplicate_pip_packages
    deduplicate_npm_packages

    TOTAL_APT=${#UNIQUE_APT[@]}
    TOTAL_PIP=${#UNIQUE_PIP[@]}
    TOTAL_NPM=${#UNIQUE_NPM[@]}

    log_success "Package lists deduplicated"
    log_verbose "APT: $TOTAL_APT, PIP: $TOTAL_PIP, NPM: $TOTAL_NPM"
    return 0
}

deduplicate_apt_packages() {
    UNIQUE_APT=()
    declare -A seen
    for pkg in "${ALL_APT_PACKAGES[@]}"; do
        local key="${pkg,,}"
        if [ -z "${seen[$key]+x}" ]; then
            seen[$key]=1
            UNIQUE_APT+=("$pkg")
        fi
    done
}

deduplicate_pip_packages() {
    UNIQUE_PIP=()
    declare -A seen
    for pkg in "${ALL_PIP_PACKAGES[@]}"; do
        if [ -z "${seen[$pkg]+x}" ]; then
            seen[$pkg]=1
            UNIQUE_PIP+=("$pkg")
        fi
    done
}

deduplicate_npm_packages() {
    UNIQUE_NPM=()
    declare -A seen
    for pkg in "${ALL_NPM_PACKAGES[@]}"; do
        if [ -z "${seen[$pkg]+x}" ]; then
            seen[$pkg]=1
            UNIQUE_NPM+=("$pkg")
        fi
    done
}

# ============================================================================
# APT PACKAGE TRANSFORMATION
# ============================================================================

# Special cases array (associative array in bash)
declare -A SPECIAL_CASES=(
    ["poppler"]="libpoppler-dev"
    ["curl"]="libcurl4-dev"
    ["openssl"]="libssl-dev"
    ["zlib"]="zlib1g-dev"
    ["readline"]="libreadline-dev"
    ["sqlite"]="libsqlite3-dev"
    ["png"]="libpng-dev"
    ["jpeg"]="libjpeg-dev"
    ["tiff"]="libtiff-dev"
    ["xml2"]="libxml2-dev"
    ["xslt"]="libxslt1-dev"
)

# Alternative suffixes array
declare -a ALT_SUFFIXES=("-utils" "-tools" "-bin" "-common")

# Transformation success tracking (key: original name, value: installed variation)
declare -A TRANSFORMATION_SUCCESS

generate_transformations() {
    local package_name="$1"
    local candidates=()

    # Check for special case
    if [[ -n "${SPECIAL_CASES[$package_name]}" ]]; then
        echo "${SPECIAL_CASES[$package_name]}"
        return 0
    fi

    # Original name
    candidates+=("$package_name")

    # -dev suffix
    candidates+=("${package_name}-dev")

    # lib prefix
    candidates+=("lib${package_name}")

    # lib + -dev
    candidates+=("lib${package_name}-dev")

    # python3- prefix
    candidates+=("python3-${package_name}")

    # Alternative suffixes
    for suffix in "${ALT_SUFFIXES[@]}"; do
        candidates+=("${package_name}${suffix}")
    done

    # lib + alternative suffixes
    for suffix in "${ALT_SUFFIXES[@]}"; do
        candidates+=("lib${package_name}${suffix}")
    done

    # Output unique candidates
    printf "%s\n" "${candidates[@]}"
}

is_package_installed() {
    local package_name="$1"
    dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"
}

try_install_with_transformations() {
    local original_name="$1"
    local error_output=""

    # Generate transformation candidates
    mapfile -t candidates < <(generate_transformations "$original_name")

    # Try each candidate
    for candidate in "${candidates[@]}"; do
        # Skip if already installed
        if is_package_installed "$candidate"; then
            log_success "Already installed: $candidate (from $original_name)"
            ((INSTALLED_APT++))
            TRANSFORMATION_SUCCESS["$original_name"]="$candidate"
            return 0
        fi

        log_verbose "Trying: $candidate (from $original_name)"
        error_output=$(sudo apt-get install -y --no-install-recommends "$candidate" 2>&1)
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            log_success "Installed: $candidate (from $original_name)"
            ((INSTALLED_APT++))
            TRANSFORMATION_SUCCESS["$original_name"]="$candidate"
            return 0
        fi
    done

    # All variations failed
    log_error "Failed to install: $original_name (tried ${#candidates[@]} variations)"
    FAILED_APT+=("$original_name")

    # Extract error from last attempt
    local error_msg
    error_msg=$(echo "$error_output" | grep -E "(E:|Package|Unable|Could not|Not found|error:)" | tail -1 | sed 's/^E: //' | sed 's/^[[:space:]]*//' | cut -c1-100)
    [ -z "$error_msg" ] && error_msg="Installation failed (tried ${#candidates[@]} variations)"
    FAILED_APT_MSGS+=("$error_msg")
    return 1
}

# ============================================================================
# PACKAGE INSTALLATION
# ============================================================================

install_packages() {
    log_info "Installing packages..."
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install the following packages:"
        show_package_preview
        return 0
    fi
    install_apt_packages || true
    install_pip_packages || true
    install_npm_packages || true
    log_success "Package installation completed"
    return 0
}

show_package_preview() {
    if [ ${#UNIQUE_APT[@]} -gt 0 ]; then
        echo ""; echo "APT packages (${TOTAL_APT}):"
        printf '  - %s\n' "${UNIQUE_APT[@]}"
    fi
    if [ ${#UNIQUE_PIP[@]} -gt 0 ]; then
        echo ""; echo "PIP packages (${TOTAL_PIP}):"
        printf '  - %s\n' "${UNIQUE_PIP[@]}"
    fi
    if [ ${#UNIQUE_NPM[@]} -gt 0 ]; then
        echo ""; echo "NPM packages (${TOTAL_NPM}):"
        printf '  - %s\n' "${UNIQUE_NPM[@]}"
    fi
}

install_apt_packages() {
    if [ ${#UNIQUE_APT[@]} -eq 0 ]; then
        log_verbose "No APT packages to install"
        return 0
    fi

    log_info "Installing APT packages..."
    log_verbose "Running apt-get update..."
    sudo apt-get update >/dev/null 2>&1 || log_warning "apt-get update failed, continuing anyway..."

    for pkg in "${UNIQUE_APT[@]}"; do
        log_verbose "Processing: $pkg"
        try_install_with_transformations "$pkg"
    done

    return 0
}

install_pip_packages() {
    if [ ${#UNIQUE_PIP[@]} -eq 0 ]; then
        log_verbose "No PIP packages to install"
        return 0
    fi
    log_info "Installing PIP packages..."
    for pkg in "${UNIQUE_PIP[@]}"; do
        log_verbose "Installing PIP package: $pkg"
        local error_output
        error_output=$(pip3 install "$pkg" 2>&1)
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            log_success "Installed: $pkg"
            ((INSTALLED_PIP++))
        else
            log_error "Failed to install: $pkg"
            FAILED_PIP+=("$pkg")
            # Extract meaningful error message
            local error_msg
            error_msg=$(echo "$error_output" | grep -E "(ERROR:|error:|Could not|No matching|Failed|not found)" | tail -1 | sed 's/ERROR: //' | sed 's/^[[:space:]]*//' | cut -c1-100)
            [ -z "$error_msg" ] && error_msg="Installation failed"
            FAILED_PIP_MSGS+=("$error_msg")
        fi
    done
    return 0
}

install_npm_packages() {
    if [ ${#UNIQUE_NPM[@]} -eq 0 ]; then
        log_verbose "No NPM packages to install"
        return 0
    fi
    log_info "Installing NPM packages..."
    local packages_str=$(printf '%s ' "${UNIQUE_NPM[@]}")
    packages_str="${packages_str% }"
    log_verbose "Packages to install: $packages_str"
    
    local batch_error_output
    batch_error_output=$(sudo npm install -g $packages_str 2>&1)
    local batch_exit_code=$?
    
    if [ $batch_exit_code -eq 0 ]; then
        INSTALLED_NPM=${#UNIQUE_NPM[@]}
        log_success "Installed all NPM packages"
    else
        log_error "Failed to install NPM packages batch, trying individually..."
        for pkg in "${UNIQUE_NPM[@]}"; do
            log_verbose "Installing NPM package: $pkg"
            local error_output
            error_output=$(sudo npm install -g "$pkg" 2>&1)
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                log_success "Installed: $pkg"
                ((INSTALLED_NPM++))
            else
                log_error "Failed to install: $pkg"
                FAILED_NPM+=("$pkg")
                # Extract meaningful error message
                local error_msg
                error_msg=$(echo "$error_output" | grep -E "(npm ERR!|error|Error:|404|not found|Unable|Failed)" | tail -1 | sed 's/npm ERR! //' | sed 's/^[[:space:]]*//' | cut -c1-100)
                [ -z "$error_msg" ] && error_msg="Installation failed"
                FAILED_NPM_MSGS+=("$error_msg")
            fi
        done
    fi
    return 0
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_report() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}SKILL DEPENDENCY INSTALLATION REPORT${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${GREEN}SKILLS PROCESSED: $TOTAL_SKILLS${NC}"
    echo "  - Total skill files found: $TOTAL_SKILLS"
    echo "  - Skills with dependencies: $SKILLS_WITH_DEPS"
    echo ""
    
    echo -e "${BLUE}PACKAGES INSTALLED:${NC}"
    
    # APT packages
    local apt_packages_str=$(printf '%s, ' "${UNIQUE_APT[@]}")
    apt_packages_str="${apt_packages_str%, }"
    [ -z "$apt_packages_str" ] && apt_packages_str="none"
    if [ ${#FAILED_APT[@]} -eq 0 ]; then
        echo -e "  ${GREEN}APT: $INSTALLED_APT/$TOTAL_APT ($apt_packages_str)${NC}"
    else
        echo -e "  ${YELLOW}APT: $INSTALLED_APT/$TOTAL_APT ($apt_packages_str)${NC}"
    fi
    
    # PIP packages
    local pip_packages_str=$(printf '%s, ' "${UNIQUE_PIP[@]}")
    pip_packages_str="${pip_packages_str%, }"
    [ -z "$pip_packages_str" ] && pip_packages_str="none"
    if [ ${#FAILED_PIP[@]} -eq 0 ]; then
        echo -e "  ${GREEN}PIP: $INSTALLED_PIP/$TOTAL_PIP ($pip_packages_str)${NC}"
    else
        echo -e "  ${YELLOW}PIP: $INSTALLED_PIP/$TOTAL_PIP ($pip_packages_str)${NC}"
    fi
    
    # NPM packages
    local npm_packages_str=$(printf '%s, ' "${UNIQUE_NPM[@]}")
    npm_packages_str="${npm_packages_str%, }"
    [ -z "$npm_packages_str" ] && npm_packages_str="none"
    if [ ${#FAILED_NPM[@]} -eq 0 ]; then
        echo -e "  ${GREEN}NPM: $INSTALLED_NPM/$TOTAL_NPM ($npm_packages_str)${NC}"
    else
        echo -e "  ${YELLOW}NPM: $INSTALLED_NPM/$TOTAL_NPM ($npm_packages_str)${NC}"
    fi
    
    echo ""
    
    # Calculate total failures
    local total_failures=$((${#FAILED_APT[@]} + ${#FAILED_PIP[@]} + ${#FAILED_NPM[@]}))
    
    if [ $total_failures -eq 0 ]; then
        echo -e "${GREEN}FAILURES: 0${NC}"
        echo "  APT: 0"
        echo "  PIP: 0"
        echo "  NPM: 0"
        echo ""
        echo -e "${GREEN}COMPLETED SUCCESSFULLY${NC}"
    else
        echo -e "${RED}FAILURES: $total_failures${NC}"
        echo "  APT: ${#FAILED_APT[@]}"
        if [ ${#FAILED_APT[@]} -gt 0 ]; then
            for i in "${!FAILED_APT[@]}"; do
                echo -e "    ${RED}- ${FAILED_APT[$i]} (error: ${FAILED_APT_MSGS[$i]})${NC}"
            done
        fi
        echo "  PIP: ${#FAILED_PIP[@]}"
        if [ ${#FAILED_PIP[@]} -gt 0 ]; then
            for i in "${!FAILED_PIP[@]}"; do
                echo -e "    ${RED}- ${FAILED_PIP[$i]} (error: ${FAILED_PIP_MSGS[$i]})${NC}"
            done
        fi
        echo "  NPM: ${#FAILED_NPM[@]}"
        if [ ${#FAILED_NPM[@]} -gt 0 ]; then
            for i in "${!FAILED_NPM[@]}"; do
                echo -e "    ${RED}- ${FAILED_NPM[$i]} (error: ${FAILED_NPM_MSGS[$i]})${NC}"
            done
        fi
        echo ""
        echo -e "${YELLOW}COMPLETED WITH FAILURES${NC}"
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

main() {
    parse_args "$@"
    check_dependencies
    discover_skills || exit 0
    parse_all_skills || exit 0
    deduplicate_packages || exit 0
    install_packages
    generate_report
    exit 0
}

main "$@"

# Docker safety - always exit 0
exit 0
