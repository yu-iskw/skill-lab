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
# Prints a JSON array of {code,message} findings to stdout.
# Exit 0 when the suite is valid; exit 1 when findings exist or JSON is unreadable.

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

	local findings
	if ! findings="$(
		jq -c --arg kind "${kind}" '
			def case_id:
				if (.id | type) == "string" and (.id | length) > 0 then .id else "<missing-id>" end;
			(if type=="array" then . else .cases end) as $raw
			| if ($raw | type) != "array" then
					[{code:"EVAL_CASES_MISSING", message:"\($kind): cases array is required"}]
				elif ($raw | length) < 1 then
					[{code:"EVAL_CASES_EMPTY", message:"\($kind): cases array must be non-empty"}]
				else
					($raw | map(select(type == "object"))) as $cases
					| (
							$raw
							| to_entries
							| map(select(.value | type != "object"))
							| map({code:"EVAL_CASE_NOT_OBJECT", message:"\($kind): case at index \(.key) must be an object"})
						)
					+ (
							$cases
							| map(select((.id | type) == "string"))
							| map(.id)
							| group_by(.)
							| map(select(length > 1) | .[0])
							| map({code:"EVAL_DUPLICATE_ID", message:"\($kind): duplicate case id \(.)"})
						)
					+ (
							$cases
							| map(select(.split != null and ((.split | type) != "string" or (.split | IN("train","validation","held-out") | not))))
							| map({code:"EVAL_SPLIT_INVALID", message:"\($kind): case \(case_id) has invalid split"})
						)
					+ (
							if $kind == "trigger" then
								$cases
								| map(select(
										(.id | type != "string" or length < 1)
										or (.prompt | type != "string" or length < 1)
										or (.expected.should_trigger | type != "boolean")
										or (.tags | type != "array")
										or ((.tags | map(select(type != "string")) | length) > 0)
										or (.split | type != "string")
										or (.rationale | type != "string" or length < 1)
									))
								| map({code:"TRIGGER_CASE_INVALID", message:"\($kind): case \(case_id) requires id, prompt, expected.should_trigger, string tags[], split, rationale"})
							elif $kind == "output" then
								$cases
								| map(select(
										(.id | type != "string" or length < 1)
										or (.prompt | type != "string" or length < 1)
										or (.assertions | type != "array" or length < 1)
										or (.input_files | type != "array")
										or (.human_review_points | type != "array")
										or (.split | type != "string")
										or (
											.assertions
											| map(select(
													(.id | type != "string" or length < 1)
													or (.type | type != "string" or length < 1)
													or ((.severity | type != "string") or ((.severity | ascii_downcase) | IN("hard","quality","info") | not))
												))
											| length > 0
										)
										or (
											.input_files
											| map(select(
													(
														(type == "string" and length > 0)
														or (
															type == "object"
															and ((.path | type) == "string")
															and ((.path | length) > 0)
														)
													) | not
												))
											| length > 0
										)
										or (
											.human_review_points
											| map(select(type != "string" or length < 1))
											| length > 0
										)
									))
								| map({code:"OUTPUT_CASE_INVALID", message:"\($kind): case \(case_id) requires id, prompt, split, typed input_files, string human_review_points, and assertions with id/type/severity"})
							else
								[{code:"EVAL_KIND_UNKNOWN", message:("unknown eval kind: " + $kind)}]
							end
						)
				end
		' "${path}" 2>/dev/null
	)"; then
		jq -nc --arg kind "${kind}" '[{code:"EVAL_CHECK_FAILED", message:($kind + ": unable to evaluate suite")}]'
		return 1
	fi

	if [[ -z ${findings} ]]; then
		jq -nc --arg kind "${kind}" '[{code:"EVAL_CHECK_FAILED", message:($kind + ": unable to evaluate suite")}]'
		return 1
	fi

	printf '%s\n' "${findings}"
	jq -e 'type == "array" and length == 0' <<<"${findings}" >/dev/null
}
