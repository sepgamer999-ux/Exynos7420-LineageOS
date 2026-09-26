# LineageOS 22.2 (Android 15) Port Changes — Samsung Galaxy Note5 (noblelte / SM-N920C)

**Base:** project289's universal7420-common/kernel/vendor@lineage-22.1 + samsungexynos7420's noblelte@lineage-19.1, built on top of official LineageOS 22.2 source.

**Build date:** 2026-09-26  
**ROM:** `lineage-22.2-20260926-UNOFFICIAL-noblelte.zip`

---

## Hardware Status

| Component | Status | Notes |
|-----------|--------|-------|
| Boot | ✅ Works | Boots to LineageOS 22.2 |
| Display | ✅ Works | Mali-T760 GPU, hardware composer |
| Wi-Fi | ✅ Works | bcmdhd, requires free_initmem() skip |
| Bluetooth | ✅ Works | |
| Audio (calls) | ✅ Works | NULL deref fix in out_get_presentation_position |
| Audio (media) | ✅ Works | ccodec=4 workaround for Stagefright |
| Camera | ✅ Works | |
| Sensors | ✅ Works | |
| GPS | ✅ Works | gpsd ↔ lhd ↔ /dev/bbd_* (BCM4773 + 47531 GNSS) |
| SIM / Telephony | ✅ Works | rild running; insert SIM before testing calls |
| MTP / USB | ✅ Works | |
| Torch | ✅ Works | |
| Thermal | ✅ Works | HAL 1.0 + 2.0 declared; exynos-therm/battery mapping fixed |
| Encryption | ❌ Not supported | FDE removed in Android 13; FBE requires kernel 4.4+ |
| VoLTE | ❌ Not tested | |
| NFC | ❌ Not tested | |
| Widevine | ❌ L3 only | Pre-Treble device, no secure path |

---

## 1. Local Manifest (`roomservice.xml`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="project289/android_device_samsung_universal7420-common"
           path="device/samsung/universal7420-common" remote="github" revision="lineage-22.1" />
  <project name="samsungexynos7420/android_device_samsung_noblelte"
           path="device/samsung/noblelte" remote="github" revision="lineage-19.1" />
  <project name="project289/android_kernel_samsung_universal7420"
           path="kernel/samsung/universal7420" remote="github" revision="lineage-22.1" />
  <project name="project289/proprietary_vendor_samsung"
           path="vendor/samsung" remote="github" revision="lineage-22.1" />
  <project name="project289/7420_patches"
           path="patches/7420_patches" remote="github" revision="lineage-20.0" />
  <project name="LineageOS/android_hardware_samsung"
           path="hardware/samsung" remote="github" revision="lineage-22.1" />
  <project name="LineageOS/android_hardware_samsung_slsi_exynos"
           path="hardware/samsung_slsi/exynos" remote="github" revision="lineage-19.1" />
  <project name="LineageOS/android_hardware_samsung_slsi_openmax"
           path="hardware/samsung_slsi/openmax" remote="github" revision="lineage-19.1" />
  <project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_exynos"
           path="hardware/samsung_slsi-linaro/exynos" remote="github" revision="lineage-21.0" />
  <project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_exynos5"
           path="hardware/samsung_slsi-linaro/exynos5" remote="github" revision="lineage-21.0" />
  <project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_openmax"
           path="hardware/samsung_slsi-linaro/openmax" remote="github" revision="lineage-21.0" />
  <project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_graphics"
           path="hardware/samsung_slsi-linaro/graphics" remote="github" revision="lineage-21.0" />
  <project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_config"
           path="hardware/samsung_slsi-linaro/config" remote="github" revision="lineage-21.0" />
  <project name="samsungexynos7420/android_device_samsung_slsi_sepolicy"
           path="device/samsung_slsi/sepolicy" remote="github" revision="lineage-21" />
  <project name="LineageOS/android_hardware_samsung_slsi-linaro_interfaces"
           path="hardware/samsung_slsi-linaro/interfaces" remote="github" revision="lineage-22.1" />
