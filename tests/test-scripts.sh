#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_TMP="$(mktemp -d)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/*|/private/tmp/*|/var/folders/*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT

project="$TEST_TMP/project"
mkdir -p "$project"
git -C "$project" init -q

init=(python3 "$ROOT/scripts/init_project.py" --root "$project" --type research
  --target both --project-name demo --description "Demo project" --domain ML)

"${init[@]}" plan | jq -e '((.missing | length) > 10) and (.conflicts == [])' >/dev/null
"${init[@]}" apply | jq -e '[.changes[].action] | index("create") != null' >/dev/null
"${init[@]}" check | jq -e '.missing == [] and .errors == []' >/dev/null
"${init[@]}" apply | jq -e '[.changes[].action] | index("skip") != null' >/dev/null
cmp "$project/.agents/skills/project-skill/SKILL.md" \
  "$project/.claude/skills/project-skill/SKILL.md"
test -f "$project/scripts/launch_exp.py"
test -f "$project/viewer/static/index.html"

experiment=(python3 "$ROOT/scripts/new_experiment.py" --root "$project"
  --motivation "Test the baseline")
"${experiment[@]}" plan | jq -e '.exp_id == "exp01a" and .exists == false' >/dev/null
"${experiment[@]}" apply | jq -e '.exp_id == "exp01a"' >/dev/null
"${experiment[@]}" check --exp-id exp01a | jq -e '.missing == []' >/dev/null
jq -e '.current_exp == "exp01a" and .stage == "experiment"' \
  "$project/.pipeline-state.json" >/dev/null

variant=(python3 "$ROOT/scripts/new_experiment.py" --root "$project"
  --motivation "Test a variant | safely" --parent exp01a)
"${variant[@]}" plan | jq -e '.exp_id == "exp01b"' >/dev/null
"${variant[@]}" apply | jq -e '.errors == []' >/dev/null
grep -q '^  id: exp01b$' "$project/exp/exp01b/config.yaml"
grep -q '^  name: "Test a variant | safely"$' "$project/exp/exp01b/config.yaml"
grep -Fq 'Test a variant \| safely' "$project/exp/summary.md"

if python3 "$ROOT/scripts/new_experiment.py" --root "$project" \
  --motivation invalid --parent exp99a plan >/dev/null 2>&1; then
  echo "missing experiment parent should fail" >&2
  exit 1
fi

todo=(python3 "$ROOT/scripts/todo.py" --root "$project")
"${todo[@]}" add "Verify baseline" --priority P0 | jq -e '.priority == "P0"' >/dev/null
if "${todo[@]}" add "Verify baseline" --priority P0 >/dev/null 2>&1; then
  echo "duplicate open todo should fail" >&2
  exit 1
fi
"${todo[@]}" list | jq -e '.items[0].text == "Verify baseline"' >/dev/null
"${todo[@]}" done "Verify baseline" | jq -e '.item | contains("[x]")' >/dev/null
"${todo[@]}" clean | jq -e '.removed == 1' >/dev/null

python3 "$ROOT/scripts/project_snapshot.py" --root "$project" \
  | jq -e '.pipeline_state.current_exp == "exp01b"' >/dev/null

conflict="$TEST_TMP/conflict"
mkdir -p "$conflict/.agents/skills/project-skill" \
  "$conflict/.claude/skills/project-skill"
printf 'left\n' > "$conflict/.agents/skills/project-skill/SKILL.md"
printf 'right\n' > "$conflict/.claude/skills/project-skill/SKILL.md"
conflict_init=(python3 "$ROOT/scripts/init_project.py" --root "$conflict"
  --type general --target both --project-name conflict --description conflict)
"${conflict_init[@]}" plan \
  | jq -e '.conflicts == ["project-skill mirrors differ: SKILL.md"]' >/dev/null
if "${conflict_init[@]}" apply >/dev/null; then
  echo "conflicting project-skill mirrors should block apply" >&2
  exit 1
fi
grep -qx 'left' "$conflict/.agents/skills/project-skill/SKILL.md"
grep -qx 'right' "$conflict/.claude/skills/project-skill/SKILL.md"

echo "PASS: LabMate deterministic interfaces"
