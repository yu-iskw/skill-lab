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

skill_lab_lib_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skill_lab_plugin_root="$(CDPATH='' cd -- "${skill_lab_lib_dir}/.." && pwd)"
skill_lab_schemas_dir="${skill_lab_plugin_root}/schemas"

skill_lab_die() {
	echo "ERROR: $*" >&2
	exit 1
}

skill_lab_require_jq() {
	command -v jq >/dev/null 2>&1 || skill_lab_die "jq is required"
}

skill_lab_require_file() {
	local path="$1"
	[[ -f ${path} ]] || skill_lab_die "missing file: ${path}"
}

skill_lab_json_ok() {
	local path="$1"
	jq -e . "${path}" >/dev/null 2>&1 || skill_lab_die "invalid JSON: ${path}"
}

# Extract YAML-like frontmatter fields from SKILL.md without a YAML parser.
# Supports simple `key: value` and `key: "value"` / `key: 'value'` lines.
skill_lab_frontmatter_field() {
	local skill_md="$1"
	local field="$2"
	awk -v field="${field}" '
		BEGIN { in_fm=0 }
		NR==1 && $0 == "---" { in_fm=1; next }
		in_fm && $0 == "---" { exit }
		in_fm {
			prefix = field ": "
			if (index($0, prefix) == 1) {
				value = substr($0, length(prefix) + 1)
				gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
				if ((value ~ /^".*"$/) || (value ~ /^'\''.*'\''$/)) {
					value = substr(value, 2, length(value) - 2)
				}
				print value
				exit
			}
		}
	' "${skill_md}"
}

skill_lab_is_valid_skill_name() {
	local name="$1"
	[[ ${#name} -ge 1 && ${#name} -le 64 ]] || return 1
	[[ ${name} =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || return 1
	return 0
}

skill_lab_emit_finding() {
	local severity="$1"
	local code="$2"
	local message="$3"
	jq -nc --arg severity "${severity}" --arg code "${code}" --arg message "${message}" \
		'{severity:$severity, code:$code, message:$message}'
}
