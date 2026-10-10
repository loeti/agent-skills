#!/usr/bin/env bash
# Check that every skill has a SKILL.md with valid name/description frontmatter.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
errors=0

fail() { echo "✗ $1: $2" >&2; errors=$((errors + 1)); }

for skill in "$repo"/skills/*/; do
  [[ -d "$skill" ]] || continue
  dir="$(basename "$skill")"
  file="$skill/SKILL.md"

  [[ -f "$file" ]] || { fail "$dir" "missing SKILL.md"; continue; }
  [[ "$(head -n 1 "$file")" == "---" ]] || { fail "$dir" "SKILL.md must start with '---' frontmatter"; continue; }

  frontmatter="$(awk 'NR==1 {next} /^---$/ {exit} {print}' "$file")"
  name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p')"
  description="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p')"
  # Block scalars (description: >- / |) continue on the following indented lines
  if [[ "$description" =~ ^[\>\|][-+]?$ ]]; then
    description="$(printf '%s\n' "$frontmatter" \
      | awk '/^description:/ {on=1; next} on && /^[[:space:]]/ {sub(/^[[:space:]]+/, ""); printf "%s ", $0; next} on {exit}')"
    description="${description% }"
  fi

  [[ "$name" == "$dir" ]] || fail "$dir" "frontmatter name '$name' does not match directory"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "$dir" "name must be lowercase-hyphenated"
  (( ${#name} <= 64 )) || fail "$dir" "name longer than 64 characters"
  [[ -n "$description" ]] || fail "$dir" "missing description"
  (( ${#description} <= 1024 )) || fail "$dir" "description longer than 1024 characters"

  (( errors == 0 )) && echo "✓ $dir"
done

exit $(( errors > 0 ))
