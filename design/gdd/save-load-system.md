# Save/Load System

> **Status**: In Design
> **Author**: Design session
> **Last Updated**: 2026-04-16
> **Implements Pillar**: Mastery Is Earned, Not Given

## Overview

Save/Load System, oyuncunun ilerleme durumunu (hangi bulmacaya kadar gelindi, kaç deneme yapıldı) cihaza kaydeder ve oyun açılışında geri yükler. MVP'de yalnızca tek bir kayıt dosyası vardır; slot sistemi yoktur. Godot'un `FileAccess` API'si üzerinden JSON formatında yazılır. Sistem kritik değil — kayıt dosyası bozulursa oyun sıfırdan başlar, hata vermez.

## Player Fantasy

Oyuncu telefonu kapatıp geri döndüğünde kaldığı yerden devam eder. Hiçbir şeyi kayıt etmek için yapmak zorunda kalmaz — her bulmaca çözümünde otomatik kaydedilir.

## Detailed Design

### Core Rules

**Kayıt verisi (MVP):**

```json
{
  "version": 1,
  "current_puzzle_index": 3,
  "total_attempts": 12,
  "puzzles": {
    "1": { "solved": true, "attempts": 2 },
    "2": { "solved": true, "attempts": 5 },
    "3": { "solved": false, "attempts": 5 }
  }
}
```

**Kayıt zamanı:** Her bulmaca çözümünde ve oyun kapatılırken (`NOTIFICATION_WM_CLOSE_REQUEST`).

**Yükleme zamanı:** Oyun açılışında. Dosya yoksa yeni oyun (`current_puzzle_index = 1`).

**Kayıt yolu:** `user://save.json` (Godot user data dizini — Android'de otomatik doğru yere yazılır).

**Bozuk dosya:** JSON parse hatası → dosya silinir, yeni oyun başlar. Hata loglanır.

### States and Transitions

Durumsuz — `save()` ve `load()` saf metodlardır.

### Interactions with Other Systems

| Sistem | Yön | Veri |
|--------|-----|------|
| Run Simulation Controller | Controller → Save | `save()` her başarılı RUN'dan sonra |
| Screen Navigation | Nav → Save | `save()` ekran geçişlerinde |
| Puzzle Data System | Save → PDS | `load()` → `current_puzzle_index` |

## Formulas

```
save_path = "user://save.json"

save(state):
  FileAccess.open(save_path, WRITE).store_string(JSON.stringify(state))

load() → SaveState:
  IF NOT FileAccess.file_exists(save_path):
    return default_save_state()
  raw = FileAccess.open(save_path, READ).get_as_text()
  parsed = JSON.parse_string(raw)
  IF parsed == null:
    FileAccess.remove(save_path)
    return default_save_state()
  return parsed
```

## Edge Cases

| Senaryo | Beklenen Davranış |
|---------|------------------|
| Kayıt dosyası yok | Yeni oyun — `current_puzzle_index = 1` |
| JSON bozuk | Dosya silinir, yeni oyun başlar |
| Disk dolu | `FileAccess` hatası loglanır, oyun devam eder (kayıtsız) |
| `version` alanı farklıysa | MVP'de yok sayılır; V1'de migration logic eklenir |

## Dependencies

| Sistem | Yön | Tür |
|--------|-----|-----|
| Run Simulation Controller | Controller → Save | Soft |
| Screen Navigation | Nav → Save | Soft |
| Puzzle Data System | Save → PDS | Soft |

## Tuning Knobs

Yok — kayıt yapısı sabittir. Yalnızca `save_path` değiştirilebilir (test için `user://save_test.json`).

## Acceptance Criteria

- [ ] `save()` → `user://save.json` oluşturulur, JSON geçerlidir
- [ ] `load()` → `current_puzzle_index` doğru döner
- [ ] Dosya yoksa → `current_puzzle_index = 1`, hata yok
- [ ] Bozuk JSON → dosya silinir, `current_puzzle_index = 1`, hata yok
- [ ] Bulmaca çözümünden sonra `save()` otomatik tetiklenir
- [ ] GUT testi: `TestSaveLoadSystem.gd` save/load döngüsünü doğrular
