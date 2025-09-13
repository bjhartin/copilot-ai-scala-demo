#!/bin/bash

# Test validation script using local data from GitHub API calls
set -e

echo "🔍 Testing validation against PR #3 content"

# Create test content from what we know about PR #3
TEMP_DIR=$(mktemp -d)
ALL_CONTENT="${TEMP_DIR}/all_content.txt"

# Simulate the PR content we saw from GitHub API
cat > "$ALL_CONTENT" << 'EOF'
=== PR DESCRIPTION ===
Implements the `--about` and `--help` CLI flags for the hello-world application. The `--about` flag prints a description of the repository's purpose, while the `--help` flag displays comprehensive usage information.

## Changes Made

- **Modified `hello-world/Main.scala`**: Added pattern matching to check for `--about` and `--help` as the first argument
- **Added test coverage**: New test cases in `MainSpec.scala` to verify both flag functionalities
- **Preserved backward compatibility**: All existing functionality remains unchanged

## Usage

```bash
# Show about information
sbt "helloWorld/run --about"
# Output: This application exists as part of a repository which is a demonstration of how to use copilot agent in the cloud.

# Show help information
sbt "helloWorld/run --help"
# Output: Usage information with available options and examples

# Existing functionality still works
sbt "helloWorld/run"          # Output: Hello, World!
sbt "helloWorld/run Alice"    # Output: Hello, Alice!
```

## Implementation Details

The implementation uses a simple pattern match on the first argument. When `--about` or `--help` is detected, it prints the appropriate message using the existing FS2 streaming approach, maintaining consistency with the application's functional programming style.

The `--help` flag provides comprehensive usage information including:
- Usage syntax and description
- Available arguments (NAME parameter)
- Available options (--about, --help)
- Practical examples with expected outputs

All tests pass (8 total tests including the new `--about` and `--help` test cases).

Fixes #2.

=== PR COMMENTS ===
I've implemented the `--help` flag functionality in commit d37cc5d. The help output includes comprehensive usage information, available arguments and options, plus practical examples. The implementation follows the existing FS2 streaming pattern and maintains consistency with the functional programming style used throughout the codebase.

=== PR DIFF ===
diff --git a/hello-world/src/main/scala/com/bjhartin/helloworld/Main.scala b/hello-world/src/main/scala/com/bjhartin/helloworld/Main.scala
index abc123..def456 100644
--- a/hello-world/src/main/scala/com/bjhartin/helloworld/Main.scala
+++ b/hello-world/src/main/scala/com/bjhartin/helloworld/Main.scala
@@ -1,6 +1,8 @@
 package com.bjhartin.helloworld
 
 import cats.effect.{IO, IOApp}
+import cats.syntax.all._
 import fs2.{Stream, text}
+import fs2.io.stdout
 
 object Main extends IOApp.Simple {
EOF

# Run validation functions
validate_instructions_read() {
    echo "✅ Checking if Copilot read .github/.copilot-instructions.md..."
    
    # Check for evidence of following FP principles from instructions
    local fp_patterns=(
        "cats"
        "IO" 
        "Resource"
        "F\[_\]"
        "FS2"
        "ScalaCheck"
        "property.*test"
        "munit"
    )
    
    local found_patterns=0
    for pattern in "${fp_patterns[@]}"; do
        if grep -i -E "$pattern" "$ALL_CONTENT" > /dev/null 2>&1; then
            echo "   ✓ Found evidence of: $pattern"
            ((found_patterns++))
        fi
    done
    
    # Also check for imports that indicate following the style guide
    if grep -E "import cats\.syntax\.all\._|cats\.effect\.IO|fs2\." "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found proper imports following instructions"
        ((found_patterns++))
    fi
    
    # Check for test-driven development patterns
    if grep -i -E "test.*before.*implement|property.*test|ScalaCheck|test.*case|spec" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of test-driven development"
        ((found_patterns++))
    fi
    
    # Check for functional programming patterns mentioned in instructions
    if grep -i -E "functional.*programming|streaming.*approach|pattern.*match" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of FP approach"
        ((found_patterns++))
    fi
    
    if [ $found_patterns -ge 3 ]; then
        echo "   ✅ PASS: Found sufficient evidence Copilot followed instructions ($found_patterns patterns)"
        return 0
    else
        echo "   ❌ FAIL: Insufficient evidence Copilot read instructions (only $found_patterns patterns found)"
        return 1
    fi
}

validate_proper_development_practices() {
    echo "✅ Checking proper development practices..."
    
    # Check for evidence of testing
    if grep -i -E "test.*case|spec|property|test.*coverage" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of test coverage"
    else
        echo "   ⚠️  No clear evidence of testing found"
    fi
    
    # Check for evidence of incremental development
    if grep -i -E "minimal.*chang|small.*chang|incremental|compatibility.*preserved|backward.*compatibility" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of minimal/incremental changes"
    fi
    
    echo "   ✅ Development practices check completed"
    return 0
}

# Run validation
echo "🔍 Running test validation..."
echo "================================"

exit_code=0

if ! validate_instructions_read; then
    exit_code=1
fi

echo ""
validate_proper_development_practices

echo "================================"

if [ $exit_code -eq 0 ]; then
    echo "🎉 All validations PASSED"
else
    echo "❌ Some validations FAILED"
fi

# Cleanup
rm -rf "$TEMP_DIR"

exit $exit_code