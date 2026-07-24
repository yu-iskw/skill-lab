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

# Inline YAML comments on unquoted scalars must not poison name/description
mkdir -p "${tmpdir}/comment-skill"
cat >"${tmpdir}/comment-skill/SKILL.md" <<'EOF'
---
name: comment-skill # package name
description: Skill with inline YAML comments in frontmatter scalars. # trailing note
---

# Comment Skill
EOF
assert_ok "validate accepts inline YAML comments on scalars" "${validate}" --json "${tmpdir}/comment-skill"

# Quoted scalars keep hash characters
mkdir -p "${tmpdir}/hash-desc"
cat >"${tmpdir}/hash-desc/SKILL.md" <<'EOF'
---
name: hash-desc
description: "Use when the user mentions #hashtags in prompts."
---

# Hash Desc
EOF
assert_ok "validate keeps hash inside quoted description" "${validate}" --json "${tmpdir}/hash-desc"

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

# Aggregate: omitted passed is rejected (not aggregated fail-open)
cat >"${tmpdir}/criteria-missing-passed.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "expected": "pass", "observed": "pass", "evidence": ["e"], "severity": "hard"}
  ]
}
EOF
assert_fail "aggregate rejects missing passed" "${eval_bin}" --aggregate "${tmpdir}/criteria-missing-passed.json"

# Aggregate: string passed is not a boolean
cat >"${tmpdir}/criteria-string-passed.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "passed": "false", "expected": "pass", "observed": "fail", "evidence": ["e"], "severity": "hard"}
  ]
}
EOF
assert_fail "aggregate rejects string passed" "${eval_bin}" --aggregate "${tmpdir}/criteria-string-passed.json"

# Aggregate: empty criteria rejected
cat >"${tmpdir}/criteria-empty.json" <<'EOF'
{"run_id":"run-test","skill_name":"demo","criteria":[]}
EOF
assert_fail "aggregate rejects empty criteria" "${eval_bin}" --aggregate "${tmpdir}/criteria-empty.json"

# Aggregate: score outside [0,1] rejected
cat >"${tmpdir}/criteria-bad-score.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 2.0, "passed": false, "expected": "ok", "observed": "bad", "evidence": [], "severity": "hard"}
  ]
}
EOF
assert_fail "aggregate rejects score outside [0,1]" "${eval_bin}" --aggregate "${tmpdir}/criteria-bad-score.json"

# Aggregate: missing severity rejected
cat >"${tmpdir}/criteria-missing-severity.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "passed": true, "expected": "ok", "observed": "ok", "evidence": []}
  ]
}
EOF
assert_fail "aggregate rejects missing severity" "${eval_bin}" --aggregate "${tmpdir}/criteria-missing-severity.json"

# Aggregate: evidence elements must be strings or objects
cat >"${tmpdir}/criteria-bad-evidence.json" <<'EOF'
{
  "run_id": "run-test",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "passed": true, "expected": "ok", "observed": "ok", "evidence": [42], "severity": "hard"}
  ]
}
EOF
assert_fail "aggregate rejects non-string/non-object evidence" "${eval_bin}" --aggregate "${tmpdir}/criteria-bad-evidence.json"

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

# Trigger tags must be strings
cat >"${tmpdir}/weak-skill/evals/trigger-evals.json" <<'EOF'
{
  "cases": [
    {
      "id": "c1",
      "prompt": "x",
      "expected": {"should_trigger": true},
      "tags": [1],
      "split": "train",
      "rationale": "tags items must be strings"
    }
  ]
}
EOF
assert_fail "validate rejects non-string trigger tags" "${validate}" --json "${tmpdir}/weak-skill"
assert_fail "eval rejects non-string trigger tags" "${eval_bin}" --validate-only "${tmpdir}/weak-skill"

# Nested output-eval fields must be validated
mkdir -p "${tmpdir}/output-skill/evals"
cat >"${tmpdir}/output-skill/SKILL.md" <<'EOF'
---
name: output-skill
description: Fixture used to prove nested output-eval field validation.
---

# Output Skill
EOF
cat >"${tmpdir}/output-skill/evals/output-evals.json" <<'EOF'
{
  "cases": [
    {
      "id": "c1",
      "prompt": "p",
      "input_files": [],
      "assertions": [{}],
      "human_review_points": [],
      "split": "train"
    }
  ]
}
EOF
assert_fail "validate rejects empty assertion objects" "${validate}" --json "${tmpdir}/output-skill"
assert_fail "eval rejects empty assertion objects" "${eval_bin}" --validate-only "${tmpdir}/output-skill"

