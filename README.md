# Skill Lab

Claude Code plugin for designing, evaluating, diagnosing, and improving Agent Skills.

Skill Lab is a thin workflow-orchestration plugin: reusable domain core as portable Agent Skills, independent reasoning via Claude Code subagents, and objective checks via deterministic scripts (`bash` + `jq`).

## End-to-end workflow

The plugin exposes two entry points. `/skill-lab:create` generates and may repair a Skill, while `/skill-lab:evaluate` inspects an existing Skill without modifying it. Both converge on deterministic validation, evidence-backed scoring, and best-valid-checkpoint selection.

```mermaid
flowchart TD
    U[User request] --> R{Workflow}

    R -->|Create a Skill| C0["/skill-lab:create"]
    R -->|Evaluate an existing Skill| E0["/skill-lab:evaluate"]

    subgraph CREATE[Create workflow]
        C0 --> IC[Intent compiler subagent]
        IC --> CT[Structured intent contract and assumptions]
        CT --> CR{Complexity and safety routing}
        CR -->|Unsafe executable action| STOP[Documentation-only plan or stop]
        CR -->|Level 1, 2, or 3| SA[Skill architect subagent]
        SA --> PKG[Minimal portable Skill package]
    end

    subgraph EVALUATE[Evaluation workflow]
        E0 --> TARGET[Resolve existing Skill package]
    end

    PKG --> V[Deterministic package validation]
    TARGET --> V
    V --> HG{Hard gates pass?}

    HG -->|No| SYN[Synthesize criteria from validator findings]
    HG -->|Yes| ES{Create complexity level}
    ES -->|Level 1| L1[Lightweight evidence review]
    ES -->|Level 2 or 3| OE[Isolated output-evaluator subagent]
    ES -->|Existing Skill| OE

    SYN --> AGG[Aggregate criteria into scorecard]
    L1 --> AGG
    OE --> AGG

    AGG --> MODE{Create workflow?}
    MODE -->|Yes, repair needed and unused| REP[One bounded repair]
    REP --> V
    MODE -->|No repair or evaluate-only| CP[Build checkpoint metadata]

    CP --> CMP[Select best valid checkpoint]
    CMP --> EV[Persist run evidence under .skill-lab/runs]
    EV --> REPORT[Report score, assumptions, limitations, and best checkpoint]

    STOP --> REPORT

    classDef agent stroke-width:2px;
    classDef deterministic stroke-dasharray:5 3;
    class IC,SA,OE agent;
    class V,AGG,CMP deterministic;
```

Solid bordered nodes represent LLM-driven skills or subagents; dashed borders represent deterministic CLI checks. A failed hard gate cannot be offset by a high average score, and the evaluate workflow never modifies the target Skill.

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
