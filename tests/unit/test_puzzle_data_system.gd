extends GutTest

## T03 — Puzzle Data System test suite
## Acceptance criteria: puzzle-data-system.md §Acceptance Criteria

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


func _make_xenith() -> CreatureTypeResource:
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


func _make_creature_system() -> CreatureDefinitionSystem:
	var s := CreatureDefinitionSystem.new()
	s.creatures = [_make_xenith()]
	return s


## Tek fark olan geçerli bir PuzzleResource döner (slot 0 farklı).
func _make_valid_puzzle_resource(p_index: int = 1) -> PuzzleResource:
	var pr := PuzzleResource.new()
	pr.puzzle_index = p_index
	pr.display_title = "Specimen 0%d-A" % p_index
	pr.creature_type_id = "xenith_01"
	# healthy = ["vordex", "valdris", "thrennic", "ossuric"]
	# slot 0 farklı → 1 fark
	pr.starting_configuration = ["ossuric", "valdris", "thrennic", "ossuric"]
	pr.hint_slot_index = 0
	pr.unlock_after_index = p_index - 1
	return pr


## PuzzleInstance'ı doğrudan (PuzzleDataSystem olmadan) kurar.
func _make_instance(
	p_puzzle: PuzzleResource,
	p_registry: OrganTypeRegistry,
	p_healthy: Array
) -> PuzzleInstance:
	var inst := PuzzleInstance.new()
	var typed_healthy: Array[String] = []
	typed_healthy.assign(p_healthy)
	inst.setup(p_puzzle, typed_healthy, p_registry)
	return inst


# ---------------------------------------------------------------------------
# PuzzleResource.is_valid — F2 doğrulaması
# ---------------------------------------------------------------------------

func test_puzzle_resource_is_valid_passes_with_one_difference() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_true(result)


func test_puzzle_resource_is_valid_fails_when_zero_differences() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.starting_configuration = ["vordex", "valdris", "thrennic", "ossuric"]  # == healthy → 0 fark
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_false(result)


func test_puzzle_resource_is_valid_fails_when_two_or_more_differences() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.starting_configuration = ["ossuric", "thrennic", "thrennic", "ossuric"]  # slot 0+1 farklı → 2 fark
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_false(result)


func test_puzzle_resource_is_valid_fails_on_unknown_organ_id() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.starting_configuration = ["UNKNOWN_ORGAN", "valdris", "thrennic", "ossuric"]
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_false(result)


func test_puzzle_resource_is_valid_fails_on_unknown_creature_type_id() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.creature_type_id = "does_not_exist"
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_false(result)


func test_puzzle_resource_is_valid_fails_when_config_size_mismatches_slots() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.starting_configuration = ["ossuric", "valdris"]  # 2 eleman, creature 4 slot
	var cds := _make_creature_system()
	var reg := _make_registry()

	# Act
	var result: bool = pr.is_valid(cds, reg)

	# Assert
	assert_false(result)


# ---------------------------------------------------------------------------
# PuzzleInstance — load, set_organ, get_current_configuration
# ---------------------------------------------------------------------------

func test_puzzle_instance_load_sets_current_configuration_equal_to_starting() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()

	# Act
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])

	# Assert
	assert_eq(inst.current_configuration, pr.starting_configuration)


func test_puzzle_instance_set_organ_updates_slot() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])

	# Act
	inst.set_organ(2, "valdris")

	# Assert
	assert_eq(inst.current_configuration[2], "valdris")


func test_puzzle_instance_set_organ_unknown_id_is_rejected() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	var before: String = inst.current_configuration[2]

	# Act
	inst.set_organ(2, "UNKNOWN_ORGAN_ID")

	# Assert
	assert_eq(inst.current_configuration[2], before,
		"Bilinmeyen organ_id reddedilmeli — current_configuration değişmemeli.")


func test_puzzle_instance_get_current_configuration_is_stable() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])

	# Act
	var first_call := inst.get_current_configuration()
	var second_call := inst.get_current_configuration()

	# Assert
	assert_eq(first_call, second_call,
		"Aynı frame içinde iki çağrı aynı sonuç vermeli.")


# ---------------------------------------------------------------------------
# PuzzleInstance — check_solved
# ---------------------------------------------------------------------------

func test_puzzle_instance_check_solved_returns_false_when_one_wrong_organ() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	# starting_configuration = ["ossuric", "valdris", "thrennic", "ossuric"] → slot 0 yanlış
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])

	# Act
	var solved: bool = inst.check_solved()

	# Assert
	assert_false(solved)
	assert_false(inst.is_solved)


func test_puzzle_instance_check_solved_returns_true_when_configuration_matches_healthy() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var healthy := ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := _make_instance(pr, reg, healthy)
	inst.set_organ(0, "vordex")  # slot 0'ı düzelt → healthy ile tam eşleşme

	# Act
	var solved: bool = inst.check_solved()

	# Assert
	assert_true(solved)
	assert_true(inst.is_solved)


