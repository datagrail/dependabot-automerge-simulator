#!/usr/bin/env bash
# reset.sh — Reset main to the baseline branch state (vulnerable deps + app code),
# then request Dependabot recreate its open PRs against the reset main.
#
# Usage: ./scripts/reset.sh
# Requires: gh CLI authenticated with write access to the repo.

set -euo pipefail

REPO="datagrail/dependabot-automerge-simulator"

echo "=== Fetching latest from origin ==="
git fetch origin

echo ""
echo "=== Resetting main to baseline file state ==="
git checkout main
git reset origin/main
git checkout origin/baseline -- .
# Update the last-reset date to trigger a Dependabot rescan
sed -i '' "s/^# last-reset: .*/# last-reset: $(date +%Y-%m-%dT%H:%M:%S)/" .github/dependabot.yml
git add -A
git commit -m "Reset: restore baseline state ($(date +%Y-%m-%d))"
git push origin main
echo "  main is now at $(git rev-parse --short HEAD)."

echo ""
echo "=== Requesting Dependabot recreate open PRs ==="
OPEN_PRS=$(gh pr list --repo "$REPO" --author "app/dependabot" --state open \
  --json number,title \
  | jq -r '.[] | [(.number|tostring), .title] | @tsv')

if [ -z "$OPEN_PRS" ]; then
  echo "  No open Dependabot PRs found."
else
  while IFS=$'\t' read -r number title; do
    echo "  PR #$number: $title"
    echo "    Removing labels..."
    gh pr edit "$number" --repo "$REPO" --remove-label "dependabot-automerge" 2>/dev/null || true
    gh pr edit "$number" --repo "$REPO" --remove-label "Human Needed" 2>/dev/null || true
    echo "    Commenting @dependabot recreate"
    gh pr comment "$number" --repo "$REPO" --body "@dependabot recreate"
  done <<< "$OPEN_PRS"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Dependabot will recreate each PR against the reset main branch."
