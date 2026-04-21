class_name GameFlowOrchestrator
extends Node

## Single wiring point for all Sprint 03 visual systems.
## Owns no game state — purely routes signals between systems.
##
## Usage:
##   1. setup() — inject all six systems.
##   2. wire() — call once after setup() and after all systems are in the scene
##               tree. Calling wire() a second time creates duplicate connections.
##
## Pre-conditions: every injected system must already have had its own setup()
## called before wire() is invoked.

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _rsc: RunSimulationController
var _viewer: SpecimenViewer
var _hud: PuzzleHUD
var _vfx: RunSequenceVFX
var _nav: ScreenNavigation
var _mechanic: OrganRepairMechanic

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Injects all system dependencies. Must be called before wire().
func setup(
	p_rsc: RunSimulationController,
	p_viewer: SpecimenViewer,
	p_hud: PuzzleHUD,
	p_vfx: RunSequenceVFX,
	p_nav: ScreenNavigation,
	p_mechanic: OrganRepairMechanic
) -> void:
	assert(p_rsc      != null, "GameFlowOrchestrator.setup: p_rsc must not be null")
	assert(p_viewer   != null, "GameFlowOrchestrator.setup: p_viewer must not be null")
	assert(p_hud      != null, "GameFlowOrchestrator.setup: p_hud must not be null")
	assert(p_vfx      != null, "GameFlowOrchestrator.setup: p_vfx must not be null")
	assert(p_nav      != null, "GameFlowOrchestrator.setup: p_nav must not be null")
	assert(p_mechanic != null, "GameFlowOrchestrator.setup: p_mechanic must not be null")
	_rsc      = p_rsc
	_viewer   = p_viewer
	_hud      = p_hud
	_vfx      = p_vfx
	_nav      = p_nav
	_mechanic = p_mechanic


## Connects all inter-system signals. Call once after setup().
func wire() -> void:
	assert(_rsc != null, "GameFlowOrchestrator.wire: call setup() first")

	# VFX two-way link:
	#   vfx_play_requested → RunSequenceVFX.handle_play
	#   RunSequenceVFX.vfx_complete → RunSimulationController (internal)
	_rsc.connect_vfx(_vfx)

	# RunSimulationController lock / unlock → all interactive systems
	_rsc.locked.connect(_on_locked)
	_rsc.unlocked.connect(_on_unlocked)

	# Puzzle completion → navigation + result display
	_rsc.puzzle_solved.connect(_nav.go_to_puzzle)
	_rsc.puzzle_solved.connect(_on_puzzle_solved)

	# Attempt counter
	_rsc.attempt_completed.connect(_hud.update_attempts)
	_rsc.attempt_completed.connect(_mechanic.on_attempt_completed)

	# OrganRepairMechanic slot events → SpecimenViewer highlight
	_mechanic.slot_selected.connect(_on_slot_selected)
	_mechanic.slot_deselected.connect(_on_slot_deselected)

# ---------------------------------------------------------------------------
# Private — signal handlers
# ---------------------------------------------------------------------------

## Locks all interactive systems during a RUN simulation.
func _on_locked() -> void:
	_viewer.lock_interaction()
	_hud.lock()
	_mechanic.lock()


## Restores all interactive systems after a RUN simulation completes.
func _on_unlocked() -> void:
	_viewer.unlock_interaction()
	_hud.unlock()
	_mechanic.unlock()


## Shows the success result in the HUD when the puzzle is solved.
func _on_puzzle_solved(_next_puzzle_index: int) -> void:
	_hud.show_result(true)


## Activates the selection highlight on the given slot in the viewer.
func _on_slot_selected(slot_index: int) -> void:
	_viewer.set_slot_selected(slot_index, true)


## Clears the selection highlight on the given slot in the viewer.
func _on_slot_deselected(slot_index: int) -> void:
	_viewer.set_slot_selected(slot_index, false)
