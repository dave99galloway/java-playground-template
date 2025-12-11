#!/usr/bin/env bash

# Java Gradle Playground Template Initializer
# Creates a new Java project from the template with customizable parameters

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

# Default values
DEFAULT_GROUP_ID="com.playground"
DEFAULT_VERSION="1.0-SNAPSHOT"
DEFAULT_BASE_PACKAGE="com.playground"

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

# Function to convert name to package format
to_package() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '.' | sed 's/[^a-z0-9.]//g'
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] PROJECT_NAME [TARGET_DIR]

Creates a new Java playground project from template.

Arguments:
  PROJECT_NAME    Name of the project (e.g., 'myPlayground')
  TARGET_DIR      Target directory (default: current directory)

Options:
  -g, --group-id GROUP_ID          Maven group ID (default: $DEFAULT_GROUP_ID)
  -v, --version VERSION            Project version (default: $DEFAULT_VERSION)
  -p, --package PACKAGE            Base package name (default: auto-generated from project name)
  -t, --title TITLE                Project title for README (default: project name)
  -d, --description DESC           Project description (default: generic description)
  -h, --help                       Show this help message

Examples:
  # Simple project creation
  $0 myPlayground

  # Create in specific directory
  $0 myPlayground ~/projects/

  # Custom group and package
  $0 myPlayground -g com.mycompany -p com.mycompany.playground

  # Full customization
  $0 designPatterns -g com.patterns -p com.patterns.design \\
     -t "Design Patterns" -d "Gang of Four patterns"

EOF
}

# Parse command line arguments
PROJECT_NAME=""
TARGET_DIR="."
GROUP_ID="$DEFAULT_GROUP_ID"
VERSION="$DEFAULT_VERSION"
BASE_PACKAGE=""
PROJECT_TITLE=""
PROJECT_DESCRIPTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--group-id)
            GROUP_ID="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--package)
            BASE_PACKAGE="$2"
            shift 2
            ;;
        -t|--title)
            PROJECT_TITLE="$2"
            shift 2
            ;;
        -d|--description)
            PROJECT_DESCRIPTION="$2"
            shift 2
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
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            elif [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                print_error "Too many arguments"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$PROJECT_NAME" ]; then
    print_error "PROJECT_NAME is required"
    usage
    exit 1
fi

# Set defaults based on project name
if [ -z "$BASE_PACKAGE" ]; then
    BASE_PACKAGE="${GROUP_ID}.$(to_package "$PROJECT_NAME")"
fi

if [ -z "$PROJECT_TITLE" ]; then
    PROJECT_TITLE="$PROJECT_NAME"
fi

if [ -z "$PROJECT_DESCRIPTION" ]; then
    PROJECT_DESCRIPTION="various Java concepts and patterns"
fi

# Convert package to path
PACKAGE_PATH="${BASE_PACKAGE//./\/}"
CUCUMBER_GLUE_PACKAGE="${BASE_PACKAGE}.cucumber"

# Create project directory
PROJECT_DIR="$TARGET_DIR/$PROJECT_NAME"

print_info "Creating new Java playground project..."
echo
echo "  Project Name:        $PROJECT_NAME"
echo "  Target Directory:    $PROJECT_DIR"
echo "  Group ID:            $GROUP_ID"
echo "  Version:             $VERSION"
echo "  Base Package:        $BASE_PACKAGE"
echo "  Cucumber Glue:       $CUCUMBER_GLUE_PACKAGE"
echo

# Check if directory exists
if [ -d "$PROJECT_DIR" ]; then
    print_error "Directory already exists: $PROJECT_DIR"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi
    rm -rf "$PROJECT_DIR"
fi

# Create directory structure
print_info "Creating directory structure..."
mkdir -p "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/src/main/java/$PACKAGE_PATH"
mkdir -p "$PROJECT_DIR/src/test/java/$PACKAGE_PATH"
mkdir -p "$PROJECT_DIR/src/cucumber/java/$PACKAGE_PATH/cucumber"
mkdir -p "$PROJECT_DIR/src/cucumber/resources"
mkdir -p "$PROJECT_DIR/.vscode"
mkdir -p "$PROJECT_DIR/gradle/wrapper"

print_success "Directory structure created"

# Copy Gradle wrapper files
print_info "Setting up Gradle wrapper..."
if [ -f "$SCRIPT_DIR/../gradlew" ]; then
    cp "$SCRIPT_DIR/../gradlew" "$PROJECT_DIR/"
    cp "$SCRIPT_DIR/../gradlew.bat" "$PROJECT_DIR/"
    cp -r "$SCRIPT_DIR/../gradle/wrapper" "$PROJECT_DIR/gradle/"
    chmod +x "$PROJECT_DIR/gradlew"
    print_success "Gradle wrapper configured"
else
    print_warning "Gradle wrapper not found in parent directory. You'll need to run 'gradle wrapper' manually."
fi

# Process template files
print_info "Processing template files..."

# Function to substitute placeholders
substitute_placeholders() {
    local input_file="$1"
    local output_file="$2"
    
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{GROUP_ID}}|$GROUP_ID|g" \
        -e "s|{{VERSION}}|$VERSION|g" \
        -e "s|{{BASE_PACKAGE}}|$BASE_PACKAGE|g" \
        -e "s|{{CUCUMBER_GLUE_PACKAGE}}|$CUCUMBER_GLUE_PACKAGE|g" \
        -e "s|{{PROJECT_TITLE}}|$PROJECT_TITLE|g" \
        -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
        "$input_file" > "$output_file"
}

