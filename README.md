# Project Spec Template

A minimal, domain-agnostic template for spec-driven development with LLM agents.

## What This Is

A structured approach to building anything:
1. **Interrogate** — Agent asks clarifying questions, you answer
2. **Spec** — Decisions are captured in structured documents
3. **Implement** — Specs become implementation guides

## Core Components

```
.claude/
├── CLAUDE.md           # Project conventions (agent reads first)
└── commands/
    ├── interrogate.md  # Deepen specs through Q&A
    ├── ingest.md       # Extract specs from rough notes
    └── human-docs.md   # Generate user documentation

spec/
├── MASTER.md           # Central index + status tracker
├── glossary.md         # Canonical term definitions
├── architecture/       # System-level specs
│   ├── overview.md
│   ├── mvp-scope.md
│   └── data-model.md
├── domains/            # Feature area specs
│   └── _TEMPLATE.md
└── implementation/     # Build specs (epics/stories)

docs/                   # Human-readable docs
```

## Quick Start

1. Clone this repo
2. Run `./init.sh` and follow prompts
3. Edit `spec/MASTER.md` to define your domains
4. Run `/interrogate spec/architecture/overview` to start

### Init Options

```bash
./init.sh                              # Interactive mode
./init.sh my-project                   # Create new GitHub repo
./init.sh git@github.com:you/repo.git  # Use existing repo
```

The init script will:
- Replace template placeholders with your project name
- Reset git history to a clean initial commit
- Create/configure the GitHub remote and push

## The Interrogation Loop

The `/interrogate` command drives spec development:

1. **Invoke**: `/interrogate spec/domains/my-feature`
2. **Agent loads context**: MASTER.md, glossary, target doc, related docs
3. **Agent asks 3-5 questions** with multiple choice options
4. **You answer**
5. **Agent updates**: Target spec, glossary, MASTER.md status
6. **Repeat** until no open questions remain

## Status Indicators

- 🔴 Not started — needs initial interrogation
- 🟡 In progress — has content, needs deepening  
- 🟢 Complete — no open questions remain
- 🔄 Needs revision — downstream decisions invalidated something

## Decision Block Format

All specs use this structure:

```markdown
### [Decision Area]

- **Decision**: What was decided
- **Rationale**: Why this choice
- **Implications**: What this affects
- **Alternatives considered**: What else was evaluated
```

## Customization

### Placeholders to Replace

- `{{PROJECT_NAME}}` — Your project's display name
- `{{PROJECT_DESCRIPTION}}` — One-line description
- `{{CORE_PRINCIPLE}}` — The north star for design decisions
- `{{DOMAIN_N}}` — Your domain areas (e.g., "Users", "Billing", "Events")
- `{{MVP_0_GOAL}}` — What MVP 0 proves
- `{{DATE}}` — Current date

### Adding Domains

1. Copy `spec/domains/_TEMPLATE.md` to `spec/domains/your-domain.md`
2. Add entry to MASTER.md domain table
3. Run `/interrogate spec/domains/your-domain`

### Adding Commands

Create `.claude/commands/your-command.md` with:
- Clear purpose statement
- Context loading instructions
- Output requirements
- Invocation syntax

## Philosophy

- **Specs are for agents** — Precise, complete, machine-readable
- **Docs are for humans** — Narrative, contextual, approachable
- **Decisions capture rationale** — Future you (or agents) will thank you
- **Glossary prevents drift** — One definition per term
- **Status tracking is honest** — 🔴 is fine; lying isn't
