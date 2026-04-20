class_name FailureCascadeResult
extends RefCounted

## Value object returned by FailureCascadeSystem.resolve().
## Describes the severity and specifics of the evaluation failure.

enum FailureType {
	## All organs in the correct slots — no failure.
	NONE,
	## 1–2 wrong organs — localised organ failure.
	ORGAN,
	## 3+ wrong organs — the creature's biology has collapsed systemically.
	STRUCTURAL,
}

## Severity category derived from EvaluationResult.wrong_slots.size().
var failure_type: FailureType = FailureType.NONE

## Organ IDs that are wrong (populated for ORGAN failures; empty for NONE and STRUCTURAL).
var failed_organs: Array[String] = []

## Machine-readable code for the structural event (populated for STRUCTURAL; empty otherwise).
var structural_code: String = ""
