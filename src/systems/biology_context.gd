class_name BiologyContext
extends RefCounted

## Immutable snapshot of board state passed to BiologyRuleEngine.
## Caller mutations to the source array after construction have no effect here
## because configuration is duplicated on construction.

## Stable snapshot of the organ slot configuration. Index matches slot index.
var configuration: Array[String] = []
## The creature type whose healthy_configuration is used as the reference.
var creature: CreatureTypeResource
## Registry used for organ lookups. Reserved for Sprint 02 rule evaluation.
var registry: OrganTypeRegistry


## Duplicates p_configuration so the engine always operates on a stable snapshot.
func _init(
	p_configuration: Array[String],
	p_creature: CreatureTypeResource,
	p_registry: OrganTypeRegistry
) -> void:
	configuration = p_configuration.duplicate()
	creature = p_creature
	registry = p_registry
