#!/bin/bash

# Test validation script with content that should FAIL validation
set -e

echo "🔍 Testing validation against content that should FAIL"

# Create test content that doesn't follow instructions
TEMP_DIR=$(mktemp -d)
ALL_CONTENT="${TEMP_DIR}/all_content.txt"

# Simulate PR content that doesn't follow FP guidelines
cat > "$ALL_CONTENT" << 'EOF'
=== PR DESCRIPTION ===
Added some basic functionality using imperative programming.

## Changes Made
- Modified the application using var and mutable state
- Used traditional Java patterns instead of functional approach
- No tests added

## Implementation
Just used standard Java-style programming with exceptions and null values.
EOF

# Run validation (copied from test-validation.sh)
validate_instructions_read() {
    echo "✅ Checking if Copilot read .github/.copilot-instructions.md..."
    
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
    
    if grep -E "import cats\.syntax\.all\._|cats\.effect\.IO|fs2\." "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found proper imports following instructions"
        ((found_patterns++))
    fi
    
    if grep -i -E "test.*before.*implement|property.*test|ScalaCheck|test.*case|spec" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of test-driven development"
        ((found_patterns++))
    fi
    
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

echo "🔍 Running test validation..."
echo "================================"

if ! validate_instructions_read; then
    echo "================================"
    echo "❌ Validation correctly FAILED (as expected)"
    rm -rf "$TEMP_DIR"
    exit 0
else
    echo "================================"
    echo "🚨 ERROR: Validation should have failed but didn't!"
    rm -rf "$TEMP_DIR"
    exit 1
fi