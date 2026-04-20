class_name EvaluationResult
extends RefCounted

## Value object returned by BiologyRuleEngine.evaluate().
## wrong_slots and wrong_organs are parallel arrays:
## wrong_organs[i] is the organ_id placed at wrong_slots[i].

## True when no wrong slots were found.
var is_healthy: bool = false
## Indices of slots that do not match the healthy configuration.
var wrong_slots: Array[int] = []
## Organ IDs placed at the corresponding wrong_slots index.
var wrong_organs: Array[String] = []
