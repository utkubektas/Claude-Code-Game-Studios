# Systems Index: Specimen

> **Status**: Draft
> **Created**: 2026-04-01
> **Last Updated**: 2026-04-01
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Specimen is a mobile logic puzzle game built around a single core loop: examine a broken alien creature, deduce the fault in its biology, repair it, and press run. The game's systems split into two concerns — the **simulation heart** (biology rules, failure propagation, run execution) and the **player interface** (inspection, organ repair, journal, progression). The simulation must be deterministic and internally consistent above all else, as the entire player experience depends on "learnable rules." Every system is either directly required to deliver the 30-second loop or supports player knowledge accumulation and progression across sessions.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Organ Type Registry | Core | MVP | Designed | design/gdd/organ-type-registry.md | — |
| 2 | Creature Definition System | Core | MVP | Designed | design/gdd/creature-definition-system.md | — |
| 3 | Biology Rule Engine | Gameplay | MVP | Designed | design/gdd/biology-rule-engine.md | Organ Type Registry |
| 4 | Failure Cascade System | Gameplay | MVP | Designed | design/gdd/failure-cascade-system.md | Biology Rule Engine, Organ Type Registry |
| 5 | Puzzle Data System | Core | MVP | Designed | design/gdd/puzzle-data-system.md | Organ Type Registry, Creature Definition System |
| 6 | Touch Input Handler | Core | MVP | Designed | design/gdd/touch-input-handler.md | — |
| 7 | Specimen Viewer | Gameplay | MVP | Designed | design/gdd/specimen-viewer.md | Creature Definition System |
| 8 | Organ Repair Mechanic | Gameplay | MVP | Not Started | — | Touch Input Handler, Puzzle Data System, Specimen Viewer |
| 9 | Run Simulation Controller | Gameplay | MVP | Not Started | — | Biology Rule Engine, Failure Cascade System, Puzzle Data System |
| 10 | Run Sequence VFX | UI | MVP | Not Started | — | Run Simulation Controller |
| 11 | Puzzle HUD | UI | MVP | Not Started | — | Organ Repair Mechanic, Run Simulation Controller, Puzzle Data System |
| 12 | Screen Navigation | UI | MVP | Not Started | — | — |
| 13 | Save/Load System | Persistence | MVP | Not Started | — | — |
| 14 | Rule Discovery System (inferred) | Gameplay | V1 | Not Started | — | Biology Rule Engine, Run Simulation Controller |
| 15 | Discovery Journal | Progression | V1 | Not Started | — | Rule Discovery System, Save/Load System |
| 16 | Discovery Journal UI (inferred) | UI | V1 | Not Started | — | Discovery Journal |
| 17 | Level Progression System (inferred) | Progression | V1 | Not Started | — | Puzzle Data System, Save/Load System |
| 18 | Creature Type Unlock System (inferred) | Progression | V1 | Not Started | — | Level Progression System, Creature Definition System, Save/Load System |
| 19 | Audio System | Audio | V1 | Not Started | — | — |
| 20 | Ambient Narrative Fragments (inferred) | Narrative | Full Vision | Not Started | — | Level Progression System |
| 21 | Creature Preview System (inferred) | UI | Full Vision | Not Started | — | Creature Type Unlock System |

---

## Categories

| Category | Description | Systems in This Game |
|----------|-------------|----------------------|
| **Core** | Foundation data systems everything else depends on | Organ Type Registry, Creature Definition System, Puzzle Data System, Touch Input Handler |
| **Gameplay** | The systems that make the game fun | Biology Rule Engine, Failure Cascade System, Specimen Viewer, Organ Repair Mechanic, Run Simulation Controller, Rule Discovery System |
| **Progression** | How the player grows over sessions | Discovery Journal, Level Progression System, Creature Type Unlock System |
| **Persistence** | Save state and continuity | Save/Load System |
| **UI** | Player-facing interfaces | Run Sequence VFX, Puzzle HUD, Screen Navigation, Discovery Journal UI, Creature Preview System |
| **Audio** | Sound and music | Audio System |
| **Narrative** | Ambient story delivery | Ambient Narrative Fragments |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Systems |
|------|------------|------------------|---------|
| **MVP** | Required for the core loop to function | First playable (10 puzzles) | 1–13 (13 systems) |
| **V1** | Complete experience for first creature type + session retention | V1 / Alpha (30 puzzles, 3 creature types) | 14–19 (6 systems) |
| **Full Vision** | Polish, narrative, meta-layer retention | Store-ready release | 20–21 (2 systems) |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Organ Type Registry** — All biology-aware systems need to know what organs exist and their properties
2. **Creature Definition System** — All creature-rendering and puzzle systems need creature archetypes defined
3. **Touch Input Handler** — Organ Repair Mechanic cannot function without platform-appropriate touch input
4. **Save/Load System** — Progression and journal depend on persisted state
5. **Audio System** (V1) — Independent; can be wired in at any stage
6. **Screen Navigation** — Minimal screen flow is self-contained

