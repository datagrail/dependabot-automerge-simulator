# Adding a New Package Ecosystem

This document explains how to add a new language or package ecosystem to the simulator so Dependabot will create PRs for it and the CI will validate it.

## Overview

Each ecosystem needs four things:
1. A **package manifest** (and lock file) with pinned versions targeting the scenarios you want to test
2. A **unit test file** that the CI can run
3. An entry in **`.github/dependabot.yml`**
4. A job in **`.github/workflows/ci.yml`**

The branch protection required check (`tests-passed`) already covers all jobs, so no changes to branch protection are needed when adding a new ecosystem.

---

## Step 1: Add the package manifest and lock file

Create a new directory at the repo root (e.g. `golang/`) and add the package manifest for your ecosystem. Pin packages at old versions that will produce the scenarios you want to test.

### Choosing package versions for each scenario

| Scenario | What to look for |
|---|---|
| **Security fix (minor/patch)** | A package with a known CVE in GitHub's advisory database where the fix lands in the same major version. Search [GitHub Advisory Database](https://github.com/advisories) for your ecosystem. |
| **Security fix + major bump** | A package with a CVE where the minimum fixed version is in a new major release. Rare — verify by checking the advisory's "patched versions" range. |
| **Major version bump (routine)** | Pin a package at an old major version (e.g. `1.x`) where a newer major version exists (e.g. `3.x`). Dependabot will suggest the latest regardless of major boundary. |
| **Routine minor/patch** | Pin any package a few minor or patch versions behind current. These will be held for the cooldown period before automerge. |
| **Foreign commits** | Not a package version — this is a manual step. After Dependabot creates a PR, push one extra commit to its branch from your own account. |

### Lock files

Always commit a lock file alongside the manifest. Without it, Dependabot may not create PRs for some ecosystems (notably `bundler` and `npm`).

Generate the lock file locally:
- **npm**: `cd <dir> && npm install`
- **bundler**: `cd <dir> && bundle install && bundle lock --add-platform x86_64-linux`
- **pip**: pip-compile (`pip install pip-tools && pip-compile requirements.in`) or commit `requirements.txt` directly (pip doesn't require a lock file for Dependabot)
- **Go modules**: `go mod tidy`
- **Other**: check the [Dependabot docs](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file) for your ecosystem

---

## Step 2: Add a unit test file

Add a simple self-contained test that the CI can run. The test should **not** import any of the pinned production packages — it just needs to pass so the required check is green on the main branch. Dependabot PRs will run CI against the updated lock file.

Examples of the pattern used here:
- `python/test_hello.py` — `pytest`, no imports from `requirements.txt`
- `ruby/test_hello.rb` — `minitest` (stdlib), no `require` of Gemfile gems
- `javascript/hello.test.js` — `jest` (devDependency), no imports of production packages

---

## Step 3: Add an entry to `.github/dependabot.yml`

```yaml
- package-ecosystem: "<ecosystem>"   # e.g. "gomod", "cargo", "composer", "pip"
  directory: "/<dir>"                # directory containing the manifest
  schedule:
    interval: "daily"
  open-pull-requests-limit: 10
```

See the [full list of supported ecosystems](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem).

---

## Step 4: Add a job to `.github/workflows/ci.yml`

Add a new job (e.g. `test-golang`) and add it to the `needs` list of the `tests-passed` job.

```yaml
  test-golang:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
      - run: go test ./golang/...

  tests-passed:
    runs-on: ubuntu-latest
    needs: [test-python, test-ruby, test-javascript, test-golang]  # add new job here
    steps:
      - run: echo "All tests passed"
```

---

## Triggering and verifying

After pushing your changes:

1. Confirm the CI passes on `main` before expecting Dependabot PRs — the required check must be green so Dependabot PRs can be merged.
2. Go to **Settings → Code security and analysis** and enable **Dependabot alerts** and **Dependabot security updates** if not already on.
3. Go to **`https://github.com/datagrail/dependabot-automerge-simulator/network/updates`** and click **"Check for updates"** next to your new ecosystem to trigger Dependabot immediately rather than waiting for the daily schedule.
4. Run `dependabot-automerge` with `--dry-run` to verify each PR is classified correctly before running live.

### Scenario flags

| What you want to test | CLI flags |
|---|---|
| Routine PRs eligible (bypass cooldown) | `--cooldown-days 0` |
| Routine PRs all in cooldown | `--cooldown-days 999` |
| Security merges only | `--cooldown-days 999` |
| Cap how many routine merges happen | `--max-cooldown-merges 1` |
| Verify classification without side effects | `--dry-run` |

### Resetting

Run `scripts/reset.sh` to close all open Dependabot PRs and post `@dependabot recreate` on each, causing Dependabot to create fresh PRs on its next scan.
