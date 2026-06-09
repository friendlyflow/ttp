---
name: commit-and-push
description: Commit the current changes and push to the remote. Use when the user asks to "commit and push", "commit", "push", or save work to GitHub. Stages changes, writes a clear message with no Co-Authored-By trailer, then pushes the current branch.
---

# commit-and-push

Commit the working-tree changes and push them to the remote.

## Convention (important)

- **Do NOT add a `Co-Authored-By` trailer.** This project's commits are
  authored by the user alone — omit it even though the global default adds one.
- Do not add "Generated with Claude Code" or any tool attribution.

## Commit

1. Inspect state in parallel: `git status`, `git diff` (staged + unstaged), and
   `git log --oneline -5` to match the repo's existing message style.
2. Confirm no build artifacts or secrets are being staged. Artifacts belong in
   `.gitignore` (root `build/`, nested `.claude/settings.local.json`); if
   something slips through, fix `.gitignore` rather than committing it.
3. Stage the intended changes (`git add -A`, or specific paths if scoped).
4. Write the message:
   - Imperative subject (~50 chars, no trailing period).
   - Blank line, then a body explaining *what* and *why* for non-trivial work,
     wrapped at ~72 chars.
   - Pass it via `git commit -F -` with a heredoc so multi-line bodies survive.

## Push

5. Push the current branch. On first push of a branch, set upstream:
   `git push -u origin <branch>`; otherwise `git push`.
6. **Auth:** this repo pushes over SSH (`git@github.com:friendlyflow/ttp.git`).
   If a push fails with "could not read Username for https://github.com", the
   remote is on HTTPS without credentials — switch it with
   `git remote set-url origin git@github.com:friendlyflow/ttp.git` and retry.
   There is no `gh` CLI and no HTTPS credential helper; SSH (key
   `~/.ssh/id_ed25519`) is the working path.
7. Verify with `git log --oneline -1` and `git status` (should show
   "up to date with origin/<branch>"). Report the hash, subject, and that it
   pushed.

## Notes

- Pushing is outward-facing — only push when the user asks (this skill implies
  they did). Never force-push unless explicitly requested.
