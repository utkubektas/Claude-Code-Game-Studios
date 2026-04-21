extends GutTest

## T09 — RunSimulationController acceptance criteria

# ---------------------------------------------------------------------------
# VFX stub — anında vfx_complete emit eder
# ---------------------------------------------------------------------------

class _VFXStub extends Node:
	signal vfx_complete
	func handle_play(_result: FailureCascadeResult) -> void:
		vfx_complete.emit()


# ---------------------------------------------------------------------------
# Helpers
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
		_make_slot(0, Vector2(-80, -70)),
		_make_slot(1, Vector2(80, -70)),
		_make_slot(2, Vector2(-80, 70)),
		_make_slot(3, Vector2(0, 90)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_puzzle_instance(p_start: Array[String]) -> PuzzleInstance:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Test Puzzle"
	pr.creature_type_id = "xenith_01"
	pr.starting_configuration = p_start
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	var inst := PuzzleInstance.new()
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	inst.setup(pr, healthy, _make_registry())
	return inst


func _make_controller_with_stub() -> Array:
	var creature := _make_creature()
	var registry := _make_registry()
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var inst := _make_puzzle_instance(start)

	var rsc := RunSimulationController.new()
	add_child(rsc)

	var stub := _VFXStub.new()
	add_child(stub)
	rsc.connect_vfx(stub)

	rsc.setup(inst, creature, registry)
	return [rsc, inst, stub]


# ---------------------------------------------------------------------------
# T09 tests
# ---------------------------------------------------------------------------

func test_run_simulation_controller_run_tapped_increments_attempts() -> void:
	# Arrange
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	var inst: PuzzleInstance = parts[1]

	# Act
	rsc._on_run_tapped()
	rsc.notify_vfx_complete()

	# Assert
	assert_eq(inst.attempt_count, 1)


func test_run_simulation_controller_run_tapped_emits_attempt_completed() -> void:
	# Arrange
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	watch_signals(rsc)

	# Act
	rsc._on_run_tapped()

	# Assert
	assert_signal_emitted(rsc, "attempt_completed")


func test_run_simulation_controller_run_tapped_emits_locked() -> void:
	# Arrange
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	watch_signals(rsc)

	# Act
	rsc._on_run_tapped()

	# Assert
	assert_signal_emitted(rsc, "locked")


func test_run_simulation_controller_vfx_complete_emits_unlocked() -> void:
	# Arrange — stub olmadan; _on_run_tapped() ANIMATING'de kalır
	var creature := _make_creature()
	var registry := _make_registry()
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var inst := _make_puzzle_instance(start)
	var rsc := RunSimulationController.new()
	add_child(rsc)
	rsc.setup(inst, creature, registry)
	rsc._on_run_tapped()  # → ANIMATING (vfx_complete gelmeyecek)
	watch_signals(rsc)

	# Act
	rsc.notify_vfx_complete()

	# Assert
	assert_signal_emitted(rsc, "unlocked")


func test_run_simulation_controller_run_emits_vfx_play_requested() -> void:
	# Arrange
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	watch_signals(rsc)

	# Act
	rsc._on_run_tapped()

	# Assert
	assert_signal_emitted(rsc, "vfx_play_requested")


func test_run_simulation_controller_wrong_organ_vfx_result_is_organ_type() -> void:
	# Arrange — slot 0 yanlış → ORGAN cascade
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	watch_signals(rsc)

	# Act
	rsc._on_run_tapped()

	# Assert
	assert_signal_emitted(rsc, "vfx_play_requested")
	var params: Array = get_signal_parameters(rsc, "vfx_play_requested")
	var result: FailureCascadeResult = params[0]
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.ORGAN)


func test_run_simulation_controller_correct_config_emits_puzzle_solved() -> void:
	# Arrange — tüm organlar doğru
	var creature := _make_creature()
	var registry := _make_registry()
	var healthy_start: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := _make_puzzle_instance(healthy_start)
	var rsc := RunSimulationController.new()
	add_child(rsc)
	var stub := _VFXStub.new()
	add_child(stub)
	rsc.connect_vfx(stub)
	rsc.setup(inst, creature, registry)
	watch_signals(rsc)

	# Act
	rsc._on_run_tapped()
	rsc.notify_vfx_complete()

	# Assert
	assert_signal_emitted(rsc, "puzzle_solved")


func test_run_simulation_controller_second_run_tapped_during_animating_is_ignored() -> void:
	# Arrange
	var parts := _make_controller_with_stub()
	var rsc: RunSimulationController = parts[0]
	var inst: PuzzleInstance = parts[1]
	rsc._on_run_tapped()  # → ANIMATING (stub emits vfx_complete immediately for non-stub case)
	# Reset state manually to ANIMATING to test guard
	rsc._state = RunSimulationController._State.ANIMATING

	# Act — ikinci tap ANIMATING'de
	rsc._on_run_tapped()

	# Assert — attempt_count hâlâ 1 (ikinci RUN işlenmedi)
	assert_eq(inst.attempt_count, 1)


func test_run_simulation_controller_vfx_timeout_forces_unlock() -> void:
	# Arrange — VFX stub olmadan; vfx_complete gelmeyecek
	var creature := _make_creature()
	var registry := _make_registry()
	var start: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var inst := _make_puzzle_instance(start)
	var rsc := RunSimulationController.new()
	add_child(rsc)
	rsc.setup(inst, creature, registry)

	# RUN tetikle ve ANIMATING'e gir
	rsc._on_run_tapped()
	assert_eq(rsc._state, RunSimulationController._State.ANIMATING)
	watch_signals(rsc)

	# Act — timeout doğrudan tetikle
	rsc._on_vfx_timeout()

	# Assert
	assert_eq(rsc._state, RunSimulationController._State.IDLE)
	assert_signal_emitted(rsc, "unlocked")


func test_run_simulation_controller_same_config_two_runs_same_result() -> void:
	# Arrange — determinizm: iki bağımsız controller, aynı config
	var parts1 := _make_controller_with_stub()
	var rsc1: RunSimulationController = parts1[0]
	watch_signals(rsc1)
	rsc1._on_run_tapped()
	var params_a: Array = get_signal_parameters(rsc1, "vfx_play_requested")

	var parts2 := _make_controller_with_stub()
	var rsc2: RunSimulationController = parts2[0]
	watch_signals(rsc2)
	rsc2._on_run_tapped()
	var params_b: Array = get_signal_parameters(rsc2, "vfx_play_requested")

	# Assert
	assert_not_null(params_a)
	assert_not_null(params_b)
	var result_a: FailureCascadeResult = params_a[0]
	var result_b: FailureCascadeResult = params_b[0]
	assert_eq(result_a.failure_type, result_b.failure_type)
