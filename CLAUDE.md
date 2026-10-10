# agent-skills

Personal collection of agent skills. Each skill lives in `skills/<name>/SKILL.md`.

- Create new skills with `scripts/new-skill.sh <name>`, never by hand-copying.
- Run `scripts/validate.sh` after adding or changing a skill.
- Frontmatter `name` must match the directory name.
- Keep `SKILL.md` concise; put long material into `references/` and reference it explicitly.
- Prefer metric units.
- Add new skills to the table in `README.md`.
- Installation and distribution is done with `skiller`, not from this repo.
