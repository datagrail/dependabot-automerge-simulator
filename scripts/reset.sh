#!/usr/bin/env bash
# reset.sh — Reset main to the baseline branch state (vulnerable deps + app code),
# then request Dependabot recreate its open PRs against the reset main.
#
# Usage: ./scripts/reset.sh
# Requires: gh CLI authenticated with write access to the repo.

set -euo pipefail

REPO="datagrail/dependabot-automerge-simulator"

echo "=== Disabling 'main' branch ruleset ==="
RULESET_ID=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "main") | .id')
if [ -z "$RULESET_ID" ]; then
  echo "  ERROR: Could not find a ruleset named 'main'. Aborting." >&2
  exit 1
fi
echo "  Ruleset ID: $RULESET_ID — disabling..."
gh api --method PUT "repos/$REPO/rulesets/$RULESET_ID" \
  --field enforcement=disabled > /dev/null

echo ""
echo "=== Force-merging open Dependabot PRs ==="
DEPENDABOT_PRS=$(gh pr list --repo "$REPO" --author "app/dependabot" --state open --json number,title --jq '.[] | "\(.number)\t\(.title)"')
if [ -z "$DEPENDABOT_PRS" ]; then
  echo "  No open Dependabot PRs found."
else
  while IFS=$'\t' read -r pr_number pr_title; do
    echo "  Merging PR #$pr_number: $pr_title"
    gh pr merge "$pr_number" --repo "$REPO" --merge --admin --delete-branch 2>&1 | sed 's/^/    /'
  done <<< "$DEPENDABOT_PRS"
fi

echo ""
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
echo "=== Re-enabling 'main' branch ruleset ==="
gh api --method PUT "repos/$REPO/rulesets/$RULESET_ID" \
  --field enforcement=active > /dev/null
echo "  Ruleset 'main' re-enabled."

echo ""
echo "=== Done ==="
echo ""
echo "Dependabot will recreate each PR against the reset main branch."
