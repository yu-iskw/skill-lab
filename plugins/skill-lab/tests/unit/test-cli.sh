#!/usr/bin/env bash

# Copyright 2026 yu-iskw
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

root="$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)"
validate="${root}/bin/skill-lab-validate"
eval_bin="${root}/bin/skill-lab-eval"
compare="${root}/bin/skill-lab-compare"
fixtures="${root}/tests/fixtures"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

pass=0
fail=0

assert_eq() {
	local label="$1"
	local expected="$2"
	local actual="$3"
	if [[ ${expected} == "${actual}" ]]; then
		echo "PASS ${label}"
		pass=$((pass + 1))
	else
		echo "FAIL ${label}: expected '${expected}' got '${actual}'" >&2
		fail=$((fail + 1))
	fi
}

assert_ok() {
	local label="$1"
	shift
	if "$@" >/dev/null; then
		echo "PASS ${label}"
		pass=$((pass + 1))
	else
		echo "FAIL ${label}" >&2
		fail=$((fail + 1))
	fi
}

assert_fail() {
	local label="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "FAIL ${label}: expected non-zero exit" >&2
		fail=$((fail + 1))
	else
		echo "PASS ${label}"
		pass=$((pass + 1))
	fi
}

assert_ok "validate normalize-config" "${validate}" --json "${fixtures}/normalize-config"
assert_ok "validate technical-notes-to-article" "${validate}" --json "${fixtures}/technical-notes-to-article"
assert_ok "validate propose-deploy-stop" "${validate}" --json "${fixtures}/propose-deploy-stop"
assert_ok "eval validate-only normalize-config" "${eval_bin}" --validate-only "${fixtures}/normalize-config"

# Invalid: name/dir mismatch
mkdir -p "${tmpdir}/bad-skill"
cat >"${tmpdir}/bad-skill/SKILL.md" <<'EOF'
---
name: other-name
description: Intentionally mismatched name for validator coverage.
---

# Bad
EOF
assert_fail "validate rejects name mismatch" "${validate}" "${tmpdir}/bad-skill"

# Aggregate: explicit hard gate failure cannot pass
cat >"${tmpdir}/criteria.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "Q1", "score": 0.95, "passed": true, "expected": "ok", "observed": "ok", "evidence": ["e1"], "severity": "quality"},
    {"criterion_id": "H1", "score": 0.0, "passed": false, "expected": "pass", "observed": "fail", "evidence": ["e2"], "severity": "hard"}
  ]
}
EOF
agg="$("${eval_bin}" --aggregate "${tmpdir}/criteria.json" || true)"
hard="$(jq -r '.hard_gates_passed' <<<"${agg}")"
assert_eq "hard gate blocks aggregate pass" "false" "${hard}"

# Aggregate: omitted passed on hard criterion fails closed
cat >"${tmpdir}/criteria-missing-passed.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "expected": "pass", "observed": "pass", "evidence": ["e"], "severity": "hard"}
  ]
}
EOF
agg_missing="$("${eval_bin}" --aggregate "${tmpdir}/criteria-missing-passed.json" || true)"
hard_missing="$(jq -r '.hard_gates_passed' <<<"${agg_missing}")"
assert_eq "missing hard passed fails closed" "false" "${hard_missing}"

# Aggregate: string passed is not boolean true
cat >"${tmpdir}/criteria-string-passed.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "passed": "false", "expected": "pass", "observed": "fail", "evidence": ["e"], "severity": "hard"}
  ]
}
EOF
agg_str="$("${eval_bin}" --aggregate "${tmpdir}/criteria-string-passed.json" || true)"
hard_str="$(jq -r '.hard_gates_passed' <<<"${agg_str}")"
assert_eq "string hard passed fails closed" "false" "${hard_str}"

# Aggregate: empty criteria rejected
cat >"${tmpdir}/criteria-empty.json" <<'EOF'
{"run_id":"run-test","skill_name":"demo","criteria":[]}
EOF
assert_fail "aggregate rejects empty criteria" "${eval_bin}" --aggregate "${tmpdir}/criteria-empty.json"

# Validate and eval agree on weak eval suite
mkdir -p "${tmpdir}/weak-skill/evals"
cat >"${tmpdir}/weak-skill/SKILL.md" <<'EOF'
---
name: weak-skill
description: Fixture used to prove validate and eval share eval-suite rules.
---

# Weak
EOF
cat >"${tmpdir}/weak-skill/evals/trigger-evals.json" <<'EOF'
{"cases":[]}
EOF
assert_fail "validate rejects empty trigger cases" "${validate}" --json "${tmpdir}/weak-skill"
assert_fail "eval rejects empty trigger cases" "${eval_bin}" --validate-only "${tmpdir}/weak-skill"

# Non-string case ids must fail closed (not abort jq / fail-open)
cat >"${tmpdir}/weak-skill/evals/trigger-evals.json" <<'EOF'
{
  "cases": [
    {
      "id": 1,
      "prompt": "x",
      "expected": {"should_trigger": true},
      "tags": [],
      "split": "train",
      "rationale": "id must be a string"
    }
  ]
}
EOF
assert_fail "validate rejects non-string trigger id" "${validate}" --json "${tmpdir}/weak-skill"
assert_fail "eval rejects non-string trigger id" "${eval_bin}" --validate-only "${tmpdir}/weak-skill"

# Non-object case entries must fail closed
cat >"${tmpdir}/weak-skill/evals/trigger-evals.json" <<'EOF'
{"cases":[1]}
EOF
assert_fail "validate rejects non-object trigger case" "${validate}" --json "${tmpdir}/weak-skill"
assert_fail "eval rejects non-object trigger case" "${eval_bin}" --validate-only "${tmpdir}/weak-skill"

# Invalid JSON under --json still emits a report
mkdir -p "${tmpdir}/bad-json/evals"
cat >"${tmpdir}/bad-json/SKILL.md" <<'EOF'
---
name: bad-json
description: Fixture for invalid eval JSON reporting under --json.
---

# Bad JSON
EOF
printf '{not-json' >"${tmpdir}/bad-json/evals/trigger-evals.json"
bad_json_out="$("${validate}" --json "${tmpdir}/bad-json" || true)"
bad_code="$(jq -r '.findings[] | select(.code=="EVAL_INVALID_JSON") | .code' <<<"${bad_json_out}")"
assert_eq "validate --json reports invalid eval JSON" "EVAL_INVALID_JSON" "${bad_code}"

# Compare selects best valid checkpoint
cat >"${tmpdir}/checkpoints.json" <<'EOF'
{
  "checkpoints": [
    {"id": "c0", "score": 0.70, "hard_gates_passed": true, "file_count": 3, "created_at": "2026-07-24T10:00:00Z"},
    {"id": "c1", "score": 0.95, "hard_gates_passed": false, "file_count": 4, "created_at": "2026-07-24T11:00:00Z"},
    {"id": "c2", "score": 0.80, "hard_gates_passed": true, "file_count": 2, "created_at": "2026-07-24T12:00:00Z"}
  ]
}
EOF
selected="$("${compare}" "${tmpdir}/checkpoints.json" | jq -r '.selected.id')"
assert_eq "compare selects highest valid score" "c2" "${selected}"

echo "---"
echo "passed=${pass} failed=${fail}"
((fail == 0))
