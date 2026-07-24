# Skill Lab

Claude Code plugin for designing, evaluating, and improving Agent Skills.

## Install

From this repository marketplace:

```bash
claude plugin marketplace add yu-iskw/skill-lab
claude plugin install skill-lab@skill-lab
```

Or load locally:

```bash
claude --plugin-dir /path/to/skill-lab/plugins/skill-lab
```

## Commands (workflow skills)

- `/skill-lab:create` — compile intent, generate a minimal Skill, validate, evaluate, one repair, select best valid checkpoint
- `/skill-lab:evaluate` — evaluate an existing Skill without modifying it

## Subagents

- `intent-compiler` — structured intent contract (read-only)
- `skill-architect` — minimal portable package generation (scoped write)
- `output-evaluator` — independent criterion assessment (read/execute only)

## Deterministic tooling

Requires `bash` and `jq`.

```bash
./bin/skill-lab-validate --json path/to/skill
./bin/skill-lab-eval --validate-only path/to/skill
./bin/skill-lab-eval --aggregate criteria.json --out scorecard.json
./bin/skill-lab-compare checkpoints.json
```

MVP eval suites are structure-validated only (assertion types are not executed). Aggregate criteria use severity `hard|quality|info` and checkpoints use boolean `hard_gates_passed`.

## Layout

```text
plugins/skill-lab/
├── .claude-plugin/plugin.json
├── skills/{create,evaluate}/
├── agents/
├── bin/
├── lib/
├── schemas/
├── templates/
└── tests/fixtures/
```

## MVP scope

Included: create, evaluate, three subagents, package validation, eval schemas, one bounded repair, best-valid-checkpoint selection, three fixtures.

Deferred: Codex adapter, hooks behavior, hosted registry, autonomous publish/deploy, improve/diagnose/extract workflows.
