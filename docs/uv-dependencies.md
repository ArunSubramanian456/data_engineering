# Python environment and dependencies with uv

How this repo builds its virtual environment and adds dependencies step by step. The goal is to never resolve everything up front: declare a package only when a week first needs it.

## Mental model

| Thing | What it is | Who edits it |
|---|---|---|
| `pyproject.toml` | What you *want*: runtime deps in `[project].dependencies`, tool deps in `[dependency-groups]` | You, via `make add` / `make remove` (or by hand) |
| `uv.lock` | What uv *resolved*: exact versions for **all** declared deps and groups, solved together | `uv lock`, `uv add`, `uv remove`. Never by hand |
| `.venv/` | What is *installed* right now: the project (editable) + `dev` + any groups you asked for | `uv sync` (via `make install`). Disposable, gitignored |
| `.python-version` | The Python version uv uses for `.venv` | `uv python pin` |
| `.git/hooks/pre-commit` | Git hook that runs the pre-commit checks on every `git commit` | `pre-commit install` (via `make install`). Local only, not versioned |

- **Runtime dependency** (`[project].dependencies`): anything `src/` imports, because that code ships to Glue/Lambda. Today: numpy, pandas, pydantic.
- **Group** (`[dependency-groups]`): tools only. `dev` (pytest, ruff, ty, pre-commit, radon) is installed by default. Later: `dbt`, `aws`, `spark`.
- **Resolution vs install.** The lockfile always resolves every declared group together, so they're compatible. Installing is selective: you choose which groups go into `.venv`.
- Airflow is **not** managed here. It has its own project and venv in `airflow/`.

## What `make install` does

`make install` → `run.sh install`:
```bash
uv sync --locked "$@"            # 1. create/sync .venv from uv.lock
if [[ -z "$CI" ]]; then          # 2. only outside CI…
    uv run --locked pre-commit install   #    …install the git hook
fi
```
1. **`uv sync --locked`** does the following:
   - creates `.venv` if it's missing (using `.python-version`)
   - installs exactly what `uv.lock` pins: runtime deps + the `dev` group + any `--group` you pass, plus the project in **editable** mode
   - removes anything else from `.venv`
   - `--locked` fails, instead of silently re-locking, if `pyproject.toml` and `uv.lock` disagree
2. **`pre-commit install`** writes `.git/hooks/pre-commit`. From then on, every `git commit` runs the checks on **staged** files and aborts the commit if one fails. `make lint` still checks **all** files and is what the push gate requires.
   - `[[ -z "$CI" ]]` is true when `$CI` is empty or unset. GitHub Actions sets `CI=true` in every job automatically, so CI skips the hook. CI never runs `git commit`; it calls `pre-commit run` directly via `lint:ci`. Try it with `CI=true bash run.sh install`.
   - Re-running it is harmless; it rewrites the same file.

### No activation needed
Every uv command walks up from the current directory to `pyproject.toml` and uses the `.venv` next to it. `uv run <cmd>` runs the command with `.venv/bin` first on `PATH`. The `make` targets all go through uv, so you never need `source .venv/bin/activate`. Activate only if you want bare `python`, `pytest` or `dbt` in your shell; otherwise prefix the command with `uv run`.

**Trap:** if *another* venv is active (e.g. `airflow/.venv`), `run.sh` points uv at that venv (`UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"`). Run `deactivate` before running `make` from the repo root.

## Command cheat sheet

| Goal | Command |
|---|---|
| Install project + dev, and the git hook | `make install` |
| Install + extra groups | `make install ARGS="--group dbt --group aws"` |
| Install everything | `make install ARGS="--all-groups"` |
| Add a runtime dep | `make add ARGS='"pandera>=0.20,<1"'` |
| Add to a group (creates the group if new) | `make add ARGS='--group dbt "dbt-core>=1.10,<2"'` |
| Remove a dep | `make remove ARGS="--group dbt dbt-duckdb"` |
| Upgrade one package in the lock | `uv lock --upgrade-package dbt-core` then `make install ARGS="--group dbt"` |
| Is the lock in sync with pyproject? | `uv lock --check` |
| What's installed? | `uv pip list` / `uv tree` |
| Is the git hook installed? | `ls .git/hooks/pre-commit` |