### Core Layer (depends on foundation)

1. **Biology Rule Engine** — depends on: Organ Type Registry. Defines and executes all alien biology rules deterministically.
2. **Puzzle Data System** — depends on: Organ Type Registry, Creature Definition System. Stores puzzle layouts, available parts, and target states.
3. **Specimen Viewer** — depends on: Creature Definition System. Renders anatomy and malfunction indicators.
4. **Failure Cascade System** — depends on: Biology Rule Engine, Organ Type Registry. Determines how organ failures propagate.

### Feature Layer (depends on core)

1. **Organ Repair Mechanic** — depends on: Touch Input Handler, Puzzle Data System, Specimen Viewer.
2. **Run Simulation Controller** — depends on: Biology Rule Engine, Failure Cascade System, Puzzle Data System.
3. **Level Progression System** (V1) — depends on: Puzzle Data System, Save/Load System.
4. **Creature Type Unlock System** (V1) — depends on: Level Progression System, Creature Definition System, Save/Load System.

### Presentation Layer (depends on features)

1. **Run Sequence VFX** — depends on: Run Simulation Controller.
2. **Rule Discovery System** (V1) — depends on: Biology Rule Engine, Run Simulation Controller.
3. **Discovery Journal** (V1) — depends on: Rule Discovery System, Save/Load System.
4. **Puzzle HUD** — depends on: Organ Repair Mechanic, Run Simulation Controller, Puzzle Data System.
5. **Discovery Journal UI** (V1) — depends on: Discovery Journal.
6. **Ambient Narrative Fragments** (Full Vision) — depends on: Level Progression System.
7. **Creature Preview System** (Full Vision) — depends on: Creature Type Unlock System.

### Polish Layer

- No additional polish-layer systems beyond those listed in Full Vision tier.

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort | Notes |
|-------|--------|----------|-------|-------------|-------|
| 1 | Organ Type Registry | MVP | Foundation | S | Start here — everything depends on it |
| 2 | Creature Definition System | MVP | Foundation | S | Can be designed in parallel with #1 |
| 3 | **Biology Rule Engine** | MVP | Core | L | ⚠️ Highest risk — design carefully, prototype early |
| 4 | Failure Cascade System | MVP | Core | M | Design after Rule Engine is stable |
| 5 | Puzzle Data System | MVP | Core | M | Can begin alongside #3 |
| 6 | Touch Input Handler | MVP | Foundation | S | Can be designed in parallel; Godot Input Map |
| 7 | Specimen Viewer | MVP | Core | M | Design after Creature Definition |
| 8 | Organ Repair Mechanic | MVP | Feature | M | Design after Specimen Viewer + Touch Input |
| 9 | **Run Simulation Controller** | MVP | Feature | M | ⚠️ Central to the emotional moment — validate with prototype |
| 10 | Run Sequence VFX | MVP | Presentation | M | Design after Run Simulation is specced |
| 11 | Puzzle HUD | MVP | Presentation | S | Design after core interaction is stable |
| 12 | Screen Navigation | MVP | Presentation | S | Minimal for MVP |
| 13 | Save/Load System | MVP | Foundation | S | Implement last in MVP; design early |
| 14 | Rule Discovery System | V1 | Presentation | M | |
| 15 | Discovery Journal | V1 | Progression | M | |
| 16 | Discovery Journal UI | V1 | UI | S | |
| 17 | Level Progression System | V1 | Feature | S | |
| 18 | Creature Type Unlock System | V1 | Feature | S | |
| 19 | Audio System | V1 | Foundation | M | |
| 20 | Ambient Narrative Fragments | Full Vision | Narrative | M | |
| 21 | Creature Preview System | Full Vision | UI | S | |

*Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions*

---

## Circular Dependencies

None detected. The dependency graph is a clean DAG (directed acyclic graph).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **Biology Rule Engine** | Technical + Design | Must be deterministic across all edge cases; rules must be learnable by player through play alone — the entire game concept depends on this working | Design first, prototype early with `/prototype biology-rule-engine`, validate with 5-person blind playtest |
| **Run Simulation Controller** | Design | Orchestrates the core emotional moment — the "run button" must feel satisfying every time; poor execution undermines Pillar 3 | Prototype before full implementation; gather player reaction data during first playtest |
| **Organ Repair Mechanic** | Design + UX | Touch drag/drop for organ placement must feel precise on mobile; too fiddly = frustrating; too loose = no satisfaction | Test on physical device early; consider snap-to-grid; benchmark against The Room series for touch precision |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 21 |
| Design docs started | 0 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 7 / 13 |
| V1 systems designed | 0 / 6 |
| Full Vision systems designed | 0 / 2 |

---

## Next Steps

- [ ] Design MVP systems in order — start with `/design-system organ-type-registry`
- [ ] Prototype Biology Rule Engine early — `/prototype biology-rule-engine`
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when all MVP systems are designed
