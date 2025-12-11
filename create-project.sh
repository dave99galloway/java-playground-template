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

# Function to substitute placeholders in template files
substitute_placeholders() {
    local input_file="$1"
    local output_file="$2"
    
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{GROUP_ID}}|$GROUP_ID|g" \
        -e "s|{{VERSION}}|$VERSION|g" \
        -e "s|{{BASE_PACKAGE}}|$BASE_PACKAGE|g" \
        -e "s|{{CUCUMBER_GLUE_PACKAGE}}|$CUCUMBER_GLUE_PACKAGE|g" \
        -e "s|{{MAIN_CLASS}}|$MAIN_CLASS|g" \
        -e "s|{{PROJECT_TITLE}}|$PROJECT_TITLE|g" \
        -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
        "$input_file" > "$output_file"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] PROJECT_NAME TARGET_DIR

Creates a new Java playground project from template.

Arguments:
  PROJECT_NAME    Name of the project (e.g., 'myPlayground')
  TARGET_DIR      Target directory (required)

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
TARGET_DIR=""
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

if [ -z "$TARGET_DIR" ]; then
    print_error "TARGET_DIR is required"
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
MAIN_CLASS="${BASE_PACKAGE}.Main"

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
echo "  Main Class:          $MAIN_CLASS"
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

# Generate Gradle wrapper
print_info "Setting up Gradle wrapper..."

# Copy gradle wrapper properties
substitute_placeholders "$TEMPLATE_DIR/gradle-wrapper.properties.template" "$PROJECT_DIR/gradle/wrapper/gradle-wrapper.properties"

# Download gradle-wrapper.jar
GRADLE_VERSION="8.10.2"
WRAPPER_JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_JAR="$PROJECT_DIR/gradle/wrapper/gradle-wrapper.jar"

if command -v curl > /dev/null 2>&1; then
    curl -sL "$WRAPPER_JAR_URL" -o "$WRAPPER_JAR"
elif command -v wget > /dev/null 2>&1; then
    wget -q "$WRAPPER_JAR_URL" -O "$WRAPPER_JAR"
else
    print_error "Neither curl nor wget found. Cannot download gradle-wrapper.jar"
    exit 1
fi

if [ ! -f "$WRAPPER_JAR" ] || [ ! -s "$WRAPPER_JAR" ]; then
    print_error "Failed to download gradle-wrapper.jar"
    exit 1
fi

# Create gradlew script (Unix)
cat > "$PROJECT_DIR/gradlew" << 'EOF'
#!/bin/sh

##############################################################################
#
#   Gradle start up script for POSIX generated by Gradle.
#
##############################################################################

# Attempt to set APP_HOME

# Resolve links: $0 may be a link
app_path=$0

# Need this for daisy-chained symlinks.
while
    APP_HOME=${app_path%"${app_path##*/}"}  # leaves a trailing /; empty if no leading path
    [ -h "$app_path" ]
do
    ls=$( ls -ld "$app_path" )
    link=${ls#*' -> '}
    case $link in             #(
      /*)   app_path=$link ;; #(
      *)    app_path=$APP_HOME$link ;;
    esac
done

# This is normally unused
# shellcheck disable=SC2034
APP_BASE_NAME=${0##*/}
APP_HOME=$( cd "${APP_HOME:-./}" && pwd -P ) || exit

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD=maximum

warn () {
    echo "$*"
} >&2

die () {
    echo
    echo "$*"
    echo
    exit 1
} >&2

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "$( uname )" in                #(
  CYGWIN* )         cygwin=true  ;; #(
  Darwin* )         darwin=true  ;; #(
  MSYS* | MINGW* )  msys=true    ;; #(
  NONSTOP* )        nonstop=true ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD=$JAVA_HOME/jre/sh/java
    else
        JAVACMD=$JAVA_HOME/bin/java
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD=java
    if ! command -v java >/dev/null 2>&1
    then
        die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
fi

# Increase the maximum file descriptors if we can.
if ! "$cygwin" && ! "$darwin" && ! "$nonstop" ; then
    case $MAX_FD in #(
      max*)
        # In POSIX sh, ulimit -H is undefined. That's why the result is checked to see if it worked.
        # shellcheck disable=SC3045
        MAX_FD=$( ulimit -H -n ) ||
            warn "Could not query maximum file descriptor limit"
    esac
    case $MAX_FD in  #(
      '' | soft) :;; #(
      *)
        # In POSIX sh, ulimit -n is undefined. That's why the result is checked to see if it worked.
        # shellcheck disable=SC3045
        ulimit -n "$MAX_FD" ||
            warn "Could not set maximum file descriptor limit to $MAX_FD"
    esac
fi

# Collect all arguments for the java command, stacking in reverse order:
#   * args from the command line
#   * the main class name
#   * -classpath
#   * -D...appname settings
#   * --module-path (only if needed)
#   * DEFAULT_JVM_OPTS, JAVA_OPTS, and GRADLE_OPTS environment variables.

# For Cygwin or MSYS, switch paths to Windows format before running java
if "$cygwin" || "$msys" ; then
    APP_HOME=$( cygpath --path --mixed "$APP_HOME" )
    CLASSPATH=$( cygpath --path --mixed "$CLASSPATH" )

    JAVACMD=$( cygpath --unix "$JAVACMD" )

    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    for arg do
        if
            case $arg in                                #(
              -*)   false ;;                            # don't mess with options #(
              /?*)  t=${arg#/} t=/${t%%/*}              # looks like a POSIX filepath
                    [ -e "$t" ] ;;                      #(
              *)    false ;;
            esac
        then
            arg=$( cygpath --path --ignore --mixed "$arg" )
        fi
        # Roll the args list around exactly as many times as the number of
        # args, so each arg winds up back in the position where it started, but
        # possibly modified.
        #
        # NB: a `for` loop captures its iteration list before it begins, so
        # changing the positional parameters here affects neither the number of
        # iterations, nor the values presented in `arg`.
        shift                   # remove old arg
        set -- "$@" "$arg"      # push replacement arg
    done
fi


# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS "\"-Dorg.gradle.appname=$APP_BASE_NAME\"" -classpath "\"$CLASSPATH\"" org.gradle.wrapper.GradleWrapperMain "$@"

exec "$JAVACMD" "$@"
EOF

chmod +x "$PROJECT_DIR/gradlew"

# Create gradlew.bat script (Windows)
cat > "$PROJECT_DIR/gradlew.bat" << 'EOF'
@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%"=="" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
@rem This is normally unused
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVACMD=java.exe
%JAVACMD% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVACMD=%JAVA_HOME%/bin/java.exe

if exist "%JAVACMD%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVACMD%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

:end
@rem End local scope for the variables with windows NT shell
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 set EXIT_CODE=1
if not ""=="%GRADLE_EXIT_CONSOLE%" exit %EXIT_CODE%
exit /b %EXIT_CODE%

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
EOF

# Process template files
print_info "Processing template files..."

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
