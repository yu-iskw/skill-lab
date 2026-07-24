---
name: implement-codex-plugin
description: Package and distribute Codex plugins with schema-safe manifests, skills, app config, marketplace assets, and release-ready validation.
---

# Implement Codex Plugin

Implement Codex plugin packaging: manifest authoring, skill reuse, app integrations, marketplace assets, and distribution to the Codex plugin directory.

## Workflow

1. Create `.codex-plugin/plugin.json` with required `name`, `version`, `description` fields.
2. Wire shared `skills/` directory from plugin root (reused across platforms).
3. Optionally add `.app.json` for third-party app integrations.
4. Add `assets/` with marketplace visuals (icon, screenshots).
5. Validate manifest with `integration_tests/validate-codex-manifest.sh`.
6. Prepare for distribution via Codex plugin directory.

## Manifest Schema

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief description of what this plugin does",
  "author": { "name": "your-name" },
  "license": "Apache-2.0",
  "repository": "https://github.com/owner/repo",
  "skills": "./skills/"
}
```

**Required**: `name` (kebab-case), `version`, `description`
**Optional**: `author`, `license`, `repository`, `skills` (path to skills directory)

## Directory Layout

```text
plugins/<plugin-name>/
├── .codex-plugin/
│   └── plugin.json          # Codex manifest (required)
├── skills/
│   └── <name>/SKILL.md      # Shared skills (also used by Claude Code, Cursor)
├── .mcp.json                # MCP server config (shared across platforms)
├── .app.json                # Third-party app integrations (Codex-specific)
└── assets/
    ├── icon.svg             # Plugin icon (64x64 recommended)
    └── screenshot.png       # Marketplace screenshot
```

## Skills (SKILL.md)

Codex skills follow the same `SKILL.md` format as Claude Code skills. They live in the shared `skills/` directory and are automatically picked up by all platforms that support them.

Frontmatter:

```markdown
---
name: skill-name
description: What this skill does
---
```

## App Integrations (.app.json)

Connect the plugin to third-party services:

```json
{
  "integrations": [
    {
      "name": "github",
      "type": "oauth",
      "scopes": ["repo", "read:user"]
    }
  ]
}
```

## Marketplace Assets

Place in `assets/`:

- `icon.svg` or `icon.png` — Plugin icon (64×64 recommended)
- `screenshot-*.png` — Up to 3 screenshots for the marketplace listing
- `banner.png` — Optional banner image

## Distribution

- **Plugin directory**: Submit via the Codex developer portal (self-serve publishing coming soon)
- **Local distribution**: Reference via marketplace JSON in a repository or personal directory

## Validation

Run before distribution:

```bash
bash integration_tests/validate-codex-manifest.sh plugins/<plugin-name>
```

## Component Skills

- Shared skills: `../implement-agent-skills/SKILL.md`
- MCP wiring: see `.mcp.json` in plugin root
- Full plugin packaging: `../implement-plugin/SKILL.md`

## Sources

- https://developers.openai.com/codex/plugins/build
