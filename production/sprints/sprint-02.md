# Sprint 02 — Interaction Layer
> **Status**: Complete
> **Start**: 2026-04-20
> **End**: 2026-05-03 (2 weeks)
> **Goal**: İlk tıklanabilir prototype: oyuncu bir slota dokunur, envanterden organ seçer, RUN'a basar — sistem evaluate eder ve sonuç üretir. Görsel animasyon yok (Sprint 03), ama tüm mantık ve sinyal akışı çalışıyor.

---

## Sprint Goal (Definition of Done)

Bir GUT test suite'i şunu doğrular:
- `slot_tapped(0)` → `OrganRepairMechanic` slot 0'ı seçer
- `inventory_tapped("vordex")` → `PuzzleDataSystem.set_organ()` çağrılır
- `run_tapped()` → `BiologyRuleEngine.evaluate()` + `FailureCascadeSystem.resolve()` çağrılır
- `FailureCascadeResult` doğru türde döner
- RUN sırasında tekrar `run_tapped()` → yutulur
- Tüm akış deterministik

Görsel animasyon yok. Specimen Viewer stub. RunSequenceVFX stub.

---

## Bağımlılık Analizi ve Kapsam Kararları

Sprint 02'nin üç ana sistemi (TouchInputHandler, OrganRepairMechanic, RunSimulationController) Specimen Viewer, RunSequenceVFX ve Screen Navigation'a bağımlı — bunların hepsi Sprint 03+.

**Çözüm: Signal-first tasarım + minimal stub'lar**

| Eksik sistem | Sprint 02 yaklaşımı |
|---|---|
| SpecimenViewer | `OrganRepairMechanic` `set_slot_selected()` yerine `slot_selected(index)` / `slot_deselected(index)` signal'i emit eder. Viewer bu signal'e bağlanır (Sprint 03). |
| RunSequenceVFX | `RunSimulationController` `vfx_play_requested(result)` signal'i emit eder. Test stub'ı anında `vfx_complete` döner. |
| ScreenNavigation | `RunSimulationController` `puzzle_solved(next_index)` signal'i emit eder. Sprint 03'te Screen Navigation bağlanır. |
| PuzzleDataSystem.mark_solved() | `active_instance.check_solved()` delegasyonu — T10'da PuzzleDataSystem'e eklenir. |

---

## Systems In Scope

| # | Sistem | GDD | Öncelik | Tahmini Efor | Bağımlılık |
|---|--------|-----|---------|--------------|------------|
| 7 | **Touch Input Handler** | `touch-input-handler.md` | P0 | 1 gün | — |
| 8 | **Organ Repair Mechanic** | `organ-repair-mechanic.md` | P0 | 1.5 gün | TouchInputHandler + PuzzleDataSystem |
| 9 | **Run Simulation Controller** | `run-simulation-controller.md` | P0 | 2 gün | OrganRepairMechanic + BiologyRuleEngine + FailureCascadeSystem + PuzzleDataSystem |
| 10 | **PuzzleDataSystem extension** | — | P0 | 0.5 gün | PuzzleDataSystem (T03) |
| 11 | **GUT test suite (Interaction)** | — | P0 | 1.5 gün | T07–T10 |

**Toplam tahmini:** ~6.5 gün

---

## Out of Scope (Sprint 03+)

- Specimen Viewer (görsel, slot highlight)
- Puzzle HUD (envanter UI, RUN butonu)
- Run Sequence VFX (animasyon)
- Screen Navigation (puzzle geçişi)
- Save/Load System

---

## Task Breakdown

### T07 — Touch Input Handler
**Dosya:** `src/systems/touch_input_handler.gd`
**Çıktı:**
- `TouchAreaType` enum: `SLOT`, `INVENTORY`, `RUN_BUTTON`, `GENERIC`
- `TouchArea` iç veri yapısı: `id: String`, `rect: Rect2`, `type: TouchAreaType`, `payload: Variant`
- `register_area(id, rect, type, payload)` / `unregister_area(id)`
- `lock_input()` / `unlock_input()`
- State machine: `IDLE` → `TOUCHING` → `IDLE` / `LOCKED`
- Signals: `slot_tapped(slot_index: int)`, `inventory_tapped(organ_id: String)`, `run_tapped()`
- Constants (export): `TAP_MAX_DURATION_MS = 200`, `TAP_MAX_DELTA_PX = 10`, `MIN_TOUCH_AREA = 48`

