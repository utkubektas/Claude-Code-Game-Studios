# Token Budget Policy

Bu dosya tüm session ve agent çağrılarında token israfını önlemek için
**bağlayıcı kurallar** içerir. CLAUDE.md'den `@` ile dahil edilir.

---

## 1. Agent Spawn vs. Inline Karar Ağacı

Her potansiyel agent çağrısı için şu soruları sor:

```
Hedef dosya(lar) toplam < 200 satır mı?
  EVET → inline yap (main session'da gerçekleştir)
  HAYIR → devam et ↓

Aynı session'da bu dosya zaten okundu mu?
  EVET → inline yap
  HAYIR → devam et ↓

Sadece tek bir soru/kontrol mu?
  EVET → inline yap
  HAYIR → agent aç
```

**İstisna yok**: Rate limit'e çarpma riski varsa önce 1 agent başlat,
sonucu gör, sonra devam et. Paralel 4+ review = kırık session.

---

## 2. Review Prompt Şablonu (Inline Standards)

Her review promptuna CLAUDE.md ve coding-standards.md'yi "oku" diye sormak
yerine aşağıdaki bloğu **inline yapıştır**. Agent dosya okumak zorunda kalmaz.

```
--- GDScript kalite kontrol listesi (dosya okumadan uygula) ---
□ Tüm değişken/parametre/dönüş tipi statik olarak tanımlanmış
□ Oyun değerleri hardcode değil (@export var veya adlandırılmış const)
□ Enum isimleri PascalCase (State, Role — _State, _Role değil)
□ var _state: State = State.IDLE  (değil: var _state: _State = _State.IDLE)
□ Public API'de ## doc comments mevcut
□ Tek metod max 40 satır, cyclomatic complexity < 10
□ setup() inject edilen bağımlılıklar için null assert var
□ Singleton yok — bağımlılık injection kullanılıyor
□ Cross-system iletişim signal ile yapılıyor
□ Test dosyası whitebox erişim kullanıyorsa başlıkta belgelenmiş
---
```

---

## 3. Agent Çağrı Politikası

### Her sprint sonunda 1 kez

| Agent | Ne zaman | Sıklık |
|-------|----------|--------|
| `lead-programmer` | Sprint gate-check | Sprint başına 1 kez, sadece sonunda |
| `godot-gdscript-specialist` | Tier-1 review (200+ satır) | Gerektiğinde |
| `gameplay-programmer` | Tier-2 review | Gerektiğinde |
| `qa-tester` | Coverage gap raporu | Sprint başına 1 kez, implementasyon bittikten sonra |
| `qa-lead` | Test planı / release gate | Milestone dönümünde |

### Henüz zamanı gelmedi (Sprint 04'e kadar çağırma)

| Agent | Neden bekle |
|-------|-------------|
| `art-director` | Gerçek sprite asset'leri Sprint 04'te. Şu an ColorRect. |
| `audio-director` | `assets/audio/` klasörü yok. Sprint 04'te oluşturulacak. |
| `localization-lead` | Henüz string extraction yapılmadı. |
| `community-manager` | Oyun henüz çıkmadı. |
| `release-manager` | Sprint 04 First Playable'dan sonra. |

---

## 4. Session State Kuralı

`production/session-state/active.md` dosyası:
- Her milestone'dan sonra güncellenir (bir dosya yazıldığında, commit atıldığında)
- Yeni session başladığında **ilk okunan** dosyadır
- Şunu içerir: aktif görev, yapılanlar, açık kararlar, bir sonraki adım

Session başındaki ilk Glob/Read çağrısı mutlaka bu dosyayı okumalı.
10 dosya okuyarak bağlam kurmak yerine bu tek dosya yeterli olmalı.

---

## 5. Paralel Agent Limiti

**Maksimum 3 agent aynı anda** başlatılabilir. 4+ paralel agent:
- Rate limit çakışması yaratır
- Başlama maliyeti boşa gider
- Sonuçlar bağımlıysa ikinci grubun başlaması zaten bloke

**Örnek**: 5 review varsa → 2 başlat → sonuçları bekle → 2 daha → 1 kala.

---

## 6. Sprint Sonu Token Retro

Her sprint sonunda `/token-retro` skill'i çalıştır:
- Son sprint için agent kullanım analizi yapar
- İhlal edilen token-budget kurallarını tespit eder
- `production/sprints/sprint-N-token-retro.md` dosyasına kaydeder
- review-delegation.md'de gerekli güncellemeleri uygular

Bu otonom değil — sprint kapanırken bir kez el ile çağrılır.
