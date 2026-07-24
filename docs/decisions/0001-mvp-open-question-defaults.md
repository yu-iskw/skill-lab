# ADR 0001: MVP Open-Question Defaults for Skill Lab

- **Status:** Accepted
- **Date:** 2026-07-24
- **Deciders:** Skill Lab RFC authors
- **Related:** [RFC](../RFC.md), [MVP plan](../superpowers/plans/2026-07-24-skill-lab-mvp.md)

## Context

Skill Lab is adopted as a hybrid Claude Code plugin (workflow skills, subagents, and deterministic scripts) living in this monorepo under `plugins/`, not as a greenfield flat repository. `plugins/hello-world` already exists as the sample plugin. CI uses Node 20, Docker, and Bash smoke tests.

The RFC left ten open questions that must be pinned before implementation so CLI shape, package layout, eval placement, sandbox policy, persistence, and schema evolution do not drift.

## Decision

### Monorepo placement

| Concern | MVP default |
| --- | --- |
| Product plugin | `plugins/skill-lab/` |
| Shared contracts / schemas | `docs/contracts/schemas/` (**source of truth**). Plugin MUST symlink or CI-diff-gate `plugins/skill-lab/schemas/` — no unsynced copies. |
| CLI package | `plugins/skill-lab/cli/` (stay under the plugin; do not invent a top-level `packages/` tree in MVP) |
| Sample template | Keep `plugins/hello-world/` unless a later ADR removes it |

Skill Lab product self-evals live under `plugins/skill-lab/evals/`.

### Agent tool posture (MVP)

| Agent | Tools | MUST NOT |
| --- | --- | --- |
| `intent-compiler` | Read-oriented | Write Skill packages |
| `skill-architect` | Scoped write to target Skill path | Embed `.claude-plugin/`; self-grade as pass |
| `output-evaluator` | Read + run `skill-lab-validate` | Write/Edit Skills or expected evals; **execute Skill `scripts/`** |

Follow `.claude/skills/implement-sub-agents/` templates for frontmatter shape.

### 1. Implementation language

- **CLI and core logic:** TypeScript on **Node 20+**.
- **Bash:** smoke wrappers and thin CI/integration shells only.
- **Not chosen:** Python-first CLI or dual-language core for MVP.

### 2. Eval location

**Default:** curated evals are **first-class artifacts inside the generated Skill package** at `evals/` under the Skill directory (see RFC §7 / §13).

**Skill Lab product self-tests** live at `plugins/skill-lab/evals/`.

Sibling `evals/<skill-name>/` outside the Skill package is **not** the MVP default for generated portable Skills.

### 3. Run metadata (tokens / cost)

- Capture metadata via a **hook + process envelope** when hooks are added; MVP may use a process envelope only.
- Token and cost fields are present in schemas but remain **`null` until the host exposes them**.
- **Never invent or estimate** token/cost numbers.

### 4. Sandbox and package validation

- **Untrusted script execution** (later): Docker, **non-root**, **`--network=none`**.
- **MVP package validator:** schema and **static checks only**. It does **not** execute untrusted skill scripts by default.
- Dangerous-script **static** hard gates are **MVP-critical** (see scenario validation).
- Execution adapters are **post-MVP**.

### 5. Install surface (v1)

- **Project-local** install and explicit **`--plugin-dir`** only.
- No global marketplace UX requirement for Skill Lab’s own workflows in v1 (marketplace entry for this monorepo may still exist for CI install tests).

### 6. Neighbor skill discovery

- Discover **sibling Skills under the same `skills/` root**.
- Optional **`--also`** for additional paths.
- **Do not** crawl `~/.claude` in MVP.

### 7. Persistence under `.skill-lab/runs/`

Persist: run manifest (including `selected_checkpoint`), scores, hashes, timings, tool-use summaries, short rationales, criterion evidence.

**Defaults:**

- **MVP:** gitignore the **entire** `.skill-lab/` directory (root `.gitignore`).
- No secrets in persisted run records.
- Generated Skill packages and curated evals SHOULD be version-controlled.

### 8. Codex parity

- **MVP:** Claude Code plugin path only; **no Codex eval parity**.
- **Phase 4:** best-effort shared `SKILL.md` packaging; not identical eval runners.

### 9. Evaluator (judge) model

- Evaluator model is **configurable**.
- Pin a **default in project/plugin config**.
- Changing the judge model or major judge prompt/version **invalidates cross-run score comparisons**; runs must record judge identity.

### 10. Schema evolution

- **Additive** changes: anytime.
- **Breaking** changes: only with ≥20 fixtures across ≥3 fixture Skills **and** a `schema_version` bump.

## Consequences

### Positive

- Aligns with existing Node/Docker CI.
- In-skill `evals/` travel with the Skill (RFC §7 / §13).
- Static-only MVP validation reduces supply-chain risk.
- Narrow install and discovery keep the trust boundary deterministic.

### Negative / follow-ups

- Authors used to sibling-only eval layouts must place curated suites under the Skill’s `evals/`.
- No untrusted script execution in MVP validate.
- No Codex eval parity until Phase 4.
- Schema sync is enforced via symlink or CI identity check (see Monorepo placement).

### Non-goals (MVP)

Python CLI, `~/.claude` crawl, invented cost metrics, executing untrusted scripts during validate, Codex eval parity, removing `plugins/hello-world` without a separate decision.
