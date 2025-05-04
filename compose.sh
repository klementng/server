#!/usr/bin/bash

set -euo pipefail

# Configuration
COMPOSE_DIR="/docker/compose"
readonly COMPOSE_DIR

cd "${COMPOSE_DIR}" || {
    echo "Error: Cannot change to directory ${COMPOSE_DIR}" >&2
    exit 1
}

show_usage() {
    echo "Usage: $(basename "$0") <project> <compose command> [options]"
    echo ""
    echo "Commands:"
    echo "  recreate   - Down and up containers (restart with fresh configuration)"
    echo "  upgrade    - Pull new images and up containers"
    echo "  all        - Run command on all YAML files"
    echo "  .git sync  - Sync with Git repository and rebuild if changes"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") webapp recreate     - Recreate the webapp project"
    echo "  $(basename "$0") all upgrade         - Upgrade all projects"
    echo "  $(basename "$0") .git sync           - Sync with Git and rebuild if needed"
    exit 1
}

# Check if we have the minimum required arguments
if [ $# -lt 2 ]; then
    show_usage
fi

# Ensure we're running as root or elevate privileges
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -s "$0" "$@"
fi

# Function to run docker compose with consistent project naming
run_docker_compose() {
    local compose_file="$1"
    local command="$2"
    local project_name
    
    # Extract project name from filename (remove .yaml extension)
    project_name="${compose_file/.yaml/}"
    
    # Log the command being executed
    echo "Running docker compose command: $command on $compose_file"
    
    case "${command}" in
        "recreate")
            COMPOSE_PROJECT_NAME="${project_name}" docker compose -f "${compose_file}" down "${@:3}"
            COMPOSE_PROJECT_NAME="${project_name}" docker compose -f "${compose_file}" up -d "${@:3}"
            ;;
        "upgrade")
            COMPOSE_PROJECT_NAME="${project_name}" docker compose -f "${compose_file}" pull "${@:3}"
            COMPOSE_PROJECT_NAME="${project_name}" docker compose -f "${compose_file}" up -d "${@:3}"
            ;;
        *)
            COMPOSE_PROJECT_NAME="${project_name}" docker compose -f "${compose_file}" "${command}" "${@:3}"
            ;;
    esac
    
    return $?
}

# Run git commands as the main user
run_git_command() {
    sudo -u main git "$@"
}

# Handle all projects at once
handle_all_projects() {
    local command="$1"
    local yaml_files
    
    # Handle case where there are no YAML files
    yaml_files=$(find . -maxdepth 1 -name "*.yaml" -type f)
    if [ -z "${yaml_files}" ]; then
        echo "No YAML files found in ${COMPOSE_DIR}" >&2
        exit 1
    fi
    
    for f in *.yaml; do
        # Skip if no actual files match the glob
        [ -e "$f" ] || continue
        
        echo "Processing $f..."
        if ! run_docker_compose "$f" "$command" "${@:2}"; then
            echo "Warning: Command failed for $f" >&2
        fi
    done
}

# Git sync function
git_sync() {
    echo "Syncing with Git repository..."
    
    # Check for git command
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git command not found" >&2
        exit 1
    fi
    
    # Fetch latest changes
    if ! run_git_command fetch; then
        echo "Error: Git fetch failed" >&2
        exit 1
    fi
    
    # Check for changes
    if run_git_command diff --quiet HEAD origin/main; then
        echo "No changes detected, exiting..."
        return 0
    fi
    
    echo "Upstream changes detected"
    
    # Pull, commit and push changes
    run_git_command pull
    run_git_command add .
    run_git_command commit -m "auto sync on $(date -u +%Y-%m-%d\ %H:%M:%S)"
    
    # Consider if force push is really necessary
    if ! run_git_command push; then
        echo "Standard push failed, using force push"
        run_git_command push --force
    fi
    
    # Rebuild and restart all services
    echo "Rebuilding all services..."
    for f in *.yaml; do
        # Skip if no actual files match the glob
        [ -e "$f" ] || continue
        
        echo "Rebuilding $f..."
        run_docker_compose "$f" build
        run_docker_compose "$f" up -d --remove-orphans
    done
}

# Main execution logic
case "$1" in
    "all")
        handle_all_projects "${@:2}"
        ;;
    ".git")
        if [ "$2" = "sync" ]; then
            git_sync
        else
            echo "Unknown git command: $2" >&2
            show_usage
        fi
        ;;
    *)
        # Check if the yaml file exists before trying to use it
        compose_file="${1}.yaml"
        if [ ! -f "$compose_file" ]; then
            echo "Error: Docker compose file '$compose_file' not found" >&2
            exit 1
        fi
        run_docker_compose "$compose_file" "${@:2}"
        ;;
esac

exit 0