# Chopshop

Chopshop translates product vision documents into agent-friendly implementation plans through a three-stage pipeline.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/lavallee/chopshop/main/install.sh | bash
```

Or clone and install locally:

```bash
git clone https://github.com/lavallee/chopshop.git
cd chopshop && ./install.sh
```

This installs:
- Claude Code skills to `~/.claude/commands/chopshop/`
- Helper scripts to `~/.local/bin/`

To uninstall:
```bash
~/.chopshop/uninstall.sh
```

## Quick Start

```bash
# 1. Triage - refine requirements
/chopshop:triage VISION.md

# 2. Architect - design the system
/chopshop:architect {session-id}

# 3. Plan - create executable tasks
/chopshop:planner {session-id}

# 4. Bootstrap - transition to beads-driven development
/chopshop:bootstrap {session-id}
```

## The Pipeline

### Stage 1: Triage (`/chopshop/triage`)

**Purpose:** Ensure product clarity before technical work begins.

**Input:** Vision document, PRD, or project description

**Process:**
- Reviews input materials
- Interviews you about scope, depth, success criteria
- Identifies gaps, ambiguities, risks
- Challenges assumptions
- Positions unknowns as experiments

**Output:** `triage-output.md` with refined requirements (P0/P1/P2)

### Stage 2: Architect (`/chopshop/architect`)

**Purpose:** Translate requirements into technical design.

**Input:** Session ID from triage

**Process:**
- Reads triage output
- Asks about technical "mindset" (prototype → enterprise)
- Asks about scale expectations
- Designs architecture appropriate to context
- Documents risks and mitigations

**Output:** `architect-output.md` with tech stack, components, phases

### Stage 3: Planner (`/chopshop/planner`)

**Purpose:** Break architecture into executable tasks.

**Input:** Session ID from architect

**Process:**
- Reads both previous outputs
- Decomposes work into epics and tasks
- Sizes tasks for AI agent context windows
- Assigns model recommendations and labels
- Wires up parent and blocking dependencies

**Output:**
- `plan.jsonl` (beads-compatible, for import)
- `plan-output.md` (human-readable summary)

### Stage 4: Bootstrap (`/chopshop:bootstrap`)

**Purpose:** Transition from planning to execution.

**Input:** Session ID from planner

**Process:**
- Validates git state (requires clean working directory)
- Checks for required tools (`bd`, `jq`)
- Initializes beads with project prefix
- Imports plan.jsonl into beads
- Optionally sets up curb integration (PROMPT.md, AGENT.md)
- Creates atomic bootstrap commit

**Output:**
- `.beads/` directory (beads database)
- `PROMPT.md` (agent system prompt, if curb enabled)
- `AGENT.md` (build/run instructions, if curb enabled)

## Session Management

Each run creates a session with ID format: `{project}-{YYYYMMDD-HHMMSS}`

Artifacts stored in: `.chopshop/sessions/{session-id}/`

Sessions are gitignored by default (working data, not source).

## Beads Integration

Chopshop outputs tasks compatible with [Steve Yegge's Beads](https://github.com/steveyegge/beads) task management system.

### Loading Plans

The planner generates a `plan.jsonl` file with the complete beads schema. Use the loader script:

```bash
# Load the plan into beads
chopshop-load .chopshop/sessions/{session-id}/plan.jsonl

# Validate the loaded state
chopshop-validate

# Start working
bd ready
```

### Helper Scripts

Add chopshop's bin directory to your PATH:

```bash
export PATH="$PATH:/path/to/chopshop/bin"
```

| Script | Purpose |
|--------|---------|
| `chopshop-load` | Import plan.jsonl into beads with proper validation |
| `chopshop-validate` | Check beads state matches chopshop expectations |

### What Gets Loaded

Each task in the JSONL includes:
- **Parent relationship**: Links task to its epic
- **Blocking dependencies**: What must complete first
- **Labels**: phase, model, complexity, domain
- **Full description**: Context, implementation hints, acceptance criteria

### Install Beads

If not already installed:
```bash
brew tap steveyegge/beads && brew install beads
```

## Mindsets

The Architect asks about your "mindset" - this shapes technical decisions:

| Mindset | Speed vs Quality | Testing | Architecture |
|---------|-----------------|---------|--------------|
| **Prototype** | Speed first | Skip | Monolith, shortcuts OK |
| **MVP** | Balanced | Critical paths | Clean modules |
| **Production** | Quality first | Comprehensive | Scalable, maintainable |
| **Enterprise** | Maximum rigor | Full coverage | Security, compliance, HA |

## Task Granularity

The Planner asks about task sizing:

| Granularity | Duration | Best For |
|-------------|----------|----------|
| **Micro** | 15-30 min | AI agents (fits context window) |
| **Standard** | 1-2 hours | Humans or mixed workflows |
| **Macro** | Half-day+ | High-level milestones |

## Labels

Every task gets labels for cross-cutting categorization:

| Category | Labels | Purpose |
|----------|--------|---------|
| **Phase** | `phase-1`, `phase-2`, ... | Which implementation phase |
| **Model** | `model:opus-4.5`, `model:sonnet`, `model:haiku` | Recommended AI model |
| **Domain** | `setup`, `model`, `api`, `ui`, `logic`, `test`, `docs` | What kind of work |
| **Complexity** | `complexity:high`, `complexity:medium`, `complexity:low` | How hard is this |
| **Risk** | `risk:high`, `risk:medium`, `experiment` | What could go wrong |
| **Special** | `checkpoint`, `blocking`, `quick-win`, `tech-debt` | Notable characteristics |
| **Slice** | `slice:auth`, `slice:dashboard`, etc. | Vertical slice grouping |

Use labels to filter work:
```bash
bd ready --label phase-1           # Phase 1 tasks ready to start
bd list --label model:haiku        # Simple tasks for haiku
bd list --label complexity:high    # Complex tasks
```

## Model Recommendations

Each task includes a recommended model based on complexity:

| Model | Use For | Examples |
|-------|---------|----------|
| **opus-4.5** | Complex, novel, security-sensitive | Architectural decisions, novel algorithms, auth flows |
| **sonnet** | Standard implementation | Features with clear specs, API integrations, CRUD with logic |
| **haiku** | Boilerplate, repetitive | Migrations, simple tests, config, docs |

The plan output includes a model distribution summary so you can estimate costs and review if the complexity assessment seems right.

## Validation Checkpoints

The Planner organizes work into **vertical slices** that deliver testable value, not just technical layers.

**Checkpoints** are suggested pause points where:
- A meaningful capability is complete and demonstrable
- User testing/feedback would be valuable before continuing
- Assumptions from triage can be validated
- The product could ship (even if minimal)

Each checkpoint task summarizes what's ready, what to test, and what questions to answer before proceeding.

You can skip checkpoints if you're confident, or request more frequent ones for tighter feedback loops.

## Tips

- **Start with Triage** even if you have a clear vision - it surfaces hidden assumptions
- **Choose the right Mindset** - over-engineering a prototype wastes time; under-engineering production causes pain
- **Use Micro granularity** if AI agents will execute the tasks
- **Review each stage** before proceeding - it's cheaper to fix the plan than the code
