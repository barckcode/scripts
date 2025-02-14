#!/bin/bash

# Verify Auth
if ! gh auth status &> /dev/null; then
    echo "You are not authenticated in GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Format: owner/repo
REPOS_FILE="repos.txt"

# Rulesets
# examples: https://github.com/github/ruleset-recipes/tree/main
EXAMPLE_RULESET="example.json"

# Iterate over each repository
while IFS= read -r repo; do
    echo "Applying rulesets to $repo..."

    # Apply each ruleset
    echo "Applying example ruleset..."
    gh api --method POST "/repos/${repo}/rulesets" --input "$EXAMPLE_RULESET"

    echo "Rulesets applied to $repo"
    echo "----------------------------------------"
done < "$REPOS_FILE"

echo "Process completed!"
