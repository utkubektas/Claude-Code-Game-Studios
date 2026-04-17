# Run Simulation Controller

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: The Run Button Moment; Mastery Is Earned, Not Given

## Overview

Run Simulation Controller, oyuncunun RUN butonuna basmasından sonra gerçekleşen tüm akışı yöneten orkestratördür. Sırasıyla şunları yapar: tüm sistemlere input kilidi gönderir; Puzzle Data System'den güncel organ konfigürasyonunu alır; Biology Rule Engine'i çalıştırır; Failure Cascade System'e sonucu iletir; `FailureCascadeResult`'a göre Run Sequence VFX'i tetikler; VFX bittikten sonra kilidi açar. Bulmaca çözüldüyse Puzzle Data System'i ve Screen Navigation'ı bilgilendirir. Sistem kendi başına hiçbir biyoloji kuralı değerlendirmez — yalnızca koordine eder.

## Player Fantasy

RUN'a basmak bir an durduruyor her şeyi. Sistem konuşmayı keser, organlar yanıp söner ya da aydınlanır. Oyuncu sadece izler — kontrol artık onda değil, creature'da. Bu an 2–3 saniye sürer ve oyunun en yoğun anıdır. Run Simulation Controller bu anın temposunu ve sırasını belirler; ne çok hızlı (anlam taşımaz) ne çok yavaş (can sıkar) olmalıdır.

## Detailed Design

### Core Rules

**RUN akışı (sıralı, senkron başlar — VFX sonrası async):**

