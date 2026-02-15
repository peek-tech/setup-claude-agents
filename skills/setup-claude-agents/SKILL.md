---
name: setup-claude-agents
description: Analyze a project and install the right Claude Code agents, skills, slash commands, MCP servers, and plugins from community registries
allowed-tools: Read, Write, Edit, Glob, Grep, WebFetch, Bash(curl *), Bash(gh api *), Bash(mkdir *), Bash(ls *), Bash(wc *)
---

# Setup Claude Agents

You are a project setup assistant. When invoked via `/setup-claude-agents`, you analyze the current project and install the right Claude Code agents, skills, slash commands, MCP servers, and plugins. You discover tooling dynamically from three registries:

1. **[awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** (~200+ curated skills, commands, resources as CSV)
2. **[Official MCP Registry](https://registry.modelcontextprotocol.io)** (searchable API for MCP servers)
3. **[Plugin marketplace](https://github.com/ComposioHQ/awesome-claude-plugins)** (~25 curated Claude Code plugins as JSON)

Falls back to a hardcoded registry if external sources are unavailable.

## CRITICAL: MCP Server Installation

**NEVER use `claude mcp add` — it causes a fatal "nested session" error inside Claude Code.**

Always write MCP server configs directly to `.mcp.json` using the Read and Write tools. See Step 4 for the exact procedure.

## Arguments

`/setup-claude-agents [filter-level]`

The optional `filter-level` argument controls quality filtering for MCP Registry API results. Parse `$ARGUMENTS` for one of these values:

| Level | Description |
|-------|-------------|
| `strict` | Trusted publishers pass automatically. Others need: GitHub stars ≥10 AND (npm ≥1K downloads/month OR PyPI ≥1K/month). Repository URL required. |
| `moderate` | **(default if omitted)** Trusted publishers pass. Others need: GitHub stars ≥5 OR npm ≥500/month. Repository URL required. |
| `light` | Only check: `repository.url` exists, `status == "active"`. No external API calls for quality. Fast but admits unvetted servers. |
| `unfiltered` | No quality filtering. All active registry results are shown. |

If `$ARGUMENTS` contains an unrecognized value, treat it as `moderate` and note the fallback to the user.

**Trusted publishers** (bypass quality checks at all filter levels):
- `@modelcontextprotocol/*`, `@anthropic-ai/*` (Anthropic)
- `awslabs.*` (AWS)
- `com.stripe/*` (Stripe)
- `@playwright/*` (Microsoft)
- `@twilio-alpha/*` (Twilio)

## Workflow

### Step 1: EXPLORE the project

Scan the project to build a raw inventory. Skip missing files silently.

#### 1a. Dependency manifests

Read every manifest that exists and extract dependency names:

| Manifest | Extract |
|----------|---------|
| `package.json` | keys from `dependencies`, `devDependencies`, `peerDependencies`; note `scripts`, `workspaces` |
| `pyproject.toml` | `[project.dependencies]`, `[tool.poetry.dependencies]` |
| `requirements.txt` / `requirements/*.txt` | each line (strip version specifiers) |
| `Cargo.toml` | `[dependencies]`, `[dev-dependencies]` |
| `go.mod` | all `require` entries |
| `Gemfile` | all `gem` names |
| `composer.json` | `require`, `require-dev` keys |
| `build.gradle` / `build.gradle.kts` | `implementation`, `testImplementation` coordinates |
| `pom.xml` | `<dependency>` `<artifactId>` values |
| `mix.exs` | `deps` function return values |
| `pubspec.yaml` | `dependencies`, `dev_dependencies` keys |

If a manifest type not listed here is present, extract dependency names the same way.

For monorepos: also scan workspace directories listed in `package.json` workspaces, `pnpm-workspace.yaml`, `lerna.json`, etc.

#### 1b. Languages

Glob for source file extensions at top-level and `src/` (not the entire tree) to detect languages. Examples: `*.ts`/`*.tsx` → TypeScript, `*.py` → Python, `*.rs` → Rust, `*.go` → Go, `*.rb` → Ruby, `*.java`/`*.kt` → Java/Kotlin, `*.php` → PHP, `*.ex`/`*.exs` → Elixir, `*.dart` → Dart, `*.swift` → Swift.

#### 1c. Infrastructure patterns

Check for presence of:

- **Containers**: `Dockerfile`, `docker-compose.yml`
- **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`, `Jenkinsfile`
- **IaC**: `terraform/`, `*.tf`, `pulumi/`, `cdk.json`, `serverless.yml`
- **Database schemas**: `prisma/`, `migrations/`, `*.sql`, `drizzle.config.*`
- **Claude Code**: `.claude-plugin/`, `.claude/`, `SKILL.md`, `.mcp.json`
- **Monorepo**: `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`

#### 1d. Documentation

Read `README.md`, `SPEC.md`, `PLAN.md` if present. Note planned features, architecture, and tech choices described there.

Also run a top-level `ls` and check key subdirectories for overall project structure.

### Step 1b: FETCH registries

#### Community registry (skills, commands, resources)

Download the awesome-claude-code CSV to a temp file:

```bash
curl -sL -o /tmp/awesome-claude-code-registry.csv "https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/main/THE_RESOURCES_TABLE.csv"
```

Verify it downloaded correctly by reading the first 2 lines to confirm the header row contains `ID,Display Name,Category,Sub-Category,Primary Link,...`. If the download failed or the header doesn't match, set `registry_available = false` and proceed — the Fallback Skills Registry will be used instead.

**Important**: The CSV is ~500+ rows. Do NOT read the entire file. Use the Grep tool to search it by keyword in later steps.

#### Plugin marketplace

Download the plugin marketplace index:

```bash
curl -sL -o /tmp/claude-plugins-marketplace.json "https://raw.githubusercontent.com/ComposioHQ/awesome-claude-plugins/main/marketplace.json"
```

This JSON contains ~25 curated Claude Code plugins with `name`, `category`, `description`, `author`, and `tags` fields. If the download fails, set `plugins_available = false` and skip plugin recommendations.

#### Official MCP Registry (MCP servers)

The Official MCP Registry at `registry.modelcontextprotocol.io` provides a searchable API for discovering MCP servers. It is queried directly in Step 3 — no upfront download needed.

### Step 2: ANALYZE what the project needs

Build a **tech stack fingerprint** from what Step 1 discovered. This is NOT a fixed vocabulary — it's derived from the actual project.

#### Raw fingerprint

Collect three lists from Step 1 results:

- **languages** — detected from source file extensions (e.g. `typescript`, `python`, `rust`, `go`)
- **dependencies** — actual package/crate/module names from manifests (e.g. `svelte`, `@aws-sdk/client-dynamodb`, `prisma`, `fastapi`)
- **infrastructure** — patterns detected in 1c (e.g. `docker`, `github-actions`, `cdk`, `terraform`, `prisma-migrations`)

#### Search terms

Derive a flat list of lowercase search keywords from the raw fingerprint:

1. Start with all language names
2. Add each dependency name, but:
   - Strip scopes/orgs (`@org/foo` → `foo`)
   - Split on `-` and `/` to get sub-terms (`@aws-sdk/client-dynamodb` → `aws`, `sdk`, `client`, `dynamodb`)
   - Add known associations: Next.js → also add `react`; Nuxt → also add `vue`; SvelteKit → also add `svelte`; etc.
3. Add infrastructure pattern names
4. Add terms from README/SPEC/PLAN that indicate planned tech choices

**Filtering**: Skip pure-utility deps that don't indicate the tech stack (e.g. `lodash`, `chalk`, `debug`, `dotenv`, `uuid`, `rimraf`). Focus on frameworks, databases, cloud SDKs, runtimes, and tools.

### Step 3: RECOMMEND tooling

If `registry_available = true`, search the CSV at `/tmp/awesome-claude-code-registry.csv` using the Grep tool (case-insensitive). For each **search term** from the fingerprint, search the CSV. Also fetch all rows with Category "Agent Skills" (broadly applicable). Deduplicate results by the ID column. **Exclude** any rows where Active is `FALSE` or Stale is `TRUE`.

Present recommendations in **6 sections**:

#### 1. MCP Servers

**a) Search the Official MCP Registry** for each relevant search term (frameworks, databases, cloud providers — skip generic terms like language names):

```bash
curl -sL "https://registry.modelcontextprotocol.io/v0.1/servers?search=<term>&version=latest&limit=5"
```

From each result, construct a `.mcp.json` config using the `packages` or `remotes` data:

- `registryType: "npm"` → `{"type":"stdio","command":"npx","args":["-y","<identifier>"]}`
- `registryType: "pypi"` → `{"type":"stdio","command":"uvx","args":["<identifier>"]}`
- `remotes` with `type: "streamable-http"` → `{"type":"http","url":"<url>"}`

Deduplicate by server name. Skip servers with `status` other than `"active"`. Cap at **10 registry results**.

**IMPORTANT**: These configs are written directly to `.mcp.json` in Step 4. Never use `claude mcp add`.

**b) Apply quality filtering** to each registry result (not curated entries — those are pre-vetted). For each result, check if the package identifier matches a **trusted publisher** (see Arguments section). If trusted, keep it. Otherwise, apply the filter level:

**`strict`** — run both checks, must pass both:
1. GitHub stars: extract `repository.url`, run `gh api repos/{owner}/{repo} --jq '.stargazers_count'` — require ≥10
2. Download count: for npm packages, run `curl -sL "https://api.npmjs.org/downloads/point/last-month/<identifier>"` and check `.downloads` ≥1,000. For PyPI, run `curl -sL "https://pypistats.org/api/packages/<identifier>/recent"` and check `.data.last_month` ≥1,000.

**`moderate`** (default) — run both checks, must pass at least one:
1. GitHub stars ≥5
2. npm/PyPI downloads ≥500/month

**`light`** — only check that `repository.url` exists and is non-empty. No API calls.

**`unfiltered`** — skip all quality checks.

If a quality check API call fails (404, timeout), treat that signal as absent — don't disqualify the server, but don't count it as passing either. In `strict` mode, a server must pass the remaining check. In `moderate`, it passes if the other check succeeds.

Show filtered-out servers in a collapsed note (e.g., "3 servers filtered out by quality checks") so the user knows they exist.

**c) Check the Curated MCP Servers table** below. Match each server's **Match When** criteria against the raw fingerprint. These curated entries have vetted configs and take priority over registry results for the same server.

**Merge** results from (a), (b), and (c). Curated entries override registry entries when both match the same server.

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
From the hardcoded Agent Roles table below. Match each agent's **Match When** criteria against the raw fingerprint (dependencies, languages, infrastructure patterns).

**Selection rules:**
1. Always include `code-reviewer` and `security-auditor` (read-only, universally useful)
2. Always include at least one **implementation agent** (with Write/Edit tools) matching the project's primary language or activity — never recommend only read-only agents
3. Cap at **6 agents total**; prioritize agents matching the project's primary activity

#### 6. Plugins (from plugin marketplace)

If `plugins_available = true`, read `/tmp/claude-plugins-marketplace.json` and match plugins whose `tags` overlap with the search terms. Show matching entries:

| Plugin | Category | Why | Repo |
|--------|----------|-----|------|
| name | category | Reason based on description + tag match | `https://github.com/ComposioHQ/awesome-claude-plugins/tree/main/<name>` |

Plugins are **NOT auto-installed** — present as links for the user to install via `claude plugin add <repo-url>`.

---

**If `registry_available = false`**: Skip sections 2-4 above. Instead, use the **Fallback Skills Registry** table below for skill recommendations. Note to the user that the community registry was unavailable and a limited fallback set is being used.

---

Note any items that need credentials (e.g., Twilio needs `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY`, `TWILIO_API_SECRET`).

**Ask the user to confirm before proceeding.**

### Step 4: INSTALL

After user confirmation:

**MCP Servers — NEVER use `claude mcp add`** (it fails with a fatal "nested session" error). Write entries directly to `.mcp.json` in the project root using the Read and Write tools:

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
  "mcp_from_registry": ["io.github.example/some-server"],
  "skills": ["owasp-security"],
  "agents": ["frontend-dev", "backend-dev", "code-reviewer"],
  "commands": ["review", "commit", "test-plan"],
  "plugins": [],
  "references": [
    {"name": "React CLAUDE.md", "type": "CLAUDE.md Files", "link": "https://github.com/..."}
  ],
  "detected": {
    "languages": ["typescript", "python"],
    "dependencies": ["svelte", "@aws-sdk/client-dynamodb", "prisma"],
    "infrastructure": ["docker", "github-actions", "cdk"],
    "search_terms": ["svelte", "aws", "dynamodb", "prisma", "typescript", "python"]
  },
  "registries_used": ["awesome-claude-code-csv", "mcp-registry-api", "plugin-marketplace"],
  "registry_fetched_at": "<ISO 8601 timestamp>",
  "_generated_at": "<ISO 8601 timestamp>",
  "_comment": "Managed by /setup-claude-agents skill. Do not edit manually."
}
```

`registries_used` tracks which sources were available. Possible values: `"awesome-claude-code-csv"`, `"mcp-registry-api"`, `"plugin-marketplace"`, `"fallback"`.

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

### Official MCP Registry API

Search for MCP servers dynamically using the Official MCP Registry:

```
GET https://registry.modelcontextprotocol.io/v0.1/servers?search=<keyword>&version=latest&limit=<n>
```

Response schema:
```json
{
  "servers": [{
    "server": {
      "name": "org.name/server-name",
      "description": "What this server does",
      "version": "1.0.0",
      "packages": [{
        "registryType": "npm",          // or "pypi", "oci"
        "identifier": "@scope/pkg-name", // npm package, PyPI package, or Docker image
        "version": "1.0.0",
        "transport": { "type": "stdio" },
        "environmentVariables": [{ "name": "API_KEY", "isSecret": true }]
      }],
      "remotes": [{
        "type": "streamable-http",       // or "sse"
        "url": "https://example.com/mcp"
      }]
    },
    "_meta": {
      "io.modelcontextprotocol.registry/official": {
        "status": "active",
        "isLatest": true
      }
    }
  }],
  "metadata": { "nextCursor": "...", "count": 5 }
}
```

**Config construction rules** — convert registry entries to `.mcp.json` format:

| Registry field | `.mcp.json` config |
|----------------|-------------------|
| `packages[0].registryType == "npm"` | `{"type":"stdio","command":"npx","args":["-y","<identifier>"]}` |
| `packages[0].registryType == "pypi"` | `{"type":"stdio","command":"uvx","args":["<identifier>"]}` |
| `remotes[0].type == "streamable-http"` | `{"type":"http","url":"<url>"}` |
| `environmentVariables` present | Note required env vars for user; add to config `"env"` if needed |

Prefer `packages` (local stdio) over `remotes` (HTTP) when both are available.

### Curated MCP Servers

Vetted server configs that take priority over registry results. Add entries to `.mcp.json` `mcpServers` object. Do NOT use `claude mcp add`.

| Name | Config | Match When |
|------|--------|------------|
| sequential-thinking | `{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}` | Always |
| awslabs-core-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.core-mcp-server@latest"]}` | Any dep containing `aws` or `@aws-sdk`, OR `cdk.json` present |
| awslabs-aws-iac-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-iac-mcp-server@latest"]}` | `cdk.json` present, OR `aws-cdk-lib` in deps, OR CloudFormation/SAM templates |
| awslabs-dynamodb-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.dynamodb-mcp-server@latest"]}` | `dynamodb` in any dep name |
| awslabs-aws-serverless-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-serverless-mcp-server@latest","--allow-write","--allow-sensitive-data-access"]}` | Lambda/SQS/API Gateway configs, OR `serverless.yml` present |
| awslabs-aws-documentation-mcp-server | `{"type":"stdio","command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"]}` | Any dep containing `aws` or `@aws-sdk`, OR `cdk.json` present |
| stripe | `{"type":"http","url":"https://mcp.stripe.com/"}` | `stripe` in any dep name (run `claude /mcp` to authenticate after) |
| twilio | `{"type":"stdio","command":"npx","args":["-y","@twilio-alpha/mcp","$SID/$KEY:$SECRET","--services","messaging"]}` | `twilio` in any dep name (needs TWILIO_ACCOUNT_SID, TWILIO_API_KEY, TWILIO_API_SECRET) |
| playwright | `{"type":"stdio","command":"npx","args":["-y","@anthropic-ai/mcp-server-playwright"]}` | `playwright` or `@playwright/test` in deps |
| postgres | `{"type":"stdio","command":"npx","args":["-y","@anthropic-ai/mcp-server-postgres"]}` | `pg`, `postgres`, `prisma`, or `drizzle` in deps, OR `.sql` migration files |

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

| Role | Tools | Match When |
|------|-------|------------|
| frontend-dev | Read, Write, Edit, Bash, Glob, Grep | UI framework deps (react, vue, svelte, angular, solid, lit, etc.) OR `.svelte`/`.vue`/`.jsx`/`.tsx` files |
| backend-dev | Read, Write, Edit, Bash, Glob, Grep | Server framework deps (express, fastapi, django, flask, gin, actix-web, spring, rails, laravel, phoenix, hono, etc.) |
| aws-architect | Read, Write, Edit, Bash, Glob, Grep | `cdk.json` OR `aws-cdk-lib` in deps OR CloudFormation/SAM templates OR significant `@aws-sdk/*` usage |
| ai-engineer | Read, Write, Edit, Bash, Glob, Grep | `.claude-plugin/` OR SKILL.md authoring OR AI/LLM deps (openai, anthropic, langchain, llamaindex, transformers, etc.) |
| mcp-developer | Read, Write, Edit, Bash, Glob, Grep | `@modelcontextprotocol/sdk` in deps OR MCP server code OR `.mcp.json` with custom servers |
| devops | Read, Write, Edit, Bash, Glob, Grep | CI/CD configs OR Dockerfiles OR deployment scripts |
| dba | Read, Write, Edit, Bash, Glob, Grep | Database schemas, migration files, ORM deps (prisma, drizzle, sqlalchemy, typeorm, diesel, gorm, ecto, etc.) |
| terraform-engineer | Read, Write, Edit, Bash, Glob, Grep | `*.tf` files OR `terraform/` OR `pulumi/` |
| test-automator | Read, Write, Edit, Bash, Glob, Grep | Test framework deps (vitest, jest, playwright, pytest, rspec, junit, etc.) |
| python-dev | Read, Write, Edit, Bash, Glob, Grep | Python is primary language (`pyproject.toml`/`requirements.txt` + significant `*.py` files) |
| rust-dev | Read, Write, Edit, Bash, Glob, Grep | Rust is primary language (`Cargo.toml` + `*.rs` files) |
| go-dev | Read, Write, Edit, Bash, Glob, Grep | Go is primary language (`go.mod` + `*.go` files) |
| code-reviewer | Read, Grep, Glob, Bash | Always |
| security-auditor | Read, Grep, Glob, Bash | Always |
