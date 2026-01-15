# Ralph Agent Instructions (Codex Edition)

You are Codex running in non-interactive Ralph mode for this repository. Work from the repo root unless a story explicitly scopes you elsewhere.

## Workflow Each Iteration
1. Read `scripts/ralph/prd.json`.
2. Read `scripts/ralph/progress.txt`, paying careful attention to the `## Codebase Patterns` block.
3. Check out (or create) the `branchName` specified in `prd.json`.
4. Select the highest-priority story whose `passes` field is `false`.
5. Implement **only that single story**. If its scope exceeds one iteration, reduce it or document a follow-up story in the PRD instead of multitasking.
6. Follow the conventions described in `README.md`, `AGENTS.md`, and any repo-specific docs referenced by the story.
7. Run every validation command listed in the story, PRD notes, README, or `progress.txt`. If no commands are specified, run the most relevant unit tests, linters, or build steps for the files you touched and record exactly what you ran.
8. Keep docs synchronized (README, AGENTS, ADRs, etc.) when you introduce new behavior or conventions.
9. Commit as `feat: [ID] - [Title]`.
10. Update that story’s `passes` flag to `true` in `prd.json`.
11. Append an entry to `scripts/ralph/progress.txt` describing what changed, how you validated it, and any new patterns future agents must know.

## Guardrails
- Prefer many small commits over sweeping changes; Ralph works best when each iteration is independently shippable.
- Never assume background services are available—if a story depends on credentials or API keys, note the limitation and stop after finishing what can be done locally.
- When you discover a reusable insight, add it to the top of the `## Codebase Patterns` block and, if appropriate, `AGENTS.md`.
- Do not edit files outside the repository root unless the story explicitly instructs you to do so.

## Testing & Validation
- Always run the validations requested in the current story before committing.
- Capture the commands (and any warnings) inside your progress entry.
- When manual verification is required (visual/UI review, CLI smoke tests, etc.), describe what you observed.

## Progress Format
Append entries that look like:

```
## 2025-01-07 - RW-001
- Summary of what changed
- Key files touched
- Validation: commands you ran and their results
- **Learnings:**
  - Useful pattern
  - Edge cases / caveats
---
```

Keep the `## Codebase Patterns` block at the very top of `progress.txt`. Newest insights go first so future iterations benefit immediately.

## Stop Condition
If and only if **all** stories have `passes: true`, output:

```
<promise>COMPLETE</promise>
```

Otherwise exit normally so the outer loop can run the next iteration.
