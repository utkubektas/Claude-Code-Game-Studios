---
name: token-retro
description: "Sprint sonu token kullanım retrospektifi. Hangi agentlar ne kadar çağrıldı, hangi kurallar ihlal edildi, bir sonraki sprint için optimizasyon uygular."
argument-hint: "[sprint-N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
context: |
  !git log --oneline --since="3 weeks ago" 2>/dev/null
---

Sprint sonu token kullanım retrospektifi. `sprint-N` argümanı verilmezse
en son sprint dosyasını kullan.

## Adım 1 — Sprint verisini oku

Şu dosyaları oku:
- `production/sprints/sprint-[N].md` — görev listesi, review delegation tablosu
- `.claude/docs/token-budget.md` — bağlayıcı token kuralları (politika referansı)
- `.claude/docs/review-delegation.md` — hangi sprint'te ne yapıldığı

## Adım 2 — Agent kullanım analizi

Sprint planındaki review delegation tablosunu ve görev listesini inceleyerek
aşağıdaki soruları yanıtla:

**A. Spawn kuralı ihlalleri** (token-budget.md §1)
- 200 satır altı dosya için agent açıldı mı?
- Aynı session'da zaten okunan dosya için tekrar agent açıldı mı?
- Sadece tek kontrol için agent başlatıldı mı?

**B. lead-programmer aşırı kullanımı** (token-budget.md §3)
- Sprint içinde lead-programmer kaç kez çağrıldı?
- Sprint sonu gate dışında çağrım var mıydı?
- Kaç K token harcandı (sprint planındaki retro notlarından tahmin et)?

**C. Paralel agent limiti ihlali** (token-budget.md §5)
- Aynı anda 3'ten fazla agent başlatıldı mı?
- Rate limit'e çarpıldı mı (sprint notlarında belirtilmişse)?

**D. Zamanı gelmeyen agentlar**
- art-director, audio-director, localization-lead, community-manager, release-manager
  çağrıldı mı? (Eğer çağrıldıysa gerekçesi neydi?)

**E. Session state kullanımı**
- `production/session-state/active.md` var mı?
- Bu sprint'te güncellendi mi?

**F. QA entegrasyonu**
- `qa-tester` coverage gap raporu için çağrıldı mı?
- Testler implementasyon agentı tarafından mı yoksa qa-tester tarafından mı yazıldı?

## Adım 3 — Kayıp agentlar analizi

Sprint'te hiç çağrılmayan ama çağrılması gereken agentları tespit et.
Bunlar için bir sonraki sprint'e öneri ekle:
- `art-director` — görsel placeholder'lardan gerçek asset'lere geçiş ne zaman?
- `audio-director` — ilk ses event listesi ne zaman gerekli?
- `qa-lead` — test planı ne zaman yazılmalı?
- `qa-tester` — coverage gap analizi yapıldı mı?

## Adım 4 — Token tasarrufu tahmini

İhlal edilen her kural için tahmini token maliyetini hesapla:

| İhlal | Tahmini maliyet | Önlem |
|-------|----------------|-------|
| lead-programmer task başına (sprint 01) | ~25K/çağrı | Tier 1/2 ile değiştir |
| 4+ paralel agent → rate limit | 4 × başlatma maliyeti boşa | Maks 3 paralel |
| Review'da CLAUDE.md okuma | ~3K/review | Inline standards bloğu |
| active.md yokken session recovery | ~10K/session | active.md zorunlu |

## Adım 5 — Optimizasyon uygula

Tespit edilen ihlallere göre şu dosyaları güncelle:

**review-delegation.md güncellemesi** (eğer delegation tablosu güncel değilse):
- Bir sonraki sprint için hangi taskların inline review, hangi taskların agent review
  alacağını tahmin et (dosya boyutu = ~satır/10 ≈ KB)
- Tabloyu güncelle

**Eğer `production/session-state/active.md` yoksa**: oluştur (boş şablon ile)

## Adım 6 — Retro raporu yaz

`production/sprints/sprint-[N]-token-retro.md` dosyasına kaydet:

```markdown
# Token Retro — Sprint [N]
Tarih: [YYYY-MM-DD]

## Özet

| Metrik | Bu Sprint | Önceki Sprint | Trend |
|--------|-----------|---------------|-------|
| lead-programmer çağrı | [N] | [N] | ↓/↑/= |
| Paralel agent max | [N] | [N] | ↓/↑/= |
| Rate limit çakışması | [Y/N] | [Y/N] | |
| active.md güncellendi mi | [Y/N] | [Y/N] | |
| qa-tester çağrıldı mı | [Y/N] | [Y/N] | |
| Tahmini toplam israf | ~[N]K token | ~[N]K token | ↓/↑ |

## Kural İhlalleri

### [İhlal başlığı]
- **Kural**: token-budget.md §[X]
- **Nerede**: [Task/Sprint/bağlam]
- **Tahmini maliyet**: ~[N]K token
- **Düzeltme**: [Ne yapılmalı]

## Bir Sonraki Sprint İçin Önlemler

| # | Önlem | Dosya | Öncelik |
|---|-------|-------|---------|
| 1 | [Spesifik eylem] | [Hangi dosya değişecek] | Yüksek/Orta |

## Ertelenmiş Agentlar

| Agent | Sprint | Neden bekliyor |
|-------|--------|----------------|
| art-director | Sprint [N] | [Gerekçe] |
| audio-director | Sprint [N] | [Gerekçe] |

## Notlar
[Serbest notlar — özellikle tekrarlayan örüntüler]
```

## Adım 7 — Çıktı

Kullanıcıya kısa özet ver:
- Tahmini token israfı bu sprint için
- En büyük 1-2 ihlal
- Bir sonraki sprintte uygulanan değişiklik sayısı
- Dosyalar güncellendi mi (evet/hayır)
