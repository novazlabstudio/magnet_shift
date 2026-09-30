# Magnet Shift — Yayına Hazırlık İlerleme Notu

Son güncelleme: 2026-09-30

## Tamamlananlar
- [x] AdMob rewarded ad entegrasyonu (canlar bitince "WATCH AD: +3 ❤️") — detay: [CLAUDE.md](CLAUDE.md)
- [x] GameAnalytics (metrik) entegrasyonu — `scripts/AnalyticsManager.gd` (daha önceden yapılmıştı)
- [x] Android paket adı: `com.novazlabstudio.magnetshift`
- [x] `version/name` = `1.0.0` (export_presets.cfg)
- [x] Release keystore oluşturuldu: `keystore/release.keystore` (alias: `magnetshift`, parola: sadece kullanıcının kendi not/parola yöneticisinde — bu dosyaya yazılmadı, `.gitignore` ile hariç tutuluyor)
- [x] İlk release `.aab` başarıyla export edildi (`Magnet Shift.aab`)
- [x] Google Group oluşturuldu: **`magnet-shift-testers@googlegroups.com`** — "anyone on the web can join/search", "who can view members" → group managers (üye mailleri birbirine görünmesin diye)
- [x] **Android Developer Verification**: paket adı zaten "Registered" durumda (3 key — cihaza kurulan debug/release build'lerden otomatik algılanmış), ekstra işlem gerekmedi
- [x] Play Console'da **"Magnet Shift"** app kaydı oluşturuldu (Create app → Game, Free)
- [x] Closed testing → **Alpha** track zaten mevcuttu, **Create new release** ile `Magnet Shift.aab` yüklendi (Play App Signing kabul edildi)
- [x] **App content** formlarının çoğu tamamlandı:
  - Financial features → "My app doesn't provide any financial features"
  - Sign in details (eski adı "App access") → "No" (kısıtlı bölüm yok)
  - Ads → "Yes, my app contains ads"
  - Health declaration → "No"
  - Content ratings (IARC) → Category: Game; questionnaire'deki tüm sorulara "No" (şiddet/cinsellik/dil/madde/vücut fonksiyonu/satın alma-kripto/sohbet/konum-paylaşımı/suç tekniği yok)
  - Target audience → **13-15, 16-17, 18 and over** işaretlendi (13 yaş altı bilinçli olarak seçilmedi — "Designed for Families" politikasına girmemek için, aksi halde kişiselleştirilmiş reklam gösterilemez ve AdMob geliri ciddi düşer)
  - **Data safety** formu dolduruldu:
    - Veri topluyor mu → Yes
    - Encrypted in transit → Yes
    - Account creation → yok ("does not allow users to create an account"), dışarıdan login da yok
    - Location (approximate/precise) → toplanmıyor (manifest'te konum izni yok, doğrulandı)
    - Files and docs → toplanmıyor
    - App activity → sadece **App interactions** işaretlendi (GameAnalytics), In-app search/Installed apps/Other → hayır
      - Ephemeral değil, collection required, amaç: sadece **Analytics** (hem collected hem shared tarafında)
      - Collected + Shared ikisi de işaretli (GameAnalytics 3. taraf servis)
    - App info and performance → sadece **Diagnostics** işaretlendi (AdMob), Crash logs işaretlenmedi (ayrı bir crash reporting servisi yok)
      - Ephemeral değil, collection required
      - Collected + Shared ikisi de işaretli (AdMob/Google 3. taraf)
    - Security practices → "Data is encrypted in transit" otomatik göründü
    - **Privacy policy linki eksik — formu submit etmek için hâlâ gerekiyor (aşağıya bak)**

## Şu An Kaldığımız Yer
Data safety formunun **Preview** adımındayız. Tek eksik: **Privacy Policy URL'i**. Kullanıcı daha önce başka bir mail hesabından GitHub Pages ile böyle bir statik sayfa yayınlamıştı (bir Chrome extension için) — aynı yöntemi burada da kullanacak ama bunu bu sohbette yapmadı, bir sonraki sohbette devam edilecek.

## Sıradaki Adımlar (bir sonraki sohbette buradan devam)
1. **Privacy Policy metnini yaz** (Claude ile birlikte hazırlanabilir — içerik: GameAnalytics + AdMob veri toplama, UMP/GDPR consent akışı, 3. taraf SDK'lar, iletişim bilgisi). Henüz yazılmadı.
2. **GitHub Pages ile yayınla**: hangi GitHub hesabından yayınlanacağı henüz netleşmedi (novazlabstudio'ya özel yeni hesap mı, eski hesap mı — kullanıcı karar verecek). Basit repo → `index.html` → Settings → Pages → `https://<user>.github.io/<repo>/` linkini al.
3. O linki Play Console → **App content → Data safety → Privacy policy** alanına gir, formu **Submit** et.
4. **Main store listing**'de eksik olan **Full description**'ı doldur (daha önce "Add a full description to save" hatası çıkmıştı, henüz yazılmadı) + short description, ekran görüntüleri, feature graphic (1024x500).
5. Closed testing track'inde **"No countries or regions have been selected"** hatası vardı → track ayarlarından **"Add countries / regions"** ile ülke seç (öneri: hepsini seçmek).
6. Yukarıdaki eksikler kapanınca release'i tekrar **review** edip **rollout**'u başlat.
7. Track'in **Testers** sekmesinde → **Add from Google Groups** → `magnet-shift-testers@googlegroups.com` ekle → kaydet.
8. Testers sekmesinde çıkan **opt-in URL**'i kopyala.
9. Bu linki **r/PlayStoreTesters** (Reddit) ve benzeri topluluklarda paylaş, Play Console'un istediği sayıda testerın **kesintisiz 14 gün** opted-in kalmasını bekle.
10. 14 gün + gerekli tester sayısı dolunca Play Console'da **Production**'a geçiş başvurusu açılacak.

## Önemli Hatırlatmalar
- Release keystore'u (`keystore/release.keystore`) proje klasörü dışında ayrıca yedekle (bulut, harici disk). Kaybedilirse bu paket adıyla bir daha güncelleme yüklenemez.
- Reklam kodu debug build'de otomatik test ID kullanıyor, release'de gerçek ID — kendi reklamına gerçek build'de tıklama (AdMob politika ihlali riski).
- Target audience'a 13 yaş altını **bilerek** dahil etmedik — "Designed for Families" kısıtlamalarına girmemek için (kişiselleştirilmiş reklam geliri korunuyor).
- Daha fazla teknik/kod detayı için [CLAUDE.md](CLAUDE.md)'ye bak.
