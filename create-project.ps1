# Java Gradle Playground Template Initializer
# PowerShell version for Windows
# Creates a new Java project from the template with customizable parameters

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$ProjectName,
    
    [Parameter(Position=1, Mandatory=$false)]
    [string]$TargetDir,
    
    [string]$GroupId = "com.playground",
    [string]$Version = "1.0-SNAPSHOT",
    [string]$Package,
    [string]$Title,
    [string]$Description,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = $ScriptDir

# Default values
$DefaultGroupId = "com.playground"
$DefaultVersion = "1.0-SNAPSHOT"

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning-Message {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function ConvertTo-Package {
    param([string]$Name)
    return $Name.ToLower() -replace '[^a-z0-9]', '.' -replace '\.+', '.'
}

function Show-Usage {
    Write-Host @"
Usage: create-project.ps1 [OPTIONS] PROJECT_NAME TARGET_DIR

Creates a new Java playground project from template.

Arguments:
  PROJECT_NAME    Name of the project (e.g., 'myPlayground')
  TARGET_DIR      Target directory (required)

Options:
  -GroupId        Maven group ID (default: $DefaultGroupId)
  -Version        Project version (default: $DefaultVersion)
  -Package        Base package name (default: auto-generated from project name)
  -Title          Project title for README (default: project name)
  -Description    Project description (default: generic description)
  -Help           Show this help message

Examples:
  # Simple project creation
  .\create-project.ps1 myPlayground C:\projects

  # Custom group and package
  .\create-project.ps1 myPlayground C:\projects -GroupId com.mycompany -Package com.mycompany.playground

  # Full customization
  .\create-project.ps1 designPatterns C:\projects ``
     -GroupId com.patterns -Package com.patterns.design ``
     -Title "Design Patterns" -Description "Gang of Four patterns"

"@
}

# Handle help
if ($Help) {
    Show-Usage
    exit 0
}

# Validate required arguments
if (-not $ProjectName) {
    Write-Error-Message "PROJECT_NAME is required"
    Show-Usage
    exit 1
}

if (-not $TargetDir) {
    Write-Error-Message "TARGET_DIR is required"
    Show-Usage
    exit 1
}

# Set defaults based on project name
if (-not $Package) {
    $BasePackage = "$GroupId.$(ConvertTo-Package $ProjectName)"
} else {
    $BasePackage = $Package
}

if (-not $Title) {
    $ProjectTitle = $ProjectName
} else {
    $ProjectTitle = $Title
}

if (-not $Description) {
    $ProjectDescription = "various Java concepts and patterns"
} else {
    $ProjectDescription = $Description
}

# Convert package to path
$PackagePath = $BasePackage -replace '\.', '/'
$CucumberGluePackage = "$BasePackage.cucumber"

# Create project directory
$ProjectDir = Join-Path $TargetDir $ProjectName

Write-Info "Creating new Java playground project..."
Write-Host ""
Write-Host "  Project Name:        $ProjectName"
Write-Host "  Target Directory:    $ProjectDir"
Write-Host "  Group ID:            $GroupId"
Write-Host "  Version:             $Version"
Write-Host "  Base Package:        $BasePackage"
Write-Host "  Cucumber Glue:       $CucumberGluePackage"
Write-Host ""

# Check if directory exists
if (Test-Path $ProjectDir) {
    Write-Error-Message "Directory already exists: $ProjectDir"
    $response = Read-Host "Do you want to overwrite it? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Info "Operation cancelled"
        exit 0
    }
    Remove-Item -Path $ProjectDir -Recurse -Force
}

# Create directory structure
Write-Info "Creating directory structure..."
New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/src/main/java/$PackagePath" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/src/test/java/$PackagePath" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/src/cucumber/java/$PackagePath/cucumber" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/src/cucumber/resources" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/.vscode" -Force | Out-Null
New-Item -ItemType Directory -Path "$ProjectDir/gradle/wrapper" -Force | Out-Null

