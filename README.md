# Skill Lab

Claude Code plugin for designing, evaluating, diagnosing, and improving Agent Skills.

Skill Lab is a thin workflow-orchestration plugin: reusable domain core as portable Agent Skills, independent reasoning via Claude Code subagents, and objective checks via deterministic scripts (`bash` + `jq`).

## End-to-end workflow

The plugin exposes two entry points. `/skill-lab:create` generates and may repair a Skill, while `/skill-lab:evaluate` inspects an existing Skill without modifying it. Both converge on deterministic validation, evidence-backed scoring, and best-valid-checkpoint selection.

```mermaid
flowchart TD
    user["User request"]
    create["/skill-lab:create"]
    evaluate["/skill-lab:evaluate"]

    user --> create
    user --> evaluate

    create --> collect["Collect request and constraints"]
    collect --> intent["Run intent-compiler"]
    intent --> route["Determine complexity level"]
    route --> safety{"Safe to continue?"}

    safety -->|"No"| stop["Stop or produce a documentation-only plan"]
    safety -->|"Yes"| architect["Run skill-architect"]

    architect --> createValidate["Run skill-lab-validate"]
    createValidate --> createValid{"Package valid?"}

    createValid -->|"No"| createSynthesize["Synthesize criteria from validation findings"]
    createValid -->|"Yes"| createEvaluator["Run output-evaluator"]

    createSynthesize --> createAggregate["Run skill-lab-eval aggregate"]
    createEvaluator --> createAggregate

    createAggregate --> repair{"Perform bounded repair?"}

    repair -->|"Yes"| repairStep["Perform one repair"]
    repairStep --> revalidate["Run skill-lab-validate again"]
    revalidate --> checkpoints["Build checkpoint records"]

    repair -->|"No"| checkpoints

    checkpoints --> compare["Run skill-lab-compare"]
    compare --> select["Select best valid checkpoint"]
    select --> createEvidence["Persist run evidence"]
    createEvidence --> createReport["Report created Skill and limitations"]

    evaluate --> resolve["Resolve directory containing SKILL.md"]
    resolve --> evaluateValidate["Run skill-lab-validate"]
    evaluateValidate --> evaluateValid{"Package valid?"}

    evaluateValid -->|"No"| evaluateSynthesize["Synthesize criteria from validation findings"]
    evaluateValid -->|"Yes"| evaluateEvaluator["Run output-evaluator"]

    evaluateSynthesize --> evaluateAggregate["Run skill-lab-eval aggregate"]
    evaluateEvaluator --> evaluateAggregate

    evaluateAggregate --> multiple{"Multiple checkpoints?"}

    multiple -->|"Yes"| evaluateCompare["Run skill-lab-compare"]
    multiple -->|"No"| evaluateEvidence["Persist scorecard and evidence"]

    evaluateCompare --> evaluateEvidence
    evaluateEvidence --> evaluateReport["Report evaluation results"]
    evaluateReport --> unchanged["Do not modify the target Skill"]
```

A failed hard gate cannot be offset by a high average score. The create workflow permits at most one bounded repair, and the evaluate workflow never modifies the target Skill.

## Repository layout

```text
.
├── plugins/
│   └── skill-lab/           # Product plugin
├── integration_tests/       # Shared plugin smoke tests
├── docs/                    # RFC and architecture notes
├── .claude-plugin/          # Claude marketplace (active)
├── .cursor-plugin/          # Cursor marketplace (empty until adapter)
├── .codex-plugin/           # Codex marketplace (empty until adapter)
└── Makefile
```

MVP installs via the **Claude** marketplace only. Cursor/Codex marketplace manifests are reserved with empty `plugins` until platform adapters ship.

## Quickstart

1. Install from the Claude marketplace (or load with `--plugin-dir plugins/skill-lab`).
2. Run `/skill-lab:create` with a short skill request, or `/skill-lab:evaluate path/to/skill`.
3. Local checks:

```bash
./plugins/skill-lab/tests/unit/test-cli.sh
./integration_tests/run.sh --manifest-only --verbose
```

## Plugin features (MVP)

| Surface              | Purpose                                                                     |
| -------------------- | --------------------------------------------------------------------------- |
| `create` skill       | Intent → minimal Skill → validate → evaluate → one repair → best checkpoint |
| `evaluate` skill     | Non-mutating evaluation with evidence                                       |
| `intent-compiler`    | Structured intent contract                                                  |
| `skill-architect`    | Portable package generation                                                 |
| `output-evaluator`   | Independent rubric assessment                                               |
| `skill-lab-validate` | Deterministic package + eval structure checks                               |
| `skill-lab-eval`     | Eval schema checks + score aggregation                                      |
| `skill-lab-compare`  | Best-valid-checkpoint selection                                             |

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) and [plugins/skill-lab/README.md](plugins/skill-lab/README.md).

Integration tests auto-discover plugins under `plugins/` that contain `.claude-plugin/plugin.json`.

```bash
make lint
make test-integration-docker
```

## License

Apache License 2.0. See [LICENSE](LICENSE).
