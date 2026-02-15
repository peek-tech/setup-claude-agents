# setup-claude-agents

A Claude Code plugin that analyzes your project and installs the right agents, skills, and MCP servers from a curated registry.

## Installation

```
/plugin install peek-tech/setup-claude-agents
```

## Usage

In any project directory, run:

```
/setup-claude-agents
```

The skill will:

1. **Explore** your project (package.json, framework configs, infra files, etc.)
2. **Analyze** what languages, frameworks, databases, and services you use
3. **Recommend** a table of MCP servers, skills, and agents tailored to your stack
4. **Install** everything after you confirm
5. **Track** what it installed in `.claude/.setup-manifest.json`
6. **Reconcile** on re-run — removes stale items, adds new ones

## What Gets Installed

### MCP Servers

AWS (core, IAC, DynamoDB, serverless, docs), Stripe, Twilio, Playwright, PostgreSQL, sequential-thinking, and more.

### Skills

Framework-specific skills (Svelte 5, MCP builder, webapp testing, Better Auth, OWASP security, Stripe best practices).

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
