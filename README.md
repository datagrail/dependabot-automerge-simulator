# dependabot-automerge-simulator

Test repository for [dependabot-automerge](https://github.com/datagrail/dependabot-automerge). Contains real package manifests with pinned old versions so Dependabot creates authentic PRs that exercise each decision branch of the automerge tool.

## Ecosystems

| Directory | Ecosystem | Dependabot type |
|---|---|---|
| `python/` | pip | version updates + security updates |
| `ruby/` | bundler | version updates + security updates |
| `javascript/` | npm | version updates + security updates |

## Scenarios covered

Each ecosystem pins packages at versions that produce specific automerge outcomes:

| Scenario | Package | Pinned version | Expected outcome |
|---|---|---|---|
| Security fix (minor) | `requests` (Python) | 2.27.1 | Immediate merge — CVE-2023-32681 fixed in 2.31.0 |
| Major version bump | `Flask` (Python) | 2.3.3 | Labeled "Human Needed" — 2.x → 3.x |
| Routine minor/patch | `certifi` (Python) | 2023.7.22 | Merged after cooldown |
| Routine minor/patch | `urllib3` (Python) | 1.26.12 | Merged after cooldown (or major bump to 2.x) |
| Security fix (patch) | `rack` (Ruby) | 2.2.3 | Immediate merge — multiple CVEs fixed in 2.2.6.3+ |
| Major version bump | `rake` (Ruby) | 12.3.3 | Labeled "Human Needed" — 12.x → 13.x |
| Routine minor/patch | `json` (Ruby) | 2.7.0 | Merged after cooldown |
| Security fix (minor) | `lodash` (JS) | 4.17.11 | Immediate merge — CVE-2020-8203 fixed in 4.17.21 |
| Major version bump | `axios` (JS) | 0.27.2 | Labeled "Human Needed" — 0.x → 1.x |
| Routine minor/patch | `express` (JS) | 4.17.3 | Merged after cooldown (or major bump if Express 5.x) |

**Foreign commits** — manual scenario: after Dependabot creates any PR, push one extra commit to its branch from your own account. The next automerge run will label it "Human Needed" with reason "foreign commits detected".

## How the baseline/reset system works

The simulator uses a **`baseline` branch** to maintain the known-good state where all dependencies are pinned at vulnerable/old versions. This branch is the "reset point" — the file state the repo returns to after each test cycle.

### Lifecycle

```
1. baseline branch holds the vulnerable state (old deps + app code)
2. Dependabot opens PRs to bump each dependency
3. You run dependabot-automerge to test classification/merging
4. ./scripts/reset.sh commits baseline's file state onto main
5. Dependabot recreates its PRs against the reset main
```

### Automatic baseline tracking

The `update-baseline` workflow (`.github/workflows/update-baseline.yml`) runs on every push to main:

- **Non-Dependabot commit** (human work): cherry-picks it onto the `baseline` branch so new ecosystems, app code, CI changes, etc. automatically become part of the reset point.
- **Reset commit** (message starts with `Reset:`): skipped — these restore baseline state and don't need to be cherry-picked back.
- **Dependabot commit**: fails the workflow with an error. A Dependabot commit on main means the simulator is "dirty" and needs resetting.

### What the reset script does

`./scripts/reset.sh` performs these steps:

1. **Overlays the baseline file state** onto main using `git checkout origin/baseline -- .` and commits it as a normal forward commit. No force pushing.
2. **Updates the `last-reset` date** in `dependabot.yml` to trigger a Dependabot rescan.
3. **Comments `@dependabot recreate`** on all open Dependabot PRs so they rebuild against the reset main. PRs are never closed or deleted — this avoids Dependabot's "won't notify you again" behavior.

## Running dependabot-automerge against this repo

```bash
# Dry run — classify PRs without merging anything
GH_TOKEN=<token> uv run automerge \
  --org datagrail \
  --repos dependabot-automerge-simulator \
  --dry-run

# Bypass cooldown to test routine merge flow
GH_TOKEN=<token> uv run automerge \
  --org datagrail \
  --repos dependabot-automerge-simulator \
  --cooldown-days 0 \
  --dry-run

# Keep all routine PRs in cooldown (security merges only)
GH_TOKEN=<token> uv run automerge \
  --org datagrail \
  --repos dependabot-automerge-simulator \
  --cooldown-days 999 \
  --dry-run
```

## Resetting

After a test run (especially a live run), reset the repo so Dependabot recreates fresh PRs:

```bash
./scripts/reset.sh
```

To trigger version update scans immediately rather than waiting for the daily schedule, visit:

```
https://github.com/datagrail/dependabot-automerge-simulator/network/updates
```

and click **"Check for updates"** next to each ecosystem.

## Adding a new ecosystem

See [ADDING_ECOSYSTEMS.md](./ADDING_ECOSYSTEMS.md).

## Branch protection

The `main` branch requires the `tests-passed` CI check to pass. This check gates Dependabot PR merges and ensures the CI workflow is exercised end-to-end.
