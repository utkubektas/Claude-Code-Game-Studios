class_name FailureCascadeSystem
extends RefCounted

## Converts an EvaluationResult into a FailureCascadeResult.
## Stateless: same input always yields the same output. No internal state.
##
## Thresholds (data-driven via STRUCTURAL_THRESHOLD):
##   0 wrong  → NONE
##   1–2 wrong → ORGAN  (failed_organs populated)
##   3+ wrong  → STRUCTURAL (structural_code populated)

## Minimum wrong-slot count that triggers a STRUCTURAL failure.
const STRUCTURAL_THRESHOLD: int = 3


## Resolves an EvaluationResult into a FailureCascadeResult.
## All failures are simultaneous — no sequential cascade in this implementation.
func resolve(evaluation: EvaluationResult) -> FailureCascadeResult:
	var result := FailureCascadeResult.new()
	var wrong_count: int = evaluation.wrong_slots.size()

	if wrong_count == 0:
		result.failure_type = FailureCascadeResult.FailureType.NONE
	elif wrong_count < STRUCTURAL_THRESHOLD:
		result.failure_type = FailureCascadeResult.FailureType.ORGAN
		result.failed_organs = evaluation.wrong_organs.duplicate()
	else:
		result.failure_type = FailureCascadeResult.FailureType.STRUCTURAL
		result.structural_code = "STRUCTURAL_%d" % wrong_count

	return result
