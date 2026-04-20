# Sprint 01 — Foundation Systems
> **Status**: Active  
> **Start**: 2026-04-20  
> **End**: 2026-05-03 (2 weeks)  
> **Goal**: Puzzle kuralları çalışıyor — herhangi bir puzzle yüklenebilir, evaluate edilebilir, sonuç NONE/ORGAN/STRUCTURAL olarak dönebilir.

---

## Sprint Goal (Definition of Done)

Bir GUT test suite'i şunu doğrular:
- Verilen bir `PuzzleResource` + `CreatureTypeResource` + `OrganTypeRegistry` üçlüsü
- `PuzzleInstance` runtime state'ine yüklenir
- `BiologyRuleEngine.evaluate()` çağrısı doğru `EvaluationResult` döner
- `FailureCascadeSystem.resolve()` bunu doğru `FailureCascadeResult`'a çevirir
- Aynı input → her zaman aynı output (determinizm garantisi)

Görsel yok. Sahne yok. Testler yeşil, logic doğru.

---

## Systems In Scope

| # | Sistem | GDD | Öncelik | Tahmini Efor | Bağımlılık |
|---|--------|-----|---------|--------------|------------|
| 1 | **Organ Type Registry** | `organ-type-registry.md` | P0 | 0.5 gün | — |
| 2 | **Creature Definition System** | `creature-definition-system.md` | P0 | 1 gün | Organ Registry |
| 3 | **Puzzle Data System** | `puzzle-data-system.md` | P0 | 1.5 gün | Creature Def |
| 4 | **Biology Rule Engine** | `biology-rule-engine.md` | P0 | 3 gün | Organ Registry + Creature Def |
| 5 | **Failure Cascade System** | `failure-cascade-system.md` | P0 | 1 gün | Biology Rule Engine |
| 6 | **GUT test suite (Foundation)** | — | P0 | 1.5 gün | Tüm yukarıdakiler |

**Toplam tahmini:** ~8.5 gün (2 haftalık sprint'te buffer var — ilk implementation sprint'i)

---

## Out of Scope (Sprint 02+)

- Touch Input Handler
- Organ Repair Mechanic
- Specimen Viewer
- Run Simulation Controller
- Run Sequence VFX
- Puzzle HUD
- Screen Navigation
- Save/Load System

---

## Task Breakdown

### T01 — Organ Type Registry
**Dosya:** `src/systems/organ_type_registry.gd`  
**Kaynak:** `assets/data/organs.tres` (OrganTypeRegistry resource)  
**Çıktı:**
- `OrganTypeRegistry` Resource subclass
- `get_organ(id: String) -> OrganTypeData` metodu
- `OrganTypeData`: `organ_id`, `display_name`, `role` (enum: EMITTER/GATE/SPLITTER/TERMINUS), `output_channels` Array[String]
- `organs.tres` içinde 4 organ tanımı: vordex, valdris, thrennic, ossuric

**Acceptance:**
- [ ] `registry.get_organ("vordex").role == OrganTypeData.Role.EMITTER`
- [ ] Bilinmeyen `organ_id` → `null` döner, crash olmaz

---

### T02 — Creature Definition System
**Dosya:** `src/systems/creature_definition_system.gd`  
**Kaynak:** `assets/data/creatures/creature_xenith_01.tres`  
**Çıktı:**
- `CreatureTypeResource` Resource subclass
- `creature_type_id`, `display_name`, `healthy_configuration: Array[String]` (4 slot, her biri organ_id)
- `slot_count: int` (MVP = 4)
- `get_healthy_configuration() -> Array[String]`

**Acceptance:**
- [ ] `creature.healthy_configuration.size() == 4`
- [ ] Her slot değeri `organ_type_registry`'de geçerli bir id

---

### T03 — Puzzle Data System
**Dosya:** `src/systems/puzzle_data_system.gd`  
**Kaynaklar:** `assets/data/puzzles/puzzle_01.tres` ... `puzzle_10.tres`  
**Çıktı:**
- `PuzzleResource`: `puzzle_index`, `display_title`, `creature_type_id`, `starting_configuration`, `hint_slot_index`
- `PuzzleInstance` (runtime, not a Resource): `current_configuration`, `attempt_count`, `is_solved`
- `PuzzleDataSystem`: `load_puzzle(index)`, `set_organ(slot, organ_id)`, `get_current_configuration()`, `get_attempt_count()`
- `valid_puzzle()` validator: tam olarak 1 slot, healthy config'den farklı

