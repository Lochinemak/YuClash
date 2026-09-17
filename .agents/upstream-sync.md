# Upstream Sync

Upstream is [chen08209/FlClash](https://github.com/chen08209/FlClash), fetched by `.github/workflows/sync-upstream.yaml`
on a daily 03:00 UTC cron and on `workflow_dispatch`.

## How Upstream Branches Relate

Upstream history is fully linear on both branches — there is not a single merge commit. Work lands on `dev` alone,
carrying a `chore: bump version to X+YYYYMMDDNN` commit that is tagged `vX-pre.N`. To release, upstream replays those
commits onto `main` by rebase or cherry-pick, drops the `+build` bump, adds `chore(release): vX`, and tags `vX`. `dev`
is then realigned onto `main`, so the two branches share a hash again at each release commit (`db03880` for v0.8.97)
and diverge in between. README and docs commits sometimes land directly on `main`.

The consequence that drives everything below: **between releases, the same change exists on upstream `main` and
upstream `dev` under different commit hashes.** `git cherry` reports them as equivalent patches; git merge does not.

## This Fork's Model: Track `main` Only

- `main` merges `upstream/main`, then gets tagged `v<version from pubspec.yaml>` if that tag does not exist yet.
- `dev` merges **this fork's own `main`**, never `upstream/dev`.
- Feature work branches off `dev` and merges back into `dev`.

Never merge `upstream/dev` into any branch of this fork. Doing so imports the pre-release copies of commits that will
arrive again on `main` with different hashes, and every later `main` into `dev` merge then conflicts on changes git
cannot tell are already applied. The `reconcile/upstream-main` branch and the run of `Merge branch 'main' into dev`
commits on 2026-09-17 were the cleanup after exactly that.

The cost of this model is latency: a fix sits on upstream `dev` for a few days before it reaches `main`. That is
accepted here because this fork ships stable builds. To preview an upstream pre-release, branch off `upstream/dev` into
a throwaway branch and delete it — do not merge it into `dev` or `main`.

## When The Workflow Opens A PR

A conflicting sync stops the automation and opens a PR instead:

- `sync/upstream-main-<date>` — upstream `main` does not merge cleanly. Resolving and merging it does **not** tag a
  release and does **not** forward `dev`; do both by hand afterwards.
- `sync/main-to-dev-<date>` — `main` advanced but does not merge cleanly into `dev`, usually because a fork-local change
  touches a file upstream reworked.

Delete these branches once their PR merges; they carry nothing that is not already on `main` or `dev`.
