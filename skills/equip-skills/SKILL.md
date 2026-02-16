---
name: equip-skills
description: Install agent skills from the community registry or fallback list
allowed-tools: Read, Write, Bash(curl *), Bash(gh api *), Bash(gh search *), Bash(mkdir *), Bash(rm -f *), Bash(test *), Grep
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
     curl -sfL -o .claude/skills/<name>/SKILL.md "https://raw.githubusercontent.com/{owner}/{repo}/main/<path-to-SKILL.md>"
     ```
   - Verify the downloaded file: `test -s .claude/skills/<name>/SKILL.md`
   - If the file is missing or empty, try alternate paths: `{repo}/main/SKILL.md`, `{repo}/main/.claude/skills/*/SKILL.md`, `{repo}/main/skills/*/SKILL.md`
4. If no installable structure → provide link for manual review

Exclude rows where Active is `FALSE` or Stale is `TRUE`.

## From Preferred Installables

Preferred skills arrive with `name` and `url` already resolved. Skip repo inspection — download directly:
```bash
mkdir -p .claude/skills/<name>
curl -sfL -o .claude/skills/<name>/SKILL.md "<url>"
```

After each download, verify the file exists and is non-empty:
```bash
test -s .claude/skills/<name>/SKILL.md
```
If the download fails (curl exit code non-zero) or the file is empty, the URL is broken — fall back to the recovery process described in Error Handling below.

## Fallback Skills Registry

Use these when the community registry is unavailable:

| Name | URL | Good For |
|------|-----|----------|
| svelte5-development | `https://raw.githubusercontent.com/splinesreticulating/claude-svelte5-skill/main/SKILL.md` | Svelte 5 / SvelteKit |
| mcp-builder | `https://raw.githubusercontent.com/anthropics/skills/main/mcp-builder/SKILL.md` | Building MCP servers |
| webapp-testing | `https://raw.githubusercontent.com/anthropics/skills/main/webapp-testing/SKILL.md` | Playwright testing |
| better-auth | `https://raw.githubusercontent.com/better-auth/skills/main/better-auth/best-practices/SKILL.md` | OAuth, magic links, auth |
| owasp-security | `https://raw.githubusercontent.com/agamm/claude-code-owasp/main/.claude/skills/owasp-security/SKILL.md` | Security best practices |
| stripe | `https://raw.githubusercontent.com/stripe/ai/main/skills/stripe-best-practices/SKILL.md` | Stripe integration |

Install fallback skills:
```bash
mkdir -p .claude/skills/<name>
curl -sfL -o .claude/skills/<name>/SKILL.md "<url>"
test -s .claude/skills/<name>/SKILL.md
```

## Error Handling

When a download fails (HTTP 404, empty file, or curl error):

1. **Remove the broken file** so it doesn't look like a successful install:
   ```bash
   rm -f .claude/skills/<name>/SKILL.md
   ```
2. **Search for an alternative source.** Use the skill name to find the real repo:
   ```bash
   gh search repos "<name> SKILL.md claude" --limit 5 --json fullName,description,url
   ```
3. **Inspect candidates** — look for a SKILL.md at common paths:
   - `SKILL.md` (root)
   - `skills/<name>/SKILL.md`
   - `.claude/skills/<name>/SKILL.md`
   ```bash
   gh api repos/{owner}/{repo}/contents/ --jq '.[].name'
   ```
4. **Download from the discovered source** and verify again.
5. If no working source is found after searching, **warn the user** and move on to the next skill. Do not block on a single failure.
