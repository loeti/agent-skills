# agent-skills

My personal collection of [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code (and other agents that understand the `SKILL.md` format).

## Layout

```
skills/<skill-name>/      one directory per skill
  SKILL.md                required – frontmatter (name, description) + instructions
  references/             optional – docs loaded on demand
  scripts/                optional – helper scripts executed by the agent
  assets/                 optional – templates, files used in output
template/                 starting point for new skills (SKILL.md.template)
scripts/
  new-skill.sh            create a skill from the template
  validate.sh             check frontmatter of all skills
```

## Usage

```sh
scripts/new-skill.sh my-skill     # scaffold skills/my-skill/
scripts/validate.sh               # lint all skills
```

Installing and grouping is done with [skiller](../skiller) (see `skills/skiller`).

## Skills

| Skill | Purpose |
|---|---|
| [skiller](skills/skiller) | Find, install, group and apply agent skills with the `skiller` CLI |
| [proton-pass-cli](skills/proton-pass-cli) | Use Proton Pass secrets as an agent via `pass-cli` without exposing them |
| [swiftui-to-compose-migration-planner](skills/swiftui-to-compose-migration-planner) | Plan the port of a SwiftUI feature to Android/Jetpack Compose, with a ticket-ready task breakdown |

## Conventions

- Directory name == `name` in the frontmatter (lowercase, hyphens, ≤ 64 chars).
- `description` says *what* the skill does and *when* to use it (≤ 1024 chars) – it is the only thing the agent sees before loading the skill.
- Token-efficient by default: only what the agent would otherwise not know or get wrong; commands over prose; well under 100 lines. Rarely needed detail goes into `references/`.
- Prefer metric units in examples and outputs.

## License

[MIT](LICENSE)
