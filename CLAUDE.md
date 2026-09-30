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
- `scripts/GameManager.gd::_show_game_over()` içinde "WATCH AD: +3 ❤️" butonu var; ödül kazanılırsa can 3'e resetlenip aynı level (skor sıfırlanmadan) yeniden yükleniyor.
- Release'e geçmeden önce Play Console → App content → Ads kısmında "Yes, my app contains ads" işaretlenmeli.

## Bilinen GDScript Tuzağı
GDScript'te (Godot 4) aynı fonksiyon içindeki iki ayrı lambda, dışarıdaki bir `bool`/`int`/`String` gibi value-type değişkeni **kopya olarak** yakalar — biri değiştirse diğeri görmez. Bu yüzden `AdManager.gd`'de ödül bilgisini paylaşmak için bare `bool` yerine `Dictionary` (`{"earned": false}`) kullanıldı. Birden fazla async callback/signal'ın state paylaştığı her yerde (AdMob, HTTP request, çoklu tween completion vb.) aynı desene dikkat et.
