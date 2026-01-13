# Chop Shop

Chop Shop is a Claude Code skill pack plus helper scripts that take a rough product idea and turn it into a beads-compatible execution plan. The system runs through three guided agents—**Triage**, **Architect**, and **Planner**—to pressure-test the product vision, produce a pragmatic technical design, and emit ready-to-run tasks for AI coding agents or humans.

## How It Works

1. **/chopshop:triage** – Reviews your vision document, interviews you about scope, success criteria, and constraints, and produces an approved triage report.
2. **/chopshop:architect** – Consumes the triage output, captures mindset/scale/stack preferences, and writes a detailed technical plan with phases, risks, and data models.
3. **/chopshop:planner** – Breaks the architecture into epics and micro-sized tasks, labels them with model + complexity metadata, and exports both `plan.jsonl` (for beads) and a human-readable plan summary.
4. **/chopshop:bootstrap** – Transitions the project from planning to execution: validates git state, initializes beads, imports the plan, and optionally sets up curb integration for autonomous development.

Every run creates a timestamped session inside `.chopshop/sessions/{project}-{YYYYMMDD-HHMMSS}` with `triage-output.md`, `architect-output.md`, and `plan-*` artifacts. Sessions are gitignored because they are working files rather than source.

## Installation

The installer pulls this repo, symlinks helper scripts into `~/.local/bin`, and links the Claude commands into `~/.claude/commands/chopshop`.

```bash
curl -fsSL https://raw.githubusercontent.com/lavallee/chopshop/main/install.sh | bash
# or
 git clone https://github.com/lavallee/chopshop.git
 cd chopshop && ./install.sh
```

Environment variables:
- `CHOPSHOP_DIR` – install location (default: `~/.chopshop`)
- `CHOPSHOP_REPO` – repo URL if you are testing a fork

Prerequisites: `git` (required), `jq` (used by `chopshop-load`), Claude Code (desktop/Web) with custom commands enabled, and optionally the [Beads CLI](https://github.com/steveyegge/beads) (`brew tap steveyegge/beads && brew install beads`).

To uninstall everything that was installed under `~/.chopshop`:

```bash
~/.chopshop/uninstall.sh
```

## Quick Start

```bash
# 1. Clarify the product idea from a VISION.md or provided doc
/chopshop:triage VISION.md

# 2. Turn the approved requirements into a technical architecture
/chopshop:architect {session-id}

# 3. Generate beads-ready epics + tasks
/chopshop:planner {session-id}

# 4. Bootstrap beads and optionally set up curb for autonomous execution
/chopshop:bootstrap {session-id}

# 5. Start working
bd ready                    # See available tasks
curb run --once             # Or run autonomously with curb
```

### Manual Alternative (skip bootstrap)

If you prefer to set up beads manually:

```bash
chopshop-load .chopshop/sessions/{session-id}/plan.jsonl
chopshop-validate
bd ready
```

### Sessions & Artifacts

- `triage-output.md` – problem statement, prioritized requirements, risks, experiments
- `architect-output.md` – system overview, stack choices, components, phases, mitigations
- `plan-output.md` – epic/task tables, dependency graph, checkpoint notes, model distribution
- `plan.jsonl` – beads import file with IDs, labels, parent/blocks dependencies, and structured markdown task descriptions (context, hints, steps, acceptance criteria, files to touch)

## Helper Scripts

| Script | Purpose |
| ------ | ------- |
| `bin/chopshop-load` | Validates `plan.jsonl`, initializes beads if needed, runs `bd import`, syncs, and shows a quick summary of ready tasks. Requires `bd` and `jq`. |
| `bin/chopshop-validate` | Exports current beads state and ensures every task has a parent epic, model/complexity/phase labels, markdown sections, and reports model distribution. |

Add `~/.local/bin` to your `PATH` in `~/.bashrc` / `~/.zshrc` so the helper commands are discoverable.

## Planning Conventions

- **Mindsets:** Prototype → MVP → Production → Enterprise; they influence how aggressive the architecture should be about rigor, testing, and infrastructure.
- **Granularity:** The planner optimizes for micro (15–30 min) tasks so AI agents stay within one context window; standard or macro sizing is optional.
- **Labels:** Every task carries `phase-*`, `model:*`, and `complexity:*` labels plus optional domain/risk/checkpoint labels for filtering (e.g., `bd ready --label model:haiku`).
- **Vertical slices:** Implementation phases are structured as epics that deliver testable user value, not just horizontal layers.
- **Checkpoints:** Planner creates `checkpoint` tasks whenever it's prudent to pause for validation or user testing.

For deeper context on the execution philosophy, read `CLAUDE.md` for in-depth usage guidance and `beads-best-practices.txt` for Steve Yegge’s notes about building atop Beads.

## Repository Guide

```
.
├── .claude/commands/chopshop/   # Command prompts for triage, architect, planner, bootstrap agents
├── bin/                         # chopshop-load / chopshop-validate helper scripts
├── install.sh / uninstall.sh    # Installer utilities (symlink skills + scripts)
├── VISION.md                    # High-level description of what Chopshop is and why
├── CLAUDE.md                    # Extended documentation shared with Claude
└── beads-best-practices.txt     # Reference article on Beads workflows
```

## Bootstrap & Curb Integration

The `/chopshop:bootstrap` skill bridges planning and execution. It:

1. **Validates prerequisites**: Checks for clean git state, required tools (`bd`, `jq`)
2. **Initializes beads**: Runs `bd init` with your chosen prefix
3. **Imports the plan**: Loads `plan.jsonl` into beads
4. **Sets up curb** (optional): Creates `PROMPT.md` and `AGENT.md` for autonomous execution

### Why Clean Git State Matters

Bootstrap strongly recommends a clean working directory because:
- The plan import becomes a single atomic commit
- Agent work creates isolated, reviewable commits
- Rollback is straightforward if something goes wrong
- `git bisect` works properly for debugging

### Curb Integration Files

When you opt for curb integration, bootstrap creates:

| File | Purpose |
|------|---------|
| `PROMPT.md` | System prompt for the agent, derived from triage/architect context |
| `AGENT.md` | Build/run instructions (how to test, lint, run the project) |
| `.curb.json` | Optional curb configuration overrides |

These files let `curb run` work immediately after bootstrap.

## Workflow Tips

- Start from a coherent `VISION.md`, but let Triage challenge assumptions—unknowns are framed as experiments, not blockers.
- Answer the Architect’s mindset/scale/stack questions honestly; this steers everything from persistence choices to logging rigor.
- Choose **micro** granularity if AI agents will implement the tasks; it keeps each bead within one context window.
- After importing into Beads, regularly run `chopshop-validate` to ensure manual edits still meet Chopshop’s requirements.
- Keep your `.chopshop/sessions` history—they document past decisions and can seed future iterations.
