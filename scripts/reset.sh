#!/usr/bin/env bash
# reset.sh — Close all open Dependabot PRs and request recreates so fresh PRs
# are created by Dependabot on its next scan.
#
# Usage: ./scripts/reset.sh
# Requires: gh CLI authenticated with write access to the repo.

set -euo pipefail

REPO="datagrail/dependabot-automerge-simulator"

echo "=== Fetching open Dependabot PRs ==="
OPEN_PRS=$(gh pr list --repo "$REPO" --author "app/dependabot" --state open \
  --json number,headRefName,title --jq '.[] | [.number|tostring, .headRefName, .title] | @tsv')

if [ -z "$OPEN_PRS" ]; then
  echo "  No open Dependabot PRs found."
  exit 0
fi

echo "=== Closing PRs ==="
while IFS=$'\t' read -r number branch title; do
  echo "  Closing PR #$number: $title"
  gh pr close "$number" --repo "$REPO"
done <<< "$OPEN_PRS"

echo ""
echo "Waiting 10 seconds before requesting recreates..."
sleep 10

echo ""
echo "=== Requesting recreates ==="
while IFS=$'\t' read -r number branch title; do
  echo "  Commenting @dependabot recreate on PR #$number: $title"
  gh pr comment "$number" --repo "$REPO" --body "@dependabot recreate"
done <<< "$OPEN_PRS"

echo ""
echo "=== Done ==="
echo ""
echo "Dependabot will recreate PRs on its next scan."
echo "To trigger version update scans immediately, visit:"
echo "  https://github.com/${REPO}/network/updates"
echo "and click 'Check for updates' next to each ecosystem."
