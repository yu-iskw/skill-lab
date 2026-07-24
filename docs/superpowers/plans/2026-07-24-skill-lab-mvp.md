# Skill Lab MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Claude Code plugin at `plugins/skill-lab/` that creates and evaluates Agent Skills via workflow skills, three subagents, and a TypeScript deterministic validator—without hosted infra, publishing, or Codex eval parity.

**Architecture:** Hybrid Approach D. User-facing `/skill-lab:create` and `/skill-lab:evaluate` orchestrate; `intent-compiler`, `skill-architect`, and `output-evaluator` isolate judgment; `skill-lab-validate` enforces hard gates (schema, naming, static dangerous-script checks). Contracts live in `docs/contracts/schemas/` (schema_version `1.0.0`). Generated Skills stay portable; Claude-only wiring stays in the plugin.

**Tech Stack:** TypeScript (Node 20+), JSON Schema draft 2020-12, Bash smoke wrappers, existing monorepo `integration_tests/` + Docker, Claude Code plugin layout.

## Global Constraints

- Product plugin path: `plugins/skill-lab/` only (keep `plugins/hello-world/`).
- Portable generated Skills: `SKILL.md` + optional `references/`, `scripts/`, `assets/`, `evals/` — never embed `.claude-plugin/` inside generated packages.
- Evaluator agents and `evaluate` workflow MUST NOT mutate the target Skill.
- MVP validator: static + schema only; do not execute untrusted Skill scripts.
- Dangerous-script static hard gate is required before claiming evaluate MVP done.
- Tokens/cost in manifests: always `null` unless host-exposed; never invent.
- MVP repair: at most **1** repair iteration; select best valid checkpoint.
- MVP workflows: `create`, `evaluate` only.
- MVP agents: `intent-compiler`, `skill-architect`, `output-evaluator` only.
- Install/test via `--plugin-dir` / monorepo marketplace; no `~/.claude` crawl.
- Follow ADR 0001 and [RFC scenario validation](../../architecture/rfc-scenario-validation.md).
- Hard-gate failure invalidates the checkpoint regardless of average score.

---

## File map (create / modify)

| Path | Responsibility |
| --- | --- |
| `plugins/skill-lab/.claude-plugin/plugin.json` | Plugin manifest |
| `plugins/skill-lab/skills/create/SKILL.md` | Create orchestration |
| `plugins/skill-lab/skills/evaluate/SKILL.md` | Evaluate orchestration (non-mutating) |
| `plugins/skill-lab/agents/intent-compiler.md` | Intent contract → skill-state |
| `plugins/skill-lab/agents/skill-architect.md` | Minimal package generation |
| `plugins/skill-lab/agents/output-evaluator.md` | Rubric review; read/execute posture, no Skill writes |
| `plugins/skill-lab/schemas/*` | Copies of frozen contracts |
| `plugins/skill-lab/bin/skill-lab-validate` | CLI entry (node) |
| `packages/skill-lab-cli/` | TypeScript validator, scoring, checkpoint select |
| `plugins/skill-lab/evals/` | Three fixture Skills + cases |
| `.claude-plugin/marketplace.json` | Register `skill-lab` |
| `.gitignore` | `.skill-lab/` traces |
| `docs/contracts/schemas/*` | Already frozen in Phase 0 — do not break without ADR |

---

### Task 1: Plugin skeleton + marketplace registration

**Files:**
- Create: `plugins/skill-lab/.claude-plugin/plugin.json`
- Create: `plugins/skill-lab/README.md`
- Modify: `.claude-plugin/marketplace.json` (and Codex/Cursor marketplace twins if present)
- Create: `plugins/skill-lab/schemas/` (copy from `docs/contracts/schemas/`)

**Steps:**
- [ ] Add `plugin.json` with `name: skill-lab`, `version: 0.1.0`, description, Apache-2.0, author.
- [ ] Copy schemas into `plugins/skill-lab/schemas/`.
- [ ] Register plugin in root marketplace JSON files with `source: ./plugins/skill-lab`.
- [ ] Run `./integration_tests/run.sh --skip-loading` (or full if Claude CLI available) and confirm discovery/validate-manifest pass.
- [ ] Commit: `feat(skill-lab): add plugin skeleton and marketplace entry`

