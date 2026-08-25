#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/skills/read-paper/SKILL.md"
DOMAIN_EXPERT="$ROOT/agents/domain-expert.md"
ACQUISITION="$ROOT/skills/read-paper/references/paper-acquisition.md"
VALIDATOR="$ROOT/skills/read-paper/scripts/validate-paper-packet.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_packet() {
  python3 - "$@" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

artifact_path = Path(sys.argv[1])
packet_path = Path(sys.argv[2])
body = artifact_path.read_bytes()
anchor_specs = json.loads(sys.argv[8])
anchor_index = []
for anchor_id, needle, page in anchor_specs:
    encoded = needle.encode("utf-8")
    start = body.index(encoded)
    end = start + len(encoded)
    anchor_index.append({
        "id": anchor_id,
        "start_byte": start,
        "end_byte": end,
        "span_sha256": hashlib.sha256(body[start:end]).hexdigest(),
        "page": page,
    })

def page_count(value):
    return None if value == "null" else int(value)

packet = {
    "schema_version": 1,
    "input_kind": sys.argv[3],
    "source_locator": sys.argv[4],
    "text_path": artifact_path.name,
    "provenance": sys.argv[5],
    "completeness": sys.argv[6],
    "anchors": json.loads(sys.argv[7]),
    "anchor_index": anchor_index,
    "extractor": sys.argv[9],
    "artifact_bytes": len(body),
    "source_page_count": page_count(sys.argv[10]),
    "extracted_page_count": page_count(sys.argv[11]),
    "content_sha256": hashlib.sha256(body).hexdigest(),
}
packet_path.write_text(json.dumps(packet, indent=2), encoding="utf-8")
PY
}

grep -q '^description: Use when the user explicitly requests' "$SKILL" \
  || fail "read-paper description must describe explicit invocation"
grep -q 'references/paper-acquisition.md' "$SKILL" \
  || fail "read-paper must load the acquisition contract"
grep -q 'validate-paper-packet.py' "$SKILL" \
  || fail "read-paper must validate the normalized paper packet"
if grep -q '{fetched paper content}' "$SKILL"; then
  fail "read-paper must pass an artifact path, not inline full text"
fi
if grep -q 'replace `/pdf/` with `/abs/`' "$SKILL"; then
  fail "arXiv PDF deep-dives must not silently downgrade to the abstract page"
fi

[ -f "$ACQUISITION" ] || fail "missing paper acquisition reference"
[ -x "$VALIDATOR" ] || fail "missing executable paper packet validator"
grep -q '"start_byte"' "$ACQUISITION" \
  || fail "paper anchors must bind to replayable artifact byte spans"
grep -q 'Paper packet path:' "$SKILL" \
  || fail "domain-expert delegation must receive the packet path"
grep -q 'artifacts/{short-name}' "$SKILL" \
  || fail "saved readings must freeze their validated artifacts"
grep -q 'Evidence Ledger' "$DOMAIN_EXPERT" \
  || fail "Mode 4 must separate paper evidence, interpretation, and project bridge"
grep -q 'section/page/equation/figure/table' "$DOMAIN_EXPERT" \
  || fail "Mode 4 must require paper-local evidence anchors"

word_count=$(wc -w < "$SKILL" | tr -d ' ')
[ "$word_count" -le 500 ] || fail "read-paper SKILL.md exceeds 500 words: $word_count"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

printf '# Introduction\n%s\n# Method\n%s\n# Results\n%s\n# References\n' \
  "$(printf 'problem %.0s' {1..80})" \
  "$(printf 'method %.0s' {1..80})" \
  "$(printf 'result %.0s' {1..80})" > "$TEST_TMP/full.md"
write_packet "$TEST_TMP/full.md" "$TEST_TMP/full.json" \
  single_paper https://arxiv.org/pdf/0000.00000 local_pdf full_text \
  '["sections"]' \
  '[["section:Introduction","# Introduction",null],["section:Method","# Method",null],["section:Results","# Results",null],["section:References","# References",null]]' \
  synthetic-test null null
python3 "$VALIDATOR" "$TEST_TMP/full.json" --mode deep-dive >/dev/null \
  || fail "complete single-paper packet should pass"

