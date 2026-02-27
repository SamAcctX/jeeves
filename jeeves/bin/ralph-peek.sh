#!/bin/bash
set -e

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Check dependencies
for cmd in opencode jq; do
    if ! command_exists "$cmd"; then
        print_error "$cmd is not installed"
        exit 1
    fi
done

# Default to TUI mode
mode="tui"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w|--web) mode="web"; shift ;;
        -t|--tui) mode="tui"; shift ;;
        *) print_error "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

# Get sessions and find the newest one
print_info "Fetching active sessions..."
sessions=$(opencode session list --format json)
if [ -z "$sessions" ]; then
    print_error "No active sessions found"
    exit 1
fi

session_id=$(echo "$sessions" | jq -r 'sort_by(.created) | last | .id')
if [ -z "$session_id" ] || [ "$session_id" == "null" ]; then
    print_error "Failed to extract session ID"
    exit 1
fi

print_success "Found newest session: $session_id"

# Execute based on mode
if [ "$mode" == "web" ]; then
    echo "http://localhost:3333/Lw/session/$session_id"
else
    print_info "Attaching to session in TUI mode..."
    exec opencode attach -s "$session_id" http://localhost:3333
fi