extends GutTest

## T06 — Foundation Systems Integration Suite
##
## Exercises the full pipeline end-to-end:
##   PuzzleInstance → BiologyContext → BiologyRuleEngine
##       → EvaluationResult → FailureCascadeSystem → FailureCascadeResult
##
## Also validates the Sprint 01 DoD determinism requirement:
##   same input → same output, every time, with no accumulated state.

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
	c.lore_hint = "Integration test creature."
	c.organ_slots = [
		_make_slot(0, Vector2(-80, -70)),
		_make_slot(1, Vector2(80, -70)),
		_make_slot(2, Vector2(-80, 70)),
		_make_slot(3, Vector2(0, 90)),
	]
	c.healthy_configuration = ["vordex", "valdris", "thrennic", "ossuric"]
	c.unlock_condition = "start"
	return c


func _make_puzzle_resource(p_start: Array[String]) -> PuzzleResource:
	var pr := PuzzleResource.new()
	pr.puzzle_index = 1
	pr.display_title = "Integration Puzzle"
	pr.creature_type_id = "xenith_01"
	pr.starting_configuration = p_start
	pr.hint_slot_index = 0
	pr.unlock_after_index = 0
	return pr


func _run_full_pipeline(
	p_placed: Array[String],
	p_creature: CreatureTypeResource,
	p_registry: OrganTypeRegistry
) -> FailureCascadeResult:
	var ctx := BiologyContext.new(p_placed, p_creature, p_registry)
	var engine := BiologyRuleEngine.new()
	var eval := engine.evaluate(ctx)
	var cascade := FailureCascadeSystem.new()
	return cascade.resolve(eval)


# ---------------------------------------------------------------------------
# Full pipeline — healthy path
# ---------------------------------------------------------------------------

func test_integration_healthy_config_yields_none_cascade() -> void:
	# Arrange
	var creature := _make_creature()
	var registry := _make_registry()
	var config: Array[String] = ["vordex", "valdris", "thrennic", "ossuric"]

	# Act
	var cascade_result := _run_full_pipeline(config, creature, registry)

	# Assert
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.NONE)


# ---------------------------------------------------------------------------
# Full pipeline — 1-wrong path (Puzzle 01 scenario)
# ---------------------------------------------------------------------------

func test_integration_one_wrong_organ_yields_organ_cascade() -> void:
	# Arrange — slot 0 has ossuric instead of vordex (canonical puzzle_01 scenario)
	var creature := _make_creature()
	var registry := _make_registry()
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]

	# Act
	var cascade_result := _run_full_pipeline(config, creature, registry)

	# Assert
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.ORGAN)
	assert_eq(cascade_result.failed_organs.size(), 1)
	assert_eq(cascade_result.failed_organs[0], "ossuric")


# ---------------------------------------------------------------------------
# Full pipeline — 3-wrong path (structural collapse)
# ---------------------------------------------------------------------------

func test_integration_three_wrong_organs_yields_structural_cascade() -> void:
	# Arrange
	var creature := _make_creature()
	var registry := _make_registry()
	var config: Array[String] = ["ossuric", "ossuric", "ossuric", "ossuric"]

	# Act
	var cascade_result := _run_full_pipeline(config, creature, registry)

	# Assert
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.STRUCTURAL)


# ---------------------------------------------------------------------------
# PuzzleInstance → pipeline integration
# ---------------------------------------------------------------------------

func test_integration_puzzle_instance_set_organ_feeds_pipeline() -> void:
	# Arrange — start with 1 wrong organ, fix it, then evaluate
	var creature := _make_creature()
	var registry := _make_registry()
	var start_config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var pr := _make_puzzle_resource(start_config)
	var inst := PuzzleInstance.new()
	inst.setup(pr, creature.healthy_configuration, registry)

	# Act — fix the wrong organ
	inst.set_organ(0, "vordex")
	var cascade_result := _run_full_pipeline(
		inst.get_current_configuration(), creature, registry
	)

	# Assert — after fix, pipeline should report NONE
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.NONE)


func test_integration_puzzle_instance_reset_restores_broken_pipeline_state() -> void:
	# Arrange — start with 1 wrong, fix it, then reset back to broken
	var creature := _make_creature()
	var registry := _make_registry()
	var start_config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]
	var pr := _make_puzzle_resource(start_config)
	var inst := PuzzleInstance.new()
	inst.setup(pr, creature.healthy_configuration, registry)
	inst.set_organ(0, "vordex")

	# Act — reset, then evaluate again
	inst.reset()
	var cascade_result := _run_full_pipeline(
		inst.get_current_configuration(), creature, registry
	)

	# Assert — reset must restore the broken configuration → ORGAN failure
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.ORGAN)


# ---------------------------------------------------------------------------
# Full pipeline — 2-wrong path (ORGAN/STRUCTURAL boundary)
# ---------------------------------------------------------------------------

func test_integration_two_wrong_organs_yields_organ_cascade() -> void:
	# Arrange — slots 0 and 1 are wrong; boundary below STRUCTURAL_THRESHOLD (3)
	var creature := _make_creature()
	var registry := _make_registry()
	var config: Array[String] = ["ossuric", "ossuric", "thrennic", "ossuric"]

	# Act
	var cascade_result := _run_full_pipeline(config, creature, registry)

	# Assert
	assert_eq(cascade_result.failure_type, FailureCascadeResult.FailureType.ORGAN)
	assert_eq(cascade_result.failed_organs.size(), 2)


# ---------------------------------------------------------------------------
# Sprint 01 DoD — determinism stress test (100 iterations)
# ---------------------------------------------------------------------------

func test_integration_pipeline_is_deterministic_over_100_iterations() -> void:
	# Arrange — fixed input; results must be identical every time
	var creature := _make_creature()
	var registry := _make_registry()
	var config: Array[String] = ["ossuric", "valdris", "thrennic", "ossuric"]

	var first_result := _run_full_pipeline(config, creature, registry)
	var expected_type: FailureCascadeResult.FailureType = first_result.failure_type
	var expected_organs: Array[String] = first_result.failed_organs.duplicate()

	# Act + Assert — 100 more iterations, each must match the first
	for _i: int in 100:
		var r := _run_full_pipeline(config, creature, registry)
		assert_eq(
			r.failure_type,
			expected_type,
			"Iteration %d: failure_type is not deterministic." % _i
		)
		assert_eq(
			r.failed_organs,
			expected_organs,
			"Iteration %d: failed_organs is not deterministic." % _i
		)