Write-Success "Directory structure created"

# Function to substitute placeholders
function Expand-Template {
    param(
        [string]$InputFile,
        [string]$OutputFile
    )
    
    $content = Get-Content $InputFile -Raw
    $content = $content -replace '{{PROJECT_NAME}}', $ProjectName
    $content = $content -replace '{{GROUP_ID}}', $GroupId
    $content = $content -replace '{{VERSION}}', $Version
    $content = $content -replace '{{BASE_PACKAGE}}', $BasePackage
    $content = $content -replace '{{CUCUMBER_GLUE_PACKAGE}}', $CucumberGluePackage
    $content = $content -replace '{{PROJECT_TITLE}}', $ProjectTitle
    $content = $content -replace '{{PROJECT_DESCRIPTION}}', $ProjectDescription
    
    $content | Out-File -FilePath $OutputFile -Encoding UTF8
}

# Generate Gradle wrapper
Write-Info "Setting up Gradle wrapper..."

# Copy gradle wrapper properties
Expand-Template "$TemplateDir/gradle-wrapper.properties.template" "$ProjectDir/gradle/wrapper/gradle-wrapper.properties"

# Download gradle-wrapper.jar
$GradleVersion = "8.10.2"
$WrapperJarUrl = "https://raw.githubusercontent.com/gradle/gradle/v$GradleVersion/gradle/wrapper/gradle-wrapper.jar"
$WrapperJar = "$ProjectDir/gradle/wrapper/gradle-wrapper.jar"

try {
    Invoke-WebRequest -Uri $WrapperJarUrl -OutFile $WrapperJar -UseBasicParsing
    if (-not (Test-Path $WrapperJar) -or (Get-Item $WrapperJar).Length -eq 0) {
        throw "Downloaded file is empty or missing"
    }
} catch {
    Write-Error-Message "Failed to download gradle-wrapper.jar: $_"
    exit 1
}

# Copy gradlew scripts from template
$gradlewUnix = @'
#!/bin/sh
APP_HOME=$( cd "${APP_HOME:-./}" && pwd -P ) || exit
CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar
if [ -n "$JAVA_HOME" ] ; then
    JAVACMD=$JAVA_HOME/bin/java
else
    JAVACMD=java
fi
exec "$JAVACMD" -Xmx64m -Xms64m -Dorg.gradle.appname=gradlew -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
'@

$gradlewUnix | Out-File -FilePath "$ProjectDir/gradlew" -Encoding ASCII -NoNewline
# Note: On Windows, we can't set Unix permissions, but Git Bash will handle it

# Create gradlew.bat for Windows
$gradlewBat = @'
@rem Gradle startup script for Windows

@if "%DEBUG%"=="" @echo off
setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

if defined JAVA_HOME goto findJavaFromJavaHome

set JAVACMD=java.exe
%JAVACMD% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVACMD=%JAVA_HOME%/bin/java.exe

if exist "%JAVACMD%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
goto fail

:execute
set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

"%JAVACMD%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

:end
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
'@

$gradlewBat | Out-File -FilePath "$ProjectDir/gradlew.bat" -Encoding ASCII

Write-Success "Gradle wrapper configured"

# Process template files
Write-Info "Processing template files..."

Expand-Template "$TemplateDir/build.gradle.template" "$ProjectDir/build.gradle"
Expand-Template "$TemplateDir/settings.gradle.template" "$ProjectDir/settings.gradle"
Expand-Template "$TemplateDir/.gitignore.template" "$ProjectDir/.gitignore"
Expand-Template "$TemplateDir/README.md.template" "$ProjectDir/README.md"
Expand-Template "$TemplateDir/vscode-settings.json.template" "$ProjectDir/.vscode/settings.json"
Expand-Template "$TemplateDir/CucumberTestRunner.java.template" "$ProjectDir/src/cucumber/java/$PackagePath/cucumber/CucumberTestRunner.java"