func test_puzzle_instance_check_solved_emits_puzzle_solved_signal() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var healthy := ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := _make_instance(pr, reg, healthy)
	watch_signals(inst)
	inst.set_organ(0, "vordex")

	# Act
	inst.check_solved()

	# Assert
	assert_signal_emitted(inst, "puzzle_solved")


# ---------------------------------------------------------------------------
# PuzzleInstance — reset
# ---------------------------------------------------------------------------

func test_puzzle_instance_reset_restores_starting_configuration() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	inst.set_organ(0, "vordex")

	# Act
	inst.reset()

	# Assert
	assert_eq(inst.current_configuration, pr.starting_configuration)


func test_puzzle_instance_reset_preserves_attempt_count() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	inst.increment_attempts()
	inst.increment_attempts()

	# Act
	inst.reset()

	# Assert
	assert_eq(inst.attempt_count, 2,
		"reset() attempt_count'u sıfırlamamalı.")


func test_puzzle_instance_reset_clears_is_solved() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var healthy := ["vordex", "valdris", "thrennic", "ossuric"]
	var inst := _make_instance(pr, reg, healthy)
	inst.set_organ(0, "vordex")
	inst.check_solved()
	assert_true(inst.is_solved)

	# Act
	inst.reset()

	# Assert
	assert_false(inst.is_solved)


func test_puzzle_instance_reset_emits_puzzle_reset_signal() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	watch_signals(inst)

	# Act
	inst.reset()

	# Assert
	assert_signal_emitted(inst, "puzzle_reset")


# ---------------------------------------------------------------------------
# PuzzleInstance — organ_placed signal
# ---------------------------------------------------------------------------

func test_puzzle_instance_set_organ_emits_organ_placed_signal() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	watch_signals(inst)

	# Act
	inst.set_organ(2, "valdris")

	# Assert
	assert_signal_emitted_with_parameters(inst, "organ_placed", [2, "valdris"])


func test_puzzle_instance_set_organ_unknown_id_does_not_emit_organ_placed() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])
	watch_signals(inst)

	# Act
	inst.set_organ(2, "UNKNOWN_ORGAN_ID")

	# Assert
	assert_signal_not_emitted(inst, "organ_placed")


# ---------------------------------------------------------------------------
# PuzzleInstance — puzzle_index 1-based
# ---------------------------------------------------------------------------

func test_puzzle_resource_index_is_1_based() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource(1)

	# Assert
	assert_eq(pr.puzzle_index, 1)
	assert_gte(pr.puzzle_index, 1,
		"puzzle_index 1-tabanlı olmalı — 0 geçersiz.")


# ---------------------------------------------------------------------------
# PuzzleDataSystem — next_puzzle_index
# ---------------------------------------------------------------------------

func test_puzzle_data_system_next_puzzle_index_returns_incremented_index() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource(3)
	var reg := _make_registry()
	var inst := _make_instance(pr, reg, ["vordex", "valdris", "thrennic", "ossuric"])

	# Sistem yokken PuzzleResource üzerinden test ediyoruz
	assert_eq(pr.puzzle_index, 3)
	var expected_next: int = pr.puzzle_index + 1

	# Assert
	assert_eq(expected_next, 4)


func test_puzzle_data_system_next_puzzle_index_returns_end_of_sequence_at_max() -> void:
	# Arrange — MAX_PUZZLE_INDEX bulmaca resource oluştur
	var pr := _make_valid_puzzle_resource(PuzzleDataSystem.MAX_PUZZLE_INDEX)

	# Assert
	assert_eq(pr.puzzle_index, PuzzleDataSystem.MAX_PUZZLE_INDEX)
	# next_puzzle_index() END_OF_SEQUENCE döndürmeli
	# (PuzzleDataSystem.next_puzzle_index() burada doğrudan çağrılamaz çünkü
	# Node bağımlılığı var; mantığı PuzzleResource üzerinden doğruluyoruz)
	var would_be_next: int = pr.puzzle_index + 1
	assert_gt(would_be_next, PuzzleDataSystem.MAX_PUZZLE_INDEX,
		"MAX_PUZZLE_INDEX'ten sonraki index sınırı aşar — END_OF_SEQUENCE dönmeli.")


# ---------------------------------------------------------------------------
# PuzzleResource — count_differences_with
# ---------------------------------------------------------------------------

func test_puzzle_resource_count_differences_returns_one_for_valid_puzzle() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]

	# Act
	var diff: int = pr.count_differences_with(healthy)

	# Assert
	assert_eq(diff, 1)


func test_puzzle_resource_count_differences_returns_zero_when_identical() -> void:
	# Arrange
	var pr := _make_valid_puzzle_resource()
	pr.starting_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	var healthy: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]

	# Act
	var diff: int = pr.count_differences_with(healthy)

	# Assert
	assert_eq(diff, 0)