**Test yaklaşımı:** GUT içinde `_input()` doğrudan çağrılarak `InputEventScreenTouch` simüle edilir.

**Acceptance:**
- [x] `register_area()` → alan kayıtlı; aynı `id` tekrar kaydedilirse üzerine yazar
- [x] Kayıtlı alan 48×48px altındaysa `push_warning()` ve alan MIN_TOUCH_AREA'ya büyütülür
- [x] SLOT alanına tap (≤200ms, ≤10px) → `slot_tapped(correct_index)`
- [x] INVENTORY alanına tap → `inventory_tapped(correct_organ_id)`
- [x] RUN_BUTTON alanına tap → `run_tapped()`
- [x] `lock_input()` → LOCKED; tap'ler yutulur, sinyal gönderilmez
- [x] `unlock_input()` → IDLE; tap'ler normal işlenir
- [x] 200ms üzeri basma → tap tanınmaz
- [x] 10px üzeri hareket → tap tanınmaz
- [x] Alan dışı tap → sinyal gönderilmez

---

### T08 — Organ Repair Mechanic
**Dosya:** `src/systems/organ_repair_mechanic.gd`
**Çıktı:**
- State machine: `IDLE`, `SLOT_SELECTED`, `LOCKED`, `LOCKED_PRE_ATT`
- `setup(puzzle_instance: PuzzleInstance)` initialization metodu
- `lock()` / `unlock()`
- `on_attempt_completed()` — ossuric kilidini açar
- Signals: `slot_selected(slot_index: int)`, `slot_deselected(slot_index: int)`, `organ_placed(slot_index: int, organ_id: String)`
- TouchInputHandler signal bağlantıları: `slot_tapped` → `_on_slot_tapped()`, `inventory_tapped` → `_on_inventory_tapped()`

**LOCKED_PRE_ATT kuralı:**
- Puzzle yüklenince `ossuric` için `LOCKED_PRE_ATT` aktif
- `inventory_tapped("ossuric")` bu durumdayken yutulur
- `on_attempt_completed()` → kilit kalkar, tek yönlü

**Acceptance:**
- [x] `slot_tapped(0)` → `slot_selected(0)` emit edilir
- [x] Aynı slota tekrar tap → `slot_deselected(0)` emit edilir
- [x] Farklı slota tap (seçiliyken) → eski slot deselect, yeni slot select
- [x] `inventory_tapped("vordex")` (slot seçiliyken) → `PuzzleInstance.set_organ()` çağrılır, `organ_placed` emit edilir, seçim sıfırlanır
- [x] `inventory_tapped` (slot seçili değilken) → yutulur
- [x] `lock()` → LOCKED; her tap yutulur
- [x] `unlock()` → önceki duruma döner
- [x] Puzzle yüklenince `inventory_tapped("ossuric")` → yutulur (LOCKED_PRE_ATT)
- [x] `on_attempt_completed()` → ossuric kilidi kalkar; sonraki `inventory_tapped("ossuric")` işlenir
- [x] `attempt_count >= 1` ile kurulan mechanic → ossuric başlangıçta açık

---

### T09 — Run Simulation Controller
**Dosya:** `src/systems/run_simulation_controller.gd`
**Çıktı:**
- State machine: `IDLE`, `EVALUATING`, `ANIMATING`, `SOLVED`
- `setup(puzzle_instance, creature, registry)` — bağımlılık injection
- VFX timeout: 5000ms (`SceneTreeTimer`)
- Signals:
  - `vfx_play_requested(cascade_result: FailureCascadeResult)` — VFX bu signal'e bağlanır
  - `puzzle_solved(next_puzzle_index: int)` — Screen Navigation bağlanır
  - `attempt_completed()` — OrganRepairMechanic bağlanır (ossuric kilidi için)
- `connect_vfx(vfx_node: Node)` — `vfx_complete` signal'ini vfx_node'a bağlar

**Test VFX stub:** Testlerde `_TestVFXStub` inner class, `vfx_play_requested` alınca anında `vfx_complete` emit eder.