**Acceptance:** Integration tests discover `skill-lab`; manifest validates.

**Test plan:** `./integration_tests/run.sh --skip-loading --verbose` → exit 0 for skill-lab.

**MVP slice:** Empty plugin that CI accepts.

---

### Task 2: TypeScript package validator (hard gates)

**Files:**
- Create: `packages/skill-lab-cli/package.json`
- Create: `packages/skill-lab-cli/tsconfig.json`
- Create: `packages/skill-lab-cli/src/validate.ts`
- Create: `packages/skill-lab-cli/src/dangerous-scripts.ts`
- Create: `packages/skill-lab-cli/src/schema.ts`
- Create: `packages/skill-lab-cli/src/checkpoints.ts`
- Create: `packages/skill-lab-cli/src/cli.ts`
- Create: `packages/skill-lab-cli/tests/*.test.ts`
- Create: `plugins/skill-lab/bin/skill-lab-validate` (wrapper invoking node)

**Steps:**
- [ ] Scaffold package with Node 20, no network deps beyond `ajv` (or similar) for JSON Schema.
- [ ] Implement checks: SKILL.md exists; YAML frontmatter `name`+`description`; name/dir equality; name pattern; description length ≤1024; optional eval JSON validates against frozen schemas; duplicate eval IDs; fixture paths exist when declared.
- [ ] Implement static dangerous-script scanner (network curl/wget, `rm -rf`, writes under `$HOME`, `chmod 777`, etc.) → hard fail.
- [ ] Implement score aggregation: any hard fail ⇒ checkpoint invalid even if quality average is high.
- [ ] Implement best-valid-checkpoint selection from a checkpoints directory/manifest.
- [ ] Write unit tests with fixtures under `packages/skill-lab-cli/tests/fixtures/` (valid minimal, bad name, dangerous script, hard-vs-quality).
- [ ] Wire `bin/skill-lab-validate`.
- [ ] Commit: `feat(skill-lab-cli): deterministic package validator and checkpoint select`

**Acceptance:** CLI exits non-zero on hard failures with structured JSON findings; selects highest-scoring valid checkpoint.

**Test plan:** `cd packages/skill-lab-cli && npm test` — all fixtures pass/fail as expected.

**MVP slice:** `skill-lab-validate path/to/skill` works offline.

---

### Task 3: Subagents (intent, architect, output-evaluator)

**Files:**
- Create: `plugins/skill-lab/agents/intent-compiler.md`
- Create: `plugins/skill-lab/agents/skill-architect.md`
- Create: `plugins/skill-lab/agents/output-evaluator.md`

**Steps:**
- [ ] `intent-compiler`: read-oriented tools; emit skill-state JSON conforming to `skill-state.schema.json`; set `complexity_level` and `artifact_budget`; list assumptions and irreversible actions.
- [ ] `skill-architect`: scoped write to target skill path only; generate minimal files per artifact_budget; never add Claude plugin manifests to generated Skills; produce checkpoint 0.
- [ ] `output-evaluator`: `disallowedTools` include Write/Edit (or equivalent); assess criteria with evidence objects; record judge model id; never modify Skill or expected eval outputs.
- [ ] Validate frontmatter with repo subagent scripts if present.
- [ ] Commit: `feat(skill-lab): add MVP subagents`

**Acceptance:** Agents load as `skill-lab:intent-compiler` (etc.); permissions match ADR table.

**Test plan:** `test-component-discovery` + manual frontmatter check; unit-less content review against templates in `.claude/skills/implement-sub-agents/`.

**MVP slice:** Three agent files with correct tool posture.

---

### Task 4: Workflow skills `create` and `evaluate`

**Files:**
- Create: `plugins/skill-lab/skills/create/SKILL.md` (+ optional `references/orchestration.md`)
- Create: `plugins/skill-lab/skills/evaluate/SKILL.md` (+ optional `references/eval-pipeline.md`)

