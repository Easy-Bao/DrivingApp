# Git Review Operations

## Safe baseline

Run read-only commands first:

```bash
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

Never infer that a dirty worktree belongs to the review target. Preserve it and restrict commands to the requested commit, staged diff, or paths.

## Target commands

### Staged changes

```bash
git --no-pager diff --cached --stat
git --no-pager diff --cached --name-status
git --no-pager diff --cached --find-renames
```

If nothing is staged, use `HEAD` only after stating that fallback:

```bash
git --no-pager show --stat --oneline --decorate HEAD
git --no-pager show --find-renames --format=fuller HEAD
```

### Single commit

```bash
git cat-file -t <commit>
git --no-pager show --stat --oneline --decorate <commit>
git --no-pager show --find-renames --format=fuller <commit>
git --no-pager show <commit> -- path/to/file
```

For a merge commit, inspect parents and review the intended parent-to-merge diff rather than assuming the combined diff tells the whole story.

### Commit range

Normalize the user’s start and end commits before diffing:

```bash
git merge-base --is-ancestor <start> <end>
git --no-pager log --oneline --decorate <start>^..<end>
git --no-pager diff --find-renames <start>^..<end>
git --no-pager diff --stat <start>^..<end>
```

If the start is a root commit, `git diff <start>^..<end>` cannot resolve its parent. Use `git diff-tree --root -p <end>` for a root-only review. Prefer deterministic `git diff-tree --root` handling over destructive workarounds.

### File-scoped review

Apply the pathspec after resolving the target:

```bash
git --no-pager show <commit> -- path/to/file
git --no-pager diff <start>^..<end> -- path/to/file
git --no-pager diff --cached -- path/to/file
```

Verify requested paths exist in the target with `git diff --name-only` before reporting that a file was reviewed.

## Noise and integrity checks

```bash
git --no-pager diff --check <target>
git --no-pager diff --summary <target>
git ls-files --stage -- path/to/generated/file
```

Check lockfiles against manifests, generated output against its source, renames for imports/references, and configuration changes for environment-name consistency. Do not use `git clean`, `reset --hard`, or checkout commands to simplify a review.
