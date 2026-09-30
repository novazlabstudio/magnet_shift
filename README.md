# 🧲 Magnet Shift — Kurulum & Çalıştırma Rehberi

## 1. Godot Engine İndir

👉 https://godotengine.org/download

- **"Godot Engine - .NET" değil, standart versiyonu indir** (GDScript kullanıyoruz)
- Sürüm: **Godot 4.2** veya üzeri
- Windows için `.zip` indir, çıkart, `Godot_v4.x_win64.exe` çalıştır — kurulum yok

---

## 2. Projeyi Aç

1. Godot'u başlat → **"Import"** butonuna tıkla
2. Bu klasördeki `project.godot` dosyasını seç
3. **"Import & Edit"** de

---

## 3. Telefonda Çalıştırma (Android Debug)

### Ön Koşullar (sende zaten var)
- Android Studio kurulu ✅
- Android SDK kurulu ✅

### Godot Ayarları
1. Godot'ta → **Editor → Export Templates** menüsünden Android template indir
   (veya: Editor → Manage Export Templates → Download)
2. **Project → Export → Add → Android** ekle
3. Android SDK path'i göster:
   - Editor → Editor Settings → Export → Android
   - `sdk_path` = Android Studio'nun SDK klasörü
     (genellikle: `C:/Users/KULLANICIADI/AppData/Local/Android/Sdk`)

### USB Debug
1. Telefonunda **Geliştirici Seçenekleri** aç
2. **USB Hata Ayıklama** aktif et
3. Telefonu USB ile bağla
4. Godot'ta sağ üst köşe → küçük **Android ikonu** → **"Run on Device"**

---

## 4. Proje Yapısı

```
magnet_shift/
├── project.godot          # Ana proje config
├── scenes/
│   ├── MainMenu.tscn      # Ana menü
│   ├── Level1.tscn        # Bölüm 1 (kolay - 2 mıknatıs, 3 coin, lazer)
│   └── Level2.tscn        # Bölüm 2 (orta - 3 mıknatıs, 4 coin, bekçi, yanıp sönen lazer)
└── scripts/
    ├── GameManager.gd     # Input, skor, win/lose kontrolü
    ├── Player.gd          # Metal zırhlı hırsız (fizikle hareket eder)
    ├── Magnet.gd          # Mıknatıs çekim mantığı
    ├── Coin.gd            # Toplanabilir altın
    ├── Laser.gd           # Lazer engeli (static veya yanıp sönen)
    ├── Guard.gd           # Devriye bekçisi (ileri-geri)
    ├── ExitDoor.gd        # Çıkış kapısı
    └── MainMenu.gd        # Menü script
```

---

## 5. Oyun Mekaniği

| Eylem | Kontrol |
|-------|---------|
| Mıknatısı aktifleştir | Ekrana dokun (tap & hold) |
| Bırak, yerçekimine düş | Parmağı kaldır |

- **Mavi kareler** = Mıknatıslar (aktifken neon mavi yanar)
- **Sarı kareler** = Coin (topla)
- **Kırmızı çubuklar** = Lazer (ölüm)
- **Turuncu figür** = Bekçi (değerse ölüm)
- **Yeşil dikdörtgen** = Çıkış kapısı

---

## 6. Bilinen Limitler (İlk Prototip)

- Görseller geometrik şekil (sprite yok) — kasıtlı, hızlı iteration için
- Ses yok — sonraki adımda eklenecek
- Level 2 sonrası "Tüm bölümler bitti" ekranı yok — `next_level_path` boş bırakıldı

---

## Sonraki Adımlar (konuşabiliriz)

- [ ] Görsel polish (neon glow shader, particle efektler)
- [ ] Dönen testere engeli
- [ ] Ses efektleri (coin collect, death, magnet hum)
- [ ] Level 3-5 tasarımı
- [ ] AdMob rewarded ad entegrasyonu
- [ ] Google Play Store export & signing
