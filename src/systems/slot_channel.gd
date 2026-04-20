class_name SlotChannel
extends Resource

## Creature anatomy'sindeki iki organ slotu arasındaki biyoloji kanalını tanımlar.
## Biology Rule Engine sinyal propagasyonu için bu kanalları kullanır.

@export var from_slot_index: int = 0
@export var to_slot_index: int = 1
@export var flow_type: OrganTypeResource.FlowType = OrganTypeResource.FlowType.PULSE


func is_valid() -> bool:
	return from_slot_index != to_slot_index
