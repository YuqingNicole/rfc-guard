# RFC Guard — Claude Code Plugin

A Stop hook plugin that automatically detects RFC-level architecture changes and enforces engineering taste guidelines.

## What it does

Every time Claude finishes a response, RFC Guard runs two checks:

1. **Keyword Detection** (shell script) — scans `git diff` for patterns that indicate architecture-level changes (data sources, API contracts, AI orchestration, compliance boundaries, persistence, etc.)
2. **Engineering Taste Review** (AI agent) — uses a lightweight model to evaluate code changes against engineering principles from your project's `ENGINEERING_TASTE.md`

If either check fails, Claude's response is blocked with a clear explanation of what needs to be fixed.

## Installation

### Via settings.json

```json
{
  "enabledPlugins": {
    "rfc-guard@your-marketplace": true
  }
}
```

### Via GitHub source

```json
{
  "enabledPlugins": {
    "rfc-guard@your-marketplace": true
  },
  "extraKnownMarketplaces": {
    "your-marketplace": {
      "source": {
        "source": "github",
        "repo": "YuqingNicole/rfc-guard"
      }
    }
  }
}
```

## Configuration

### Custom keyword patterns

Set environment variables in your Claude Code settings:

```json
{
  "env": {
    "RFC_GUARD_EXTRA_PATTERNS": "my-service|my-api|custom-pattern"
  }
}
```

Or point to a patterns file:

```json
{
  "env": {
    "RFC_GUARD_PATTERNS_FILE": "/path/to/patterns.txt"
  }
}
```

### Custom RFC directory

```json
{
  "env": {
    "RFC_GUARD_RFC_DIR": "./docs/rfcs"
  }
}
```

### Engineering Taste file

The agent hook looks for your engineering taste document in this order:
1. `rfcs/ENGINEERING_TASTE.md`
2. `docs/ENGINEERING_TASTE.md`
3. `ENGINEERING_TASTE.md`

If not found, it falls back to universal engineering principles.

## Default detected patterns

The keyword layer scans for:

| Category | Patterns |
|----------|----------|
| Data sources | `polymarket`, `gamma-api`, `clob-api`, `kalshi`, `DataSource` |
| AI orchestration | `agent orchestrat`, `layer2`, `multi-agent` |
| Persistence | `CREATE/ALTER/DROP TABLE`, `schema.prisma` |
| Cross-platform | `cross-platform`, `EventMatch` |
| Compliance | `compliance`, `trust boundary`, `auth boundary` |
| Public API | `api/v*`, `/api/public`, `openapi`, `swagger` |

## How blocking works

- **No changes** → silent pass
- **Minor changes** (config, docs, tests) → silent pass
- **RFC-level keyword match** → blocks with matched lines + RFC list
- **Engineering taste violation** → blocks with specific principle violated

## License

MIT
