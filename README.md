# copilot-ai-scala-demo

🤖 A demonstration of GitHub Copilot agents with a complete Scala development environment.

## Features

- **SBT** multi-project build with Scala 2.13
- **cats-effect + FS2** for functional programming and streaming
- **Property-based testing** with ScalaCheck
- **Development CLI** for common tasks
- **GitHub Actions** CI/CD pipeline
- **GitHub Pages** documentation

## Quick Start

### Setup Development Environment

```bash
# Source the development environment (adds commands to PATH)
source dev.env

# Run the hello-world application
dev run "Your Name"

# Build all projects  
dev build

# Run tests
dev test
```

### Manual Usage

```bash
# Run hello-world directly with SBT
sbt 'helloWorld/run "GitHub"'

# Run tests
sbt test

# Build development CLI
sbt devCli/assembly
```

## Project Structure

```
.
├── hello-world/          # Simple greeting app using cats-effect + FS2
├── dev-cli/             # CLI tool for development commands
├── dev                  # Shell script wrapper for dev-cli
├── dev.env              # Environment setup (source this)
├── docs/site/           # Documentation for GitHub Pages
└── .github/workflows/   # CI/CD pipelines
```

## Development Commands

After sourcing `dev.env`, these commands are available:

- `dev run [name]` - Run hello-world with optional name parameter
- `dev build` - Compile all subprojects  
- `dev test` - Run all tests including property-based tests
- `sbt` - Access SBT directly with proper PATH setup

## Technologies

- **Scala 2.13** - Programming language
- **SBT 1.9.6** - Build tool and dependency management
- **cats-effect** - Functional effects library
- **FS2** - Functional streaming
- **ScalaCheck** - Property-based testing framework
- **decline** - Command-line argument parsing
- **GitHub Actions** - CI/CD automation

## CI/CD

- **PR Tests** (`pr-test.yml`) - Runs on pull requests to test code quality
- **Main Build** (`main-build.yml`) - Tests and packages on main branch pushes  
- **GitHub Pages** (`pages.yml`) - Deploys documentation from `docs/site/`

## Testing

The project includes both unit tests and property-based tests:

```bash
# Run all tests
sbt test

# Run tests for specific project
sbt helloWorld/test
sbt devCli/test
```

Property-based tests use ScalaCheck to validate behavior across many generated inputs.
