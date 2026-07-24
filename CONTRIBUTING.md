# Contributing

Thanks for contributing to Skill Lab.

## Development Prerequisites

- `git`
- `docker`
- `jq`
- `trunk` CLI
- Optional: `claude` CLI (`npm install -g @anthropic-ai/claude-code`) for full plugin loading checks

## Setup

1. Fork or branch from this repository.
2. Install Trunk: `curl https://get.trunk.io -fsSL | bash`
3. Verify tools: `trunk --version`, `docker --version`, `jq --version`

## Local Checks

Run these before opening a pull request:

1. `./plugins/skill-lab/tests/unit/test-cli.sh`
2. `make format`
3. `make lint`
4. `./integration_tests/run.sh --manifest-only --verbose`
5. `make test-integration-docker` when Docker is available

## Plugin layout

Product plugin: `plugins/skill-lab/`

- Skills under `skills/<skill-name>/SKILL.md`
- Agents under `agents/*.md`
- Deterministic CLIs under `bin/` (bash + jq)
- Schemas under `schemas/`
- Fixtures under `tests/fixtures/`

## Pull Request Guidelines

1. Keep changes scoped and focused.
2. Update docs when behavior or structure changes.
3. Include test evidence (commands and outcomes).
4. Ensure CI passes.

## License

Contributions are under Apache License 2.0.