printf 'Title\nAbstract only. No methods, experiments, or references.\n' > "$TEST_TMP/abstract.md"
write_packet "$TEST_TMP/abstract.md" "$TEST_TMP/abstract.json" \
  single_paper https://arxiv.org/abs/0000.00000 web_page abstract_only \
  '["sections"]' '[["section:Abstract","Abstract only",null]]' \
  synthetic-test null null
if python3 "$VALIDATOR" "$TEST_TMP/abstract.json" --mode deep-dive >/dev/null 2>&1; then
  fail "abstract-only packet must not pass the deep-dive gate"
fi
python3 - "$TEST_TMP/abstract.json" "$TEST_TMP/fake-full.json" <<'PY'
import json
import sys
from pathlib import Path

packet = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packet["completeness"] = "full_text"
Path(sys.argv[2]).write_text(json.dumps(packet), encoding="utf-8")
PY
if python3 "$VALIDATOR" "$TEST_TMP/fake-full.json" --mode deep-dive >/dev/null 2>&1; then
  fail "a shallow artifact must not pass merely by self-reporting full_text"
fi

printf '# Awesome Loop Models\n- [Paper A](https://example.com/a)\n- [Paper B](https://example.com/b)\n' > "$TEST_TMP/hub.md"
write_packet "$TEST_TMP/hub.md" "$TEST_TMP/hub.json" \
  literature_hub https://github.com/example/awesome-loop-models github_repo hub_index \
  '["entries","links"]' \
  '[["entry:Paper A","[Paper A]",null],["entry:Paper B","[Paper B]",null],["link:https://example.com/a","https://example.com/a",null],["link:https://example.com/b","https://example.com/b",null]]' \
  synthetic-test null null
python3 "$VALIDATOR" "$TEST_TMP/hub.json" --mode hub-triage >/dev/null \
  || fail "literature hub packet should route to hub triage"

python3 - "$TEST_TMP/long.md" <<'PY'
import sys
from pathlib import Path

pages = []
for page in range(1, 91):
    body = "Equation (7): E = mc^2.\n" if page == 7 else f"Page {page} body.\n"
    pages.append(f"<!-- page: {page} -->\n{body}")
Path(sys.argv[1]).write_text("".join(pages), encoding="utf-8")
PY
write_packet "$TEST_TMP/long.md" "$TEST_TMP/long.json" \
  single_paper local-90-page-paper.pdf local_pdf full_text \
  '["pages","equations"]' \
  '[["equation:7","Equation (7): E = mc^2.",7]]' \
  'pdftotext -layout' 90 90
python3 "$VALIDATOR" "$TEST_TMP/long.json" --mode deep-dive \
  --require-anchor equation:7 >/dev/null \
  || fail "page-complete long paper with requested anchor should pass"
if python3 "$VALIDATOR" "$TEST_TMP/long.json" --mode deep-dive \
  --require-anchor table:3 >/dev/null 2>&1; then
  fail "deep-dive must reject an unavailable user-requested anchor"
fi

python3 - "$TEST_TMP/long.json" "$TEST_TMP/long.md" "$TEST_TMP/fake-anchor.json" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

packet = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
body = Path(sys.argv[2]).read_bytes()
needle = b"Page 8 body."
start = body.index(needle)
packet["anchor_index"] = [{
    "id": "equation:7",
    "start_byte": start,
    "end_byte": start + len(needle),
    "span_sha256": hashlib.sha256(needle).hexdigest(),
    "page": 8,
}]
Path(sys.argv[3]).write_text(json.dumps(packet), encoding="utf-8")
PY
if python3 "$VALIDATOR" "$TEST_TMP/fake-anchor.json" --mode deep-dive \
  --require-anchor equation:7 >/dev/null 2>&1; then
  fail "self-reported anchor without a bound artifact marker must fail"
fi

python3 - "$TEST_TMP/long.json" "$TEST_TMP/page-mismatch.json" <<'PY'
import json
import sys
from pathlib import Path

packet = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packet["extracted_page_count"] = 89
Path(sys.argv[2]).write_text(json.dumps(packet), encoding="utf-8")
PY
if python3 "$VALIDATOR" "$TEST_TMP/page-mismatch.json" --mode deep-dive >/dev/null 2>&1; then
  fail "mismatched source and extracted page counts must fail"
fi

echo "read-paper contract checks passed"
