---
name: equip-hooks
description: Install hooks with per-hook user approval
allowed-tools: Read, Write, Edit, WebFetch
---

# Install Hooks

Install Claude Code hooks from the community registry. Hooks run shell commands automatically on Claude Code events, so each one requires explicit user approval.

## Per-Hook Approval

For every hook, prompt the user individually:

> Install **\<name\>**? This runs `<command>` on every **\<event\>**. (y/n)

Only install hooks the user explicitly approves.

## From Preferred Installables

Preferred hooks arrive with `event`, `matcher`, and `command` fields inline. Skip the WebFetch step — proceed directly to the merge procedure (read settings.json, merge, write). **Still require per-hook user approval.**

## Installation Procedure

1. **Fetch details** — WebFetch the Primary Link to extract the event type, matcher, and shell command
2. **Read** `.claude/settings.json` (or start with `{}`)
3. **Merge** into `hooks.<event>[]` — skip duplicates (same event + matcher + command)
4. **Write** `.claude/settings.json`

## Hook Entry Format

Each hook entry in `settings.json` must use this exact structure:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {"type": "command", "command": "./scripts/pre-write-check.sh"}
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "./scripts/post-bash-check.sh"}
        ]
      }
    ]
  }
}
```

The `hooks` array inside each matcher contains objects with `"type"` (`"command"`, `"prompt"`, or `"agent"`) and the corresponding field (`"command"` or `"prompt"`). Do NOT use plain strings.

## Merge Logic

- Read existing `settings.json` and preserve all existing keys
- For each new hook, check if an entry with the same event + matcher + command already exists — if so, skip
- Append new entries to the appropriate event array
- Write the complete merged JSON back

## Error Handling

- If WebFetch fails for a hook, warn the user and provide the link for manual review
- Continue with remaining hooks on any individual failure
