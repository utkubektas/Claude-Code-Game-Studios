extends GutTest

## T04 — BiologyRuleEngine acceptance criteria

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


func _make_context(p_config: Array[String]) -> BiologyContext:
	return BiologyContext.new(p_config, _make_creature(), _make_registry())


# ---------------------------------------------------------------------------
# T04 tests
# ---------------------------------------------------------------------------

func test_biology_rule_engine_evaluate_returns_healthy_when_all_correct() -> void:
	# Arrange
	var config: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert
	assert_true(result.is_healthy)
	assert_eq(result.wrong_slots.size(), 0)


func test_biology_rule_engine_evaluate_returns_one_wrong_slot_when_slot0_differs() -> void:
	# Arrange — slot 0 has "ossuric" instead of the healthy "vordex"
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert
	assert_eq(result.wrong_slots.size(), 1)
	assert_eq(result.wrong_slots[0], 0)


func test_biology_rule_engine_evaluate_wrong_organs_contains_placed_organ_id() -> void:
	# Arrange — slot 0 has "ossuric"; wrong_organs must record what was actually placed
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert
	assert_eq(result.wrong_organs[0], "ossuric")


func test_biology_rule_engine_evaluate_returns_four_wrong_slots_when_all_differ() -> void:
	# Arrange — every slot is swapped to a wrong organ
	var config: Array[String] = ["ossuric", "thrennic", "valdris", "vordex"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert
	assert_eq(result.wrong_slots.size(), 4)
	assert_false(result.is_healthy)


func test_biology_rule_engine_evaluate_is_deterministic() -> void:
	# Arrange — same context evaluated twice must yield identical results
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result_a := engine.evaluate(ctx)
	var result_b := engine.evaluate(ctx)

	# Assert
	assert_eq(result_a.is_healthy, result_b.is_healthy)
	assert_eq(result_a.wrong_slots, result_b.wrong_slots)
	assert_eq(result_a.wrong_organs, result_b.wrong_organs)


func test_biology_rule_engine_evaluate_does_not_mutate_context() -> void:
	# Arrange
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var config_before: Array[String] = ctx.configuration.duplicate()
	var engine := BiologyRuleEngine.new()

	# Act
	engine.evaluate(ctx)

	# Assert — ctx.configuration must be byte-for-byte identical to what it was before
	assert_eq(ctx.configuration, config_before)


func test_biology_rule_engine_evaluate_returns_healthy_false_when_one_wrong() -> void:
	# Arrange
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert
	assert_false(result.is_healthy)


func test_biology_rule_engine_evaluate_wrong_slot_index_is_correct() -> void:
	# Arrange — only slot 2 is wrong
	var config: Array[String] = ["vordex", "valdris", "ossuric", "ossuric"]
	var ctx := _make_context(config)
	var engine := BiologyRuleEngine.new()

	# Act
	var result := engine.evaluate(ctx)

	# Assert — the first (and only) wrong slot must be index 2
	assert_eq(result.wrong_slots[0], 2)
