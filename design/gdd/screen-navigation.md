# Screen Navigation

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given

## Overview

Screen Navigation, oyunun farklı ekranları (ana menü, bulmaca, bitiş) arasındaki geçişleri yöneten basit bir yönlendirici sistemdir. MVP'de yalnızca üç ekran vardır: ana menü, aktif bulmaca ekranı, ve MVP sonu ekranı (10 bulmaca tamamlandığında). Godot'un `SceneTree.change_scene_to_file()` üzerine ince bir sarmalayıcıdır; geçiş animasyonu (fade) ve ekranın önceki durumunu temizleme sorumluluğunu üstlenir.

## Player Fantasy

Oyuncu bir bulmacadan çıkıp diğerine geçerken sürtünme hissetmez. Bulmaca çözüldüğünde kısa bir geçiş olur ve bir sonraki bulmaca önünde belirir. MVP'de fazla menü yok — mümkün olduğunca az ekran, mümkün olduğunca çok bulmaca.

## Detailed Design

### Core Rules

**MVP Ekranları:**

| Ekran ID | Sahne Dosyası | Giriş Koşulu |
|----------|--------------|-------------|
| `main_menu` | `scenes/MainMenu.tscn` | Oyun başlangıcı |
| `puzzle` | `scenes/Puzzle.tscn` | "Başla" butonu / bulmaca tamamlandı |
| `end_screen` | `scenes/EndScreen.tscn` | Son bulmaca (index 10) çözüldü |

**Geçiş akışı:**

1. `go_to(screen_id, params)` çağrılır
2. `fade_out(0.2s)` — ekran kararır
3. `SceneTree.change_scene_to_file(scene_path)` — yeni sahne yüklenir
4. Yeni sahneye `params` iletilir (örn. `puzzle_index`)
5. `fade_in(0.2s)` — yeni ekran açılır

**`go_to_puzzle(index)`:** Shortcut — `go_to("puzzle", {puzzle_index: index})`.
**`go_to_next_puzzle()`:** `current_index + 1`; son bulmacaysa `go_to("end_screen")`.

### States and Transitions

```
main_menu → puzzle(1) → puzzle(2) → ... → puzzle(10) → end_screen
               ↑ (her bulmaca tamamlanınca bir sonraki)
```

Tüm geçişler tek yönlü MVP'de. Geri butonu yok (MVP).

### Interactions with Other Systems

| Sistem | Yön | Veri |
|--------|-----|------|
| Puzzle HUD | HUD → Nav | `go_to_next_puzzle()` ("Devam Et" butonundan) |
| Run Simulation Controller | Controller → Nav | `puzzle_solved(next_index)` |
| Save/Load System | Nav → Save | Geçiş öncesi mevcut durumu kaydet |

## Formulas

```
next_screen(current_puzzle_index) =
  IF current_puzzle_index < MAX_PUZZLE_INDEX (10):
    go_to_puzzle(current_puzzle_index + 1)
  ELSE:
    go_to("end_screen")
```

## Edge Cases

| Senaryo | Beklenen Davranış |
|---------|------------------|
| `go_to()` geçiş sırasında çağrılırsa | Yutulur — fade tamamlanana kadar kuyruk alınmaz |
| Geçersiz `screen_id` | Hata loglanır, `main_menu`'ye düşülür |
| Sahne dosyası bulunamazsa | Godot hatası — yükleme zamanı doğrulanmalı |

## Dependencies

| Sistem | Yön | Tür |
|--------|-----|-----|
| Puzzle HUD | HUD → Nav | Hard |
| Run Simulation Controller | Controller → Nav | Hard |
| Save/Load System | Nav → Save | Soft |

## Tuning Knobs

| Parametre | Değer | Aralık |
|-----------|-------|--------|
| Fade süresi | 200ms | 100–400ms |

## Acceptance Criteria

- [ ] `go_to_puzzle(1)` → Puzzle sahnes yüklenir, doğru bulmaca aktif
- [ ] `go_to_next_puzzle()` son bulmacadan → `end_screen` yüklenir
- [ ] Geçiş sırasında ikinci `go_to()` → yutulur
- [ ] Fade animasyonu 60fps'de düzgün çalışır
- [ ] GUT testi: `TestScreenNavigation.gd` geçiş akışlarını doğrular
