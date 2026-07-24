# Skill Lab MVP

## Phase 0 — Foundation
- [x] Create branch `cursor/skill-lab-mvp-0eac`
- [ ] Scaffold `plugins/skill-lab` layout + manifests
- [ ] Add JSON schemas (trigger/output/result/manifest/state)
- [ ] Empty `hooks/hooks.json` for structure CI

## Phase 1 — Reasoning + Interaction
- [ ] Agents: intent-compiler, skill-architect, output-evaluator
- [ ] Skills: create (+ refs), evaluate (+ refs)

## Phase 2 — Verification plane (bash + jq)
- [ ] `bin/skill-lab-validate` package validator
- [ ] `bin/skill-lab-eval` schema + score aggregation
- [ ] `bin/skill-lab-compare` best-valid-checkpoint selection
- [ ] Shared `lib/` helpers
- [ ] Unit tests for validators

## Phase 3 — Fixtures + docs
- [ ] Three fixture Skills
- [ ] Templates minimal/standard/rigorous
- [ ] docs/RFC.md, CHANGELOG, plugin README, root README
- [ ] Remove hello-world; retarget marketplaces

## Phase 4 — Verify + ship
- [ ] Integration tests (`--manifest-only` / full)
- [ ] Commit, push, draft PR
