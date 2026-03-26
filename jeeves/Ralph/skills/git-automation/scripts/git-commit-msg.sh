#!/bin/bash
# git-commit-msg.sh - Conventional commit message generator
#
# Usage:
#   ./git-commit-msg.sh --task-id 0042 --agent-type developer --task-title "Implement feature X"
#   ./git-commit-msg.sh --task-id 0042 --agent-type tester --task-title "Add tests for Y"
#   ./git-commit-msg.sh --task-id 0042 --agent-type developer --task-title "Fix login crash" --scope 0042
#
# Output: Single line conventional commit message to stdout
#   With --scope:    feat(0042): implement feature x
#   Without --scope: feat: implement feature x

set -e

TASK_ID=""
AGENT_TYPE=""
TASK_TITLE=""
SCOPE=""
BREAKING="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id)
            TASK_ID="$2"
            shift 2
            ;;
        --agent-type)
            AGENT_TYPE="$2"
            shift 2
            ;;
        --task-title)
            TASK_TITLE="$2"
            shift 2
            ;;
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --breaking)
            BREAKING="true"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Determine commit type based on agent type and task title keywords
determine_commit_type() {
    local agent="$1"
    local title="$2"
    local title_lower
    title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')

    # Check for override keywords first
    if [[ "$title_lower" =~ (fix|bug|error|crash) ]]; then
        echo "fix"
        return
    fi

    if [[ "$title_lower" =~ refactor ]]; then
        echo "refactor"
        return
    fi

    if [[ "$title_lower" =~ test ]]; then
        echo "test"
        return
    fi

    if [[ "$title_lower" =~ (doc|documentation) ]]; then
        echo "docs"
        return
    fi

    # Map agent type to default commit type
    case "$agent" in
        developer)
            echo "feat"
            ;;
        tester)
            echo "test"
            ;;
        architect)
            echo "feat"
            ;;
        writer)
            echo "docs"
            ;;
        researcher)
            echo "docs"
            ;;
        ui-designer)
            echo "feat"
            ;;
        *)
            # Unknown agent type defaults to chore
            echo "chore"
            ;;
    esac
}

# Generate subject from task title
generate_subject() {
    local title="$1"
    local subject

    # Handle empty title
    if [[ -z "$title" ]]; then
        echo "update code"
        return
    fi

    # Convert to lowercase
    subject=$(echo "$title" | tr '[:upper:]' '[:lower:]')

    # Remove trailing period
    subject=$(echo "$subject" | sed 's/\.$//')

    # Sanitize special characters (keep only alphanumeric, space, hyphen, underscore)
    subject=$(echo "$subject" | sed 's/[^a-z0-9 _-]//g')

    # Trim leading/trailing whitespace
    subject=$(echo "$subject" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Truncate to 50 chars (ideal) or 72 (max)
    if [[ ${#subject} -gt 72 ]]; then
        # Truncate at 72 and add ellipsis
        subject="${subject:0:69}..."
    fi

    echo "$subject"
}

# Main logic
main() {
    # Validate required arguments
    if [[ -z "$AGENT_TYPE" ]]; then
        echo "Error: --agent-type is required" >&2
        exit 1
    fi

    # TASK_TITLE can be empty - generate_subject will handle it with generic message

    # Determine commit type
    local commit_type
    commit_type=$(determine_commit_type "$AGENT_TYPE" "$TASK_TITLE")

    # Generate subject
    local subject
    subject=$(generate_subject "$TASK_TITLE")

    # Check for breaking change marker
    local breaking_marker=""
    if [[ "$BREAKING" == "true" ]]; then
        breaking_marker="!"
    fi

    # Build scope portion
    local scope_str=""
    if [[ -n "$SCOPE" ]]; then
        scope_str="(${SCOPE})"
    fi

    # Output formatted commit message
    echo "${commit_type}${breaking_marker}${scope_str}: ${subject}"
}

main "$@"