Quote version specifiers (`'"pkg>=1,<2"'`). Without the quotes, the shell reads `<` as a redirect.

---

## Part A: set up from scratch (new clone, or after deleting `.venv`)

**0. Prerequisites**
```bash
cd ~/repos/data_engineering
deactivate 2>/dev/null || true  # make sure no other venv is active
uv --version                    # uv is installed
git status                      # know what's uncommitted
```

**1. Work on a branch, never on `main`.** `make lint` and `git commit` fail on `main` because of the `no-commit-to-branch` hook.
```bash
git switch main && git pull --rebase
git switch -c build/<short-desc>
```

**2. Pin Python to match Glue 5.x (3.11).** Once per repo. Commit `.python-version`.
```bash
uv python install 3.11          # downloads a managed CPython if you don't have one
uv python pin 3.11              # writes .python-version
cat .python-version
```

**3. Create the virtual environment (optional, but it makes the step visible)**
```bash
uv venv                         # creates .venv using the pinned Python
.venv/bin/python --version      # → Python 3.11.x
```
Skip this and step 5 creates `.venv` anyway.

**4. Make sure the lockfile matches `pyproject.toml`**
```bash
uv lock --check                 # OK → go on; error → run `uv lock`
uv lock                         # re-resolve (needed after a Python pin or hand edits)
git diff --stat uv.lock
```

**5. Install the env and the git hook**
```bash
make install                    # uv sync --locked + pre-commit install
```
Expect `pre-commit installed at .git/hooks/pre-commit` at the end. Check it:
```bash
uv pip list                                         # what landed in .venv
uv pip show data-engineering | grep -i editable     # project installed editable
uv run python -c "import numpy, pandas, pydantic, data_engineering; print('ok')"
ls .git/hooks/pre-commit                            # git hook present
```

**6. Verify.** Run these as plain commands (no pipes or `;`), so the push gate records them as verified.
```bash
make lint
make test
```
- The first `make lint` after a Python change is slower: pre-commit builds its own tool environments in `~/.cache/pre-commit`, separate from `.venv`.
- Reports go to `test-reports/`. Open `test-reports/htmlcov/index.html`, or run `make serve-coverage-report`.

**7. Commit, push, PR**
```bash
git add .python-version pyproject.toml uv.lock
git commit -m "build: pin python 3.11 and sync env"   # the git hook runs the checks here
git push -u origin build/<short-desc>
gh pr create --fill
```
If the commit is aborted because a hook modified files (e.g. `ruff format`), review the changes, `git add` them, and commit again. Then follow **Part C** to watch CI, merge and clean up.

---

## Part B: add dependencies as the plan progresses

Same loop every time. Example: the first dbt week.

**1. Branch**
```bash
git switch main && git pull --rebase
git switch -c build/dbt-deps
```

**2. Decide: runtime dep or group?** Does code in `src/` import it?
- Yes → runtime: `make add ARGS='"<pkg>>=X,<Y"'`
- No, it's a tool → group: `make add ARGS='--group <name> "<pkg>>=X,<Y"'`

**3. Add it, with a deliberate upper bound.** `uv add` alone only writes `>=current`.
```bash
make add ARGS='--group dbt "dbt-core>=1.10,<2" "dbt-duckdb>=1.10,<2"'
```
This updates `pyproject.toml`, re-resolves `uv.lock`, and installs into `.venv`, all in one step. No separate `make install` is needed. If you later run `make install` without `ARGS="--group dbt"`, the dbt group is removed from `.venv` again (exact sync).

