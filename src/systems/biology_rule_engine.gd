class_name BiologyRuleEngine
extends RefCounted

## Stateless evaluator: same input always yields same output.
## Sprint 01 MVP: slot-by-slot comparison only.
## Sprint 02 will add graph traversal and BiologyRuleResource firing.


## Compares each slot in ctx.configuration against ctx.creature.healthy_configuration.
## Returns an EvaluationResult describing which slots (if any) are wrong.
## Never mutates ctx.
func evaluate(ctx: BiologyContext) -> EvaluationResult:
	var result := EvaluationResult.new()

	for i: int in ctx.configuration.size():
		if i >= ctx.creature.healthy_configuration.size():
			push_warning(
				"BiologyRuleEngine: configuration length %d exceeds healthy_configuration length %d — slot %d skipped."
				% [ctx.configuration.size(), ctx.creature.healthy_configuration.size(), i]
			)
			break
		if ctx.configuration[i] != ctx.creature.healthy_configuration[i]:
			result.wrong_slots.append(i)
			result.wrong_organs.append(ctx.configuration[i])

	result.is_healthy = result.wrong_slots.is_empty()
	return result
