---
description: Commit and pull request rules for Otto
---

# Commits & Pull Requests

## Conventional Commits

Format: `<type>(<scope>): <subject>`

Common types:
- `feat` — new feature
- `fix` — bug fix
- `refactor` — behavior-preserving structural change
- `test` — adding or improving tests
- `docs` — documentation only
- `chore` — tooling, dependencies, non-code changes

## Rules

- One logical change per commit. Separate **structural** (refactor) and **behavioral** (feat/fix) changes into different commits.
- The codebase stays releasable on `main` at all times. Use feature flags to decouple deploy from release.
- Pre-commit checks must pass before commit. CI is a backstop, not a substitute.
- Do **not** add co-authors to commit messages.
- Do **not** mention the AI agent in commit messages or PR descriptions.

## Pull Requests

- Title is short (under 70 characters); details go in the body.
- Body explains the **why**, not just the **what**.
- Include a test plan when the change touches user-facing behavior.

## Project-Specific Notes

Repo: `tacoda/otto` on GitHub. Use `gh` for PRs. No co-authors and no AI-agent mentions in commits, PRs, or issues.
