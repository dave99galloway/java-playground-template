# Java Playground Template

A reusable Gradle template for quickly creating Java playground projects with JUnit and Cucumber testing infrastructure.

## 🎯 Overview

This template provides a complete, ready-to-use structure for Java experimentation and learning projects. It includes:

- ✅ Java 21 (LTS) configuration
- ✅ Gradle build system with wrapper
- ✅ JUnit 5 test framework with AssertJ assertions
- ✅ Cucumber BDD testing framework
- ✅ Separate source sets for main, test, and cucumber code
- ✅ VS Code integration with Cucumber navigation
- ✅ Pre-configured logging (SLF4J + Logback)
- ✅ Sample files to get started quickly

## 🚀 Quick Start

### Create a New Project

```bash
./create-project.sh myPlayground
```

This creates a new project called `myPlayground` in the current directory.

### With Custom Options

```bash
./create-project.sh myPlayground \
  --group-id com.mycompany \
  --package com.mycompany.playground \
  --title "My Java Playground" \
  --description "exploring advanced Java features"
```

### Create in Specific Directory

```bash
./create-project.sh myPlayground ~/projects/
```

## 📋 Command Line Options

```
Usage: ./create-project.sh [OPTIONS] PROJECT_NAME [TARGET_DIR]

Arguments:
  PROJECT_NAME    Name of the project (e.g., 'myPlayground')
  TARGET_DIR      Target directory (default: current directory)

Options:
  -g, --group-id GROUP_ID          Maven group ID (default: com.playground)
  -v, --version VERSION            Project version (default: 1.0-SNAPSHOT)
  -p, --package PACKAGE            Base package name (default: auto-generated)
  -t, --title TITLE                Project title for README
  -d, --description DESC           Project description
  -h, --help                       Show help message
```

## 📁 Generated Project Structure

```
myPlayground/
├── .github/
│   └── copilot-instructions.md  # GitHub Copilot context
├── .vscode/
│   └── settings.json            # VS Code Cucumber integration
├── gradle/
│   └── wrapper/                 # Gradle wrapper files
├── src/
│   ├── main/java/              # Main source code
│   │   └── com/playground/myplayground/
│   │       └── Main.java       # Sample main class
│   ├── test/java/              # JUnit tests
│   │   └── com/playground/myplayground/
│   │       └── MainTest.java   # Sample test
│   ├── cucumber/java/          # Cucumber step definitions
│   │   └── com/playground/myplayground/cucumber/
│   │       ├── CucumberTestRunner.java
│   │       └── SampleSteps.java
│   └── cucumber/resources/     # Feature files
│       └── sample.feature      # Sample feature
├── .gitignore
├── build.gradle                # Gradle configuration
├── settings.gradle             # Project settings
├── gradlew                     # Gradle wrapper (Unix)
├── gradlew.bat                 # Gradle wrapper (Windows)
└── README.md                   # Project documentation
```

## 🧪 Working with Generated Projects

Once you create a project:

```bash
cd myPlayground

# Build the project
./gradlew build

# Run JUnit tests only
./gradlew unitTest

# Run Cucumber tests only
./gradlew cucumber

# Run all tests
./gradlew check

# Clean build artifacts
./gradlew clean
```

## 🔧 Customizing the Template

### Modifying Template Files

1. Edit any `.template` file in this directory
2. Update placeholders using the format `{{VARIABLE_NAME}}`
3. Available variables:
   - `{{PROJECT_NAME}}` - Project name
   - `{{GROUP_ID}}` - Maven group ID
   - `{{VERSION}}` - Project version
   - `{{BASE_PACKAGE}}` - Base Java package
   - `{{CUCUMBER_GLUE_PACKAGE}}` - Cucumber glue package
   - `{{PROJECT_TITLE}}` - Human-readable title
   - `{{PROJECT_DESCRIPTION}}` - Project description

### Adding New Template Files

1. Create file with `.template` extension
2. Add substitution logic in `create-project.sh`
3. Define target location in the script

## 🔄 Upgrading Existing Projects

Use the `upgrade-project.sh` script to apply template changes to existing projects:

```bash
# Upgrade a project to match current template structure
./upgrade-project.sh ~/projects/myPlayground

# Preview changes without applying
./upgrade-project.sh --dry-run ~/projects/myPlayground

# Upgrade specific files only
./upgrade-project.sh --files build.gradle,settings.gradle ~/projects/myPlayground
```

**Note:** Always commit your work before upgrading!

## 📦 Template Components

### Build Configuration
- **build.gradle.template** - Complete Gradle build with JUnit and Cucumber
- **settings.gradle.template** - Project name configuration

### Documentation
- **README.md.template** - Project documentation template
- **.gitignore.template** - Comprehensive gitignore

### Testing Infrastructure
- **CucumberTestRunner.java.template** - Cucumber test suite configuration

### IDE Integration
- **vscode-settings.json.template** - VS Code Cucumber support

## 🎓 Usage Examples

### Example 1: Design Patterns Project
```bash
./create-project.sh designPatterns \
  --title "Design Patterns Playground" \
  --description "Gang of Four design patterns" \
  --package com.patterns.gof
```

### Example 2: Algorithm Practice
```bash
./create-project.sh algorithms \
  --title "Algorithm Practice" \
  --description "data structures and algorithms" \
  --group-id com.learning
```

### Example 3: Framework Exploration
```bash
./create-project.sh springExperiments ~/projects/ \
  --title "Spring Framework Experiments" \
  --description "Spring Boot features and patterns" \
  --group-id com.experiments \
  --package com.experiments.spring
```

## 🛠️ Requirements

- **Bash** or compatible shell
- **Java 21** or higher
- **Gradle** (uses wrapper, so not strictly required)
- **Git** (for repository initialization)

## 💡 Tips

1. **Version Control**: Each generated project is automatically git-initialized
2. **VS Code**: Open generated projects with `code myPlayground`
3. **Cucumber Navigation**: Use F12 to jump from feature steps to definitions
4. **Batch Creation**: Script can be used to create multiple projects
5. **Custom Templates**: Fork and modify for team-specific needs

## 📄 License

This template is provided as-is for learning and development purposes.

## 🤝 Contributing

To improve this template:

1. Modify template files
2. Test with `./create-project.sh test-project`
3. Verify generated project builds and tests pass
4. Update this README with new features

## 📚 Related Resources

- [Gradle Documentation](https://docs.gradle.org)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
- [Cucumber Documentation](https://cucumber.io/docs/cucumber/)
- [AssertJ Documentation](https://assertj.github.io/doc/)
