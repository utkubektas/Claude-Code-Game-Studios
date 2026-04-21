# Sprint 04 — First Playable
> **Status**: Active
> **Start**: 2026-05-05
> **End**: 2026-05-18 (2 weeks)
> **Goal**: Sprint 01–03'te kodlanan tüm sistemleri gerçek sahne dosyalarına bağla; tek bir xenith_01 bulmacası baştan sona oynanabilir hale gelsin; ilerleme kaydedilsin.

---

## Sprint Goal (Definition of Done)

Godot editörde çalıştırıldığında:
- MainMenu.tscn açılır
- Puzzle.tscn'e geçilir — xenith_01 creature görünür, slotlar tıklanabilir
- Organ yerleştir → RUN → VFX oynar → sonuç gösterilir
- Başarılı RUN → bir sonraki bulmacaya geçilir (ScreenNavigation)
- Oyun kapatılıp açıldığında kaldığı yerden devam eder (SaveLoadSystem)
- GUT testleri: `gut -gdir=res://tests/unit` → 0 failure

---

## Kapasite

- Toplam: 10 iş günü (2 hafta)
- Buffer (%20): 2 gün
- Kullanılabilir: **8 gün**

---

## Review Delegation

> Politika: `.claude/docs/token-budget.md` ve `.claude/docs/review-delegation.md`
> Token retro kural: maks 2 paralel review agent, < 200 satır = inline

| Task | İmplementasyon | Review | Tier | Yöntem |
|------|----------------|--------|------|--------|
| T17 GameFlowOrchestrator | `gameplay-programmer` | `gameplay-programmer` | 2 | inline (< 150 satır bekleniyor) |
| T18 SaveLoadSystem | `godot-gdscript-specialist` | inline | 1 | inline (< 150 satır bekleniyor) |
| T19 Puzzle.tscn wiring | main agent | inline | — | scene setup, review gereksiz |
| T20 Data dosyaları (.tres) | main agent | inline | — | data, code review gereksiz |
| T21 MainMenu.tscn | `godot-gdscript-specialist` | inline | 1 | minimal (< 80 satır) |
| T22 End-to-end tests | main agent | `gameplay-programmer` | 2 | agent (300+ satır bekleniyor) |
| T23 QA Lead test planı | `qa-lead` | — | — | 1 çağrı, sprint başında |
| T24 Art Director art bible | `art-director` | — | — | 1 çağrı, sprint başında |
| Sprint gate | — | `lead-programmer` | 3 | sprint sonu 1 kez |

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent | Est. Gün | Bağımlılık | Kabul Kriteri |
|----|------|-------|----------|------------|---------------|
| T17 | **GameFlowOrchestrator** | `gameplay-programmer` | 1.0 | Sprint 02-03 tüm sistemler | `puzzle_solved` → `ScreenNavigation.go_to_next_puzzle()` bağlı; `RunSimulationController.locked/unlocked` → HUD + Viewer bağlı; tüm signal wiring tek noktada |
| T18 | **SaveLoadSystem** | `godot-gdscript-specialist` | 1.0 | PuzzleDataSystem | `save()` → `user://save.json`; `load()` → current_puzzle_index; bozuk JSON → graceful reset; GUT tests geçiyor |
| T19 | **Puzzle.tscn** | main agent | 2.0 | T17, T18 | Godot editörde çalışır; tüm sistemler (SpecimenViewer, PuzzleHUD, RSC, VFX, ScreenNav, GameFlow) doğru parent/child hiyerarşisinde; xenith_01 creature render ediliyor |
| T20 | **Data dosyaları** (.tres) | main agent | 1.0 | Sprint 01 | `assets/data/creatures/xenith_01.tres`; `assets/data/puzzles/puzzle_001.tres` … `puzzle_010.tres`; 10 bulmaca, üç farklı başlangıç konfigürasyonu |
| T21 | **MainMenu.tscn** | `godot-gdscript-specialist` | 0.5 | T19 | "Başla" butonu → Puzzle.tscn geçişi; `scene_change_requested` signal kullanılıyor; sahne bağımsız test edilebilir |
| T22 | **End-to-end integration tests** | main agent | 1.5 | T17-T21 | Tam loop: menu → puzzle → RUN → result → next puzzle; save/load döngüsü; 0 failure |

**Must Have toplamı: 7.0 gün**

---

### Should Have

