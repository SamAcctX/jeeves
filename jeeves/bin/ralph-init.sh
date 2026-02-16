#!/bin/bash
set -e
trap 'print_error "Error on line $LINENO"' ERR

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

FORCE=0
FORCE_RULES=0
TEMPLATE_SOURCE="/opt/jeeves/Ralph/templates"
RALPH_DIR=".ralph"

show_usage() {
    cat << 'EOF'
ralph-init.sh - Initialize Ralph project scaffolding

USAGE:
    ralph-init.sh [OPTIONS]

OPTIONS:
    --help, -h     Show this help message and exit
    --force, -f    Skip overwrite prompts
    --rules        Force RULES.md creation

DESCRIPTION:
    Sets up Ralph scaffolding in the current project directory.
    Validates required tools and creates the basic Ralph structure.

EXAMPLES:
    ralph-init.sh                # Interactive setup
    ralph-init.sh --force        # Force overwrite existing files
    ralph-init.sh --rules        # Force RULES.md creation
    ralph-init.sh --help         # Show help

REQUIREMENTS:
    - yq: YAML processor
    - jq: JSON processor  
    - git: Version control system
EOF
}

validate_tools() {
    print_info "Validating required tools..."
    local missing_tools=()
    
    for tool in yq jq git; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            print_success "$tool found: $(command -v "$tool")"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install missing tools and try again"
        exit 1
    fi
}

detect_project_root() {
    if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && [ ! -f "pyproject.toml" ] && [ ! -f "go.mod" ]; then
        print_warning "No standard project markers found"
        print_info "Current directory will be used as project root: $(pwd)"
    else
        print_success "Project root detected: $(pwd)"
    fi
}

create_ralph_structure() {
    print_info "Creating Ralph directory structure..."
    
    local dirs=("config" "prompts" "tasks" "specs")
    
    for dir in "${dirs[@]}"; do
        local target_dir="$RALPH_DIR/$dir"
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            print_success "Created directory: $target_dir"
        else
            print_info "Directory exists: $target_dir"
        fi
    done
    
    mkdir -p "$RALPH_DIR/tasks/done"
    print_success "Created directory: $RALPH_DIR/tasks/done"
}

validate_template_source() {
    if [ ! -d "$TEMPLATE_SOURCE" ]; then
        print_error "Template source directory not found: $TEMPLATE_SOURCE"
        return 1
    fi
    
    if [ ! -r "$TEMPLATE_SOURCE" ]; then
        print_error "Template source directory not readable: $TEMPLATE_SOURCE"
        return 1
    fi
    
    print_success "Template source validated: $TEMPLATE_SOURCE"
    return 0
}

copy_config_templates() {
    print_info "Copying configuration templates..."
    
    local config_templates=(
        "config/agents.yaml.template:config/agents.yaml"
        "config/TODO.md.template:TODO.md"
        "config/deps-tracker.yaml.template:config/deps-tracker.yaml"
    )
    
    local copied_count=0
    
    for template_mapping in "${config_templates[@]}"; do
        local source_template="${template_mapping%:*}"
        local dest_file="${template_mapping#*:}"
        local source_path="$TEMPLATE_SOURCE/$source_template"
        local dest_path="$RALPH_DIR/$dest_file"
        local filename=$(basename "$dest_file")
        
        if [ -f "$source_path" ]; then
            if [ -f "$dest_path" ]; then
                if [ "$filename" = "agents.yaml" ]; then
                    print_info "Preserving existing $dest_file (never overwrite)"
                elif [ "${FORCE:-0}" -ne 1 ]; then
                    print_warning "Skipping existing file: $dest_path (use --force to overwrite)"
                else
                    cp -p "$source_path" "$dest_path"
                    print_success "Created: $dest_file"
                    copied_count=$((copied_count + 1))
                fi
            else
                cp -p "$source_path" "$dest_path"
                print_success "Created: $dest_file"
                copied_count=$((copied_count + 1))
            fi
        else
            print_warning "Template not found: $source_path"
        fi
    done
    
    echo "$copied_count"
    return 0
}