**4. Review what changed**
```bash
git diff pyproject.toml
git diff --stat uv.lock
uv tree --group dbt --depth 1   # what the group pulled in (optional)
```

**5. Use it and add a test**
```bash
uv run dbt --version
```

**6. If CI needs the group**, edit `.github/workflows/ci.yaml` in the job that needs it:
```yaml
run: /bin/bash -x run.sh install --group dbt
```
Lint and unit tests that don't touch dbt don't need it. The git hook step is skipped there automatically (`CI=true`).

**7. If a pre-commit hook needs the package** (e.g. sqlfluff with the dbt templater): pre-commit hooks run in their **own** environments (`~/.cache/pre-commit`), not `.venv`. Add the packages under that hook's `additional_dependencies` in `.pre-commit-config.yaml`.

**8. Verify, then commit deps separately from code.** The git hook runs the checks on each commit.
```bash
make lint
make test
git add pyproject.toml uv.lock
git commit -m "build(dbt): add dbt group"
git add dbt/
git commit -m "feat(f1): first dbt model"
```

**9. Push, open a PR, merge and clean up.** See **Part C** for the details. In short:
```bash
git push -u origin build/dbt-deps
gh pr create --fill-first          # title = first commit subject (Conventional Commit)
gh pr checks --watch               # wait for the required checks
gh pr merge --rebase --delete-branch   # keeps build(...) and feat(...) as separate commits on main
make install ARGS="--group dbt"    # re-sync with the groups you're using
```

### Expected additions over the plan

| When | Command |
|---|---|
| F1: dbt fundamentals | `make add ARGS='--group dbt "dbt-core>=1.10,<2" "dbt-duckdb>=1.10,<2"'` |
| MP1 on Redshift | `make add ARGS='--group dbt dbt-redshift "sqlfluff>=3,<4" sqlfluff-templater-dbt'` |
| Redshift Python access drill | `make add ARGS='--group aws boto3 redshift-connector awswrangler'` |
| First `src/` data validation | `make add ARGS='"pandera>=0.20,<1"'` (runtime) |
| First test that mocks AWS | `make add ARGS='--group dev "moto[s3,glue]>=5,<6"'` |
| Spark phase (Glue 5.x = Spark 3.5) | `make add ARGS='--group spark "pyspark>=3.5,<3.6" pyarrow'` |

---

## Part C: pull request lifecycle (open → check → merge → clean up)

`main` is protected: a PR is required, with 0 approvals, and the required checks `Lint, Format, and other static code quality checks` and `Execute tests` must pass on a branch that's up to date with `main`. The PR exists to run CI, not for review.

### 1. Open the PR
```bash
git push -u origin <branch>
gh pr create --fill-first      # or --fill / --title "type(scope): summary"
```
| Flag | Title / body comes from |
|---|---|
| `--fill` | 1 commit: its subject/body. Several commits: title from the **branch name**, body = list of commit subjects |
| `--fill-first` | The first commit's subject/body, even with several commits |
| `--fill-verbose` | Body = every commit's full message |
| `--title "…" --body "…"` | You. `--draft` opens a draft; `--web` finishes it in the browser |

Make the PR title a valid Conventional Commit (`build(dbt): add dbt group`). With `--squash` it becomes the commit subject on `main`, and the local commit-msg hook never sees it. Fix it with `gh pr edit --title "…"`.

### 2. Check the PR's status
```bash
gh pr status                    # your PRs at a glance
gh pr checks --watch            # live CI status until all checks finish
gh pr view                      # human-readable summary of the current branch's PR
gh pr view <number> --json state,mergeStateStatus,mergedAt,headRefName \
  --jq '{state, mergeStateStatus, mergedAt, headRefName}'
gh pr view <number> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | "\(.name): \(.conclusion)"'
```
Without `<number>`, `gh pr view` uses the PR for the current branch.

