#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Local LLM Routing Setup
# =============================================================================
#
# Machine-level infrastructure for routing Claude Code subagents to local
# models via Ollama and Claude Code Router. Separate from per-project tooling
# (which is handled by the /setup-claude-agents skill).
#
# Usage:
#   ./setup-local.sh                                        # Ollama on same machine
#   OLLAMA_HOST=h0pp3r.local ./setup-local.sh               # Ollama on remote machine
#   OLLAMA_HOST=192.168.1.50 ./setup-local.sh               # Ollama by IP
#   ./setup-local.sh --dry-run                              # Show what would change
#
# What this script does:
#   1. Installs Ollama (if local and not present)
#   2. Pulls recommended coding models
#   3. Installs Claude Code Router (ccr)
#   4. Writes router config with provider/model assignments
#   5. Patches agent .md files to route to local models
#
# Requirements:
#   - Node.js 18+ (for ccr)
#   - (Optional) Existing agent .md files in .claude/agents/
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
DRY_RUN=false

# ── Local LLM host configuration ──
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: ./setup-local.sh [--dry-run]"
      echo ""
      echo "Sets up local LLM routing via Ollama + Claude Code Router."
      echo ""
      echo "Environment variables:"
      echo "  OLLAMA_HOST   Hostname/IP of the machine running Ollama (default: localhost)"
      echo "  OLLAMA_PORT   Port Ollama is listening on (default: 11434)"
      echo ""
      echo "Examples:"
      echo "  ./setup-local.sh                                        # Local Ollama"
      echo "  OLLAMA_HOST=h0pp3r.local ./setup-local.sh               # Remote Ollama"
      echo "  OLLAMA_HOST=192.168.1.50 ./setup-local.sh               # Remote by IP"
      exit 0
      ;;
  esac
done

# Helpers
log_section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
log_step()    { echo -e "  ${GREEN}✓${NC} $1"; }
log_skip()    { echo -e "  ${YELLOW}⊘${NC} $1 (skipped — already installed)"; }
log_warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_info()    { echo -e "  ${NC}  $1"; }

run_cmd() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} $1"
  else
    eval "$1"
  fi
}

check_command() {
  command -v "$1" &>/dev/null
}

# =============================================================================
# Prerequisites
# =============================================================================

log_section "Checking Prerequisites"

if check_command node; then
  log_step "Node.js $(node --version)"
else
  echo -e "${RED}Node.js not found (required for Claude Code Router).${NC}"
  exit 1
fi

IS_REMOTE_OLLAMA=false
if [[ "$OLLAMA_HOST" != "localhost" && "$OLLAMA_HOST" != "127.0.0.1" ]]; then
  IS_REMOTE_OLLAMA=true
  log_step "Remote Ollama host: ${OLLAMA_URL}"
  log_info "Make sure Ollama is running on ${OLLAMA_HOST} and listening on 0.0.0.0:${OLLAMA_PORT}"
  log_info "(Set OLLAMA_HOST=0.0.0.0 in Ollama's env on the remote machine)"
elif check_command ollama; then
  log_step "Ollama found (local)"
else
  log_warn "Ollama not found locally. Will install."
fi

# =============================================================================
# 1. Install Ollama (local only)
# =============================================================================

log_section "Ollama Setup"

if ! $IS_REMOTE_OLLAMA; then
  if ! check_command ollama; then
    log_step "Installing Ollama"
    run_cmd "curl -fsSL https://ollama.com/install.sh | sh"
  else
    log_skip "Ollama"
  fi
fi

# =============================================================================
# 2. Pull recommended coding models
# =============================================================================

log_section "Model Setup"

if $IS_REMOTE_OLLAMA; then
  log_step "Remote Ollama at ${OLLAMA_URL} — pull models on that machine:"
  log_info "  ssh ${OLLAMA_HOST} 'ollama pull qwen3-coder:30b'"
  log_info "  ssh ${OLLAMA_HOST} 'ollama pull glm-4.7-flash'"
else
  log_step "Pulling local models (this may take a while on first run)"
  run_cmd "ollama pull qwen3-coder:30b"
  run_cmd "ollama pull glm-4.7-flash"
fi

echo ""
echo -e "  ${CYAN}Recommended models for Mac Mini 64GB:${NC}"
echo ""
echo -e "  ${GREEN}Primary coding model:${NC}"
echo -e "    qwen3-coder:30b    30B params, 3B active (MoE), 128K context, tool-calling"
echo ""
echo -e "  ${GREEN}Fast/lightweight model:${NC}"
echo -e "    glm-4.7-flash       9B active params, 128K context, good tool-calling"
echo ""
echo -e "  ${GREEN}Large reasoning model (optional):${NC}"
echo -e "    qwen3:32b          32B params, 32K context"
echo ""

# =============================================================================
# 3. Install Claude Code Router
# =============================================================================

log_section "Claude Code Router Setup"

if check_command ccr; then
  log_skip "Claude Code Router"
else
  log_step "Installing Claude Code Router"
  run_cmd "npm install -g @musistudio/claude-code-router"
fi

# =============================================================================
# 4. Write router config
# =============================================================================

ROUTER_DIR="$HOME/.claude-code-router"
mkdir -p "$ROUTER_DIR"

log_step "Writing Claude Code Router config"

