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

# shellcheck shell=bash

# Shared eval-suite shape checks used by skill-lab-validate and skill-lab-eval.
# Prints a JSON array of {code,message} findings to stdout. Exit 0 always when
# the file can be read as JSON; caller decides severity. Exit 1 if JSON parse fails
# (stdout still contains a single findings array when possible).

skill_lab_cases_expr='(if type=="array" then . else .cases end)'

skill_lab_eval_suite_findings() {
	local path="$1"
	local kind="$2"

	if [[ ! -f ${path} ]]; then
		jq -nc --arg kind "${kind}" '[{code:"EVAL_MISSING", message:($kind + ": file not found")}]'
		return 1
	fi

	if ! jq -e . "${path}" >/dev/null 2>&1; then
		jq -nc --arg kind "${kind}" '[{code:"EVAL_INVALID_JSON", message:($kind + ": invalid JSON")}]'
		return 1
	fi

	jq -c --arg kind "${kind}" '
		(if type=="array" then . else .cases end) as $cases
		| [] as $errs
		| (if ($cases | type) != "array" then
				$errs + [{code:"EVAL_CASES_MISSING", message:($kind + ": cases array is required")}]
			elif ($cases | length) < 1 then
				$errs + [{code:"EVAL_CASES_EMPTY", message:($kind + ": cases array must be non-empty")}]
			else
				$errs
			end) as $errs
		| (if ($errs | length) > 0 then $errs else
				(
					($cases
						| map(.id)
						| group_by(.)
						| map(select(length > 1) | .[0])
						| map({code:"EVAL_DUPLICATE_ID", message:($kind + ": duplicate case id \u0027" + . + "\u0027")})
					)
					+ (
						$cases
						| map(select(.split != null and (.split | IN("train","validation","held-out") | not)))
						| map({code:"EVAL_SPLIT_INVALID", message:($kind + ": case \u0027" + (.id // "<missing-id>") + "\u0027 has invalid split")})
					)
					+ (
						if $kind == "trigger" or $kind == "trigger-evals" then
							$cases
							| map(select(
									(.id | type != "string" or length < 1)
									or (.prompt | type != "string" or length < 1)
									or (.expected.should_trigger | type != "boolean")
									or (.tags | type != "array")
									or (.split | type != "string")
									or (.rationale | type != "string" or length < 1)
								))
							| map({code:"TRIGGER_CASE_INVALID", message:($kind + ": case \u0027" + (.id // "<missing-id>") + "\u0027 requires id, prompt, expected.should_trigger, tags, split, rationale")})
						elif $kind == "output" or $kind == "output-evals" then
							$cases
							| map(select(
									(.id | type != "string" or length < 1)
									or (.prompt | type != "string" or length < 1)
									or (.assertions | type != "array" or length < 1)
									or (.input_files | type != "array")
									or (.human_review_points | type != "array")
									or (.split | type != "string")
								))
							| map({code:"OUTPUT_CASE_INVALID", message:($kind + ": case \u0027" + (.id // "<missing-id>") + "\u0027 requires id, prompt, assertions, input_files, human_review_points, split")})
						else
							[]
						end
					)
				)
			end)
	' "${path}"
}
