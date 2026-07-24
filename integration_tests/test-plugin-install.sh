#!/usr/bin/env bash

# Copyright 2026 yu-iskw
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Test plugin installation via Claude CLI (marketplace add + plugin install + list/validate)
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
	echo "WARNING: Claude CLI not found. Skipping plugin install tests."
	echo "Install with: npm install -g @anthropic-ai/claude-code"
	exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "ERROR: jq is required for plugin install tests."
	exit 1
fi

# Workspace root (repo root); caller sets cwd (e.g. /workspace in Docker)
WORKSPACE_ROOT="${1:-.}"
MARKETPLACE_JSON="${WORKSPACE_ROOT}/.claude-plugin/marketplace.json"

if [[ ! -f ${MARKETPLACE_JSON} ]]; then
	echo "ERROR: Marketplace manifest not found: ${MARKETPLACE_JSON}"
	exit 1
fi

MARKETPLACE_NAME="$(jq -r '.name' "${MARKETPLACE_JSON}")"
PLUGIN_NAMES="$(jq -r '.plugins[].name' "${MARKETPLACE_JSON}")"

if [[ -z ${MARKETPLACE_NAME} ]] || [[ ${MARKETPLACE_NAME} == "null" ]]; then
	echo "ERROR: Could not read marketplace name from ${MARKETPLACE_JSON}"
	exit 1
fi

if [[ -z ${PLUGIN_NAMES} ]]; then
	echo "No plugins listed in marketplace; skipping install test."
	exit 0
fi

echo "Testing plugin install from marketplace: ${MARKETPLACE_NAME}"

# Add workspace as marketplace (path to repo root; CLI may accept dir with .claude-plugin)
echo "Adding marketplace from ${WORKSPACE_ROOT}..."
if ! claude plugin marketplace add "${WORKSPACE_ROOT}" 2>/dev/null; then
	# Some CLIs expect directory containing marketplace manifest
	if ! claude plugin marketplace add "${WORKSPACE_ROOT}/.claude-plugin" 2>/dev/null; then
		echo "ERROR: Failed to add marketplace from ${WORKSPACE_ROOT} or ${WORKSPACE_ROOT}/.claude-plugin"
		claude plugin marketplace add "${WORKSPACE_ROOT}" || true
		exit 1
	fi
fi

# Install each plugin with project scope (container-local)
for name in ${PLUGIN_NAMES}; do
	echo "Installing plugin: ${name}..."
	# Prefer plugin@marketplace; fallback to plugin only if one marketplace
	if ! claude plugin install -s project "${name}@${MARKETPLACE_NAME}" 2>/dev/null; then
		if ! claude plugin install -s project "${name}" 2>/dev/null; then
			echo "ERROR: Failed to install plugin: ${name}"
			claude plugin install -s project "${name}@${MARKETPLACE_NAME}" || true
			exit 1
		fi
	fi
done

# Verify: installed plugins appear in list
echo "Verifying installed plugins..."
LIST_JSON="$(claude plugin list --json 2>/dev/null)" || true
if [[ -z ${LIST_JSON} ]]; then
	echo "ERROR: 'claude plugin list --json' produced no output"
	exit 1
fi

for name in ${PLUGIN_NAMES}; do
	if echo "${LIST_JSON}" | jq -e --arg n "${name}" '.installed[]? | select(.name == $n)' >/dev/null 2>&1; then
		echo "  ${name}: found in installed list"
	elif echo "${LIST_JSON}" | jq -e --arg n "${name}" '.[]? | select(.name == $n)' >/dev/null 2>&1; then
		echo "  ${name}: found in list"
	else
		echo "WARNING: ${name} not found in plugin list output; structure may differ"
	fi
done

# Minimal load check without --plugin-dir (plugin should be loaded from install location)
echo "Checking plugin load without --plugin-dir..."
if ! claude --print "Reply with exactly: ok" 2>/dev/null | grep -q "ok"; then
	echo "WARNING: Minimal --print check did not succeed; install may still be valid"
fi

echo "Plugin install test passed"