| Field | Values and meaning |
|---|---|
| `state` | `OPEN`, `MERGED`, `CLOSED` (closed without merging). **Check this is `MERGED` before deleting a branch by hand** |
| `mergedAt` | Timestamp of the merge, `null` if not merged |
| `mergeStateStatus` | `CLEAN` = ready to merge · `BLOCKED` = required checks pending/failing · `BEHIND` = branch not up to date with `main` (rebase, see below) · `DIRTY` = merge conflicts · `UNSTABLE` = a non-required check failed · `UNKNOWN` = still computing (or already merged) |
| `statusCheckRollup` | Each check's `name` and `conclusion`: `SUCCESS`, `FAILURE`, `SKIPPED`, … |
| `mergeCommit` | `.mergeCommit.oid`: the commit the PR produced on `main` |

**`BEHIND`?** The branch must be rebased onto the latest `main`. Two ways:
```bash
# A) Let GitHub do it (no force push needed). CI re-runs on the rebased branch.
gh pr update-branch --rebase
git pull --rebase               # bring your local branch in line, if you keep working on it

# B) Locally. Rebasing rewrites the branch's commits, so the push must be a force push.
git fetch origin && git rebase origin/main
make lint
make test
git push --force-with-lease     # blocked for Claude by the hooks: run it yourself
```
Use `--rebase` with `update-branch`: without it, GitHub merges `main` into your branch and adds a merge commit.

### 3. Merge: choose a method
| Method | What lands on `main` | Use when |
|---|---|---|
| `gh pr merge --rebase` | Each branch commit, replayed on top of `main` (new SHAs), no merge commit | Commits are already clean and meaningful, e.g. `build(dbt): add dbt group` then `feat(f1): first model`. **This repo's default**: it keeps "deps separate from code" visible on `main` |
| `gh pr merge --squash` | One new commit: subject = PR title + `(#N)`, body = squashed messages | The branch has WIP noise ("fix typo", "try again"), or the PR is one logical change anyway |
| `gh pr merge --merge` | Your commits **plus** a "Merge pull request #N" commit | Avoid: it breaks linear history. Turn it off in the repo settings (below) |

Useful extras:
- `-d` / `--delete-branch`: after merging, deletes the remote branch, deletes the local branch, switches you to `main` and pulls it. It does **not** remove the stale `origin/<branch>` ref (see §4) unless `fetch.prune` is on.
- `--subject "…"` / `--body "…"`: override the squash commit message.
- `--auto`: merge automatically once checks pass. Needs Settings → General → "Allow auto-merge".
- `--admin`: bypass protection. Don't use it; the point of the PR is CI.

**Recommended:**
```bash
gh pr merge --rebase --delete-branch     # or --squash --delete-branch for noisy branches
git fetch --prune                        # only needed if fetch.prune isn't set (see §4)
git branch -a                            # → main, origin/main, origin/HEAD
```

### 4. Delete the branch (remote and local)
Three different things are called "the branch":

| What | Where | Removed by |
|---|---|---|
| `<branch>` on GitHub | the remote | `gh pr merge -d`, auto-delete, or the PR's "Delete branch" button |
| `<branch>` | your local branch | `gh pr merge -d`, or `git branch -D` |
| `remotes/origin/<branch>` | your **local snapshot** of the remote, as of the last fetch | only `git fetch --prune` (or any fetch/pull with `fetch.prune` on) |

A normal fetch or pull adds and updates `origin/*` refs but never removes them. That's why `git branch -a` still lists a branch that GitHub has already deleted.

**One-time setup (recommended):** prune automatically on every fetch/pull, including the pull that `gh pr merge -d` runs:
```bash
git config --global fetch.prune true     # or without --global for this repo only
```
This only removes your cached `origin/*` copies, never real branches, so it's safe everywhere.

**Remote.** One of:
- `--delete-branch` on `gh pr merge` (above), or
- Settings → General → Pull Requests → **"Automatically delete head branches"** (already on for this repo), or
- the "Delete branch" button on the merged PR page.

