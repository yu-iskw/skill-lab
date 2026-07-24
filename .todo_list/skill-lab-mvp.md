# Skill Lab MVP

## Phase 0 — Foundation

- [x] Create branch `cursor/skill-lab-mvp-0eac`
- [x] Scaffold `plugins/skill-lab` layout + manifests
- [x] Add JSON schemas (trigger/output/result/manifest/state)
- [x] Empty `hooks/hooks.json` for structure CI

## Phase 1 — Reasoning + Interaction

- [x] Agents: intent-compiler, skill-architect, output-evaluator
- [x] Skills: create (+ refs), evaluate (+ refs)

## Phase 2 — Verification plane (bash + jq)

- [x] `bin/skill-lab-validate` package validator
- [x] `bin/skill-lab-eval` schema + score aggregation
- [x] `bin/skill-lab-compare` best-valid-checkpoint selection
- [x] Shared `lib/` helpers
- [x] Unit tests for validators

## Phase 3 — Fixtures + docs

- [x] Three fixture Skills
- [x] Templates minimal/standard/rigorous
- [x] docs/RFC.md, CHANGELOG, plugin README, root README
- [x] Remove hello-world; retarget marketplaces

## Phase 4 — Verify + ship

- [x] Integration tests (`--manifest-only` / full)
- [x] Commit, push, draft PR
