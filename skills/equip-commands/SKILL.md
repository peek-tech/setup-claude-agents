---
name: equip-commands
description: Install slash commands from the community registry
allowed-tools: Read, Write, Bash(curl *), Bash(mkdir *)
---

# Install Slash Commands

Install Claude Code slash commands from the community registry.

## Installation Procedure

1. **Convert URLs** — replace `github.com` → `raw.githubusercontent.com` and remove `/blob/` to get raw URLs
2. **Check for conflicts** — if `.claude/commands/<name>.md` already exists and is NOT in the setup manifest, skip it and warn the user (it was manually created)
3. **Download**:
   ```bash
   mkdir -p .claude/commands
   curl -sL -o .claude/commands/<name>.md "<raw-url>"
   ```

## From Preferred Installables

Preferred commands arrive with `name` and pre-resolved raw `url`. Skip URL conversion — download directly:
```bash
mkdir -p .claude/commands
curl -sL -o .claude/commands/<name>.md "<url>"
```

## Selection

Match "Slash-Commands" entries from the community CSV registry. Always include "Version Control & Git" matches. Cap at **10 commands**.

## Error Handling

- If a download fails, warn the user and provide the link for manual install
- Continue with remaining commands on any individual failure