**Acceptance:**
- [x] `run_tapped()` → `PuzzleInstance.increment_attempts()`, `BiologyRuleEngine.evaluate()`, `FailureCascadeSystem.resolve()` sırayla çağrılır
- [x] `vfx_play_requested(result)` emit edilir; tür = cascade result türü
- [x] `vfx_complete` alınınca IDLE'a döner, `unlock()` emit edilir
- [x] Başarılı RUN → `PuzzleInstance.check_solved()` true döner, `puzzle_solved(next_index)` emit edilir
- [x] `run_tapped()` ANIMATING durumunda → yutulur
- [x] `attempt_completed()` signal'i emit edilir → OrganRepairMechanic ossuric kilidini açabilir
- [x] VFX 5 saniye içinde `vfx_complete` göndermezse → zorla `IDLE`'a döner
- [x] Aynı konfigürasyonla iki RUN → aynı `cascade_result.failure_type` (determinizm)

---

### T10 — PuzzleDataSystem Extension
**Dosya:** `src/systems/puzzle_data_system.gd` (mevcut dosyaya ekleme)
**Çıktı:**
- `mark_solved() -> void` — `active_instance.check_solved()` delegasyonu; null guard
- `increment_attempts() -> void` — `active_instance.increment_attempts()` delegasyonu; null guard

**Acceptance:**
- [x] `mark_solved()` → `active_instance.is_solved == true`, `puzzle_solved` signal emit edilir
- [x] `mark_solved()` null active_instance'ta → `push_warning()`, crash yok
- [x] `increment_attempts()` → `active_instance.attempt_count` artar
- [x] Mevcut 85 test hâlâ geçiyor

---

### T11 — Interaction Integration Tests
**Dosya:** `tests/unit/test_interaction_integration.gd`
**Kapsam:** T07–T10 tam signal akışı; determinizm

**Acceptance:**
- [x] tap → seçim → yerleştirme → RUN tam zinciri test ediliyor
- [x] LOCKED_PRE_ATT → attempt → kilit açılma test ediliyor
- [x] RUN sırasında ikinci `run_tapped()` → yutulur test ediliyor
- [x] Tüm testler geçiyor (`gut -gdir=res://tests/unit` → 0 failure)

---

## File Map (Sprint Çıktısı)

```
src/
  systems/
    touch_input_handler.gd          (yeni)
    organ_repair_mechanic.gd        (yeni)
    run_simulation_controller.gd    (yeni)
    puzzle_data_system.gd           (genişletildi: mark_solved, increment_attempts)
tests/
  unit/
    test_touch_input_handler.gd     (yeni)
    test_organ_repair_mechanic.gd   (yeni)
    test_run_simulation_controller.gd (yeni)
    test_interaction_integration.gd (yeni)
```

---

## Risks

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| GUT içinde `_input()` simülasyonu — Godot 4.6'da Node olmayan test sınıflarında input event tetiklemek güç olabilir | Orta | Orta | TouchInputHandler'ı test edilebilir hale getirmek için `_process_touch_event(event)` public metodu ekle; testler bunu doğrudan çağırır |
| `SceneTreeTimer` gerektiren VFX timeout GUT'ta test edilemez | Düşük | Düşük | Timeout mantığını ayrı `_on_vfx_timeout()` metoduna çıkar; testlerde doğrudan çağrılabilir |
| OrganRepairMechanic `attempt_count` okumak için PuzzleInstance'a doğrudan erişiyor — bu tight coupling | Düşük | Orta | `setup()` metodu PuzzleInstance referansı alır; mock PuzzleInstance testte kullanılır |
| Sprint 03'te SpecimenViewer signal'lere bağlanırken sinyal isimlerinde uyumsuzluk | Düşük | Düşük | Signal isimleri GDD'den alınmış; değişirse T08'de tek yerde güncellenir |

---

## Review Model Notu (Retrospektif)

Sprint 02'de tüm code review'lar `lead-programmer` tarafından yapıldı (7 çağrı, ~182K token).
Sprint 03'ten itibaren **üç katmanlı review modeli** uygulanacak:
- Tier 1 (GDScript kalitesi): `godot-gdscript-specialist`
- Tier 2 (gameplay doğruluğu): `gameplay-programmer`
- Tier 3 (mimari): `lead-programmer` — sprint başına tek sefer

Detay: `.claude/docs/review-delegation.md`

---

## Sprint 03 Preview (Bilgi için)

Sprint 03 — Visual Layer: Specimen Viewer (slot görseli, selection highlight) + Puzzle HUD (envanter UI, RUN butonu) + Run Sequence VFX (animasyon). Sprint 02 signal'lerine bağlanır — logic değişmez.
