#!/usr/bin/env bash

# Java Gradle Playground Template Upgrader
# Applies template updates to existing projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where template files are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] PROJECT_DIR

Upgrades an existing Java playground project with latest template changes.

Arguments:
  PROJECT_DIR     Path to the existing project directory

Options:
  --dry-run              Show what would be updated without making changes
  --files FILES          Comma-separated list of files to update
                         (e.g., build.gradle,settings.gradle)
  --skip-backup          Skip creating backup before upgrade
  --force                Force upgrade even if uncommitted changes exist
  -h, --help             Show this help message

Available files to upgrade:
  - build.gradle         Gradle build configuration
  - settings.gradle      Project settings
  - .gitignore           Git ignore rules
  - .vscode/settings.json VS Code configuration
  - CucumberTestRunner   Cucumber test runner (preserves package)

Examples:
  # Upgrade all template files
  $0 ~/projects/myPlayground

  # Preview changes without applying
  $0 --dry-run ~/projects/myPlayground

  # Upgrade only build configuration
  $0 --files build.gradle ~/projects/myPlayground

  # Force upgrade with uncommitted changes
  $0 --force ~/projects/myPlayground

EOF
}

# Function to check if directory is a git repository with uncommitted changes
check_git_status() {
    local project_dir="$1"
    
    if [ -d "$project_dir/.git" ]; then
        cd "$project_dir"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            return 1  # Has uncommitted changes
        fi
    fi
    return 0  # No git or no uncommitted changes
}

# Function to create backup
create_backup() {
    local project_dir="$1"
    local backup_dir="${project_dir}.backup.$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup at: $backup_dir"
    cp -r "$project_dir" "$backup_dir"
    print_success "Backup created"
    echo "$backup_dir"
}

# Function to extract current values from existing project
extract_project_values() {
    local project_dir="$1"
    
    # Extract from settings.gradle
    if [ -f "$project_dir/settings.gradle" ]; then
        PROJECT_NAME=$(grep "rootProject.name" "$project_dir/settings.gradle" | sed "s/.*'\(.*\)'.*/\1/")
    fi
    
    # Extract from build.gradle
    if [ -f "$project_dir/build.gradle" ]; then
        GROUP_ID=$(grep "^group = " "$project_dir/build.gradle" | sed "s/.*'\(.*\)'.*/\1/")
        VERSION=$(grep "^version = " "$project_dir/build.gradle" | sed "s/.*'\(.*\)'.*/\1/")
        
        # Extract cucumber glue package
        CUCUMBER_GLUE_PACKAGE=$(grep "cucumber.glue" "$project_dir/build.gradle" | sed "s/.*'\(.*\)'.*/\1/")
    fi
    
    # Find base package from source structure
    if [ -d "$project_dir/src/main/java" ]; then
        # Get the deepest package path
        local java_file=$(find "$project_dir/src/main/java" -name "*.java" | head -1)
        if [ -n "$java_file" ]; then
            BASE_PACKAGE=$(grep "^package " "$java_file" | sed 's/package \(.*\);/\1/')
        fi
    fi
    
    # Fallback to cucumber glue if base package not found
    if [ -z "$BASE_PACKAGE" ] && [ -n "$CUCUMBER_GLUE_PACKAGE" ]; then
        BASE_PACKAGE="${CUCUMBER_GLUE_PACKAGE%.cucumber}"
    fi
    
    # Set defaults if extraction failed
    PROJECT_NAME="${PROJECT_NAME:-unknown}"
    GROUP_ID="${GROUP_ID:-com.playground}"
    VERSION="${VERSION:-1.0-SNAPSHOT}"
    BASE_PACKAGE="${BASE_PACKAGE:-com.playground.unknown}"
    CUCUMBER_GLUE_PACKAGE="${CUCUMBER_GLUE_PACKAGE:-${BASE_PACKAGE}.cucumber}"
}

# Function to substitute placeholders
substitute_placeholders() {
    local input_file="$1"
    
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{GROUP_ID}}|$GROUP_ID|g" \
        -e "s|{{VERSION}}|$VERSION|g" \
        -e "s|{{BASE_PACKAGE}}|$BASE_PACKAGE|g" \
        -e "s|{{CUCUMBER_GLUE_PACKAGE}}|$CUCUMBER_GLUE_PACKAGE|g" \
        -e "s|{{PROJECT_TITLE}}|$PROJECT_NAME|g" \
        -e "s|{{PROJECT_DESCRIPTION}}|various Java concepts|g" \
        "$input_file"
}

