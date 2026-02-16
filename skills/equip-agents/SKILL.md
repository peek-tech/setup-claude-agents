---
name: equip-agents
description: Create project-tailored agent .md files based on detected tech stack
allowed-tools: Read, Write, Glob, Grep
---

# Create Agents

Create role-specific Claude Code agent `.md` files tailored to the detected tech stack. Write files to `.claude/agents/<name>.md`.

## Agent Roles Table

| Role | Tools | Match When |
|------|-------|------------|
| frontend-dev | Read, Write, Edit, Bash, Glob, Grep | UI framework deps OR `.svelte`/`.vue`/`.jsx`/`.tsx` files |
| backend-dev | Read, Write, Edit, Bash, Glob, Grep | Server framework deps (express, fastapi, django, flask, gin, rails, laravel, phoenix, hono, etc.) |
| aws-architect | Read, Write, Edit, Bash, Glob, Grep | `cdk.json` OR `aws-cdk-lib` OR CloudFormation/SAM OR significant `@aws-sdk/*` |
| ai-engineer | Read, Write, Edit, Bash, Glob, Grep | `.claude-plugin/` OR SKILL.md authoring OR AI/LLM deps |
| mcp-developer | Read, Write, Edit, Bash, Glob, Grep | `@modelcontextprotocol/sdk` in deps OR MCP server code |
| devops | Read, Write, Edit, Bash, Glob, Grep | CI/CD configs OR Dockerfiles OR deployment scripts |
| dba | Read, Write, Edit, Bash, Glob, Grep | Database schemas, migration files, ORM deps |
| terraform-engineer | Read, Write, Edit, Bash, Glob, Grep | `*.tf` OR `terraform/` OR `pulumi/` |
| test-automator | Read, Write, Edit, Bash, Glob, Grep | Test framework deps (vitest, jest, playwright, pytest, etc.) |
| python-dev | Read, Write, Edit, Bash, Glob, Grep | Python primary (`pyproject.toml`/`requirements.txt` + `*.py`) |
| rust-dev | Read, Write, Edit, Bash, Glob, Grep | Rust primary (`Cargo.toml` + `*.rs`) |
| go-dev | Read, Write, Edit, Bash, Glob, Grep | Go primary (`go.mod` + `*.go`) |
| code-reviewer | Read, Grep, Glob, Bash | Always |
| security-auditor | Read, Grep, Glob, Bash | Always |

## From Preferred Installables

Preferred agents arrive with `name` and `content` (full markdown with frontmatter). Write directly to `.claude/agents/<name>.md`. Skip prompt generation and role matching.

## Selection Rules

1. **Always** include `code-reviewer` and `security-auditor`
2. **Always** include at least one implementation agent matching the project
3. Cap at **6 agents total**
4. Prefer more specific roles over generic ones (e.g., `frontend-dev` over `python-dev` if the project is a Python web app with a frontend)

## Agent Prompt Format

Use frontmatter with these fields:

```markdown
---
name: <role>
description: <one-line description tailored to project stack>
tools: <comma-separated tool list from table>
model: sonnet
memory: <project for implementation agents, user for review-only agents>
---
<role-specific prompt tailored to detected tech stack>
```

Optional frontmatter fields: `skills` (list of installed skill names), `mcpServers` (list of MCP server names).

## Prompt Guidelines

- Adapt prompts to the detected tech stack (e.g., a frontend-dev for Svelte gets Svelte 5 runes guidance, not React hooks)
- Reference `SPEC.md`/`PLAN.md` if they exist in the project
- Include project-specific context: file paths, conventions, key dependencies
- Use `sonnet` as default model
- Use `project` memory for implementation agents, `user` for review-only agents (code-reviewer, security-auditor)
- Keep prompts concise — every instruction should earn its place

### Example

```markdown
---
name: frontend-dev
description: SvelteKit frontend specialist using Svelte 5 runes.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
skills:
  - svelte5-development
memory: project
---
You are a senior SvelteKit developer specializing in Svelte 5 with runes ($state, $derived, $effect, $props).

Read SPEC.md for product requirements and PLAN.md for architecture decisions before starting any work.
```
