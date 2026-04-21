# Sprint 03 — Visual Layer
> **Status**: Complete
> **Start**: 2026-04-21
> **End**: 2026-05-04 (2 weeks)
> **Closed**: 2026-05-05
> **Gate**: ONAYLANDI — lead-programmer gate-check geçti. Tek açık: `puzzle_solved→ScreenNavigation` wire → T17 (Sprint 04)
> **Goal**: İlk görsel prototype: oyuncu creature'ı ekranda görür, organ slotlarına dokunur, RUN'a basar — animasyon oynar ve sonuç görsel olarak iletilir. Sprint 02 logic layer üzerine görsel katman eklenir; mantık değişmez.

---

## Sprint Goal (Definition of Done)

Bir GUT test suite'i şunu doğrular:
- `load_creature()` → SpecimenViewer slotları doğru pozisyona yerleştirir, touch alanlarını kaydeder
- `organ_placed` sinyali → SpecimenViewer slot görselini günceller
- `slot_selected(0)` → SpecimenViewer slot 0 seçili duruma geçer
- `run_tapped()` → RunSequenceVFX doğru sekansı çalıştırır, `vfx_complete` döner
- PuzzleHUD envanter kartları `inventory_tapped(organ_id)` sinyali gönderir
- `go_to_next_puzzle()` → ScreenNavigation geçiş akışını tetikler
- Tüm akış deterministik ve Sprint 02 sinyallerine geri uyumlu

---

## Review Delegation (Yeni Model)

> Detay: `.claude/docs/review-delegation.md`

| Task | İmplementasyon | Review | Tier |
|------|----------------|--------|------|
| T12 SpecimenViewer | `godot-gdscript-specialist` | `godot-gdscript-specialist` | 1 |
| T13 PuzzleHUD | `godot-gdscript-specialist` | `gameplay-programmer` | 2 |
| T14 RunSequenceVFX | `godot-gdscript-specialist` | `gameplay-programmer` | 2 |
| T15 ScreenNavigation | `godot-gdscript-specialist` | `gameplay-programmer` | 2 |
| T16 Integration Tests | main agent | `gameplay-programmer` | 2 |
| Sprint gate | — | `lead-programmer` | 3 |

---

## Bağımlılık Analizi

Sprint 03 sistemleri Sprint 02 sinyal sözleşmelerine bağlanır:

| Bağlantı | Sprint 02 signal | Sprint 03 alıcı |
|----------|-----------------|-----------------|
| Slot seçimi görseli | `OrganRepairMechanic.slot_selected(i)` | `SpecimenViewer.set_slot_selected(i, true)` |
| Slot bırakma görseli | `OrganRepairMechanic.slot_deselected(i)` | `SpecimenViewer.set_slot_selected(i, false)` |
| Organ yerleşimi görseli | `PuzzleInstance.organ_placed(i, id)` | `SpecimenViewer.refresh_slots()` |
| VFX tetikleme | `RunSimulationController.vfx_play_requested(result)` | `RunSequenceVFX.handle_play(result)` |
| UI kilidi | `RunSimulationController.locked()` | `SpecimenViewer.lock_interaction()`, `PuzzleHUD.lock()` |
| UI kilidi açma | `RunSimulationController.unlocked()` | `SpecimenViewer.unlock_interaction()`, `PuzzleHUD.unlock()` |
| Bulmaca geçişi | `RunSimulationController.puzzle_solved(next)` | `ScreenNavigation.go_to_puzzle(next)` |

---

## Systems In Scope

| # | Sistem | GDD | Öncelik | Tahmini Efor |
|---|--------|-----|---------|--------------|
| 12 | **SpecimenViewer** | `specimen-viewer.md` | P0 | 2 gün |
| 13 | **PuzzleHUD** | `puzzle-hud.md` | P0 | 1.5 gün |
| 14 | **RunSequenceVFX** | `run-sequence-vfx.md` | P0 | 1.5 gün |
| 15 | **ScreenNavigation** | `screen-navigation.md` | P0 | 1 gün |
| 16 | **Visual Layer Integration Tests** | — | P0 | 1.5 gün |

**Toplam tahmini:** ~7.5 gün

---

## MVP Görsel Yaklaşımı

Gerçek sprite asset'leri yok → placeholder görsel stratejisi:

