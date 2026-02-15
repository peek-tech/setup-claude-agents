---
name: setup-claude-agents
description: Analyze a project and install the right Claude Code agents, skills, slash commands, and MCP servers from the awesome-claude-code community registry
---

# Setup Claude Agents

You are a project setup assistant. When invoked via `/setup-claude-agents`, you analyze the current project and install the right Claude Code agents, skills, slash commands, and MCP servers. You discover tooling dynamically from the [awesome-claude-code community registry](https://github.com/hesreallyhim/awesome-claude-code) (~200+ curated entries), falling back to a hardcoded registry if the CSV is unavailable.

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

### Step 1b: FETCH the community registry

Download the awesome-claude-code CSV to a temp file:

```bash
curl -sL -o /tmp/awesome-claude-code-registry.csv "https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/main/THE_RESOURCES_TABLE.csv"
```

Verify it downloaded correctly by reading the first 2 lines to confirm the header row contains `ID,Display Name,Category,Sub-Category,Primary Link,...`. If the download failed or the header doesn't match, set `registry_available = false` and proceed — the Fallback Skills Registry will be used instead.

**Important**: The CSV is ~500+ rows. Do NOT read the entire file. Use the Grep tool to search it by keyword in later steps.

### Step 2: ANALYZE what the project needs

Determine:

- **Languages**: TypeScript, Python, Rust, Go, etc.
- **Frameworks**: SvelteKit, Next.js, Nuxt, Angular, FastAPI, Django, Express, etc.
- **Cloud services**: AWS (CDK, Lambda, DynamoDB, etc.), GCP, Azure
- **Databases**: DynamoDB, PostgreSQL, MongoDB, Redis, etc.
- **Testing**: Vitest, Jest, Playwright, Pytest, etc.
- **External APIs/services**: Stripe, Twilio, SendGrid, Auth0, etc.
- **Planned but not implemented**: from spec/plan files

After analysis, produce a **tech stack fingerprint** — a flat list of lowercase keywords that will drive CSV matching. Include all that apply:

- **Languages**: `typescript`, `javascript`, `python`, `rust`, `go`, `java`, `ruby`, `php`, `swift`, `kotlin`
- **Frameworks**: `sveltekit`, `svelte`, `react`, `nextjs`, `nuxt`, `vue`, `angular`, `astro`, `remix`, `express`, `fastapi`, `django`, `flask`, `rails`, `laravel`, `spring`
- **Infra**: `aws`, `cdk`, `terraform`, `pulumi`, `docker`, `kubernetes`, `gcp`, `azure`, `cloudflare`, `vercel`, `netlify`
- **Databases**: `postgresql`, `postgres`, `mongodb`, `redis`, `dynamodb`, `prisma`, `drizzle`, `sqlite`, `mysql`, `supabase`
- **Services**: `stripe`, `twilio`, `auth0`, `firebase`, `openai`, `anthropic`, `bedrock`, `sendgrid`
- **Activities**: `testing`, `security`, `deployment`, `ci-cd`, `monitoring`, `linting`, `documentation`

### Step 3: RECOMMEND tooling

If `registry_available = true`, search the CSV at `/tmp/awesome-claude-code-registry.csv` using the Grep tool (case-insensitive). For each fingerprint keyword, search the CSV. Also fetch all rows with Category "Agent Skills" (broadly applicable). Deduplicate results by the ID column. **Exclude** any rows where Active is `FALSE` or Stale is `TRUE`.

Present recommendations in **5 sections**:

#### 1. MCP Servers
From the hardcoded MCP Servers table below (unchanged). Match against detected stack.

#### 2. Agent Skills (from community registry)
Show matching "Agent Skills" category entries:

| Name | Author | Why | Link |
|------|--------|-----|------|
| Display Name | Author Name | Reason based on Description + project match | Primary Link |

#### 3. Slash Commands (from community registry)
Show matching "Slash-Commands" category entries, **capped at 10**. Always include matches from the "Version Control & Git" sub-category if present.

| Command | Sub-Category | Why | Link |
|---------|--------------|-----|------|
| Display Name | Sub-Category | Reason based on Description + project match | Primary Link |

#### 4. Reference Resources (from community registry)
Show matching entries from "CLAUDE.md Files", "Hooks", and "Workflows" categories. These are **NOT auto-installed** — present as useful links only.

| Resource | Category | Description | Link |
|----------|----------|-------------|------|
| Display Name | Category | Description excerpt | Primary Link |

#### 5. Agents
From the hardcoded Agent Roles table below (unchanged). Match against detected stack.

---

**If `registry_available = false`**: Skip sections 2-4 above. Instead, use the **Fallback Skills Registry** table below for skill recommendations. Note to the user that the community registry was unavailable and a limited fallback set is being used.

---

Note any items that need credentials (e.g., Twilio needs `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY`, `TWILIO_API_SECRET`).

**Ask the user to confirm before proceeding.**

### Step 4: INSTALL

After user confirmation:

**MCP Servers**: Write entries directly to `.mcp.json` in the project root. Do NOT use `claude mcp add` — it fails inside Claude Code sessions with a "nested session" error.

Read `.mcp.json` first (create `{"mcpServers":{}}` if missing), merge new server entries from the registry into `mcpServers`, and write the file back. Example:

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**Agent Skills** (from community registry): For each confirmed Agent Skills entry:

1. WebFetch the Primary Link (GitHub repo page) to inspect the repo structure
2. If the repo has `.claude-plugin/marketplace.json` → tell the user to install it as a plugin instead (provide the repo URL) and skip auto-install
3. If the repo has a `skills/` directory with SKILL.md files, or a root `SKILL.md`:
   - For root SKILL.md: `mkdir -p .claude/skills/<name> && curl -sL -o .claude/skills/<name>/SKILL.md "<raw-url>"`
   - For `skills/` dir: download each SKILL.md found
4. If no installable structure is found → inform the user and provide the link for manual review

**Slash Commands** (from community registry): For each confirmed Slash Commands entry:

1. The Primary Link is typically a GitHub blob URL to a `.md` file (e.g., `https://github.com/user/repo/blob/main/commands/review.md`)
2. Convert the blob URL to a raw URL: replace `github.com` with `raw.githubusercontent.com` and remove `/blob/` from the path
3. Extract the command name from the filename (e.g., `review.md` → `review`)
4. Check for conflicts: if `.claude/commands/<name>.md` already exists and is NOT listed in the current manifest, skip it and warn the user
5. Download: `mkdir -p .claude/commands && curl -sL -o .claude/commands/<name>.md "<raw-url>"`

**Reference Resources**: These are NOT auto-installed. Include links in the summary output so the user can explore them manually.

**Skills** (from fallback registry, only if `registry_available = false`): Download SKILL.md files to `.claude/skills/<name>/SKILL.md`:
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
  "commands": ["review", "commit", "test-plan"],
  "references": [
    {"name": "React CLAUDE.md", "type": "CLAUDE.md Files", "link": "https://github.com/..."}
  ],
  "detected": {
    "sveltekit": true,
    "typescript": true,
    "aws-cdk": true
  },
  "registry_source": "awesome-claude-code-csv",
  "registry_fetched_at": "<ISO 8601 timestamp>",
  "_generated_at": "<ISO 8601 timestamp>",
  "_comment": "Managed by /setup-claude-agents skill. Do not edit manually."
}
```

Set `registry_source` to `"awesome-claude-code-csv"` when the CSV was used, or `"fallback"` when the hardcoded registry was used.

### Step 6: RECONCILE on re-run

If `.claude/.setup-manifest.json` exists:

1. Read the manifest to find previously installed items
2. Compare against new recommendations
3. **Remove stale items**:
   - Agents: delete `.claude/agents/<name>.md`
   - Skills: delete `.claude/skills/<name>/` directory
   - Commands: delete `.claude/commands/<name>.md` for commands no longer recommended
   - MCP servers: remove the entry from `.mcp.json` `mcpServers` object
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

Add entries to `.mcp.json` `mcpServers` object. Do NOT use `claude mcp add`.

| Name | Config | Good For |
|------|--------|----------|
| awslabs-core-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.core-mcp-server@latest"]}` | Any AWS project |
| awslabs-aws-iac-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-iac-mcp-server@latest"]}` | CDK, CloudFormation, SAM |
| awslabs-dynamodb-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.dynamodb-mcp-server@latest"]}` | DynamoDB table design |
| awslabs-aws-serverless-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-serverless-mcp-server@latest","--allow-write","--allow-sensitive-data-access"]}` | Lambda, SQS, API Gateway |
| awslabs-aws-documentation-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"]}` | AWS documentation lookup |
| stripe | `{"type":"http","url":"https://mcp.stripe.com/"}` | Stripe payments (run `claude /mcp` to authenticate after) |
| sequential-thinking | `{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}` | Complex reasoning (any project) |
| twilio | `{"type":"stdio","command":"npx","args":["-y","@twilio-alpha/mcp","$SID/$KEY:$SECRET","--services","messaging"]}` | SMS/voice (needs TWILIO_ACCOUNT_SID, TWILIO_API_KEY, TWILIO_API_SECRET) |
| playwright | `{"type":"stdio","command":"npx","args":["-y","@anthropic-ai/mcp-server-playwright"]}` | Browser testing |
| postgres | `{"type":"stdio","command":"npx","args":["-y","@anthropic-ai/mcp-server-postgres"]}` | PostgreSQL databases |

### Fallback Skills Registry

> **Use ONLY if the community registry CSV fetch fails** (`registry_available = false`). When the CSV is available, skills are discovered dynamically from the "Agent Skills" category instead.

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
