---
name: commit
description: Create a git commit for the current changes. Use when the user asks to "commit", "make a commit", or save work to git. Stages changes, writes a clear conventional message, and omits the Co-Authored-By trailer.
---

# commit

Create a git commit for the working-tree changes.

## Convention (important)

- **Do NOT add a `Co-Authored-By` trailer.** This project's commits are
  authored by the user alone — omit it even though the global default adds one.
- Do not add "Generated with Claude Code" or any tool attribution.

## Steps

1. Inspect state in parallel: `git status`, `git diff` (staged + unstaged), and
   `git log --oneline -5` to match the repo's existing message style.
2. Confirm no build artifacts or secrets are being staged. Artifacts belong in
   `.gitignore` (root `build/`, nested `.claude/settings.local.json`); if
   something slips through, fix `.gitignore` rather than committing it.
3. Stage the intended changes (`git add -A`, or specific paths if the user
   scoped the request).
4. Write the message:
   - A concise imperative subject line (~50 chars, no trailing period).
   - A blank line, then a body explaining *what* and *why* when the change is
     non-trivial. Wrap at ~72 chars.
   - Pass it via `git commit -F -` with a heredoc so multi-line bodies and
     special characters survive.
5. Verify with `git log --oneline -1` and `git show --stat HEAD`. Report the
   resulting hash and subject.

## Notes

- Commit only when the user asks. If on the default branch and the change
  warrants a branch, mention it — but don't block a simple commit request.
- Never run `git push` unless explicitly asked.
