#!/bin/bash
# bootstrap.sh — First-run personalization for cc-native-research-template
#
# Asks 4 questions, replaces placeholders, configures compute environment.
# Idempotent: re-running enters update mode if .pipeline-state.json has last_commit set.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

STATE_FILE=".pipeline-state.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}cc-native-research-template bootstrap${NC}"
echo "========================================"
echo ""

# Check for update mode
LAST_COMMIT=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('last_commit') or '')" 2>/dev/null || echo "")
if [ -n "$LAST_COMMIT" ]; then
    echo -e "${YELLOW}Existing project detected (last commit: ${LAST_COMMIT}).${NC}"
    echo "Entering update mode — will only change fields you specify."
    echo ""
    UPDATE_MODE=true
else
    UPDATE_MODE=false
fi

# Question 1: Project name
read -p "Project name (kebab-case, e.g. my-research-project): " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name is required."
    exit 1
fi

# Question 2: One-line description
read -p "One-line description: " DESCRIPTION
if [ -z "$DESCRIPTION" ]; then
    echo "Error: Description is required."
    exit 1
fi

# Question 3: Research domain
read -p "Research domain (e.g., NLP, computer vision, reinforcement learning): " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN="general machine learning"
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

# Replace placeholders
if [ "$UPDATE_MODE" = false ] || [ -n "$PROJECT_NAME" ]; then
    # Use | as sed delimiter to avoid conflicts with / in descriptions
    find . -name "*.md" -not -path "./.git/*" -exec sed -i '' "s|{PROJECT_NAME}|${PROJECT_NAME}|g" {} +
    find . -name "*.md" -not -path "./.git/*" -exec sed -i '' "s|{ONE_LINE_DESCRIPTION}|${DESCRIPTION}|g" {} +
    find . -name "*.md" -not -path "./.git/*" -exec sed -i '' "s|{RESEARCH_DOMAIN}|${DOMAIN}|g" {} +
    echo "  Replaced placeholders in .md files"
fi

# Configure compute environment
if [ "$COMPUTE_ENV" = "remote-gpu" ]; then
    read -p "Remote server (user@host): " SERVER
    # Add SSH/rsync permissions to settings.local.json
    python3 -c "
import json
with open('.claude/settings.local.json') as f:
    config = json.load(f)
perms = config.setdefault('permissions', {}).setdefault('allow', [])
for p in ['Bash(ssh ${SERVER}:*)', 'Bash(rsync:*)', 'Bash(scp:*)']:
    if p not in perms:
        perms.append(p.replace('\${SERVER}', '${SERVER}'))
with open('.claude/settings.local.json', 'w') as f:
    json.dump(config, f, indent=2)
"
    echo "  Added SSH/rsync permissions for ${SERVER}"
fi

# Update pipeline state
python3 -c "
import json, time
with open('$STATE_FILE') as f:
    state = json.load(f)
state['skill_updated_at'] = int(time.time())
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
"
echo "  Updated pipeline state"

# Update CLAUDE.md current state section
sed -i '' "s|{CURRENT_EXP}|null|g" CLAUDE.md
sed -i '' "s|{STAGE}|dev|g" CLAUDE.md
sed -i '' "s|{SKILL_UPDATE_DATE}|$(date +%Y-%m-%d)|g" CLAUDE.md
echo "  Updated CLAUDE.md current state"

echo ""
echo -e "${GREEN}Bootstrap complete!${NC}"
echo ""
echo "Project: ${PROJECT_NAME}"
echo "Domain:  ${DOMAIN}"
echo "Compute: ${COMPUTE_ENV}"
echo ""

if [ "$UPDATE_MODE" = false ]; then
    echo "Next steps:"
    echo "  1. Review the generated files"
    echo "  2. git add -A && git commit -m 'chore: bootstrap ${PROJECT_NAME}'"
    echo "  3. Run /new-experiment to create your first experiment"
else
    echo "Update applied. Review changes with 'git diff'."
fi
