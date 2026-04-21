# Review Delegation Model

Sprint 01–02 gözleminden çıkan bulgu: **lead-programmer her task için çağrılıyordu**,
oysa birçok review doğrudan ilgili uzman tarafından daha verimli yapılabilir.

## Üç Katmanlı Review Modeli

### Tier 1 — GDScript kalitesi
**Agent:** `godot-gdscript-specialist`
**Kapsam:** GDScript statik tipleme, signal mimarisi, Godot node/resource pattern, coroutine, performans
**Hangi tasklar:** Node/Resource extending, signal architecture, GDScript-specific idioms, Godot API kullanımı

### Tier 2 — Gameplay doğruluğu
**Agent:** `gameplay-programmer`
**Kapsam:** Mekanik mantığı, state machine doğruluğu, formül uygulaması, GDD ile uyum
**Hangi tasklar:** Mechanic implementasyonu, game loop, puzzle logic, cascade/evaluation sistemleri

### Tier 3 — Mimari
**Agent:** `lead-programmer`
**Kapsam:** Cross-system API tasarımı, bağımlılık yönü, breaking change riski, sprint sonu gate-check
**Hangi tasklar:** Yeni sistemler arası entegrasyon, API değişiklikleri, sprint sonu mimari denetim

## Uygulama Kuralları

- Her task **tek bir tier** alır; tier atlamak için explicit gerekçe gerekir
- Tier 1 ve 2 paralel çalışabilir (aynı task için farklı boyutlar)
- **lead-programmer sprint başına 1 kez** çağrılır: sprint sonu entegrasyon gate-check'i için
- Tier tespiti task başlamadan sprint planında belirlenir

## Sprint'e Göre Delegation Tablosu

### Sprint 01 (geriye dönük)
| Task | Yapılan | Olması gereken |
|------|---------|----------------|
| T03 PuzzleDataSystem review | lead-programmer | `godot-gdscript-specialist` |
| T04 BiologyRuleEngine review | lead-programmer | `gameplay-programmer` |
| T05 FailureCascadeSystem review | lead-programmer | `gameplay-programmer` |
| T06 Integration suite review | lead-programmer | `gameplay-programmer` |

### Sprint 02 (geriye dönük)
| Task | Yapılan | Olması gereken |
|------|---------|----------------|
| T07 TouchInputHandler review | lead-programmer | `godot-gdscript-specialist` |
| T08 OrganRepairMechanic review | lead-programmer | `gameplay-programmer` |
| T09 RunSimulationController review | lead-programmer (rate limit) | `gameplay-programmer` |

### Sprint 03+ (bu modelden itibaren)
| Task | İmplementasyon | Review |
|------|----------------|--------|
| SpecimenViewer | `godot-gdscript-specialist` | `godot-gdscript-specialist` |
| PuzzleHUD | `godot-gdscript-specialist` | `gameplay-programmer` |
| RunSequenceVFX | `godot-gdscript-specialist` | `gameplay-programmer` |
| ScreenNavigation | `godot-gdscript-specialist` | `gameplay-programmer` |
| Sprint gate | — | `lead-programmer` (tek sefer) |
