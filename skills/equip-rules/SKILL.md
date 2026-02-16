---
name: equip-rules
description: Install baseline project rules as .claude/rules/*.md files
allowed-tools: Read, Write, Edit, Glob, Bash(mkdir *)
---

# Install Project Rules

Create `.claude/rules/*.md` files in the project root, filtered by the detected tech stack. Rules are organized by topic so users can easily find, edit, or remove individual rule sets.

## Rules Table

| Rule | File | Match When |
|------|------|------------|
| Follow existing file structure and naming conventions. | `general.md` | Always |
| Write unit tests for new features. | `general.md` | Always |
| Always output full code blocks. | `general.md` | Always |
| Use Typescript strict mode. | `typescript.md` | `typescript` in languages |
| Use functional components and hooks. | `react.md` | `react`, `preact`, or `next` in deps |

## Installation Procedure

1. **Glob** `.claude/rules/*.md` to discover existing rule files
2. **Collect** matching rules based on detected tech stack, grouped by target file
3. **Dedup** — for each target file, skip any rule whose text already appears in the file
4. **Write** each rule file:
   - `mkdir -p .claude/rules`
   - For each target file, create or append to `.claude/rules/<file>` with a `# <Topic>` heading and the matching rules as bullet points
   - If the file already exists and contains a matching heading, append only new rules under that heading

## File Layout

```
.claude/rules/
├── general.md        # Universal rules (always applied)
├── typescript.md     # TypeScript-specific rules
└── react.md          # React/Preact/Next-specific rules
```

## Policies

- **Create or append** — if a rule file already exists, append new rules; never overwrite existing content
- Only create rule files whose rules match the detected stack
- Never modify `CLAUDE.md` — all managed rules go in `.claude/rules/`
- On re-run, skip rules already present in their target file