Don't use `git push origin --delete <branch>`; the push hook blocks branch deletes.

**Local.** After a squash *or* rebase merge, the commits on `main` have new SHAs. Git therefore thinks your branch isn't merged, and `git branch -d` refuses ("not fully merged"). Confirm on GitHub, then force-delete:
```bash
git switch main && git pull --rebase
gh pr view <branch> --json state --jq .state      # must print MERGED
git branch -D <branch>                            # capital -D: force, safe only after MERGED
git fetch --prune                                 # drop stale origin/* refs (skip if fetch.prune is on)
git branch -a                                     # verify
```
`gh pr merge --delete-branch` covers the first three lines (switch, pull, delete local). The prune still needs `git fetch --prune` or `fetch.prune=true`.

### 5. Check the run on `main` after the merge
Merging triggers a `push` run on `main`, separate from the PR run:
```bash
gh run list --branch main --limit 3
gh run view <run-id> --log-failed     # if it failed
```

### One-time repo settings for this flow
Settings → General → **Pull Requests**:
- **Untick "Allow merge commits"** so `--merge` and the green button's merge-commit option are gone. The history needs it: PRs #1 and #2 were merged with merge commits.
- Keep "Allow squash merging" and "Allow rebase merging" ticked.
- "Automatically delete head branches": ticked.

Settings → Branches → `main` rule: optionally tick **"Require linear history"** to enforce it.

---

## Troubleshooting

| Symptom | Cause → fix |
|---|---|
| `The lockfile at uv.lock needs to be updated, but --locked was provided` | `pyproject.toml` was edited by hand → `uv lock`, then `make install` |
| `Group 'dbt' is not defined in the project's dependency-groups table` | Group not added yet → `make add ARGS='--group dbt …'` |
| A group's packages vanished after `make install` | `uv sync` is exact: it removes groups you didn't name → `make install ARGS="--group dbt"` |
| `No module named …` when running `python` directly | venv not active → use `uv run python …`, or `source .venv/bin/activate` |
| `make lint` or `git commit` fails with "don't commit to branch" | You're on `main` → `git switch -c <branch>` (uncommitted changes come along) |
| `git commit` aborted, files modified by a hook | A fixer hook (e.g. `ruff format`) changed files → review, `git add`, commit again |
| `git commit` fails with `pre-commit not found` / missing Python | `.venv` was deleted; the hook points at `.venv/bin/python` → `make install` |
| Packages landed in the wrong venv | Another venv was active → `deactivate`, then `make install` |
| Wrong Python in `.venv` | `rm -rf .venv && make install` (uses `.python-version`) |
| Two groups can't resolve together | Add `[tool.uv] conflicts = [[{ group = "a" }, { group = "b" }]]` to `pyproject.toml` |
| Want a totally clean slate | `make clean && rm -rf .venv && make install` |
| `git branch -d` says "not fully merged" after the PR merged | Squash/rebase merges create new SHAs → confirm `gh pr view <branch> --json state` is `MERGED`, then `git branch -D <branch>` |
| `git branch -a` still lists `origin/<branch>` after the PR merged and the branch was deleted | Stale remote-tracking ref → `git fetch --prune`; prevent it with `git config --global fetch.prune true` |
| PR shows `mergeStateStatus: BEHIND` / "branch out of date" | Strict checks are on → `gh pr update-branch --rebase` (see Part C §2) |
| Push run on `main` fails in **Tag Release** with `fatal: tag 'v0.0.0' already exists` | Not a merge failure: the merge already happened, only the post-merge tagging job failed. `version.txt` (`v0.0.0`) is already tagged. Fix: turn `release-on-main` into a no-op placeholder (no tagging, no `contents: write`) |
| `git commit` on `main` blocked for a docs-only change | `no-commit-to-branch` blocks all commits on `main` → use a branch + PR, or run `SKIP=no-commit-to-branch git commit …` yourself for an admin direct push |
