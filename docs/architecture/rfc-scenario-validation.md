# Skill Lab RFC — Scenario Validation

Validates Approach D (hybrid Claude Code plugin: workflow skills + subagents + deterministic scripts) under monorepo placement `plugins/skill-lab/`.

**MVP surface:** skills `create`, `evaluate`; agents `intent-compiler`, `skill-architect`, `output-evaluator`; plus package/schema validators (static).

**Deferred (post-MVP):** `improve` skill; `eval-suite-designer`; `confusion-tester`; `repair-controller`; `script-security-scanner`; execution/sandbox adapter; approval-broker UX; run-metadata hooks; Codex eval adapters.

## Routing (RFC Level 1 / 2 / 3)

| Level | When | Create path | Eval posture |
| --- | --- | --- | --- |
| **L1** | Deterministic I/O, structural checks, little judgment | Thin: `intent-compiler` → `skill-architect` → static gates | Hard gates only; soft judge optional/off |
| **L2** | Subjective quality, rubrics, taste | Full MVP create; curated soft evals required | Soft scores + human accept on ship |
| **L3** | Multi-artifact / app-dev workflows (scripts, refs, progressive disclosure) | Full MVP + richer package plan | Hard gates strict; soft + human; security review when scripts present |

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

### MVP flow

1. `create` → `intent-compiler` → plan: L1, SKILL.md (+ tiny `scripts/` only if check is fragile).  
2. `skill-architect` writes portable package under target `skills/<name>/`.  
3. Static validators: frontmatter schema, name rules, no undeclared dirs.  
4. Optional `evaluate`: structural fixtures only; `output-evaluator` scores pass/fail against expected exit/stdout.  
5. No soft rubric; no human gate unless author opts in to publish.

### Checklist

| Criterion | Result |
| --- | --- |
| Boundaries | Compiler plans; architect writes; validators/evaluator read-only. |
| Artifacts | SKILL.md required; `scripts/` only if L1 plan says so; **no** `references/`, empty eval theatre, or plugin hooks. |
| Hard gates | Schema/name/layout fail → block ship; observable in CLI + `.skill-lab/runs/`. |
| Non-mutating eval | `evaluate` / `output-evaluator` never write Skill files. |
| Bounded repair | Architect may retry ≤ N (RFC default) on hard-gate fail; then stop with report. |
| Human approval | Not required for L1 local iterate; optional for publish. |
| Portable vs Claude | Output is portable Agent Skill; no `.claude-plugin/` inside generated Skill. |

### Post-MVP

`repair-controller` formalizes retry policy; execution adapter runs script fixtures in Docker if behavioral evals needed.

**Verdict:** RFC holds — L1 routing prevents overbuild.

---

## Scenario 2 — Create subjective writing Skill

**Example intent:** “Rewrite prose in a house voice; prioritize clarity over cleverness.”

**Route:** **Level 2**

### MVP flow

1. `intent-compiler` → L2; success criteria as rubric dimensions (tone, clarity, fidelity).  
2. `skill-architect` → SKILL.md + `evals/` with positive/negative style fixtures (in-skill, ADR 0001).  
3. Hard gates: package validity only (not “is writing good”).  
4. `evaluate` → `output-evaluator` applies rubric; records judge model id; soft fail ≠ mutate.  
5. Ship/accept requires **human approval** of soft scores (or explicit waive).

### Checklist

| Criterion | Result |
| --- | --- |
| Boundaries | Soft judgment stays in `output-evaluator`; architect does not self-grade into a pass. |
| Artifacts | Rubric + eval fixtures justified; **no** scripts/hooks unless plan demands. |
| Hard gates | Invalid package still blocks; soft score is visible, not a silent hard fail. |
| Non-mutating eval | Judge writes run records only under `.skill-lab/runs/`. |
| Bounded repair | Create-loop repair only on hard gates / missing eval stubs; not infinite “make prose better” loops. |
| Human approval | **Required** before treating L2 Skill as accepted for distribution. |
| Portable vs Claude | Rubric+evals travel in Skill; Skill Lab judge config stays in plugin/project. |

### Post-MVP

`eval-suite-designer` expands fixtures; `improve` consumes human feedback without eval rewriting history.

**Verdict:** RFC holds — L2 forces human gate on subjective accept.

---

## Scenario 3 — Create complex application-development Skill

**Example intent:** “Scaffold a small service: layout conventions, test commands, progressive disclosure for API refs.”

**Route:** **Level 3**

### MVP flow

1. `intent-compiler` → L3 plan: SKILL.md + `references/` + optional `scripts/` + curated `evals/`.  
2. `skill-architect` emits progressive-disclosure layout; must not bury trigger text only in references.  
3. Hard gates: structure, frontmatter, eval presence for L3, script static checks (no execution in MVP).  
4. `evaluate` runs fixture prompts; `output-evaluator` checks behavioral expectations + package invariants.  
5. Human approval for first accept of L3 Skills (complexity + blast radius).

### Checklist

| Criterion | Result |
| --- | --- |
| Boundaries | Architect builds package; evaluator judges; create orchestrates only. |
| Artifacts | Multi-file OK **because L3**; still reject unrelated agents/hooks/MCP inside portable Skill. |
| Hard gates | L3 minimum package shape + static script lint are blocking and logged. |
| Non-mutating eval | Same as other levels. |
| Bounded repair | Retries only against gate diffs; cap N then escalate to human. |
| Human approval | **Required** for initial L3 accept. |
| Portable vs Claude | Skill remains host-portable; Claude plugin packaging is Skill Lab’s concern (`plugins/skill-lab/`), not the user’s Skill. |