copy_task_templates() {
    print_info "Copying task templates..."
    
    local task_templates=(
        "task/TASK.md.template:TASK.md"
        "task/activity.md.template:activity.md"
        "task/attempts.md.template:attempts.md"
    )
    
    local copied_count=0
    
    for template_mapping in "${task_templates[@]}"; do
        local source_template="${template_mapping%:*}"
        local dest_file="${template_mapping#*:}"
        local source_path="$TEMPLATE_SOURCE/$source_template"
        local dest_path="$RALPH_DIR/$dest_file"
        
        if [ -f "$source_path" ]; then
            if [ -f "$dest_path" ] && [ "${FORCE:-0}" -ne 1 ]; then
                print_warning "Skipping existing file: $dest_path (use --force to overwrite)"
            else
                cp -p "$source_path" "$dest_path"
                print_success "Created: $dest_file"
                copied_count=$((copied_count + 1))
            fi
        else
            print_warning "Template not found: $source_path"
        fi
    done
    
    echo "$copied_count"
    return 0
}

copy_agent_templates() {
    print_info "Copying agent templates..."
    
    if [ ! -d "$TEMPLATE_SOURCE/agents" ]; then
        print_warning "Agent templates directory not found: $TEMPLATE_SOURCE/agents"
        return 0
    fi
    
    local copied_count=0
    
    mkdir -p ".opencode/agents"
    mkdir -p ".claude/agents"
    
    for template_file in "$TEMPLATE_SOURCE/agents"/*.md; do
        if [ -f "$template_file" ]; then
            local template_name=$(basename "$template_file")
            local dest_path=""
            local dest_dir=""
            
            if [[ "$template_name" == *"-opencode.md" ]]; then
                dest_dir=".opencode/agents"
                dest_path="$dest_dir/$template_name"
                
                if [ -f "$dest_path" ] && [ "${FORCE:-0}" -ne 1 ]; then
                    print_warning "Skipping existing OpenCode template: $template_name (use --force to overwrite)"
                else
                    cp -p "$template_file" "$dest_path"
                    print_success "Copied $template_name to .opencode/agents/"
                    copied_count=$((copied_count + 1))
                fi
                
            elif [[ "$template_name" == *"-claude.md" ]]; then
                dest_dir=".claude/agents"
                dest_path="$dest_dir/$template_name"
                
                if [ -f "$dest_path" ] && [ "${FORCE:-0}" -ne 1 ]; then
                    print_warning "Skipping existing Claude template: $template_name (use --force to overwrite)"
                else
                    cp -p "$template_file" "$dest_path"
                    print_success "Copied $template_name to .claude/agents/"
                    copied_count=$((copied_count + 1))
                fi
                
            else
                print_warning "Skipping template with unknown suffix: $template_name"
            fi
        fi
    done
    
    echo "$copied_count"
    return 0
}

copy_bash_scripts() {
    print_info "Copying bash scripts..."
    
    if [ ! -d "$TEMPLATE_SOURCE/bin" ]; then
        print_warning "Bash scripts directory not found: $TEMPLATE_SOURCE/bin"
        return 0
    fi
    
    local copied_count=0
    
    for script_file in "$TEMPLATE_SOURCE/bin"/*.sh; do
        if [ -f "$script_file" ]; then
            local script_name=$(basename "$script_file")
            local dest_path="/usr/local/bin/$script_name"
            
            if [ -f "$dest_path" ] && [ "${FORCE:-0}" -ne 1 ]; then
                print_warning "Skipping existing bash script: $script_name (use --force to overwrite)"
            else
                cp -p "$script_file" "$dest_path"
                chmod +x "$dest_path"
                print_success "Copied $(basename "$script_file") to /usr/local/bin/"
                copied_count=$((copied_count + 1))
            fi
        fi
    done
    
    echo "$copied_count"
    return 0
}

handle_rules_md() {
    print_info "Checking for RULES.md..."
    
    if [ -f "RULES.md" ] && [ "${FORCE_RULES:-0}" -ne 1 ]; then
        print_info "RULES.md already exists, skipping creation"
        return 0
    fi
    
    local template_path="/opt/jeeves/Ralph/templates/RULES.md.template"
    
    if [ -f "$template_path" ]; then
        cp "$template_path" "RULES.md"
        print_success "Created RULES.md from template"
    else
        cat > "RULES.md" << 'EOF'
# Project Rules

## Code Patterns
<!-- Add discovered patterns here -->

## Common Pitfalls
<!-- Add directory-specific pitfalls here -->

## Standard Approaches
<!-- Add standard approaches here -->

## Auto-Discovered Patterns
<!-- Agents append here -->

## Proposals to Parent Rules
<!-- Agents add cross-cutting proposals here -->
EOF
        print_success "Created minimal RULES.md"
    fi
    
    if [ -f "RULES.md" ]; then
        print_success "RULES.md validated successfully"
    else
        print_error "Failed to create RULES.md"
        return 1
    fi
}

git_integration() {
    print_info "Configuring git integration..."
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "Not a git repository. Skipping git configuration."
        return 0
    fi
    
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    print_info "Current branch: $CURRENT_BRANCH"
    
    update_gitignore
}

check_existing_installation() {
    local existing=0
    
    if [ -d "$RALPH_DIR" ]; then
        print_warning "Existing Ralph installation detected at $RALPH_DIR/"
        existing=1
    fi
    
    if [ -f "ralph-loop.sh" ]; then
        print_warning "Existing ralph-loop.sh detected"
        existing=1
    fi
    
    if [ $existing -eq 1 ]; then
        if [ "${FORCE:-0}" -eq 1 ]; then
            print_info "Force mode - backing up existing installation before overwrite"
            backup_existing
        else
            print_info "Existing Ralph installation found - will update while preserving data"
        fi
    fi
}

backup_existing() {
    local backup_dir=".ralph.backup.$(date +%Y%m%d_%H%M%S)"
    if [ -d "$RALPH_DIR" ]; then
        cp -r "$RALPH_DIR" "$backup_dir"
        print_success "Backed up existing installation to $backup_dir"
    fi
    if [ -f "ralph-loop.sh" ]; then
        cp -r "ralph-loop.sh" "ralph-loop.sh.backup"
        print_success "Backed up existing ralph-loop.sh"
    fi
}

preserve_task_data() {
    if [ -d "$RALPH_DIR/tasks/done" ]; then
        print_info "Preserving existing task data in $RALPH_DIR/tasks/done"
    fi
}

update_gitignore() {
    local gitignore=".gitignore"
    local ralph_entries=(
        "# Ralph Loop - ephemeral task data"
        ".ralph/tasks/*"
        "!.ralph/tasks/done/"
        "ralph-loop.sh"
    )
    
    if [ ! -f "$gitignore" ]; then
        touch "$gitignore"
        print_info "Created .gitignore"
    fi
    
    for entry in "${ralph_entries[@]}"; do
        if ! grep -qF "$entry" "$gitignore" 2>/dev/null; then
            echo "$entry" >> "$gitignore"
        fi
    done
    
    print_success "Updated .gitignore with Ralph exclusions"
}

copy_templates() {
    print_info "Copying Ralph templates..."
    
    if ! validate_template_source; then
        print_error "Template validation failed - aborting template copy"
        return 1
    fi
    
    create_ralph_structure
    
    local total_copied=0
    local config_count=0
    local task_count=0
    local agent_count=0
    local script_count=0
    
    config_count=$(copy_config_templates)
    total_copied=$((total_copied + config_count))
    
    task_count=$(copy_task_templates)
    total_copied=$((total_copied + task_count))
    
    agent_count=$(copy_agent_templates)
    total_copied=$((total_copied + agent_count))
    
    script_count=$(copy_bash_scripts)
    total_copied=$((total_copied + script_count))
    
    if [ "$total_copied" -gt 0 ]; then
        print_success "Template copying completed: $total_copied files copied (config: $config_count, task: $task_count, agents: $agent_count, scripts: $script_count)"
    else
        print_warning "No templates were copied (files may already exist)"
    fi
    
    return 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h) 
                show_usage
                exit 0
                ;;
            --force|-f)
                FORCE=1
                print_info "Force mode enabled - will skip overwrite prompts"
                ;;
            --rules)
                FORCE_RULES=1
                print_info "Force RULES.md creation enabled"
                ;;
            *)
                print_error "Unknown option: $1"
                print_error "Use --help for usage information"
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    print_info "Starting Ralph initialization..."
    
    parse_args "$@"
    
    check_existing_installation
    
    detect_project_root
    
    validate_tools
    
    handle_rules_md
    
    git_integration
    
    preserve_task_data
    
    if [ "$FORCE" -eq 1 ]; then
        print_warning "Running in force mode - existing files may be overwritten"
    fi
    
    copy_templates
    
    print_success "Ralph initialization completed successfully!"
    print_info "Your Ralph project structure is ready for use"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