cat >"${tmpdir}/output-skill/evals/output-evals.json" <<'EOF'
{
  "cases": [
    {
      "id": "c1",
      "prompt": "p",
      "input_files": [42],
      "assertions": [{"id": "a1", "type": "contains", "severity": "hard"}],
      "human_review_points": [],
      "split": "train"
    }
  ]
}
EOF
assert_fail "validate rejects non-string/non-object input_files" "${validate}" --json "${tmpdir}/output-skill"
assert_fail "eval rejects non-string/non-object input_files" "${eval_bin}" --validate-only "${tmpdir}/output-skill"

cat >"${tmpdir}/output-skill/evals/output-evals.json" <<'EOF'
{
  "cases": [
    {
      "id": "c1",
      "prompt": "p",
      "input_files": [],
      "assertions": [{"id": "a1", "type": "contains", "severity": "hard"}],
      "human_review_points": [42],
      "split": "train"
    }
  ]
}
EOF
assert_fail "validate rejects non-string human_review_points" "${validate}" --json "${tmpdir}/output-skill"
assert_fail "eval rejects non-string human_review_points" "${eval_bin}" --validate-only "${tmpdir}/output-skill"

# Unclosed frontmatter must fail
mkdir -p "${tmpdir}/unclosed-skill"
cat >"${tmpdir}/unclosed-skill/SKILL.md" <<'EOF'
---
name: unclosed-skill
description: Fixture missing the closing frontmatter delimiter on purpose.

# Unclosed
EOF
assert_fail "validate rejects unclosed frontmatter" "${validate}" --json "${tmpdir}/unclosed-skill"

# Folded/literal description markers must fail closed
mkdir -p "${tmpdir}/folded-desc"
cat >"${tmpdir}/folded-desc/SKILL.md" <<'EOF'
---
name: folded-desc
description: >
  This long description would bypass the length check if folded blocks were accepted.
---

# Folded
EOF
folded_out="$("${validate}" --json "${tmpdir}/folded-desc" || true)"
folded_code="$(jq -r '.findings[] | select(.code=="DESCRIPTION_MULTILINE_UNSUPPORTED") | .code' <<<"${folded_out}")"
assert_eq "validate rejects folded description marker" "DESCRIPTION_MULTILINE_UNSUPPORTED" "${folded_code}"

mkdir -p "${tmpdir}/folded-plus"
cat >"${tmpdir}/folded-plus/SKILL.md" <<'EOF'
---
name: folded-plus
description: >+
  Body that would bypass an exact-marker check.
---

# Folded Plus
EOF
assert_fail "validate rejects >+ folded description marker" "${validate}" --json "${tmpdir}/folded-plus"

mkdir -p "${tmpdir}/folded-indent"
cat >"${tmpdir}/folded-indent/SKILL.md" <<'EOF'
---
name: folded-indent
description: >1+
  Indent-then-chomp header must also be rejected.
---

# Folded Indent
EOF
assert_fail "validate rejects >1+ folded description marker" "${validate}" --json "${tmpdir}/folded-indent"

# Shared remapper: validate warning → quality criterion
mkdir -p "${tmpdir}/todo-skill"
cat >"${tmpdir}/todo-skill/SKILL.md" <<'EOF'
---
name: todo-skill
description: Fixture with unfinished placeholder markers for remapper coverage.
---

# Todo
TODO: finish
EOF
todo_report="$("${validate}" --json "${tmpdir}/todo-skill" || true)"
printf '%s\n' "${todo_report}" >"${tmpdir}/todo-report.json"
# shellcheck source=../../lib/common.sh
source "${root}/lib/common.sh"
# shellcheck disable=SC2311 # remapper is pure jq; capture without aborting the suite
remapped="$(skill_lab_criteria_from_validate_report "${tmpdir}/todo-report.json" "run-todo" "todo-skill")"
remap_sev="$(jq -r '.criteria[0].severity' <<<"${remapped}")"
assert_eq "criteria-from-validate maps warning to quality" "quality" "${remap_sev}"

# Aggregate normalizes severity case
cat >"${tmpdir}/criteria-upper.json" <<'EOF'
{
  "run_id": "run-upper",
  "skill_name": "demo",
  "criteria": [
    {"criterion_id": "H1", "score": 1.0, "passed": true, "expected": "ok", "observed": "ok", "evidence": [], "severity": "HARD"}
  ]
}
EOF
upper_out="$("${eval_bin}" --aggregate "${tmpdir}/criteria-upper.json")"
upper_sev="$(jq -r '.criteria[0].severity' <<<"${upper_out}")"
assert_eq "aggregate lowercases severity" "hard" "${upper_sev}"

# Compare rejects score outside [0,1]
cat >"${tmpdir}/checkpoints-oob.json" <<'EOF'
{
  "checkpoints": [
    {"id": "c0", "score": 100, "hard_gates_passed": true, "file_count": 1, "created_at": "2026-07-24T10:00:00Z"}
  ]
}
EOF
assert_fail "compare rejects score outside [0,1]" "${compare}" "${tmpdir}/checkpoints-oob.json"

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
