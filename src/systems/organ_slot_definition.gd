class_name OrganSlotDefinition
extends Resource

## Creature anatomy'sindeki tek bir organ slotunu tanımlar.
## world_position: creature merkezine göre piksel offset (Specimen Viewer kullanır).
## accepted_organ_type_ids boşsa tüm organ tipleri geçerlidir.

@export var slot_index: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var accepted_organ_type_ids: Array[String] = []


func accepts_organ(organ_id: String) -> bool:
	if accepted_organ_type_ids.is_empty():
		return true
	return organ_id in accepted_organ_type_ids
