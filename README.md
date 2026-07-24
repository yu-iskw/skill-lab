# Skill Lab

Claude Code plugin for designing, evaluating, diagnosing, and improving Agent Skills.

Skill Lab is a thin workflow-orchestration plugin: reusable domain core as portable Agent Skills, independent reasoning via Claude Code subagents, and objective checks via deterministic scripts (`bash` + `jq`).

## End-to-end workflow

The primary lifecycle starts by creating a new Skill or updating an existing Skill. The resulting Skill is then validated and evaluated. When evidence identifies a correctable problem, the create workflow may perform one bounded update before selecting the best valid checkpoint. `/skill-lab:evaluate` can also evaluate an existing Skill independently without modifying it.

```mermaid
flowchart TD
    request["User request"]
    operation{"Create or update a Skill?"}
    create["Create a new Skill"]
    update["Update an existing Skill"]
    collect["Collect intent, constraints, and acceptance criteria"]
    compile["Run intent-compiler"]
    safety{"Safe to continue?"}
    stop["Stop or produce a documentation-only plan"]
    architect["Run skill-architect"]
    skill["Created or updated Skill package"]
    validate["Run skill-lab-validate"]
    valid{"Package hard gates pass?"}
    findings["Record validation findings"]
    evaluate["Run output-evaluator"]
    aggregate["Run skill-lab-eval aggregate"]
    acceptable{"Meets acceptance criteria?"}
    repair{"Bounded update available?"}
    revise["Apply one bounded Skill update"]
    checkpoint["Build checkpoint metadata"]
    compare["Run skill-lab-compare"]
    select["Select the best valid checkpoint"]
    evidence["Persist scorecard and run evidence"]
    report["Report the Skill, score, assumptions, and limitations"]
    standalone["/skill-lab:evaluate existing Skill"]

    request --> operation
    operation -->|"Create"| create
    operation -->|"Update"| update
    create --> collect
    update --> collect
    collect --> compile
    compile --> safety
    safety -->|"No"| stop
    safety -->|"Yes"| architect
    architect --> skill
    skill --> validate
    validate --> valid
    valid -->|"No"| findings
    valid -->|"Yes"| evaluate
    findings --> repair
    evaluate --> aggregate
    aggregate --> acceptable
    acceptable -->|"Yes"| checkpoint
    acceptable -->|"No"| repair
    repair -->|"Yes"| revise
    repair -->|"No"| checkpoint
    revise --> skill
    checkpoint --> compare
    compare --> select
    select --> evidence
    evidence --> report
    stop --> report
    standalone --> validate
```

Evaluation follows creation or update in the primary workflow. A failed hard gate cannot be offset by a high average score, only one bounded update is permitted during creation, and standalone evaluation never modifies the target Skill.

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