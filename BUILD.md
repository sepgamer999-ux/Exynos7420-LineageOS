# LineageOS 22.2 (Android 15) for Samsung Galaxy Note5 (SM-N920C, `noblelte`) — build guide

Everything needed to reproduce the working build from scratch: a local manifest, a patch set
generated from the tested tree, and the exact build procedure. Full technical history and the
reason behind every change: `docs/CHANGES_noblelte_los22.md`.

## 0. Host requirements (tested on my hp zbook 15 g2 8gb ram sdd 480gb sata ssd)
- Linux x86_64(Fedora 44), ~250 GB free disk, 8 GB RAM minimum (tested on 7.6 GB: works with the settings below).
- Swap: zram 16 GB (zstd, priority 100) + a disk swapfile. Do **not** use a huge zram (45 GB zram caused OOM kills).
- Close browsers/IDEs during the first ~50 min (Soong analysis is the most memory-hungry phase).

## 1. Sync
```bash
mkdir -p ~/los22 && cd ~/los22
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs
mkdir -p .repo/local_manifests
```
copy roomservice.xml to .repo/local_manifests before repo sync 

```bash
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags
```

## 2. Apply the patch set
```bash
cd <bundle>
./apply_patches.sh ~/los22
```
Each `patches/<project>/` holds: `PATH` (project path), `BASE` (commit it applies on),
`0001-*.patch` (commits, applied with `git am`) and `9999-noblelte-worktree.patch`
(edits, deletions, symlinks, file modes, new files and binary blobs, applied with `git apply --binary`).
The script is idempotent and stops on the first conflict.

## 3. Environment (every new terminal)
```bash
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
ccache -M 20G
cd ~/los22 && source build/envsetup.sh && breakfast noblelte
```

## 4. Pre-build gate (must be clean)
```bash
bash <bundle>/tools/audit_src.sh | grep -vE "^\s*\[OK\]|^OK|^=="   # must print nothing
```

## 5. Build (live log, low priority so the PC stays usable, alarm at the end)
```bash
nice -n 10 ionice -c3 m bacon -j4 2>&1 | tee ~/full_build.log; bash <bundle>/tools/build_done_alert.sh
```
- If Java tools (metalava) fail with `OutOfMemoryError`, re-run the same command with `-j2`
  (progress is kept; ninja resumes).
- Output: `out/target/product/noblelte/lineage-22.2-*-UNOFFICIAL-noblelte.zip`

## 6. Flash
TWRP → Advanced → ADB Sideload, then `adb sideload lineage-22.2-*.zip`.
First install: format data as usual for a new ROM. Updates: no wipe needed.
GApps (optional): flash NikGApps **after** the ROM. `ro.control_privapp_permissions=log`
is set so missing GApps privapp allowlists do not block boot.

## 7. test everything before release (before publishing anything)
connect your phone to the computer make sure to enable usb debuging and rooted debuging for devloper options in your phone and adb is installed on your computer 
```bash
bash <bundle>/tools/smoke_test.sh     # must report 0 failures (GMS check only after GApps)
```

## Status
Working: display, touch, Wi-Fi (+hotspot), SIM + mobile network (RIL; voice calls/SMS: verify before each release), Bluetooth (+A2DP audio),
speaker, microphone/recording, headphone jack, camera + torch, fingerprint, sensors/compass,
GPS (outdoors), thermal HAL, GApps.
Known issues: NFC (HAL missing, untested), Widevine DRM (Netflix HD; undeclared to avoid app hangs),
armnn NN HAL (not needed), weak indoor GPS, big CPU cluster stays at max frequency (kernel TODO),
banking apps (integrity checks).

## Credits
LineageOS · project289 (universal7420 common tree, kernel, 7420 patches) · samsungexynos7420
(noblelte device tree, slsi-linaro HALs) · Fakeman (LOS21 reference blobs).
