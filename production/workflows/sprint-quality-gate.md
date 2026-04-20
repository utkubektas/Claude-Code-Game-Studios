# Sprint Quality Gate

Her sprint sonunda — ve production branch'e merge öncesinde — bu süreç eksiksiz uygulanır.

## Adımlar (sırayla)

### 1. Testleri çalıştır
```bash
godot --headless -s addons/gut/gut_cmdln.gd -- -gdir=res://tests/unit -gprefix=test_ -gsuffix=.gd -glog=0
```
**Geçme kriteri:** `---- All tests passed! ----` — tek bir failing test bile bloke eder.

### 2. Kod review
Sprint'te yazılan tüm `src/` dosyaları `/code-review` skill'i ile incelenir.

**Geçme kriteri:** `APPROVED` veya `APPROVED WITH SUGGESTIONS` — `CHANGES REQUIRED` bloke eder.

### 3. Review bulgularını düzelt
`CHANGES REQUIRED` döndüren her bulgu düzeltilir. Düzeltme sonrası testler tekrar koşulur.

### 4. Sprint planını güncelle
`production/sprints/sprint-XX.md` dosyasındaki tamamlanan task'ların acceptance criteria kutucukları işaretlenir.

### 5. Commit ve stage güncelleme
Tüm düzeltmeler commit edilir. Sprint tamamlandıysa `production/stage.txt` güncellenir (gerekiyorsa).

---

## Sorumluluklar

| Adım | Kim yapar |
|------|-----------|
| Test çalıştırma | Otomatik (Bash) |
| Kod review | `code-review` skill → `lead-programmer` agent |
| Düzeltmeler | İlgili implementasyon agent'ı |
| Sprint güncelleme | `producer` agent |

---

## Neden bu süreç?

Yazan agent kendi kodunu doğrulayamaz — confirmation bias nedeniyle kendi hatalarını gözden kaçırır. Review ayrı bir agent tarafından yapıldığında:
- Dead code yakalanır (T02'de `valid_creatures()` redundant check)
- Mimari sorunlar erken tespit edilir (cross-file enum coupling)
- Stale comment'lar düzeltilir
- 40-satır limiti gibi standartlar uygulanır

Test suite olmadan code review, code review olmadan test suite — ikisi birlikte çalışır.
