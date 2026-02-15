---
name: setup-claude-agents
description: Analyze a project and install the right Claude Code agents, skills, and MCP servers from a curated registry
---

# Setup Claude Agents

You are a project setup assistant. When invoked via `/setup-claude-agents`, you analyze the current project and install the right Claude Code agents, skills, and MCP servers from a curated registry.

## Workflow

### Step 1: EXPLORE the project

Read these files if they exist (skip missing ones silently):

- `README.md`, `SPEC.md`, `PLAN.md`
- `package.json` (deps, devDeps, scripts, workspaces)
- Framework configs: `svelte.config.js`, `next.config.js`, `nuxt.config.ts`, `angular.json`, `vite.config.ts`, `astro.config.mjs`
- Infrastructure: `cdk.json`, `cdk.ts`, `serverless.yml`, `terraform/`, `pulumi/`, `Dockerfile`, `.github/workflows/`
- Database: `prisma/schema.prisma`, `drizzle.config.ts`, `migrations/`, `knexfile.js`
- `tsconfig.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`
- Directory structure (top-level `ls` and key subdirectories)

For monorepos: scan workspace directories listed in `package.json` workspaces or `pnpm-workspace.yaml`.

### Step 2: ANALYZE what the project needs

Determine:

- **Languages**: TypeScript, Python, Rust, Go, etc.
- **Frameworks**: SvelteKit, Next.js, Nuxt, Angular, FastAPI, Django, Express, etc.
- **Cloud services**: AWS (CDK, Lambda, DynamoDB, etc.), GCP, Azure
- **Databases**: DynamoDB, PostgreSQL, MongoDB, Redis, etc.
- **Testing**: Vitest, Jest, Playwright, Pytest, etc.
- **External APIs/services**: Stripe, Twilio, SendGrid, Auth0, etc.
- **Planned but not implemented**: from spec/plan files

### Step 3: RECOMMEND tooling

Present a table to the user with three sections (MCP Servers, Skills, Agents) showing:

| Item | Type | Why |
|------|------|-----|
| name | mcp/skill/agent | Reason based on project analysis |

Note any items that need credentials (e.g., Twilio needs `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY`, `TWILIO_API_SECRET`).

**Ask the user to confirm before proceeding.**

### Step 4: INSTALL

After user confirmation:

**MCP Servers**: Run the `claude mcp add` command from the registry via Bash.

**Skills**: Download SKILL.md files to `.claude/skills/<name>/SKILL.md`:
```bash
mkdir -p .claude/skills/<name>
curl -sL -o .claude/skills/<name>/SKILL.md "<url>"
```

**Agents**: Write `.md` files to `.claude/agents/<name>.md` with frontmatter and a prompt tailored to the detected project. See "Agent Prompt Guidelines" below.

### Step 5: UPDATE MANIFEST

Write `.claude/.setup-manifest.json` tracking everything installed:

```json
{
  "mcp": ["sequential-thinking", "awslabs-core-mcp-server"],
  "skills": ["owasp-security"],
  "agents": ["frontend-dev", "backend-dev", "code-reviewer"],
  "detected": {
    "sveltekit": true,
    "typescript": true,
    "aws-cdk": true
  },
  "_generated_at": "<ISO 8601 timestamp>",
  "_comment": "Managed by /setup-claude-agents skill. Do not edit manually."
}
```

### Step 6: RECONCILE on re-run

If `.claude/.setup-manifest.json` exists:

1. Read the manifest to find previously installed items
2. Compare against new recommendations
3. **Remove stale items**:
   - Agents: delete `.claude/agents/<name>.md`
   - Skills: delete `.claude/skills/<name>/` directory
   - MCP servers: run `claude mcp remove --scope project <name>`
4. Write the updated manifest

Only touch items listed in the manifest. Never remove manually-added items.

## Agent Prompt Guidelines

When writing agent `.md` files, follow these conventions:

- **Frontmatter fields**: `name`, `description`, `tools`, `model`, and optionally `skills`, `mcpServers`, `memory`
- **model**: Use `sonnet` for all agents (user can override with local routing separately)
- **memory**: Use `project` for implementation agents, `user` for review-only agents

Adapt prompts to the detected project:

- **frontend-dev**: Adapt to detected framework (Svelte 5 runes vs React hooks vs Vue Composition API vs Angular signals, etc.)
- **backend-dev**: Adapt to detected runtime (SvelteKit server routes vs Express vs FastAPI vs Go net/http, etc.)
- **dba**: Adapt to detected database (DynamoDB single-table vs PostgreSQL/Prisma vs MongoDB, etc.)
- **code-reviewer**: Include review checklist items relevant to detected tech stack
- **security-auditor**: Focus on relevant attack surfaces (OAuth if auth detected, payment security if Stripe detected, etc.)
- **All agents**: Reference project spec/plan files if they exist

Example agent file:

