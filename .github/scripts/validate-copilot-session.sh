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
WORKFLOW_LOGS="${TEMP_DIR}/workflow_logs.txt"

echo "🔍 Validating Copilot session on PR #${PR_NUMBER}"

# Function to fetch Copilot workflow logs
fetch_copilot_workflow_logs() {
    echo "🔍 Searching for Copilot workflow runs..."
    
    # First, get the PR branch name
    local pr_branch=$(jq -r '.head.ref' "$PR_DATA" 2>/dev/null || echo "")
    if [ -z "$pr_branch" ]; then
        echo "⚠️  Could not determine PR branch, fetching PR data first..."
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
             -H "Accept: application/vnd.github.v3+json" \
             "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DATA"
        pr_branch=$(jq -r '.head.ref' "$PR_DATA")
    fi
    
    echo "📝 PR branch: $pr_branch"
    
    # Find the Copilot workflow ID by name
    local workflows_response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows")
    
    local copilot_workflow_id=$(echo "$workflows_response" | jq -r '.workflows[] | select(.name == "Copilot") | .id')
    
    if [ -z "$copilot_workflow_id" ] || [ "$copilot_workflow_id" = "null" ]; then
        echo "⚠️  No Copilot workflow found, skipping workflow log analysis"
        echo "" > "$WORKFLOW_LOGS"
        return 0
    fi
    
    echo "🔍 Found Copilot workflow ID: $copilot_workflow_id"
    
    # Get workflow runs for this workflow, filtered by branch
    local runs_response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows/${copilot_workflow_id}/runs?branch=${pr_branch}&per_page=10")
    
    # Find the most recent run that matches our criteria
    local latest_run_id=$(echo "$runs_response" | jq -r '
        .workflow_runs[] | 
        select(.head_branch == "'"$pr_branch"'" and .actor.login == "Copilot") |
        .id' | head -n1)
    
    if [ -z "$latest_run_id" ] || [ "$latest_run_id" = "null" ]; then
        echo "⚠️  No matching Copilot workflow runs found for branch $pr_branch"
        echo "" > "$WORKFLOW_LOGS"
        return 0
    fi
    
    echo "📋 Found latest Copilot run ID: $latest_run_id"
    
    # Get the workflow run details
    local run_details=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${latest_run_id}")
    
    local run_title=$(echo "$run_details" | jq -r '.display_title // .name // ""')
    echo "🏷️  Run title: $run_title"
    
    # Get the jobs for this run
    local jobs_response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${latest_run_id}/jobs")
    
    # Fetch logs for all jobs in this run
    echo "📥 Downloading workflow logs..."
    echo "=== COPILOT WORKFLOW LOGS ===" > "$WORKFLOW_LOGS"
    echo "Run: $run_title (ID: $latest_run_id)" >> "$WORKFLOW_LOGS"
    echo "Branch: $pr_branch" >> "$WORKFLOW_LOGS"
    echo "================================" >> "$WORKFLOW_LOGS"
    
    local job_ids=$(echo "$jobs_response" | jq -r '.jobs[].id')
    
    for job_id in $job_ids; do
        local job_name=$(echo "$jobs_response" | jq -r ".jobs[] | select(.id == $job_id) | .name")
        echo "" >> "$WORKFLOW_LOGS"
        echo "--- Job: $job_name (ID: $job_id) ---" >> "$WORKFLOW_LOGS"
        
        # Download job logs
        local logs_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/jobs/${job_id}/logs"
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
             -H "Accept: application/vnd.github.v3+json" \
             "$logs_url" >> "$WORKFLOW_LOGS" 2>/dev/null || echo "Could not fetch logs for job $job_id" >> "$WORKFLOW_LOGS"
    done
    
    echo "✅ Workflow logs downloaded successfully"
}

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

# Fetch Copilot workflow logs
echo "📥 Fetching Copilot workflow logs..."
fetch_copilot_workflow_logs

# Combine all content for validation
ALL_CONTENT="${TEMP_DIR}/all_content.txt"
{
    echo "=== COPILOT WORKFLOW LOGS ==="
    cat "$WORKFLOW_LOGS"
    echo -e "\n=== PR DESCRIPTION ==="
    jq -r '.body // ""' "$PR_DATA"
    echo -e "\n=== PR COMMENTS ==="
    jq -r '.[] | select(.user.login == "Copilot") | .body' "$PR_COMMENTS"
    echo -e "\n=== PR DIFF ==="
    cat "$PR_DIFF"
} > "$ALL_CONTENT"

# Validation functions
validate_instructions_read() {
    echo "✅ Checking if Copilot read .github/.copilot-instructions.md..."
    
    # First check the workflow logs for direct evidence
    local workflow_evidence=0
    if [ -s "$WORKFLOW_LOGS" ]; then
        echo "   🔍 Scanning workflow logs for instruction-reading evidence..."
        
        # Look for direct mentions of reading instructions
        if grep -i -E "(\.copilot-instructions|copilot.*instructions|reading.*instructions)" "$WORKFLOW_LOGS" > /dev/null 2>&1; then
            echo "   ✓ Found direct reference to reading Copilot instructions in workflow logs"
            ((workflow_evidence++))
        fi
        
        # Look for evidence of following the specific instruction patterns from the file
        local instruction_patterns=(
            "Pure.*FP.*Approach"
            "Test-Driven.*Development"
            "cats\.syntax\.all"
            "Resource\.make"
            "MonadError|ApplicativeError"
            "ScalaCheck.*munit"
            "Property.*test.*first"
        )
        
        for pattern in "${instruction_patterns[@]}"; do
            if grep -i -E "$pattern" "$WORKFLOW_LOGS" > /dev/null 2>&1; then
                echo "   ✓ Found evidence of following instruction pattern: $pattern"
                ((workflow_evidence++))
            fi
        done
        
        # Check for evidence of reading the actual instruction file
        if grep -i -E "\.github/\.copilot-instructions\.md|copilot-instructions\.md" "$WORKFLOW_LOGS" > /dev/null 2>&1; then
            echo "   ✓ Found evidence of accessing .copilot-instructions.md file"
            ((workflow_evidence += 2))  # This is strong evidence
        fi
    else
        echo "   ⚠️  No workflow logs available for analysis"
    fi
    
    # Also check for evidence of following FP principles from instructions in PR content
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
    
    # Combine evidence from workflow logs and PR content
    local total_evidence=$((workflow_evidence + found_patterns))
    
    if [ $workflow_evidence -ge 2 ]; then
        echo "   🎉 STRONG PASS: Found strong evidence in workflow logs that Copilot read instructions ($workflow_evidence patterns)"
        return 0
    elif [ $total_evidence -ge 3 ]; then
        echo "   ✅ PASS: Found sufficient evidence Copilot followed instructions (workflow: $workflow_evidence, content: $found_patterns patterns)"
        return 0
    else
        echo "   ❌ FAIL: Insufficient evidence Copilot read instructions (workflow: $workflow_evidence, content: $found_patterns patterns found)"
        echo "   💡 Expected to find evidence in workflow logs of reading .github/.copilot-instructions.md"
        return 1
    fi
}

# EXAMPLE: Add more validation functions here as needed
# validate_custom_rule() {
#     echo "✅ Checking custom rule..."
#     if grep -i "your-pattern" "$ALL_CONTENT" > /dev/null 2>&1; then
#         echo "   ✓ Found evidence of your custom rule"
#         return 0
#     else
#         echo "   ❌ FAIL: Custom rule not followed"
#         return 1
#     fi
# }

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
    
    # EXAMPLE: Uncomment and modify to add new validation
    # if ! validate_custom_rule; then
    #     exit_code=1
    # fi
    
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