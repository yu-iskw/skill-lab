# Skill Lab RFC — Scenario Validation

Validates Approach D (hybrid Claude Code plugin: workflow skills + subagents + deterministic scripts) under monorepo placement `plugins/skill-lab/`.

**MVP surface:** skills `create`, `evaluate`; agents `intent-compiler`, `skill-architect`, `output-evaluator`; plus package/schema validators (static).

**Deferred (post-MVP):** `improve`, `diagnose-trigger`, `extract-from-session`; agents `trigger-evaluator`, `adversarial-reviewer`, `repair-planner` as full roles; hooks; MCP; Codex adapter; execution sandbox for untrusted scripts.

## Routing (RFC Level 1 / 2 / 3)

| Level  | When                                                  | Create path                                                | Eval posture                                                          |
| ------ | ----------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------- |
| **L1** | Deterministic I/O, structural checks, little judgment | Thin: `intent-compiler` → `skill-architect` → static gates | Hard gates only; soft judge optional/off                              |
| **L2** | Subjective quality, rubrics, taste                    | Full MVP create; curated soft evals required               | Soft scores + human accept on ship                                    |
| **L3** | Multi-artifact / app-dev workflows                    | Full MVP + richer package plan                             | Hard gates strict; soft + human; security review when scripts present |

`intent-compiler` emits `complexity_level` ∈ {1,2,3}. Downstream agents must not invent artifacts the level does not justify.

## Checklist (every scenario)

1. Clear component boundaries
2. No unnecessary artifacts
3. Observable hard gates
4. Non-mutating evaluator
5. Bounded repair
6. Human approval when needed
7. Portable Skill vs Claude-specific plugin separation

---

## Scenario 1 — Create minimal deterministic Skill

**Example intent:** “Validate YAML frontmatter fields and exit non-zero on missing keys.”

**Route:** **Level 1**

### Scenario 1 flow

1. `create` → `intent-compiler` → plan: L1, SKILL.md (+ tiny `scripts/` only if justified).
2. `skill-architect` writes portable package under target `skills/<name>/`.
3. Static validators: frontmatter schema, name rules, no undeclared dirs.
4. Optional `evaluate`: structural fixtures only; `output-evaluator` uses **static** assertions (MVP MUST NOT execute Skill `scripts/` for exit/stdout).
5. No soft rubric; no human gate unless author opts in to publish.

### Scenario 1 checklist

| Criterion          | Result                                                                                  |
| ------------------ | --------------------------------------------------------------------------------------- |
| Boundaries         | Compiler plans; architect writes; validators/evaluator read-only.                       |
| Artifacts          | SKILL.md required; `scripts/` only if L1 plan says so; no unnecessary references/hooks. |
| Hard gates         | Schema/name/layout fail → block; observable in CLI + `.skill-lab/runs/`.                |
| Non-mutating eval  | `evaluate` / `output-evaluator` never write Skill files.                                |
| Bounded repair     | Architect may retry ≤ N (default 1 in MVP) on hard-gate fail; then stop with report.    |
| Human approval     | Not required for L1 local iterate.                                                      |
| Portable vs Claude | Output is portable Agent Skill; no `.claude-plugin/` inside generated Skill.            |

**Verdict:** RFC holds — L1 routing prevents overbuild.

---

## Scenario 2 — Create subjective writing Skill

**Example intent:** “Rewrite prose in a house voice; prioritize clarity over cleverness.”

**Route:** **Level 2**

### Scenario 2 flow

1. `intent-compiler` → L2; success criteria as rubric dimensions.
2. `skill-architect` → SKILL.md + `evals/` with fixtures.
3. Hard gates: package validity only (not “is writing good”).
4. `evaluate` → `output-evaluator` applies rubric; records judge model id.
5. Ship/accept requires **human approval** of soft scores (or explicit waive).

### Scenario 2 checklist

| Criterion          | Result                                                                                |
| ------------------ | ------------------------------------------------------------------------------------- |
| Boundaries         | Soft judgment stays in `output-evaluator`; architect does not self-grade into a pass. |
| Artifacts          | Rubric + eval fixtures justified; no scripts/hooks unless plan demands.               |
| Hard gates         | Invalid package still blocks; soft score is visible, not a silent hard fail.          |
| Non-mutating eval  | Judge writes run records only under `.skill-lab/runs/`.                               |
| Bounded repair     | Create-loop repair only on hard gates / missing eval stubs.                           |
| Human approval     | **Required** before treating L2 Skill as accepted for distribution.                   |
| Portable vs Claude | Rubric+evals travel in Skill; Skill Lab judge config stays in plugin/project.         |

**Verdict:** RFC holds — L2 forces human gate on subjective accept.

---

## Scenario 3 — Create complex application-development Skill

**Example intent:** “Scaffold a small service: layout conventions, test commands, progressive disclosure for API refs.”

**Route:** **Level 3**

### Scenario 3 flow

1. `intent-compiler` → L3 plan: SKILL.md + `references/` + optional `scripts/` + curated `evals/`.
2. `skill-architect` emits progressive-disclosure layout; trigger text remains in SKILL.md description/body as appropriate.
3. Hard gates: structure, frontmatter, eval presence for L3, script **static** checks (no execution in MVP).
4. `evaluate` runs fixture prompts; `output-evaluator` checks expectations + package invariants.
5. Human approval for first accept of L3 Skills.