**Acceptance:**
- [ ] `load_puzzle(1)` → geçerli `PuzzleInstance` döner
- [ ] `set_organ(0, "valdris")` → `current_configuration[0] == "valdris"`
- [ ] `valid_puzzle()` 0 veya 2+ fark olan puzzle'da `false` döner

---

### T04 — Biology Rule Engine
**Dosya:** `src/systems/biology_rule_engine.gd`  
**Çıktı:**
- `BiologyContext` (value object): `configuration`, `creature`, `registry`
- `EvaluationResult`: `is_healthy: bool`, `wrong_slots: Array[int]`, `wrong_organs: Array[String]`
- `BiologyRuleEngine.evaluate(ctx: BiologyContext) -> EvaluationResult`
- **Stateless pure function** — aynı input → aynı output, internal state yok

**Acceptance:**
- [ ] Tüm doğru organlar → `is_healthy == true`, `wrong_slots.is_empty()`
- [ ] 1 yanlış organ → `wrong_slots.size() == 1`
- [ ] 4 yanlış organ → `wrong_slots.size() == 4`
- [ ] Farklı sırayla aynı konfigürasyon → aynı sonuç (determinizm)
- [ ] `evaluate()` instance state değiştirmez

---

### T05 — Failure Cascade System
**Dosya:** `src/systems/failure_cascade_system.gd`  
**Çıktı:**
- `FailureCascadeResult`: `failure_type` (enum: NONE/ORGAN/STRUCTURAL), `failed_organs: Array[String]`, `structural_code: String`
- `FailureCascadeSystem.resolve(result: EvaluationResult) -> FailureCascadeResult`
- Eşik: `wrong_slots.size() >= 3` → STRUCTURAL; 1-2 → ORGAN; 0 → NONE

**Acceptance:**
- [ ] 0 yanlış → `NONE`
- [ ] 1 yanlış → `ORGAN`, `failed_organs.size() == 1`
- [ ] 2 yanlış → `ORGAN`, `failed_organs.size() == 2`
- [ ] 3 yanlış → `STRUCTURAL`
- [ ] 4 yanlış → `STRUCTURAL`
- [ ] Tüm başarısızlıklar aynı anda — sequential cascade yok

---

### T06 — GUT Test Suite
**Dosya:** `tests/unit/test_foundation_systems.gd`  
**Kapsam:** T01–T05 tüm acceptance kriterleri otomatik test olarak

**Acceptance:**
- [ ] `gut -gtest=tests/unit/test_foundation_systems.gd` → 0 failure
- [ ] Determinizm testi: aynı input 100 kez çalıştır → her seferinde aynı output

---

## File Map (Sprint Çıktısı)

```
src/
  systems/
    organ_type_registry.gd
    creature_definition_system.gd
    puzzle_data_system.gd
    biology_rule_engine.gd
    failure_cascade_system.gd
assets/
  data/
    organs.tres
    creatures/
      creature_xenith_01.tres
    puzzles/
      puzzle_01.tres
      ...
      puzzle_10.tres
tests/
  unit/
    test_foundation_systems.gd
```

---

## Risks

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| Biology Rule Engine topological sort beklenenden karmaşık | Orta | Yüksek | MVP'de basit "slot index karşılaştırma" ile başla; gerçek graph traversal Sprint 02'ye taşı |
| `.tres` dosya formatı için Godot 4.6 Resource subclass API'si | Düşük | Orta | `@export` annotation kullan, `ResourceSaver.save()` test et |
| GUT kurulumu yoksa test pipeline çalışmaz | Düşük | Düşük | Proje addons/gut klasörü yoksa önce install et |

---

## Sprint 02 Preview (Bilgi için)

Sprint 02 — Interaction Layer: Touch Input Handler + Organ Repair Mechanic + Run Simulation Controller. Sprint 01 foundation'ı kullanır, ilk kez tıklanabilir prototype ortaya çıkar.
