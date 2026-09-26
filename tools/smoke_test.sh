#!/bin/bash
# noblelte post-flash smoke test. Usage: ~/smoke_test.sh  (phone booted, adb root)
adb root >/dev/null; sleep 2
ok(){ echo "PASS  $1"; }; bad(){ echo "FAIL  $1"; FAILS=$((FAILS+1)); }; FAILS=0
t(){ eval "$2" >/dev/null 2>&1 && ok "$1" || bad "$1"; }
t "boot completed"          '[ "$(adb shell getprop sys.boot_completed)" = 1 ]'
t "no missing libs"         '! adb logcat -d | grep -iE "CANNOT LINK|library .* not found" | grep -qvE "widevine|armnn"'
t "SIM ready"               'adb shell getprop gsm.sim.state | grep -qE "READY|LOADED"'
t "rild running"            'adb shell pidof rild'
t "wifi enabled"            'adb shell cmd wifi status | grep -qi "Wifi is enabled"'
t "bt profiles A2DP"        'adb shell dumpsys bluetooth_manager | grep -A20 "Enabled Profile Services" | grep -q A2DP'
t "audio HAL running"       '[ "$(adb shell getprop init.svc.vendor.audio-hal)" = running ]'
t "codec2 AAC encoder"      'adb shell dumpsys media.player | grep -q c2.android.aac.encoder'
t "camera HAL listed"       'adb shell dumpsys media.camera | grep -qE "Number of camera devices: [1-9]"'
t "fingerprint HAL"         'adb shell dumpsys fingerprint | grep -qiE "sensorId|prop"'
t "thermal readings"        'adb shell dumpsys thermalservice | grep -q exynos-therm'
t "gpsd running"            'adb shell pidof gpsd'
t "gnss HAL"                'adb shell lshal | grep -q "gnss@1.0::IGnss/default"'
t "GMS privileged"          'adb shell pm path com.google.android.gms | grep -qE "/system|/product"'
t "no crash-loop services"  '! adb shell getprop | grep -E "init.svc.*\]: \[restarting\]" | grep -qvE "armnn|widevine"'
echo "== $FAILS failure(s)"
adb shell getprop | grep -E "init.svc.*\]: \[restarting\]"
# --- declared-but-not-registered HIDL HALs (cause of app/boot hangs: thermal, NFC, widevine) ---
adb shell lshal -i 2>/dev/null | awk '$1 ~ /^DM/ && $2 == "N" {print $3}' > /tmp/hal_dead.txt
adb shell lshal 2>/dev/null | awk '$1 ~ /DM/ && $2 != "Y" {print $3}' >> /tmp/hal_dead.txt
sort -u /tmp/hal_dead.txt | grep -vE "graphics.mapper" | grep . && echo "FAIL  declared-but-dead HALs above (declare only what registers)" || echo "PASS  every declared HAL is registered"
