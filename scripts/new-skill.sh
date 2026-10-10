#!/usr/bin/env bash
# Create a new skill from the template: scripts/new-skill.sh <skill-name>
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
name="${1:-}"

if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "usage: $0 <skill-name>   (lowercase, digits, hyphens)" >&2
  exit 1
fi

target="$repo/skills/$name"
if [[ -e "$target" ]]; then
  echo "error: $target already exists" >&2
  exit 1
fi

cp -R "$repo/template" "$target"
sed -i '' "s/^name: skill-name$/name: $name/" "$target/SKILL.md"
echo "created $target"