**Steps:**
- [ ] `create`: compile intent via subagent → route L1/L2/L3 → architect → run `skill-lab-validate` → optional output-evaluator → at most one repair via architect → select best valid checkpoint → report assumptions, evidence, limitations.
- [ ] `evaluate`: load path; refuse writes; validate + output-evaluator; write run under `.skill-lab/runs/<run-id>/`; never mutate target.
- [ ] Document human approval gates for L2/L3 accept and any irreversible actions (stop before performing them).
- [ ] Commit: `feat(skill-lab): add create and evaluate workflow skills`

**Acceptance:** Skills expose `/skill-lab:create` and `/skill-lab:evaluate`; instructions do not duplicate full evaluator rubrics (progressive disclosure).

**Test plan:** Plugin load + component discovery; golden prompt dry-run checklist in README.

**MVP slice:** Orchestration instructions only—no duplicate domain encyclopedia.

---

### Task 5: Three fixture Skills + self-evals

**Files:**
- Create: `plugins/skill-lab/evals/fixtures/normalize-config/` (minimal deterministic)
- Create: `plugins/skill-lab/evals/fixtures/technical-notes-to-article/` (subjective writing)
- Create: `plugins/skill-lab/evals/fixtures/boundary-risk-deploy/` (proposes deploy, stops)
- Create: matching trigger/output eval JSON where applicable
- Create: golden expected validate results

**Steps:**
- [ ] Build three portable Skill packages used as corpus (RFC §25.1 items 1, 2, 5 prioritized; coding Skill can be Phase 2 if time-boxed).
- [ ] Ensure dangerous-script positive fixture exists for scenario 5 (script that would be dangerous if executed; static scanner must fail it).
- [ ] Add self-eval questions as a short checklist in `plugins/skill-lab/evals/README.md`.
- [ ] Commit: `test(skill-lab): add three fixture skills and eval corpus`

**Acceptance:** Validator passes good fixtures; fails dangerous fixture; ≥ enough cases to exercise schemas (aim ≥20 assertion/case rows across fixtures before any breaking schema change).

**Test plan:** `skill-lab-validate` on each fixture; npm tests include corpus.

**MVP slice:** Three fixtures proving L1, L2, and security hard gate.

---

### Task 6: Run store defaults + gitignore + docs wiring

**Files:**
- Modify: `.gitignore`
- Create: `docs/architecture/overview.md` (short five-plane pointer)
- Modify: root `README.md` (Skill Lab pointer — brief)
- Create: `plugins/skill-lab/CHANGELOG.md`

**Steps:**
- [ ] Gitignore `.skill-lab/runs/*/traces/` (or entire `.skill-lab/` except optional committed scorecards policy).
- [ ] Document run layout from RFC §21 in plugin README.
- [ ] Link RFC, ADR, plan from plugin README.
- [ ] Commit: `docs(skill-lab): run store policy and README wiring`

**Acceptance:** Accidental traces not committed; docs navigable.

**Test plan:** `git check-ignore -v .skill-lab/runs/x/traces/a.json`

---

### Task 7: Integration + Docker CI green

**Files:**
- Modify: `integration_tests/` only if skill-lab needs an exception (prefer none)
- Modify: `Makefile` only if a `test-skill-lab-cli` target is useful

**Steps:**
- [ ] `make lint`
- [ ] `cd packages/skill-lab-cli && npm test`
- [ ] `./integration_tests/run.sh`
- [ ] `make test-integration-docker` when Docker available
- [ ] Fix failures; commit: `test(skill-lab): make CI green for skill-lab plugin`

**Acceptance:** All existing plugins + skill-lab pass CI-parity checks.

---

## Out of scope (do not implement in this plan)

- `improve`, `diagnose-trigger`, `extract-from-session`
- `trigger-evaluator`, `adversarial-reviewer`, `repair-planner` agents
- Codex adapter / eval parity
- Hooks, MCP, hosted registry, web UI
- Untrusted script execution adapters
- Autonomous publishing / PR merge

## Success criteria (RFC §26.3)

1. Novice request → valid minimal Skill via create path.
2. Existing Skill evaluated without mutation.
3. Deterministic failures reported with evidence.
4. Subjective evaluation in separate agent context.
5. Hard-gate failures not offset by aggregate score.
6. Best valid checkpoint selected.
7. Completion report claims traceable to run evidence.