### Scenario 3 checklist

| Criterion          | Result                                                                             |
| ------------------ | ---------------------------------------------------------------------------------- |
| Boundaries         | Architect builds package; evaluator judges; create orchestrates only.              |
| Artifacts          | Multi-file OK because L3; reject unrelated agents/hooks/MCP inside portable Skill. |
| Hard gates         | L3 minimum package shape + static script lint are blocking and logged.             |
| Non-mutating eval  | Same as other levels.                                                              |
| Bounded repair     | Retries only against gate diffs; cap N then escalate to human.                     |
| Human approval     | **Required** for initial L3 accept.                                                |
| Portable vs Claude | Skill remains host-portable; Claude plugin packaging is Skill Lab’s concern.       |

**Verdict:** RFC holds — L3 licenses complexity without collapsing into a mini-plugin.

---

## Scenario 4 — Improve Skill with false-positive triggering

**Example intent:** Existing Skill triggers on unrelated prompts; reduce false positives.

**Route:** Treat as **improve** workflow; complexity inherits Skill level.

### MVP mapping (gap)

MVP has **no** `improve` skill. Closest path: human edits description/triggers → `evaluate` only (diagnostic). Create must not silently overwrite an installed Skill without an improve contract.

**Paper path (post-MVP):** `improve` + trigger evaluator + neighbor confusion tests + bounded repair + human approval of description changes.

| Criterion         | MVP                                         | Post-MVP                                      |
| ----------------- | ------------------------------------------- | --------------------------------------------- |
| Boundaries        | Eval-only diagnosis; no autonomous rewrite. | `improve` ≠ `create`.                         |
| Non-mutating eval | Yes.                                        | Yes; repair is separate mutating stage.       |
| Human approval    | Any rewrite is human-driven in MVP.         | **Required** for trigger/description changes. |

**Verdict:** Architecture holds; **scenario 4 is out of MVP scope**. MVP correctly degrades to non-mutating evaluation.

---

## Scenario 5 — Evaluate Skill containing dangerous validation script

**Example intent:** Skill ships `scripts/validate.sh` that curls the network, writes `$HOME`, or `rm -rf`.

### Scenario 5 flow

1. `evaluate` loads package; **static** package validator runs (ADR 0001: no untrusted execution by default).
2. Dangerous patterns (network, absolute writes, destructive shell) → **hard fail**; no script execution; `hard_gates_passed=false`.
3. Per RFC §9 short-circuit: **do not** run quality / textual soft scoring after this hard fail (unless debug). Report cites file/line evidence only.
4. Human must approve any override/waive (default: no waive in CI).

### Scenario 5 checklist

| Criterion          | Result                                                        |
| ------------------ | ------------------------------------------------------------- |
| Boundaries         | Static security/policy checks ≠ LLM judge.                    |
| Artifacts          | No repair artifacts invented during evaluate.                 |
| Hard gates         | Dangerous-script findings are blocking and persisted.         |
| Non-mutating eval  | Evaluator reports only.                                       |
| Bounded repair     | Out of band; evaluate does not loop mutate.                   |
| Human approval     | Required to force-continue past security hard fail.           |
| Portable vs Claude | Policy engine lives in Skill Lab plugin/CLI; Skill unchanged. |

**Verdict:** RFC holds for MVP **if** static dangerous-script gate is in the validator (MVP-critical).

---

## Cross-scenario matrix

| Scenario                 | Level    | MVP components                                                                   | Deferred                                | Human gate              |
| ------------------------ | -------- | -------------------------------------------------------------------------------- | --------------------------------------- | ----------------------- |
| 1 Minimal deterministic  | L1       | create, intent-compiler, skill-architect, validators, evaluate, output-evaluator | execution adapter                       | Optional                |
| 2 Subjective writing     | L2       | same + in-skill evals                                                            | improve, richer suites                  | **Yes** (accept)        |
| 3 Complex app-dev        | L3       | same + richer package                                                            | trigger-evaluator, adversarial-reviewer | **Yes** (first accept)  |
| 4 False-positive improve | inherits | evaluate diagnosis only                                                          | **improve**, trigger-evaluator          | **Yes** (trigger edits) |
| 5 Dangerous script       | any      | evaluate, static validators                                                      | execution sandbox                       | **Yes** (waive only)    |

## Validated constraints (already in RFC / ADR 0001)

1. L1/L2/L3 `artifact_budget` defaults are in RFC §8; `skill-state` requires `artifact_budget` booleans.
2. `evaluate` / `output-evaluator` never mutate Skill packages and never execute Skill `scripts/` in MVP.
3. MVP create repair: `max_iterations = 1`.
4. Scenario 4 is **out of MVP scope**.
5. Dangerous-script **static** hard gate is MVP-critical (`severity: hard` only).
6. Generated Skills stay portable; Claude-only wiring stays under `plugins/skill-lab/`.

## Overall

Approach D + Level routing validates scenarios **1–3 and 5** on the MVP surface. Scenario **4** validates the architecture only with deferred `improve` / trigger evaluation; MVP correctly degrades to non-mutating evaluation rather than unsafe autonomous rewrite.
