# Java Gradle Playground Template Upgrader
# PowerShell version for Windows
# Applies template updates to existing projects

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$ProjectDir,
    
    [switch]$DryRun,
    [string]$Files,
    [switch]$SkipBackup,
    [switch]$Force,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = $ScriptDir

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

function Show-Usage {
    Write-Host @"
Usage: upgrade-project.ps1 [OPTIONS] PROJECT_DIR

Upgrades an existing Java playground project with latest template changes.

Arguments:
  PROJECT_DIR     Path to the existing project directory

Options:
  -DryRun         Show what would be updated without making changes
  -Files          Comma-separated list of files to update
                  (e.g., "build.gradle,settings.gradle")
  -SkipBackup     Skip creating backup before upgrade
  -Force          Force upgrade even if uncommitted changes exist
  -Help           Show this help message

Available files to upgrade:
  - build.gradle         Gradle build configuration
  - settings.gradle      Project settings
  - .gitignore           Git ignore rules
  - .vscode/settings.json VS Code configuration
  - CucumberTestRunner   Cucumber test runner (preserves package)

Examples:
  # Upgrade all template files
  .\upgrade-project.ps1 C:\projects\myPlayground

  # Preview changes without applying
  .\upgrade-project.ps1 -DryRun C:\projects\myPlayground

  # Upgrade only build configuration
  .\upgrade-project.ps1 -Files "build.gradle" C:\projects\myPlayground

  # Force upgrade with uncommitted changes
  .\upgrade-project.ps1 -Force C:\projects\myPlayground

"@
}

function Test-GitStatus {
    param([string]$Path)
    
    if (Test-Path "$Path/.git") {
        Push-Location $Path
        try {
            $status = git status --porcelain 2>$null
            if ($status) {
                return $false  # Has uncommitted changes
            }
        } finally {
            Pop-Location
        }
    }
    return $true  # No git or no uncommitted changes
}

function New-Backup {
    param([string]$Path)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$Path.backup.$timestamp"
    
    Write-Info "Creating backup at: $backupPath"
    Copy-Item -Path $Path -Destination $backupPath -Recurse
    Write-Success "Backup created"
    return $backupPath
}

function Get-ProjectValues {
    param([string]$Path)
    
    $values = @{
        ProjectName = ""
        GroupId = "com.playground"
        Version = "1.0-SNAPSHOT"
        BasePackage = ""
        CucumberGluePackage = ""
    }
    
    # Extract from settings.gradle
    if (Test-Path "$Path/settings.gradle") {
        $settings = Get-Content "$Path/settings.gradle"
        foreach ($line in $settings) {
            if ($line -match "rootProject\.name\s*=\s*['""]([^'""]+)['""]") {
                $values.ProjectName = $matches[1]
            }
        }
    }
    
    # Extract from build.gradle
    if (Test-Path "$Path/build.gradle") {
        $build = Get-Content "$Path/build.gradle"
        foreach ($line in $build) {
            if ($line -match "^group\s*=\s*['""]([^'""]+)['""]") {
                $values.GroupId = $matches[1]
            }
            if ($line -match "^version\s*=\s*['""]([^'""]+)['""]") {
                $values.Version = $matches[1]
            }
            if ($line -match "cucumber\.glue['""][,\s]*['""]([^'""]+)['""]") {
                $values.CucumberGluePackage = $matches[1]
            }
        }
    }
    
    # Find base package from source structure
    if (Test-Path "$Path/src/main/java") {
        $javaFiles = Get-ChildItem -Path "$Path/src/main/java" -Filter "*.java" -Recurse | Select-Object -First 1
        if ($javaFiles) {
            $content = Get-Content $javaFiles.FullName
            foreach ($line in $content) {
                if ($line -match "^package\s+([^;]+);") {
                    $values.BasePackage = $matches[1]
                    break
                }
            }
        }
    }
    
    # Fallback to cucumber glue if base package not found
    if (-not $values.BasePackage -and $values.CucumberGluePackage) {
        $values.BasePackage = $values.CucumberGluePackage -replace '\.cucumber$', ''
    }
    
    # Set defaults if extraction failed
    if (-not $values.ProjectName) { $values.ProjectName = "unknown" }
    if (-not $values.BasePackage) { $values.BasePackage = "com.playground.unknown" }
    if (-not $values.CucumberGluePackage) { $values.CucumberGluePackage = "$($values.BasePackage).cucumber" }
    
    return $values
}

function Expand-Template {
    param(
        [string]$InputFile,
        [hashtable]$Values
    )
    
    $content = Get-Content $InputFile -Raw
    $content = $content -replace '{{PROJECT_NAME}}', $Values.ProjectName
    $content = $content -replace '{{GROUP_ID}}', $Values.GroupId
    $content = $content -replace '{{VERSION}}', $Values.Version
    $content = $content -replace '{{BASE_PACKAGE}}', $Values.BasePackage
    $content = $content -replace '{{CUCUMBER_GLUE_PACKAGE}}', $Values.CucumberGluePackage
    $content = $content -replace '{{PROJECT_TITLE}}', $Values.ProjectName
    $content = $content -replace '{{PROJECT_DESCRIPTION}}', "various Java concepts"
    
    return $content
}

