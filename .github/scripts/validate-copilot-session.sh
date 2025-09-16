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
    
    # Store session metadata for TDD validation
    echo "$run_details" > "${TEMP_DIR}/run_details.json"
    
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
    
    # Extract session start time from workflow run details (silent operation)
    local session_start_time=""
    if [ -f "${TEMP_DIR}/run_details.json" ]; then
        session_start_time=$(jq -r '.run_started_at // .created_at' "${TEMP_DIR}/run_details.json" 2>/dev/null)
        
        # Fallback to extracting from logs if needed
        if [ -z "$session_start_time" ] || [ "$session_start_time" = "null" ]; then
            if [ -f "$WORKFLOW_LOGS" ] && [ -s "$WORKFLOW_LOGS" ]; then
                session_start_time=$(grep -E "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z" "$WORKFLOW_LOGS" | head -1 | cut -d' ' -f1)
            fi
        fi
    fi
    
    # Get all commits from the PR
    local pr_commits=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}/commits")
    
    # Filter commits to only those made during or after the Copilot session
    local filtered_commits="$pr_commits"
    if [ -n "$session_start_time" ] && [ "$session_start_time" != "null" ]; then
        local session_timestamp=$(date -d "$session_start_time" +%s 2>/dev/null || echo "")
        if [ -n "$session_timestamp" ]; then
            filtered_commits=$(echo "$pr_commits" | jq --argjson session_ts "$session_timestamp" '
                [.[] | select(
                    (.commit.author.date | fromdateiso8601) >= $session_ts or
                    (.commit.committer.date | fromdateiso8601) >= $session_ts
                )]')
        fi
    fi
    
    # Count session commits and show summary
    local session_commits=$(echo "$filtered_commits" | jq '. | length')
    echo "   📊 Found $session_commits commits in this copilot session"
    
    # Extract commits with TDD tags from the filtered set
    local red_commits=$(echo "$filtered_commits" | jq -r '.[] | select(.commit.message | contains("#red")) | .sha')
    local green_commits=$(echo "$filtered_commits" | jq -r '.[] | select(.commit.message | contains("#green")) | .sha')
    
    local red_count=$(echo "$red_commits" | grep -c . || echo "0")
    local green_count=$(echo "$green_commits" | grep -c . || echo "0")
    
    local tdd_exit_code=0
    
    # Check if we have required commits and fail if missing
    if [ -z "$red_commits" ]; then
        echo "   ❌ No #red commits found - TDD validation failed"
        tdd_exit_code=1
    fi
    
    if [ -z "$green_commits" ]; then
        echo "   ❌ No #green commits found - TDD validation failed"
        tdd_exit_code=1
    fi
    
    # Exit early if missing required commits
    if [ $tdd_exit_code -eq 1 ]; then
        return 1
    fi
    
    # Save current state for testing
    local current_commit=$(git rev-parse HEAD)
    
    # Test red commit - should have failing tests
    local selected_red=$(echo "$red_commits" | shuf -n 1)
    git checkout "$selected_red" --quiet
    
    if source dev.env > /dev/null 2>&1 && sbt test > "${TEMP_DIR}/red_test_output.log" 2>&1; then
        echo "   ❌ $red_count #red commits, tests pass at sampled commit"
        tdd_exit_code=1
    else
        echo "   ✅ $red_count #red commits, tests fail at sampled commit"
    fi
    
    # Test green commit - should have passing tests
    local selected_green=$(echo "$green_commits" | shuf -n 1)
    git checkout "$selected_green" --quiet
    
    if source dev.env > /dev/null 2>&1 && sbt test > "${TEMP_DIR}/green_test_output.log" 2>&1; then
        echo "   ✅ $green_count #green commits, tests pass at sampled commit"
    else
        echo "   ❌ $green_count #green commits, tests fail at sampled commit"
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
