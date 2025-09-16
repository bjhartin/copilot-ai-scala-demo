#!/bin/bash

# CI-for-AI Validation Script
# Validates that Copilot sessions follow established rules and use appropriate tools

set -e

PR_NUMBER=${1:-3}
REPO_OWNER=${2:-bjhartin}
REPO_NAME=${3:-copilot-ai-scala-demo}

echo "🔍 Reviewing latest Copilot session on PR #${PR_NUMBER}"

# Create temporary files for validation data
TEMP_DIR=$(mktemp -d)
PR_DATA="${TEMP_DIR}/pr_data.json"
WORKFLOW_LOGS="${TEMP_DIR}/workflow_logs.txt"

# Function to fetch Copilot workflow logs
fetch_copilot_workflow_logs() {
    # First, get the PR branch name
    local pr_branch=$(jq -r '.head.ref' "$PR_DATA" 2>/dev/null || echo "")
    if [ -z "$pr_branch" ]; then
        echo "⚠️  Could not determine PR branch, fetching PR data first..."
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
             -H "Accept: application/vnd.github.v3+json" \
             "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DATA"
        pr_branch=$(jq -r '.head.ref' "$PR_DATA")
    fi
    
    # Find the Copilot workflow ID by name
    local workflows_response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows")
    
    local copilot_workflow_id=$(echo "$workflows_response" | jq -r '.workflows[] | select(.name == "Copilot") | .id')
    
    if [ -z "$copilot_workflow_id" ] || [ "$copilot_workflow_id" = "null" ]; then
        echo "⚠️  No Copilot workflow found"
        exit 1
    fi
    
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
    
    # Get the workflow run details
    local run_details=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${latest_run_id}")

    echo "..Copilot session: $(echo $run_details | jq -r '.html_url')"
    
    local run_title=$(echo "$run_details" | jq -r '.display_title // .name // ""')
    
    # Get the jobs for this run
    local jobs_response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${latest_run_id}/jobs")
    
    # Fetch logs for all jobs in this run
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

	curl -s -L -H "Authorization: token ${GITHUB_TOKEN}" \
             -H "Accept: application/vnd.github.v3+json" \
             "$logs_url" >> "$WORKFLOW_LOGS" 
    done

    echo "✓ Workflow logs downloaded successfully"
    echo "...$(cat $WORKFLOW_LOGS | wc -l) lines found"
}

# Fetch minimal PR data needed for workflow log fetching
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}" > "$PR_DATA"

# Fetch Copilot workflow logs (focus only on session logs)
echo "📥 Fetching Copilot workflow logs..."
fetch_copilot_workflow_logs

# Validation functions
validate_instructions_read() {
    echo "🔍 Checking if Copilot read .github/.copilot-instructions.md..."
    
    if grep -i -P "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z copilot: ✓ I have read and understood the .github/.copilot-instructions.md guidelines and will follow them.$" "$WORKFLOW_LOGS" > /dev/null 2>&1; then
        echo "   ✅ PASS"
        return 0
    else
        echo "   ❌ FAIL"
        return 1
    fi
}

 validate_environment_setup() {
     echo "🔍 Checking if development environment was set up"
     if grep -i -P "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z Copilot development environment set up successfully\.$" "$WORKFLOW_LOGS" > /dev/null 2>&1; then
         echo "   ✅ PASS"
         return 0
     else
         echo "   ❌ FAIL"
         return 1
     fi
 }

check_tdd() {
    echo "🔍 Checking TDD process compliance..."
    
    # Get all commits from the PR
    local pr_commits=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}/commits")
    
    # Extract commits with TDD tags
    local red_commits=$(echo "$pr_commits" | jq -r '.[] | select(.commit.message | contains("#red")) | .sha')
    local green_commits=$(echo "$pr_commits" | jq -r '.[] | select(.commit.message | contains("#green")) | .sha')
    local refactor_commits=$(echo "$pr_commits" | jq -r '.[] | select(.commit.message | contains("#refactor")) | .sha')
    
    # Check if we have commits of each type
    if [ -z "$red_commits" ]; then
        echo "   ⚠️  No #red commits found - skipping TDD validation"
        return 0
    fi
    
    if [ -z "$green_commits" ]; then
        echo "   ⚠️  No #green commits found - skipping TDD validation"
        return 0
    fi
    
    echo "   📋 Found $(echo "$red_commits" | wc -w) #red commits"
    echo "   📋 Found $(echo "$green_commits" | wc -w) #green commits"
    echo "   📋 Found $(echo "$refactor_commits" | wc -w) #refactor commits"
    
    # Randomly select one commit of each type
    local selected_red=$(echo "$red_commits" | shuf -n 1)
    local selected_green=$(echo "$green_commits" | shuf -n 1)
    
    echo "   🎲 Testing red commit: $selected_red"
    echo "   🎲 Testing green commit: $selected_green"
    
    # Save current state
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    local current_commit=$(git rev-parse HEAD)
    
    local tdd_exit_code=0
    
    # Test red commit - should have failing tests
    echo "   🔴 Checking out red commit and running tests..."
    git checkout "$selected_red" --quiet
    
    # Source dev environment and run tests, capture output
    if source dev.env > /dev/null 2>&1 && sbt test > "${TEMP_DIR}/red_test_output.log" 2>&1; then
        echo "   ❌ FAIL: Tests passed on #red commit (should fail)"
        tdd_exit_code=1
    else
        echo "   ✅ PASS: Tests failed on #red commit as expected"
    fi
    
    # Test green commit - should have passing tests
    echo "   🟢 Checking out green commit and running tests..."
    git checkout "$selected_green" --quiet
    
    if source dev.env > /dev/null 2>&1 && sbt test > "${TEMP_DIR}/green_test_output.log" 2>&1; then
        echo "   ✅ PASS: Tests passed on #green commit as expected"
    else
        echo "   ❌ FAIL: Tests failed on #green commit (should pass)"
        tdd_exit_code=1
    fi
    
    # Restore original state
    git checkout "$current_commit" --quiet
    
    return $tdd_exit_code
}

# Main validation runner
run_validations() {
    local exit_code=0
    
    # Core validation: Did Copilot read instructions?
    if ! validate_instructions_read; then
        exit_code=1
    fi
    
    if ! validate_environment_setup; then
        exit_code=1
     fi
    
    # TDD validation
    if ! check_tdd; then
        exit_code=1
    fi
    
    # Cleanup
    #rm -rf "$TEMP_DIR"
    echo "Logs are in $TEMP_DIR"
    
    return $exit_code
}

# Run the validations
run_validations
