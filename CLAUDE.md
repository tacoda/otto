# CLAUDE.md

Guidance for Claude Code when working in **Otto**.

## Project Overview

AsciiDoc static site generator. Distributed as the `ottogen` Ruby gem with an `otto` CLI (Thor-based) supporting `init`, `build`, `generate`, `clean`, `watch`, and `serve`. Pages are authored in AsciiDoc and rendered to `_build/` via Asciidoctor; `serve` runs a local WEBrick server on port 8778.

**Tech Stack:** Ruby (>= 1.9), Thor, Asciidoctor, Listen, WEBrick, RSpec

**Main branch:** `main`
**Task tracker:** none
**CI:** GitHub Actions

## Layout

- `bin/otto` — CLI entry point
- `lib/ottogen/otto.rb` — Thor command definitions
- `lib/ottogen/ottogen.rb` — core logic (init/build/generate/clean/watch/serve)
- `spec/ottogen/` — RSpec tests
- `ottogen.gemspec`, `Gemfile`, `Gemfile.lock` — gem packaging

---

## The Harness

The harness is the system that lets an AI agent produce correct, high-quality code consistently. It has four parts plus the discipline that makes them work.

1. **Guidance** — `CLAUDE.md` (this file) and `.claude/rules/`. Path-scoped rules auto-load when touching matching files. These shape what the agent writes before it writes a single line.
2. **Guardrails** — automated checks (`bundle exec rubocop`, `bundle exec rspec`, `gem build ottogen.gemspec`). The agent runs them; it does not bypass them.
3. **Flywheel** — the feedback loop. When a reviewer flags a pattern, update the relevant rule file in `.claude/rules/`, reload it, then re-apply. Every review improves every future conversation.
4. **Executable Workflows** — `.claude/agents/` for isolated read-only analysis, `.claude/commands/` for single-step utilities, `.claude/skills/` for multi-phase workflows.

The harness is only as strong as the code it governs. Write new code to harness standards. Refactor existing code when you touch it. Delete dead code.

| Rule file | Scope |
|---|---|
| `.claude/rules/design-principles.md` | Always loaded — SOLID, KISS, YAGNI, DRY |
| `.claude/rules/tests.md` | Loaded when editing tests — TDD workflow, patterns |
| `.claude/rules/security.md` | Loaded for auth, queries, file I/O, response shapes |
| `.claude/rules/commits.md` | Loaded before commit — conventional commits |

## Commands

```
bundle exec rubocop                # static checks
bundle exec rspec                  # full test suite
gem build ottogen.gemspec          # build / compile
```

## Change Approval Flow

During implementation, auto-accept edits. When changes are ready to commit:

1. **Self-review** — spawn the self-review agent on the diff
2. **Show diff** — present changes and findings, ask for feedback
3. **Feedback given** — update the relevant rule file, reload it, re-apply
4. **Approved** — run `/pre-commit`
5. **Checks pass** — commit and push (conventional commits, no co-authors)

## TDD Workflow

1. **Red** — write failing tests first; present a list of test descriptions for review
2. **Green** — implement the smallest change to make tests pass
3. **Refactor** — clean up only after green; spawn the refactor-changes agent on the diff
4. **Commit** — follow the change approval flow

## Pre-Commit Verification

Run `/pre-commit` immediately before `git commit` — every time. Checks that ran earlier in a task do not count if any code has changed since.
