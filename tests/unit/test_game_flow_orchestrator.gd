extends GutTest

## T17 — GameFlowOrchestrator unit tests.
## Verifies that wire() correctly routes all inter-system signals.
##
## Whitebox access: viewer._state, viewer._slot_states, hud._state are inspected
## directly to confirm that signal routing reached its intended target.

# ---------------------------------------------------------------------------
# Fixture helpers — shared with test_visual_layer_integration.gd pattern
# ---------------------------------------------------------------------------

func _make_organ(p_id: String) -> OrganTypeResource:
	var o := OrganTypeResource.new()
	o.organ_id = p_id
	o.display_name = p_id.capitalize()
	o.role = OrganTypeResource.Role.EMITTER
	o.output_channels = ["PULSE"]
	o.biology_rule_id = "rule_test"
	o.creature_type_ids = ["xenith_01"]
	return o


func _make_registry() -> OrganTypeRegistry:
	var r := OrganTypeRegistry.new()
	r.organs = [
		_make_organ("vordex"),
		_make_organ("valdris"),
		_make_organ("thrennic"),
		_make_organ("ossuric"),
	]
	return r


func _make_slot(p_index: int, p_pos: Vector2) -> OrganSlotDefinition:
	var s := OrganSlotDefinition.new()
	s.slot_index = p_index
	s.world_position = p_pos
	return s


func _make_creature() -> CreatureTypeResource:
	var c := CreatureTypeResource.new()
	c.creature_id = "xenith_01"
	c.display_name = "Xenith"
	c.lore_hint = "Test creature."
	c.organ_slots = [
		_make_slot(0, Vector2(-80.0, -70.0)),
		_make_slot(1, Vector2( 80.0, -70.0)),
		_make_slot(2, Vector2(-80.0,  70.0)),
		_make_slot(3, Vector2(  0.0,  90.0)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_puzzle_resource() -> PuzzleResource:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "GFO Test Puzzle"
	pr.creature_type_id = "xenith_01"
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.starting_configuration = start
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	return pr


## Builds and wires all six systems. Returns a Dictionary with every node.
## All nodes are add_child()-ed to the test scene for proper lifecycle.
func _build_wired() -> Dictionary:
	var reg      := _make_registry()
	var creature := _make_creature()
	var pr       := _make_puzzle_resource()
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]

	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, reg)

	var handler := TouchInputHandler.new()
	add_child(handler)

	var rsc := RunSimulationController.new()
	add_child(rsc)
	rsc.setup(inst, creature, reg)

	var viewer := SpecimenViewer.new()
	add_child(viewer)
	viewer.setup(creature, reg, handler, inst)
	viewer.load_creature(healthy)

	# PuzzleHUD must be in the tree before setup() because setup() calls add_child()
	# on its child labels and rects.
	var hud := PuzzleHUD.new()
	add_child(hud)
	hud.setup(reg, handler, inst)
	hud.load_puzzle(pr)

	var vfx := RunSequenceVFX.new()
	add_child(vfx)

	var nav := ScreenNavigation.new()
	nav.total_puzzle_count = 10
	add_child(nav)

	var mechanic := OrganRepairMechanic.new()
	add_child(mechanic)
	mechanic.setup(inst)

	var gfo := GameFlowOrchestrator.new()
	add_child(gfo)
	gfo.setup(rsc, viewer, hud, vfx, nav, mechanic)
	gfo.wire()

	return {
		"gfo": gfo, "rsc": rsc, "viewer": viewer,
		"hud": hud, "vfx": vfx, "nav": nav,
		"mechanic": mechanic, "inst": inst,
	}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_gfo_locked_locks_viewer_and_hud() -> void:
	# Arrange
	var s := _build_wired()
	var viewer: SpecimenViewer = s.viewer
	var hud: PuzzleHUD         = s.hud
	var rsc: RunSimulationController = s.rsc

	# Act — emit locked directly (bypasses the full RUN flow)
	rsc.locked.emit()

	# Assert — whitebox: state machines reflect the lock
	assert_eq(viewer._state, SpecimenViewer.State.LOCKED,
		"SpecimenViewer should enter LOCKED state after rsc.locked")
	assert_eq(hud._state, PuzzleHUD.State.LOCKED,
		"PuzzleHUD should enter LOCKED state after rsc.locked")


func test_gfo_unlocked_restores_viewer_and_hud() -> void:
	# Arrange
	var s := _build_wired()
	var viewer: SpecimenViewer = s.viewer
	var hud: PuzzleHUD         = s.hud
	var rsc: RunSimulationController = s.rsc
	rsc.locked.emit()   # enter locked first

	# Act
	rsc.unlocked.emit()

	# Assert
	assert_eq(viewer._state, SpecimenViewer.State.ACTIVE,
		"SpecimenViewer should return to ACTIVE after rsc.unlocked")
	assert_eq(hud._state, PuzzleHUD.State.ACTIVE,
		"PuzzleHUD should return to ACTIVE after rsc.unlocked")


func test_gfo_puzzle_solved_emits_scene_change_for_correct_puzzle() -> void:
	# Arrange
	var s   := _build_wired()
	var nav: ScreenNavigation = s.nav
	var rsc: RunSimulationController = s.rsc
	watch_signals(nav)

	# Act — puzzle_solved carries the NEXT puzzle index
	rsc.puzzle_solved.emit(3)

	# Assert
	assert_signal_emitted(nav, "scene_change_requested")
	var params: Array = get_signal_parameters(nav, "scene_change_requested")
	assert_eq(params[0], ScreenNavigation.SCREEN_PUZZLE,
		"scene_change_requested screen_id should be 'puzzle'")
	assert_eq((params[1] as Dictionary).get("puzzle_index"), 3,
		"scene_change_requested params should contain puzzle_index = 3")


func test_gfo_puzzle_solved_shows_hud_success_result() -> void:
	# Arrange
	var s   := _build_wired()
	var hud: PuzzleHUD = s.hud
	var rsc: RunSimulationController = s.rsc

	# Act
	rsc.puzzle_solved.emit(2)

	# Assert — show_result(true) transitions hud to SOLVED
	assert_eq(hud._state, PuzzleHUD.State.SOLVED,
		"PuzzleHUD should enter SOLVED state when puzzle_solved is emitted")


func test_gfo_slot_selected_highlights_viewer_slot() -> void:
	# Arrange
	var s        := _build_wired()
	var viewer: SpecimenViewer    = s.viewer
	var mechanic: OrganRepairMechanic = s.mechanic

	# Act
	mechanic.slot_selected.emit(1)

	# Assert — whitebox: slot 1 marked selected in viewer
	assert_true(viewer._slot_states[1].selected,
		"viewer._slot_states[1].selected should be true after slot_selected(1)")


func test_gfo_slot_deselected_clears_viewer_highlight() -> void:
	# Arrange
	var s        := _build_wired()
	var viewer: SpecimenViewer    = s.viewer
	var mechanic: OrganRepairMechanic = s.mechanic
	mechanic.slot_selected.emit(2)  # select first

	# Act
	mechanic.slot_deselected.emit(2)

	# Assert
	assert_false(viewer._slot_states[2].selected,
		"viewer._slot_states[2].selected should be false after slot_deselected(2)")
