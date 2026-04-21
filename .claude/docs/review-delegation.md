# Review Delegation Model

Sprint 01–02 gözleminden çıkan bulgu: **lead-programmer her task için çağrılıyordu**,
oysa birçok review doğrudan ilgili uzman tarafından daha verimli yapılabilir.

Tam token politikası için: `.claude/docs/token-budget.md`

---

## Üç Katmanlı Review Modeli

### Tier 1 — GDScript kalitesi
**Agent:** `godot-gdscript-specialist`
**Kapsam:** GDScript statik tipleme, signal mimarisi, Godot node/resource pattern, coroutine, performans
**Hangi tasklar:** Node/Resource extending, signal architecture, GDScript-specific idioms, Godot API kullanımı

**⚠ Spawn kuralı:** Hedef dosya < 200 satırsa agent AÇMA — main session'da inline yap.
Review prompt'una token-budget.md §2'deki inline standards bloğunu yapıştır.

### Tier 2 — Gameplay doğruluğu
**Agent:** `gameplay-programmer`
**Kapsam:** Mekanik mantığı, state machine doğruluğu, formül uygulaması, GDD ile uyum
**Hangi tasklar:** Mechanic implementasyonu, game loop, puzzle logic, cascade/evaluation

### Tier 3 — Mimari
**Agent:** `lead-programmer`
**Kapsam:** Cross-system API tasarımı, bağımlılık yönü, breaking change riski, sprint sonu gate-check
**Sprint başına 1 kez** — sprint sonunda entegrasyon gate-check için. Task bazında çağırma.

---

## Review Prompt Şablonu

Aşağıdaki şablonu kullan. `[...]` alanlarını doldur.
**`@.claude/docs/coding-standards.md` veya CLAUDE.md'yi "oku" deme** — inline standards bloğu yeterli.

```
[DOSYA YOLU] dosyasını şu açıdan incele:
[REVIEW ODAK NOKTASI — örn: "state machine doğruluğu ve signal akışı"]

Kabul kriterleri:
[SPRINT DOC'TAN ACCEPTANCE CRITERIA — 3-5 madde, kopyala-yapıştır]

--- GDScript kalite kontrol listesi (dosya okumadan uygula) ---
□ Tüm değişken/parametre/dönüş tipi statik olarak tanımlanmış
□ Oyun değerleri hardcode değil (@export var veya adlandırılmış const)
□ Enum isimleri PascalCase (State — _State değil)
□ Public API'de ## doc comments mevcut
□ Tek metod max 40 satır, cyclomatic complexity < 10
□ setup() inject edilen bağımlılıklar için null assert var
□ Singleton yok — dependency injection kullanılıyor
□ Cross-system iletişim signal ile yapılıyor
---

Çıktı formatı:
## Gerekli Değişiklikler (mutlaka düzeltilmeli)
## Öneriler (nice-to-have)
## Karar: ONAYLANDI / ÖNERİLERLE ONAYLANDI / DEĞİŞİKLİK GEREKİYOR
```

---

## QA Entegrasyon Noktası

`qa-tester` sprint başına **1 kez** çağrılır — implementasyon bittikten sonra,
sprint gate'ten önce. Görevi: mevcut test dosyalarında **coverage gap raporu** üretmek.

Prompt şablonu:
```
tests/unit/ altındaki [SPRINT] test dosyalarını incele.
Hangi acceptance criteria test edilmemiş? Hangi edge case'ler eksik?
Yeni test YAZMA — sadece gap listesi ver, öncelik sırasıyla.
```

Bu sayede test yazma ve review aynı agent'a düşmez.

---

## Sprint Bazında Delegation

### Sprint 01 (geriye dönük)
| Task | Yapılan | Olması gereken | Token fark |
|------|---------|----------------|------------|
| T03 PuzzleDataSystem | lead-programmer | `godot-gdscript-specialist` | ~25K israf |
| T04 BiologyRuleEngine | lead-programmer | `gameplay-programmer` | ~25K israf |
| T05 FailureCascadeSystem | lead-programmer | `gameplay-programmer` | ~25K israf |
| T06 Integration suite | lead-programmer | `gameplay-programmer` | ~25K israf |

### Sprint 02 (geriye dönük)
| Task | Yapılan | Olması gereken | Token fark |
|------|---------|----------------|------------|
| T07 TouchInputHandler | lead-programmer | `godot-gdscript-specialist` | ~20K israf |
| T08 OrganRepairMechanic | lead-programmer | `gameplay-programmer` | ~20K israf |
| T09 RunSimulationController | lead-programmer (rate limit) | `gameplay-programmer` | ~15K israf |

### Sprint 03 (gerçekleşen)
| Task | İmplementasyon | Review | Tier | Yöntem | Sonuç |
|------|----------------|--------|------|--------|-------|
| T12 SpecimenViewer (266 satır) | `godot-gdscript-specialist` | `godot-gdscript-specialist` | 1 | agent | ✅ 6 required change bulundu |
| T13 PuzzleHUD (267 satır) | `godot-gdscript-specialist` | `gameplay-programmer` | 2 | agent → rate limit | ❌ 0 token, review yok |
| T14 RunSequenceVFX (155 satır) | `godot-gdscript-specialist` | `gameplay-programmer` | 2 | agent → rate limit | ❌ §1 ihlali (< 200 satır) |
| T15 ScreenNavigation (106 satır) | `godot-gdscript-specialist` | `gameplay-programmer` | 2 | agent → rate limit | ❌ §1 ihlali (< 200 satır) |
| T16 Integration Tests (345 satır) | main agent | `gameplay-programmer` | 2 | (rate limit nedeniyle atlandı) | ⚠ Bekliyor |
| Sprint gate | — | `lead-programmer` | 3 | (henüz yapılmadı) | ⏳ Sprint 04 başında |

> Token retro: `production/sprints/sprint-03-token-retro.md`
> İsraf tahmini: ~28K token (§1 + §5 ihlalleri + active.md eksikliği)

### Sprint 04+ (uygulanan kurallar)

**Ders çıkarıldı**: 4 paralel agent → 3 rate limit. Kural: 2 agent başlat → bekle → devam.
**Ders çıkarıldı**: 155 + 106 satır dosyalar için agent açıldı → §1 ihlali. Inline yap.

| Task türü | Satır tahmini | Yöntem | Agent |
|-----------|--------------|--------|-------|
| Küçük sistem (< 150 satır) | — | inline review | — |
| Orta sistem (150-250 satır) | — | inline veya 1 agent | `godot-gdscript-specialist` |
| Büyük sistem (> 250 satır) | — | agent (tek seferde) | Tier'a göre |
| Integration test suite | genellikle 300+ satır | agent | `gameplay-programmer` |
| Sprint gate | — | agent | `lead-programmer` (1 kez) |

**Paralel limit**: Aynı anda max 2 review agent. Biri biterken diğeri başlar.
