extends GutTest

## T05 — FailureCascadeSystem acceptance criteria

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_evaluation(p_wrong_count: int) -> EvaluationResult:
	var r := EvaluationResult.new()
	for i: int in p_wrong_count:
		r.wrong_slots.append(i)
		r.wrong_organs.append("wrong_organ_%d" % i)
	r.is_healthy = p_wrong_count == 0
	return r


# ---------------------------------------------------------------------------
# T05 tests — thresholds
# ---------------------------------------------------------------------------

func test_failure_cascade_system_resolve_returns_none_when_zero_wrong() -> void:
	# Arrange
	var eval := _make_evaluation(0)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.NONE)


func test_failure_cascade_system_resolve_returns_organ_when_one_wrong() -> void:
	# Arrange
	var eval := _make_evaluation(1)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.ORGAN)
	assert_eq(result.failed_organs.size(), 1)


func test_failure_cascade_system_resolve_returns_organ_when_two_wrong() -> void:
	# Arrange
	var eval := _make_evaluation(2)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.ORGAN)
	assert_eq(result.failed_organs.size(), 2)


func test_failure_cascade_system_resolve_returns_structural_when_three_wrong() -> void:
	# Arrange
	var eval := _make_evaluation(3)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.STRUCTURAL)


func test_failure_cascade_system_resolve_returns_structural_when_four_wrong() -> void:
	# Arrange
	var eval := _make_evaluation(4)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.STRUCTURAL)


func test_failure_cascade_system_resolve_none_has_empty_failed_organs() -> void:
	# Arrange
	var eval := _make_evaluation(0)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failed_organs.size(), 0)


func test_failure_cascade_system_resolve_structural_has_empty_failed_organs() -> void:
	# Arrange — STRUCTURAL does not populate failed_organs (cascade replaces individual tracking)
	var eval := _make_evaluation(3)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failed_organs.size(), 0)


func test_failure_cascade_system_resolve_structural_populates_structural_code() -> void:
	# Arrange
	var eval := _make_evaluation(3)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert
	assert_false(result.structural_code.is_empty())


func test_failure_cascade_system_resolve_organ_failed_organs_match_evaluation() -> void:
	# Arrange
	var eval := _make_evaluation(2)
	var system := FailureCascadeSystem.new()

	# Act
	var result := system.resolve(eval)

	# Assert — failed_organs is a copy of evaluation.wrong_organs
	assert_eq(result.failed_organs, eval.wrong_organs)


func test_failure_cascade_system_resolve_is_simultaneous_not_sequential() -> void:
	# Arrange — all 4 slots wrong; resolve() must return a single result, not 4 cascaded ones
	var eval := _make_evaluation(4)
	var system := FailureCascadeSystem.new()

	# Act — calling resolve() once must be sufficient; no iteration needed by caller
	var result := system.resolve(eval)

	# Assert
	assert_eq(result.failure_type, FailureCascadeResult.FailureType.STRUCTURAL,
		"Tüm başarısızlıklar aynı anda çözülmeli — tek resolve() çağrısı yeterli.")
