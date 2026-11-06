#!/bin/zsh
# MAGNET SHIFT — Google Play'e yüklenecek imzalı AAB'yi bu Mac'te üretir ve Masaüstüne kopyalar.
# Kullanım: ./tools/build_aab.sh
#
# Gereken:
#   - Godot 4.6.3: /Applications/Godot 4.6.app (+ 4.6.3 export şablonları)
#   - İmza bilgileri: ~/MagnetShift-imza/imza_bilgileri.txt (Git'e GİRMEZ, proje dışında):
#       keystore=/Users/<kullanıcı>/MagnetShift-imza/release.keystore
#       alias=magnetshift
#       password=<keystore şifresi>
#   - Sürüm: export_presets.cfg -> version/code her yüklemede bir öncekinden büyük olmalı (elle artırılır).
#
# Kontroller: imza sertifikası ilk yüklemedeki upload anahtarıyla aynı mı, yerel kütüphaneler 16 KB hizalı mı.
set -e
cd "$(dirname "$0")/.."
GODOT="/Applications/Godot 4.6.app/Contents/MacOS/Godot"
IMZA="${MAGNETSHIFT_IMZA:-$HOME/MagnetShift-imza/imza_bilgileri.txt}"
EXPECTED_SHA256="6C:C3:CF:F6:3A:7D:B7:5B:89:0E:50:73:0F:AE:E1:9B:4D:78:25:2D:E0:C6:9B:97:B9:19:FC:ED:D3:84:13:3B"
TPL="$HOME/Library/Application Support/Godot/export_templates/4.6.3.stable/android_source.zip"
BT=$(ls -d "$HOME"/Library/Android/sdk/build-tools/* | sort -V | tail -1)

[ -x "$GODOT" ] || { echo "HATA: Godot 4.6 bulunamadı: $GODOT" >&2; exit 1; }
[ -f "$IMZA" ] || { echo "HATA: imza bilgileri yok: $IMZA" >&2; exit 1; }

# Android derleme şablonu (Git'te yok); sürüm değişmişse yeniden kur
if [ ! -f android/build/build.gradle ] || [ "$(cat android/.build_version 2>/dev/null)" != "4.6.3.stable" ]; then
  rm -rf android/build
  mkdir -p android/build
  unzip -q -o "$TPL" -d android/build
  printf "4.6.3.stable\n" > android/.build_version
  touch android/build/.gdignore
  echo "Android derleme şablonu (4.6.3) kuruldu."
fi

CODE=$(grep -m1 '^version/code=' export_presets.cfg | cut -d= -f2)
NAME=$(grep -m1 '^version/name=' export_presets.cfg | cut -d= -f2 | tr -d '"')

# İmza bilgileri ortam değişkeni olarak verilir; dosyaya/loga yazılmaz
KS="" KA="" KP=""
while IFS='=' read -r k v || [ -n "$k" ]; do
  case "$k" in
    keystore) KS="$v" ;;
    alias) KA="$v" ;;
    password) KP="$v" ;;
  esac
done < "$IMZA"
[ -f "$KS" ] || { echo "HATA: keystore dosyası yok: $KS" >&2; exit 1; }
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS" GODOT_ANDROID_KEYSTORE_RELEASE_USER="$KA" GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$KP"

mkdir -p build
rm -f build/MagnetShift.aab
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Android" build/MagnetShift.aab 2>&1 | grep -E "ERROR" | grep -v "resources still" || true
# Godot içe aktarırken project.godot'taki bir satırın yerini değiştirebiliyor; içerik aynı
git checkout -- project.godot 2>/dev/null || true
[ -f build/MagnetShift.aab ] || { echo "HATA: AAB üretilemedi." >&2; exit 1; }

# 1) İmza: ilk yüklemedeki upload anahtarıyla aynı olmalı (farklıysa Play reddeder)
# macOS'un /usr/bin/keytool'u Java kurulu değilse çalışmaz; JDK 17'ninkini kullan
KT=$(ls -d "$HOME"/Library/Java/jdk-17*/Contents/Home/bin/keytool 2>/dev/null | head -1)
SHA=$("${KT:-keytool}" -printcert -jarfile build/MagnetShift.aab 2>/dev/null | grep -m1 "SHA256:" | awk '{print $2}')
if [ "$SHA" != "$EXPECTED_SHA256" ]; then
  echo "HATA: imza sertifikası beklenenden farklı!" >&2
  echo "  bulunan : $SHA" >&2
  echo "  beklenen: $EXPECTED_SHA256" >&2
  exit 1
fi

# 2) 16 KB bellek sayfası: tüm 64 bit .so dosyalarında LOAD hizalaması 16384 olmalı
TMP=$(mktemp -d)
unzip -q -o build/MagnetShift.aab 'base/lib/*' -d "$TMP"
python3 - "$TMP" <<'PY'
import os, struct, sys
bad = []
for root, _, files in os.walk(sys.argv[1]):
    for f in files:
        d = open(os.path.join(root, f), 'rb').read()
        if d[:4] != b'\x7fELF' or d[4] != 2:
            continue
        phoff = struct.unpack_from('<Q', d, 0x20)[0]
        es, num = struct.unpack_from('<HH', d, 0x36)
        al = {struct.unpack_from('<Q', d, phoff + i * es + 48)[0] for i in range(num) if struct.unpack_from('<I', d, phoff + i * es)[0] == 1}
        if min(al) < 16384:
            bad.append(f)
if bad:
    print("HATA: 16 KB hizalı olmayan kütüphane:", bad)
    sys.exit(1)
print("16 KB hizalama: tamam")
PY

OUT="$HOME/Desktop/MagnetShift_${NAME}_code${CODE}.aab"
cp build/MagnetShift.aab "$OUT"
echo "Hazır: $OUT ($(du -h build/MagnetShift.aab | cut -f1)) — sürüm $NAME (code $CODE), imza doğrulandı"
