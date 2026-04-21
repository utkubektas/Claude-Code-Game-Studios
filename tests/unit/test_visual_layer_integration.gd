extends GutTest

## T16 — Visual Layer Integration Tests
## Verifies that Sprint 03 systems wire correctly to each other and to
## the Sprint 02 signal contracts. No rendering is asserted — only state
## and signal outcomes.

# ---------------------------------------------------------------------------
# Shared helpers
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
		_make_slot(1, Vector2(80.0, -70.0)),
		_make_slot(2, Vector2(-80.0, 70.0)),
		_make_slot(3, Vector2(0.0, 90.0)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_puzzle_resource() -> PuzzleResource:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Integration Test"
	pr.creature_type_id = "xenith_01"
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.starting_configuration = config
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	return pr


func _make_puzzle_instance(p_start: Array[String] = []) -> PuzzleInstance:
	var start: Array[String]
	if p_start.is_empty():
		var default_start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
		start = default_start
	else:
		start = p_start
	var pr := _make_puzzle_resource()
	pr.starting_configuration = start
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := PuzzleInstance.new()
	inst.setup(pr, healthy, _make_registry())
	return inst


func _make_touch_handler() -> TouchInputHandler:
	var h := TouchInputHandler.new()
	add_child(h)
	return h


# ---------------------------------------------------------------------------
# Integration set-up: SpecimenViewer + OrganRepairMechanic
# ---------------------------------------------------------------------------

func _make_viewer_with_mechanic() -> Dictionary:
	var registry := _make_registry()
	var creature := _make_creature()
	var handler := _make_touch_handler()
	var inst := _make_puzzle_instance()

	var mechanic := OrganRepairMechanic.new()
	add_child(mechanic)
	mechanic.setup(inst)
	mechanic.connect_input(handler)

	var viewer := SpecimenViewer.new()
	add_child(viewer)
	viewer.setup(creature, registry, handler, inst)
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	viewer.load_creature(healthy)

	# Wire mechanic selection signals → viewer slot highlight
	mechanic.slot_selected.connect(func(i: int) -> void: viewer.set_slot_selected(i, true))
	mechanic.slot_deselected.connect(func(i: int) -> void: viewer.set_slot_selected(i, false))

	return { "handler": handler, "mechanic": mechanic, "viewer": viewer, "inst": inst }


# ---------------------------------------------------------------------------
# T16 tests — SpecimenViewer + OrganRepairMechanic
# ---------------------------------------------------------------------------

func test_visual_layer_slot_tapped_makes_viewer_show_selection() -> void:
	# Arrange
	var sys: Dictionary = _make_viewer_with_mechanic()
	var handler: TouchInputHandler = sys["handler"]
	var viewer: SpecimenViewer = sys["viewer"]

	# Act — simulate a tap on slot 0
	handler.slot_tapped.emit(0)

	# Assert — viewer reflects selected state
	assert_true(viewer._slot_states[0].selected)

	# Cleanup
	sys["mechanic"].queue_free()
	viewer.queue_free()


func test_visual_layer_second_slot_tap_moves_selection_to_new_slot() -> void:
	# Arrange
	var sys: Dictionary = _make_viewer_with_mechanic()
	var handler: TouchInputHandler = sys["handler"]
	var viewer: SpecimenViewer = sys["viewer"]

	# Act — select slot 0, then slot 2
	handler.slot_tapped.emit(0)
	handler.slot_tapped.emit(2)

	# Assert
	assert_false(viewer._slot_states[0].selected)
	assert_true(viewer._slot_states[2].selected)

	# Cleanup
	sys["mechanic"].queue_free()
	viewer.queue_free()


func test_visual_layer_organ_placed_clears_selection_and_refreshes_viewer() -> void:
	# Arrange — slot 0 has "ossuric" (wrong); correct is "vordex"
	var sys: Dictionary = _make_viewer_with_mechanic()
	var handler: TouchInputHandler = sys["handler"]
	var viewer: SpecimenViewer = sys["viewer"]

	# Slot 0 starts damaged (ossuric != vordex)
	assert_true(viewer._slot_states[0].damaged)

	# Act — select slot 0, place correct organ via mechanic
	handler.slot_tapped.emit(0)
	# ossuric is pre-attempt locked; give mechanic first attempt credit
	sys["mechanic"].on_attempt_completed()
	# Now place "vordex" (the healthy organ for slot 0)
	handler.inventory_tapped.emit("vordex")

	# Assert — selection cleared and damage healed
	assert_false(viewer._slot_states[0].selected)
	assert_false(viewer._slot_states[0].damaged)

	# Cleanup
	sys["mechanic"].queue_free()
	viewer.queue_free()


# ---------------------------------------------------------------------------
# T16 tests — RunSequenceVFX + RunSimulationController
# ---------------------------------------------------------------------------

func _make_vfx_with_controller() -> Dictionary:
	var registry := _make_registry()
	var creature := _make_creature()
	var inst := _make_puzzle_instance()
	var handler := _make_touch_handler()

	var controller := RunSimulationController.new()
	add_child(controller)
	controller.setup(inst, creature, registry)
	controller.connect_input(handler)

	var vfx := RunSequenceVFX.new()
	add_child(vfx)
	controller.connect_vfx(vfx)

	return { "handler": handler, "controller": controller, "vfx": vfx, "inst": inst }


func test_visual_layer_run_tapped_triggers_vfx_and_vfx_complete_unlocks() -> void:
	# Arrange
	var sys: Dictionary = _make_vfx_with_controller()
	var handler: TouchInputHandler = sys["handler"]
	var controller: RunSimulationController = sys["controller"]
	var vfx: RunSequenceVFX = sys["vfx"]
	watch_signals(controller)

	# Act
	handler.run_tapped.emit()
	# VFX receives handle_play → stub out Tween with seam
	vfx.notify_vfx_complete()

	# Assert — unlocked signal fired after vfx_complete
	assert_signal_emitted(controller, "unlocked")

	# Cleanup
	controller.queue_free()
	vfx.queue_free()


func test_visual_layer_vfx_complete_sets_controller_back_to_idle() -> void:
	# Arrange
	var sys: Dictionary = _make_vfx_with_controller()
	var handler: TouchInputHandler = sys["handler"]
	var controller: RunSimulationController = sys["controller"]
	var vfx: RunSequenceVFX = sys["vfx"]

	# Act — run once, complete
	handler.run_tapped.emit()
	vfx.notify_vfx_complete()

	# Assert — a second run_tapped should work (controller is IDLE again)
	watch_signals(controller)
	handler.run_tapped.emit()
	assert_signal_emitted(controller, "locked")

	# Cleanup
	vfx.notify_vfx_complete()
	controller.queue_free()
	vfx.queue_free()


# ---------------------------------------------------------------------------
# T16 tests — PuzzleHUD + TouchInputHandler touch areas
# ---------------------------------------------------------------------------

func test_visual_layer_puzzle_hud_inventory_areas_all_registered() -> void:
	# Arrange
	var registry := _make_registry()
	var handler := _make_touch_handler()
	var inst := _make_puzzle_instance()

	var hud := PuzzleHUD.new()
	hud.setup(registry, handler, inst)
	add_child(hud)
	hud.load_puzzle(_make_puzzle_resource())

	# Assert — all four inventory touch areas and RUN are registered
	assert_true(handler._areas.has("inv_vordex"))
	assert_true(handler._areas.has("inv_valdris"))
	assert_true(handler._areas.has("inv_thrennic"))
	assert_true(handler._areas.has("inv_ossuric"))
	assert_true(handler._areas.has("run_btn"))

	# Cleanup
	hud.queue_free()


func test_visual_layer_puzzle_hud_show_result_registers_continue_area() -> void:
	# Arrange
	var registry := _make_registry()
	var handler := _make_touch_handler()
	var inst := _make_puzzle_instance()

	var hud := PuzzleHUD.new()
	hud.setup(registry, handler, inst)
	add_child(hud)
	hud.load_puzzle(_make_puzzle_resource())

	# Act
	hud.show_result(true)

	# Assert
	assert_true(handler._areas.has("continue_btn"))

	# Cleanup
	hud.queue_free()


# ---------------------------------------------------------------------------
# T16 tests — Sprint 02 regression guard
# ---------------------------------------------------------------------------

func test_visual_layer_sprint02_organ_repair_mechanic_slot_selection_intact() -> void:
	# Arrange
	var handler := _make_touch_handler()
	var inst := _make_puzzle_instance()

	var mechanic := OrganRepairMechanic.new()
	add_child(mechanic)
	mechanic.setup(inst)
	mechanic.connect_input(handler)
	watch_signals(mechanic)

	# Act
	handler.slot_tapped.emit(1)

	# Assert — Sprint 02 signal contract unchanged
	assert_signal_emitted(mechanic, "slot_selected")
	var params: Array = get_signal_parameters(mechanic, "slot_selected")
	assert_eq(params[0], 1)

	# Cleanup
	mechanic.queue_free()


func test_visual_layer_sprint02_run_controller_attempt_completed_signal_intact() -> void:
	# Arrange
	var registry := _make_registry()
	var creature := _make_creature()
	var inst := _make_puzzle_instance()
	var handler := _make_touch_handler()

	var controller := RunSimulationController.new()
	add_child(controller)
	controller.setup(inst, creature, registry)
	controller.connect_input(handler)

	var vfx := RunSequenceVFX.new()
	add_child(vfx)
	controller.connect_vfx(vfx)

	watch_signals(controller)

	# Act
	handler.run_tapped.emit()
	vfx.notify_vfx_complete()

	# Assert — attempt_completed fired (Sprint 02 contract)
	assert_signal_emitted(controller, "attempt_completed")

	# Cleanup
	controller.queue_free()
	vfx.queue_free()
