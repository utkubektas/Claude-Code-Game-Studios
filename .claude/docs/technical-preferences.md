# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical systems only)
- **Rendering**: Compatibility renderer (mobile-optimized for Android/iOS targets)
- **Physics**: Jolt (Godot 4.6 default)

## Naming Conventions

- **Classes**: PascalCase — e.g., `OrganRepairSystem`
- **Variables/Functions**: snake_case — e.g., `move_speed`, `repair_organ()`
- **Signals**: snake_case past tense — e.g., `organ_repaired`, `simulation_failed`
- **Files**: snake_case matching class — e.g., `organ_repair_system.gd`
- **Scenes**: PascalCase matching root node — e.g., `OrganRepairSystem.tscn`
- **Constants**: UPPER_SNAKE_CASE — e.g., `MAX_ORGANS`, `RUN_DURATION`

## Performance Budgets

- **Target Framerate**: 60 fps (mobile minimum: 30 fps)
- **Frame Budget**: 16.6ms (33ms at 30fps floor)
- **Draw Calls**: [TO BE CONFIGURED — set after first profiling pass]
- **Memory Ceiling**: [TO BE CONFIGURED — set after first profiling pass]

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Simulation determinism (same input → same output always), organ rule validation, puzzle solution uniqueness

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- No hardcoded gameplay values — all tuning knobs must be exported variables or data files
- No singletons for gameplay state — use dependency injection or explicit passing

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- GUT (Godot Unit Testing) — testing framework

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
