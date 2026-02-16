---
name: equip-skills
description: Install agent skills from the community registry or fallback list
allowed-tools: Read, Write, Bash(curl *), Bash(gh api *), Bash(mkdir *), Grep
---

# Install Agent Skills

Install Claude Code skills (reusable instruction sets) from the community registry or fallback sources.

## From Community Registry

Skills are discovered by searching the awesome-claude-code CSV for "Agent Skills" entries.

1. Extract `{owner}/{repo}` from the Primary Link and inspect the repo structure:
   ```bash
   gh api repos/{owner}/{repo}/contents/ --jq '.[].name'
   ```
2. If repo has `.claude-plugin/marketplace.json` → tell user to install as plugin, skip
3. If repo has a root `SKILL.md` or a `skills/` directory:
   - Check for SKILL.md files: `gh api repos/{owner}/{repo}/contents/skills --jq '.[].name'`
   - Create dirs and download:
     ```bash
     mkdir -p .claude/skills/<name>
     curl -sL -o .claude/skills/<name>/SKILL.md "https://raw.githubusercontent.com/{owner}/{repo}/main/<path-to-SKILL.md>"
     ```
4. If no installable structure → provide link for manual review

Exclude rows where Active is `FALSE` or Stale is `TRUE`.

## From Preferred Installables

Preferred skills arrive with `name` and `url` already resolved. Skip repo inspection — download directly:
```bash
mkdir -p .claude/skills/<name>
curl -sL -o .claude/skills/<name>/SKILL.md "<url>"
```

## Fallback Skills Registry

Use these when the community registry is unavailable:

| Name | URL | Good For |
|------|-----|----------|
| svelte5-development | `https://raw.githubusercontent.com/splinesreticulating/claude-svelte5-skill/main/SKILL.md` | Svelte 5 / SvelteKit |
| mcp-builder | `https://raw.githubusercontent.com/anthropics/skills/main/mcp-builder/SKILL.md` | Building MCP servers |
| webapp-testing | `https://raw.githubusercontent.com/anthropics/skills/main/webapp-testing/SKILL.md` | Playwright testing |
| better-auth | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/better-auth/SKILL.md` | OAuth, magic links, auth |
| owasp-security | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/owasp-security/SKILL.md` | Security best practices |
| stripe | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/stripe-best-practices/SKILL.md` | Stripe integration |

Install fallback skills:
```bash
mkdir -p .claude/skills/<name>
curl -sL -o .claude/skills/<name>/SKILL.md "<url>"
```

## Error Handling

- If a download fails, warn the user and provide the link for manual install
- Continue with remaining skills on any individual failure