# Function to upgrade a specific file
upgrade_file() {
    local file_name="$1"
    local project_dir="$2"
    local dry_run="$3"
    
    local template_file=""
    local target_file=""
    
    case "$file_name" in
        build.gradle)
            template_file="$TEMPLATE_DIR/build.gradle.template"
            target_file="$project_dir/build.gradle"
            ;;
        settings.gradle)
            template_file="$TEMPLATE_DIR/settings.gradle.template"
            target_file="$project_dir/settings.gradle"
            ;;
        .gitignore)
            template_file="$TEMPLATE_DIR/.gitignore.template"
            target_file="$project_dir/.gitignore"
            ;;
        .vscode/settings.json)
            template_file="$TEMPLATE_DIR/vscode-settings.json.template"
            target_file="$project_dir/.vscode/settings.json"
            mkdir -p "$project_dir/.vscode"
            ;;
        CucumberTestRunner)
            template_file="$TEMPLATE_DIR/CucumberTestRunner.java.template"
            # Find existing CucumberTestRunner
            local existing_runner=$(find "$project_dir/src" -name "CucumberTestRunner.java" 2>/dev/null | head -1)
            if [ -n "$existing_runner" ]; then
                target_file="$existing_runner"
            else
                local package_path="${BASE_PACKAGE//./\/}"
                target_file="$project_dir/src/cucumber/java/$package_path/cucumber/CucumberTestRunner.java"
                mkdir -p "$(dirname "$target_file")"
            fi
            ;;
        *)
            print_warning "Unknown file: $file_name"
            return 1
            ;;
    esac
    
    if [ ! -f "$template_file" ]; then
        print_error "Template file not found: $template_file"
        return 1
    fi
    
    if [ "$dry_run" = true ]; then
        print_info "Would update: $target_file"
        return 0
    fi
    
    # Generate content with substitutions
    substitute_placeholders "$template_file" > "$target_file"
    print_success "Updated: $target_file"
}

# Parse command line arguments
PROJECT_DIR=""
DRY_RUN=false
SKIP_BACKUP=false
FORCE=false
SPECIFIC_FILES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --files)
            SPECIFIC_FILES="$2"
            shift 2
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$PROJECT_DIR" ]; then
    print_error "PROJECT_DIR is required"
    usage
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Directory does not exist: $PROJECT_DIR"
    exit 1
fi

# Convert to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

print_info "Upgrading project at: $PROJECT_DIR"
echo

# Check git status
if [ "$FORCE" = false ] && ! check_git_status "$PROJECT_DIR"; then
    print_error "Project has uncommitted changes!"
    print_warning "Please commit or stash your changes first, or use --force"
    exit 1
fi

# Create backup unless skipped or dry-run
BACKUP_DIR=""
if [ "$DRY_RUN" = false ] && [ "$SKIP_BACKUP" = false ]; then
    BACKUP_DIR=$(create_backup "$PROJECT_DIR")
    echo
fi

# Extract current project values
print_info "Analyzing project configuration..."
extract_project_values "$PROJECT_DIR"

echo "  Project Name:        $PROJECT_NAME"
echo "  Group ID:            $GROUP_ID"
echo "  Version:             $VERSION"
echo "  Base Package:        $BASE_PACKAGE"
echo "  Cucumber Glue:       $CUCUMBER_GLUE_PACKAGE"
echo

# Determine which files to upgrade
if [ -n "$SPECIFIC_FILES" ]; then
    FILES_TO_UPGRADE=(${SPECIFIC_FILES//,/ })
else
    FILES_TO_UPGRADE=(
        "build.gradle"
        "settings.gradle"
        ".gitignore"
        ".vscode/settings.json"
        "CucumberTestRunner"
    )
fi

# Upgrade files
if [ "$DRY_RUN" = true ]; then
    print_info "DRY RUN - No files will be modified"
    echo
fi

print_info "Upgrading files..."
for file in "${FILES_TO_UPGRADE[@]}"; do
    upgrade_file "$file" "$PROJECT_DIR" $DRY_RUN
done

echo
if [ "$DRY_RUN" = true ]; then
    print_success "Dry run completed - no changes made"
else
    print_success "Project upgraded successfully!"
    
    if [ -n "$BACKUP_DIR" ]; then
        echo
        print_info "Backup location: $BACKUP_DIR"
        print_warning "If issues arise, restore with: rm -rf $PROJECT_DIR && mv $BACKUP_DIR $PROJECT_DIR"
    fi
    
    echo
    print_info "Next steps:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. ./gradlew clean build    # Verify build still works"
    echo "  3. ./gradlew check           # Run all tests"
    echo "  4. git diff                  # Review changes"
    echo "  5. git add -A && git commit  # Commit if satisfied"
fi
echo
