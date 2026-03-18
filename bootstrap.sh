#!/bin/bash
# bootstrap.sh — First-run personalization for cc-native-research-template
#
# Asks 4 questions, replaces values across the project.
# Idempotent: re-running reads current values from .pipeline-state.json
# and replaces them with new values (no placeholder dependency).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

STATE_FILE=".pipeline-state.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}cc-native-research-template bootstrap${NC}"
echo "========================================"
echo ""

# Read current config from state file (if previously bootstrapped)
OLD_NAME=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('project_name', ''))" 2>/dev/null || echo "")
OLD_DESC=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('description', ''))" 2>/dev/null || echo "")
OLD_DOMAIN=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('domain', ''))" 2>/dev/null || echo "")

if [ -n "$OLD_NAME" ]; then
    echo -e "${YELLOW}Existing project: ${OLD_NAME}${NC}"
    echo "Current values shown in [brackets]. Press Enter to keep."
    echo ""
    UPDATE_MODE=true
else
    UPDATE_MODE=false
fi

# Question 1: Project name
if [ "$UPDATE_MODE" = true ]; then
    read -p "Project name [${OLD_NAME}]: " PROJECT_NAME
    PROJECT_NAME="${PROJECT_NAME:-$OLD_NAME}"
else
    read -p "Project name (kebab-case, e.g. my-research-project): " PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        echo "Error: Project name is required."
        exit 1
    fi
fi

# Question 2: One-line description
if [ "$UPDATE_MODE" = true ]; then
    read -p "Description [${OLD_DESC}]: " DESCRIPTION
    DESCRIPTION="${DESCRIPTION:-$OLD_DESC}"
else
    read -p "One-line description: " DESCRIPTION
    if [ -z "$DESCRIPTION" ]; then
        echo "Error: Description is required."
        exit 1
    fi
fi

# Question 3: Research domain
if [ "$UPDATE_MODE" = true ]; then
    read -p "Research domain [${OLD_DOMAIN}]: " DOMAIN
    DOMAIN="${DOMAIN:-$OLD_DOMAIN}"
else
    read -p "Research domain (e.g., NLP, computer vision, reinforcement learning): " DOMAIN
    DOMAIN="${DOMAIN:-general machine learning}"
fi

# Question 4: Compute environment
echo ""
echo "Compute environment:"
echo "  1) local     — experiments run on this machine"
echo "  2) remote-gpu — experiments run on remote GPU server (SSH)"
echo "  3) cloud     — experiments run on cloud instances"
read -p "Choose [1/2/3] (default: 1): " COMPUTE_CHOICE
case "${COMPUTE_CHOICE:-1}" in
    1) COMPUTE_ENV="local" ;;
    2) COMPUTE_ENV="remote-gpu" ;;
    3) COMPUTE_ENV="cloud" ;;
    *) COMPUTE_ENV="local" ;;
esac

echo ""
echo "Applying configuration..."

# Determine what to search for (old values or placeholders)
SEARCH_NAME="${OLD_NAME:-\{PROJECT_NAME\}}"
SEARCH_DESC="${OLD_DESC:-\{ONE_LINE_DESCRIPTION\}}"
SEARCH_DOMAIN="${OLD_DOMAIN:-\{RESEARCH_DOMAIN\}}"

# Replace across all .md files and .yaml files
for EXT in "*.md" "*.yaml"; do
    find . -name "$EXT" -not -path "./.git/*" -exec sed -i '' "s|${SEARCH_NAME}|${PROJECT_NAME}|g" {} +
    find . -name "$EXT" -not -path "./.git/*" -exec sed -i '' "s|${SEARCH_DESC}|${DESCRIPTION}|g" {} +
    find . -name "$EXT" -not -path "./.git/*" -exec sed -i '' "s|${SEARCH_DOMAIN}|${DOMAIN}|g" {} +
done
echo "  Replaced project values in .md and .yaml files"

# Replace CLAUDE.md current state placeholders (first run only)
sed -i '' "s|{CURRENT_EXP}|null|g" CLAUDE.md 2>/dev/null || true
sed -i '' "s|{STAGE}|dev|g" CLAUDE.md 2>/dev/null || true
sed -i '' "s|{SKILL_UPDATE_DATE}|$(date +%Y-%m-%d)|g" CLAUDE.md 2>/dev/null || true

# Configure compute environment
if [ "$COMPUTE_ENV" = "remote-gpu" ]; then
    read -p "Remote server (user@host): " SERVER
    python3 -c "
import json
with open('.claude/settings.local.json') as f:
    config = json.load(f)
perms = config.setdefault('permissions', {}).setdefault('allow', [])
extras = ['Bash(ssh ${SERVER}:*)', 'Bash(rsync:*)', 'Bash(scp:*)']
for p in extras:
    real_p = p.replace('\${SERVER}', '${SERVER}')
    if real_p not in perms:
        perms.append(real_p)
with open('.claude/settings.local.json', 'w') as f:
    json.dump(config, f, indent=2)
"
    echo "  Added SSH/rsync permissions for ${SERVER}"
fi

# Save current config to pipeline state (enables future re-bootstrap)
python3 -c "
import json, time
with open('$STATE_FILE') as f:
    state = json.load(f)
state['project_name'] = '${PROJECT_NAME}'
state['description'] = '${DESCRIPTION}'
state['domain'] = '${DOMAIN}'
state['compute_env'] = '${COMPUTE_ENV}'
state['skill_updated_at'] = int(time.time())
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
"
echo "  Saved config to .pipeline-state.json"

echo ""
echo -e "${GREEN}Bootstrap complete!${NC}"
echo ""
echo -e "  Project: ${CYAN}${PROJECT_NAME}${NC}"
echo -e "  Domain:  ${CYAN}${DOMAIN}${NC}"
echo -e "  Compute: ${CYAN}${COMPUTE_ENV}${NC}"
echo ""

if [ "$UPDATE_MODE" = false ]; then
    echo "Next steps:"
    echo "  1. Review the generated files"
    echo "  2. git add -A && git commit -m 'chore: bootstrap ${PROJECT_NAME}'"
    echo "  3. Run /new-experiment to create your first experiment"
else
    echo "Update applied. Review changes with 'git diff'."
fi