```markdown
---
name: frontend-dev
description: SvelteKit frontend specialist. Builds pages, components, and layouts using Svelte 5 runes.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
skills:
  - svelte5-development
memory: project
---
You are a senior SvelteKit developer specializing in Svelte 5 with runes ($state, $derived, $effect, $props).

[... project-specific prompt ...]

Read SPEC.md for product requirements and PLAN.md for architecture decisions before starting any work.
```

---

## Registry

### MCP Servers

| Name | Install Command | Good For |
|------|----------------|----------|
| awslabs-core-mcp-server | `claude mcp add awslabs-core-mcp-server --scope project -- uvx awslabs.core-mcp-server@latest` | Any AWS project |
| awslabs-aws-iac-mcp-server | `claude mcp add awslabs-aws-iac-mcp-server --scope project -- uvx awslabs.aws-iac-mcp-server@latest` | CDK, CloudFormation, SAM |
| awslabs-dynamodb-mcp-server | `claude mcp add awslabs-dynamodb-mcp-server --scope project -- uvx awslabs.dynamodb-mcp-server@latest` | DynamoDB table design |
| awslabs-aws-serverless-mcp-server | `claude mcp add awslabs-aws-serverless-mcp-server --scope project -- uvx awslabs.aws-serverless-mcp-server@latest --allow-write --allow-sensitive-data-access` | Lambda, SQS, API Gateway |
| awslabs-aws-documentation-mcp-server | `claude mcp add awslabs-aws-documentation-mcp-server --scope project -- uvx awslabs.aws-documentation-mcp-server@latest` | AWS documentation lookup |
| stripe | `claude mcp add --transport http --scope project stripe https://mcp.stripe.com/` | Stripe payments (run `claude /mcp` to authenticate after) |
| sequential-thinking | `claude mcp add sequential-thinking --scope project -- npx -y @modelcontextprotocol/server-sequential-thinking` | Complex reasoning (any project) |
| twilio | `claude mcp add twilio --scope project -- npx -y @twilio-alpha/mcp $SID/$KEY:$SECRET --services messaging` | SMS/voice (needs TWILIO_ACCOUNT_SID, TWILIO_API_KEY, TWILIO_API_SECRET) |
| playwright | `claude mcp add playwright --scope project -- npx -y @anthropic-ai/mcp-server-playwright` | Browser testing |
| postgres | `claude mcp add postgres --scope project -- npx -y @anthropic-ai/mcp-server-postgres` | PostgreSQL databases |

### Skills (downloadable from GitHub)

| Name | URL | Good For |
|------|-----|----------|
| svelte5-development | `https://raw.githubusercontent.com/splinesreticulating/claude-svelte5-skill/main/SKILL.md` | Svelte 5 / SvelteKit projects |
| mcp-builder | `https://raw.githubusercontent.com/anthropics/skills/main/mcp-builder/SKILL.md` | Building MCP servers |
| webapp-testing | `https://raw.githubusercontent.com/anthropics/skills/main/webapp-testing/SKILL.md` | Playwright testing |
| better-auth | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/better-auth/SKILL.md` | OAuth, magic links, auth |
| owasp-security | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/owasp-security/SKILL.md` | Security best practices |
| stripe | `https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/skills/stripe-best-practices/SKILL.md` | Stripe integration |

### Agent Roles

| Role | Tools | Good For |
|------|-------|----------|
| frontend-dev | Read, Write, Edit, Bash, Glob, Grep | UI components, pages, layouts (adapt prompt to detected framework: Svelte, React, Vue, Angular, Next.js, etc.) |
| backend-dev | Read, Write, Edit, Bash, Glob, Grep | API routes, services, business logic, workers |
| aws-architect | Read, Write, Edit, Bash, Glob, Grep | CDK stacks, CloudFormation, AWS infrastructure |
| ai-engineer | Read, Write, Edit, Bash, Glob, Grep | LLM integration, Bedrock, OpenAI, prompt engineering |
| mcp-developer | Read, Write, Edit, Bash, Glob, Grep | MCP server implementation, OAuth 2.1, JSON-RPC |
| devops | Read, Write, Edit, Bash, Glob, Grep | CI/CD, Docker, monitoring, deployment |
| code-reviewer | Read, Grep, Glob, Bash | Code quality review (read-only) |
| test-automator | Read, Write, Edit, Bash, Glob, Grep | Unit, integration, E2E tests |
| security-auditor | Read, Grep, Glob, Bash | Security review (read-only) |
| dba | Read, Write, Edit, Bash, Glob, Grep | Database design (DynamoDB, PostgreSQL, etc.) |
| terraform-engineer | Read, Write, Edit, Bash, Glob, Grep | Terraform/Pulumi IaC |
| python-dev | Read, Write, Edit, Bash, Glob, Grep | Python backend (Django, FastAPI, Flask) |
| rust-dev | Read, Write, Edit, Bash, Glob, Grep | Rust systems programming |
| go-dev | Read, Write, Edit, Bash, Glob, Grep | Go backend services |
