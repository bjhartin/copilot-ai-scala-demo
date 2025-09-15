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

# Fetch minimal PR data needed for workflow log fetching
echo "📥 Fetching minimal PR data for branch identification..."
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DATA"

# Fetch Copilot workflow logs (focus only on session logs)
echo "📥 Fetching Copilot workflow logs..."
fetch_copilot_workflow_logs

echo "✅ Workflow logs obtained, focusing validation on session logs only"

# Validation functions
validate_instructions_read() {
    echo "✅ Checking if Copilot read .github/.copilot-instructions.md..."
    
    # Only check the workflow logs for evidence - PR content checks disabled per user request
    local workflow_evidence=0
    local workflow_run_url=""
    if [ -s "$WORKFLOW_LOGS" ]; then
        echo "   🔍 Scanning workflow logs for instruction-reading evidence..."
        
        # Extract workflow run info for URL construction
        local run_id=$(grep "Run.*ID:" "$WORKFLOW_LOGS" | head -1 | sed 's/.*ID: \([0-9]*\).*/\1/' 2>/dev/null || echo "")
        if [ -n "$run_id" ]; then
            workflow_run_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/actions/runs/${run_id}"
        fi
        
        # Look for the required acknowledgment first
        echo "   🔍 Looking for explicit acknowledgment of reading instructions..."
        local acknowledgment_matches=$(grep -i -n -E "(I have read.*understood.*copilot.*instructions|✓.*read.*understood.*guidelines)" "$WORKFLOW_LOGS" 2>/dev/null || true)
        if [ -n "$acknowledgment_matches" ]; then
            echo "   ✓ Found explicit acknowledgment of reading Copilot instructions:"
            echo "$acknowledgment_matches" | head -3 | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local line_num=$(echo "$line" | cut -d: -f1)
                    local content=$(echo "$line" | cut -d: -f2-)
                    # Trim whitespace without xargs to avoid errors
                    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    echo "     > Line $line_num: $content"
                    if [ -n "$workflow_run_url" ]; then
                        echo "     > Source: $workflow_run_url"
                    fi
                fi
            done
            ((workflow_evidence += 3))  # Strong evidence - explicit acknowledgment
        fi
        
        # Look for direct mentions of reading instructions with enhanced detail
        echo "   🔍 Looking for direct mentions of reading .copilot-instructions.md..."
        local instruction_matches=$(grep -i -n -E "(\.copilot-instructions|copilot.*instructions|reading.*instructions)" "$WORKFLOW_LOGS" 2>/dev/null || true)
        if [ -n "$instruction_matches" ]; then
            echo "   ✓ Found direct reference to reading Copilot instructions in workflow logs:"
            echo "$instruction_matches" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local line_num=$(echo "$line" | cut -d: -f1)
                    local content=$(echo "$line" | cut -d: -f2-)
                    # Trim whitespace without xargs to avoid errors
                    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    echo "     > Line $line_num: $content"
                    if [ -n "$workflow_run_url" ]; then
                        echo "     > Source: $workflow_run_url"
                    fi
                fi
            done
            ((workflow_evidence++))
        fi
        
        # Check for evidence of reading the actual instruction file with enhanced patterns
        echo "   🔍 Looking for evidence of accessing .copilot-instructions.md file..."
        local file_access_matches=$(grep -i -n -E "(\.github/\.copilot-instructions\.md|copilot-instructions\.md|str_replace_editor.*copilot.*instructions|view.*copilot.*instructions)" "$WORKFLOW_LOGS" 2>/dev/null || true)
        if [ -n "$file_access_matches" ]; then
            echo "   ✓ Found evidence of accessing .copilot-instructions.md file:"
            echo "$file_access_matches" | head -5 | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local line_num=$(echo "$line" | cut -d: -f1)
                    local content=$(echo "$line" | cut -d: -f2-)
                    # Trim whitespace without xargs to avoid errors
                    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    echo "     > Line $line_num: $content"
                    if [ -n "$workflow_run_url" ]; then
                        echo "     > Source: $workflow_run_url"
                    fi
                fi
            done
            ((workflow_evidence += 2))  # This is strong evidence
        fi
        
        # Also check for tool call pattern specifically (multiline aware)
        echo "   🔍 Looking for str_replace_editor tool calls to .copilot-instructions.md..."
        local tool_call_matches=$(awk '
            /str_replace_editor/ { 
                in_tool_call = 1; 
                line_start = NR; 
                buffer = $0; 
                next; 
            } 
            in_tool_call && /copilot.*instructions\.md/ { 
                print line_start ":" buffer; 
                print NR ":" $0; 
                in_tool_call = 0; 
                next; 
            } 
            in_tool_call && /path:.*copilot.*instructions/ { 
                print line_start ":" buffer; 
                print NR ":" $0; 
                in_tool_call = 0; 
                next; 
            } 
            in_tool_call { 
                buffer = buffer "\n" $0; 
            } 
            !/^[[:space:]]*/ { 
                in_tool_call = 0; 
            }
        ' "$WORKFLOW_LOGS" 2>/dev/null || true)
        
        if [ -n "$tool_call_matches" ]; then
            echo "   ✓ Found str_replace_editor tool call accessing .copilot-instructions.md:"
            echo "$tool_call_matches" | head -5 | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local line_num=$(echo "$line" | cut -d: -f1)
                    local content=$(echo "$line" | cut -d: -f2-)
                    # Trim whitespace without xargs to avoid errors
                    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    echo "     > Line $line_num: $content"
                    if [ -n "$workflow_run_url" ]; then
                        echo "     > Source: $workflow_run_url"
                    fi
                fi
            done
            ((workflow_evidence += 2))  # This is strong evidence
        fi
        
        # Look for evidence of following the specific instruction patterns from the file
        echo "   🔍 Looking for evidence of following specific instruction patterns..."
        local instruction_patterns=(
            "Pure.*FP.*Approach"
            "Test-Driven.*Development" 
            "cats\.syntax\.all"
            "Resource\.make"
            "MonadError|ApplicativeError"
            "ScalaCheck.*munit"
            "Property.*test.*first"
            "str_replace_editor.*\.github.*copilot"
            "think.*tool.*plan"
        )
        
        for pattern in "${instruction_patterns[@]}"; do
            local pattern_matches=$(grep -i -n -E "$pattern" "$WORKFLOW_LOGS" 2>/dev/null || true)
            if [ -n "$pattern_matches" ]; then
                echo "   ✓ Found evidence of following instruction pattern: $pattern"
                echo "$pattern_matches" | head -3 | while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        local line_num=$(echo "$line" | cut -d: -f1)
                        local content=$(echo "$line" | cut -d: -f2-)
                        # Trim whitespace without xargs to avoid errors
                        content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                        echo "     > Line $line_num: $content"
                        if [ -n "$workflow_run_url" ]; then
                            echo "     > Source: $workflow_run_url"
                        fi
                    fi
                done
                ((workflow_evidence++))
            fi
        done
        
        # Look for specific tool usage patterns that indicate following instructions
        echo "   🔍 Looking for evidence of proper tool usage as instructed..."
        local tool_patterns=(
            "report_progress.*commit"
            "think.*tool.*before"
            "str_replace_editor.*view"
            "bash.*async.*false"
            "github-mcp-server"
        )
        
        for pattern in "${tool_patterns[@]}"; do
            local pattern_matches=$(grep -i -n -E "$pattern" "$WORKFLOW_LOGS" 2>/dev/null || true)
            if [ -n "$pattern_matches" ]; then
                echo "   ✓ Found evidence of proper tool usage: $pattern"
                echo "$pattern_matches" | head -2 | while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        local line_num=$(echo "$line" | cut -d: -f1)
                        local content=$(echo "$line" | cut -d: -f2-)
                        # Trim whitespace and limit length
                        content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -c 100)
                        echo "     > Line $line_num: $content..."
                        if [ -n "$workflow_run_url" ]; then
                            echo "     > Source: $workflow_run_url"
                        fi
                    fi
                done
                ((workflow_evidence++))
            fi
        done
        
    else
        echo "   ⚠️  No workflow logs available for analysis"
    fi
    
    echo ""
    echo "📊 Evidence Summary (Workflow Logs Only):"
    echo "   • Workflow log evidence: $workflow_evidence patterns found"
    echo "   • PR content evidence: DISABLED (focusing on session logs only)"
    
    if [ $workflow_evidence -ge 2 ]; then
        echo "   🎉 PASS: Found sufficient evidence in workflow logs that Copilot read instructions ($workflow_evidence patterns)"
        return 0
    else
        echo "   ❌ FAIL: Insufficient evidence Copilot read instructions in workflow logs ($workflow_evidence patterns found)"
        echo "   💡 Expected to find at least 2 patterns in workflow logs indicating Copilot read .github/.copilot-instructions.md"
        echo "   💡 Look for: file access, instruction mentions, proper tool usage, or specific patterns"
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