| ID | Task | Agent | Est. Gün | Bağımlılık | Kabul Kriteri |
|----|------|-------|----------|------------|---------------|
| T23 | **QA Lead — Test planı** | `qa-lead` | 0.5 | T22 | Test planı yazıldı: unit/integration/device test kategorileri, release gate kriterleri, test ortamı kurulumu (`production/qa/test-plan.md`) |
| T24 | **Art Director — Art bible** | `art-director` | 0.5 | T20 | Art bible iskelet oluşturuldu: renk paleti, organ görsel kuralları, silüet stili, font; Sprint 05 asset üretimine rehberlik eder (`design/art-bible.md`) |

**Should Have toplamı: 1.0 gün**

---

### Nice to Have

| ID | Task | Agent | Est. Gün | Bağımlılık | Kabul Kriteri |
|----|------|-------|----------|------------|---------------|
| T25 | **Audio Director — Ses paleti** | `audio-director` | 0.5 | T24 | Ses event listesi: slot_tap, organ_place, run_start, vfx_success, vfx_failure; `design/audio-palette.md` |
| T26 | **Device test** (Android fiziksel) | main agent | 0.5 | T19 | Godot Android export; dokunma doğru çalışıyor; touch area boyutları gerçek ekranda ≥ 48px |

**Nice to Have toplamı: 1.0 gün**

---

## Sprint 03'ten Taşınanlar

| Task | Neden taşındı | Yeni tahmin |
|------|--------------|-------------|
| T13/T14/T15 Tier-2 review (eksik) | Rate limit → 3/4 agent başarısız | Sprint 04 içinde inline olarak tamamlanacak (§1 kuralı uygulandı — T14: 155 satır, T15: 106 satır → inline) |
| `puzzle_solved → ScreenNavigation` wire | Kapsam dışı bırakıldı (Sprint 03 bilinçli karar) | T17 içinde çözülüyor (0.3 gün) |
| lead-programmer gate Sprint 03 | Sprint 04 başında yapıldı ✅ | Tamamlandı — geçiş onaylandı |

---

## Bağımlılık Haritası

```
T20 (data)──┐
            ├──► T19 (Puzzle.tscn) ──► T22 (e2e tests)
T17 (flow)──┤                              │
T18 (save)──┘                              ▼
T21 (menu)─────────────────────────► T23 (QA plan)
                                          T24 (art bible)
```

---

## Yeni Agentlar (İlk Kez Sprint 04)

| Agent | Görev | Zamanlama |
|-------|-------|-----------|
| `qa-lead` | Test planı + release gate kriterleri | T22 tamamlanınca |
| `art-director` | Art bible iskelet | T20 (data) tamamlanınca |
| `audio-director` | Ses event listesi (nice-to-have) | Art bible sonrası |

---

## Riskler

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| Puzzle.tscn'de node hiyerarşisi karmaşıklaşır | Orta | Yüksek | GameFlowOrchestrator single wiring point olarak tasarlandı; CanvasLayer vs Node2D parent ayrımı erkenden test edilmeli |
| SpecimenViewer `creature_anchor` koordinat kayması (gate-check bulgusu) | Orta | Orta | T19'da gerçek sahneye eklenince editörde görsel doğrulama yapılacak |
| RunSequenceVFX Control anchor parent bağımlılığı (gate-check bulgusu) | Düşük | Orta | VFX node'u CanvasLayer altına taşınacak, extends Control'e alınacak (T19) |
| 10 puzzle data dosyası içeriği tasarım kararı gerektirir | Orta | Düşük | Xenith_01 GDD'den başlangıç config'leri alınacak; T20 süresi içinde yeterli |
| Android export kurulumu zaman alabilir | Düşük | Düşük | T26 nice-to-have — Sprint 05'e atılabilir |

---

## File Map (Sprint Çıktısı)

```
src/
  systems/
    game_flow_orchestrator.gd   (yeni — T17)
    save_load_system.gd         (yeni — T18)
scenes/
  Puzzle.tscn                   (yeni — T19)
  MainMenu.tscn                 (yeni — T21)
assets/
  data/
    creatures/
      xenith_01.tres             (yeni — T20)
    puzzles/
      puzzle_001.tres            (yeni — T20)
      …
      puzzle_010.tres            (yeni — T20)
tests/
  unit/
    test_save_load_system.gd    (yeni — T18)
    test_end_to_end.gd          (yeni — T22)
production/
  qa/
    test-plan.md                (yeni — T23)
design/
  art-bible.md                  (yeni — T24)
```

---

## Sprint 05 Preview

Sprint 05 — Polish & Content: Gerçek sprite asset'leri (art bible'dan), ses efektleri (ses paletiyle), 10 → 30 puzzle içeriği, Rule Discovery System tasarımı, ilk external playtest.
