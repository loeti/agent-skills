# agent-skills

Personal collection of agent skills. Each skill lives in `skills/<name>/SKILL.md`.

- Create new skills with `scripts/new-skill.sh <name>`, never by hand-copying.
- Run `scripts/validate.sh` after adding or changing a skill.
- Frontmatter `name` must match the directory name.
- Token-efficient by default: every line is loaded into the agent's context. Write only what the agent wouldn't know or would get wrong; no background, no repetition, commands over prose. Aim for well under 100 lines; move rarely needed detail into `references/`.
- Prefer metric units.
- Add new skills to the table in `README.md`.
- Installation and distribution is done with `skiller`, not from this repo.
