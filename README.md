# setup-claude-agents

A Claude Code plugin that analyzes your project and installs the right agents, skills, slash commands, and MCP servers from the [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) community registry (~200+ curated entries).

## Installation

First, add the marketplace:

```
/plugin marketplace add peek-tech/setup-claude-agents
```

Then install the plugin:

```
/plugin install setup-claude-agents@peek-tech-setup-claude-agents
```

## Usage

In any project directory, run:

```
/setup-claude-agents
```

The skill will:

1. **Explore** your project (package.json, framework configs, infra files, etc.)
2. **Analyze** what languages, frameworks, databases, and services you use
3. **Fetch** the awesome-claude-code community registry (falls back to hardcoded list if offline)
4. **Recommend** MCP servers, agent skills, slash commands, reference resources, and agents tailored to your stack
5. **Install** everything after you confirm
6. **Track** what it installed in `.claude/.setup-manifest.json`
7. **Reconcile** on re-run — removes stale items, adds new ones

## What Gets Installed

### MCP Servers

AWS (core, IAC, DynamoDB, serverless, docs), Stripe, Twilio, Playwright, PostgreSQL, sequential-thinking, and more.

### Agent Skills (from community registry)

Dynamically discovered from the awesome-claude-code CSV based on your project's tech stack. Falls back to a curated set (Svelte 5, MCP builder, webapp testing, Better Auth, OWASP security, Stripe) if offline.

### Slash Commands (from community registry)

Matched from ~80 community-contributed slash commands covering version control, testing, documentation, code review, and more. Installed as `.claude/commands/<name>.md`.

### Reference Resources

CLAUDE.md files, hooks, and workflow guides recommended as links for manual exploration.

### Agents

Project-adapted agents with role-specific prompts: frontend-dev, backend-dev, aws-architect, ai-engineer, mcp-developer, devops, code-reviewer, test-automator, security-auditor, dba, terraform-engineer, python-dev, rust-dev, go-dev.

## Local LLM Routing (Optional)

The included `setup-local.sh` script configures local model routing via Ollama + Claude Code Router. This is machine-level infrastructure, separate from the per-project plugin.

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

This routes subagent work to local models (qwen3-coder:30b, glm-4.7-flash) while keeping main conversation and reasoning on Anthropic cloud.

## License

MIT