Write-Success "Template files processed"

# Create sample files
Write-Info "Creating sample files..."

# Sample main class
$mainClass = @"
package $BasePackage;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Main {
    private static final Logger logger = LoggerFactory.getLogger(Main.class);

    public static void main(String[] args) {
        logger.info("Hello from $ProjectTitle!");
        System.out.println("Project is ready for experimentation.");
    }
}
"@
$mainClass | Out-File -FilePath "$ProjectDir/src/main/java/$PackagePath/Main.java" -Encoding UTF8

# Sample test class
$testClass = @"
package $BasePackage;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class MainTest {
    
    @Test
    void sampleTest() {
        assertThat(true).isTrue();
    }
}
"@
$testClass | Out-File -FilePath "$ProjectDir/src/test/java/$PackagePath/MainTest.java" -Encoding UTF8

# Sample Cucumber feature
$feature = @"
Feature: Sample Feature
  This is a sample Cucumber feature for $ProjectTitle

  Scenario: Sample scenario
    Given a sample step
    When I execute it
    Then it should pass
"@
$feature | Out-File -FilePath "$ProjectDir/src/cucumber/resources/sample.feature" -Encoding UTF8

# Sample step definitions
$steps = @"
package $BasePackage.cucumber;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.assertj.core.api.Assertions.*;

public class SampleSteps {
    
    @Given("a sample step")
    public void aSampleStep() {
        // Setup code
    }
    
    @When("I execute it")
    public void iExecuteIt() {
        // Execution code
    }
    
    @Then("it should pass")
    public void itShouldPass() {
        assertThat(true).isTrue();
    }
}
"@
$steps | Out-File -FilePath "$ProjectDir/src/cucumber/java/$PackagePath/cucumber/SampleSteps.java" -Encoding UTF8

Write-Success "Sample files created"

# Create GitHub Copilot instructions
Write-Info "Creating GitHub Copilot instructions..."

$copilotInstructions = @"
You are working on a Java playground project: **$ProjectTitle**

**Purpose**: $ProjectDescription

**Project Structure**:
- Main code: \`src/main/java/$PackagePath/\`
- Tests: \`src/test/java/$PackagePath/\`
- Cucumber: \`src/cucumber/\`

**Guidelines**:
- Use Java 21 features
- Write tests with JUnit 5 and AssertJ
- Use Cucumber for BDD scenarios
- Keep code simple and educational
- Add helpful comments

**Common Tasks**:
- \`./gradlew test\` - Run JUnit tests
- \`./gradlew cucumber\` - Run Cucumber tests
- \`./gradlew build\` - Build entire project
- \`./gradlew check\` - Run all tests
"@
$copilotInstructions | Out-File -FilePath "$ProjectDir/.github/copilot-instructions.md" -Encoding UTF8 -Force
New-Item -ItemType Directory -Path "$ProjectDir/.github" -Force | Out-Null

Write-Success "GitHub Copilot instructions created"

# Initialize git repository
Write-Info "Initializing git repository..."
Push-Location $ProjectDir
try {
    git init > $null 2>&1
    git add . > $null 2>&1
    git commit -m "Initial commit from template" > $null 2>&1
    Write-Success "Git repository initialized"
} catch {
    Write-Warning-Message "Git initialization failed (git may not be installed)"
} finally {
    Pop-Location
}

# Print completion message
Write-Host ""
Write-Success "Project created successfully!"
Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. cd $ProjectName"
Write-Host "  2. .\gradlew.bat build          # Build the project (Windows)"
Write-Host "     ./gradlew build              # Build the project (Git Bash/WSL)"
Write-Host "  3. .\gradlew.bat test           # Run JUnit tests (Windows)"
Write-Host "  4. .\gradlew.bat cucumber       # Run Cucumber tests (Windows)"
Write-Host ""
Write-Info "Open in VS Code:"
Write-Host "  code $ProjectName"
Write-Host ""
