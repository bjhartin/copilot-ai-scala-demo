#!/bin/bash

# CI-for-AI Validation Script
# Validates that Copilot sessions follow established rules and use appropriate tools

set -e

PR_NUMBER=${1:-3}
REPO_OWNER=${2:-bjhartin}
REPO_NAME=${3:-copilot-ai-scala-demo}

echo "🔍 Validating Copilot session on PR #${PR_NUMBER}"

# Create temporary files for validation data
TEMP_DIR=$(mktemp -d)
PR_DATA="${TEMP_DIR}/pr_data.json"
PR_COMMENTS="${TEMP_DIR}/pr_comments.json"
PR_DIFF="${TEMP_DIR}/pr_diff.txt"

# Fetch PR data using GitHub API
echo "📥 Fetching PR data..."
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DATA"

curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" > "$PR_COMMENTS"

curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github.v3.diff" \
     "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DIFF"

# Combine all content for validation
ALL_CONTENT="${TEMP_DIR}/all_content.txt"
{
    echo "=== PR DESCRIPTION ==="
    jq -r '.body // ""' "$PR_DATA"
    echo -e "\n=== PR COMMENTS ==="
    jq -r '.[] | select(.user.login == "Copilot") | .body' "$PR_COMMENTS"
    echo -e "\n=== PR DIFF ==="
    cat "$PR_DIFF"
} > "$ALL_CONTENT"

# Validation functions
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
    if grep -i -E "test.*before.*implement|property.*test|ScalaCheck" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of test-driven development"
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

# Add more validation functions here as needed
validate_proper_development_practices() {
    echo "✅ Checking proper development practices..."
    
    # Check for evidence of testing
    if grep -i -E "test.*case|spec|property" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of test coverage"
    else
        echo "   ⚠️  No clear evidence of testing found"
    fi
    
    # Check for evidence of incremental development
    if grep -i -E "minimal.*chang|small.*chang|incremental" "$ALL_CONTENT" > /dev/null 2>&1; then
        echo "   ✓ Found evidence of minimal/incremental changes"
    fi
    
    echo "   ✅ Development practices check completed"
    return 0
}

# Main validation runner
run_validations() {
    local exit_code=0
    
    echo "🔍 Running validation checks..."
    echo "================================"
    
    # Core validation: Did Copilot read instructions?
    if ! validate_instructions_read; then
        exit_code=1
    fi
    
    echo ""
    
    # Additional validations (non-failing for now)
    validate_proper_development_practices
    
    echo "================================"
    
    if [ $exit_code -eq 0 ]; then
        echo "🎉 All validations PASSED"
    else
        echo "❌ Some validations FAILED"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    return $exit_code
}

# Run the validations
run_validations