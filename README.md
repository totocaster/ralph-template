# Codex Ralph Template

This repository is a stripped-down template for running Ralph loops with the Codex CLI. It packages the scripts, prompts, and documentation we use when we want Codex to pull tasks from a Product Requirements Document (PRD), work autonomously, and land a commit after each story.

## What is Ralph?

Ralph is a lightweight technique popularized by Ryan Carson: you hand an AI a PRD plus a progress log, ask it to tackle one task at a time, and let it loop. Each iteration reads the PRD, picks the next unchecked line item, implements it, runs verification, commits, and updates the log. The magic is in keeping the tasks crisp and the loop deterministic (e.g., “ONLY DO ONE TASK AT A TIME.”).

This repo swaps Claude Code for Codex, mirroring how we run agentic work in Codex CLI (`codex exec`). Fork or copy it into any project that needs a Ralph workflow.

## Repository Layout

```
AGENTS.md                 # Place to document repo-specific rules for agents
scripts/ralph/ralph.sh    # Multi-iteration loop that feeds prompt.md to Codex
scripts/ralph/prompt.md   # System prompt describing your expectations
scripts/ralph/prd.json    # Product requirements; Ralph pulls its queue here
scripts/ralph/progress.txt# Progress log + reusable patterns
```

## Quick Start

1. **Install Codex CLI** – ensure `codex exec` works locally and is authenticated.
2. **Copy these files** into the root of the repo you want Codex to work on (or clone this repo and move your code into it).
3. **Edit `scripts/ralph/prd.json`** with real stories. Keep each story independently shippable and set `passes: false` until it is verified.
4. **Populate `scripts/ralph/progress.txt`** with lessons, codebase patterns, or validation commands agents should know before they start.
5. **Tailor `scripts/ralph/prompt.md` and `AGENTS.md`** so they describe your stack, required checks, and commit expectations.
6. **Make the runner executable**: `chmod +x scripts/ralph/ralph.sh`.

## Running the Loop

```
./scripts/ralph/ralph.sh 20
```

- The optional numeric argument caps iterations (default `10`).
- The script streams `prompt.md` into `codex exec --dangerously-bypass-approvals-and-sandbox`, so Codex runs with full local access—be sure the repo is sandbox-safe.
- Codex is expected to:
  1. Read `prd.json` and `progress.txt`.
  2. Pick the highest-priority story where `passes` is `false`.
  3. Implement only that story.
  4. Run the validations documented in the PRD, README, or `progress.txt`.
  5. Commit with `feat: [ID] - [Title]`.
  6. Flip the story’s `passes` flag to `true`.
  7. Append a log entry to `progress.txt`.
  8. Print `<promise>COMPLETE</promise>` when all stories pass.

## Customizing the Template

- **PRD structure** – `branchName` controls which branch Codex should create/switch into. `userStories` is an ordered list where `priority` determines the work queue. Keep acceptance criteria bullet-sized, and include required commands (tests, linters, deploy scripts) there.
- **Prompt** – `scripts/ralph/prompt.md` is the agent-side contract. Document coding standards, repos the agent should reference, how to update docs, and anything humans have to review manually.
- **Progress log** – Keep the `## Codebase Patterns` block at the top as a scratchpad of heuristics agents must respect. Every iteration should append a dated section with summary, files, and learnings. This doubles as an audit trail.
- **AGENTS.md** – Treat it as a living FAQ for your repo. Add conventions, tooling quirks, or known pitfalls. Codex reads it automatically when the prompt tells it to.

## Suggested Workflow

1. Draft a PRD manually or with plan mode inside Codex (`codex exec --plan`).
2. Run `./scripts/ralph/ralph.sh 1` a few times manually to watch Codex’ behavior.
3. Once you are happy, bump the iteration count for AFK runs (e.g., `./scripts/ralph/ralph.sh 25`).
4. Review commits between runs, update `progress.txt` with extra context, and refine the PRD as scope evolves.

## Notes

- This template intentionally contains sample placeholder stories/log entries. Replace them before running in a production repo.
- Because the runner disables the Codex sandbox (`--sandbox danger-full-access`), audit your PRD carefully—Codex can modify anything in the repo root.

Happy looping!
