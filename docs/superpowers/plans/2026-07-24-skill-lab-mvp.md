# Skill Lab MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Claude Code plugin at `plugins/skill-lab/` that creates and evaluates Agent Skills via workflow skills, three subagents, and a TypeScript deterministic validator—without hosted infra, publishing, or Codex eval parity.

**Architecture:** Hybrid Approach D. Normative rules: [RFC](../../RFC.md) + [ADR 0001](../../decisions/0001-mvp-open-question-defaults.md). Contracts: [docs/contracts](../../contracts/).

**Tech Stack:** TypeScript (Node 20+), JSON Schema draft 2020-12, Bash smoke wrappers, existing monorepo `integration_tests/` + Docker, Claude Code plugin layout.

## Global Constraints

See ADR 0001 and RFC §3/§6/§9/§11. Summary:

- Plugin at `plugins/skill-lab/`; keep `plugins/hello-world/`.
- No Skill mutation from `evaluate` / `output-evaluator`; no Skill `scripts/` execution in MVP.
- Hard gates dominate; short-circuit soft eval on hard fail.
- `max_iterations = 1`; `selected_checkpoint` naming; tokens/cost stay `null` unless host-exposed.

---

## File map (create / modify)

| Path                                           | Responsibility                                              |
| ---------------------------------------------- | ----------------------------------------------------------- |
| `plugins/skill-lab/.claude-plugin/plugin.json` | Plugin manifest                                             |
| `plugins/skill-lab/skills/create/SKILL.md`     | Create orchestration                                        |
| `plugins/skill-lab/skills/evaluate/SKILL.md`   | Evaluate orchestration (non-mutating)                       |
| `plugins/skill-lab/agents/*.md`                | Three MVP subagents                                         |
| `plugins/skill-lab/schemas/`                   | Symlink or CI-gated mirror of `docs/contracts/schemas/`     |
| `plugins/skill-lab/bin/skill-lab-validate`     | CLI entry                                                   |
| `plugins/skill-lab/cli/`                       | TypeScript validator sources                                |
| `plugins/skill-lab/evals/fixtures/`            | Three corpus Skills (self-tests, not user-installed skills) |
| Marketplace JSON ×3                            | Register `skill-lab`                                        |

---

### Task 1: Plugin skeleton + marketplace registration

**Files:** `plugins/skill-lab/.claude-plugin/plugin.json`, marketplaces, schemas link, README

**Steps:**

- [ ] Clone layout from `plugins/hello-world/` (trim MCP/LSP/hooks; hooks not required for skill-lab MVP — use `integration_tests/` discovery, not `implement-plugin` hooks-required structure check as a hard gate).
- [ ] Follow `.claude/skills/implement-plugin/` for manifest fields.
- [ ] Symlink or CI-diff-gate `plugins/skill-lab/schemas` → `docs/contracts/schemas` (ADR 0001).
- [ ] Register in `.claude-plugin/marketplace.json`, `.codex-plugin/marketplace.json`, `.cursor-plugin/marketplace.json`.
- [ ] Run `./integration_tests/run.sh --skip-loading --verbose`.
- [ ] Commit: `feat(skill-lab): add plugin skeleton and marketplace entry`

**Acceptance:** Integration tests discover `skill-lab`; manifest validates.

---

### Task 2: TypeScript package validator (hard gates)

**Files:** under `plugins/skill-lab/cli/` + `bin/skill-lab-validate`

**Steps:**

- [ ] Scaffold Node 20 package (`ajv` OK).
- [ ] Reuse/wrap `.claude/skills/implement-agent-skills/scripts/check-skill-frontmatter.sh` and `validate-skill-structure.sh` for shared Agent Skills gates where practical.
- [ ] Implement Skill Lab–specific gates: eval JSON vs frozen schemas; dangerous-script static scan; no `.claude-plugin/` in generated packages; emit hard findings only (soft-eval short-circuit is owned by workflow orchestration per RFC §9).
- [ ] Implement best-valid-checkpoint selection helper used by workflows (single field: `selected_checkpoint`).
- [ ] Unit tests with fixtures (valid minimal, bad name, dangerous script, hard-vs-quality).
- [ ] Commit: `feat(skill-lab): deterministic package validator and checkpoint select`

**Acceptance:** CLI exits non-zero on hard failures with structured JSON; selects highest-scoring valid checkpoint.

---

### Task 3: Subagents

**Steps:**

- [ ] Author three agents per ADR 0001 tool posture table + `.claude/skills/implement-sub-agents/` templates.
- [ ] `output-evaluator`: read-only toward Skills; may invoke `skill-lab-validate`; MUST NOT execute Skill `scripts/`.
- [ ] Commit: `feat(skill-lab): add MVP subagents`

**Acceptance:** Agents load as `skill-lab:*`; tool posture matches ADR table.

---

### Task 4: Workflow skills `create` and `evaluate`

**Steps:**

- [ ] Orchestration only (progressive disclosure): run validate → short-circuit soft eval after hard fail (RFC §9) → ≤1 repair → set `selected_checkpoint` → any failed `severity: hard` suite assertion invalidates the checkpoint.
- [ ] Commit: `feat(skill-lab): add create and evaluate workflow skills`

**Acceptance:** `/skill-lab:create` and `/skill-lab:evaluate` documented; evaluate never mutates.

---

### Task 5: Three fixture Skills + self-evals

**Files:** `plugins/skill-lab/evals/fixtures/{normalize-config,technical-notes-to-article,boundary-risk-deploy}/`

Corpus Skills live under `evals/fixtures/` (product self-tests). Each fixture is a portable Skill tree (`SKILL.md`, optional in-package `evals/` for output suites). They are **not** installed as plugin `skills/`.

**Steps:**

- [ ] Build three fixtures (RFC fixture priority: deterministic, writing, boundary/dangerous-script).
- [ ] Output-eval JSON only for MVP (no trigger-eval consumption).
- [ ] Dangerous-script positive fixture must hard-fail static scan.
- [ ] Commit: `test(skill-lab): add three fixture skills and eval corpus`

---

### Task 6: Plugin docs wiring

**Already done in Phase 0:** root `.gitignore` (entire `.skill-lab/`), `docs/architecture/overview.md`, root README pointers.

**Steps:**

- [ ] Add `plugins/skill-lab/CHANGELOG.md` and plugin README linking RFC/ADR/plan.
- [ ] Document run layout from RFC §12.
- [ ] Commit: `docs(skill-lab): plugin README and changelog`

---

### Task 7: Integration + Docker CI green

**Steps:**

- [ ] `make lint`
- [ ] `cd plugins/skill-lab/cli && npm test`
- [ ] `./integration_tests/run.sh`
- [ ] `make test-integration-docker` when Docker available
- [ ] Commit: `test(skill-lab): make CI green for skill-lab plugin`

---

## Out of scope

`improve`, trigger diagnosis, Codex eval parity, hooks/MCP, untrusted script execution, publishing.

## Success criteria

See RFC §14 Success criteria (same seven checks).