function Update-File {
    param(
        [string]$FileName,
        [string]$ProjectPath,
        [hashtable]$Values,
        [bool]$IsDryRun
    )
    
    $templateFile = ""
    $targetFile = ""
    
    switch ($FileName) {
        "build.gradle" {
            $templateFile = "$TemplateDir/build.gradle.template"
            $targetFile = "$ProjectPath/build.gradle"
        }
        "settings.gradle" {
            $templateFile = "$TemplateDir/settings.gradle.template"
            $targetFile = "$ProjectPath/settings.gradle"
        }
        ".gitignore" {
            $templateFile = "$TemplateDir/.gitignore.template"
            $targetFile = "$ProjectPath/.gitignore"
        }
        ".vscode/settings.json" {
            $templateFile = "$TemplateDir/vscode-settings.json.template"
            $targetFile = "$ProjectPath/.vscode/settings.json"
            New-Item -ItemType Directory -Path "$ProjectPath/.vscode" -Force | Out-Null
        }
        "CucumberTestRunner" {
            $templateFile = "$TemplateDir/CucumberTestRunner.java.template"
            $packagePath = $Values.BasePackage -replace '\.', '/'
            $targetFile = "$ProjectPath/src/cucumber/java/$packagePath/cucumber/CucumberTestRunner.java"
        }
        default {
            Write-Error-Message "Unknown file: $FileName"
            return $false
        }
    }
    
    if (-not (Test-Path $templateFile)) {
        Write-Error-Message "Template file not found: $templateFile"
        return $false
    }
    
    if ($IsDryRun) {
        Write-Info "Would update: $targetFile"
        return $true
    }
    
    # Generate content with substitutions
    $content = Expand-Template -InputFile $templateFile -Values $Values
    $content | Out-File -FilePath $targetFile -Encoding UTF8
    Write-Success "Updated: $targetFile"
    return $true
}

# Handle help
if ($Help) {
    Show-Usage
    exit 0
}

# Validate arguments
if (-not $ProjectDir) {
    Write-Error-Message "PROJECT_DIR is required"
    Show-Usage
    exit 1
}

if (-not (Test-Path $ProjectDir)) {
    Write-Error-Message "Directory does not exist: $ProjectDir"
    exit 1
}

# Convert to absolute path
$ProjectDir = (Resolve-Path $ProjectDir).Path

Write-Info "Upgrading project at: $ProjectDir"
Write-Host ""

# Check git status
if (-not $Force -and -not (Test-GitStatus $ProjectDir)) {
    Write-Error-Message "Project has uncommitted changes!"
    Write-Warning-Message "Please commit or stash your changes first, or use -Force"
    exit 1
}

# Create backup unless skipped or dry-run
$BackupDir = ""
if (-not $DryRun -and -not $SkipBackup) {
    $BackupDir = New-Backup $ProjectDir
    Write-Host ""
}

# Extract current project values
Write-Info "Analyzing project configuration..."
$projectValues = Get-ProjectValues $ProjectDir

Write-Host "  Project Name:        $($projectValues.ProjectName)"
Write-Host "  Group ID:            $($projectValues.GroupId)"
Write-Host "  Version:             $($projectValues.Version)"
Write-Host "  Base Package:        $($projectValues.BasePackage)"
Write-Host "  Cucumber Glue:       $($projectValues.CucumberGluePackage)"
Write-Host ""

# Ensure Gradle wrapper exists
if (-not (Test-Path "$ProjectDir/gradlew.bat") -or -not (Test-Path "$ProjectDir/gradle/wrapper/gradle-wrapper.jar")) {
    Write-Info "Gradle wrapper missing, setting it up..."
    
    New-Item -ItemType Directory -Path "$ProjectDir/gradle/wrapper" -Force | Out-Null
    
    # Create gradle-wrapper.properties
    $wrapperProps = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
"@
    $wrapperProps | Out-File -FilePath "$ProjectDir/gradle/wrapper/gradle-wrapper.properties" -Encoding ASCII
    
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
    
    # Create gradlew scripts
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
    Write-Host ""
}

# Determine which files to upgrade
if ($Files) {
    $FilesToUpgrade = $Files -split ','
} else {
    $FilesToUpgrade = @(
        "build.gradle",
        "settings.gradle",
        ".gitignore",
        ".vscode/settings.json",
        "CucumberTestRunner"
    )
}

# Upgrade files
if ($DryRun) {
    Write-Info "DRY RUN - No files will be modified"
    Write-Host ""
}

Write-Info "Upgrading files..."
foreach ($file in $FilesToUpgrade) {
    Update-File -FileName $file -ProjectPath $ProjectDir -Values $projectValues -IsDryRun $DryRun
}

Write-Host ""
if ($DryRun) {
    Write-Success "Dry run completed - no changes made"
} else {
    Write-Success "Project upgraded successfully!"
    
    if ($BackupDir) {
        Write-Host ""
        Write-Info "Backup location: $BackupDir"
        Write-Warning-Message "If issues arise, restore with: Remove-Item '$ProjectDir' -Recurse; Move-Item '$BackupDir' '$ProjectDir'"
    }
    
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. cd $ProjectDir"
    Write-Host "  2. .\gradlew.bat clean build    # Verify build still works (Windows)"
    Write-Host "  3. .\gradlew.bat check           # Run all tests (Windows)"
    Write-Host "  4. git diff                      # Review changes"
    Write-Host "  5. git add -A; git commit        # Commit if satisfied"
}
Write-Host ""
