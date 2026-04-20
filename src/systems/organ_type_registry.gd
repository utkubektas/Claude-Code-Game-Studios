class_name OrganTypeRegistry
extends Resource

## Tüm OrganTypeResource tanımlarını tutan statik katalog.
## Runtime'da salt okunur — yüklendikten sonra değişmez.
## Tüm biyoloji sistemleri bu registry üzerinden organ verilerine erişir.

@export var organs: Array[OrganTypeResource] = []

var _index: Dictionary = {}


## Verilen id'ye sahip organı döner; bilinmeyen id → null (hata atmaz).
func get_organ(id: String) -> OrganTypeResource:
	_ensure_index()
	return _index.get(id, null)


## Tüm organ tanımlarını döner.
func get_all_organs() -> Array[OrganTypeResource]:
	return organs


## Registry veri bütünlüğünü doğrular.
## Hata durumunda push_warning çağırır ve false döner.
## Oyun başlangıcında (Autoload._ready veya test setup) çağrılmalı.
func valid_registry() -> bool:
	var seen_ids: Dictionary = {}

	for organ: OrganTypeResource in organs:
		if not organ.is_valid():
			push_warning(
				"OrganTypeRegistry: '%s' geçersiz — zorunlu alan boş." % organ.organ_id
			)
			return false

		if seen_ids.has(organ.organ_id):
			push_warning(
				"OrganTypeRegistry: '%s' ID'si birden fazla organda kullanılıyor." % organ.organ_id
			)
			return false

		seen_ids[organ.organ_id] = true

	return true


func _ensure_index() -> void:
	if _index.is_empty() and not organs.is_empty():
		_build_index()


func _build_index() -> void:
	_index.clear()
	for organ: OrganTypeResource in organs:
		_index[organ.organ_id] = organ
