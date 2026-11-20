#!/bin/zsh
HERE="$(cd "$(dirname "$0")" && pwd)"
# Test kopyasını güncelle: kaynak + stub autoload'lar + ayrı kullanıcı klasörü
SCR=${MS_SCR:-/tmp/magnet_shift_harness}
T=$SCR/ms_test
rsync -a --exclude .git --exclude android/build --exclude build --exclude .godot ~/magnet_shift/ $T/
cp $HERE/AnalyticsStub.gd $T/scripts/AnalyticsManager.gd
cp $HERE/AdStub.gd $T/scripts/AdManager.gd
mkdir -p $T/test
cp $HERE/Runner.gd $T/test/Runner.gd 2>/dev/null
python3 -I - "$T/project.godot" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
if "custom_user_dir_name" not in s:
    s=s.replace("[application]\n","[application]\n\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=\"magnet_shift_test\"\n",1)
s=re.sub(r'enabled=PackedStringArray\([^)]*\)','enabled=PackedStringArray()',s)
open(p,"w").write(s)
PY
python3 -I - "$T/project.godot" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
if "TestRunner=" not in s:
    s=s.replace('RunMode="*res://scripts/RunMode.gd"\n','RunMode="*res://scripts/RunMode.gd"\nTestRunner="*res://test/Runner.gd"\n',1)
open(p,"w").write(s)
PY
if [ -n "$MS_WIN" ]; then
python3 -I - "$T/project.godot" "$MS_WIN" <<'PY'
import sys
p,wh=sys.argv[1],sys.argv[2]; w,h=wh.split("x"); s=open(p).read()
if "window_width_override" not in s:
    s=s.replace("window/size/resizable=false\n","window/size/resizable=false\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n"%(w,h),1)
open(p,"w").write(s)
PY
fi