1. `run_tapped()` sinyali gelir (Touch Input Handler'dan)
2. Tüm sistemlere `lock()` gönderilir: Touch Input Handler, Organ Repair Mechanic, Specimen Viewer
3. `PuzzleDataSystem.increment_attempts()`
4. `EvaluationContext` oluşturulur: `current_configuration` + `slot_channels` + organ tip verileri
5. `BiologyRuleEngine.evaluate(context)` → `EvaluationResult`
6. `FailureCascadeSystem.process(eval_result)` → `FailureCascadeResult`
7. `FailureCascadeResult.failure_type`'a göre dallanır:
   - `NONE` → `RunSequenceVFX.play_success(slot_positions)`
   - `ORGAN` → `RunSequenceVFX.play_organ_failure(failed_slots)`
   - `STRUCTURAL` → `RunSequenceVFX.play_structural_failure(structural_code)`
8. VFX tamamlanma sinyali beklenir (`vfx_complete`)
9. `failure_type == NONE` ise: `PuzzleDataSystem.mark_solved()` → `puzzle_solved` sinyali → Screen Navigation
10. Tüm sistemlere `unlock()` gönderilir

**EvaluationContext yapısı:**

| Alan | Kaynak |
|------|--------|
| `organ_instances` | `PuzzleDataSystem.current_configuration` + `OrganTypeRegistry` |
| `channels` | `CreatureDefinitionSystem.slot_channels` |
| `creature_type_id` | `PuzzleDataSystem.puzzle_resource.creature_type_id` |

### States and Transitions

| Durum | Açıklama | Giriş | Çıkış |
|-------|----------|-------|-------|
| `IDLE` | RUN bekleniyor | Başlangıç / VFX tamamlandı | `run_tapped()` → `EVALUATING` |
| `EVALUATING` | Biology Rule Engine + Failure Cascade çalışıyor | `run_tapped()` | Sonuç hazır → `ANIMATING` |
| `ANIMATING` | VFX oynatılıyor, sistemler kilitli | `EVALUATING` tamamlandı | `vfx_complete` → `IDLE` (başarısız) veya `SOLVED` (başarılı) |
| `SOLVED` | Bulmaca çözüldü | `failure_type == NONE` + VFX tamamlandı | Screen Navigation yönlendirirse → `IDLE` (yeni bulmaca) |

### Interactions with Other Systems

| Sistem | Yön | Veri | Ne Zaman |
|--------|-----|------|----------|
| Touch Input Handler | Handler → Controller | `run_tapped()` | RUN butonuna basınca |
| Touch Input Handler | Controller → Handler | `lock()` / `unlock()` | RUN başında/sonunda |
| Organ Repair Mechanic | Controller → Mechanic | `lock()` / `unlock()` | RUN başında/sonunda |
| Specimen Viewer | Controller → Viewer | `lock_interaction()` / `unlock_interaction()` | RUN başında/sonunda |
| Puzzle Data System | Controller → PDS | `get_current_configuration()`, `increment_attempts()`, `mark_solved()` | RUN akışı boyunca |
| Creature Definition System | Controller → CDS | `get_creature(id).slot_channels` | `EvaluationContext` oluşturulurken |
| Biology Rule Engine | Controller → Engine | `evaluate(context) → EvaluationResult` | `EVALUATING` aşamasında |
| Failure Cascade System | Controller → Cascade | `process(eval_result) → FailureCascadeResult` | `EvaluationResult` gelince |
| Run Sequence VFX | Controller → VFX | `play_success()`, `play_organ_failure()`, `play_structural_failure()` | `ANIMATING` başında |
| Run Sequence VFX | VFX → Controller | `vfx_complete` sinyali | Animasyon bitince |
| Screen Navigation | Controller → Nav | `puzzle_solved(next_puzzle_index)` | `SOLVED` durumunda |

## Formulas

### F1 — EvaluationContext Oluşturma

```
build_context(puzzle, creature, registry) =
  EvaluationContext(
    organ_instances = [
      OrganInstance(
        slot_index = i,
        organ_type = registry.get_organ(puzzle.current_configuration[i]),
        connected_slots = creature.slot_channels
                            .filter(ch → ch.from_slot_index == i OR ch.to_slot_index == i)
      )
      FOR i IN puzzle.current_configuration.keys()
    ],
    channels = creature.slot_channels,
    creature_type_id = puzzle.creature_type_id
  )
```

### F2 — VFX Seçimi

```
select_vfx(result) =
  MATCH result.failure_type:
    NONE       → vfx.play_success(all_slot_positions)
    ORGAN      → vfx.play_organ_failure(result.failed_organs.map(r → slot_position(r.slot_index)))
    STRUCTURAL → vfx.play_structural_failure(result.structural_code)
```

## Edge Cases

| Senaryo | Beklenen Davranış | Gerekçe |
|---------|------------------|---------|
| `run_tapped()` `EVALUATING` veya `ANIMATING` durumunda | Yutulur — sistemler zaten kilitli | Çift RUN önlenir |
| Biology Rule Engine `ERROR` döndürürse | `STRUCTURAL` olarak işlenir, `structural_code = "ENGINE_ERROR"` | Oyun çökmez; hata loglanır |
| VFX `vfx_complete` hiç gönderemezse | 5 saniye timeout → zorla `unlock()`, `IDLE`'a dön | Askıda kalan sistemleri çözer |
| Bulmaca çözüldü ama sonraki bulmaca yok | `END_OF_SEQUENCE` → Screen Navigation bitiş akışını başlatır | Puzzle Data System F3 kuralı |
| `lock()` sonrası oyuncu uygulamayı arka plana alırsa | Durum korunur; ön plana dönünce VFX resume veya `unlock()` + sıfırlama | Platform yaşam döngüsü — Godot `_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)` ile ele alınır |

## Dependencies

| Sistem | Yön | Tür | Arayüz |
|--------|-----|-----|--------|
| Touch Input Handler | Handler → Controller | Hard | `run_tapped()` sinyali |
| Puzzle Data System | Controller → PDS | Hard | `get_current_configuration()`, `increment_attempts()`, `mark_solved()` |
| Creature Definition System | Controller → CDS | Hard | `get_creature(id).slot_channels` |
| Biology Rule Engine | Controller → Engine | Hard | `evaluate(context) → EvaluationResult` |
| Failure Cascade System | Controller → Cascade | Hard | `process(result) → FailureCascadeResult` |
| Run Sequence VFX | Controller → VFX | Hard | `play_success()`, `play_organ_failure()`, `play_structural_failure()`; `vfx_complete` sinyali |
| Organ Repair Mechanic | Controller → Mechanic | Hard | `lock()` / `unlock()` |
| Specimen Viewer | Controller → Viewer | Hard | `lock_interaction()` / `unlock_interaction()` |
| Screen Navigation | Controller → Nav | Hard | `puzzle_solved(next_index)` |

## Tuning Knobs

| Parametre | Mevcut Değer | Güvenli Aralık | Artınca | Azalınca |
|-----------|-------------|----------------|---------|---------|
| VFX timeout süresi | 5000ms | 3000–8000ms | Bozuk VFX daha uzun beklenir | Çok kısa; animasyon kesilir |
| `EVALUATING` → `ANIMATING` geçiş gecikmesi | 0ms (senkron) | 0–200ms | Küçük duraklama, daha dramatik | Anında — tercih edilen |

## Visual/Audio Requirements

Run Simulation Controller görsel üretmez — yalnızca VFX sistemine komut verir. Beklenen VFX davranışları Run Sequence VFX GDD'sinde tanımlanacaktır.

| `failure_type` | VFX Komutu | Tahmini Süre |
|----------------|------------|-------------|
| `NONE` | `play_success()` | ~2.0s |
| `ORGAN` | `play_organ_failure(failed_slots)` | ~1.5s |
| `STRUCTURAL` | `play_structural_failure(code)` | ~2.5s |

## UI Requirements

Run Simulation Controller doğrudan UI üretmez. RUN butonu Puzzle HUD'a aittir; butona basınca `run_tapped()` sinyali Touch Input Handler üzerinden gelir.

## Acceptance Criteria

- [ ] `run_tapped()` → tüm sistemler kilitlenir, Biology Rule Engine çağrılır
- [ ] `EvaluationResult` başarılı → `play_success()` çağrılır
- [ ] `EvaluationResult` organ başarısız → `play_organ_failure(correct_slots)` çağrılır
- [ ] `EvaluationResult` yapısal hata → `play_structural_failure(code)` çağrılır
- [ ] `vfx_complete` → tüm sistemler kilit açılır
- [ ] Başarılı RUN → `PuzzleDataSystem.mark_solved()` ve `puzzle_solved` sinyali
- [ ] `run_tapped()` `ANIMATING` durumunda → yutulur, ikinci RUN tetiklenmez
- [ ] VFX 5 saniye içinde `vfx_complete` göndermezse → zorla `unlock()`, sistem `IDLE`'a döner
- [ ] `evaluate()` aynı konfigürasyonla iki kez çağrıldığında aynı VFX dalına girer (determinizm)
- [ ] GUT testi: `TestRunSimulationController.gd` tüm dallanmaları mock VFX ile doğrular
