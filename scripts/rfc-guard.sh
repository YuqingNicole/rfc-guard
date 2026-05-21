#!/usr/bin/env bash
# RFC Guard — detects RFC-level changes in git diff
# Exit 0 = pass, Exit 2 = block
set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"

# --- Configurable patterns ---
# Users can override by setting RFC_GUARD_PATTERNS_FILE to a newline-separated file of regex patterns
# Or by setting RFC_GUARD_EXTRA_PATTERNS as a pipe-separated string
DEFAULT_PATTERNS=(
  "polymarket"
  "gamma-api"
  "clob-api"
  "kalshi"
  "data.source"
  "DataSource"
  "APIContract"
  "agent.orchestrat"
  "AgentOrchestrat"
  "layer.?2"
  "multi.?agent"
  "CREATE TABLE"
  "ALTER TABLE"
  "DROP TABLE"
  "prisma.*model"
  "schema.prisma"
  "cross.?platform"
  "event.?match"
  "EventMatch"
  "compliance"
  "trust.?boundary"
  "auth.?boundar"
  "api/v[0-9]"
  "/api/public"
  "openapi"
  "swagger"
)

# Load custom patterns if file exists
if [ -n "${RFC_GUARD_PATTERNS_FILE:-}" ] && [ -f "$RFC_GUARD_PATTERNS_FILE" ]; then
  mapfile -t CUSTOM_PATTERNS < "$RFC_GUARD_PATTERNS_FILE"
  PATTERNS=("${CUSTOM_PATTERNS[@]}")
elif [ -n "${RFC_GUARD_EXTRA_PATTERNS:-}" ]; then
  PATTERNS=("${DEFAULT_PATTERNS[@]}")
  IFS='|' read -ra EXTRA <<< "$RFC_GUARD_EXTRA_PATTERNS"
  PATTERNS+=("${EXTRA[@]}")
else
  PATTERNS=("${DEFAULT_PATTERNS[@]}")
fi

# Build grep pattern
GREP_PATTERN=$(printf "|%s" "${PATTERNS[@]}")
GREP_PATTERN="${GREP_PATTERN:1}"

# Get changes
DIFF_OUTPUT=$(cd "$PROJECT_ROOT" && git diff --unified=0 2>/dev/null || true)
STAGED_OUTPUT=$(cd "$PROJECT_ROOT" && git diff --cached --unified=0 2>/dev/null || true)
COMBINED="$DIFF_OUTPUT
$STAGED_OUTPUT"

if [ -z "$COMBINED" ] || [ "$COMBINED" = $'\n' ]; then
  exit 0
fi

# Search for RFC-level patterns
MATCHES=$(echo "$COMBINED" | grep -iE "$GREP_PATTERN" | head -5 || true)

if [ -n "$MATCHES" ]; then
  echo "⚠️  RFC Guard: detected changes that may require an RFC update"
  echo ""
  echo "Matched content:"
  echo "$MATCHES" | sed 's/^/  /'
  echo ""
  echo "These types of changes need an RFC before implementation:"
  echo "  - Product scope, data sources, AI orchestration, compliance boundaries"
  echo "  - Cross-platform matching, API contracts, persistence, architecture"
  echo ""

  # List existing RFCs if directory exists
  RFC_DIR="${RFC_GUARD_RFC_DIR:-$PROJECT_ROOT/rfcs}"
  if [ -d "$RFC_DIR" ]; then
    echo "Existing RFCs:"
    find "$RFC_DIR" -name "RFC-*.md" -exec basename {} \; 2>/dev/null | sort | sed 's/^/  /'
  fi

  exit 2
fi

exit 0