| Bileşen | MVP Görsel |
|---------|-----------|
| Creature silüeti | `ColorRect` (koyu gri, creature boyutunda) |
| Organ slot (normal) | `ColorRect` (organ rengi, 80×80px) |
| Organ slot (hasarlı) | `ColorRect` (kırmızı tint, 80×80px) |
| Organ slot (seçili) | Sarı kenarlık (`draw_rect` stroke) |
| Kanal çizgileri | `draw_line` (mavi PULSE, yeşil FLUID) |
| Envanter kartı | `ColorRect` + `Label` |
| RUN butonu | `Button` node |
| VFX başarı | `ColorRect` modulation yeşil |
| VFX başarısızlık | `ColorRect` modulation kırmızı |
| VFX yapısal | `ColorRect` overlay + `Label` |

---

## Out of Scope (Sprint 04+)

- Gerçek sprite asset'leri (silüet, organ görselleri)
- Ses efektleri
- Animasyonlu kanal çizgileri
- Ekran geçiş efektleri (fade)
- Kaydet/yükle sistemi

---

## Task Breakdown

### T12 — SpecimenViewer
**Dosya:** `src/systems/specimen_viewer.gd`
**Implementasyon:** `godot-gdscript-specialist`
**Review:** `godot-gdscript-specialist`

**Çıktı:**
- `extends Node2D`
- State machine: `EMPTY`, `ACTIVE`, `LOCKED`
- `setup(p_creature, p_registry, p_handler, p_puzzle_instance)` — bağımlılık injection
- `load_creature()` — placeholder ColorRect + draw_line çizer, touch alanları kaydeder
- `refresh_slots(current_config, healthy_config)` — hasar durumunu günceller
- `set_slot_selected(slot_index, selected)` — sarı çerçeve açar/kapatır
- `lock_interaction()` / `unlock_interaction()`
- `_draw()` — kanal çizgileri (PULSE: mavi, FLUID: yeşil)

**Test:** `tests/unit/test_specimen_viewer.gd`

**Acceptance:**
- [ ] `load_creature()` → 4 slot doğru pozisyonda, touch alanları kayıtlı
- [ ] `refresh_slots()` hasarlı slot → "hasar" durumu işaretlenir
- [ ] `set_slot_selected(0, true)` → slot 0 seçili; `false` → seçim kalkar
- [ ] `lock_interaction()` → LOCKED; `unlock_interaction()` → ACTIVE
- [ ] `organ_placed` sinyali → `refresh_slots()` tetiklenir
- [ ] `sprite_normal` null → placeholder görünür, crash yok
- [ ] Slot pozisyonu ekran dışı → clamp çalışır

---

### T13 — PuzzleHUD
**Dosya:** `src/systems/puzzle_hud.gd`
**Implementasyon:** `godot-gdscript-specialist`
**Review:** `gameplay-programmer`

**Çıktı:**
- `extends CanvasLayer`
- `setup(p_registry, p_handler, p_puzzle_instance)` — bağımlılık injection
- `load_puzzle(p_puzzle_resource)` — başlık, deneme sayacı
- Envanter kartları (4 kart, 2×2 grid, ColorRect + Label)
- RUN butonu (Godot `Button` node)
- `lock()` / `unlock()` — görsel alpha + touch handler lock
- `show_result(is_success)` — başarı/başarısızlık mesajı

**Sinyal bağlantıları:**
- Touch Handler'a envanter ve RUN alanları kaydeder
- `RunSimulationController.attempt_completed` → deneme sayacı güncellenir

**Test:** `tests/unit/test_puzzle_hud.gd`

**Acceptance:**
- [ ] `load_puzzle()` → başlık ve numara doğru gösterilir
- [ ] Envanter kartı tap → `inventory_tapped(organ_id)` sinyali gönderilir
- [ ] RUN tap → `run_tapped()` sinyali gönderilir
- [ ] `lock()` → RUN + envanter alpha 0.5; `unlock()` → normale döner
- [ ] `puzzle_solved` → başarı mesajı görünür
- [ ] Tüm touch alanları ≥ 48×48px

---

### T14 — RunSequenceVFX
**Dosya:** `src/systems/run_sequence_vfx.gd`
**Implementasyon:** `godot-gdscript-specialist`
**Review:** `gameplay-programmer`

**Çıktı:**
- `extends Node`
- State machine: `IDLE`, `PLAYING`
- `handle_play(result: FailureCascadeResult)` — RSC sinyaline bağlanır (mevcut duck-type arayüzü korunur)
  - `NONE` → `_play_success()`
  - `ORGAN` → `_play_organ_failure(result.failed_organs)`
  - `STRUCTURAL` → `_play_structural_failure(result.structural_code)`
