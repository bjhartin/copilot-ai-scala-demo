# CI-for-AI Validation Scripts

This directory contains scripts to validate that Copilot sessions follow established rules and best practices.

## Files

- `validate-copilot-session.sh` - Main validation script that checks Copilot compliance
- `test-validation.sh` - Test script to validate the validation logic locally
- `README.md` - This documentation

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

4. **Test your changes**:
   - Update `test-validation.sh` with appropriate test content
   - Run `./test-validation.sh` to verify your validation works

## Current Validation Rules

### Instructions Compliance
Checks if Copilot read `.github/.copilot-instructions.md` by looking for:
- **FP Patterns**: cats, IO, Resource, F[_], FS2, ScalaCheck, property tests, munit
- **Proper Imports**: cats.syntax.all._, cats.effect.IO, fs2.*
- **TDD Evidence**: test-driven development patterns
- **FP Approach**: functional programming mentions

**Pass Criteria**: At least 3 patterns must be found

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