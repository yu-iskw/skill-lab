---
name: implement-cursor-plugin
description: Package and distribute Cursor plugins with schema-safe manifests, rules, skills, MCP wiring, and release-ready validation.
---

# Implement Cursor Plugin

Implement Cursor plugin packaging: manifest authoring, rules creation, skill reuse, MCP wiring, and distribution to the Cursor marketplace.

## Workflow

1. Create `.cursor-plugin/plugin.json` with required `name` field (kebab-case) and optional `version`, `description`.
2. Add Cursor-specific `rules/` directory with `.mdc` files for persistent AI guidance.
3. Wire shared `skills/` and `.mcp.json` from the plugin root (reused across platforms).
4. Validate manifest with `integration_tests/validate-cursor-manifest.sh`.
5. Prepare for distribution via the Cursor marketplace or team channel.

## Manifest Schema

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief description of what this plugin does",
  "author": { "name": "your-name" },
  "license": "Apache-2.0",
  "repository": "https://github.com/owner/repo"
}
```

**Required**: `name` (kebab-case: `^[a-z0-9-]+$`)
**Optional**: `version`, `description`, `author`, `license`, `repository`

## Directory Layout

```text
plugins/<plugin-name>/
├── .cursor-plugin/
│   └── plugin.json          # Cursor manifest (required)
├── rules/
│   └── <name>.mdc           # Persistent AI guidance rules
├── skills/
│   └── <name>/SKILL.md      # Shared skills (also used by Claude Code, Codex)
├── hooks/
│   └── hooks.json           # Event-triggered automation (shared with Claude Code)
└── .mcp.json                # MCP server config (shared across platforms)
```

## Rules (.mdc files)

Rules provide persistent AI guidance injected into every Cursor session. Use them for:

- Coding standards and conventions
- Project-specific patterns to follow or avoid
- Context about the codebase architecture

**Frontmatter fields**:

```markdown
---
description: Brief description of what this rule enforces
globs:
  - "**/*.ts"
  - "src/**/*.py"
alwaysApply: false
---
```

- `globs`: File patterns where this rule activates
- `alwaysApply: true`: Rule always injected regardless of file context

## Distribution Channels

- **Official Marketplace**: Submit via cursor.com/marketplace/publish (manually reviewed)
- **Team Marketplace**: Available on Cursor Teams/Enterprise plans
- **Community**: Listed at cursor.directory
- **Local testing**: Install from `~/.cursor/plugins/local`

## Validation

Run before distribution:

```bash
bash integration_tests/validate-cursor-manifest.sh plugins/<plugin-name>
```

## Component Skills

- Claude Code hooks (also work in Cursor): `../implement-hooks/SKILL.md`
- Shared skills: `../implement-agent-skills/SKILL.md`
- MCP wiring: see `.mcp.json` in plugin root
- Full plugin packaging: `../implement-plugin/SKILL.md`

## Sources

- https://cursor.com/docs/plugins
- https://cursor.directory
