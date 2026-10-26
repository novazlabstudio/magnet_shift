# Magnet Shift — Proje Notları

## Genel Kurallar
- Oyun içi/UI metinleri (buton, label, mesaj) **her zaman İngilizce** yazılır, sohbet Türkçe olsa bile. Mevcut kod bu şekilde: "GAME OVER", "MAIN MENU", "TRY AGAIN" vb.
- Android paket adı: `com.novazlabstudio.magnetshift` (kişisel isim yerine stüdyo markası "novazlabstudio" kullanılıyor — Gmail hesabıyla tutarlı). İleride yazılacak diğer oyunlarda da aynı prefix: `com.novazlabstudio.<oyunadi>`.

## AdMob Entegrasyonu (2026-09-28 tamamlandı)
Canlar bitince rewarded (ödüllü) reklam gösteriliyor.

- AdMob hesabı: aynı Gmail (novazlabstudio) üzerinden yönetiliyor; ileride yazılacak her oyun için AdMob'da ayrı bir "app" kaydı açılacak.
- AdMob App ID: `ca-app-pub-5920018930695278~4393848565`
- Rewarded Ad unit ID (ExtraLife): `ca-app-pub-5920018930695278/5551017561`
- Plugin: Godot AssetLib → **poing.studios "AdMob" v5.1.0** (Godot 4.2 uyumlu), `addons/admob/`.
  - Bu plugin'in kendi Claude Code skill dosyaları var: `addons/admob/skills/*/SKILL.md`. Ama bu örnekler kurulu sürümün gerçek API'siyle tam örtüşmüyor (ör. `ConsentInformation` static değil, instance metod adları farklı). Yeni bir reklam formatı (interstitial, banner vb.) eklerken SKILL.md'yi rehber olarak oku ama örnek kodu kurulu `addons/admob/gdscript/src/**/*.gd` dosyalarındaki gerçek API ile karşılaştırıp doğrula.
- `scripts/AdManager.gd` (autoload): SDK init + UMP/GDPR consent akışı + rewarded reklamı sürekli arka planda önceden yükleyip hazır tutuyor. `OS.is_debug_build()` true iken otomatik Google'ın resmi test ID'sini kullanıyor, release build'de gerçek ID'ye geçiyor — reklamına kendin tıklayıp AdMob politikasını ihlal etme riskini önlemek için.
- `scripts/GameManager.gd::_show_game_over()` içinde en üstteki "CONTINUE +3 ❤️" butonu (altında "keep your N coins") var; ödül kazanılırsa can 3'e resetlenip aynı level (skor sıfırlanmadan) yeniden yükleniyor.
- Release'e geçmeden önce Play Console → App content → Ads kısmında "Yes, my app contains ads" işaretlenmeli.

## Bilinen GDScript Tuzağı
GDScript'te (Godot 4) aynı fonksiyon içindeki iki ayrı lambda, dışarıdaki bir `bool`/`int`/`String` gibi value-type değişkeni **kopya olarak** yakalar — biri değiştirse diğeri görmez. Bu yüzden `AdManager.gd`'de ödül bilgisini paylaşmak için bare `bool` yerine `Dictionary` (`{"earned": false}`) kullanıldı. Birden fazla async callback/signal'ın state paylaştığı her yerde (AdMob, HTTP request, çoklu tween completion vb.) aynı desene dikkat et.

## Level Verisi Kuralları (`GameManager.gd::get_level_data`)
- Tasarım koordinatı 480x854. Level 4'ten itibaren level yüksekliği `854 + (n-3)*120`; y değerleri `scale_y = lh/854` ile ölçeklenir.
- **Platform `Vector4(x, y, w, h)`: x SOL kenar, y merkez.** Kod merkeze çevirir (`x + w/2`). Sağ platformlarda `x + w = 455` (sağ duvarın iç kenarı), soldakiler x=25'ten başlar. Coin ve guard'lar platform ortasına göre yazılmıştır.
- `extra_magnets`: x=50/430 olanlar (duvar mıknatısları) 854'lük tasarım koordinatında → ölçeklenir. **x=80/400 olan dizi zaten mutlak level koordinatında → ölçeklenmez.** Birbirine 56px'den yakın mıknatıslar tekilleştirilir.
- Level 21–50 sahneleri `CreateLevels.gd` ile Level20'den üretildi; yeni level eklerken `next_level_path` zincirini kontrol et (Level 20'de bir ara boş kalmıştı).
- Guard'lar platform kenarını ray ile algılar ve `patrol_distance` sınırında döner.

## Ekran / UI Yerleşimi
- `stretch/aspect = keep_width`: genişlik hep 480, uzun telefonlarda viewport dikeyde uzar (siyah bant yok). Geniş ekranda (tablet) yanlarda bant olur.
- Sabit koordinatlı paneller 854'e göre çizilir, sonra `ScreenUtil.shift_children(..., ScreenUtil.center_offset(self))` ile ortalanır. Üst çubuktaki öğeler (HUD, BOARD/LVL, SKIP) ise `ScreenUtil.safe_top(self)` kadar aşağı itilir (çentik). Yeni ekran/panel eklerken aynı deseni kullan.
- Müzikler import ayarında `loop_mode=2` (Forward) ile kesintisiz döner.

## Sürüm
- Proje Godot 4.6 ile kaydedilmiş (`config/features` 4.6, sahnelerde `unique_id`). Bu Mac'te şu an sadece 4.4.1 + 4.4.1 export şablonları var.
- Play Console'a her yüklemede `export_presets.cfg` → `version/code` artırılmalı (ilk yükleme 1 idi).

## Analitik
- `AnalyticsManager` Complete/Fail olaylarında gerçek `attempt_num` gönderir (`user://ga_attempts.json`, Complete'te sıfırlanır); `os_version` cihazdan okunur.
- Testlerde GameAnalytics'e gerçek olay gitmemesi için autoload'u stub ile değiştir.

## Kahramanlar
- 0=Cyborg, 1=Pink, 2=Shadow (Lvl 5), 3=Mech (Lvl 10), 4=Blaze. Çizimler `PlayerVisual.gd`; menüdeki 0–3 önizlemeleri `MainMenu.gd::_get_hero_preview_script` içinde ayrı kopya, Blaze ise doğrudan `PlayerVisual` (`preview_hero`) kullanıyor.
- **Blaze 3 ödüllü reklamla açılır** (`HeroManager.BLAZE_ADS_REQUIRED`, ilerleme `user://blaze_ads.dat`). Her reklam oyuncunun ayrı dokunuşuyla başlar, ödül her izlemede kaydedilir (AdMob kurallarına uygun: isteğe bağlı, ödül önceden açıkça yazılı). Pencere: `MainMenu.gd::_show_blaze_unlock`.
- Şimdilik ExtraLife ile aynı rewarded ad unit kullanılıyor; AdMob'da ayrı bir "HeroUnlock" unit'i açılırsa raporlar ayrışır.
- GA Design olayları: `HeroUnlock:Blaze:Ad1..Ad3`, `HeroUnlock:Blaze:Unlocked` — kaç kişinin hangi adımda bıraktığı görülebilir.
- Yeni kahraman eklerken: `HeroManager` clamp sınırı, `GameManager` içindeki `hero_names` (3 yer), `PlayerVisual._draw_dead` renk dizisi ve menü kart sayısı birlikte güncellenmeli.