- `signal vfx_complete` — animasyon bitti
- Tween tabanlı animasyonlar (ColorRect modulation, MVP)
- `@export var cascade_stagger_ms: float = 180.0` — tuning knob

**Test:** `tests/unit/test_run_sequence_vfx.gd`

**Acceptance:**
- [ ] `handle_play(NONE result)` → ~2.0s sonra `vfx_complete` emit edilir
- [ ] `handle_play(ORGAN result)` → ~1.5s sonra `vfx_complete` emit edilir
- [ ] `handle_play(STRUCTURAL result)` → ~2.5s sonra `vfx_complete` emit edilir
- [ ] `PLAYING` sırasında ikinci `handle_play()` → yutulur
- [ ] `vfx_complete` GUT içinde `notify_vfx_complete()` test seam ile doğrulanır

---

### T15 — ScreenNavigation
**Dosya:** `src/systems/screen_navigation.gd`
**Implementasyon:** `godot-gdscript-specialist`
**Review:** `gameplay-programmer`

**Çıktı:**
- `extends Node`
- State machine: `IDLE`, `TRANSITIONING`
- `go_to_puzzle(puzzle_index: int)` — bulmaca geçişi
- `go_to_next_puzzle()` — `current_index + 1`; son ise `go_to("end_screen")`
- `go_to(screen_id: String)` — genel geçiş
- Geçiş sırasında ikinci `go_to()` → yutulur
- `@export var fade_duration_sec: float = 0.2` — tuning knob
- MVP: sahne yok, sinyal bazlı (`scene_change_requested(path, params)` emit eder)

**Test:** `tests/unit/test_screen_navigation.gd`

**Acceptance:**
- [ ] `go_to_puzzle(1)` → `scene_change_requested` doğru path ile emit edilir
- [ ] `go_to_next_puzzle()` last puzzle → `end_screen` sinyali
- [ ] Geçiş sırasında ikinci `go_to()` → yutulur
- [ ] Geçersiz screen_id → `push_warning()`, `main_menu`'ye düşer

---

### T16 — Visual Layer Integration Tests
**Dosya:** `tests/unit/test_visual_layer_integration.gd`
**Implementasyon:** main agent
**Review:** `gameplay-programmer`

**Kapsam:** T12–T15 tam sinyal akışı + Sprint 02 retrouyumluluk

**Acceptance:**
- [ ] SpecimenViewer + OrganRepairMechanic: slot_tapped → görsel seçim
- [ ] SpecimenViewer + PuzzleInstance: organ_placed → görsel güncelleme
- [ ] RunSequenceVFX + RunSimulationController: vfx_play_requested → vfx_complete tam döngüsü
- [ ] PuzzleHUD + TouchInputHandler: tüm dokunma alanları çalışır
- [ ] Sprint 02 testi: mevcut 134 test hâlâ geçiyor (regresyon yok)

---

## File Map (Sprint Çıktısı)

```
src/
  systems/
    specimen_viewer.gd          (yeni)
    puzzle_hud.gd               (yeni)
    run_sequence_vfx.gd         (yeni)
    screen_navigation.gd        (yeni)
tests/
  unit/
    test_specimen_viewer.gd     (yeni)
    test_puzzle_hud.gd          (yeni)
    test_run_sequence_vfx.gd    (yeni)
    test_screen_navigation.gd   (yeni)
    test_visual_layer_integration.gd (yeni)
```

---

## Risks

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| `_draw()` GUT içinde test edilemez | Yüksek | Düşük | Logic test et, render test etme; sadece durum (state/config) doğrula |
| Tween GUT içinde gerçek zamanla çalışır | Orta | Orta | `vfx_complete` için `notify_*` test seam ekle; animasyon süresini 0'a yakın set et |
| CanvasLayer child node yönetimi karmaşıklaşabilir | Orta | Orta | PuzzleHUD setup'ını iki aşamalı yap: `_ready()` node'ları oluşturur, `setup()` veriyi bağlar |
| ScreenNavigation gerçek sahne yüklemeyi gerektirir | Yüksek | Düşük | Signal-first: `scene_change_requested` emit eder; gerçek yükleme Puzzle.tscn'de |

---

## Sprint 04 Preview

Sprint 04 — First Playable: Gerçek sahne dosyaları (Puzzle.tscn, MainMenu.tscn), save/load sistemi, tüm sistemlerin birbirine bağlandığı ilk oynanabilir build.