# Process each template file
substitute_placeholders "$TEMPLATE_DIR/build.gradle.template" "$PROJECT_DIR/build.gradle"
substitute_placeholders "$TEMPLATE_DIR/settings.gradle.template" "$PROJECT_DIR/settings.gradle"
substitute_placeholders "$TEMPLATE_DIR/.gitignore.template" "$PROJECT_DIR/.gitignore"
substitute_placeholders "$TEMPLATE_DIR/README.md.template" "$PROJECT_DIR/README.md"
substitute_placeholders "$TEMPLATE_DIR/vscode-settings.json.template" "$PROJECT_DIR/.vscode/settings.json"
substitute_placeholders "$TEMPLATE_DIR/CucumberTestRunner.java.template" "$PROJECT_DIR/src/cucumber/java/$PACKAGE_PATH/cucumber/CucumberTestRunner.java"

print_success "Template files processed"

# Create sample files
print_info "Creating sample files..."

# Sample main class
cat > "$PROJECT_DIR/src/main/java/$PACKAGE_PATH/Main.java" << EOF
package ${BASE_PACKAGE};

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Main {
    private static final Logger logger = LoggerFactory.getLogger(Main.class);

    public static void main(String[] args) {
        logger.info("Hello from ${PROJECT_TITLE}!");
    }
}
EOF

# Sample test class
cat > "$PROJECT_DIR/src/test/java/$PACKAGE_PATH/MainTest.java" << EOF
package ${BASE_PACKAGE};

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class MainTest {

    @Test
    void sampleTest() {
        assertThat(true).isTrue();
    }
}
EOF

# Sample feature file
cat > "$PROJECT_DIR/src/cucumber/resources/sample.feature" << EOF
Feature: Sample Feature
  As a developer
  I want to verify the project setup
  So that I can start building features

  Scenario: Sample scenario
    Given the project is set up
    When I run the tests
    Then they should pass
EOF

# Sample step definitions
cat > "$PROJECT_DIR/src/cucumber/java/$PACKAGE_PATH/cucumber/SampleSteps.java" << EOF
package ${BASE_PACKAGE}.cucumber;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.assertj.core.api.Assertions.assertThat;

public class SampleSteps {

    @Given("the project is set up")
    public void theProjectIsSetUp() {
        // Setup code
    }

    @When("I run the tests")
    public void iRunTheTests() {
        // Test execution
    }

    @Then("they should pass")
    public void theyShouldPass() {
        assertThat(true).isTrue();
    }
}
EOF

print_success "Sample files created"

# Create .github directory with copilot instructions
print_info "Creating GitHub Copilot instructions..."
mkdir -p "$PROJECT_DIR/.github"
cat > "$PROJECT_DIR/.github/copilot-instructions.md" << EOF
# ${PROJECT_TITLE}

## Project Overview

A Java playground project for ${PROJECT_DESCRIPTION}.

## Project Structure

- \`src/main/java\` - Main source code
- \`src/test/java\` - JUnit tests
- \`src/cucumber/java\` - Cucumber step definitions
- \`src/cucumber/resources\` - Cucumber feature files

## Build Commands

- \`./gradlew test\` - Run JUnit tests
- \`./gradlew cucumber\` - Run Cucumber tests
- \`./gradlew build\` - Build entire project
- \`./gradlew check\` - Run all tests

## Code Standards

- Use Java 21 features
- Write tests with AssertJ assertions
- Follow BDD principles for Cucumber tests
- Keep code clean and well-documented
EOF

print_success "GitHub Copilot instructions created"

# Initialize git repository
print_info "Initializing git repository..."
cd "$PROJECT_DIR"
git init > /dev/null 2>&1
git add . > /dev/null 2>&1
git commit -m "Initial commit from template" > /dev/null 2>&1
print_success "Git repository initialized"

# Print completion message
echo
print_success "Project created successfully!"
echo
print_info "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. ./gradlew build          # Build the project"
echo "  3. ./gradlew test           # Run JUnit tests"
echo "  4. ./gradlew cucumber       # Run Cucumber tests"
echo
print_info "Open in VS Code:"
echo "  code $PROJECT_NAME"
echo
