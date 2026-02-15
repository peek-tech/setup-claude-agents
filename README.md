# setup-claude-agents

A Claude Code plugin that scans your project, figures out what tech stack you're using, and installs the right agents, skills, slash commands, hooks, MCP servers, and project rules — so Claude Code understands your codebase from the start.

It discovers tooling from three community registries:

- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — skills, slash commands, hooks, workflows (~200+ entries)
- [Official MCP Registry](https://registry.modelcontextprotocol.io) — MCP servers (searchable API)
- [Plugin marketplace](https://github.com/ComposioHQ/awesome-claude-plugins) — Claude Code plugins (~25 curated)

Falls back to a hardcoded registry if any source is unavailable.

## Installation

Add the marketplace, then install the plugin:

```
/plugin marketplace add peek-tech/setup-claude-agents
/plugin install setup-claude-agents@peek-tech-setup-claude-agents
```

## Usage

In any project directory, run:

```
/setup-claude-agents
```

The skill scans your project, shows you what it recommends, and **waits for your confirmation before installing anything**. Hooks require individual approval since they execute shell commands automatically.

### Quality filtering

An optional argument controls how strictly MCP servers from the registry are vetted:

| Level | What it checks |
|-------|----------------|
| `strict` | GitHub stars >= 10 **and** npm/PyPI downloads >= 1K/month |
| `moderate` | **(default)** Stars >= 5 **or** downloads >= 500/month |
| `light` | Only checks that a repository URL exists |
| `unfiltered` | No quality checks — shows all active servers |

```
/setup-claude-agents strict
```

Trusted publishers (Anthropic, AWS, Stripe, Microsoft, Twilio) bypass quality checks at all levels.

## How it works

1. **Explore** — reads dependency manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.), detects languages from source files, and checks for infrastructure patterns (Docker, CI/CD, Terraform, database migrations). Handles monorepos.
2. **Analyze** — builds a tech stack fingerprint: languages, dependencies, and infrastructure. Derives search terms from these (e.g., `@aws-sdk/client-dynamodb` produces search terms `aws`, `dynamodb`).
3. **Recommend** — searches all three registries for tooling that matches your stack. Shows everything in a table and waits for you to confirm.
4. **Install** — writes files to your project (see below). Hooks are prompted one at a time.
5. **Track** — saves a manifest at `.claude/.setup-manifest.json` so it knows what it installed.
6. **Reconcile** — on re-run, removes items that are no longer relevant and adds new ones. Never touches files it didn't install.

## What gets installed

### MCP Servers

[MCP servers](https://modelcontextprotocol.io) give Claude access to external tools and data sources. The skill discovers servers from the Official MCP Registry (with quality filtering) and matches against a curated list of vetted servers:

sequential-thinking (always), AWS (core, IAC, DynamoDB, serverless, documentation), Stripe, Twilio, Playwright, and PostgreSQL.

Some servers require credentials — the skill will note which environment variables you need to set (e.g., Twilio needs `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY`, `TWILIO_API_SECRET`).

Written to: `.mcp.json`

### Agents

[Agents](https://docs.anthropic.com/en/docs/claude-code/agents) are role-specific Claude personas with tailored prompts and tool access. The skill picks up to 6 agents matched to your project. Every project gets a **code-reviewer** and **security-auditor** (read-only). The rest are chosen from:

| Agent | When it's added |
|-------|-----------------|
| frontend-dev | React, Vue, Svelte, Angular, or other UI frameworks |
| backend-dev | Express, FastAPI, Django, Rails, Hono, or other server frameworks |
| aws-architect | AWS CDK, CloudFormation, or significant `@aws-sdk` usage |
| ai-engineer | AI/LLM deps (OpenAI, Anthropic, LangChain, etc.) or Claude plugin authoring |
| mcp-developer | MCP SDK in deps or custom MCP server code |
| devops | CI/CD configs, Dockerfiles, or deployment scripts |
| dba | Database schemas, migrations, or ORM deps (Prisma, Drizzle, SQLAlchemy, etc.) |
| terraform-engineer | Terraform or Pulumi files |
| test-automator | Test framework deps (Vitest, Jest, Playwright, pytest, etc.) |
| python-dev | Python is the primary language |
| rust-dev | Rust is the primary language |
| go-dev | Go is the primary language |

Agent prompts are adapted to your specific stack (e.g., a frontend-dev for a Svelte project gets Svelte 5 runes guidance, not React hooks).

Written to: `.claude/agents/<name>.md`

### Skills

[Skills](https://docs.anthropic.com/en/docs/claude-code/skills) are reusable instruction sets that teach Claude how to work with specific frameworks or tools. Discovered dynamically from the community registry based on your tech stack. Falls back to a curated set (Svelte 5, MCP builder, webapp testing, Better Auth, OWASP security, Stripe) if the registry is unavailable.

Written to: `.claude/skills/<name>/SKILL.md`

### Slash Commands

Slash commands are markdown prompts you invoke with `/<name>` in Claude Code. Matched from community-contributed commands covering version control, testing, documentation, code review, and more.

Written to: `.claude/commands/<name>.md`

### Hooks

[Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) are shell commands that run automatically on Claude Code events (e.g., before a file write, after a tool call). Because they execute code on your machine, each hook is presented individually — you see the exact shell command and approve or reject it one by one.

Written to: `.claude/settings.json`

### Project Rules

Baseline rules are appended to `CLAUDE.md` in your project root, filtered by your tech stack. For example, "Use Typescript strict mode" is only added for TypeScript projects, and "Use functional components and hooks" only for React projects. Rules that already exist in your `CLAUDE.md` are skipped.

Rules are **append-only** — they're never removed on re-run, since you may have customized them.

### Reference Resources and Plugins

CLAUDE.md files, workflow guides, and plugins are shown as links for you to explore and install manually. They are not auto-installed.

## Re-running

Running `/setup-claude-agents` again is safe. The skill reads its manifest (`.claude/.setup-manifest.json`) to see what it previously installed, compares against fresh recommendations, and:

- **Removes** agents, skills, commands, MCP servers, and hooks that are no longer relevant
- **Adds** new items that match your updated stack
- **Leaves alone** anything it didn't install (your manual additions are never touched)
- **Appends** new project rules to `CLAUDE.md` without removing existing ones

## Files written

| Path | What |
|------|------|
| `.mcp.json` | MCP server configurations |
| `.claude/agents/<name>.md` | Agent definitions |
| `.claude/skills/<name>/SKILL.md` | Skill instructions |
| `.claude/commands/<name>.md` | Slash commands |
| `.claude/settings.json` | Hook configurations |
| `.claude/.setup-manifest.json` | Tracks what was installed (for re-run reconciliation) |
| `CLAUDE.md` | Baseline project rules (appended, not overwritten) |

## Local LLM Routing (Optional)

The included `setup-local.sh` script is separate from the plugin. It configures local model routing via Ollama and Claude Code Router so subagent work runs on local models while the main conversation stays on Anthropic cloud.

```bash
# Clone and run the local setup
git clone https://github.com/peek-tech/setup-claude-agents.git
cd setup-claude-agents

# Local Ollama
./setup-local.sh

# Remote Ollama (e.g., Mac Mini on your network)
OLLAMA_HOST=h0pp3r.local ./setup-local.sh

# Preview changes without applying
./setup-local.sh --dry-run
```

Requires Node.js 18+. See the script header for full details.

## License

MIT