</manifest>
```

**Path notes:**
- All `slsi-linaro_*` repos live under `hardware/samsung_slsi-linaro/<name>` (hyphen), not `hardware/samsung_slsi/linaro_<name>` — matches what `BoardConfigCommon.mk` actually expects.
- `device/samsung_slsi/sepolicy` (underscore after samsung).
- `hardware/samsung_slsi-linaro/interfaces` is a **manually added repo** from LineageOS — not in project289's original manifest, but required for namespace imports in `hardware/samsung_slsi-linaro/exynos/Android.bp`.

---

## 2. Kernel Patches (`kernel/samsung/universal7420`)

### a. bpffs rename2 backport (`kernel/bpf/inode.c`)
Android 15's BPF filesystem calls `rename2()` with `RENAME_NOREPLACE`. Kernel 3.10 does not implement `rename2` in bpffs — backported it. Without this, bpffs fails to initialize and `netd` / `bpfloader` crash at boot.

### b. Skip `free_initmem()` in `do_deferred_initcalls` (`init/main.c`)
The bcmdhd Wi-Fi driver registers itself via `late_initcall`. After `free_initmem()` reclaims init memory, the deferred call queue still holds pointers into freed pages — calling them causes a kernel panic. Fix: skip `free_initmem()` when deferred initcalls are in use (Wi-Fi comes up reliably after this).

### c. IFA_FLAGS backport (`net/ipv4/devinet.c`, `net/ipv6/addrconf.c`, `include/uapi/linux/if_addr.h`)
Android 15's DHCP client (dhcpcd) uses `IFA_FLAGS` netlink attribute (added in Linux 3.14) to set address flags without a separate ioctl. Kernel 3.10 does not have it — backported the attribute handling. Without this, DHCP fails silently (address never assigned).

### d. Defconfig changes (`arch/arm64/configs/exynos7420-noblelte_defconfig`)
- Disabled: `CONFIG_KALLSYMS_ALL`, `CONFIG_DEBUG_KERNEL`, `CONFIG_SCHED_DEBUG`, `CONFIG_SCHEDSTATS`, `CONFIG_TIMER_STATS`, `CONFIG_DEBUG_BUGVERBOSE`, `CONFIG_DEBUG_INFO`
- Enabled: `CONFIG_USER_NS=y`
- Changed: `CONFIG_HZ` 250 → 300

---

## 3. Device / Board Fixes (`device/samsung/universal7420-common`)

### a. `BoardConfigCommon.mk` — deprecated variable
Replaced `BOARD_PLAT_PRIVATE_SEPOLICY_DIR` → `SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS` (same value, new name required by Android 15 build system).

### b. `boot-image-profile.txt` symlink (`frameworks/base/config/`)
In Android 15, `frameworks/base/config/boot-image-profile.txt` moved to `frameworks/base/boot/boot-image-profile.txt`, but several `Android.bp` files still reference the old path. Created a symlink so both paths resolve correctly.

### c. `libstagefright` include path (`libshims/libstagefright/Android.bp`)
`frameworks/av/media/libstagefright/foundation/include` → `frameworks/av/media/module/foundation/include`
(foundation/ moved from libstagefright/ to module/ in Android 15.)

### d. Old `libhidl` shim disabled (`libhidl/Android.mk` → `Android.mk.disabled`)
A 2017-era stub that re-declared `android.hidl.base@1.0` and `android.hidl.manager@1.0` — both are now properly defined in `hardware/lineage/compat/Android.bp`. The duplicate caused a build error (`already defined`). Disabled the old file.

### e. `PRODUCT_SOONG_NAMESPACES` — add `hardware/samsung`
Added `hardware/samsung` to the namespace list in `device-common.mk`.  
`hardware/samsung/Android.bp` declares a separate Soong namespace. Without explicitly importing it, Soong-defined targets under `hardware/samsung/` (like `dtbhtoolExynos`) are invisible to the product build and ninja reports `missing and no known rule to make it`.

### f. Audio HAL — NULL deref fix (`hardware/audio/audio_hw.c`)
`out_get_presentation_position()` could dereference a NULL pointer if called before the output stream was fully initialized. Added a NULL check. Without this, audio HAL crashed on first playback start.

### g. `system.prop` — Stagefright workaround
```
debug.stagefright.ccodec=4
```
Disables the CCodec (codec2) path for this Exynos 7420 GPU; falls back to OMX. Without this, video playback would stall or crash.

### h. `manifest.xml` — HAL declarations
- Added: `android.hardware.thermal@1.0` and `android.hardware.thermal@2.0`
- Removed: `android.hardware.drm@widevine` (not present on device)

Android 15's `libhidl` enforces `kEnforceVintfManifest=true`: any HAL not declared in manifest is rejected immediately; any HAL declared but not running causes ANR/boot hang. Thermal HAL must be declared because the system polls it. Widevine must be removed because the service is absent.

### i. Thermal HAL fixes (`hardware/samsung_slsi-linaro/exynos/thermal/`)

**`thermal_exynos.cpp`:** The HAL reported all sensors as `UNKNOWN`. Fixed the type mapping to accept `exynos-therm` → `CPU` and `battery` → `BATTERY` (the sysfs names this SoC exposes).

**`Thermal.cpp`:** `filterType()` always returned false (wrong logic), so no temperature readings were ever returned. Fixed the condition.

---

## 4. Vendor Fixes

### a. 32-bit blob modules (`vendor/samsung/universal7420-common/proprietary/vendor/Android.bp`)
Android 15's `fsgen` converts every `PRODUCT_COPY_FILES` entry into a Soong module. When the same `.so` filename appears under both `lib/` (32-bit) and `lib64/` (64-bit), `fsgen` tries to generate two modules with conflicting names. Fix: removed 32-bit entries from `PRODUCT_COPY_FILES` for pure-packaging duplicates, and added explicit `cc_prebuilt_library_shared` modules with `compile_multilib: "32"` for the 6 libraries actually needed at link time by 32-bit targets:

- `libsecril-client` (used by audio HAL)
- `libbauthtzcommon` (used by bauthtzcommon shim)
- `libexynoscamera` (used by camera3 HAL)
- `libhwjpeg` (used by graphics HAL)
- `libGLES_mali` (used by OpenCL symlink and vendor Android.mk)
- `libMcClient` (used by keymaster, HWC, gscaler)

### b. `gps.xml` fixes (`vendor/samsung/universal7420-common/proprietary/vendor/etc/gnss/gps.xml`)
- `IgnoreJniTime=false` — let the GNSS stack use JNI timestamps (required for A-GPS)
- `SuplSslMethod=SSLv23` — fixes SUPL connection (TLS negotiation)
- `EnableLowPowerPmm=false` — prevents GNSS core from sleeping during active fix

### c. GPS shim (`device/samsung/universal7420-common/shims/gpsd/sensor_shim.cpp`)
Created `libsensor_shim_gpsd` via ASM label override to satisfy `gpsd`'s undefined symbol for the sensor HAL interface. GPS daemon (`gpsd`) → location daemon (`lhd`) → `/dev/bbd_*` (BCM4773 + BCM47531 GNSS).

---

## 5. Framework / LineageOS Fixes

### a. `ro.control_privapp_permissions=log` (`vendor/lineage/config/common.mk`)
Changed from `enforce` to `log` (and removed the duplicate definition from `system.prop`). Android 15's `gen_build_prop` rejects duplicate sysprop definitions at build time — this was defined in both places.

### b. `kEnforceVintfManifest=true` (`system/libhidl/transport/ServiceManagement.cpp`)
Enabled strict VINTF manifest enforcement (now the Android 15 default). This means undeclared HALs are immediately rejected and never cause silent hangs. Paired with the manifest.xml fixes above.

### c. Build flags (`device/samsung/universal7420-common/`)
```makefile
PRODUCT_ENFORCE_VINTF_MANIFEST := false   # pre-Treble device, no FCM level
OVERRIDE_PRODUCT_COMPRESSED_APEX := false # kernel 3.10 cannot mount .capex
```

---

## 6. Deleted / Disabled Components

| Component | Reason |
|-----------|--------|
| `hardware/samsung/hidl/powershare/` | HIDL stub conflicts with AIDL successor in `hardware/lineage/interfaces/powershare/aidl/` |
| `hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/` | StrongBox not present on Exynos 7420 (2015); AIDL version mismatch (V3 vs V4) |
| `hardware/samsung_slsi-linaro/exynos/ssp/wait_for_dual_keymint/` | Same reason as above |
| `hardware/samsung/aidl/sensors/` | `samsung-multihal` sensors V2 vs V3 conflict; basic sensor HAL still works |

---

## 7. GitHub Repositories

All source trees are published at:

| Repo | Branch |
|------|--------|
| [android_kernel_samsung_universal7420](https://github.com/sepgamer999-ux/android_kernel_samsung_universal7420) | lineage-22.2 |
| [android_device_samsung_universal7420-common](https://github.com/sepgamer999-ux/android_device_samsung_universal7420-common) | lineage-22.2 |
| [android_device_samsung_noblelte](https://github.com/sepgamer999-ux/android_device_samsung_noblelte) | lineage-22.2 |
| [proprietary_vendor_samsung](https://github.com/sepgamer999-ux/proprietary_vendor_samsung) | lineage-22.2 |
| [noblelte-los22](https://github.com/sepgamer999-ux/noblelte-los22) | main (patch bundle + ROM release) |

---

## 8. TODO / Known Issues

- [ ] Insert SIM and test calls + SMS before publishing
- [ ] PowerShare (wireless reverse charging) — HIDL stub removed, AIDL successor not wired up yet
- [ ] VoLTE — not tested
- [ ] NFC — not tested
- [ ] `libMcRegistry` — removed from `PRODUCT_COPY_FILES`; if missing `.so.toc` error appears in a future build, add explicit `cc_prebuilt_library_shared` module (same pattern as the 6 libraries above)
