# CI-for-AI Validation Scripts

This directory contains scripts to validate that Copilot sessions follow established rules and best practices.

## Overview

The validation system has been enhanced to examine both the **process** (workflow logs) and the **output** (PR artifacts) to ensure Copilot is following established guidelines. This provides comprehensive validation of Copilot's working style and adherence to repository instructions.

## Files

- `validate-copilot-session.sh` - Main validation script that checks Copilot compliance
- `README.md` - This documentation

## Key Features

### Workflow Log Analysis ⭐ NEW
The validation now examines actual Copilot workflow run logs to verify:
- **Direct Evidence**: Copilot reading `.github/.copilot-instructions.md`
- **Instruction Adherence**: Following specific patterns from the instructions
- **Process Validation**: Ensuring proper development workflow was followed

### PR Content Analysis
Traditional validation of PR artifacts including:
- **Code Changes**: Functional programming patterns and best practices
- **Comments**: Evidence of following repository guidelines  
- **Descriptions**: Proper documentation and approach

## Usage

### Manual Validation
Run the validation script directly:
```bash
# Validate PR #3 (default)
.github/scripts/validate-copilot-session.sh

# Validate a specific PR
.github/scripts/validate-copilot-session.sh 5 bjhartin copilot-ai-scala-demo
```

### GitHub Actions
The validation runs automatically via the "CI-for-AI Validation" workflow, which can be triggered manually from the Actions tab.

## How It Works

### 1. Workflow Log Fetching
The script automatically:
1. **Identifies the PR branch** from GitHub API
2. **Finds the Copilot workflow** by name ("Copilot")
3. **Locates the latest run** for the PR branch by Copilot actor
4. **Downloads job logs** from the workflow run
5. **Scans logs for evidence** of instruction reading

### 2. Validation Criteria

#### Strong Pass (Workflow Evidence)
- **2+ workflow patterns** found indicating instruction reading
- Direct evidence of accessing `.github/.copilot-instructions.md`
- Evidence of following specific instruction patterns

#### Regular Pass (Combined Evidence)  
- **3+ total patterns** across workflow logs and PR content
- Mix of workflow evidence and output adherence

#### Failure
- **<3 total patterns** found
- No clear evidence of reading instructions

### 3. Search Patterns

#### Workflow Log Patterns
- Direct instruction file mentions: `.copilot-instructions`, `reading.*instructions`
- Instruction adherence: `Pure.*FP.*Approach`, `Test-Driven.*Development`
- Specific techniques: `cats.syntax.all`, `Resource.make`, `Property.*test.*first`

#### PR Content Patterns
- **FP Patterns**: cats, IO, Resource, F[_], FS2, ScalaCheck, property tests, munit
- **Proper Imports**: cats.syntax.all._, cats.effect.IO, fs2.*
- **TDD Evidence**: test-driven development patterns

## Adding New Validation Checks

To add new validation checks:

1. **Edit `validate-copilot-session.sh`**:
   - Add a new validation function following the pattern `validate_your_check()`
   - Call it from the `run_validations()` function
   - Return 0 for pass, 1 for fail

2. **Example new validation function**:
   ```bash
   validate_your_check() {
       echo "✅ Checking your custom rule..."
       
       if grep -i "your-pattern" "$ALL_CONTENT" > /dev/null 2>&1; then
           echo "   ✓ Found evidence of your rule"
           return 0
       else
           echo "   ❌ FAIL: Your rule not followed"
           return 1
       fi
   }
   ```

3. **Add it to the validation runner**:
   ```bash
   # In run_validations() function
   if ! validate_your_check; then
       exit_code=1
   fi
   ```

## Current Validation Rules

### Instructions Compliance ⭐ ENHANCED
**Primary Check**: Scans Copilot workflow logs for evidence of reading `.github/.copilot-instructions.md`

**Workflow Evidence Patterns**:
- Direct file access: `.github/.copilot-instructions.md`, `copilot-instructions.md`
- Instruction following: `Pure FP Approach`, `Test-Driven Development`
- Technical patterns: `cats.syntax.all`, `Resource.make`, `ScalaCheck`

**PR Content Fallback Patterns**:
- **FP Patterns**: cats, IO, Resource, F[_], FS2, ScalaCheck, property tests, munit
- **Proper Imports**: cats.syntax.all._, cats.effect.IO, fs2.*
- **TDD Evidence**: test-driven development patterns

**Pass Criteria**: 
- **Strong Pass**: 2+ workflow log patterns
- **Regular Pass**: 3+ combined patterns

### TDD Validation ⭐ NEW
**Primary Check**: Validates proper Test-Driven Development workflow by examining commits

**Process**:
1. **Identifies commits** with TDD tags: "#red", "#green", and "#refactor"
2. **Randomly selects** one commit of each type from the latest Copilot session
3. **Tests behavior**: 
   - Checks out "#red" commits and asserts that at least one test fails
   - Checks out "#green" commits and asserts that no tests fail
4. **Minimal code**: Uses efficient git operations and test execution
5. **Graceful handling**: Skips validation if TDD commits are not found

**Pass Criteria**:
- Tests fail on selected "#red" commit (as expected for TDD red phase)
- Tests pass on selected "#green" commit (as expected for TDD green phase)

### Development Practices
Checks for:
- **Test Coverage**: Evidence of test cases, specs, properties
- **Incremental Development**: Minimal changes, backward compatibility

## Environment Variables

- `GITHUB_TOKEN` - Required for API access (provided by GitHub Actions)
- `PR_NUMBER` - PR to validate (default: 3)
- `REPO_OWNER` - Repository owner (default: bjhartin)  
- `REPO_NAME` - Repository name (default: copilot-ai-scala-demo)

## Exit Codes

- `0` - All validations passed
- `1` - One or more validations failed

## Troubleshooting

### No Workflow Logs Found
If the validation shows "No matching Copilot workflow runs found":
1. Verify the PR branch has an associated Copilot workflow run
2. Check that the workflow name is exactly "Copilot"
3. Ensure the actor for the run is "Copilot"

### API Rate Limits
If you encounter rate limiting:
1. Use a personal access token with appropriate permissions
2. Reduce validation frequency
3. Check GitHub API quota usage