if ! $DRY_RUN; then
cat > "$ROUTER_DIR/config.json" << ROUTER_EOF
{
  "Providers": [
    {
      "name": "anthropic",
      "api_base_url": "https://api.anthropic.com/v1/messages",
      "api_key": "\$ANTHROPIC_API_KEY",
      "models": [
        "claude-opus-4-6",
        "claude-sonnet-4-5-20250929",
        "claude-haiku-4-5-20251001"
      ]
    },
    {
      "name": "ollama",
      "api_base_url": "${OLLAMA_URL}",
      "api_key": "ollama",
      "models": [
        "qwen3-coder:30b",
        "glm-4.7-flash"
      ]
    }
  ],
  "Router": {
    "default": "anthropic,claude-sonnet-4-5-20250929",
    "background": "ollama,qwen3-coder:30b",
    "think": "anthropic,claude-opus-4-6",
    "longContext": "ollama,qwen3-coder:30b",
    "longContextThreshold": 100000,
    "webSearch": "anthropic,claude-sonnet-4-5-20250929"
  }
}
ROUTER_EOF
fi

log_info ""
log_info "Router config written to $ROUTER_DIR/config.json"
log_info ""
log_info "Routing strategy:"
log_info "  default (main conversation) → Anthropic Sonnet (cloud)"
log_info "  background tasks            → Ollama qwen3-coder:30b (local)"
log_info "  deep thinking/reasoning     → Anthropic Opus (cloud)"
log_info "  long context (>100K tokens) → Ollama qwen3-coder:30b (local, 128K ctx)"
log_info "  web search                  → Anthropic Sonnet (cloud)"

# =============================================================================
# 5. Patch agent files for local model routing
# =============================================================================

log_section "Patching Agent Model Tiers"

AGENTS_DIR="$PROJECT_DIR/.claude/agents"

# Agents that stay on cloud (LLM-about-LLMs work)
CLOUD_OPUS_AGENTS=("ai-engineer")

if [[ -d "$AGENTS_DIR" ]]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue
    agent_name=$(basename "$agent_file" .md)

    # Check if this agent should stay on cloud
    is_cloud=false
    for cloud_agent in "${CLOUD_OPUS_AGENTS[@]}"; do
      if [[ "$agent_name" == "$cloud_agent" ]]; then
        is_cloud=true
        break
      fi
    done

    if $is_cloud; then
      log_step "$agent_name → CLOUD (opus)"
      if ! $DRY_RUN; then
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' 's/^model: .*/model: opus/' "$agent_file"
        else
          sed -i 's/^model: .*/model: opus/' "$agent_file"
        fi
      fi
    else
      log_step "$agent_name → LOCAL (ollama/qwen3-coder:30b)"
      if ! $DRY_RUN; then
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' 's/^model: .*/model: haiku/' "$agent_file"
        else
          sed -i 's/^model: .*/model: haiku/' "$agent_file"
        fi
        # Add CCR routing tag if not already present
        if ! grep -q 'CCR-SUBAGENT-MODEL' "$agent_file"; then
          # Insert the tag after the frontmatter closing ---
          if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/^---$/,/^---$/{
              /^---$/{
                x
                s/^$/found/
                x
                /found/!b
                a\
<CCR-SUBAGENT-MODEL>ollama,qwen3-coder:30b</CCR-SUBAGENT-MODEL>
              }
            }' "$agent_file"
          else
            sed -i '/^---$/,/^---$/{
              /^---$/{
                x
                s/^$/found/
                x
                /found/!b
                a\<CCR-SUBAGENT-MODEL>ollama,qwen3-coder:30b</CCR-SUBAGENT-MODEL>
              }
            }' "$agent_file"
          fi
        fi
      fi
    fi
  done
else
  log_warn "No agents directory found at $AGENTS_DIR"
  log_info "Run /setup-claude-agents first to create agents, then re-run this script."
fi

# =============================================================================
# Summary
# =============================================================================

log_section "Summary"

echo ""
echo -e "  ${GREEN}Local LLM:${NC}"
echo "    Ollama at ${OLLAMA_URL} with qwen3-coder:30b + glm-4.7-flash"
echo "    Claude Code Router at ~/.claude-code-router/config.json"
echo ""
echo -e "  ${CYAN}Token savings strategy:${NC}"
echo "    ┌─────────────────────┬──────────────────────────┐"
echo "    │ Task Type           │ Where It Runs            │"
echo "    ├─────────────────────┼──────────────────────────┤"
echo "    │ Main conversation   │ Anthropic Sonnet (cloud) │"
echo "    │ Deep reasoning      │ Anthropic Opus (cloud)   │"
echo "    │ Web search          │ Anthropic Sonnet (cloud) │"
echo "    │ AI engineer agent   │ Anthropic Opus (cloud)   │"
echo "    ├─────────────────────┼──────────────────────────┤"
echo "    │ All other agents    │ Ollama local             │"
echo "    │ Background tasks    │ Ollama local             │"
echo "    │ Long context        │ Ollama local             │"
echo "    └─────────────────────┴──────────────────────────┘"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
if $IS_REMOTE_OLLAMA; then
  echo "    1. On ${OLLAMA_HOST}: OLLAMA_HOST=0.0.0.0 ollama serve"
  echo "    2. On ${OLLAMA_HOST}: ollama pull qwen3-coder:30b && ollama pull glm-4.7-flash"
  echo "    3. On this machine: ccr code"
else
  echo "    1. Start Ollama: ollama serve"
  echo "    2. Start Claude with router: ccr code"
fi
echo ""
echo -e "${GREEN}Done!${NC}"
