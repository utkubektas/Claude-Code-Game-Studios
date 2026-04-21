extends GutTest

## T12 — SpecimenViewer acceptance criteria
##
## Whitebox policy: these tests access private members (_state, _slot_states,
## _puzzle_instance, handler._areas) intentionally. SpecimenViewer has no
## public query API for slot state by design — the only observable side-effects
## are visual (draw calls), which cannot be asserted in GUT. Unit-tier whitebox
## access is the accepted pattern for this codebase.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _viewer: SpecimenViewer

func before_each() -> void:
	_viewer = null


func after_each() -> void:
	if is_instance_valid(_viewer):
		_viewer.queue_free()
	_viewer = null


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
		_make_slot(1, Vector2(80.0, -70.0)),
		_make_slot(2, Vector2(-80.0, 70.0)),
		_make_slot(3, Vector2(0.0, 90.0)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_puzzle_instance(p_start: Array[String]) -> PuzzleInstance:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Specimen 01-A"
	pr.creature_type_id = "xenith_01"
	pr.starting_configuration = p_start
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, _make_registry())
	return inst


## Creates a fully wired SpecimenViewer with load_creature() already called.
## Both the handler and viewer are added as children of the test node.
func _make_viewer(p_start: Array[String]) -> SpecimenViewer:
	var creature := _make_creature()
	var registry := _make_registry()
	var handler := TouchInputHandler.new()
	add_child(handler)
	var puzzle := _make_puzzle_instance(p_start)
	var viewer := SpecimenViewer.new()
	add_child(viewer)
	viewer.setup(creature, registry, handler, puzzle)
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	viewer.load_creature(healthy)
	return viewer


# ---------------------------------------------------------------------------
# T12 tests
# ---------------------------------------------------------------------------

func test_specimen_viewer_load_creature_registers_touch_areas() -> void:
	# Arrange
	var creature := _make_creature()
	var registry := _make_registry()
	var handler := TouchInputHandler.new()
	add_child(handler)
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var puzzle := _make_puzzle_instance(start)
	_viewer = SpecimenViewer.new()
	add_child(_viewer)

	# Act
	_viewer.setup(creature, registry, handler, puzzle)
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	_viewer.load_creature(healthy)

	# Assert — whitebox: handler._areas is private but has no public query API
	assert_true(handler._areas.has("slot_0"))
	assert_true(handler._areas.has("slot_1"))
	assert_true(handler._areas.has("slot_2"))
	assert_true(handler._areas.has("slot_3"))


func test_specimen_viewer_load_creature_sets_state_active() -> void:
	# Arrange + Act
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Assert — whitebox: State enum is public (PascalCase per R6 fix)
	assert_eq(_viewer._state, SpecimenViewer.State.ACTIVE)


func test_specimen_viewer_refresh_slots_marks_damaged_slot() -> void:
	# Arrange — slot 0 has "ossuric" but healthy expects "vordex"
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Act
	_viewer.refresh_slots()

	# Assert
	assert_true(_viewer._slot_states[0].damaged)


func test_specimen_viewer_refresh_slots_marks_healthy_slot() -> void:
	# Arrange — slot 1 has correct organ "valdris"
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Act
	_viewer.refresh_slots()

	# Assert
	assert_false(_viewer._slot_states[1].damaged)


func test_specimen_viewer_set_slot_selected_true_marks_selected() -> void:
	# Arrange
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Act
	_viewer.set_slot_selected(0, true)

	# Assert
	assert_true(_viewer._slot_states[0].selected)


func test_specimen_viewer_set_slot_selected_false_clears_selected() -> void:
	# Arrange
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)
	_viewer.set_slot_selected(0, true)

	# Act
	_viewer.set_slot_selected(0, false)

	# Assert
	assert_false(_viewer._slot_states[0].selected)


func test_specimen_viewer_lock_sets_locked_state() -> void:
	# Arrange
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Act
	_viewer.lock_interaction()

	# Assert
	assert_eq(_viewer._state, SpecimenViewer.State.LOCKED)


func test_specimen_viewer_unlock_sets_active_state() -> void:
	# Arrange
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)
	_viewer.lock_interaction()

	# Act
	_viewer.unlock_interaction()

	# Assert
	assert_eq(_viewer._state, SpecimenViewer.State.ACTIVE)


func test_specimen_viewer_organ_placed_signal_triggers_refresh() -> void:
	# Arrange — slot 0 has "ossuric" (wrong); correct is "vordex"
	# Whitebox: directly mutates _puzzle_instance to trigger the organ_placed signal.
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)
	assert_true(_viewer._slot_states[0].damaged, "pre-condition: slot 0 should be damaged")

	# Act — place the correct organ; PuzzleInstance.set_organ emits organ_placed
	_viewer._puzzle_instance.set_organ(0, "vordex")

	# Assert — _on_organ_placed triggered refresh_slots; damage cleared
	assert_false(_viewer._slot_states[0].damaged)


func test_specimen_viewer_invalid_slot_index_does_not_crash() -> void:
	# Arrange
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	_viewer = _make_viewer(start)

	# Act + Assert — no crash on negative index; no assertion needed beyond surviving
	_viewer.set_slot_selected(-1, true)
	pass