### Post-MVP

Execution adapter for scripted golden paths; `confusion-tester` vs neighbor Skills; richer `repair-controller`.

**Verdict:** RFC holds — L3 licenses complexity without collapsing into a mini-plugin.

---

## Scenario 4 — Improve Skill with false-positive triggering

**Example intent:** Existing Skill triggers on unrelated prompts; reduce false positives without gutting true triggers.

**Route:** Treat as **improve** workflow; complexity inherits Skill level (often L2/L3).

### MVP mapping (gap)

MVP has **no** `improve` skill. Closest path: human edits description/triggers → `evaluate` only (diagnostic). Create must not silently overwrite an installed Skill without an improve contract.

**Paper path (post-MVP):**

1. `improve` → `intent-compiler` (delta intent: false-positive examples).  
2. `confusion-tester` loads sibling Skills under same `skills/` root (+ `--also`).  
3. Propose trigger/description diffs; hard gate = confusion metric threshold.  
4. `evaluate` / `output-evaluator` compare before/after on fixed suites (non-mutating).  
5. `repair-controller` applies at most N patch cycles; human approves trigger text changes.

### Checklist

| Criterion | MVP | Post-MVP |
| --- | --- | --- |
| Boundaries | Eval-only diagnosis; no autonomous rewrite. | `improve` ≠ `create`; confusion-tester ≠ judge. |
| Artifacts | No new Skill copy unless user asks. | Patch existing package; no extra scaffolding. |
| Hard gates | N/A beyond package validate. | Confusion regression gate observable in run record. |
| Non-mutating eval | Yes. | Yes; repair is separate mutating stage. |
| Bounded repair | N/A. | ≤ N patch loops, then human. |
| Human approval | Any rewrite is human-driven in MVP. | **Required** for trigger/description changes. |
| Portable vs Claude | Eval tooling in plugin; Skill stays portable. | Same. |

**Verdict:** RFC incomplete for MVP on this scenario — **deferred `improve` + `confusion-tester` required**; eval-only MVP is safe but not sufficient.

---

## Scenario 5 — Evaluate Skill containing dangerous validation script

**Example intent:** Skill ships `scripts/validate.sh` that curls the network, writes `$HOME`, or `rm -rf`.

**Route:** Eval path; Skill level irrelevant — **security hard gate** dominates.

### MVP flow

1. `evaluate` loads package; **static** package validator runs (ADR 0001: no untrusted execution by default).  
2. Dangerous patterns (network, absolute writes, destructive shell) → **hard fail**; no script execution.  
3. `output-evaluator` may still score textual fixtures **without** invoking Skill scripts.  
4. Report cites file/line evidence; does not “fix” the script.  
5. Human must approve any override/waive (default: no waive in CI).

### Checklist

| Criterion | Result |
| --- | --- |
| Boundaries | Static security/policy checks ≠ LLM judge; judge never asked to “approve” dangerous code. |
| Artifacts | No repair artifacts invented during evaluate. |
| Hard gates | Dangerous-script findings are blocking and persisted in run output. |
| Non-mutating eval | Evaluator does not quarantine-by-rewrite; only reports. |
| Bounded repair | Out of band: user/create/improve later; evaluate does not loop mutate. |
| Human approval | Required to force-continue past security hard fail (discouraged). |
| Portable vs Claude | Policy engine lives in Skill Lab plugin/CLI; Skill package unchanged. |

### Post-MVP

`script-security-scanner` as dedicated agent/tool; execution adapter in Docker `non-root --network=none` for opted-in behavioral tests; still fail closed on policy violations.

**Verdict:** RFC holds for MVP **if** static dangerous-script gate is in the validator (must be explicit in schemas/CLI). Execution-based confirmation is post-MVP only.

---

## Cross-scenario matrix

| Scenario | Level | MVP components | Deferred components | Human gate |
| --- | --- | --- | --- | --- |
| 1 Minimal deterministic | L1 | create, intent-compiler, skill-architect, validators, (evaluate, output-evaluator) | execution adapter, repair-controller | Optional |
| 2 Subjective writing | L2 | same + in-skill evals | eval-suite-designer, improve | **Yes** (accept) |
| 3 Complex app-dev | L3 | same + richer package | confusion-tester, execution adapter, repair-controller | **Yes** (first accept) |
| 4 False-positive improve | inherits | evaluate diagnosis only | **improve**, confusion-tester, repair-controller | **Yes** (trigger edits) |
| 5 Dangerous script | any | evaluate, static validators, output-evaluator (no exec) | script-security-scanner, execution adapter | **Yes** (waive only) |

## RFC amendments implied

1. Freeze L1/L2/L3 artifact budgets in `intent-compiler` contract (what may be emitted).  
2. State explicitly: **`evaluate` / `output-evaluator` never mutate Skill packages.**  
3. MVP create repair: capped retries on hard gates only.  
4. Scenario 4 is **out of MVP scope** unless `improve` is pulled forward.  
5. Dangerous-script **static** hard gate is MVP-critical (not Phase-4).  
6. Keep generated Skills portable; Claude-only wiring stays under `plugins/skill-lab/`.

## Overall

Approach D + Level routing validates scenarios **1–3 and 5** on the MVP surface. Scenario **4** validates the architecture only with deferred `improve` / `confusion-tester`; MVP correctly degrades to non-mutating evaluation rather than unsafe autonomous rewrite.
