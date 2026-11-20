#!/bin/zsh
HERE="$(cd "$(dirname "$0")" && pwd)"
# kullanım: shoot.sh senaryo [ek ortam]
SCR=${MS_SCR:-/tmp/magnet_shift_harness}
mkdir -p $SCR/shots
rm -rf "$HOME/Library/Application Support/Godot/app_userdata/magnet_shift_test" "$HOME/Library/Application Support/magnet_shift_test"
cd $SCR/ms_test
MS_SCENARIO=$1 MS_SHOTS=$SCR/shots $HERE/to ${MS_TIMEOUT:-60} "/Applications/Godot 4.6.app/Contents/MacOS/Godot" --path . --resolution ${MS_RES:-480x1040} ${=MS_EXTRA} 2>&1 | grep -E "SCRIPT ERROR|ERROR|SHOT|DBG|at: |\[AD\]|\[GA\]" | grep -v "resources still in use\|ObjectDB\|core/object\|core/io/resource" | head -40
