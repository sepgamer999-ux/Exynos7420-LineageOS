# توثيق تعديلات بورت LineageOS 22.2 (Android 15) لـ Samsung Galaxy Note5 (noblelte / SM-N920C)

القاعدة: local_manifest يمزج project289's universal7420-common/kernel/vendor@lineage-22.1 مع samsungexynos7420's noblelte device tree@lineage-19.1، فوق مصدر AOSP/LineageOS الرسمي lineage-22.2.

---

## 1. local_manifest النهائي (`.repo/local_manifests/noblelte.xml`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
<project name="project289/android_device_samsung_universal7420-common" path="device/samsung/universal7420-common" remote="github" revision="lineage-22.1" />
<project name="samsungexynos7420/android_device_samsung_noblelte" path="device/samsung/noblelte" remote="github" revision="lineage-19.1" />
<project name="project289/android_kernel_samsung_universal7420" path="kernel/samsung/universal7420" remote="github" revision="lineage-22.1" />
<project name="project289/proprietary_vendor_samsung" path="vendor/samsung" remote="github" revision="lineage-22.1" />
<project name="project289/7420_patches" path="patches/7420_patches" remote="github" revision="lineage-20.0" />
<project name="LineageOS/android_hardware_samsung" path="hardware/samsung" remote="github" revision="lineage-22.1" />
<project name="LineageOS/android_hardware_samsung_slsi_exynos" path="hardware/samsung_slsi/exynos" remote="github" revision="lineage-19.1" />
<project name="LineageOS/android_hardware_samsung_slsi_openmax" path="hardware/samsung_slsi/openmax" remote="github" revision="lineage-19.1" />
<project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_exynos" path="hardware/samsung_slsi-linaro/exynos" remote="github" revision="lineage-21.0" />
<project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_exynos5" path="hardware/samsung_slsi-linaro/exynos5" remote="github" revision="lineage-21.0" />
<project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_openmax" path="hardware/samsung_slsi-linaro/openmax" remote="github" revision="lineage-21.0" />
<project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_graphics" path="hardware/samsung_slsi-linaro/graphics" remote="github" revision="lineage-21.0" />
<project name="samsungexynos7420/android_hardware_samsung_slsi-linaro_config" path="hardware/samsung_slsi-linaro/config" remote="github" revision="lineage-21.0" />
<project name="samsungexynos7420/android_device_samsung_slsi_sepolicy" path="device/samsung_slsi/sepolicy" remote="github" revision="lineage-21" />
<project name="LineageOS/android_hardware_samsung_slsi-linaro_interfaces" path="hardware/samsung_slsi-linaro/interfaces" remote="github" revision="lineage-22.1" />
</manifest>
```

**ملاحظات على المسارات (لماذا تختلف عن مانفست project289 المنشور علنًا):**
- كل مسارات `slsi-linaro_*` تحت `hardware/samsung_slsi-linaro/<name>` (بشرطة) وليس `hardware/samsung_slsi/linaro_<name>` — لأن `BoardConfigCommon.mk` الفعلي من project289 يتوقع المسار بالشرطة، حتى لو مانفستّه المنشور يقول عكس ذلك (تناقض داخلي في مصادر project289 نفسها).
- `device/samsung_slsi/sepolicy` (بشرطة سفلية بعد samsung) وليس `device/samsung/slsi_sepolicy`.
- `hardware/samsung_slsi-linaro/interfaces` ريبو **جديد أضفناه يدويًا** من `LineageOS` (وليس project289 أو samsungexynos7420) — غير مذكور في مانفست project289 الأصلي، لكنه مطلوب لـ namespace imports في `hardware/samsung_slsi-linaro/exynos/Android.bp`.

---

## 2. تعديلات ملفات مباشرة (patched files)

### أ. Kernel defconfig
**ملف:** `kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig`
- عطّلنا: `CONFIG_KALLSYMS_ALL`, `CONFIG_DEBUG_KERNEL`, `CONFIG_SCHED_DEBUG`, `CONFIG_SCHEDSTATS`, `CONFIG_TIMER_STATS`, `CONFIG_DEBUG_BUGVERBOSE`, `CONFIG_DEBUG_INFO`
- فعّلنا: `CONFIG_USER_NS=y` (كان معطلاً)
- غيّرنا: `CONFIG_HZ` من 250 إلى 300 (`CONFIG_HZ_250` → `CONFIG_HZ_300`)
- نسخة احتياطية محفوظة بامتداد `.bak` في نفس المجلد

### ب. BoardConfigCommon.mk
**ملف:** `device/samsung/universal7420-common/BoardConfigCommon.mk`
- استبدلنا متغيّر مهجور: `BOARD_PLAT_PRIVATE_SEPOLICY_DIR` → `SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS` (السطر 159، نفس القيمة `$(COMMON_PATH)/sepolicy/private`)

### ج. boot-image-profile.txt (symlink)
- حذفنا الملف المفقود `frameworks/base/config/boot-image-profile.txt`
- أنشأنا رابطًا رمزيًا: `frameworks/base/config/boot-image-profile.txt -> ../boot/boot-image-profile.txt`
- السبب: الملف الحقيقي انتقل من `config/` إلى `boot/` في هذا الإصدار من `frameworks/base`، لكن عدة ملفات `Android.bp` أخرى (art, packages/modules/*) لا تزال تشير للمسار القديم.

### د. libstagefright_shim (مسار include قديم)
**ملف:** `device/samsung/universal7420-common/libshims/libstagefright/Android.bp`
- غيّرنا: `frameworks/av/media/libstagefright/foundation/include` → `frameworks/av/media/module/foundation/include`
- السبب: `foundation/` انتقل من `libstagefright/` إلى `module/` في هيكلة `frameworks/av` الحديثة (Android 15).

### هـ. libhidl/Android.mk (تعطيل كامل)
**ملف:** `device/samsung/universal7420-common/libhidl/Android.mk` → أُعيدت تسميته إلى `Android.mk.disabled`
- المحتوى: شيم قديم (2017) يعرّف يدويًا `android.hidl.base@1.0` و `android.hidl.manager@1.0` (مجرد stub يربط بـ `libhidltransport`، بلا `LOCAL_SRC_FILES`).
- السبب: كلا الموديولين معرَّفان الآن رسميًا وبشكل حديث في `hardware/lineage/compat/Android.bp` (الأسطر 235 و242) — تعارض تعريف مزدوج (`already defined by hardware/lineage/compat`) عبر legacy Make (`base_rules.mk:300`).
- **قابل لإعادة الاستخدام لأي جهاز على `universal7420-common`** — نفس التعطيل ينطبق تلقائيًا.

### و. PRODUCT_SOONG_NAMESPACES — إضافة hardware/samsung
**ملف:** `device/samsung/universal7420-common/device-common.mk` (حوالي السطر 364)
- أضفنا `hardware/samsung` إلى قائمة `PRODUCT_SOONG_NAMESPACES` الموجودة.
- **السبب:** `hardware/samsung/Android.bp` يعلن نفسه كـ `soong_namespace` منفصل (يستورد فقط `hardware/google/pixel` و`hardware/google/interfaces`). أي موديول مُعرَّف مباشرة تحت `hardware/samsung/*` (كـ `dtbhtoolExynos` في `hardware/samsung/dtbhtool/Android.bp`) **يكون غير مرئي من منظور namespace المنتج الرئيسي** ما لم يُستورد `hardware/samsung` صراحة في `PRODUCT_SOONG_NAMESPACES`. النتيجة العملية: الموديول يُعرَّف بشكل صحيح تمامًا ويظهر في ملف Soong الوسيط الضخم (`build.lineage_noblelte.ninja`) لكنه **يختفي كليًا** من الملف النهائي القابل للتنفيذ (`out/combined-<product>.ninja`)، فيفشل `ninja` برسالة `missing and no known rule to make it` رغم أن كل شيء يبدو سليمًا ظاهريًا.
- **خطأ ninja الذي كشف المشكلة:** `'out/host/linux-x86/bin/dtbhtoolExynos', needed by '.../dt.img', missing and no known rule to make it`
- **درس عام مهم:** أي وحدة Soong "تظهر" في الشجرة وتُقرأ بلا خطأ لكن `ninja` يرفضها كـ"غير معروفة" — تحقق أولاً من `soong_namespace` في `Android.bp` الجذر لمجلدها، وهل namespace ذاك مُستورد فعليًا في `PRODUCT_SOONG_NAMESPACES` بالمنتج.
- **قابل لإعادة الاستخدام لأي جهاز على `universal7420-common`.**

---

## 3. ملفات/مجلدات محذوفة بالكامل

- `hardware/samsung/hidl/powershare/` — موديول HIDL قديم (`vendor.lineage.powershare@1.0-service.samsung`) يتصادم مع النسخة AIDL الحديثة `vendor.lineage.powershare` من `hardware/lineage/interfaces/powershare/aidl/`. لم يكن مستدعى في `PRODUCT_PACKAGES` أصلاً (يُبنى تلقائيًا فقط بسبب `PRODUCT_SOONG_NAMESPACES`).
  - **لم نُفعّل البديل الحديث بعد** (`vendor.lineage.powershare-service.default` مع `soong_config_set` لـ `powershare_path=/sys/class/power_supply/battery/wc_tx_en`) — **مهمة معلّقة** إن أردنا دعم الشحن العكسي فعليًا.

- `hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/` — ميزة أمان (StrongBox chip) غير موجودة فعليًا في Note5/Exynos7420 (2015)، مصممة لأجيال Samsung أحدث بكثير. تصادمت (V3 مقابل V4 من نفس aidl_interface keymint).
- `hardware/samsung_slsi-linaro/exynos/ssp/wait_for_dual_keymint/` — نفس السبب (تابع لـ strongbox_keymint).
- `hardware/samsung/aidl/sensors/` — موديول `samsung-multihal` لدعم عدة HAL حساسات، تصادم إصدارات (sensors-V2 مقابل V3). **تنبيه: إذا فقد الجهاز دعم الحساسات الأساسي لاحقًا، هذا أول مكان للتحقق منه.**

- **تكرارات lib/ مقابل lib64/ (packaging conflicts) — ✅ الحل النهائي (4 محاولات، الرابعة صحيحة):**
  - **[مُلغى] المحاولة 1 (حذف كل شيء):** كسر `ckati` (`missing libsecril-client`, إلخ). استُرجعت الملفات عبر `git checkout`.
  - **[مُلغى] المحاولة 2 (hardlink):** لم يحل تعارض `fsgen` — Soong يتتبّع بالاسم المعرَّف وليس بمحتوى inode.
  - **[مُلغى] المحاولة 3 (`Android.bp` فارغ في `lib/`):** لم يُغيّر شيئًا — التعارض لم يكن من مسح `Android.bp` التلقائي إطلاقًا.
  - **✅ المحاولة 4 (الصحيحة): اكتشفنا السبب الجذري الحقيقي.** التعارض كان من **آلية `fsgen` الجديدة في Soong التي تُحوّل كل إدخال `PRODUCT_COPY_FILES` تلقائيًا إلى موديول Soong مستقل**، وتُطبّع مسار الوجهة لكل من `lib/` و`lib64/` إلى نفس `vendor/lib64/` النهائي (خطأ/قصور حقيقي في `fsgen` مع أجهزة non-Treble كهذا الجهاز). الحل: **حذف فقط إدخال `PRODUCT_COPY_FILES` للنسخة 32-بت (`lib/`) عندما تكون فعليًا مكررة بلا استخدام فعلي، مع إبقاء الملف الفعلي `.so` على القرص سليمًا** — استخدمنا سكربت Python (`dedupe_vendor_mk.py`، مرفق كملف منفصل) يحذف الإدخال المكرر من ملفات `*-vendor.mk` (`universal7420-common-vendor.mk`, `noblelte-vendor.mk`) تلقائيًا بمطابقة الاسم النسبي.
    - النتيجة: حُذف 29 إدخال من `universal7420-common-vendor.mk` و4 من `noblelte-vendor.mk`. **تعارضات `fsgen` اختفت بالكامل** — وصلنا لأول مرة لمرحلة `ninja` الفعلية.
  - **⚠️ أثر جانبي مهم اكتُشف لاحقًا:** بعض المكتبات (وليس كلها) كانت تحتاج فعليًا لإدخال `lib/` (32-بت) **ليس فقط للتعبئة النهائية، بل لتوليد موديول Soong قابل للربط (linkable, ينتج `.so.toc`) يحتاجه هدف 32-بت (`obj_arm`) آخر** (مثل `audio.primary.universal7420` الذي يحتاج `libsecril-client` بصيغة 32-بت). حذفها بالكامل كسر `ninja` (`missing libsecril-client.so.toc`).
  - **✅ الحل النهائي المُصحَّح: استرجاع انتقائي دقيق.** بحثنا في كل الشجرة (`hardware/`, `device/`, `vendor/`) عن كل مكتبة من الـ30 المحذوفة **مُستخدمة فعليًا كـ `LOCAL_SHARED_LIBRARIES` في أي `Android.mk`** (وليس فقط تعبئة تلقائية)، فوجدنا **6 مكتبات فقط تحتاج الاسترجاع**:
    - `libsecril-client` (يستخدمها `device/samsung/universal7420-common/hardware/audio/Android.mk`)
    - `libbauthtzcommon` (`device/samsung/universal7420-common/libshims/libbauthtzcommon/Android.mk`)
    - `libexynoscamera` (`device/samsung/universal7420-common/libshims/libexynoscamera/Android.mk` وعدة ملفات camera3 في `hardware/samsung_slsi-linaro/`)
    - `libhwjpeg` (`hardware/samsung_slsi-linaro/graphics/base/libhwjpeg/Android.mk` وغيرها)
    - `libGLES_mali` (`vendor/samsung/universal7420-common/Android.mk`, `hardware/samsung_slsi-linaro/exynos/opencl_symlink/Android.mk`)
    - `libMcClient` (noblelte — يستخدمها `hardware/samsung_slsi-linaro/exynos5/libkeymaster/Android.mk` وملفات hwc/gscaler في `hardware/samsung_slsi/exynos/`)
    - **[مُلغى أيضًا] محاولة وسيطة:** استرجعنا سطر `PRODUCT_COPY_FILES` الخاص بـ `lib/` (32-بت) لهذه الستة فقط عبر `sed -i` مباشر. **فشلت** — أعادت نفس تعارض `fsgen` بالضبط لهذه الستة (لأن استرجاع `lib/` مع وجود `lib64/` لنفس الاسم هو بالضبط الحالة التي يفشل فيها `fsgen`، بغض النظر عن سبب الاسترجاع). هذا أكّد أن **أي زوج (lib/ + lib64/) لنفس الاسم النسبي في `PRODUCT_COPY_FILES` سيتصادم دائمًا**، ولا حل جزئي بالاستعادة/الحذف من `PRODUCT_COPY_FILES` وحده.
    - `libMcRegistry` (noblelte) **لم يظهر كمستخدم مباشر في أي `Android.mk`** — تُرك محذوفًا نهائيًا من `PRODUCT_COPY_FILES` (على الأرجح يُحمَّل ديناميكيًا عبر `dlopen` وقت التشغيل، لا يحتاج ربط ساكن وقت البناء) — **إن ظهر خطأ `missing libMcRegistry.so.toc` لاحقًا، طبّق عليه نفس حل الموديول الصريح أدناه**.
  - **✅✅ الحل النهائي الصحيح (يحل المشكلتين معًا): موديولات Soong صريحة ثنائية المعمارية.**
    بدل الاعتماد على `PRODUCT_COPY_FILES` + التحويل التلقائي المعطوب من `fsgen` لهذه الستة مكتبات، عرّفناها يدويًا كموديولات `cc_prebuilt_library_shared` في ملفات `.bp` جديدة، بمعمارية `arm`/`arm64` منفصلة صراحةً، **وحذفنا إدخالات `PRODUCT_COPY_FILES` الخاصة بها (لكل من lib/ و lib64/) نهائيًا من كلا ملفي `*-vendor.mk`** (تحقّقنا بـ `grep -n` أن لا وجود متبقٍ لأي من الأسماء الستة في الملفين). بهذا يتولى Soong وحده – لا `fsgen` ولا Kati – تعريف كلا المتغيرين المعماريين تحت نفس اسم الموديول، فلا يوجد أي تعارض تعبئة (لأن الموديول واحد بمعرّف واحد وليس موديولَين متنافسَين)، وفي نفس الوقت يبقى متاحًا كـ`LOCAL_SHARED_LIBRARIES` بصيغة 32-بت لأي هدف Kati يحتاجه (كـ`audio.primary.universal7420`).
    - **ملف جديد:** `device/samsung/universal7420-common/proprietary-libs-dualarch.bp` — يحتوي 5 موديولات: `libbauthtzcommon`, `libexynoscamera`, `libhwjpeg`, `libGLES_mali` (بـ `relative_install_path: "egl"`), `libsecril-client`. كل موديول:
      ```
      cc_prebuilt_library_shared {
          name: "<lib>",
          vendor: true,
          check_elf_files: false,
          arch: {
              arm:   { srcs: ["proprietary/vendor/lib/<...>.so"] },
              arm64: { srcs: ["proprietary/vendor/lib64/<...>.so"] },
          },
      }
      ```
    - **ملف جديد:** `device/samsung/noblelte/proprietary-libs-dualarch.bp` — نفس النمط لموديول واحد: `libMcClient`.
    - `check_elf_files: false` ضروري لأن هذه ملفات prebuilt من ROM أصلي (stock) وقد لا تمرّ فحوصات ELF الصارمة الافتراضية لـ Soong (rpath/soname strictness).
    - **فحص أمان تصادم الأسماء (namespace collision check):** بحثنا في الشجرة الكاملة عن أي موديول آخر بنفس الاسم:
      - `libhwjpeg` معرَّف أيضًا في `hardware/google/graphics/common/libhwjpeg/Android.bp`. لكن `hardware/google/graphics/common/Android.bp` يعلن `soong_namespace { imports: ["hardware/google/gchips"] }` — namespace منفصل تمامًا عن namespace المنتج الرئيسي، وغير مستورد في `PRODUCT_SOONG_NAMESPACES` الحالي. **آمن.**
      - `libMcClient` معرَّف أيضًا 3 مرات في `hardware/samsung_slsi-linaro/exynos/tee/kinibi{500,510,520}/vendor/ClientLib/Android.bp`. لكن `hardware/samsung_slsi-linaro/exynos/Android.bp` يعلن `soong_namespace { imports: ["hardware/samsung_slsi-linaro/graphics", "hardware/samsung_slsi-linaro/interfaces", "hardware/samsung_slsi-linaro/openmax"] }` — namespace منفصل، و`hardware/samsung_slsi-linaro/exynos` نفسه **غير** مستورد في `PRODUCT_SOONG_NAMESPACES` للمنتج (فقط `hardware/samsung_slsi-linaro/interfaces` مستورد صراحة)، فموديولات kinibi الثلاثة داخل `exynos/tee/` تبقى في namespace غير مرئي من نطاق موديولنا الجديد. **آمن نظريًا — يحتاج تأكيدًا عمليًا من أول `m bacon` بعد هذا التغيير** (إن ظهر خطأ تصادم اسم لأي من المكتبتين، الحل الفوري: إعادة تسمية موديولنا إلى `libhwjpeg_n5` / `libMcClient_n5` + تحديث أي `LOCAL_SHARED_LIBRARIES`/`shared_libs` يشير إليه في شجرتنا فقط).
  - **الملف المساعد (لمرحلة أولية فقط، لم يعد كافيًا وحده):** `dedupe_vendor_mk.py` — سكربت لحذف تكرارات `lib`/`lib64` الفعلية (غير المستخدمة كموديول ربط) من `PRODUCT_COPY_FILES` تلقائيًا. **ملاحظة مهمة للنشر على جهاز جديد:** هذا السكربت وحده **لا يكفي** لأي مكتبة تحتاج فعليًا صيغتي 32/64-بت كموديول ربط (اكتشفنا 6 حالات هنا) — لتلك الحالات، يجب استخدام نمط `cc_prebuilt_library_shared` ثنائي المعمارية أعلاه بدل استرجاع `PRODUCT_COPY_FILES`.

- `frameworks/base/config/boot-image-profile.txt` (الملف الأصلي المفقود، استُبدل بـ symlink — انظر أعلاه)

---

## 4. باتشات مطبَّقة (git am) من مجلد `patches/` (Android 15 netlink/BPF compat patches)
بنية: `patches/{bionic,build_make,frameworks_av,frameworks_base,frameworks_native,hardware_interfaces,packages_modules_Connectivity,packages_modules_DnsResolver,packages_modules_NetworkStack,system_bpf,system_core,system_netd,system_security}/*.patch` + `patches/apply.sh` (يُشغَّل من جذر `~/los22`).

- طُبّقت جميعها بنجاح **إلا واحد تم تخطّيه (نُقل إلى `patches/_skipped/`):**
  - `bionic: Support wildcards in cached hosts file` — فشل (`sha1 information is lacking`) لأن `hosts_cache.c` أُعيد هيكلته في bionic الحديث. **غير حرج** (تحسين اختياري في DNS caching)، مؤجَّل.

---

## 5. مشاكل معروفة لم تُحل بعد (TODO عند النشر لجهاز آخر كـ S6 Edge+)

1. **PowerShare (شحن لاسلكي عكسي) — تحليل مكتمل، التفعيل لا يزال معلّقًا.**
   تحققنا من كود `hardware/lineage/interfaces/powershare/aidl/default/Android.bp` (الخدمة الافتراضية الحديثة `vendor.lineage.powershare-service.default`) ومن منطق `hardware/samsung/hidl/powershare/PowerShare.cpp` الأصلي المحذوف (القسم 3) قبل الحذف. الخلاصة:
   - الخدمة الحديثة تقرأ **مسارًا واحدًا فقط** عبر `soong_config_variable("lineage_powershare", "powershare_path")` (يُترجم إلى `-DPOWERSHARE_PATH="..."` وقت الترجمة)، بالإضافة لعلمين اختياريين `powershare_enabled`/`powershare_disabled` (قيم افتراضية `1`/`0`).
   - منطق Samsung القديم (`PowerShare.cpp`) كان يستخدم **مسارين منفصلين**: `POWERSHARE_PATH` (تفعيل/تعطيل + قراءة الحالة) و`POWERSHARE_STOP_CAPACITY_PATH` (حد أدنى للبطارية يوقف الشحن العكسي تلقائيًا، عبر `getMinBattery`/`setMinBattery`).
   - **المشكلة:** واجهة AIDL/الخدمة الافتراضية الحديثة **لا تعرّف** حاليًا أي `soong_config_variable` أو دالة مكافئة لـ `POWERSHARE_STOP_CAPACITY_PATH` — فقط `powershare_path`. أي تفعيل مباشر سيفقد ميزة "حد أدنى للبطارية" الفرعية (وليس الميزة الأساسية للتشغيل/الإيقاف).
   - **خطوة التفعيل الأساسية (تشغيل/إيقاف فقط، بدون حد أدنى) — لم تُطبَّق بعد، تحتاج إضافة في `device/samsung/noblelte/device.mk`:**
     ```
     PRODUCT_PACKAGES += vendor.lineage.powershare-service.default
     $(call soong_config_set, lineage_powershare, powershare_path, /sys/class/power_supply/battery/wc_tx_en)
     ```
     (المسار مُستخرج حرفيًا من `POWERSHARE_PATH` في كود Samsung الأصلي المحذوف؛ **لم يُتحقق بعد فعليًا من وجود هذا المسار في sysfs الجهاز الحقيقي بعد الإقلاع** — أول شيء يُفحص عند اختبار الميزة: `adb shell ls -la /sys/class/power_supply/battery/wc_tx_en`).
   - **لدعم `stop_capacity` لاحقًا:** يتطلب إما (أ) تعديل `hardware/lineage/interfaces/powershare/aidl/default/Android.bp` و`PowerShare.cpp` الخاصين بـ LineageOS محليًا لإضافة `soong_config_variable` جديد + منطق قراءة/كتابة مكافئ لـ`setMinBattery`/`getMinBattery` الأصلي (تغيير في شجرة `hardware/lineage` المشتركة، يحتاج نفس التعديل يتكرر عند التحديث من upstream)، أو (ب) قبول فقدان هذه الميزة الفرعية والاكتفاء بالتشغيل/الإيقاف فقط.
   - **حالة القسم:** لا يزال TODO — لم تُضف أي من هذه الأسطر فعليًا إلى `device.mk` حتى الآن.

2. ~~آلية تكرار lib/lib64~~ — **✅ حُل جذريًا (انظر القسم 3، "الحل النهائي الصحيح")**: السبب الجذري (`fsgen` لا يميّز 32/64-بت لأي زوج `PRODUCT_COPY_FILES`) عولج نهائيًا عبر موديولات `cc_prebuilt_library_shared` ثنائية المعمارية للمكتبات الست التي تحتاج ربطًا فعليًا؛ دعم 32-بت الحقيقي محفوظ لها. **متبقٍ فقط:** التأكيد العملي من أول `m bacon` أن لا تصادم أسماء فعلي مع `libhwjpeg`/`libMcClient` (احتمال ضعيف، انظر تحليل الـ namespace في القسم 3).

3. **StrongBox Keymint وSensors multihal:** حُذفا بالكامل بدل تصحيح تعارض الإصدارات. إن احتاج جهاز آخر (كـ S6 Edge+ إن كان له شريحة StrongBox فعلية، وهو غير مرجّح لهذا الجيل) هذه الميزات، ستحتاج توحيد إصدار aidl_interface بدل الحذف.

4. **مسارات `frameworks/av` المعاد هيكلتها:** صحّحنا `libstagefright_shim` فقط. **قد تظهر مسارات أخرى مشابهة** (`frameworks/av/media/libstagefright/include` نفسه، أو ملفات أخرى تشير لبنية `libstagefright/` القديمة) في ملفات `Android.bp`/`Android.mk` أخرى لم نصل إليها بعد في هذه الشجرة أو شجرة noblelte نفسها.

5. ~~تعارض `android.hidl.base@1.0`~~ — **✅ حُل (انظر القسم 2-هـ)**: كان `device/samsung/universal7420-common/libhidl/Android.mk` وليس `hardware/audio`، وتم حله بالتعطيل الكامل (`.disabled`).

6. **مسار sysfs الخاص بـ PowerShare (`wc_tx_en`) غير مُتحقَّق منه على جهاز فعلي بعد** — انظر القسم 5-1 أعلاه.

---

## 6. إعداد الأداء (ccache) — طبّقه المستخدم يدويًا
لتقليل زمن إعادة الترجمة الفعلية بعد كل تصحيح (لا يُقلّل زمن إعادة تحليل Kati/Soong، فذلك متأصل في أي تعديل لملف `.mk`، لكنه يجعل خطوة الترجمة الفعلية شبه فورية عند تكرار بناء نفس الكائنات):
```bash
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache        # أو أي مسار بسعة كافية
ccache -M 50G                       # الحد الأقصى لحجم الكاش
```
يجب تصديرها **قبل** `source build/envsetup.sh` و`lunch` في كل جلسة طرفية جديدة (أو إضافتها إلى `~/.bashrc`).

**ملاحظات عملية اكتُشفت أثناء هذا البورت لتقليل عدد دورات إعادة تحليل Kati/Soong (الساعة الواحدة تقريبًا لكل دورة):**
- **جمّع كل الإصلاحات المعروفة في جولة تعديل واحدة قبل إعادة البناء**، بدل إصلاح خطأ واحد ثم إعادة البناء فورًا — كل لمسة لملف `.mk` تفرض إعادة تحليل Kati كاملة بغض النظر عن حجم التعديل.
- استخدم `tmux`/`screen` لضمان استمرار البناء الطويل رغم انقطاع الاتصال بالطرفية.
- تجنّب تعديل أي ملف `.mk` أثناء بناء جارٍ.
- استخدم فحوصات `grep` استباقية عبر الشجرة كاملة (تصادم أسماء الموديولات، مراجع `Android.mk` مفقودة، تكرارات `lib`/`lib64` متبقية) **قبل** كل محاولة بناء، لا بعدها — يوفر دورة كاملة كل مرة يُكتشف فيها خطأ محتمل مسبقًا.

**تحديث (2026-09-18): `-j1` أثناء مرحلة Kati/Soong، لكن `-j4` بعد الوصول لمرحلة `ninja` الفعلية.**
بعد نجاح كل إصلاحات القسم 7 (namespaces + PRODUCT_PACKAGES + VNDK + تعطيل NFC)، تجاوز البناء لأول مرة كل مراحل تحليل Kati/Soong بالكامل ودخل فعليًا مرحلة الترجمة (`ninja`، ظهرت أوامر `clang++`/`rustc`/`aapt2` الفعلية في المخرجات). عند هذه النقطة تحديدًا أعاد المستخدم البناء بـ`-j4` بدل `-j1`. **الفرق الجوهري بين المرحلتين:**
- **مرحلة Kati/Soong (تحليل `.mk`/`.bp`)**: عملية واحدة أساسًا (توازيها الداخلي محدود)، وهي المرحلة التي كانت تفشل بـ`segfault`/تستغرق ساعة على هذا الجهاز (7.62GB RAM) — `-j` لا يُسرّعها كثيرًا و**رفعها هنا يزيد خطر ضغط الذاكرة/السواب** دون فائدة تُذكر.
- **مرحلة `ninja` (الترجمة الفعلية لآلاف ملفات C++/Rust/Java)**: هذه المرحلة **تستفيد فعليًا** من التوازي، لكل عملية `clang++`/`rustc` استهلاك ذاكرة خاص بها، لذا على جهاز بـ7.62GB RAM فقط، **`-j4` يحمل خطر حقيقي لـ OOM أو استخدام swap ثقيل جدًا** إن تزامنت 4 عمليات ترجمة ثقيلة (خصوصًا ملفات C++ الكبيرة كـ`framework-res`/`libbase`). لا يوجد ضمان قاطع أن `-j4` آمن على هذا الجهاز تحديدًا — **إن ظهر تجمّد/segfault/OOM-kill أثناء هذه المرحلة، الحل الفوري هو العودة إلى `-j1` أو `-j2` لبقية البناء** (يمكن استئناف `m bacon` بقيمة `-j` مختلفة بأمان؛ `ninja`/`ccache` يحتفظان بالتقدّم المُنجز).
- **الأوامر المستخدمة فعليًا لهذا البناء الحالي:**
  ```bash
  cd ~/los22
  source build/envsetup.sh
  breakfast noblelte
  time m bacon -j4 2>&1 | tee ~/build_log_$(date +%H%M).txt
  ```
- **مراقبة الذاكرة أثناء البناء (موصى بها بشدة مع `-j4` على هذا الجهاز):** فتح طرفية ثانية وتشغيل `watch -n5 free -h` أو `htop` لمتابعة استهلاك RAM/swap لحظيًا، وخفض `-j` فورًا (Ctrl+C ثم إعادة التشغيل بـ`-j2`) إن اقترب swap من الامتلاء الكامل بثبات (لا يعني الاستخدام المؤقت للسواب مشكلة، لكن الامتلاء الكامل المستمر ينذر بتجمّد أو OOM-kill قريب).

**تحديث (2026-09-18، بعد 87 دقيقة بناء): التحذير أعلاه تحقّق فعليًا — `-j4` سبّب `OutOfMemoryError: Java heap space`.**
البناء تقدّم بنجاح مذهل حتى **11% (20818/181276 هدف)** — أول مرة يتجاوز فيها كل مراحل Kati/Soong بالكامل ويدخل الترجمة الفعلية (`clang++`, `rustc`, `aapt2`, `kotlinc`...) — ثم فشل بخطأ من نوع مختلف تمامًا:
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
    at com.android.tools.metalava.model.text.ApiFile...
FAILED: out/soong/.intermediates/frameworks/base/api/system-api-stubs-docs-non-updatable/...
ninja: build stopped: subcommand failed.
```
**السبب:** `metalava` (أداة JVM تحلّل وتقارن ملفات توقيعات API الكاملة لأندرويد — ملفات ضخمة جدًا) تُشغَّل بحجم `heap` أقصى تُحدّده JVM تلقائيًا عادة كنسبة من الذاكرة **المتاحة وقت الإطلاق**. مع `-j4` وأربع عمليات ترجمة ثقيلة متزامنة (كل واحدة تحجز ذاكرتها الخاصة) على جهاز بـ7.62GB RAM فقط، تضاءلت الذاكرة المتاحة للحظة إطلاق `metalava` لدرجة أن الـheap التلقائي لم يكفِ لمعالجة ملف API الضخم. **هذا ليس خطأ في أي تعديل بالشجرة** — بل قيد صرف لموارد الجهاز، تمامًا كما حذّرنا أعلاه.

**نقطة إيجابية مهمة:** التقدّم حتى 11% محفوظ بالكامل في `ccache`/كائنات `ninja` المُنجَزة — لا حاجة لإعادة البناء من الصفر؛ استئناف `m bacon` بقيمة `-j` أقل يكمل من حيث توقف تمامًا (`ninja` يتخطى كل هدف مُنجَز مسبقًا ويعيد فقط الهدف الذي فشل وما بعده).

**الإجراء المُتَّخذ:** العودة إلى `-j2` (بدل `-j4` أو `-j1`) لبقية البناء — توازن بين الاستفادة من التوازي (أسرع من `-j1`) وتقليل خطر تكرار نفس مشكلة نفاد الذاكرة (أكثر أمانًا من `-j4`):
```bash
cd ~/los22
source build/envsetup.sh
breakfast noblelte
time m bacon -j2 2>&1 | tee ~/build_log_$(date +%H%M).txt
```
**إن تكرر `OutOfMemoryError` حتى مع `-j2`:** الخيار التالي هو `-j1` للبقية (أبطأ لكن الأكثر أمانًا لذاكرة 7.62GB)، أو — كحل بديل يحافظ على بعض التوازي — رفع حجم `heap` الأقصى لـ`metalava` يدويًا عبر متغير بيئة `JAVA_TOOL_OPTIONS="-Xmx4g"` قبل تشغيل `m bacon` (لم يُجرَّب بعد في هذا البورت — أداة تشخيصية احتياطية فقط إن استمرت المشكلة تحديدًا مع أهداف `metalava`/الأدوات المبنية على JVM دون غيرها من أهداف الترجمة).

---

## 7. جلسة إصلاحات إضافية: أخطاء بعد فتح ملف الـ Soong (namespaces متتالية + PRODUCT_PACKAGES)

بعد نجاح إصلاحات القسم 3 (موديولات lib/lib64 الثنائية المعمارية)، ظهرت سلسلة طويلة من الأخطاء الجديدة عند إعادة `m bacon`، تنقسم لثلاث فئات مختلفة تمامًا. التوثيق هنا **يُلغي جزئيًا** ما ورد في القسم 3 عن مكان ملفات `.bp` الجديدة — التصحيح النهائي موثّق هنا.

### أ. خطأ حرج: اسم/مكان ملف `.bp` الجديد كان خاطئًا بالكامل
الملفان اللذان أُنشئا في القسم 3 (`proprietary-libs-dualarch.bp`) **لم يُقرآ إطلاقًا** لسببين متتاليين اكتُشفا بالتتابع:
1. **اسم الملف خاطئ:** Soong يفحص فقط ملفات اسمها **`Android.bp`** حرفيًا، وليس أي ملف بامتداد `.bp`. الحل: دمج المحتوى داخل `Android.bp` الموجود فعليًا في كل مجلد (`device/samsung/universal7420-common/Android.bp` و`device/samsung/noblelte/Android.bp`) عبر `cat ... >> Android.bp` بدل ملف منفصل.
2. **بعد إصلاح الاسم، ظهر خطأ Soong:** `module source path ... does not exist` — لأن مسارات `srcs` نسبية لمكان ملف `Android.bp` نفسه، وقد وُضعت الموديولات في `device/samsung/...` بينما الملفات الفعلية `.so` موجودة تحت **`vendor/samsung/...proprietary/vendor/lib(64)/`** (فصل تقليدي بين `device/` كإعدادات بناء و`vendor/` كـ blobs احتكارية). **الحل النهائي:** نقل كتلتي الموديولات بالكامل إلى `vendor/samsung/universal7420-common/Android.bp` و`vendor/samsung/noblelte/Android.bp` (نفس المسارات النسبية `proprietary/vendor/lib(64)/...` تعمل بشكل صحيح هناك).
- **الدرس العام:** أي موديول `cc_prebuilt_*` جديد يُنشأ يدويًا يجب أن يكون ملفه دائمًا اسمه `Android.bp` بالضبط، وموضوعًا في **نفس الشجرة الفعلية** التي تحوي ملفات `srcs` (`vendor/` للـ proprietary blobs، `device/` فقط لموديولات مبنية من مصدر أو معرّفات بناء).

### ب. سلسلة أخطاء namespace متتالية (بعد إصلاح (أ))
كل مرة أُصلح خطأ "missing module"، ظهر خطأ مشابه لمكتبة أخرى — لأن كل مجلد فرعي تحت `hardware/samsung_slsi-linaro/` و`hardware/broadcom/` و`hardware/lineage/interfaces/*` **يمكن أن يعلن `soong_namespace` منفصلًا خاصًا به بشكل متداخل ومستقل عن الأب**، وكل واحد يحتاج استيرادًا صريحًا في `PRODUCT_SOONG_NAMESPACES` (`device/samsung/universal7420-common/device-common.mk`) بغض النظر عن كون الموديول "موجودًا فعليًا" في الشجرة. القائمة الكاملة المُضافة في هذه الجولة:
- `hardware/samsung_slsi-linaro/exynos` (كان مستوردًا فرعه `cpboot` فقط سابقًا — أصلح `libion_exynos` و`libdisplaycolor_default`)
- `hardware/samsung_slsi-linaro/exynos5`, `hardware/samsung_slsi-linaro/graphics`, `hardware/samsung_slsi-linaro/interfaces`, `hardware/samsung_slsi-linaro/openmax` (أُضيفت جميعها استباقيًا دفعة واحدة بعد اكتشاف أن `samsung_slsi-linaro` بأكملها مقسّمة لـ5 namespaces منفصلة)
- `hardware/broadcom` — أصلح رؤية موديولات المستوى الأعلى، **لكن لم يكفِ وحده** لـ `libbt-vendor`
- `hardware/broadcom/libbt` — namespace متداخل منفصل داخل `hardware/broadcom` نفسه (نفس النمط يتكرر حتى داخل namespace واحد — namespace الابن يطغى على الأب ولا يرث استيراده تلقائيًا)
- `hardware/lineage/interfaces/power-libperfmgr` — namespace متداخل منفصل أيضًا (لاحظ أن `hardware/lineage/interfaces/powershare` **لا** يحتاج نفس المعاملة لأنه لا يعلن `soong_namespace` خاصًا به إطلاقًا — كل مجلد يُفحص على حدة، لا قاعدة عامة).
- **الدرس العام النهائي:** عند ظهور خطأ "missing module" لموديول تؤكد أنه معرَّف بشكل صحيح في `Android.bp`، تحقق دائمًا من `soong_namespace` في **كل مستوى** من مساره (المجلد نفسه، ثم كل مجلد أب حتى الجذر) — النطاق الفعلي هو أقرب `soong_namespace` معلن صراحة، وليس بالضرورة أول مجلد بمستوى أعلى.

### ج. تنظيف شامل لـ `PRODUCT_PACKAGES` في `device-common.mk` (موديولات من جيل lineage-19.1 القديم لا مقابل لها بنفس الاسم في مصدر 22.2)
بعد حل كل أخطاء الـ namespace، ظهر خطأ من نوع مختلف تمامًا: تحذير Kati "`includes non-existent modules in PRODUCT_PACKAGES`" — لأن شجرة `device-common.mk` (من فرع lineage-19.1/18.1 القديم في المانفست الأصلي) تشير لأسماء موديولات HIDL قديمة اختفت أو أُعيدت تسميتها بالكامل في LineageOS 22.2/Android 15. تحقيق شامل (بحث بعلامات تنصيص لـ Soong + بلا علامات لـ Android.mk + بحث ويب لمصدر `hardware/broadcom` الرسمي) حدّد لكل حالة إن كانت **حُذفت فعليًا** (فقدان ميزة) أو **أُعيدت تسميتها فقط** (تصحيح بسيط):

| الميزة | الاسم القديم (محذوف) | الحالة | الإجراء |
|---|---|---|---|
| Audio A2DP | `audio.a2dp.default` | غير موجود، غير مطلوب (يوجد `audio.bluetooth.default` بديل) | حذف |
| DRM | `android.hardware.drm@1.4-service.clearkey` | غير موجود | حذف (أُبقي `@1.0-impl`/`-service`) |
| **البصمة (Fingerprint)** | `android.hardware.biometrics.fingerprint@2.3-service.samsung` | **لا بديل بأي اسم في الشجرة كاملة** | **حذف — TODO: الميزة معطّلة تمامًا حتى إيجاد/كتابة بديل** |
| OMX | `android.hardware.media.omx@1.0-impl` | غير موجود (النسخة `-service` سليمة وبقيت) | حذف `-impl` فقط |
| Power | `android.hardware.power-service.samsung-libperfmgr` | أُعيد تسميته لـ `android.hardware.power-service.lineage-libperfmgr` (`hardware/lineage/interfaces/power-libperfmgr/aidl`) | **إعادة تسمية** |
| Thermal | `android.hardware.thermal@2.0-service.samsung` | أُعيد تسميته لـ `android.hardware.thermal@2.0-service.exynos` (نفس الملف بالضبط في `hardware/samsung_slsi-linaro/exynos/thermal/`) | **إعادة تسمية** |
| **الثقة (Trust)** | `vendor.lineage.trust@1.0-service` | **لا بديل بأي اسم في الشجرة كاملة** | **حذف — TODO** |
| USB | `android.hardware.usb@1.0-impl` + `android.hardware.usb@1.0-service.basic` | أُعيد تسميته لـ `android.hardware.usb@1.3-service.basic` (من `hardware/lineage/interfaces/usb/1.3-basic/`؛ اختير `basic` لأن Note5 منفذ microUSB بلا Type-C/dual-role) | **إعادة تسمية واحدة بدل سطرين** |
| Wifi أدوات مساعدة | `libnetcmdiface`, `macloader`, `wifiloader`, `wifilogd`, `wlutil` | **حُذفت معماريًا بالكامل من `hardware/broadcom/wlan/bcmdhd` الحديث** (لم تعد موجودة حتى بالاسم القديم في المصدر الرسمي — العمارة الحديثة تدير الشريحة عبر `wifi_hal`/`wpa_supplicant`/`wificond` مباشرة، لا حاجة لأدوات وسيطة منفصلة) | حذف الخمسة |
| Wifi HAL | `android.hardware.wifi@1.0-impl` + `android.hardware.wifi@1.0-service` (HIDL قديم) | أُعيد تسميته/استُبدل بـ `android.hardware.wifi-service` (AIDL من `hardware/interfaces/wifi/aidl/default/`، يعتمد داخليًا على `wifi_hal` من bcmdhd لنفس الشريحة) | **إعادة تسمية — ضروري جدًا، بدونه Wifi لن يعمل إطلاقًا** |
| Graphics | `libfimg` | غير موجود (فقط `libfimg4x`/`libfimg5x` من شجرة `samsung_slsi/exynos` القديمة غير ذات الصلة) | حذف |

**ملاحظة منهجية مهمة:** الفحص بعلامات تنصيص (`grep '"$mod"'`) وحده **غير كافٍ** لأنه يطابق فقط تعريفات Soong (`Android.bp`)، ويفوّت موديولات `Android.mk` القديمة (`LOCAL_MODULE := x` بلا علامات تنصيص) — يجب دائمًا فحص كلا النمطين معًا عند البحث عن موديول "مفقود".

### د. مشكلة غير محلولة بعد: انهيار `ckati` (segfault) بعد كل الإصلاحات أعلاه
بعد تطبيق كل ما سبق، فشل البناء بـ`exit status 139` (SIGSEGV) داخل `ckati` نفسه أثناء تحليل `Parser::ParseIfeq`/`ParseIfdef`/`ParseDefine` — **ليس خطأ تكوين بل انهيار البرنامج نفسه**. التحقيق حتى الآن:
- فحص توازن `ifeq`/`ifdef`/`ifndef`/`ifneq` مقابل `endif` في كل الملفات المعدَّلة هذه الجلسة: **متوازن تمامًا** — السبب ليس في تعديلاتنا المباشرة (على الأقل ليس بهذا الشكل البسيط).
- لا دليل على OOM-kill في `dmesg`.
- محاولة تحليل الـ coredump عبر `gdb` **فشلت** بسبب امتلاء مساحة `/tmp` أثناء فك ضغط ملف core (485MB مضغوط)، رغم وجود مساحة كافية على `/home` و`/` — يُرجَّح أن `/tmp` مُركَّب كـ`tmpfs` بحجم محدود من الـ RAM المحدودة أصلًا (7.62GB فقط، أقل من الحد الأدنى الموصى به 16GB).
- **التوصية القادمة:** (1) تحرير/تحديد مساحة `/tmp` أو استخراج الـ core إلى مسار على `/home` بدلًا منه، (2) إعادة تشغيل الجهاز لتفريغ الذاكرة المُجزّأة قبل إعادة المحاولة (نظرًا لساعات من swap الثقيل المتراكم)، (3) إن تكرر الانهيار تحديدًا، فحص الشجرة الكاملة (وليس فقط الملفات المعدَّلة) عن `ifeq`/`endif` غير متوازن، لأن حذف موديولات من `PRODUCT_PACKAGES` قد يكون غيّر مسار تضمين ملفات أخرى (conditional includes) لم تُفحص بعد.

---

## 7-هـ. تحديث: انهيار `ckati` (segfault) كان عابرًا (transient) وليس عيبًا في الشجرة
بعد إعادة تشغيل الجهاز (بدون أي تعديل إضافي على الشجرة) وإعادة `breakfast noblelte && m bacon -j1`، **لم يتكرر الانهيار إطلاقًا** — تقدّم البناء لمرحلة لاحقة تمامًا بخطأ مختلف كليًا (انظر 7-و). هذا يؤكد أن سبب الانهيار كان ضغط ذاكرة/swap متراكم على الجهاز (7.62GB RAM فقط) وليس أي خلل في ملفات `.mk` المعدَّلة. **لا حاجة لمزيد من التحقيق في هذا الموضوع** ما لم يتكرر الانهيار مستقبلًا.

**إجراء وقائي مُطبَّق:** رفع حد `ccache` من 10G إلى 20G (`ccache -M 20G`) لتقليل وقت إعادة الترجمة الفعلية عند تكرار دورات البناء (لا علاقة لهذا بمرحلة Kati/الانهيار نفسها — ccache يعمل فقط بعد الوصول لمرحلة الترجمة الفعلية).

**طلب معلّق غير مُنفَّذ:** رفع `zram` من الحجم الافتراضي (~22.9G) إلى 32G بشكل دائم عبر `/etc/systemd/zram-generator.conf` — طُلب لكن لم يُتابَع حتى الآن. إن رغب المستخدم لاحقًا، القالب المقترح:
```ini
[zram0]
zram-size = 32768
compression-algorithm = zstd
```

## 7-و. `NfcNci` يفشل بفحص `platform_availability_check` (APEX availability) — غير محلول بعد، مُشخَّص جزئيًا فقط
بعد زوال انهيار `ckati`، ظهر خطأ من `build/make/core/tasks/platform_availability_check.mk`: موديول `NfcNci:packages/apps/Nfc` مُعلَّم كغير متاح للـ platform (فحص توافق APEX). تحقّقنا مباشرة من `packages/apps/Nfc/Android.bp` — الموديول نفسه **يحمل بالفعل** `apex_available: ["//apex_available:platform"]` بشكل صحيح. إذن السبب الحقيقي هو **اعتماد متعدٍّ (transitive dependency)** غير متاح للـ platform — المشتبه به الأول (غير مؤكد) هو `framework-nfc.impl` ضمن `libs:` الخاصة بـ NfcNci، لكن لم يُتحقق منه بعد بشكل قاطع.

**إجراء تشخيصي مؤقت فقط (ليس إصلاحًا):** تشغيل `ALLOW_MISSING_DEPENDENCIES=true m bacon -j1` لتجاوز هذا الخطأ مؤقتًا ورؤية ما وراءه — لم يُعدَّل أي ملف. سمح هذا بتقدّم البناء بالكامل عبر Kati و`ninja` (46 دقيقة) حتى الوصول لخطأ VNDK منفصل تمامًا (انظر 7-ز أدناه)، مما يعني أن `NfcNci` **لم يُحل بعد** وسيعاود الظهور فور إزالة `ALLOW_MISSING_DEPENDENCIES`.

**الخيارات المتبقية لحل NfcNci حلاً حقيقيًا (لم يُقرَّر أي منها بعد):**
1. تتبّع السلسلة الكاملة لاعتمادات `NfcNci` (`libs:`, `static_libs:`, إلخ في `packages/apps/Nfc/Android.bp` و`framework-nfc`) وإضافة `apex_available` الناقص للموديول الفعلي المخالف.
2. إن تعذّر إصلاح الاعتماد (مثلاً كان جزءًا من AOSP الأساسي غير قابل للتعديل بأمان)، حذف NFC بالكامل من `PRODUCT_PACKAGES` وتوثيقه TODO **بنفس أسلوب Fingerprint/Trust** في القسم 7ج.
3. البحث عن نسخة NFC بديلة غير-mainline (كما فعلت بعض أجهزة Exynos7420 الأخرى) إن وُجدت في شجرة samsungexynos7420 أو project289.

## 7-ز. إصلاح: `ninja` — VNDK prebuilt `libprotobuf-cpp-full.so` (32-بت) "مفقود ولا توجد قاعدة لبنائه"
بعد تجاوز NfcNci تشخيصيًا، ظهر خطأ `ninja` جديد كليًا (فئة مختلفة تمامًا — ملف VNDK prebuilt مفقود فعليًا، وليس مشكلة namespace/تكوين):
```
FAILED: ninja: 'prebuilts/vndk/v29/arm64/arch-arm-armv8-a/shared/vndk-core/libprotobuf-cpp-full.so', needed by
'out/target/product/noblelte/system/vendor/lib/libprotobuf-cpp-full-v29.so', missing and no known rule to make it
```

**التشخيص الكامل (بالترتيب):**
1. `find prebuilts/vndk/v29 ...` رجع فارغًا تمامًا — تحقّقنا: **مجلد `prebuilts/vndk/v29` غير موجود إطلاقًا** في شجرة الجهاز (فقط v30–v34 موجودة فعليًا على القرص).
2. فحص `.repo/manifests/default.xml`: **`v29` غير مذكور في أي manifest** لهذا الفرع (فقط `prebuilts/vndk/v30` حتى `v34` معرّفة كمشاريع repo) — و`repo sync prebuilts/vndk/v29` يفشل بـ`error: project prebuilts/vndk/v29 not found`. إذن السطور الأصلية في `device-common.mk` كانت **بقايا يتيمة من شجرة `project289` القديمة** (استهدفت غالبًا Android إصدار أقدم يستخدم VNDK v29)، ولم تُحدَّث عند رفع القاعدة إلى LineageOS 22.2/Android 15.
3. فحص `grep -rn "BOARD_VNDK_VERSION\|vndk/v29"` عبر الشجرة كاملة: **المرجع الوحيد لـ `v29` في كل الشجرة هو هذه الأسطر الأربعة نفسها** — لا `BOARD_VNDK_VERSION=29` معرّف في أي `BoardConfig`. هذا يستبعد أي اعتماد بنيوي حقيقي على نسخة VNDK محددة.
4. **السؤال الحاسم:** هل أي مكتبة مثبَّتة فعليًا على الجهاز تحتاج `libprotobuf-cpp-full-v29.so` أو `libprotobuf-cpp-lite-v29.so` تحديدًا بالاسم (SONAME)؟ فحصنا عبر `readelf -d` على الثنائيات الاحتكارية الوحيدة المرشَّحة (`libwvhidl.so`, `libwvdrmengine.so` — مكتبات Widevine DRM):
   - **`libprotobuf-cpp-lite-v29.so` مطلوبة فعليًا (`NEEDED`)** من كلا الملفين.
   - **`libprotobuf-cpp-full-v29.so` غير مطلوبة إطلاقًا من أي ثنائي في الشجرة** — الإدخالان الخاصان بها في `PRODUCT_COPY_FILES` (كانا يشيران لملف `full` من VNDK v29) كانا **كودًا ميتًا بالكامل**.
5. البحث عن نسخة `lite` منفصلة ضمن blobs الجهاز الاحتكارية: **لا توجد** — لكن الجهاز يملك فعليًا `libprotobuf-cpp-full-3.9.1.so` (SONAME حقيقي: `libprotobuf-cpp-full-3.9.1.so`) في كل من `vendor/samsung/universal7420-common/proprietary/vendor/lib/` و`lib64/` (موثّق مسبقًا في `proprietary-files.txt` ومُنسوخ فعليًا عبر `universal7420-common-vendor.mk`). بروتوبوف "full" هو دائمًا **مجموعة شاملة (superset)** لرموز "lite" (full = lite + reflection API) — تأكدنا عمليًا: `nm -D --defined-only` على الملف أظهر 4805 رمزًا معرَّفًا، وهو عدد يتوافق مع نسخة full كاملة تغطي كل ما تحتاجه lite.

**محاولة أولى (فشلت بتصادم توزيع Soong):** نسخ `libprotobuf-cpp-full-3.9.1.so` مرتين (من `lib/` و`lib64/`) إلى وجهتين مختلفتين (`lib/libprotobuf-cpp-lite-v29.so` و`lib64/libprotobuf-cpp-lite-v29.so`) — فشل البناء بخطأ Soong `packaging conflict at vendor/lib64/libprotobuf-cpp-lite-v29.so` لأن **كلا الملفين المصدر 64-بت فعليًا رغم أن أحدهما موضوع خطأً في مجلد `lib/`** (تأكيد عبر `file`: كلاهما "ELF 64-bit ... aarch64"، ونفس MD5 تمامًا) — `fsgen` يحدد مجلد التثبيت الفعلي حسب معمارية ELF الحقيقية للملف، فتصادم الاثنان معًا في `lib64` رغم اختلاف الوجهة المكتوبة.

**التشخيص الإضافي الذي كشف الحل الصحيح:**
- تحقّقنا (`file`) من أن `libwvhidl.so`/`libwvdrmengine.so` (مستهلكا `libprotobuf-cpp-lite-v29.so` الفعليان) **32-بت فقط — لا نسخة 64-بت لهما إطلاقًا** في هذا الجهاز. إذن **الوجهة الوحيدة المطلوبة فعليًا هي `lib/libprotobuf-cpp-lite-v29.so` (32-بت)**؛ إدخال `lib64` كان زائدًا وسيُحذف بالكامل.
- بحثنا عن مصدر 32-بت حقيقي (ليس `libprotobuf-cpp-full-3.9.1.so` المكرر خطأً) في `prebuilts/vndk/v30` حتى `v34` — **لا وجود لأي ملف protobuf بأي إصدار VNDK متاح** (المكتبة لم تعد جزءًا من `vndk-core` في هذه الإصدارات الحديثة).
- بحث أوسع كشف `prebuilts/misc/protobuf_vendorcompat/{arm,arm64}/libprotobuf-cpp-lite-3.9.1.so` — مسار مخصص فعليًا في AOSP الحديث لتوافق البلوبات القديمة (legacy vendor blobs) مع protobuf، غير مستخدَم سابقًا في أي مكان بالشجرة. تأكّدنا (`file`/`readelf`) أن نسخة `arm/` هي فعلًا ELF 32-bit ARM EABI5 صحيحة بـ SONAME داخلي `libprotobuf-cpp-lite-3.9.1.so`.

**الحل النهائي المُطبَّق** (`device/samsung/universal7420-common/device-common.mk`, حول السطر 397، استُبدلت الكتلة بأكملها — سطر واحد فقط الآن):
```makefile
PRODUCT_COPY_FILES += \
    prebuilts/misc/protobuf_vendorcompat/arm/libprotobuf-cpp-lite-3.9.1.so:$(TARGET_COPY_OUT_VENDOR)/lib/libprotobuf-cpp-lite-v29.so
```
- حُذف إدخال `full-v29.so` بالكامل (كود ميت مؤكَّد — لا شيء يطلبه بـ`DT_NEEDED`).
- حُذف إدخال `lib64` بالكامل (لا شيء 64-بت يطلب `-lite-v29`؛ `libwvhidl.so`/`libwvdrmengine.so` 32-بت فقط).
- المصدر الوحيد المتبقي: `prebuilts/misc/protobuf_vendorcompat/arm/libprotobuf-cpp-lite-3.9.1.so` (32-بت حقيقي) → الوجهة `lib/libprotobuf-cpp-lite-v29.so` (اسم الوجهة يطابق ما يتوقعه `libwvhidl.so`/`libwvdrmengine.so` عبر `DT_NEEDED`، بصرف النظر عن SONAME الداخلي للملف نفسه).

**نتيجة التحقق (بناء كامل):** تجاوز هذا الخطأ بصمت تمامًا في محاولة البناء التالية (44 دقيقة) — لم يظهر أي خطأ VNDK/protobuf من جديد.

**الدرس العام (قابل لإعادة الاستخدام لأي جهاز آخر من نفس العائلة):**
- أي `PRODUCT_COPY_FILES` يشير لمسار `prebuilts/vndk/vXX/...` يجب التحقق أولًا أن `vXX` هذا **موجود فعليًا في مانفست الفرع المستهدف** (`grep vndk .repo/manifests/*.xml`) — أرقام VNDK تتبع رقم مستوى API الذي بُنيت عليه شجرة المصدر الأصلية، وقد لا تطابق ما يوفره مانفست LineageOS الحديث المستهدف إطلاقًا.
- عند ظهور "missing and no known rule to make it" لملف VNDK: افحص أولًا (`readelf -d` أو `grep NEEDED`) **هل الملف المطلوب فعليًا** له وجود حقيقي كـ`DT_NEEDED`، **ومن أي معمارية (32 أم 64-بت)** — عبر فحص الثنائي المستهلك نفسه بـ`file`، وليس افتراض أنه يحتاج كلا المعماريتين.
- **قبل استخدام أي ملف proprietary blob كمصدر بديل، تحقّق من معماريته الفعلية بـ`file`/`readelf`** — وجود الملف في مجلد `lib/` لا يعني أنه 32-بت فعليًا؛ بعض الـ blobs المُستخرجة بأدوات غير دقيقة تضع نفس الثنائي 64-بت في كلا المجلدين (نفس MD5)، ومحاولة استخدامه كمصدرين لوجهتين مختلفتين تسبب "packaging conflict" في `fsgen` لأن Soong يعيد توجيه كل نسخة حسب معماريتها الحقيقية بصرف النظر عن المسار المكتوب.
- تحقّق من `prebuilts/misc/protobuf_vendorcompat/{arm,arm64}/` كمصدر أول قبل `prebuilts/vndk/vXX/` عند الحاجة لـ`libprotobuf-cpp-lite`/`-full` بأي إصدار قديم — هذا المسار مخصص أصلًا لتوافق البلوبات القديمة ومضمون التوفر في AOSP الحديث بعكس لقطات VNDK التي قد تُحذف مكتبات منها بمرور الإصدارات.

---

## 7-ح. حذف (تعطيل) NFC بالكامل — `NfcNci` يفشل `platform_availability_check` بلا سبب قابل للعزل يدويًا

بعد حل مشكلة VNDK (7-ز)، عاود ظهور خطأ `NfcNci:packages/apps/Nfc` من `platform_availability_check.mk` كما توقّعنا في 7-و. هذه المرة أُجري **تدقيق كامل ومباشر** (وليس تخمينًا) لكل موديول في سلسلة اعتمادات `NfcNci` المباشرة، بفحص `apex_available` لكل واحد بـ`sed`/`grep` مباشرة على ملفات `Android.bp` الفعلية:

| الموديول | apex_available | ملاحظة |
|---|---|---|
| `NfcNci` نفسه | ✅ صحيح | يشمل `//apex_available:platform` |
| `framework-nfc` (`java_sdk_library`) | ✅ عبر `framework-module-defaults` | يولّد `framework-nfc.impl` تلقائيًا |
| `libnfc_nci_jni` / `libnfc_nci_jni_defaults` | ✅ صحيح | |
| `libnfc-nci` | ✅ صحيح | (كان خارج نطاق أول فحص بـ25 سطر، تأكّد لاحقًا) |
| `libxml2`, `libnfcutils`, `libnfc-nci_flags`, `libstatslog_nfc` | ✅ صحيح لكل منها | |
| `android.hardware.nfc@1.0/1.1/1.2` (HIDL) | ✅ صحيح لكل منها | |
| `android.hardware.nfc` (AIDL، يولّد `-V2-ndk`) | ✅ صحيح | `apex_available` معرّف على مستوى `backend.ndk` في `hardware/interfaces/nfc/aidl/Android.bp` |
| `android_nfc_flags_aconfig_c_lib` (`cc_aconfig_library`) | ✅ صحيح | معرَّف في `frameworks/base/AconfigFlags.bp:352`، يشمل حتى `nfc_nci.st21nfc.default` |
| `libnfc-nci.conf-default` (`prebuilt_etc` مخصص) | (غير قابل للتطبيق عادة) | معرَّف في `system/nfc/conf/Android.bp` |

**النتيجة: كل موديول في السلسلة المباشرة سليم تمامًا.** لم يُعزَل الموديول المخالف الحقيقي — إما اعتماد غير مباشر أعمق لم يُفحص، أو مشكلة توافق `sdk_version`/`min_sdk_version` لا تظهر كغياب `apex_available` بسيط. عزل السبب الحقيقي يتطلب أداة استعلام رسمية لشجرة اعتمادات Soong (غير متاحة يدويًا عبر `grep`)، وقد يستهلك دورات بناء إضافية طويلة (44+ دقيقة لكل محاولة) بلا ضمان نتيجة.

**القرار المُتَّخذ (بطلب المستخدم صراحة):** تعطيل NFC بالكامل بدل الاستمرار في المطاردة اليدوية — بنفس منطق Fingerprint/Trust سابقًا، لكن بطريقة **قابلة للعكس بسهولة** (تعليق بدل حذف فعلي، بناءً على طلب المستخدم صراحة).

**كيف تم التعطيل بالضبط:**
- **الملف:** `device/samsung/universal7420-common/device-common.mk`
- **الموقع:** كتلة `# NFC` (كانت عند الأسطر 232-238 تقريبًا قبل التعديل)
- **الطريقة:** كل سطر من كتلة `PRODUCT_PACKAGES` الخاصة بـNFC (`libnfc-nci`, `libnfc_nci_jni`, `NfcNci`, `Tag`, `com.android.nfc_extras`, `android.hardware.nfc@1.2-service.exynos7420`) عُلِّق بوضع `#` في بداية كل سطر — **لم يُحذف أي سطر فعليًا**. أُضيفت فوقها كتلة تعليق توثيقية تشرح السبب والتاريخ (2026-09-18) وتحيل لهذا القسم من ملف التغييرات.

**كيف تُعاد NFC مستقبلًا (خطوتان فقط):**
1. افتح `device/samsung/universal7420-common/device-common.mk`، ابحث عن `# NFC - DISABLED`.
2. احذف علامة `#` من بداية كل سطر ضمن كتلة `PRODUCT_PACKAGES += \ ... android.hardware.nfc@1.2-service.exynos7420` (احتفظ بأسطر الشرح فوقها أو احذفها، لا فرق وظيفيًا)، ثم أعد البناء.
3. **تحذير:** إن عاد نفس خطأ `platform_availability_check` فورًا، فهذا متوقَّع ومعناه أن السبب الجذري (غير المعزول بعد) لا يزال قائمًا — الإصلاح الحقيقي عندها يتطلب أداة تتبع اعتمادات Soong رسمية، وليس مزيدًا من `grep` اليدوي على نفس القائمة أعلاه (استُنفدت بالكامل).

---

## 7-ط: إصلاح `metalava OutOfMemoryError` ثم اكتشاف قيد رام حقيقي (`kotlinc SIGSEGV`)

**المشكلة الأولى:** بعد تجاوز NFC (7-ح)، وصل البناء لأول مرة إلى مرحلة `ninja` الفعلية، ثم فشل بشكل متكرر (3 محاولات متتالية) بـ:
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```
عند موديول `frameworks/base/api:system-api-stubs-docs-non-updatable` (أداة `metalava`، تحلل ملف توقيعات API ~4.2MB).

**محاولات فشلت:**
1. خفض `-j4` إلى `-j2` — لم يغيّر شيئًا (فشل بنفس المكان تقريبًا فورًا، ما ينفي علاقة التزامن بالمشكلة).
2. `export JAVA_TOOL_OPTIONS="-Xmx4g"` قبل `m bacon` — **لم يصل هذا المتغير إطلاقًا لعملية `metalava`**، لأن Soong يشغّلها داخل بيئة معزولة (`sbox`) تُسقط متغيرات البيئة الخارجية لضمان قابلية إعادة الإنتاج (تأكّدنا بالبحث عن رسالة "Picked up JAVA_TOOL_OPTIONS" في السجل — لم تظهر إطلاقًا).

**التشخيص الجذري:** بحثنا في مصدر Soong نفسه (`build/soong/java/droidstubs.go`، دالة `metalavaCmd`) ووجدنا أن أعلام JVM الممرَّرة فعليًا لـ`metalava` تأتي من `config.JavacVmFlags` المعرَّف في `build/soong/java/config/config.go` (متغير `javacVmFlagsList`). **لم يكن هناك أي `-Xmx` مضبوط في هذه القائمة إطلاقًا** — أي أن JVM كان يعمل بالحجم الافتراضي التلقائي (تقريبًا ربع الرام الفعلي ≈ 1.9GB فقط على جهاز بـ7.6GB رام)، غير كافٍ لتحليل ملف توقيعات API الكبير.

**الإصلاح المطبَّق:**
- **الملف:** `build/soong/java/config/config.go` (نسخة احتياطية محفوظة تلقائيًا بجانبه: `config.go.bak_javacvm`)
- **الموقع:** أول عنصر داخل `javacVmFlagsList = []string{...}` (حوالي السطر 66)
- **التعديل:**
  ```go
  javacVmFlagsList = []string{
      "-J-Xmx6g",
      `-J-XX:OnError="cat hs_err_pid%p.log"`,
      "-J-XX:CICompilerCount=6",
      "-J-XX:+UseDynamicNumberOfGCThreads",
      ...
  }
  ```
- **لماذا هذا الحل صحيح وليس المتغير البيئي:** هذا العلم يُمرَّر كجزء من سطر أوامر تشغيل الأداة نفسها (وليس كمتغير بيئة خارجي)، فيصل حتمًا حتى داخل `sbox`. القيمة 6GB معقولة نظرًا لوجود 54GB swap احتياطي.
- **كيفية التراجع:** استبدل `build/soong/java/config/config.go` بالنسخة الاحتياطية `config.go.bak_javacvm`، أو احذف يدويًا سطر `"-J-Xmx6g",` من `javacVmFlagsList`. هذا يجبر Soong على إعادة تحليل ذاته مرة واحدة فقط (وليس فقدان تقدم `ninja`/`ccache`).
- **النتيجة: نجح فعليًا.** البناء تجاوز `system-api-stubs-docs-non-updatable` نهائيًا ووصل إلى 18% (29765/158436 هدف) دون أي تكرار لخطأ metalava.

**ملاحظة جانبية (غير مؤثرة):** أثناء محاولة إعادة بناء واحدة، ظهر انهيار عابر غير متكرر `panic: SIGSEGV` داخل `soong_build` نفسه (مرحلة `writeAllModuleActions` في blueprint) — لم يتكرر عند إعادة المحاولة مباشرة، ولم يُعثر على أي OOM-kill في `dmesg`/`journalctl` بنفس التوقيت. يُرجَّح أنه خلل تزامن (race) نادر وعابر في blueprint تحت ضغط تحليل كبير، غير متعلق بتعديل `config.go`. لم يُتَّخذ أي إجراء إضافي بخصوصه لأنه لم يتكرر.

**المشكلة الثانية (تم حلها بـ`-j1`):** بعد نجاح إصلاح metalava، وعند الوصول إلى 18% تقريبًا، انهار موديول Kotlin آخر (`HealthConnectLibrary`, `PermissionController-lib`) بانهيار **native حقيقي داخل JVM نفسها** (ليس `OutOfMemoryError` نظيف):
```
SIGSEGV (0xb) ... Problematic frame: V [libjvm.so+0x104dd56] G1CMTask::drain_local_queue(bool)+0x296
```
هذا نمط كلاسيكي لجهاز ينفد رامه الفعلي أثناء swapping شديد (تشغيل `kotlinc` بحد `-Xmx4096M` خاص فيه بالتوازي مع مهام `ninja` أخرى تحت `-j2` يتجاوز سعة 7.62GB رام الفعلية، رغم توفر 54GB swap). من سجل `hs_err_pid*.log` وقت الانهيار: `load average: 10.29 26.16 27.24` على جهاز 8 أنوية فقط، و`MemAvailable` كان ~1.9GB فقط.

**الإجراء المتخذ:** خفض التوازي نهائيًا إلى `-j1` لهذا الجهاز تحديدًا (وليس كخيار مؤقت — قيد رام حقيقي لا يُحل إلا بتقليل عدد العمليات المتزامنة، بما أن الـswap لا يمنع انهيار JVM الـnative تحت ضغط ذاكرة شديد). تحققنا أيضًا أنه لا توجد Kotlin daemons عالقة من محاولات سابقة (`pkill -9 -f "KotlinCompileDaemon\|javac\|kotlinc"` قبل كل إعادة محاولة، احتياطًا). **النتيجة: نجح تمامًا** — البناء بـ`-j1` تجاوز نقطة الانهيار بلا أي مشكلة ووصل لمرحلة أخرى تمامًا (تجميع رؤوس النواة) بعد حوالي 20 دقيقة، مؤكدًا أن `-j1` هو الإعداد الصحيح والدائم لهذا الجهاز تحديدًا (7.62GB رام فعلي غير كافٍ لتشغيل أكثر من عملية JVM ثقيلة واحدة في نفس اللحظة، بصرف النظر عن الـswap المتوفر).

**ملاحظة للأجهزة الأخرى (مثل S6 Edge+):** إذا كان الجهاز المضيف للبناء يملك رامًا أكبر (16GB+)، يمكن تجربة `-j2` أو أعلى مباشرة؛ `-j1` قرار خاص بقيد هذا الجهاز المضيف (7.62GB)، وليس بمشكلة في الكود المصدري نفسه.

---

## 7-ك: سلسلة انهيارات متنوعة (SIGSEGV / deadlock / SIGBUS) — الاشتباه بعطل رام جزئي في الجهاز المضيف

> **تحديث لاحق (2026-09-19):** انهيار سادس من نفس العائلة، هذه المرة في **linker** (`ld.lld`) أثناء LTO linking لموديول `libfcp_cpp_dep_jni` ضمن `FederatedCompute`:
> ```
> clang++: error: unable to execute command: Bus error (core dumped)
> clang++: error: linker command failed due to signal (use -v to see invocation)
> ```
> هذا يوسّع نطاق العائلة المشتبه بها لتشمل أيضًا **رابط LLVM (C++)** وليس فقط JVM/Go كما وُثِّق سابقًا — دليل إضافي على أن السبب الجذري لا علاقة له بلغة/عملية معينة، بل بضغط الذاكرة العام أثناء LTO linking (عملية أخرى، مثل GC، تلمس مساحات ذاكرة كبيرة جدًا بشكل مكثف). المعالجة: إعادة نفس أمر البناء حرفيًا دون تغيير — النمط الثابت في كل الحالات السابقة (5 من 6 مرات نجحت بمجرد الإعادة).

بعد إصلاح كل مشاكل الرؤوس ومشكلة metalava (7-ط، 7-ي)، استمر البناء بالانهيار **بأربعة أنماط مختلفة تمامًا**، كل مرة في عملية/لغة مختلفة، دائمًا أثناء معالجة ذاكرة مكثفة (GC/JIT):

| # | العملية | اللغة | نوع الانهيار | الموقع |
|---|---|---|---|---|
| 1 | `soong_build` (تحليل Android.bp) | Go | `panic: SIGSEGV` | `blueprint/ninja_defs.go` (`writeAllModuleActions`) |
| 2 | `soong_build` (محاولة لاحقة) | Go | **Deadlock كامل** — عشرات الـgoroutines عالقة على نفس القفل | `blueprint/live_tracker.go:44` (`AddBuildDefDeps`) |
| 3 | `soong_build` (محاولة أخرى، بعد `GOMAXPROCS=4`) | Go | `SIGBUS: bus error` أثناء GC scan | `runtime.mspan.heapBitsSmallForAddr` |
| 4 | `r8` (DEX/proguard لـ`FederatedCompute`، بعد `GOMAXPROCS=2`) | JVM | `SIGBUS` أثناء تجميع bytecode | `java.lang.invoke.LambdaForm.compileToBytecode` |

**التشخيص:** تحققنا من كل الأسباب المعتادة واستبعدناها بالكامل:
- لا OOM في `dmesg`/`journalctl` بأي توقيت من هذه الانهيارات.
- مساحة القرص متوفرة بكثرة (49-96GB فارغة على الأقسام ذات الصلة).
- الـswap متوفر بكثرة (54GB، لم يُستهلك منه إلا جزء صغير وقت أي انهيار).
- خفض التوازي تدريجيًا (`-j2`→`-j1`، `GOMAXPROCS=4`→`2`) أخّر ظهور المشكلة (تقدم البناء لمراحل أبعد في كل مرة) لكن **لم يحلها جذريًا** — فقط قلّل تكرارها.
- **الدليل الحاسم:** بعد انهيار `r8` (رقم 4)، أُعيد تشغيل نفس أمر `m bacon` **دون أي تغيير في الإعدادات ودون إعادة إقلاع الجهاز** — ونجح البناء هذه المرة وتجاوز نفس النقطة بالضبط بلا مشاكل. نفس الكود، نفس الأمر، نفس البيئة، نتيجتان مختلفتان — هذا يستبعد أي سبب برمجي حتمي (خلل كود ثابت كان سيتكرر بنفس الشكل)، ويرجّح **عطل رام متقطع (bit-flip)** بدل أي شيء آخر.

**لماذا عطل رام جزئي لا يمنع الإقلاع أو الاستخدام العادي:** عطل الرام النموذجي جزئي جدًا (خلية أو خلايا قليلة من مليارات الخلايا)، ويظهر فقط عند لمس ذلك العنوان المحدد بالضبط — وهو نادر الحدوث في استخدام عادي (تصفح، تحرير نصوص)، لكن يحدث بشكل شبه مضمون عند ملء الرام بالكامل لساعات مع GC مستمر (بالضبط طبيعة بناء AOSP). أنظمة GC (Go وJVM) هي الأكثر قدرة على كشف هذا لأنها تفحص/تعيد كتابة كل بايت من الذاكرة المخصصة باستمرار.

**الحالة الراهنة:** لم يُطبَّق أي حل جذري بعد (يتطلب فحص عتادي `memtest86+` لتأكيد العطل ثم تحديد وحدة/شريحة الرام المعطوبة لاستبدالها أو تعطيلها). **الإجراء المؤقت المتبع:** الاستمرار في إعادة محاولة البناء (`m bacon -j1` مع `GOMAXPROCS=2`) عند أي انهيار من هذا النوع — بما أن `ninja`/`ccache`/Soong يحافظون على كل التقدم السابق، إعادة المحاولة رخيصة (دقائق) ولها فرصة نجاح جيدة كما أثبتت المحاولة الأخيرة.

**للمتابعة لاحقًا:** تشغيل `memtest86+` (يتطلب إقلاع الجهاز من USB، يأخذ عدة ساعات لفحص شامل) لتأكيد العطل نهائيًا وتحديد موقعه، أو `memtester` من داخل Linux (لا يحتاج إعادة إقلاع لكنه أقل دقة). إذا تأكد العطل، الحل الجذري هو استبدال وحدة الرام المعطوبة (أو تشغيل النظام بذاكرة أقل عبر تعطيل الوحدة المعطوبة إن كان الجهاز يحتوي عدة وحدات، كحل مؤقت رخيص).

**ملاحظة للأجهزة الأخرى:** هذا القسم خاص **بالجهاز المضيف للبناء** (`ameen-hpzbook15g2`)، ولا علاقة له بكود البورت نفسه أو بجهاز الهدف (Note5) — لا ينطبق تلقائيًا عند نشر البورت على جهاز مضيف آخر لبناء S6 Edge+ ما لم يكن نفس الجهاز المادي يُستخدم.

---

## 7-ي: إصلاح `kernel headers_install` — ملف UAPI مفقود بسبب اختلاف حالة الأحرف (`xt_CONNMARK.h`)

**المشكلة:** بعد تجاوز مشاكل الذاكرة بالكامل، تقدّم البناء إلى مرحلة تجميع رؤوس النواة (`generated_kernel_includes` → `make headers_install` في `kernel/samsung/universal7420`) وفشل بـ:
```
scripts/Makefile.headersinst:55: *** Missing UAPI file
  .../kernel/samsung/universal7420/include/uapi/linux/netfilter/xt_CONNMARK.h. Stop.
```

**التشخيص:** الملف المطلوب (`xt_CONNMARK.h`، بأحرف كبيرة) **غير موجود فعليًا على القرص**، لكن ملفًا مطابقًا بالمحتوى موجود باسم مختلف بحالة الأحرف: `include/uapi/linux/netfilter/xt_connmark.h` (بأحرف صغيرة بالكامل). السبب الجذري: `include/uapi/linux/netfilter/Kbuild` (السطر 21) يحوي:
```
header-y += xt_CONNMARK.h
```
بينما اسم الملف الفعلي في نفس شجرة kernel/samsung/universal7420 هذه هو `xt_connmark.h` — تعارض/خطأ إملائي قديم في هذه الشجرة تحديدًا، لم يظهر أثره إلا الآن لأن أنظمة الملفات الحساسة لحالة الأحرف (كل توزيعات Linux، بما فيها Fedora) تفرّق بين الاسمين حرفيًا، بعكس أنظمة أخرى غير حساسة لحالة الأحرف كانت قد تتجاوز هذا الخلل بصمت.

**الإصلاح المطبَّق:** رابط رمزي (symlink) بدل تعديل `Kbuild` نفسه (أضمن وأسهل للتراجع، ولا يغيّر أي منطق بناء):
```bash
cd ~/los22/kernel/samsung/universal7420
ln -s xt_connmark.h include/uapi/linux/netfilter/xt_CONNMARK.h
```

**كيفية التراجع:** `rm kernel/samsung/universal7420/include/uapi/linux/netfilter/xt_CONNMARK.h`.

**فحص شامل استباقي (تطبيقًا لمبدأ تجميع الإصلاحات قبل كل محاولة بناء):** بدل انتظار كل ملف مفقود ليظهر في محاولة بناء منفصلة (كل محاولة تُكلّف عشرات الدقائق)، فحصنا **كل** إدخالات `header-y` في **كل** ملفات `Kbuild` تحت `include/uapi` دفعة واحدة، بمقارنة الاسم الحرفي المطلوب مقابل الموجود فعليًا على القرص (بحث case-insensitive للمقارنة). وجدنا **7 حالات إضافية** من نفس نمط اختلاف حالة الأحرف، بالإضافة لحالة ثامنة مختلفة جذريًا:

| الملف المطلوب (بـ`Kbuild`) | الملف الفعلي على القرص | نوع المشكلة |
|---|---|---|
| `include/uapi/linux/netfilter/xt_CONNMARK.h` | `xt_connmark.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter/xt_DSCP.h` | `xt_dscp.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter/xt_MARK.h` | `xt_mark.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter/xt_RATEEST.h` | `xt_rateest.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter/xt_TCPMSS.h` | `xt_tcpmss.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter_ipv4/ipt_ECN.h` | `ipt_ecn.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter_ipv4/ipt_TTL.h` | `ipt_ttl.h` | اختلاف حالة أحرف |
| `include/uapi/linux/netfilter_ipv6/ip6t_HL.h` | `ip6t_hl.h` | اختلاف حالة أحرف |
| `include/uapi/linux/rmnet_data.h` | **غير موجود إطلاقًا في `uapi/`** — فقط `include/linux/rmnet_data.h` (رأس داخلي للنواة) | بنيوي، ليس اختلاف حالة أحرف |

**السبب الجذري العام (للحالات السبع الأولى):** هذه الشجرة (`kernel/samsung/universal7420`) قديمة (مبنية أصلًا على kernel قديم من مصدر Samsung)، وملف `Kbuild` بها يستخدم أسماء `header-y` بأحرف كبيرة (نمط تسمية قديم شائع في نواة Linux لأسماء موديولات `xt_*`/`ipt_*`)، بينما الملفات الفعلية على القرص بأحرف صغيرة (النمط الحديث بعد إعادة تسمية upstream). أنظمة الملفات الحساسة لحالة الأحرف (كل توزيعات Linux) تفشل، بعكس بعض السياقات الأخرى (مثل macOS الافتراضي) التي كانت قد تتجاوز هذا الخلل بصمت — ما يعني أن هذا الخلل موجود في الشجرة منذ فترة طويلة ولم يظهر إلا الآن.

**الإصلاح (7 حالات اختلاف الأحرف) — روابط رمزية دفعة واحدة:**
```bash
cd ~/los22/kernel/samsung/universal7420
ln -s xt_dscp.h    include/uapi/linux/netfilter/xt_DSCP.h
ln -s xt_mark.h    include/uapi/linux/netfilter/xt_MARK.h
ln -s xt_rateest.h include/uapi/linux/netfilter/xt_RATEEST.h
ln -s xt_tcpmss.h  include/uapi/linux/netfilter/xt_TCPMSS.h
ln -s ipt_ecn.h    include/uapi/linux/netfilter_ipv4/ipt_ECN.h
ln -s ipt_ttl.h    include/uapi/linux/netfilter_ipv4/ipt_TTL.h
ln -s ip6t_hl.h    include/uapi/linux/netfilter_ipv6/ip6t_HL.h
```
**كيفية التراجع:** احذف كل رابط رمزي بنفس اسمه (`rm include/uapi/linux/netfilter/xt_DSCP.h` وهكذا لكل واحد) — الملفات الأصلية بأحرف صغيرة لا تُمس إطلاقًا.

**الإصلاح (حالة `rmnet_data.h` — مختلفة):** تحقّقنا أن `rmnet_data.h` **لا نظير له بأي حالة أحرف** في `include/uapi/linux/`، لكن رأسًا داخليًا كاملًا (`include/linux/rmnet_data.h`) موجود ومُستخدَم فعليًا وبنجاح من قِبل سائق `net/rmnet_data/*.c` (تأكدنا عبر `grep`). أي أن هذا السائق لم يُصمَّم أصلًا بأسلوب UAPI الحديث (فصل الرأس الداخلي عن رأس مُصدَّر لمساحة المستخدم) — كل تعريفاته داخلية للنواة فقط. بما أن `header-y` في `Kbuild` يتحكم فقط بنسخ الرؤوس لمساحة المستخدم (توليد NDK headers) ولا علاقة له بترجمة النواة نفسها، فالإصلاح الأضمن هو **تعطيل سطر التصدير** بدل اختراع ملف UAPI وهمي:
```bash
cd ~/los22/kernel/samsung/universal7420
cp include/uapi/linux/Kbuild include/uapi/linux/Kbuild.bak_rmnet_data
# تعليق السطر: header-y += rmnet_data.h  →  # header-y += rmnet_data.h  # DISABLED (سبب في هذا القسم)
```
**كيفية التراجع:** استبدل `include/uapi/linux/Kbuild` بالنسخة الاحتياطية `Kbuild.bak_rmnet_data`، أو أزل علامة `#` يدويًا من بداية السطر.

**الأثر المتوقع:** هذا التعطيل **لا يمنع** أي وظيفة فعلية لـrmnet (شبكة الراديو/الموديم) — يمنع فقط توفر هذا الرأس تحديدًا لتطبيقات مساحة المستخدم عبر NDK، وهو غير مطلوب عمليًا لأن لا أحد من مصادر AOSP/vendor في هذا البورت يتضمن رأس `rmnet_data.h` هذا من مساحة المستخدم (تأكيد عبر `grep -rln "rmnet_data.h"` الذي أظهر استخدامه فقط داخل شجرة النواة نفسها).

**ملاحظة للأجهزة الأخرى (S6 Edge+ إلخ):** إذا كانت تستخدم نفس شجرة `kernel/samsung/universal7420` (مشتركة على مستوى العائلة)، فهذه الروابط الرمزية الثمانية تنطبق تلقائيًا ولا حاجة لإعادة التشخيص — فقط طبّقها مباشرة عند استنساخ نفس شجرة kernel لجهاز جديد من نفس العائلة.

---

## 7-ع: خطأ ترجمة C عادي (وليس sepolicy) — مسار include مفقود لـ `secril-client.h`

**المشكلة:** فشل ترجمة `audio.primary.universal7420_32` (وملفات أخرى تعتمد عليه: `ril_interface.c`, `audience.c`, `voice.c`, `audio_hw.c`) بخطأ:
```
device/samsung/universal7420-common/hardware/audio/ril_interface.h:21:10: fatal error: 'secril-client.h' file not found
```
هذا أول خطأ في هذه الجلسة **من خارج فئة sepolicy** — خطأ ترجمة C تقليدي بسبب `LOCAL_C_INCLUDES` قديم في ملف `Android.mk` (وليس `Android.bp`، هذا موديول Make قديم الطراز ضمن الشجرة).

**التشخيص:**
- `device/samsung/universal7420-common/hardware/audio/Android.mk:49` كان يُشير إلى `hardware/samsung/ril/libsecril-client` — مسار **غير موجود إطلاقًا** كمشروع في `.repo` (لا في المانفست ولا فعليًا على القرص)، بقايا شجرة جهاز أقدم لم تُستبدل عند تجميع البورت الحالي.
- المكتبة المُجمَّعة سلفًا نفسها (`libsecril-client.so`) **موجودة ومُعرَّفة بشكل صحيح** كـ`cc_prebuilt_library_shared` في `vendor/samsung/universal7420-common/Android.bp` (لذا لا مشكلة في الربط `LOCAL_SHARED_LIBRARIES`، فقط في include المطلوب وقت الترجمة).
- الرأس الصحيح فعليًا موجود في مكانين بديلين ضمن `hardware/samsung_slsi-linaro/exynos/libaudio/`: `audioril-sec/include/secril-client.h` و`audiohal_comv1/odm_specific/audioril-sec/include/secril-client.h` — الفرق بينهما 4 قيم `enum` إضافية (VoLTE/LINEOUT) في النسخة الأولى. تحقق (`grep`) أن كود الصوت في هذا الجهاز **لا يستخدم** أيًا من القيم الإضافية، فكلا الرأسين متوافقان وظيفيًا هنا؛ اختير المسار غير المتفرّع (`audioril-sec/include`، وليس نسخة `odm_specific`) لأنه الأعم والأقرب لموديول Make القديم.

**الإصلاح المطبَّق:**
```bash
cd ~/los22
cp device/samsung/universal7420-common/hardware/audio/Android.mk device/samsung/universal7420-common/hardware/audio/Android.mk.bak_secril
# السطر 49 ضمن LOCAL_C_INCLUDES:
# hardware/samsung/ril/libsecril-client \
#   →
# hardware/samsung_slsi-linaro/exynos/libaudio/audioril-sec/include \
```

**كيفية التراجع:** استبدل `device/samsung/universal7420-common/hardware/audio/Android.mk` بالنسخة الاحتياطية `Android.mk.bak_secril`.

**الأثر المتوقع:** لا أثر وظيفي سلبي — نفس تعريفات الـ`enum`/الدوال المطلوبة فعليًا متوفرة، فقط عبر المسار الصحيح الحالي بدل المسار القديم المفقود. `LOCAL_SHARED_LIBRARIES := libsecril-client` لم يُلمس لأنه كان صحيحًا أصلًا.

**ملاحظة لإعادة الاستخدام:** هذا الإصلاح على مستوى `universal7420-common` المشترك، فينطبق تلقائيًا على أي جهاز آخر من نفس العائلة يستخدم موديول `audio.primary.universal7420` هذا. **درس عام:** ليست كل أخطاء البناء المتبقية في هذا البورت من فئة sepolicy — بعد إصلاح سلسلة أخطاء `checkpolicy` (7-ل، 7-م، 7-ن، 7-س)، بدأت تظهر أخطاء ترجمة C/C++ تقليدية بنفس النمط العام (مسارات/مراجع قديمة من شجرة جهاز سابقة لم تُحدَّث لتطابق البنية الحالية للشجرة المدمجة) — يجب التعامل مع كل خطأ حسب فئته الفعلية بدل افتراض تكرار نفس فئة الخطأ السابق.

> **⚠️ تصحيح لاحق — هذا الإصلاح (7-ع) خاطئ واستُبدل بالكامل بـ7-ف أدناه.** الرأسان البديلان (`audioril-sec/include/secril-client.h` وnسخة `odm_specific`) تبيّن أنهما **واجهة مختلفة تمامًا** (خاصة بتطبيق RIL بديل يستخدم `dlopen`/`dlsym`)، ولا يعرّفان أيًا من الدوال/الأنواع الفعلية التي يستدعيها `ril_interface.c` (`OpenClient_RILD`, `HRilClient`, إلخ) — راجع 7-ف للتشخيص والإصلاح الصحيح الكامل.

---

## 7-ف: التشخيص الصحيح لمشكلة `secril-client.h` — استعادة الرأس الأصلي من تاريخ Git لمستودع `hardware/samsung`

**المشكلة (بعد تطبيق 7-ع الخاطئ):** الترجمة نجحت في العثور على ملف، لكن فشلت بعشرات أخطاء "undeclared function"/"unknown type" (`HRilClient`, `OpenClient_RILD`, `RIL_CLIENT_ERR_SUCCESS`, `Connect_RILD`, إلخ) — دليل على أن الرأس المستخدم في 7-ع لم يكن الواجهة الصحيحة إطلاقًا، رغم تطابق الاسم فقط.

**التشخيص الصحيح:**
1. بحث في كل ملفات `.h` بالشجرة عن `OpenClient_RILD` لم يُظهر أي رأس يحتوي هذه الدوال — الواجهة **غائبة تمامًا** من الشجرة الحالية، وليست مجرد مسار خاطئ.
2. تبيّن أن `hardware/samsung_slsi-linaro/exynos/libaudio/audioril-sec/secril_interface.c` (المصدر الوحيد الذي طابق البحث الأول) يستخدم `dlopen`/`dlsym` لتحميل مكتبة RIL الحقيقية ديناميكيًا أثناء التشغيل — تطبيق بديل حديث غير متوافق مع أسلوب `ril_interface.c` (الذي يستدعي الدوال كرموز ربط عادية عبر `libsecril-client.so`).
3. **الاكتشاف الحاسم:** مشروع `hardware/samsung` (`LineageOS/android_hardware_samsung`, فرع `lineage-22.1`، متزامن محليًا وله `.git` كامل) يحتوي في تاريخه على الالتزام:
   ```
   931340f ril: Remove outdated libsecril-client and libsecril-client-sap
   ```
   أي أن **LineageOS نفسها أزالت** `ril/libsecril-client/secril-client.h` (والمصدر `.cpp` المرافق) من شجرتها الرسمية عمدًا (اعتُبرت قديمة، على الأرجح لصالح واجهة RIL الحديثة القائمة على AIDL/`sehradiomanager`) — تمامًا نفس نمط 7-ن (`iorapd_data_file`): **ميزة قديمة حذفتها LineageOS من الشجرة الحديثة، لكن شجرة الجهاز (`universal7420-common`) لا تزال تفترض وجودها.**
   الفرق الجوهري عن 7-ن: هنا **الميزة لا تزال مطلوبة فعليًا** (تحكم صوت المكالمات عبر RIL)، وليست ميتة كـ`iorapd` — لذا الحل الصحيح ليس تعليق الاستدعاء بل استعادة الرأس.
4. بما أن مكتبة `libsecril-client.so` نفسها **لا تزال موجودة** كـ`cc_prebuilt_library_shared` في `vendor/samsung/universal7420-common/Android.bp` (ثنائي جاهز من الشركة المصنّعة، لم يُحذف قط)، فإن الحل الآمن هو استعادة **الرأس فقط** (وليس المصدر `.cpp`، غير مطلوب لأن المكتبة prebuilt) من تاريخ Git لنفس المستودع مباشرة قبل حذفه، مما يضمن توافقًا حرفيًا 100% مع توقيعات الدوال التي بُنيت بها المكتبة الثنائية أصلًا.

**الإصلاح المطبَّق:**
```bash
cd ~/los22
mkdir -p hardware/samsung/ril/libsecril-client
cd hardware/samsung
git show 931340f^:ril/libsecril-client/secril-client.h > /home/ameen/los22/hardware/samsung/ril/libsecril-client/secril-client.h
cd ~/los22
# التراجع عن تعديل 7-ع الخاطئ: استعادة Android.mk الأصلي (المسار الأصلي hardware/samsung/ril/libsecril-client أصبح صحيحًا الآن بما أن الملف عاد للوجود)
cp device/samsung/universal7420-common/hardware/audio/Android.mk.bak_secril device/samsung/universal7420-common/hardware/audio/Android.mk
```
تحقق ناجح: الملف المُستخرج يحتوي فعليًا على `HRilClient`, `OpenClient_RILD`, `RIL_CLIENT_ERR_SUCCESS`, `__TwoMicSolDevice` وكل الدوال الأخرى المطلوبة (`SetCallVolume`, `SetCallAudioPath`, `SetCallClockSync`, `SetMute`, إلخ) بنفس التوقيعات الحرفية التي يستدعيها `ril_interface.c`.

**كيفية التراجع:** احذف `hardware/samsung/ril/libsecril-client/secril-client.h` (ملف مُستعاد وليس جزءًا من المشروع الرسمي كما هو متزامن الآن — لن يُحذف تلقائيًا عبر `repo sync` لاحقًا طالما بقي المسار خارج تتبع `.git` النشط لذلك المشروع؛ **راجع الملاحظة أدناه بخصوص استقرار هذا عبر `repo sync`**).

**الأثر المتوقع:** إيجابي بالكامل — استعادة وظيفة تحكم صوت المكالمات عبر RIL (التبديل بين مسارات الصوت أثناء المكالمة، كتم الصوت، إلخ) والتي كانت ستُعطَّل تمامًا (فشل بناء audio HAL بأكمله) لولا هذا الإصلاح.

**⚠️ ملاحظة حرجة لاستقرار البناء (`repo sync` لاحقًا):** الملف المُستعاد (`hardware/samsung/ril/libsecril-client/secril-client.h`) **خارج تتبع Git الرسمي** لمشروع `hardware/samsung` بفرعه الحالي (`lineage-22.1`) — تمت استعادته يدويًا من تاريخ commit قديم دون إعادته فعليًا لفهرس المستودع. لذا:
- `git status` داخل `hardware/samsung` سيُظهره كملف "untracked" — هذا متوقع وغير ضار.
- أي `repo sync -d` مستقبلي **لن يحذفه** (لأن `repo sync` لا يلمس untracked files افتراضيًا)، لكن للأمان: بعد أي `repo sync`، تحقق بسرعة أن الملف لا يزال موجودًا (`ls hardware/samsung/ril/libsecril-client/secril-client.h`) قبل إعادة البناء.
- **الأفضل لجهاز S6 Edge+ لاحقًا:** أضف هذا الملف كـ patch دائم عبر `git add` + `git commit` محلي داخل نسخة `hardware/samsung` (commit محلي فوق `lineage-22.1`، لا يُرفع لأي remote)، بدل تركه untracked، لضمان بقائه مهما حدث. أمر ذلك:
  ```bash
  cd ~/los22/hardware/samsung
  git add ril/libsecril-client/secril-client.h
  git commit -m "Restore legacy libsecril-client header for universal7420-common audio HAL (see CHANGES_noblelte_los22.md 7-ف)"
  cd ~/los22
  ```

**ملاحظة لإعادة الاستخدام (S6 Edge+ وغيره):** إصلاح على مستوى `universal7420-common`، ينطبق تلقائيًا على أي جهاز من نفس العائلة يستخدم نفس audio HAL القديم. **درس عام مهم جدًا:** عندما يُبلَّغ عن "ملف/دالة غير موجودة" ينتمي لواجهة قديمة معروفة (RIL، sepolicy، إلخ)، **افحص تاريخ Git لمشروع AOSP/LineageOS المعني نفسه** (`git log --all --oneline -- <path>`) قبل البحث عن بدائل تخمينية بالاسم فقط — إن كانت الميزة أُزيلت عمدًا من upstream (وليست معطوبة في شجرة الجهاز)، غالبًا ما يكون آخر إصدار صحيح منها متاحًا مباشرة في تاريخ نفس المستودع المتزامن محليًا، وهو مصدر أدق بكثير من أي تخمين بالاسم.

---

## 7-ص: خطأ ترجمة C — رأس `cutils/log.h` مفقود من مسار include لموديول `libbauthtzcommon_shim` تحديدًا (وليس حذفًا من AOSP)

**المشكلة:** فشل `libbauthtzcommon_shim` (موديول shim قديم لخداع مكتبة مصادقة الأجهزة الموثوقة/TrustZone):
```
device/samsung/universal7420-common/libshims/libbauthtzcommon/libbauthtzcommon.c:20:10: fatal error: 'cutils/log.h' file not found
```

**التشخيص:** خلافًا لأنماط 7-ن/7-س، هذا **ليس** حذفًا لميزة من AOSP ولا إعادة تسمية — `cutils/log.h` **لا يزال موجودًا فعليًا** في `system/core/libcutils/include/cutils/log.h`. المشكلة محصورة في `Android.mk` الخاص بهذا الموديول تحديدًا: `LOCAL_SHARED_LIBRARIES := liblog` فقط (بدون `libcutils`)، فلم يُصدَّر مسار include الخاص بـ`libcutils` لهذا الموديول تحديدًا. دليل قاطع: نفس الرأس (`cutils/log.h`) يُستخدم بنجاح تام (بلا أي خطأ) في نفس هذا البناء من طرف `audio_hw.c`, `voice.c`, `audience.c`, `compress_offload.c` — لأن موديولاتها تحصل على مسار `libcutils` بشكل صحيح عبر تبعياتها الأخرى.

فحص استباقي شامل (`grep -rl "cutils/log.h" device/samsung/universal7420-common/ device/samsung/noblelte/`) أظهر 8 ملفات تستخدم هذا الرأس، لكن التحقق أثبت أن **6 منها تعمل بلا مشكلة**: 4 ملفات صوت (مذكورة أعلاه، Android.mk قديم لكن include صحيح أصلًا) + ملفات الكاميرا الأربعة (`Android.bp`/Soong حديث، يُصدِّر include تلقائيًا لأن `libcutils` مُدرجة صراحة في `shared_libs`). لذا **لم تُلمس** — التعديل اقتصر على الموديول المعطوب فعليًا فقط، تجنبًا لتعديلات غير ضرورية.

**الإصلاح المطبَّق:** استبدال الرأس بالمكافئ الحديث المتاح مسبقًا عبر `liblog` نفسها (المُرتبطة أصلًا)، بدل إضافة `libcutils` كتبعية جديدة:
```bash
cd ~/los22
cp device/samsung/universal7420-common/libshims/libbauthtzcommon/libbauthtzcommon.c device/samsung/universal7420-common/libshims/libbauthtzcommon/libbauthtzcommon.c.bak_cutilslog
# السطر 20: #include <cutils/log.h>  →  #include <log/log.h>
```
تحقق: الملف يستخدم فقط ماكرو `ALOGW`، متوفر في كلا الرأسين (`cutils/log.h` و`log/log.h`)، فالاستبدال آمن 100% دلاليًا.

**كيفية التراجع:** استبدل الملف بالنسخة الاحتياطية `libbauthtzcommon.c.bak_cutilslog`.

**الأثر المتوقع:** لا أثر وظيفي — نفس ماكروز التسجيل (`ALOGW` وغيرها) متاحة بنفس السلوك عبر `log/log.h`.

**ملاحظة لإعادة الاستخدام:** فحص خاص بموديول `libbauthtzcommon_shim` وحده — لا تُعمّم هذا الإصلاح تلقائيًا على أي ملف آخر يستخدم `cutils/log.h` في هذه الشجرة أو غيرها؛ **تحقق أولًا هل الموديول المتأثر يفشل فعليًا** (كما فعلنا بفحص ملفات الصوت والكاميرا) قبل التعديل، لأن أغلب الاستخدامات الأخرى تعمل بلا مشكلة بفضل تبعياتها الصحيحة أصلًا.

---

## 7-ق: خطأ API — `String8::string()` أصبحت خاصة (private)، البديل الحديث `c_str()`

**المشكلة:** فشل `camera.exynos5` (`Camera2Wrapper.cpp`) و`CameraParameters.cpp` بنفس الخطأ:
```
error: 'string' is a private member of 'android::String8'
```

**التشخيص:** نمط "إعادة تسمية/توحيد API" مطابق لـ7-س لكن على مستوى C++ class بدل sepolicy. فحص `system/core/libutils/include/utils/String8.h` أظهر أن `string()` (الدالة القديمة) لا تزال موجودة تقنيًا لكن جُعلت **خاصة**، بينما `c_str()` (مضافة حديثًا) هي البديل **العام** الرسمي — كلاهما تُعيد نفس `const char*` بنفس السلوك تمامًا (`c_str()` مجرد اسم بديل قياسي متوافق مع `std::string`).

**الإصلاح المطبَّق:** استبدال كل استدعاءات `.string()` على متغيرات `String8` بـ`.c_str()`، في ملفين:
```bash
cd ~/los22
cp device/samsung/universal7420-common/camera/Camera2Wrapper.cpp device/samsung/universal7420-common/camera/Camera2Wrapper.cpp.bak_string8
cp device/samsung/universal7420-common/camera/CameraParameters.cpp device/samsung/universal7420-common/camera/CameraParameters.cpp.bak_string8
# كل .string()  →  .c_str()  (2 استبدالات في Camera2Wrapper.cpp، 7 في CameraParameters.cpp)
```
تحقق مسبق: تم التأكد أن كل الكائنات المتأثرة (`params`, `v`, `k`, `result`) من نوع `String8` فعلًا (وليست `String16` أو نوعًا آخر لا يملك `c_str()`) قبل التطبيق.

**كيفية التراجع:** استبدل الملفين بالنسختين الاحتياطيتين `.bak_string8`.

**الأثر المتوقع:** لا أثر وظيفي — سلوك مطابق 100%.

**ملاحظة لإعادة الاستخدام:** إصلاح على مستوى `universal7420-common/camera`، ينطبق تلقائيًا على أي جهاز آخر من نفس العائلة. **درس عام:** أي كود C++ قديم يستخدم `String8::string()` في شجرة الجهاز سيفشل بنفس الخطأ على AOSP الحديث — عند مواجهته مجددًا، البديل الآمن دومًا هو `c_str()` بعد التأكد أن الكائن من نوع `String8`.

---

## 7-ر: خطأ include — إعادة تنظيم رؤوس `frameworks/native` (`MetadataBufferType.h` انتقل إلى `headers/media_plugin`)

**المشكلة:** فشل `libstagefright_shim` (`CameraSource.cpp`، عبر `frameworks/av/media/libstagefright/include/media/stagefright/CameraSource.h`):
```
fatal error: 'media/hardware/MetadataBufferType.h' file not found
```

**التشخيص:** نمط مطابق لـ7-س (إعادة تسمية/نقل، وليس حذفًا). الرأس **لا يزال موجودًا فعليًا** في الشجرة الحالية، لكن AOSP نقله من `frameworks/native/include/media/hardware/` (المسار القديم المُدرَج في `include_dirs` لموديول `libstagefright_shim`) إلى `frameworks/native/headers/media_plugin/media/hardware/` (مسار رؤوس عامة جديد منظَّم ضمن `frameworks/native/headers/`). تأكيد إضافي: نفس الرأس موجود أيضًا في كل نسخ `prebuilts/vndk/v30` حتى `v34`، ما يدل على أن هذا مسار مستقر معتمد منذ إصدارات AOSP سابقة، وليس تغييرًا حديثًا جدًا.

**الإصلاح المطبَّق:** إضافة المسار الجديد إلى `include_dirs` **دون حذف** المسار القديم (بقاؤه غير ضار، وقد تحتاجه رؤوس أخرى بنفس المجلد القديم):
```bash
cd ~/los22
cp device/samsung/universal7420-common/libshims/libstagefright/Android.bp device/samsung/universal7420-common/libshims/libstagefright/Android.bp.bak_metadatabuf
# إضافة سطر بعد "frameworks/native/include/media/hardware":
#     "frameworks/native/headers/media_plugin",
```

**كيفية التراجع:** استبدل `Android.bp` بالنسخة الاحتياطية `Android.bp.bak_metadatabuf`.

**الأثر المتوقع:** لا أثر وظيفي سلبي — إضافة مسار include فقط، لا تغيير على أي منطق.

**ملاحظة لإعادة الاستخدام:** إصلاح على مستوى `universal7420-common/libshims/libstagefright`، ينطبق تلقائيًا على أي جهاز آخر من نفس العائلة يستخدم نفس الـshim. **درس عام متراكم من 7-س/7-ق/7-ر:** ثلاثة أنماط "إعادة تنظيم/تسمية" ظهرت في نفس هذه الجلسة عبر مستويات مختلفة تمامًا (sepolicy، C++ class API، مسارات رؤوس C/C++) — عند أي خطأ "غير موجود"، الخطوة الأولى دومًا هي البحث عن العنصر بنفس الاسم أو اسم قريب في الشجرة الحالية (`find`/`grep`) قبل افتراض أنه حُذف بالكامل (كما في 7-ن/7-ف)؛ فقط إن لم يُعثر عليه إطلاقًا يُلجأ لتاريخ Git (كما في 7-ف) أو التعليق كحل أخير.

---

## 7-ش: خلل نظامي جسيم في vendor blobs — 27 مكتبة 32-بت كانت نسخًا مكررة خاطئة من نسخة 64-بت (استُبدلت من مصدر بديل)

**المشكلة:** فشل الربط (`ld.lld`) لـ`audio.primary.universal7420_32`:
```
ld.lld: error: out/target/product/noblelte/obj_arm/SHARED_LIBRARIES/libsecril-client_intermediates/libsecril-client.so is incompatible with armelf
```

**التشخيص (الأخطر في هذه الجلسة):**
1. `file`/`readelf` على `vendor/samsung/universal7420-common/proprietary/vendor/lib/libsecril-client.so` (مسار 32-بت المتوقع) أظهر أنه فعليًا **`ELF 64-bit ARM aarch64`** — أي أن المكتبة "32-بت" ليست 32-بت إطلاقًا.
2. `md5sum` أثبت أنه **نفس الملف بالضبط** (checksum مطابق حرفيًا) الموجود في `lib64/libsecril-client.so` — نسخة طبق الأصل، وليس مجرد خطأ تسمية.
3. فحص شامل لكل ملفات `.so` في `lib/` مقابل نظيراتها بالاسم في `lib64/` كشف أن هذا **ليس حالة معزولة**: **27 مكتبة على الأقل** بنفس هذا الخلل بالضبط (قائمة كاملة أدناه) — خطأ نظامي في عملية استخراج/تعبئة هذه الـvendor blobs الأصلية (على الأرجح من طاقم `project289` عند تجهيز فرع lineage-22.1)، وليس خطأ تكويني في شجرة الجهاز.
4. **الأهم:** فحص `device/samsung/universal7420-common/BoardConfigCommon.mk:42` أظهر `AUDIOSERVER_MULTILIB := 32` — هذا الجهاز **يُجبر `audioserver` بالكامل على العمل 32-بت حصرًا** (نمط شائع لأجهزة Exynos القديمة ذات DSP صوت 32-بت فقط تاريخيًا). أي أن نسخة 32-بت من هذه المكتبات **ليست اختيارية إطلاقًا** — هي الوحيدة المستخدمة عمليًا، فلا يمكن "حل" المشكلة بقصر الموديول على 64-بت فقط.

قائمة المكتبات الـ27 المتأثرة (كلها كانت نسخًا مكررة من `lib64/` بنفس الـmd5):
```
libbauthserver.so, libbauthtzcommon.so, libegis_fp_normal_sensor_test.so, libengmode_client.so,
libexynoscamera3.so, libexynoscamera.so, libfloatingfeature.so, libgf_in_system_lib.so,
libhwjpeg.so, libprotobuf-cpp-full-3.9.1.so, libril.so, libsecnativefeature.so,
libsecril-client.so, libsec-ril-dsds.so, libsec-ril.so, libsec_semRil.so,
libsemnativecarrierfeature.so, libsensorlistener.so, libsensor-mod.so, libsynaFpSensorTestNwd.so,
libuniplugin.so, libvkmanager_vendor.so, libwrappergps.so,
vendor.samsung.hardware.radio@2.0.so, vendor.samsung.hardware.radio@2.1.so,
vendor.samsung.hardware.radio.bridge@2.0.so, vendor.samsung.hardware.radio.channel@2.0.so
```

**البحث عن مصدر صحيح:** بما أن استخراج blobs حقيقية يتطلب جهازًا فعليًا (غير متاح)، تم البحث عن شجرة vendor blobs بديلة أُعدّت أصلًا لنفس الجهاز. وُجد مستودع **`samsungexynos7420/proprietary_vendor_samsung`** (فرع `lineage-19.1`) — نفس المنظمة المصدر لشجرة `noblelte` نفسها قبل الدمج مع `project289` (فرع أقدم يعود لعصر كانت فيه الـHALs لا تزال تُبنى 32-بت فعليًا). التحقق أثبت تطابقًا 100%:
- نسخة `lib64/` في هذا المصدر البديل **مطابقة حرفيًا** (نفس md5 وBuildID) لنسخة `lib64/` الموجودة أصلًا في شجرتنا — تأكيد قاطع أنه **نفس مصدر الـblobs الأصلي بالضبط**، وليس إصدارًا مختلفًا قد يسبب عدم توافق.
- نسخة `lib/` في هذا المصدر **32-بت حقيقية** (`ELF 32-bit ARM EABI5`) لكل الـ27 مكتبة، بلا استثناء.

**الإصلاح المطبَّق:**
```bash
# فحص واستطلاع (منفصل تمامًا عن شجرة البناء، في /tmp)
mkdir -p /tmp/vendor_check && cd /tmp/vendor_check
git clone --depth 1 --branch lineage-19.1 --filter=blob:none --sparse \
    https://github.com/samsungexynos7420/proprietary_vendor_samsung.git
cd proprietary_vendor_samsung
git sparse-checkout set universal7420-common/proprietary/vendor/lib universal7420-common/proprietary/vendor/lib64

# بعد التحقق الكامل من تطابق lib64/ ومطابقة القائمة الكاملة:
cd ~/los22
cp -r vendor/samsung/universal7420-common/proprietary/vendor/lib \
      vendor/samsung/universal7420-common/proprietary/vendor/lib.bak_32bit_dupes
# نسخ كل الـ27 ملفًا من المصدر البديل إلى نفس المسار (استبدال الملفات المكررة الخاطئة فقط)
rm -rf /tmp/vendor_check   # تنظيف، لا أثر متبقٍ خارج شجرة البناء
```

**كيفية التراجع:** احذف `vendor/samsung/universal7420-common/proprietary/vendor/lib/` بالكامل واستبدله بمحتوى `lib.bak_32bit_dupes/` (النسخة الاحتياطية الكاملة للمجلد قبل الاستبدال).

**الأثر المتوقع:** إيجابي وجوهري — بدون هذا الإصلاح، `audio.primary.universal7420_32` (وبالتبعية `audioserver` بأكمله، بما أن الجهاز يُجبره على 32-بت) كان سيفشل نهائيًا في الربط، أي **لا صوت إطلاقًا على الجهاز الفعلي** حتى لو تجاوزنا هذا الخطأ ببناء بديل (لا يوجد بديل ممكن هنا، فلا نسخة مصدر C أخرى لهذه المكتبات الاحتكارية).

**ملاحظة حرجة لإعادة الاستخدام (S6 Edge+ وغيره):** هذا الخلل على مستوى **`vendor/samsung/universal7420-common`** المشترك بالكامل (وليس خاصًا بـ`noblelte`)، فمن شبه المؤكد ينطبق تلقائيًا على أي جهاز آخر من نفس العائلة يستخدم نفس vendor blobs (S6 Edge+ / zenlte، S6 Edge / zerolte، S6 / zeroflte). **يُنصح بشدة** بتكرار نفس فحص "التطابق بين lib/ وlib64/" (`md5sum` مقارنةً) على **كامل** مجلد `vendor/samsung/universal7420-common/proprietary/vendor/lib/` (وليس فقط المكتبات الـ27 المكتشفة هنا، إذ رُصدت بالصدفة عبر خطأ ربط واحد فقط — قد توجد المزيد لم تظهر بعد لأن البناء يتوقف عند أول خطأ ربط) **قبل** بدء أي بناء جديد لجهاز آخر من هذه العائلة، بدل انتظار اكتشافها تباعًا عبر عشرات أخطاء الربط المحتملة. أمر الفحص الشامل نفسه معطى أعلاه (حلقة `for f in lib/*.so`).

---

## 7-ت: خطأ توليد `build.prop` — آلية "انتحال هوية GMS" القديمة (`PRODUCT_BUILD_PROP_OVERRIDES`) مرفوضة من `gen_build_prop.py` الحديث

**المشكلة:** فشل توليد `odm-build.prop`:
```
Key "PRODUCT_NAME" isn't a valid prop override
```

**الخلفية:** `device/samsung/noblelte/lineage_noblelte.mk` يحتوي على كتلة قديمة من عهد CyanogenMod/LineageOS المبكر تُستخدم لجعل `build.prop` النهائي "ينتحل" هوية بناء سامسونج الرسمي الأصلي (`nobleltejv`) بدل `lineage_noblelte` — ممارسة شائعة ومعروفة في مجتمع custom ROM، غرضها مطابقة بصمة جهاز معتمدة لأغراض GMS/SafetyNet (وليست انتحالًا ضارًا تجاه المستخدم؛ موثّقة علنًا في كل أشجار الأجهزة تقريبًا). الآلية القديمة:
```makefile
PRODUCT_BUILD_PROP_OVERRIDES += \
        PRODUCT_NAME=nobleltejv \
        TARGET_DEVICE=noblelte \
        PRIVATE_BUILD_DESC="nobleltejv-user 7.0 NRD90M N920CXXS5CRH3 release-keys"
```

**التشخيص:** قرأنا `build/soong/scripts/gen_build_prop.py` (الأداة الحديثة في Soong التي حلّت محل آلية `build.prop` القديمة القائمة على Make بالكامل). دالة `override_config()` تتحقق أن كل مفتاح في `PRODUCT_BUILD_PROP_OVERRIDES` موجود مسبقًا كمفتاح في قاموس `config` (المبني من JSON يُنتجه `build/make/core/soong_extra_config.mk`) — و`PRODUCT_NAME`/`TARGET_DEVICE`/`PRIVATE_BUILD_DESC` **لم تعد أسماء مفاتيح صالحة** في هذا القاموس الحديث (المفاتيح الآن بصيغة `CamelCase` مثل `DeviceProduct`)، فتفشل الأداة فورًا عند أول مفتاح غير معروف.

**الآلية الحديثة البديلة (رسمية ومدعومة):** AOSP أضاف متغيرات `PRODUCT_*_FOR_ATTESTATION` مخصصة تحديدًا لنفس هذا الغرض (مطابقة هوية الانتحال لأغراض GMS attestation) دون المساس بالخصائص الفعلية (`ro.product.name` وغيرها) التي يعتمد عليها النظام والبناء نفسه:
```
PRODUCT_NAME_FOR_ATTESTATION       → ro.product.name_for_attestation
PRODUCT_MODEL_FOR_ATTESTATION      → ro.product.model_for_attestation
PRODUCT_BRAND_FOR_ATTESTATION      → ro.product.brand_for_attestation
PRODUCT_DEVICE_FOR_ATTESTATION     → ro.product.device_for_attestation
PRODUCT_MANUFACTURER_FOR_ATTESTATION → ro.product.manufacturer_for_attestation
```
(المصدر: `build/make/core/product.mk`, `build/make/core/soong_extra_config.mk`, `build/make/core/sysprop.mk`)

**الإصلاح المطبَّق:** استبدال الكتلة القديمة بالكامل بالآلية الحديثة:
```bash
cd ~/los22
cp device/samsung/noblelte/lineage_noblelte.mk device/samsung/noblelte/lineage_noblelte.mk.bak_prodname
```
```makefile
# 2026-09-20 (راجع هذا القسم): PRODUCT_BUILD_PROP_OVERRIDES بالمفاتيح القديمة مرفوض من
# gen_build_prop.py الحديث. استُبدل بالآلية الرسمية *_FOR_ATTESTATION.
PRODUCT_NAME_FOR_ATTESTATION := nobleltejv
PRODUCT_MODEL_FOR_ATTESTATION := SM-N920C
PRODUCT_BRAND_FOR_ATTESTATION := samsung
PRODUCT_DEVICE_FOR_ATTESTATION := noblelte
PRODUCT_MANUFACTURER_FOR_ATTESTATION := samsung
```
ملاحظة: لا يوجد مكافئ حديث مباشر لـ`PRIVATE_BUILD_DESC` (وصف نصي حر) ضمن آلية `*_FOR_ATTESTATION` — حُذف لأنه كان جزءًا ثانويًا من الانتحال القديم (وصف نصي فقط، وليس معرِّفًا يُتحقق منه فعليًا)، بينما بقيت الخصائص الجوهرية الخمس (`NAME`/`MODEL`/`BRAND`/`DEVICE`/`MANUFACTURER`) كاملة.

**كيفية التراجع:** استبدل `lineage_noblelte.mk` بالنسخة الاحتياطية `lineage_noblelte.mk.bak_prodname` (لن يعمل إلا إذا أُعيد `gen_build_prop.py` لسلوكه القديم مستقبلًا، غير متوقع).

**الأثر المتوقع:** إيجابي — يُصلح فشل البناء بالكامل، ويحافظ على نفس غرض انتحال الهوية الأصلي (لأغراض GMS) عبر الآلية الرسمية المخصصة لذلك بدل الحيلة القديمة، بل بشكل أنظف (لا يلمس `ro.product.name` الفعلي، فقط الحقول المخصصة للـattestation).

**ملاحظة لإعادة الاستخدام:** إصلاح على مستوى `device/samsung/noblelte` تحديدًا (خاص بهذا الجهاز، وليس `universal7420-common`) — لأي جهاز آخر من نفس العائلة (S6 Edge+ وغيره) له نفس الكتلة القديمة في ملف `lineage_<device>.mk` الخاص به، طبّق نفس الاستبدال بقيم الهوية الخاصة بذلك الجهاز (`PRODUCT_NAME_FOR_ATTESTATION` بقيمة اسم بناء سامسونج الأصلي لذلك الجهاز تحديدًا، إلخ).

---

## 9. للنشر/الدمج لدعم جهاز آخر (S6 Edge+ SM-G928 مثلاً)
- المانفست في القسم 1 قابل لإعادة الاستخدام حرفيًا لأي جهاز على نفس `universal7420-common` (exynos7420 family)، فقط استبدل مشروع `device/samsung/noblelte` بمشروع الجهاز الجديد (تأكد من الفرع الصحيح — الأجهزة المختلفة من نفس العائلة قد تكون على فروع lineage مختلفة كما رأينا مع noblelte@19.1).
- كل التصحيحات في القسم 2 (BoardConfigCommon.mk, boot-image-profile symlink, libstagefright_shim) هي على مستوى **`universal7420-common` المشترك**، فتنطبق تلقائيًا على أي جهاز يستخدم هذه الشجرة المشتركة — لا حاجة لتكرارها.
- تصحيحات القسم 3 (حذف lib/lib64 المكررة + موديولات `cc_prebuilt_library_shared` الثنائية المعمارية) **خاصة بكل جهاز على حدة** لأن `proprietary/vendor/lib/` تختلف محتوياتها بين noblelte و zeroltexx وغيرها — عند نشر جهاز جديد من نفس العائلة، أعد تطبيق **نفس المنهجية الأربع خطوات** بدل تخمين النتائج:
  1. شغّل `dedupe_vendor_mk.py` على ملف `*-vendor.mk` الخاص بالجهاز الجديد لحذف تكرارات lib/lib64 الآمنة.
  2. ابحث (`grep -rl "$lib" --include=Android.mk`) عن أي مكتبة محذوفة لا تزال مُستخدمة كـ `LOCAL_SHARED_LIBRARIES` من هدف 32-بت.
  3. لكل مكتبة كهذه، أنشئ موديول `cc_prebuilt_library_shared` ثنائي المعمارية (بنية القسم 3 أعلاه) بدل استرجاع `PRODUCT_COPY_FILES`، واحذف إدخالاتها القديمة نهائيًا.
  4. تحقق من تصادم أسماء الموديولات الجديدة مع أي `soong_namespace` آخر في الشجرة قبل البناء (`grep -rn "name: \"$lib\"" --include=Android.bp`)، وتأكد أن أي namespace متصادم غير مستورد في `PRODUCT_SOONG_NAMESPACES`.
- تصحيح القسم 2-و (`PRODUCT_SOONG_NAMESPACES += hardware/samsung` لأجل `dtbhtoolExynos`) قابل لإعادة الاستخدام حرفيًا لأي جهاز على `universal7420-common` — الدرس العام (تحقّق من `soong_namespace` عند أي "missing and no known rule" لموديول يبدو معرَّفًا بشكل صحيح) ينطبق على أي موديول جديد آخر أيضًا، وليس فقط `dtbhtoolExynos`.
- تصحيح القسم 7-ز (`VNDK prebuilts` / `libprotobuf-cpp-lite-v29.so`) هو على مستوى **`universal7420-common` المشترك**، فينطبق تلقائيًا على أي جهاز من نفس العائلة يستخدم `libwvhidl.so`/`libwvdrmengine.so` الاحتكاريَين — لا حاجة لإعادة التشخيص، لكن تأكد أن مانفست الفرع المستهدف عند جهازك الجديد لا يزال يفتقر `prebuilts/vndk/v29` بنفس الطريقة قبل تطبيق الحل حرفيًا (`grep vndk .repo/manifests/*.xml`).
- تصحيح القسم 7-ل (`dtbo_block_device` مكرر في sepolicy) هو على مستوى `device/samsung_slsi/sepolicy` المشترك بين أجهزة Samsung Exynos القديمة (وليس `universal7420-common` تحديدًا) — ينطبق تلقائيًا على أي جهاز يستخدم نفس شجرة `device/samsung_slsi/sepolicy`، لكن تحقق أولاً هل نفس النوع (`type`) بات معرَّفًا في `system/sepolicy/public/device.te` لنسخة AOSP التي تبنيها (`grep -n "type dtbo_block_device" system/sepolicy/public/device.te`) قبل افتراض وجود نفس التعارض.
- تصحيح القسم 7-م (`vendor_hwc_prop` مكرر بين `device/samsung_slsi` و`universal7420-common`) **ليس تعارضًا مع AOSP** بل بين شجرتي جهاز قديمتين مُدمجتين عمدًا في هذا البورت — لا تفترض تلقائيًا انطباقه على جهاز جديد؛ تحقق أولاً هل الجهاز الجديد يدمج نفس الشجرتين، وإن كان كذلك افحص كل ماكروهات sepolicy المشتركة بينهما يدويًا (وليس فقط `vendor_hwc_prop`) لأن `checkpolicy` يُبلغ عن خطأ واحد فقط في كل مرة، فمن المرجح وجود المزيد من نفس النمط.

---

## 7-ل: تعارض SELinux — إعادة تعريف `dtbo_block_device` (مكرر مع AOSP الحديث)

**المشكلة:** فشل `checkpolicy` عند بناء `vendor_sepolicy.cil.raw` بخطأ:
```
device/samsung_slsi/sepolicy/common/vendor/device.te:6:ERROR 'Duplicate declaration of type' at token ';' on line 22390:
type dtbo_block_device, dev_type;
```

**التشخيص:** `grep` شامل على كل ملفات `.te` في الشجرة أظهر أن `dtbo_block_device` معرّف مرتين:
- `system/sepolicy/public/device.te:99` — **التعريف الرسمي في AOSP الحديث نفسه** (وأيضًا في `system/sepolicy/prebuilts/api/202404/public/device.te:99`).
- `device/samsung_slsi/sepolicy/common/vendor/device.te:5` — تعريف قديم مكرر، بقايا من شجرة sepolicy الأصلية لـSamsung Exynos (سابقة لإضافة AOSP هذا النوع لسياسته العامة).

نفس نمط "بقايا قديمة من شجرة الجهاز تتعارض مع إضافات AOSP الحديثة" الذي رأيناه سابقًا (VNDK v29، أسماء رؤوس kernel بأحرف كبيرة).

**الإصلاح المطبَّق:** تعليق السطر المكرر فقط في ملف الجهاز (وليس لمس `system/sepolicy` إطلاقًا):
```bash
cd ~/los22
cp device/samsung_slsi/sepolicy/common/vendor/device.te device/samsung_slsi/sepolicy/common/vendor/device.te.bak_dtbo
# السطر 5: type dtbo_block_device, dev_type;  →  # type dtbo_block_device, dev_type;  # DISABLED (سبب في هذا القسم)
```

**كيفية التراجع:** استبدل `device/samsung_slsi/sepolicy/common/vendor/device.te` بالنسخة الاحتياطية `device.te.bak_dtbo`، أو أزل `#` من بداية السطر 5 يدويًا.

**الأثر المتوقع:** لا أثر وظيفي — النوع (`type`) نفسه لا يزال معرَّفًا (من AOSP)، وكل القواعد (`allow`) التي تستخدم `dtbo_block_device` في ملفات الجهاز (مثل `fastbootd.te`) تبقى تعمل بلا تغيير لأنها تشير للاسم فقط، لا لمكان تعريفه.

---

## 7-م: تعارض SELinux — إعادة تعريف `vendor_hwc_prop` (مكرر بين شجرتي `device/samsung_slsi` و`universal7420-common`)

**المشكلة:** فشل `checkpolicy` عند بناء `vendor_sepolicy.cil.raw` (بعد إصلاح 7-ل مباشرة) بخطأ:
```
device/samsung/universal7420-common/sepolicy/vendor/property.te:8:ERROR 'Duplicate declaration of type' at token ';' on line 26171:
```

**التشخيص:** هذا التعارض **مختلف عن 7-ل** — ليس بين شجرة الجهاز وAOSP الحديث، بل بين **شجرتي أجهزة قديمتين مختلطتين معًا** في هذا البورت (خاصية المزج بين `project289` و`samsungexynos7420` المذكورة في مقدمة هذا الملف). `vendor_hwc_prop` معرَّف مرتين عبر ماكروهات مختلفة (كلاهما يُوسَّع إلى `type ...;`):
- `device/samsung/universal7420-common/sepolicy/vendor/property.te:8` — `vendor_internal_prop(vendor_hwc_prop);` — **الشجرة المُبقاة**، لأن لها استخدامات فعلية مرتبطة بها تحديدًا (`hal_graphics_composer_default.te:19` عبر `get_prop`، و`vendor_init.te:61` عبر `set_prop`).
- `device/samsung_slsi/sepolicy/common/vendor/property.te:4` — `vendor_restricted_prop(vendor_hwc_prop)` — تعريف مكرر قديم من الشجرة العامة المشتركة، عُلِّق.

ملاحظة: `device/samsung_slsi/sepolicy/common/vendor/hal_graphics_composer_default.te:1` يستخدم `set_prop(hal_graphics_composer_default, vendor_hwc_prop)` — هذا **استخدام** للخاصية فقط (ليس تعريفًا)، فلم يُلمس ويستمر بالعمل بلا تغيير لأنه يشير للاسم فقط.

**الإصلاح المطبَّق:**
```bash
cd ~/los22
cp device/samsung_slsi/sepolicy/common/vendor/property.te device/samsung_slsi/sepolicy/common/vendor/property.te.bak_hwcprop
# السطر 4: vendor_restricted_prop(vendor_hwc_prop)  →  # vendor_restricted_prop(vendor_hwc_prop)  # DISABLED 2026-09-19 (راجع هذا القسم): تعريف مكرر، الأصلي في device/samsung/universal7420-common/sepolicy/vendor/property.te عبر vendor_internal_prop()
```

**كيفية التراجع:** استبدل `device/samsung_slsi/sepolicy/common/vendor/property.te` بالنسخة الاحتياطية `property.te.bak_hwcprop`، أو أزل `#` من بداية السطر 4 يدويًا.

**الأثر المتوقع:** لا أثر وظيفي — الخاصية (`vendor_hwc_prop`) تبقى معرَّفة (من `universal7420-common`، عبر ماكرو `vendor_internal_prop` بدل `vendor_restricted_prop` — الفرق بينهما هو مستوى القيود على مَن يمكنه تعيين الخاصية، وليس وجودها)، وكل الاستخدامات (`get_prop`/`set_prop`) في كلا الشجرتين تستمر بالعمل لأنها تشير للاسم فقط.

**ملاحظة مهمة لإعادة الاستخدام (S6 Edge+ وغيره):** خلافًا لكل التعارضات السابقة (VNDK، رؤوس kernel، `dtbo_block_device`) التي كانت "شجرة جهاز قديمة تتعارض مع AOSP حديث"، هذا التعارض بين **شجرتي جهاز قديمتين مُختلطتين معًا عمدًا** في هذا البورت تحديدًا. إن كان الجهاز المستهدف الجديد يستخدم نفس دمج `device/samsung_slsi` + `universal7420-common`، تحقق يدويًا من كل الماكروهات المشتركة بينهما (`vendor_internal_prop`/`vendor_restricted_prop`/`vendor_public_prop` وغيرها) بدل افتراض عدم وجود تعارضات أخرى — من المحتمل وجود المزيد بنفس النمط لم يظهر بعد لأن `checkpolicy` يتوقف عند أول خطأ فقط.

---

## 7-ن: خطأ SELinux مختلف النوع — `unknown type iorapd_data_file` (ميزة iorap أُزيلت من AOSP الحديث)

**المشكلة:** فشل `checkpolicy` عند بناء `vendor_sepolicy.cil.raw` (بعد إصلاح 7-م مباشرة) بخطأ **من نوع مختلف** عن كل ما سبق:
```
device/samsung/universal7420-common/sepolicy/vendor/init.te:18:ERROR 'unknown type iorapd_data_file' at token ';' on line 25758:
allow init iorapd_data_file:file getattr;
```
هذا ليس "تعريف مكرر" (`Duplicate declaration`) كالأخطاء 7-ل و7-م، بل **"نوع غير معرَّف إطلاقًا"** (`unknown type`) — القاعدة (`allow`) تشير لنوع لم يعد موجودًا في السياسة الحالية.

**التشخيص:** `iorapd_data_file` (وميزة `iorapd` نفسها — تحسين أوقات إطلاق التطبيقات عبر I/O prefetching) كانت موجودة في `system/sepolicy/public/` حتى API 33 تقريبًا (`system/sepolicy/prebuilts/api/{29..33}.0/public/iorapd.te`, `file.te`)، لكنها **أُزيلت بالكامل** من `system/sepolicy/private|public/` الحالي في نسخة AOSP/LineageOS 22 التي يُبنى عليها هذا البورت. الإشارات المتبقية للنوع موجودة فقط في ملفات `compat/*.cil` (طبقات التوافق العكسي الخاصة بنسخ API قديمة) وليس في السياسة النشطة الفعلية — القاعدة الوحيدة التي تستخدمه هي من الشجرة القديمة `device/samsung/universal7420-common/sepolicy/vendor/init.te:17`، بقايا زمن كانت فيه `iorapd` لا تزال جزءًا من AOSP.

**الإصلاح المطبَّق:** تعليق السطر الوحيد الذي يستخدم هذا النوع (لا يوجد نوع بديل لتعريفه — الميزة نفسها غير موجودة):
```bash
cd ~/los22
cp device/samsung/universal7420-common/sepolicy/vendor/init.te device/samsung/universal7420-common/sepolicy/vendor/init.te.bak_iorapd
# السطر 17: allow init iorapd_data_file:file getattr;  →  # ... DISABLED (راجع هذا القسم)
```

**كيفية التراجع:** استبدل `device/samsung/universal7420-common/sepolicy/vendor/init.te` بالنسخة الاحتياطية `init.te.bak_iorapd`، أو أزل `#` من بداية السطر 17 يدويًا — لاحظ أن هذا لن يعمل إلا إذا أُعيد `iorapd_data_file` لاحقًا لسياسة AOSP الحديثة، وهو غير متوقع.

**الأثر المتوقع:** لا أثر وظيفي — `iorapd` أصلًا غير موجود كميزة في Android 15/LineageOS 22 (لا `iorapd` binary ولا خدمته)، فهذه القاعدة كانت ميتة (dead rule) بلا فائدة حتى قبل هذا الإصلاح.

**ملاحظة لإعادة الاستخدام:** هذا الإصلاح على مستوى `universal7420-common` المشترك، فينطبق تلقائيًا على أي جهاز آخر من نفس العائلة (S6 Edge+ وغيره) يستخدم نفس الشجرة، بلا حاجة لإعادة تشخيص — طالما لا يزال `iorapd` غائبًا عن `system/sepolicy/public` في فرع AOSP المستهدف (تحقق بـ`grep -rn "iorapd" system/sepolicy/public/ system/sepolicy/private/ 2>/dev/null | grep -v compat`، توقع نتيجة فارغة).

**درس عام مهم:** هذا يُظهر أن أخطاء `checkpolicy` في هذا البورت ليست جميعها من نفس الفئة — بعضها "تعريف مكرر" (fix: علّق أحد التعريفين) وبعضها "نوع محذوف من AOSP الحديث" (fix: علّق القاعدة التي تستخدمه، إذ لا معنى لتعريفه من جديد). يجب قراءة رسالة الخطأ بعناية (`Duplicate declaration` مقابل `unknown type`) لتحديد الفئة الصحيحة قبل اختيار طريقة الإصلاح.

---

## 7-س: خطأ SELinux — نمط ثالث مختلف: **إعادة تسمية نوع** (`sysfs_block` → `sysfs_devices_block`)

**المشكلة:** فشل `checkpolicy` (بعد إصلاح 7-ن مباشرة) بخطأ:
```
device/samsung/universal7420-common/sepolicy/vendor/genfs_contexts:105:ERROR 'type sysfs_block is not defined or is an attribute' at token 'genfscon' on line 28135:
genfscon sysfs /devices/virtual/bdi/254:0/read_ahead_kb     u:object_r:sysfs_block:s0
```

**التشخيص:** هذا **نمط ثالث** مختلف عن كل من 7-ل/7-م (تعريف مكرر) و7-ن (ميزة محذوفة بالكامل). `sysfs_block` لم يعد معرَّفًا في AOSP الحديث، لكن بحثًا عن أنواع `sysfs_*` مشابهة وظيفيًا أظهر `system/sepolicy/public/file.te:108`:
```
type sysfs_devices_block, fs_type, sysfs_type;
```
أي أن AOSP **أعاد تسمية** هذا النوع (من `sysfs_block` إلى `sysfs_devices_block`) بدل حذفه بالكامل — المسار المستهدف في `genfscon` (`/devices/virtual/bdi/254:0/read_ahead_kb`، وهو مسار `sysfs` حقيقي متعلق بخصائص قراءة-مسبقة لجهاز كتلة) يطابق دلاليًا التسمية الجديدة، ووظيفة القاعدة (ضبط سياق أمان ملف `read_ahead_kb` تحت `sysfs`) لا تزال مطلوبة فعليًا لعمل الجهاز — لذا الإصلاح الصحيح هو **استبدال الاسم**، وليس التعليق كما في 7-ن.

**الإصلاح المطبَّق:**
```bash
cd ~/los22
cp device/samsung/universal7420-common/sepolicy/vendor/genfs_contexts device/samsung/universal7420-common/sepolicy/vendor/genfs_contexts.bak_sysfsblock
# استبدال: u:object_r:sysfs_block:s0  →  u:object_r:sysfs_devices_block:s0  (سطر 101، مسار /devices/virtual/bdi/254:0/read_ahead_kb)
```

**كيفية التراجع:** استبدل `device/samsung/universal7420-common/sepolicy/vendor/genfs_contexts` بالنسخة الاحتياطية `genfs_contexts.bak_sysfsblock`.

**الأثر المتوقع:** إيجابي/محايد وظيفيًا — القاعدة تستمر بالعمل فعليًا (بعكس 7-ن حيث الميزة نفسها غائبة)، فقط تحت الاسم الصحيح الذي يتعرف عليه `checkpolicy` الحديث. لا حاجة لأي تعديل آخر (لا `allow` rules أخرى تشير إلى `sysfs_block` بالاسم القديم وُجدت في هذه الشجرة).

**ملاحظة لإعادة الاستخدام:** إصلاح على مستوى `universal7420-common` المشترك، ينطبق تلقائيًا على أي جهاز من نفس العائلة. **درس عام أهم**: عند مواجهة `unknown type` أو `is not defined or is an attribute` مستقبلًا، لا تفترض تلقائيًا أنه "ميزة محذوفة" (كـ 7-ن) — ابحث أولًا عن نوع `sysfs_*`/مشابه بديل بنفس السياق الوظيفي في `system/sepolicy/public/file.te` (أو `*.te` عمومًا)؛ AOSP كثيرًا ما يُعيد تسمية أنواع `sysfs`/`proc` بدل حذفها فعليًا. رتّب التشخيص كالتالي: (1) `Duplicate declaration` → علّق أحد التعريفين، (2) `unknown type` + لا بديل واضح بنفس الوظيفة → الميزة محذوفة، علّق القاعدة، (3) `unknown type` + وُجد نوع مشابه بنفس نمط التسمية والسياق → إعادة تسمية، استبدل الاسم بدل التعليق.

---

## 7-ف2: أخطاء مُجمِّع الكيرنل (`clang: assembler command failed`، "junk at end of line") — سببان مُركَّبان

**المشكلة:** فشل بناء عشرات ملفات `.o` من الكيرنل (`pm_domains-exynos7420.o`, `aes-ce-glue.o`, `bpf_jit_comp.o`, `exynos-pm.o`, `pm_domains_sysfs.o`, `exynos-powermode.o`, `do_mounts.o` وغيرها) بخطأ متكرر:
```
out/soong/.temp/<file>-<hash>.s:<N>: Error: junk at end of line, first unrecognized character is `"'
out/soong/.temp/<file>-<hash>.s:18: Error: file number less than one
clang: error: assembler command failed with exit code 1
```
مئات الأسطر من نفس الخطأ في كل ملف `.s`، أول ظهور دائمًا حول السطر 18 مصحوبًا بـ"file number less than one".

**صعوبة التشخيص:** ملفات `.s` الوسيطة في `out/soong/.temp/` تُحذف فورًا عند الفشل (سباق زمني)، فتعذّر فحص محتواها مباشرة حتى بمحاولة نسخها بحلقة مراقبة سريعة (`cp` عند الإنشاء يلتقط ملفًا فارغًا 0 بايت قبل أن يكتب المُصرّف فيه). التشخيص اعتمد بدل ذلك على قراءة نظام بناء الكيرنل نفسه.

**السبب الأول (مُكتشَف ومُصحَّح، لكن لم يكن كافيًا وحده): `CONFIG_CROSS_COMPILE=""` فارغ في الـdefconfig.**
- `kernel/samsung/universal7420/Makefile:600` يُفعّل كتلة كاملة من أعلام clang الحرجة (`--target=`, `-no-integrated-as`, `--gcc-toolchain=`) فقط ضمن `ifneq ($(CROSS_COMPILE),)`.
- `vendor/lineage/build/tasks/kernel.mk` (نظام بناء الكيرنل الحديث من LineageOS 22 الذي يستدعيه Soong فعليًا عبر `TARGET_KERNEL_SOURCE`) **لا يُمرِّر `CROSS_COMPILE` كسطر أوامر افتراضيًا** (`KERNEL_CROSS_COMPILE` غير مُعرَّف بقيمة افتراضية) — يعتمد كليًا على `CONFIG_CROSS_COMPILE` من الـ`.config`/defconfig نفسه عبر `CROSS_COMPILE ?= $(CONFIG_CROSS_COMPILE:"%"=%)` في Makefile الكيرنل العام.
- الـdefconfig (`arch/arm64/configs/exynos7420-noblelte_defconfig:45`) بقايا من نظام بناء أقدم (عصر CyanogenMod، كان يُمرِّر `CROSS_COMPILE` مباشرة كسطر أوامر) يحتوي `CONFIG_CROSS_COMPILE=""` فارغًا صراحة — تعارض كلاسيكي آخر بين دمج شجرتين من عصرين مختلفين.
- **النتيجة:** بدون `--target=aarch64-linux-gnu`، صرّف clang الكود مستهدفًا معمارية المضيف الافتراضية (x86_64) بدل aarch64 — أكّدنا هذا عبر محاولة تصريف يدوية منفصلة (`asm-offsets.c`) أظهرت أخطاء مميزة لهذا العطل بالضبط (`register 'sp' unsuitable for global register variable on this target`, `value '65536' out of range for constraint 'I'`, `redefinition of 'stat64'`).
- **الإصلاح:**
  ```bash
  cd ~/los22
  cp kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig \
     kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig.bak_crosscompile
  sed -i 's/^CONFIG_CROSS_COMPILE=""/CONFIG_CROSS_COMPILE="aarch64-linux-android-"/' \
     kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig
  ```
  (البادئة `aarch64-linux-android-` تطابق toolchain GCC 4.9 الموجود فعليًا في `prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/`.)
- **أثر جزئي فقط:** بعد هذا الإصلاح وحده، تغيّرت طبيعة الخطأ (بقيت رسالة "junk at end of line" لكن بصيغة أخطاء GNU `as` الكلاسيكية بدل مُجمِّع clang الداخلي — دليل أن `-no-integrated-as` أصبح فعّالًا وأن `aarch64-linux-android-as` الحقيقي أصبح يُستدعى فعلًا) — أي أن هذا الإصلاح **ضروري لكن غير كافٍ**؛ ظل هناك سبب ثانٍ منفصل.

**السبب الثاني (الحاسم): `CONFIG_DEBUG_INFO=y` لا يزال مفعّلاً فعليًا رغم توثيق سابق (القسم 2-أ) يذكر تعطيله.**
- **ملاحظة توثيق مهمة:** القسم 2-أ من هذا الملف يذكر أننا عطّلنا `CONFIG_DEBUG_INFO` ضمن دفعة تعديلات defconfig سابقة — لكن الفحص الفعلي هذه الجلسة أظهر `CONFIG_DEBUG_INFO=y` **لا يزال نشطًا** في الملف الحالي على القرص. السبب الدقيق لعدم انطباق التعديل القديم غير مؤكد (احتمال: `repo sync` لاحق استبدل الملف، أو خطأ حفظ في حينه) — **تنبيه لأي مراجعة مستقبلية لهذا الملف: تحقق دومًا من القيمة الفعلية على القرص بدل الثقة بالتوثيق وحده عند التعامل مع ملفات defconfig تحديدًا**، لأنها عرضة للاستبدال الكامل عبر `repo sync`/checkout بخلاف ملفات `.mk`/`.bp` الفردية.
- **التشخيص:** `kernel/samsung/universal7420/Makefile:720-722`:
  ```makefile
  ifdef CONFIG_DEBUG_INFO
  KBUILD_CFLAGS += -g
  KBUILD_AFLAGS += -gdwarf-2
  endif
  ```
  مع `CONFIG_DEBUG_INFO=y`، يُضاف `-g` لكل ملف .c في الكيرنل. مُصرّف الكيرنل الخاص (`prebuilts/clang/kernel/linux-x86/clang-r416183b`، LLVM 12.0.5) يُصدر عندها توجيهات تصحيح (`.file`/`.loc`) بصيغة لا يفهمها `aarch64-linux-android-as` القديم (binutils من toolchain GCC 4.9، صادر تقريبًا 2014) — تحديدًا خطأ "file number less than one" عند أول توجيه `.file`، يليه انهيار تحليل بقية الملف بالكامل (مئات أخطاء "junk at end of line" التالية كلها أعراض ثانوية لنفس الانهيار الأول، وليست أخطاء منفصلة).
- **الإصلاح:**
  ```bash
  cd ~/los22
  cp kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig \
     kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig.bak_debuginfo
  sed -i 's/^CONFIG_DEBUG_INFO=y/# CONFIG_DEBUG_INFO is not set/' \
     kernel/samsung/universal7420/arch/arm64/configs/exynos7420-noblelte_defconfig
  ```
- **النتيجة المؤكدة:** بعد تطبيق **كلا الإصلاحين معًا**، اختفت جميع أخطاء "junk at end of line"/"file number less than one" بالكامل من سجل البناء، وتقدّم بناء الكيرنل عمليًا حتى `LD kernel/built-in.o` (قرب نهاية مرحلة الربط الداخلية للكيرنل) — أول مرة يتجاوز فيها بناء الكيرنل كل ملفات `.c` الفردية بنجاح.

**كيفية التراجع:** استبدل الـdefconfig بالنسخة الاحتياطية `exynos7420-noblelte_defconfig.bak_crosscompile` (قبل كلا الإصلاحين) أو أزل التعليقين يدويًا.

**الأثر المتوقع:** إيجابي وجوهري — بدون هذين الإصلاحين معًا، بناء الكيرنل بأكمله مستحيل. فقدان `CONFIG_DEBUG_INFO` يعني عدم توفر رموز تصحيح كاملة (`vmlinux` بلا معلومات dwarf غنية) — مقبول لبناء إنتاجي عادي (لا حاجة لتصحيح الكيرنل بـ gdb مباشرة)، ولا يمس أي وظيفة تشغيلية للجهاز.

**ملاحظة حرجة لإعادة الاستخدام (S6 Edge+ وغيره):** كلا الإصلاحين على مستوى **defconfig الجهاز نفسه** (`exynos7420-<device>_defconfig`)، وليس `universal7420-common` أو الكيرنل المشترك — أي جهاز آخر من نفس العائلة له defconfig منفصل خاص به على الأرجح يحتوي نفس القيمتين الموروثتين من نفس الأصل القديم (`CONFIG_CROSS_COMPILE=""` و`CONFIG_DEBUG_INFO=y`). **تحقق من كليهما فورًا** (`grep -n "CONFIG_CROSS_COMPILE\|CONFIG_DEBUG_INFO" arch/arm64/configs/exynos7420-<device>_defconfig`) قبل حتى محاولة أول بناء لجهاز جديد من هذه العائلة، بدل انتظار اكتشاف نفس الخطأين تباعًا عبر عشرات دورات التشخيص كما حدث هنا.

**درس عام مهم لهذا البورت تحديدًا:** أخطاء المُجمِّع الغامضة ("junk at end of line" بلا سياق واضح) في نواة قديمة (3.10) مبنية بـclang حديث نسبيًا غالبًا ليست خطأ نحوي حقيقي في الكود المصدري، بل **عرض تراكمي لأول توجيه تجميع غير مفهوم** (هنا: `.file` الخاص بمعلومات تصحيح DWARF) يُفسِد تحليل بقية الملف بالكامل. القاعدة العملية: عند رؤية عشرات/مئات من نفس رسالة الخطأ في ملف `.s` واحد، **ركّز التشخيص على أول سطر فشل فقط** (وليس كل الأسطر اللاحقة)، وابحث عن سبب جذري واحد يفسر انهيار التحليل من تلك النقطة فصاعدًا.

---

## 7-ف3: روابط رمزية/صلاحيات تنفيذ مكسورة على نطاق واسع في شجرة الكيرنل (نمط متكرر خطير لإعادة الاستخدام)

بعد تجاوز مشاكل المُجمِّع (7-ف2)، ظهرت سلسلة من الأخطاء المختلفة تمامًا، جميعها من **نفس الفئة الجذرية**: ملفات فقدت خاصية نظام ملفات (رابط رمزي أو صلاحية تنفيذ) عند نقل/تصدير شجرة `project289` الأصلية إلى الشكل الحالي — على الأرجح أداة أو عملية لا تحافظ على الروابط الرمزية/صلاحيات `+x` بشكل صحيح عند التصدير.

### أ. `include/uapi/linux/ion.h` — رابط رمزي تحوّل لملف نصي عادي
**المشكلة:** `mach-universal7420.c` فشل بأخطاء `expected identifier or '('`, `unknown type 'ion_heap_type'` إلخ، لأن `ion.h` كان **ملف نصي 43 بايت يحتوي نص المسار حرفيًا** (`../../../drivers/staging/android/uapi/ion.h`) بدل رابط رمزي فعلي. تأكيد عبر `git ls-files -s` أن الوضع `100644` (ملف عادي) وليس `120000` (رابط) — أي أن المشكلة **في شجرة project289 المصدر نفسها**، وليست خطأ محلي في هذا الجهاز.
**الإصلاح:**
```bash
cd ~/los22/kernel/samsung/universal7420
cp include/uapi/linux/ion.h include/uapi/linux/ion.h.bak_brokensymlink
rm include/uapi/linux/ion.h
ln -s ../../../drivers/staging/android/uapi/ion.h include/uapi/linux/ion.h
```

### ب. عشرات سكربتات `.sh` فقدت صلاحية التنفيذ (`+x`)
**المشكلة:** `gen_vdso_offsets.sh` فشل بـ`Permission denied`، مما أنتج `vdso-offsets.h` **فارغًا بصمت** (الـMakefile لا يتحقق من نجاح السكربت بصرامة)، مسببًا لاحقًا خطأ `use of undeclared identifier 'vdso_offset_sigtramp'` في `signal.c` — خطأ بعيد تمامًا عن السبب الجذري الحقيقي، صعّب التشخيص. فحص شامل كشف **أكثر من 70 سكربت `.sh`** في الشجرة بلا صلاحية `+x`، من بينها سكربتات **حرجة فعليًا للبناء** مثل `scripts/clang-android.sh` (تُستدعى مباشرة من كتلة أعلام clang في القسم 7-ف2)، `scripts/link-vmlinux.sh`، `scripts/gcc-version.sh`، `scripts/ld-version.sh`.
**الإصلاح (شامل لكل الشجرة دفعة واحدة):**
```bash
cd ~/los22/kernel/samsung/universal7420
find . -name "*.sh" ! -perm -u+x -exec chmod +x {} \;
# بعد الإصلاح، احذف أي ملفات مولَّدة فارغة نتجت عن السكربتات الفاشلة سابقًا لإجبار إعادة توليدها:
find ~/los22/out -iname "vdso-offsets.h" -delete
find ~/los22/out -path "*vdso*" -name "*.so" -delete
```
**ملاحظة:** فحصنا أيضًا ملفات بلا امتداد `.sh` لكن بـ`shebang` (`#!`) وبلا صلاحية تنفيذ — وجدنا ~30 ملفًا، لكن جميعها أدوات لمعماريات أخرى (`arm`, `ia64`, `powerpc`...) أو توثيق/أدوات مساعدة غير مُستدعاة في مسار بناء `arm64` العادي؛ لم تُلمس.

### ج. ملفات `netfilter` UAPI — روابط رمزية خاطئة استبدلت رؤوسًا مختلفة فعليًا (الأخطر في هذه الدفعة)
**المشكلة:** `net/netfilter/xt_TCPMSS.c` فشل بـ`incomplete definition of type 'const struct xt_tcpmss_info'` و`use of undeclared identifier 'XT_TCPMSS_CLAMP_PMTU'`. الفحص كشف أن `include/uapi/linux/netfilter/xt_TCPMSS.h` (بحروف كبيرة، خاص بوحدة **الهدف/target**) كان **رابطًا رمزيًا خاطئًا** يشير إلى `xt_tcpmss.h` (بحروف صغيرة، خاص بوحدة **المطابقة/match**) — نمط تسمية شائع في netfilter حيث الاسم بحروف كبيرة = target والصغيرة = match، **وغالبًا ببنى بيانات مختلفة تمامًا رغم تشابه الاسم**. فحص إضافي بحث عن كل الروابط الرمزية المُنشأة بنفس التوقيت تقريبًا (على الأرجح من عملية "تطبيع" آلية سابقة خاطئة افترضت أنها تكرارات حالة أحرف فقط) كشف **8 ملفات متأثرة** بنفس النمط:
| الملف (رابط خاطئ) | يشير خطأً إلى | الحالة الحقيقية (حسب `git log`) |
|---|---|---|
| `xt_TCPMSS.h` | `xt_tcpmss.h` | **مختلف** — بنية `xt_tcpmss_info` + `XT_TCPMSS_CLAMP_PMTU` |
| `xt_DSCP.h` | `xt_dscp.h` | **مختلف** — `xt_DSCP_info` + `xt_tos_target_info` |
| `xt_RATEEST.h` | `xt_rateest.h` | **مختلف** — `xt_rateest_target_info` |
| `ipt_ECN.h` | `ipt_ecn.h` | **مختلف** — `ipt_ECN_info` + ثوابت `IPT_ECN_*` |
| `ipt_TTL.h` | `ipt_ttl.h` | **مختلف** — `ipt_TTL_info` |
| `ip6t_HL.h` | `ip6t_hl.h` | **مختلف** — `ip6t_HL_info` |
| `xt_CONNMARK.h` | `xt_connmark.h` | **آمن فعليًا** — الأصل كان مجرد `#include` لنفس الملف، فالرابط يعطي نفس الأثر |
| `xt_MARK.h` | `xt_mark.h` | **آمن فعليًا** — نفس حالة `CONNMARK` |

**منهجية التحقق (مهمة لإعادة الاستخدام):** لكل ملف، استُخدم `git log --all -p -- <path>` لاستخراج آخر محتوى حقيقي قبل تحوّله لرابط رمزي، وقورن يدويًا هل هو فعليًا نفس محتوى نظيره بحروف الحالة الأخرى أم مختلف. **لا تفترض أبدًا** أن ملفين بنفس الاسم بحروف حالة مختلفة في netfilter متطابقان — تحقق من كل واحد عبر `git log` قبل حذف/استبدال أي رابط.
**الإصلاح المطبَّق:** لكل من الملفات الستة "المختلفة فعليًا"، حُذف الرابط الرمزي وأُعيد إنشاء الملف كنص عادي بالمحتوى المُستخرج حرفيًا من `git log --all -p`. `CONNMARK`/`MARK` تُركا كما هما (رابط رمزي، آمن).

**كيفية التراجع:** لكل ملف من الستة، احذفه وأعد إنشاءه كرابط رمزي (`ln -s <lowercase>.h <UPPERCASE>.h>`) — لن يعمل إلا إذا رجع الملف الأصلي المكسور من project289، غير متوقع.

**الأثر المتوقع:** إيجابي وجوهري — بدون هذه الإصلاحات، وحدات netfilter target (`TCPMSS`, `DSCP`, `RATEEST`, `ECN`, `TTL`, `HL`) لا يمكن أن تُبنى إطلاقًا، مما يعطّل ميزات iptables/ip6tables الأساسية على الجهاز (تعديل MSS/TTL/Hop-Limit/DSCP لحركة الشبكة — تُستخدم أحيانًا لأغراض tethering/VPN).

**ملاحظة حرجة لإعادة الاستخدام (S6 Edge+ وغيره):** هذا الخلل على مستوى **شجرة `kernel/samsung/universal7420` المشتركة بالكامل** (وليس خاصًا بـ`noblelte`)، فينطبق تلقائيًا على أي جهاز آخر يستخدم نفس شجرة الكيرنل. **قبل بدء أي بناء لجهاز جديد من هذه العائلة، شغّل فحصًا استباقيًا شاملاً بدل انتظار اكتشاف كل حالة عبر دورة بناء منفصلة:**
```bash
cd kernel/samsung/universal7420
# 1. روابط رمزية مكسورة (تشير لملف غير موجود)
find . -xtype l
# 2. ملفات تحتوي نص مسار رابط رمزي حرفيًا بدل كونها روابط فعلية (نمط ion.h)
find . -type f -size -200c -exec sh -c 'for f; do [ "$(wc -l < "$f")" = "0" ] && grep -qE "^(\.\./)+[a-zA-Z0-9_./-]+$" "$f" && echo "$f"; done' _ {} +
# 3. سكربتات .sh بلا صلاحية تنفيذ
find . -name "*.sh" ! -perm -u+x
# 4. روابط رمزية بين ملفي include بحروف حالة مختلفة لنفس الاسم (نمط netfilter) — راجع كل نتيجة عبر git log يدويًا قبل الحكم إن كانت آمنة أم لا
find . -type l -iname "*.h" -exec sh -c 'for f; do t=$(readlink "$f"); [ "$(basename "$f")" != "$t" ] && [ "$(echo "$(basename "$f")" | tr A-Z a-z)" = "$(echo "$t" | tr A-Z a-z)" ] && echo "$f -> $t"; done' _ {} +
```
**درس عام أهم:** عند نقل/دمج شجرة كيرنل قديمة من مصدر مضغوط أو مُصدَّر (وليس `git clone` مباشر)، لا تثق تلقائيًا بأن الروابط الرمزية وصلاحيات التنفيذ سليمة — افحصها استباقيًا في أول جلسة عمل على الشجرة، قبل حتى أول محاولة بناء، بدل اكتشافها تباعًا عبر عشرات دورات debug مكلفة (كل دورة هنا استغرقت 5-90 دقيقة).

---

## 8. اكتشاف جذري: `systemd-oomd` هو السبب الحقيقي وراء فشل Soong bootstrap المتكرر (وليس نفاذ الذاكرة الفعلي)

**الأعراض:** مرحلة `analyzing Android.bp files and generating ninja file` (Soong bootstrap) تفشل بصمت متكرر (`FAILED: out/soong/build.lineage_noblelte.ninja`, `ninja: build stopped: subcommand failed`, بدون أي رسالة خطأ نصية سوى تحذيرات غير ذات صلة). استمر الفشل رغم: إغلاق Firefox، `GOMAXPROCS=1`، `-j1`، والتحقق من أن سواب zram/swapfile مضبوط بشكل سليم (`vm.swappiness=100`، zram بأولوية 100 فوق swapfile بأولوية -1).

**التشخيص:** `sudo dmesg | grep -i oom` كشف قتل متكرر لـ`soong_build` عبر الـ **kernel OOM killer الحقيقي** (وليس حد cgroup — تأكدنا `systemctl --user show ... -p MemoryMax -p MemoryHigh` يرجع `infinity`). **التفصيل الحاسم:** كل رسائل القتل أظهرت `oom_score_adj:200` (القيمة الافتراضية للعمليات العادية هي **0**) مع `anon-rss:0kB` أو قريب من الصفر وقت القتل — يعني العملية بالكاد كانت تستخدم ذاكرة فعلية حقيقية وقت قتلها، وشي آخر رفع أولويتها للقتل عمدًا.

**السبب الجذري:** `systemd-oomd.service` (خدمة Fedora الافتراضية لإدارة الذاكرة الاستباقية) فعالة (`active (running)`). هذه الخدمة **لا** تنتظر نفاذ الذاكرة الفعلية — تراقب "ضغط الذاكرة" (PSI - Pressure Stall Information) على مستوى الـ cgroup وتقتل استباقيًا أعلى عملية `oom_score_adj` فور حدوث طفرة ضغط مؤقتة، حتى لو الذاكرة والسواب متوفرين بكثرة (تأكدنا `free -h` يعرض غيغابايتات متاحة و66G+ سواب فاضي وقت القتل). طفرة تخصيص الذاكرة الكبيرة لمرحلة Soong bootstrap (Go runtime يحجز عناوين ذاكرة افتراضية ضخمة دفعة واحدة) تُطلق هذا الضغط المؤقت فتقتل `systemd-oomd` العملية استباقيًا قبل ما تكمل، رغم عدم وجود نقص حقيقي.

**الإصلاح المطبَّق:**
```bash
sudo systemctl disable --now systemd-oomd
sudo systemctl mask systemd-oomd
```
**نتيجة الإصلاح:** بعد التعطيل، اجتازت مرحلة Soong bootstrap بنجاح للمرة الأولى (بعد عشرات المحاولات الفاشلة سابقًا)، ووصل البناء فعليًا لمرحلة تجميع الكيرنل.

**كيفية التراجع:** `sudo systemctl unmask systemd-oomd && sudo systemctl enable --now systemd-oomd`.

**ملاحظة حرجة لإعادة الاستخدام (S6 Edge+ وأي جهاز آخر، وأي جهاز Fedora/أي توزيعة تستخدم systemd-oomd افتراضيًا):** **عطّل `systemd-oomd` كأول خطوة** قبل أي محاولة بناء AOSP/LineageOS على جهاز بذاكرة محدودة (أقل من 16GB)، بدل انتظار اكتشافه عبر عشرات دورات debug (استغرق هذا الاكتشاف عدة جلسات وساعات من التتبع الخاطئ خلف "نقص ذاكرة حقيقي" افتراضي). أي توزيعة تستخدم `systemd-oomd` (Fedora Workstation/KDE افتراضيًا منذ إصدارات حديثة) معرّضة لنفس المشكلة.

---

## 9. ملف كيرنل مفقود بالكامل: `net/netfilter/xt_hl.c` (موديول مطابقة hop-limit لـ IPv6)

**العرض:** `make[3]: *** No rule to make target 'net/netfilter/xt_hl.o', needed by 'net/netfilter/built-in.o'. Stop.`

**التشخيص:** `net/netfilter/xt_HL.c` (موديول *target*، حروف كبيرة) موجود، لكن `net/netfilter/xt_hl.c` (موديول *match*، حروف صغيرة) **غير موجود إطلاقًا** في الشجرة — تأكدنا عبر `git log --all --diff-filter=D -- net/netfilter/xt_hl.c` أنه لم يُحذف من تاريخ هذا الريبو، بل لم يكن موجودًا أبدًا (نفس عائلة مشكلة netfilter case-sensitivity الموثقة بالقسم 7-ف3، لكن هذه المرة الملف غائب كليًا وليس رابطًا مكسورًا).

**الإصلاح المطبَّق (تعطيل بدل إعادة كتابة الكود):** بدل محاولة إعادة كتابة الملف من الذاكرة (خطر دقة عالٍ لكود كيرنل)، عطّلنا الخيارين اللذين يفرضان تفعيل `NETFILTER_XT_MATCH_HL` عبر `select` في Kconfig:
```bash
cd kernel/samsung/universal7420
sed -i \
  -e 's/^CONFIG_IP_NF_MATCH_TTL=.*/# CONFIG_IP_NF_MATCH_TTL is not set/' \
  -e 's/^CONFIG_IP6_NF_MATCH_HL=.*/# CONFIG_IP6_NF_MATCH_HL is not set/' \
  arch/arm64/configs/exynos7420-noblelte_defconfig
```
كلا الخيارين موثّقان صراحة في Kconfig أنفسهما كـ"خيارات توافقية خلفية لراحة oldconfig فقط" (`This is a backwards-compat option for the user's convenience`) — تعطيلهما آمن 100%، لا يمس أي وظيفة فعلية (IPv6، VPN، DNS، proxy تعمل جميعًا بشكل طبيعي، لأن `xt_hl`/`xt_ttl` مجرد موديول iptables نادر الاستخدام لمطابقة قيمة TTL/hop-limit، يُستخدم غالبًا فقط لكشف tethering).

**درس مهم:** تعديل `.config` يدويًا (عبر `sed` على ملف `.config` المُولَّد مباشرة، أو حتى إعادة توليده بـ`make defconfig` مرة واحدة) **لا يكفي** إذا كان خيار آخر يفرض القيمة عبر `select` — لازم تعطيل الخيار **المصدر** (الذي يعمل `select`) بالـ defconfig، ثم حذف `.config` بالكامل وإعادة توليده من الصفر (`rm .config && make defconfig`) للتأكد من عدم بقاء قيم قديمة من دمج جزئي سابق (`silentoldconfig`/`oldconfig` لا يعيد التوليد الكامل، فقط يدمج فوق `.config` الموجود).

**كيفية التراجع:** استرجع `exynos7420-noblelte_defconfig.bak_xthl`، أو أعد كتابة `net/netfilter/xt_hl.c` من مصدر kernel.org لنفس نسخة الكيرنل إذا احتجت ميزة hop-limit matching مستقبلاً.

---

## 10. تعارض Kconfig: `struct esd_protect` "غير مكتملة" بسبب اعتماد `DECON_EVENT_LOG` على `DEBUG_INFO`

**العرض:** `drivers/video/exynos/decon_7420/decon.h:841:21: error: field has incomplete type 'struct esd_protect'`، متبوعًا بـ`ld.lld: error: target emulation unknown: -m or at least one .o file required` (نتيجة ثانوية لفشل التجميع، وليست خطأ مستقل).

**التشخيص:** تعريف `struct esd_protect` بالكامل (`decon.h:626-638`) محشور داخل `#ifdef CONFIG_DECON_EVENT_LOG ... #else ... #endif` (السطور 510-703). فرع `#else` لا يحتوي نفس التعريف. رغم أن `CONFIG_DECON_EVENT_LOG=y` بالـ defconfig، تبيّن أن الخيار **غائب كليًا** من `.config` الفعلي (ليس حتى `# not set`) — لأن Kconfig يحدد:
```
config DECON_EVENT_LOG
        depends on DEBUG_INFO && EXYNOS_DECON_7420
```
وإحنا عطّلنا `CONFIG_DEBUG_INFO` عمدًا بالقسم 7-ف2 (إصلاح أساسي وضروري لحل تعارض DWARF/binutils الذي كان يمنع التجميع بالكامل) — فتعطيل `DEBUG_INFO` عطّل تبعًا `DECON_EVENT_LOG` دون قصد، مما كسر تعريف بنية أساسية غير متعلقة فعليًا بالـ debug logging.

**الإصلاح المطبَّق:** تعديل الـ Kconfig نفسه (مو الـ defconfig) لفصل الاعتماد على `DEBUG_INFO`:
```bash
cd kernel/samsung/universal7420
cp drivers/video/exynos/decon_7420/Kconfig drivers/video/exynos/decon_7420/Kconfig.bak_esdfix
sed -i '/^config DECON_EVENT_LOG/,/depends on/{s/depends on DEBUG_INFO && EXYNOS_DECON_7420/depends on EXYNOS_DECON_7420/}' \
  drivers/video/exynos/decon_7420/Kconfig
```
بعدها إلزاميًا: `rm .config && make ... exynos7420-noblelte_defconfig` لإعادة التوليد الكامل (نفس درس القسم 9).

**درس مهم لإعادة الاستخدام:** هذا خلل أصلي بشجرة سامسونج (ربط بنية بيانات أساسية بخيار debug logging عرضي) — **أي جهاز آخر من عائلة exynos7420 (بما فيها S6 Edge+) سيواجه نفس الخطأ بالضبط** إذا عُطِّل `CONFIG_DEBUG_INFO` (وهو إصلاح إلزامي لكل هذه العائلة حسب القسم 7-ف2). طبّق هذا الإصلاح على `Kconfig` مباشرة كخطوة قياسية بعد تعطيل `DEBUG_INFO`، بدل انتظار اكتشافه من جديد.

**كيفية التراجع:** استرجع `Kconfig.bak_esdfix`.

---

## 11. تحذير: حذف `out/soong` يفرض إعادة بناء كاملة من الصفر (ليس فقط إعادة تحليل)

عند حل مشاكل Soong المستعصية (مثل خطأ `provider "cc.SharedLibraryInfo" was modified after being set`)، حذف `out/soong` و`out/.module_paths` يمسح بصمات أوامر ninja المخزّنة (`.ninja_log` command hashes مبنية على متغيرات البيئة المولَّدة). أي فرق بسيط بالبيئة عند إعادة التوليد (حتى وجود/غياب `GOMAXPROCS` كمتغير) يجعل ninja يعتبر **كل** هدف "تغيّر أمر بنائه" ويعيد الكل من الصفر (لاحظنا القفزة من ~4000 إلى ~183,700 خطوة إجمالية). **هذا لا يعني بالضرورة إعادة تجميع فعلي لكل شيء** — إذا كان `ccache` مفعّلاً (تأكدنا: نعم، بنسبة إصابة ~43%)، جزء كبير من "إعادة البناء" هو استرجاع سريع من الكاش، فالوقت الفعلي الضائع أقل بكثير من العدد الظاهري للخطوات.

**الدرس:** تجنّب حذف `out/soong` إلا كملاذ أخير، وإذا اضطررت، تحقق أولاً من `ccache -s` لتقدير الأثر الحقيقي، ولا تفزع من رقم الخطوات الإجمالي الكبير.

---

## 12. إصلاح جذري وعام: `ld.lld` يرفض ملفات object فارغة (`empty archive`) عند تجميع مجلدات كيرنل خالية من التعريفات

**العرض:** `ld.lld: error: target emulation unknown: -m or at least one .o file required` متكرر لعدة مجلدات مختلفة (`drivers/gpu`، `sound/drivers`، `sound/i2c`، `sound/i2c/other`).

**التشخيص:** قاعدة `cmd_link_o_target` القديمة في `scripts/Makefile.build` (نظام kbuild القديم) تُنشئ أرشيف `ar` **فارغًا** (`$(AR) rcs$(KBUILD_ARFLAGS) $@`) عندما يكون `obj-y` لمجلد فارغًا (كل التعريفات المتعلقة معطّلة بالـ`.config` — مثلاً كل سائقي ALSA من فئة PCI/PCMCIA القديمة في `sound/i2c` معطّلون لأنهم غير ذوي صلة بهاتف). الرابط القديم GNU `ld` كان يتسامح مع أرشيف فارغ كمدخل لعملية `-r` (composite link)، لكن `ld.lld` الحديث **يرفضه صراحة**. المشكلة **تتكرر في كل مجلد فارغ جديد** يُكتشف — إصلاح توفيق واحد تلو الآخر (مثل تفعيل `CONFIG_SND_DUMMY=y` لحل `sound/drivers`) غير قابل للتوسع لأن بعض المجلدات (`sound/i2c`) ليس لها أي سائق آمن للتفعيل كحل مؤقت.

**الإصلاح المطبَّق (نظامي، يحل كل الحالات دفعة واحدة):** تعديل مصدر قاعدة `cmd_link_o_target` نفسها في `scripts/Makefile.build` بحيث بدل إنشاء أرشيف `ar` فارغ، تُجمَّع ملف object فارغ حقيقي عبر المُجمِّع (يُقبل دائمًا من `ld -r`):
```bash
cd kernel/samsung/universal7420
cp scripts/Makefile.build scripts/Makefile.build.bak_emptyobj
```
تعديل قاعدة `cmd_link_o_target` (حوالي السطر 338-341) من:
```makefile
cmd_link_o_target = $(if $(strip $(obj-y)),\
                     $(LD) $(ld_flags) -r -o $@ $(filter $(obj-y), $^) \
                     $(cmd_secanalysis),\
                     rm -f $@; $(AR) rcs$(KBUILD_ARFLAGS) $@)
```
إلى:
```makefile
cmd_link_o_target = $(if $(strip $(obj-y)),\
                     $(LD) $(ld_flags) -r -o $@ $(filter $(obj-y), $^) \
                     $(cmd_secanalysis),\
                     rm -f $@; $(CC) $(c_flags) -c -x c /dev/null -o $@)
```

**النتيجة المؤكدة:** حل كل حالات `ld.lld: error: target emulation unknown` دفعة واحدة (`sound/drivers`, `sound/i2c`, `sound/i2c/other`, وأي مجلد فارغ مستقبلي) — لا حاجة لتفعيل سائقين وهميين (`CONFIG_SND_DUMMY` أُبقي مفعّلاً لكن أصبح غير ضروري).

**ملاحظة لإعادة الاستخدام (S6 Edge+ وكل عائلة exynos7420):** هذا إصلاح على مستوى `scripts/Makefile.build` المشترك — ينطبق تلقائيًا على أي جهاز يستخدم نفس شجرة الكيرنل. طبّقه استباقيًا كخطوة قياسية بدل انتظار اكتشافه لكل مجلد فارغ على حدة.

**كيفية التراجع:** استرجع `scripts/Makefile.build.bak_emptyobj`.

---

## 13. `-Werror=strict-prototypes` يفشل على تصريحات دوال قديمة الطراز (K&R-style)

**العرض:** `drivers/input/input.c:676:24: error: a function declaration without a prototype is deprecated in all versions of C and is not supported in C2x [-Werror,-Wstrict-prototypes]` — كود سامسونج قديم يستخدم تصريحات `int foo()` بدل `int foo(void)`.

**محاولة أولى فاشلة:** إضافة `KBUILD_CFLAGS += $(call cc-disable-warning, strict-prototypes)` بعد السطر 618 في `Makefile` الجذري للكيرنل — **لم تحل المشكلة**؛ نفس الخطأ تكرر بالضبط في البناء التالي.

**التشخيص:** بحث شامل عن `strict-prototypes` في `Makefile` كشف سطرًا **لاحقًا** (796) يعيد تفعيل الخطأ صراحة:
```makefile
KBUILD_CFLAGS   += $(call cc-option,-Werror=strict-prototypes)
```
(بتعليق أصلي: "require functions to have arguments in prototypes, not empty 'int foo()'"). بما أن ترتيب أعلام `KBUILD_CFLAGS` مهم (الأعلام اللاحقة تفوز عند التعارض)، فإن هذا السطر اللاحق كان يُلغي أثر إصلاحي الأول بالكامل.

**الإصلاح الفعلي (نجح مؤكدًا):** تعطيل السطر 796 نفسه بدل إضافة علم مضاد:
```bash
cd kernel/samsung/universal7420
cp Makefile Makefile.bak_strictproto
sed -i '796s|^KBUILD_CFLAGS   += \$(call cc-option,-Werror=strict-prototypes)|# KBUILD_CFLAGS += $(call cc-option,-Werror=strict-prototypes)  # DISABLED: legacy K\&R-style declarations in old Samsung driver code trigger this on modern clang|' Makefile
```

**درس مهم:** عند إضافة علم لتعطيل تحذير/خطأ في `Makefile` كيرنل كبير، **ابحث دائمًا عن كل الأسطر الأخرى** التي تذكر نفس اسم التحذير (`grep -n "اسم-التحذير" Makefile`) قبل افتراض أن إضافة علم واحد كافية — قد يوجد علم متعارض لاحق يُلغي أثرك.

**كيفية التراجع:** استرجع `Makefile.bak_strictproto`.

---

## 14. ملحمة VINTF الكاملة: من `target-level="legacy"` إلى تعطيل `PRODUCT_ENFORCE_VINTF_MANIFEST`

سلسلة أخطاء VINTF (Vendor Interface / Treble compatibility) متتالية عند الوصول لمرحلة تعبئة الصور (packaging)، كل واحدة كشفت المشكلة التالية بعد حل السابقة. **الدرس العام الأهم في النهاية: هذا الجهاز (Note5، ما قبل Treble الكامل فعليًا) لا يمكن أن يجتاز فحص توافق VINTF الصارم بأي مستوى FCM مجمّد، بغض النظر عن القيمة المختارة — الحل الصحيح هو تعطيل الفحص كليًا، وليس البحث عن "المستوى الصحيح".**

### أ. `target-level="legacy"` لم يعد قيمة صالحة
**العرض:** `ERROR: No such file or directory: Cannot find framework matrix at FCM version legacy`
**السبب:** كل من `device/samsung/noblelte/manifest.xml` و`device/samsung/universal7420-common/manifest.xml` كانا يحملان `target-level="legacy"` — مستوى FCM أُزيل دعمه من أدوات بناء أندرويد الحديثة.
**محاولة الإصلاح الأولى:** تغييره إلى `target-level="5"` (أقرب مستوى رقمي صالح لجهاز HIDL-era قديم). هذا حل الـ HALs القياسية لكن كشف عن المشكلة التالية.

### ب. HALs خاصة بالجهاز غير معلنة بأي مصفوفة إطار عمل
**العرض:** `ERROR: files are incompatible: ... instances are in the device manifest but not specified in framework compatibility matrix` (18 HAL من نوع `vendor.lineage.*` و`vendor.samsung.hardware.radio.*`).
**الإصلاح:** وُجد ملف هيكلي غير موصول `device/samsung/universal7420-common/compatibility_matrix.xml` (9 HALs عامة فقط)، تمت إضافة الـ8 كتل `<hal>` الناقصة إليه، ثم وصله عبر:
```makefile
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(COMMON_PATH)/compatibility_matrix.xml
```
في `BoardConfigCommon.mk`.

### ج. خاصية `type="device"` خاطئة بدل `type="framework"`
**العرض:** `ERROR: Cannot fetch system matrix` — `checkvintf` يرفض الملف بقوله `is not a framework compatibility matrix`.
**السبب:** `<compatibility-matrix version="2.0" type="device">` — الخاصية `type` يجب أن تكون `"framework"` عند استخدام الملف عبر `DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE`؛ لاحقة اسم الملف `.device.xml` مجرد تسمية تمييزية، **لا علاقة لها بخاصية `type` الداخلية**.
**الإصلاح:** `sed -i 's/type="device"/type="framework"/' compatibility_matrix.xml`.

### د. `check_vintf_system` فشل: لا يوجد `/vendor` منفصل قابل للحل
تبيّن لاحقًا أن هذا لم يكن يسبب فشلًا حقيقيًا مستقلاً (بل كان جزءًا من نفس سلسلة أخطاء VINTF التي حُلّت بالكامل بالخطوة (هـ) أدناه).

### هـ. `check_vintf_compatible`: HALs مفقودة بغض النظر عن مستوى FCM المختار
**العرض عند `target-level="5"`:** HALs قديمة مطلوبة (`android.hidl.token`, `android.system.net.netd@1.1`, `android.system.wifi.keystore`, `netutils-wrapper`) — **حُذفت فعليًا من كود إطار عمل Android 15/LineageOS 22** ولم تعد موجودة كخدمات، فلا يمكن لأي بيان جهاز توفيرها.
**محاولة:** رفع `target-level` إلى `8` (أحدث مستوى متوفر). **النتيجة:** مجموعة HALs مفقودة **مختلفة تمامًا** — هذه المرة HALs حديثة جدًا (`android.hardware.radio@1.4`, `usb@1.3`, `sensors@1.0`, `neuralnetworks@1.1`...) لأن سائقي HIDL القدامى في Note5 لا يوفرون هذه الإصدارات الحديثة.
**الاستنتاج:** الجهاز يقع في "منطقة وسطى" — يخلط فريموورك حديث (Android 15) مع سائقين HIDL من حقبة ما قبل Treble الكامل — **لا يوجد مستوى FCM مجمّد واحد يطابق الجانبين معًا**. جرّبنا `BUILD_BROKEN_VINTF_ERROR := true` أولاً (أضفناه في `BoardConfig.mk`) لكن تبيّن أن هذا العلم **غير موجود إطلاقًا** في شجرة `build/make/` لهذا الإصدار (تحقّقنا عبر `grep -rn` كاملة) — بلا أي أثر.

**الإصلاح الصحيح والنهائي:** تعطيل فحص `PRODUCT_ENFORCE_VINTF_MANIFEST` بالكامل (المتغيّر الذي يُفعّل/يُعطّل مجموعة قواعد `check_vintf_*` كلها في `build/make/core/Makefile`، مشتق افتراضيًا من `PRODUCT_FULL_TREBLE`):
```makefile
# في device.mk أولاً (لم يكفِ وحده):
PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := false
```
**فخ مهم اكتُشف:** هذا التعيين في `device.mk` **لم يُطبَّق فعليًا** رغم صحته المنطقية — `get_build_var PRODUCT_ENFORCE_VINTF_MANIFEST` استمر يرجع `true`. السبب: `device/samsung/universal7420-common/BoardConfigCommon.mk` كان يحتوي **بالفعل** سطرًا يضبط نفس المتغيّر إلى `true` صراحة (سطر قديم موجود مسبقًا في الشجرة، على الأرجح من محاولة توافق Treble سابقة فاشلة). ملفات `BoardConfig.mk` تُقرأ في AOSP **بعد** ملفات `device.mk`/المنتج، فتفوز قيمتها الأخيرة. **الإصلاح الفعلي:**
```bash
cd device/samsung/universal7420-common
sed -i '80s/PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true/PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := false/' BoardConfigCommon.mk
```
تأكيد النجاح: `get_build_var PRODUCT_ENFORCE_VINTF_MANIFEST` → `false`، والبناء تجاوز كل فحوصات `check_vintf_*` ووصل فعليًا لبناء صور `system.img`/`cache.img` كاملة لأول مرة في كامل هذا المشروع.

**درس عام حاسم لإعادة الاستخدام:** عند تعيين متغير `PRODUCT_*_OVERRIDE` في `device.mk` ولا يظهر أثره، **ابحث دائمًا** عن كل مكان آخر يضبط نفس الاسم (`grep -rln "اسم_المتغير" --include=*.mk .`) — قد يوجد تعيين مباشر في `BoardConfig*.mk` يُقرأ لاحقًا ويفوز. تحقّق من القيمة الفعلية المحسوبة دائمًا عبر `get_build_var <VAR>` بدل افتراض نجاح التعديل من مجرد كتابته.

**كيفية التراجع الكامل:** استرجع `BoardConfigCommon.mk.bak_vintfoverride`، `manifest.xml.bak_level5` (×2)، `compatibility_matrix.xml.bak_typefix`، `BoardConfig.mk.bak_vintferror` (يمكن حذف `BUILD_BROKEN_VINTF_ERROR` منه لاحقًا، غير مؤثر لكن غير ضار).

---

## 15. `ab_update=true` خطأً رغم أن Note5 جهاز شريحة واحدة (non-A/B)

**العرض:** بعد تجاوز كل عوائق VINTF والوصول لبناء صور `system.img`/`cache.img` بنجاح كامل (أول نجاح من هذا النوع في المشروع)، فشل توليد حزمة OTA فقط: `AssertionError: META/ab_partitions.txt is required for ab_update` من سكربت `ota_from_target_files.py`.
**التشخيص:** `META/misc_info.txt` يحتوي `ab_update=true` رغم أن `AB_OTA_UPDATER` **غير معرّف إطلاقًا** في أي ملف بشجرة `device/samsung/noblelte` أو `device/samsung/universal7420-common` — القيمة الافتراضية في هذا الإصدار الحديث من AOSP أصبحت `true` عند عدم التصريح، بعكس الافتراض القديم المتوقع (`false`). Note5 جهاز شريحة تخزين واحدة تقليدي (non-seamless-update)، فلا يوجد `ab_partitions.txt` أصلاً ولا ينبغي توليد حزمة A/B له.
**الإصلاح:** (قيد التطبيق — انظر الأمر التالي في المحادثة)
```makefile
AB_OTA_UPDATER := false
```
يُضاف صراحة في `BoardConfigCommon.mk` أو `BoardConfig.mk`.
**ملاحظة لإعادة الاستخدام:** أي جهاز من عائلة exynos7420 غير A/B (كل الأجهزة القديمة في هذه العائلة، بما فيها S6 Edge+) يحتاج هذا التصريح الصريح — لا تعتمد على الافتراض الضمني لأي متغير Treble/OTA في شجرات AOSP الحديثة؛ صرّح دائمًا بالقيم المطلوبة صراحة.

---

---

# المرحلة الثانية: إصلاحات الإقلاع (bootloop) — تُختبر على الجهاز أولاً ثم تُنقل للمصدر

## 16. ❌ `fileencryption=none` في fstab — خطأ، أُزيل (انظر 24)
**الملف:** `device/samsung/universal7420-common/ramdisk/etc/fstab.samsungexynos7420.noble` — سطرا USERDATA (f2fs و ext4).
**الإضافة:** `,fileencryption=none` بعد `reservedsize=128M`. (نسخة احتياطية: `.bak_fileenc`).
**الأثر:** vold يتعامل مع /data غير المشفّر صراحة، والإقلاع وصل إلى surfaceflinger/bootanim.

## 17. keystore2 وخطأ `-68` — **ليس سببًا للـ bootloop** (لا تغيير في المصدر)
keystore2 يبدأ طبيعيًا عبر `class_start early_hal` في `late-fs` (init.rc). الخطأ `earlyBootEnded -68` = `HARDWARE_TYPE_UNAVAILABLE`؛ keystore2 يجد `keymaster@3.0` (SOFTWARE) ويستعمله بمغلّف emulation — غير قاتل.
**تحذير:** تغيير `class early_hal` → `class hal` يسبب deadlock (vold يطلب keystore2 في `init_user0` داخل post-fs-data قبل `on boot`). أُرجِع الملف لاحقًا بسطر `on late-fs start keystore2` — زائد وغير ضار؛ **لا يُنقل للمصدر**.
**ملاحظة جانبية مفتوحة:** `mcDriverDaemon` (mobicore/TEE) يفشل: `libMcClient.so` مفقودة.

## 18. السبب الحقيقي الأول للـ reboot: APEX المضغوطة (`.capex`) لا تُفعَّل على كيرنل 3.10
**العرض:** `init: Service bpfloader has 'reboot_on_failure'... reason: reboot,netbpfload-missing`.
**السلسلة:** `/system/etc/init/netbpfload.rc` placeholder يشغّل `/system/bin/false` بانتظار أن يستبدله rc من APEX الـ tethering. apexd يفك `.capex` إلى `/data/apex/decompressed/` ثم يفشل: `Failed to create Apex Verity device ... Failed to activate dm-device` — كل الـ 22 APEX المضغوطة فشلت (APEX على /data تتطلب dm-verity).
**اختبار الجهاز (نجح):** استخراج `original_apex` من كل `.capex` (`unzip -p x.capex original_apex > x.apex`) ووضعها في `/system/apex/` بدل `.capex` (سياق `system_file`).
**الإصلاح الدائم في المصدر:** تعطيل ضغط APEX (في `device.mk`):
```makefile
PRODUCT_COMPRESSED_APEX := false
```
**تحقق إلزامي بعد البناء:** `ls out/target/product/noblelte/system/apex/*.capex | wc -l` → `0`. إن لم يكن 0 فهناك ملف منتج يعيد ضبطه — ابحث: `grep -rn "COMPRESSED_APEX" build/make device vendor/lineage`، واستعمل `OVERRIDE_PRODUCT_COMPRESSED_APEX := false`.

## 19. السبب الحقيقي الثاني: bpffs في كيرنل 3.10 لا يدعم `renameat2(RENAME_NOREPLACE)` (مُطبّق في المصدر)
**العرض:** `NetBpfLoad: rename /sys/fs/bpf/netd_readonly/tmp_map_... -> -1 [22:Invalid argument]` ثم `CRITICAL FAILURE LOADING BPF PROGRAMS` وخروج بالحالة 2.
**السبب:** `fs/namei.c:4249` — `if (flags && !old_dir->i_op->rename2) return -EINVAL;` و`bpf_dir_iops` يعرّف `.rename` فقط.
**الإصلاح:** `kernel/samsung/universal7420/kernel/bpf/inode.c` (نسخة احتياطية `.bak_rename2`): دالة `bpf_rename2` ترفض أي flag غير `RENAME_NOREPLACE` وتستدعي `simple_rename` (VFS يفرض NOREPLACE بنفسه في `namei.c:4429`)، وإضافة `.rename2 = bpf_rename2,` إلى `bpf_dir_iops`.
**النتيجة:** `NetBpfLoad: success.` والجهاز يتجاوز الشعار دون reboot (شاشة سوداء).
**ملاحظات:** أخطاء `bpfGetFdProgId failed [22]` و`Unsupported kernel version (30a006c)` غير قاتلة (بفضل تعديلات LineageOS الموجودة في `packages/modules/Connectivity`: `Support <4.14 kernels`، `Relax kernel version requirement`، `netd: Remove <4.14 kernel restrictions`).

## 20. أدوات تشخيص مؤقتة على الجهاز — **لا تُنقل للمصدر**
- `/system/etc/init/bootlog.rc`: خدمة `logcat -b all -f /data/local/tmp/boot.log` تبدأ في `late-fs` (seclabel `u:r:su:s0`) + `setprop sys.usb.config adb` في post-fs-data.
- `/data/misc/adb/adb_keys` = مفتاح الحاسوب.
- `/system/bin/netbpfload` stub — أُنشئ ثم **حُذف** (الخدمة لا تستدعيه أصلاً).
- `echo 0 > /sys/fs/selinux/enforce` في TWRP — بلا أثر على إقلاع النظام.

## 21. المفتوح حاليًا (بعد نجاح bpfloader)
حلقات SIGABRT لـ: `surfaceflinger` (عند "Initializing graphics H/W")، `netd`، وخدمة HAL باسم `android.hardwar...`. ينقص `android.hardware.configstore@1.0::ISurfaceFlingerConfigs` في VINTF.

## 22. إصلاحات مصدر إضافية قبل البناء الكامل (2026-09-23)
- **ضغط APEX:** `PRODUCT_COMPRESSED_APEX := false` في `device.mk` **لا يعمل** لأن `build/make/target/product/updatable_apex.mk:26` يضبطه `:= true` بعده. الصحيح: `OVERRIDE_PRODUCT_COMPRESSED_APEX := false` في `device/samsung/noblelte/device.mk` (يُقرأ في `build/make/core/product_config.mk:542`) + `export OVERRIDE_PRODUCT_COMPRESSED_APEX=false` احتياطًا. تحقق: `get_build_var PRODUCT_COMPRESSED_APEX` → `false`، وبعد البناء لا ملفات `.capex`.
- **netd** (`U+ platform with cg2_path != /sys/fs/cgroup is unsupported`): `device/samsung/universal7420-common/configs/cgroups.json` — `Cgroups2.Path` من `/dev/cg2_bpf` إلى `/sys/fs/cgroup` (نسخة احتياطية `.bak_cg2`). النواة فيها `compat_cgroup2_fs_type`.
- **mobicore/gatekeeper** (`libMcClient.so not found` → `Unable to open GateKeeper HAL`): `mcDriverDaemon` 32-بت ونسخة `vendor/lib/libMcClient.so` لم تكن مثبّتة. أُضيف إلى `device.mk`:
  `PRODUCT_COPY_FILES += vendor/samsung/noblelte/proprietary/vendor/lib/libMcClient.so:$(TARGET_COPY_OUT_VENDOR)/lib/libMcClient.so`
  (انتبه: تكرار تنفيذ `echo >>` ولّد أسطرًا مكررة — نُظّفت).
- **مفتوح:** audio HAL 32-بت يسقط بـ `Binder threadpool cannot be shrunk after starting`؛ surfaceflinger: `libEGL: couldn't find an OpenGL ES implementation` رغم وجود `libGLES_mali.so` في الـ blobs وعدم نقص أي من مكتباتها المعتمدة.

## 23. patches الـ 7420 (project289 / samsungexynos7420)
المجلدات `~/los22/patches/7420_patches` و`patches67/7420_patches` و`project289/7420_patches` كلها نفس الـ commit `8fb67ef "Do not apply frameworks/native patches"` (فرع lineage-20.0 = Android 13).
فحص جاف (`~/check_patches.sh`): نظيف فقط `frameworks_native/0001-Disable-gpu-service.patch` و`system_security/0001-keystore-hackup.patch` — **طُبّقا** كـ commits (للتراجع: `git reset --hard HEAD~1` داخل `frameworks/native` أو `system/security`).
متعارضة (لم تُطبّق): fp-always-on revert، hwui-reset-to-13 (خطر)، obsolete-debug-option revert، createEventQueue pre-S، Nfc FW sysprop، NetworkStack netlink revert.
⚠️ عنوان الـ commit نفسه يقول "Do not apply frameworks/native patches" — أي أن صاحب الفرع استبعد patches frameworks/native عمدًا؛ `Disable-gpu-service` طُبّق للاختبار، ويُتراجع عنه إن سبّب مشكلة.

## 24. تصحيح: `fileencryption=none` يسبب reboot إلى recovery
السجل: `Invalid file contents encryption mode: none` ← `/data is file encrypted` ← `Unable to read system policy with name /data/unencrypted/ref` ← `Rebooting into recovery`.
مجرد وجود `fileencryption=` يجعل fs_mgr يعامل /data كـ FBE. **الإصلاح:** حذف `,fileencryption=none` من سطري USERDATA في `ramdisk/etc/fstab.samsungexynos7420.noble` (المصدر) و`/system/vendor/etc/fstab.samsungexynos7420` (الجهاز). بعده: الجهاز يبقى في النظام (شاشة سوداء) و adbd يعمل (`unauthorized`).

---

# ✅ المرحلة الثالثة: أول إقلاع ناجح (2026-09-24) — `sys.boot_completed=1`

## 25. سلسلة ما بعد bpfloader حتى الإقلاع الكامل
1. **surfaceflinger / شاشة سوداء:** `libEGL: couldn't find an OpenGL ES implementation` — مجلد `/vendor/lib{,64}/egl/` **لم يُثبَّت إطلاقًا** في الـ ROM. إضافة `libGLES_mali.so` يدويًا أظهر البوت أنيميشن.
   ⚠️ `vendor/samsung/universal7420-common/proprietary/vendor/lib/egl/libGLES_mali.so` هو **نسخة 64-بت** (نفس BuildID لنسخة lib64) — من خلل الـ blobs المكررة (قسم 7-ش). تطبيقات 32-بت لن تستخدم GPU حتى يُستبدل بنسخة 32-بت حقيقية.
2. **libMcClient.so** مفقودة بنسختيها (32 و64) رغم وجودها في `proprietary-files.txt` — أُضيفت يدويًا (يحتاجها keymaster/gatekeeper/mcDriverDaemon).
3. **audio HAL — `F ProcessState: Binder threadpool cannot be shrunk after starting`:**
   `hardware/interfaces/audio/common/all-versions/default/service/service.cpp` — السطر 80 `ProcessState::self()->startThreadPool()` ثم السطر 83 `ABinderProcess_setThreadPoolMaxThreadCount(1)` → libbinder في A15 يُجهض. **الإصلاح:** تعليق السطر 83 (نسخة احتياطية `.bak_threadpool`). بناء: `m android.hardware.audio.service`.
4. **system_server Watchdog / عالق على البوت أنيميشن:** ANR: `AudioService.<init> → AudioSystem.* → getService<IAudioFlingerService>` ينتظر للأبد. في A15 لا يسجّل audioserver خدمة AudioFlinger بدون HAL — **تعطيل audio HAL لا يحل المشكلة**، الـ HAL إلزامي.
5. **audio HAL — SIGSEGV (fault addr 0x0) في خيط HwBinder** بعد إصلاح الـ threadpool، سببه `audio.primary.universal7420.so`. **حل مؤقت:** إخفاؤه ← الـ wrapper يسقط إلى `audio.primary.default.so` (stub بلا صوت) ← **الإقلاع اكتمل**.
6. **أدوات:** `ro.adb.secure=0` + `persist.sys.root_access=3` في build.prop (LineageOS يمنع `adb root` افتراضيًا)؛ tombstoned لا يحفظ ملفات (`unexpected dump type`) — الـ ANR في `/data/anr` تُسحب من TWRP.
7. **درس:** بعد `adb reboot recovery` استخدم `adb wait-for-recovery` قبل أي أمر (وإلا تُنفَّذ الأوامر على Android المُطفأ جزئيًا — سبب رسائل `'/system' not in fstab`).

## 26. ما لا يعمل بعد الإقلاع (المرحلة التالية)
SIM / IMEI / RIL (`rild`: `/vendor/lib64/libril.so is 32-bit instead of 64-bit`)، Wi-Fi، Bluetooth، الكاميرا، الحساسات/التدوير (`gpsd`: `libsensor-mod.so is 32-bit instead of 64-bit`)، الصوت (stub)، Widevine (`libwvhidl.so` رمز protobuf مفقود)، armnn. **النمط الغالب:** blobs مكررة/خاطئة المعمارية بين lib وlib64 — نفس مشكلة 7-ش لكن في الاتجاه المعاكس.

## 27. نقل تعديلات الجهاز إلى المصدر (2026-09-24) + فشل البناء بالذاكرة
**تعديلات المصدر:**
- `device/samsung/universal7420-common/device-common.mk`: **حذف** سطر `audio.primary.universal7420_32 \` (نسخة احتياطية `.bak_audio`). ⚠️ تعليقه بـ `#` داخل قائمة `\` يكسر الـ Makefile: `device-common.mk:40: error: commands commence before first target` ← `breakfast` يفشل بـ "Don't have a product spec" (مضلّل).
- `device/samsung/noblelte/device.mk`: `PRODUCT_COPY_FILES` لـ `lib64/egl/libGLES_mali.so` و`lib64/libMcClient.so` فقط. السبب: `vendor/samsung/*/Android.bp` يعرّفهما كـ `cc_prebuilt_library_shared` (مع `check_elf_files: false`) لكنهما **غير مضافين لـ PRODUCT_PACKAGES**. لم يُستخدم الـ module لأن نسخة `vendor/lib/` لكليهما **64-بت** (BuildID مطابق) — كان سيثبّت ملف 64-بت في lib/.
- ⚠️ `echo >>` المتكرر ولّد أسطرًا مكررة في device.mk — نُظّف بسكربت python وأُعيدت الكتابة مرة واحدة.

**فشل `m bacon` مرتين (31 و20 دقيقة) في `soong bootstrap` بلا رسالة خطأ:**
`journalctl`: `kernel: Out of memory: Killed process ... (soong_build) total-vm:35GB` — قاتل OOM للنواة (ليس systemd-oomd، الذي كان inactive).
**السبب:** RAM 7.6GB، و`/dev/zram0` بحجم 45.7GB وأولوية 100 (فوق `/swapfile` 24GB بأولوية -1 وغير المستخدم إطلاقًا: 0B). zram يضغط داخل الذاكرة نفسها فيستهلك RAM ← thrashing (1h8m system time) ← OOM. تعديل ملف `.mk` أجبر Soong على إعادة تحليل كل `Android.bp` (أثقل مرحلة ذاكرةً).
**الحل:** `sudo swapoff /dev/zram0` أثناء البناء ليُستخدم swap القرص، و`-j2`.

## 28. ✅ ROM كامل مبني من المصدر يقلع (2026-09-24)
- zram: ‏`/etc/systemd/zram-generator.conf` ← `zram-size = 16384`, `zstd`, `swap-priority = 100` (بدل 45.7G). بعد حذف الجهاز عرضيًا: `rmmod zram; modprobe zram; systemctl restart systemd-zram-setup@zram0; systemctl start dev-zram0.swap`.
- `m bacon -j2` نجح (2h00m). التفليش عبر TWRP بدون مسح /data.
- **السلوك:** بوت أنيميشن 1–2 دقيقة ← شاشة سوداء ← إعادة تشغيل ← إقلاع ناجح. تأخير ~1 ثانية في فتح التطبيقات. يعمل: الشاشة، اللمس، USB/adb. لا يعمل: SIM/IMEI، Wi‑Fi، BT، كاميرا، حساسات، صوت (stub).
- جميع التعديلات اليدوية السابقة على الجهاز أصبحت داخل الـ ROM (APEX غير مضغوطة، bpf rename2، fstab، cgroups، Mali lib64، libMcClient lib64، audio threadpool، audio stub).

## 29. 🎯 السبب الجذري لخلل الـ blobs المكررة: **hardlinks** بين lib/ و lib64/
**الاكتشاف:** `find ... -links +1` أظهر أن عشرات الملفات في `proprietary/vendor/lib/X.so` و`lib64/X.so` **نفس الـ inode** (عدد الروابط 2) — ملف واحد فعليًا في مكانين. أي تعديل على أحدهما يغيّر الآخر؛ لذلك كان أحد المجلدين دائمًا بالمعمارية الخاطئة (هذا يفسّر القسم 7-ش أيضًا). على الأرجح نشأت عند نسخ الـ blobs بأداة تنشئ hardlinks.
**المرجع الصحيح:** ROM Fakeman LOS 21 (`lineage-21.0-20260424-UNOFFICIAL-noblelte`)، استُخرج بـ `brotli -d` + `sdat2img.py` إلى `~/blobsrc/los21_system.img` ورُكّب على `/mnt/los21`.
⚠️ `brotli -d` بدون `-f` يفشل بصمت إن وُجد الملف ← `sdat2img` يمزج بيانات قديمة مع transfer list جديد = صورة تالفة. استخدم دائمًا `-f` واسمًا فريدًا ومجلدًا خارج شجرة المصدر.
**الإصلاح:** `~/blobsrc/fixarch2.sh apply` — لكل `.so` في lib/lib64 (للشجرتين) بمعمارية خاطئة أو `links>1`: نسخ احتياطي ← `rm` (فك الرابط) ← `cp` من LOS21 بالمعمارية الصحيحة. 32 ملفًا أُصلحت، منها: RIL (`libril`, `libsec-ril*`, `vendor.samsung.hardware.radio*`)، الحساسات (`lib/hw/sensors.universal7420.so`, `sensorhubs`)، gatekeeper، TEE (`libMcClient`, `libMcRegistry`)، الكاميرا (`libexynoscamera*`, `camera.vendor.exynos5`, `libhwjpeg`)، البصمة، **Mali 32-بت حقيقي**. نسخ احتياطية: `~/blobsrc/backup_1124/` و`backup2_*`.
**gpsd:** نسختنا معدّلة لتحتاج `libsensor-mod.so` (32-بت فقط، بلا بديل). gpsd من Fakeman يحتاج `libsensor.so` + `libutils-v32.so` ← استُبدل gpsd، وأُزيل `libsensor-mod`/`libsec_semRil` من `universal7420-common-vendor.mk`، وأُضيف `libutils-v32` (module في `hardware/lineage/compat`).
**device.mk:** `PRODUCT_PACKAGES += libGLES_mali libMcClient libutils-v32` (بدل PRODUCT_COPY_FILES — الـ modules صارت صحيحة بالنسختين). نسخ `lib/` الـ 64-بت المتبقية لمكتبات RIL غير مُثبّتة أصلًا (لا مرجع لها في mk/bp).

## 30. نتائج اختبارات الجهاز (2026-09-24) — ما ثبت وما لم يثبت
**✅ مُختبر على الجهاز وينتظر النقل للمصدر:**
- **RIL:** طقم Fakeman المتكامل: `vendor/bin/hw/rild` (يعتمد `libril_sem.so` وليس `libril.so`) + `lib64/libril_sem.so` + `lib64/libsecril-client.so` + `lib64/vendor.samsung.hardware.radio@2.2.so` + `lib64/vendor.samsung.hardware.radio.bridge@2.1.so` (أداة `~/blobsrc/deps.sh` لحل الاعتماديات تلقائيًا). النتيجة: `ril-daemon running`, `Samsung RIL v4.0`.
- **macloader:** `/vendor/bin/macloader` مفقود في ROMنا — نسخة Fakeman تعمل (exit 0، تُنشئ `.cid.info`).
- ⚠️ نقل الملفات في TWRP: `mount /system` غير موثوق ("not in fstab") ← استخدم دائمًا `mount -t ext4 /dev/block/platform/15570000.ufs/by-name/SYSTEM /mnt/sys` والمسار `/mnt/sys/system/vendor/...`.

**🔧 مُعدّل في المصدر، غير مُختبر:** `system/libhidl/transport/ServiceManagement.cpp:151` ← `kEnforceVintfManifest = true` (نسخة أصلية `~/blobsrc/ServiceManagement.cpp.orig`).
السبب: `com.android.phone` يُقتل بـ ANR (signal 9) لأن RILJ يطلب `radio@1.6` ثم `@1.5` (غير مُعلنة) وكل طلب ينتظر ~3 ث (`Potential race detected`) على الخيط الرئيسي لأن `PRODUCT_ENFORCE_VINTF_MANIFEST=false` (قسم 14). HAL الراديو نفسه مُعلن وسليم (`lshal`: `DM,FC radio@1.4::IRadio/slot1`). مرشّح أيضًا لتفسير بطء الواجهة.

**📍 GPS:** `gpsd` (Fakeman) يحتاج `SensorManager::createEventQueue(String8,int)` (حُذف بعد Android 12) ← يتطلب تكييف `7420_patches/frameworks_native/0002-Add-back-pre-S-createEventQueue-function.patch` لـ A15.

**❌ Wi-Fi — طريق مسدود مؤقتًا:**
- السبب المباشر: `wifiloader` مفقود (يُطلق "deferred initcalls" لـ bcmdhd المبني في النواة) ← لا `wlan0`، ولا أجهزة PCIe.
- ⚠️ تصحيح: الشريحة **BCM4359** (وليس 4358) — مؤكد من IKCONFIG نواة Fakeman المضمّن (`CONFIG_BCM4359=y`). إعدادات النواتين متطابقة تقريبًا (9 فروق فقط، لا شيء يخص Wi-Fi/PCIe).
- تشغيل `wifiloader` يدويًا ← **تجمد كامل + إعادة تشغيل بـ watchdog** بلا panic مسجّل (على الأرجح تجمد رابط PCIe) ← الفرق في **كود** نواتنا (project289، فيها KernelSU) لا في الإعدادات.
- تجربة نواة Fakeman (`Linux 3.10.108-gadec332bd4c8`) + ramdisk ROMنا ← bootloop (السجل مبتور، السبب غير محسوم؛ المرشح bpfloader لغياب `rename2`).
- الملفان على الجهاز حاليًا باسم `wifiloader.off` / `macloader.off` (لا تُعِد تسميتهما قبل حل التجمد!).
- استخراج ملف إعداد النواة من boot.img: gzip المضمن داخل Image هو IKCONFIG (سكربت python في المحادثة).

## 31. cgroup v2 permissions + camera/fingerprint shims (patchelf)
- cgroups.json: Cgroups2 += Mode 0775, UID system, GID system (was root 0600 → libprocessgroup "Permission denied" loop every ~200ms for uid 1001 → post-boot lag + IMS/phone restarts). Tested on device: failures 0. Backup: cgroups.json.bak_perm.
- TARGET_LD_SHIM_LIBS no longer works on A15 → shims never loaded.
  - libexynoscamera.so (lib+lib64): patchelf --add-needed libexynoscamera_shim.so (METERING_SPOT). Result: 2 camera devices, camera + torch work. Backups: ~/blobsrc/backup3/libexynoscamera*.orig
  - libbauthserver.so (lib+lib64): patchelf --add-needed libbauthtzcommon_shim.so (fingerprint) — being tested.
- Known: video recording freezes ~3s at start and has no sound → expected with stub audio HAL (mic missing); revisit in the audio stage.

## 32. Wi-Fi SOLVED (kernel): skip free_initmem() in do_deferred_initcalls
- Root cause: init/main.c do_deferred_initcalls() calls free_initmem() after the deferred initcalls
  (tcrypt, dhd_wlan_init, dhd_module_init). dhd threads/work still referenced __init memory -> instant silent reboot.
- Debug kernel (DEFER> / DEFER< pr_emerg + mdelay) proved all 3 initcalls complete; crash was after them.
- Fix: comment out free_initmem() there (leaks a few hundred KB, harmless). kernel_init already skips it under CONFIG_DEFERRED_INITCALLS.
- Result: wlan0 + swlan0 + p2p0 registered, real MAC, wpa_supplicant starts. Original: ~/blobsrc/main.c.orig
- Debug images: ~/blobsrc/boot_debug.img, boot_debug2.img. Clean image to follow (boot_wifi.img).
- Kernel-only fix => carries over to an A16 port unchanged.

## 33. Wi-Fi DHCP (IP configuration hang) + BT/IMS/NFC status — IN PROGRESS
- Symptom: networks visible, association OK, stuck at "Obtaining IP address" then fails.
- Cause (per project289 patch list): A13+ NetworkStack relies on kernel netlink events a 3.10 kernel does not send.
- Fix source: ~/Downloads/7420_patches-lineage-20.0/packages_modules_NetworkStack/0001-Revert-Enable-parsing-netlink-events-from-kernel-sin.patch
  - git am FAILED on A15 at src/android/net/ip/IpClientLinkObserver.java:21 -> needs manual port (git am in progress in packages/modules/NetworkStack: must --abort or resolve).
  - Deploy target on device: /system/priv-app/NetworkStack/NetworkStack.apk (module-only build: m NetworkStack, push; no full build).
- Also in same patch set (to port later): frameworks_native/0002-Add-back-pre-S-createEventQueue-function.patch (GPS gpsd).
- Runtime (device only, not source): pm disable-user com.android.nfc (NFC HAL missing -> 1/s restart spam). com.android.ims.rcsservice name not found as package (crash loop: RECEIVER_EXPORTED SecurityException) -> find real package name.
- BT: com.android.bluetooth aborts in bt_stack_manage; AIDL IBluetoothHci not in VINTF, HIDL vendor.bluetooth-1-0 running; /dev/ttySAC4 bluetooth:bluetooth. Abort message pending.
- WebView: soft reboot; crash not in crash buffer yet -> capture with logcat -b all.
- Pending list (priority): 1 Wi-Fi DHCP + BT, 2 mic, 3 fingerprint HAL (not installed), 4 RIL (radio 1.5/1.6/AIDL not in VINTF). Then WebView.
- Rule: prefer device/vendor/kernel-level fixes; framework/module patches marked as legacy patches to re-apply on the A16 port.
- CORRECTION to §30: the Wi-Fi "PCIe link freeze" hypothesis was wrong; the real cause is free_initmem() (§32). wifiloader is not needed: deferred initcalls get triggered automatically ~26s after boot. Keep wifiloader.off/macloader.off as-is.

## 34. Root causes found for Wi-Fi IP + BT (from logs)
- Wi-Fi: DHCP WORKS (ACK 192.168.0.123, address set on wlan0). IpClient rejects every RTM_NEWADDR: "unparsable netlink msg".
  Decoded msg attrs: IFA_ADDRESS(1) IFA_LOCAL(2) IFA_BROADCAST(4) IFA_LABEL(3) IFA_CACHEINFO(6) — NO IFA_FLAGS(8).
  IFA_FLAGS was added in Linux 3.14; A15 net-utils parser requires it -> IpClient never sees the address -> provisioning timeout -> disconnect.
  Fix (kernel, carries to A16): backport IFA_FLAGS to uapi if_addr.h + net/ipv4/devinet.c + net/ipv6/addrconf.c (put + msgsize). project289's NetworkStack revert is obsolete on A15 (flag removed).
- BT: stack aborts "Unable to get a Bluetooth service after 500ms". bluetooth@1.0 IS declared + registered (lshal). The @1.1 lookup (undeclared) blocks >500ms because kEnforceVintfManifest=false -> same libhidl issue as phone ANR (§30). Fix = libhidlbase with kEnforceVintfManifest=true (already in source) -> test by pushing libhidlbase.so (lib+lib64).

## 35. SIM detected + hwservicemanager spam removed (device tests)
- libhidlbase with kEnforceVintfManifest=true pushed (lib+lib64; originals ~/blobsrc/hidl_orig/). Result: SIM detected.
  Why: com.android.phone (RILJ) probes radio@1.6, @1.5 (undeclared) before falling back to the declared radio@1.4::IRadio/slot1.
  With enforce=false each undeclared probe waits ~3s ("Potential race") on the phone main thread -> ANR -> phone killed -> SIM never initialised.
  With enforce=true undeclared lookups return immediately -> RILJ binds radio@1.4 -> SIM OK.
  If SIM breaks again: check `grep -n kEnforceVintfManifest system/libhidl/transport/ServiceManagement.cpp` and that /system/lib*/libhidlbase.so is the patched one (md5 vs out/).
- Fingerprint: vendor manifest declared fingerprint@2.1 but no service installed -> system_server polled it several times per ms -> hwservicemanager flooded, logd pruning.
  Device fix: removed fingerprint <hal> from /vendor/etc/vintf/manifest.xml (orig ~/blobsrc/vendor_manifest.orig.xml) + renamed /vendor/etc/permissions/android.hardware.fingerprint.xml -> .off. Spam: 0. Re-add both when the fingerprint HAL is added.
- ims: real package com.android.service.ims (RcsService) crash-loops (RECEIVER_EXPORTED) -> disable.
- BT: HAL answers in 0.1s (lshal debug), yet the BT app's V1_0 getService still exceeds 500ms -> problem is on the client side; still open.
- Wi-Fi: deferred initcalls are NOT triggered automatically (earlier run at ~26s was manual). wlan0 missing after reboot until /proc/deferred_initcalls is read -> re-enable wifiloader (safe now with the free_initmem kernel fix).

## 36. Source audit (~/audit_src.sh) + pending source ports applied
- Applied to source: fingerprint <hal> removed from universal7420-common/manifest.xml; android.hardware.fingerprint.xml copy removed from device-common.mk (backups ~/blobsrc/*.bak_fp). Re-add both with the fingerprint HAL.
- Kernel IFA_FLAGS backport complete: uapi if_addr.h, ipv4 devinet.c (fill + msgsize), ipv6 addrconf.c inet6_fill_ifaddr (|| chain) + inet6_ifaddr_msgsize. Originals ~/blobsrc/{if_addr.h,devinet.c,addrconf.c}.orig
- Audit: all [OK] except "wifiloader in vendor blobs" (not a blob; only sepolicy wifiloader.te/macloader.te found) -> locate its source/package.
- Run ~/audit_src.sh before every full build.

## 37. ✅ Wi-Fi WORKS (connect + internet) + hotspot works
- boot image ~/blobsrc/boot_wifi.img = free_initmem skip + IFA_FLAGS backport (ipv4+ipv6). wifiloader re-enabled on device (/vendor/bin/wifiloader; macloader still .off).
- Next order (user): WebView (needed for GApps) -> BT -> fingerprint -> audio (last, careful).
- Note: fingerprint is hidden in Settings on purpose (feature xml + manifest entry removed in §35/36 to stop the spam) until the HAL is added.
- User preference: no `tail` in commands (wants live output).

## 38. ✅ WebView soft reboot SOLVED = cgroup v2 permissions (same root cause as §31)
- dropbox system_server_crash: "AssertionError: Unable to create process group for com.android.webview:sandboxed_process0 ..." (ProcessList.startProcess).
- WebView spawns an isolated (sandboxed) process with a NEW uid; system_server (uid 1000) must create /sys/fs/cgroup/uid_<new>/pid_<n>; /sys/fs/cgroup was root:root 0600 -> fails -> system_server crash -> soft reboot.
- The lowmem report in dropbox was written AFTER the crash (during restart), not the cause (MemAvailable ~2GB).
- Runtime test: chown system:system + chmod 0775 /sys/fs/cgroup (+ uid_*) -> WebView works.
- Permanent: cgroups.json Cgroups2 Mode 0775 / UID system / GID system — already in source (§31, audit OK), active after the next full build. Until then run the chmod after every reboot.
- Thermal HAL (thermal@2.0-service.exynos) fails to register since libhidl enforce=true (not declared). Added <hal> thermal@2.0 IThermal/default to device /vendor/etc/vintf/manifest.xml; hwservicemanager reads VINTF at boot -> needs reboot to verify. Must also be added to source manifest.xml.

## 39. REVERTED: thermal entry in device manifest -> stuck on bootanimation
- Declaring thermal@2.0 while the service still can't register makes system_server block waiting for a declared-but-absent HAL -> bootanimation hang.
- Likely real reason registration fails: IThermal@2.0 registerAsService also registers the parent @1.0 interface, which is NOT declared -> must declare BOTH @1.0 and @2.0 (test later, carefully).
- Revert: push ~/blobsrc/vendor_manifest.nofp.xml back to /vendor/etc/vintf/manifest.xml.

## TODO — minor services (fix later, low priority)
- [ ] thermal HAL: declare @1.0 + @2.0 IThermal/default (device test first; revert path above)
- [ ] widevine DRM: libwvhidl needs protobuf symbol _ZN6google8protobuf8internal13empty_string_E (shim / older libprotobuf-cpp-lite)
- [ ] armnn NN HAL: missing __cxa_demangle (shim or drop the service)
- [ ] gpsd: port frameworks_native createEventQueue(String8,int) patch to A15
- [ ] NFC: AIDL/HIDL NFC HAL missing; com.android.nfc disabled at runtime -> either add HAL or remove NFC packages/features from source
- [ ] IMS: com.android.service.ims (RcsService) crash-loop (RECEIVER_EXPORTED) -> remove package from build
- [ ] fingerprint HAL: add service + rc, then re-add manifest <hal> + android.hardware.fingerprint.xml
- [ ] macloader: still .off (Wi-Fi fine without it); check if needed for correct NVRAM/cid
- [ ] wifiloader: make sure it is built/installed from source (only sepolicy found) — needed for wlan0 after every boot
- [ ] BT: HAL answers in 0.1s but BT app getService(1.0) > 500ms
- [ ] audio (last, careful): stub HAL; mic missing (video 3s freeze, no sound)
- [ ] CPU monitor wtf (cpufreq stats), dropbox service missing, memtrack/power.stats not declared (cosmetic)

## 40. ✅ Bluetooth ON + scanning works (pairing still failing)
Three stacked causes:
1. libhidl in the BT APEX is STATIC: /apex/com.android.btservices/lib64/libbluetooth_jni.so contained the old "Potential race" code (enforce=false) -> @1.1 lookup ~1s > 500ms watchdog -> abort.
   Fix: rebuild `m com.android.btservices` after the libhidl change, push /system/apex/com.android.btservices.apex (orig ~/blobsrc/btapex/com.android.btservices.apex.orig). Full build will include it automatically.
   NOTE for A16: any APEX that statically links libhidl must be rebuilt with the patched libhidl.
2. libbt opened default UART /dev/ttyO1 (TI OMAP default; BOARD_BLUEDROID_VENDOR_CONF not set) -> open failed -> HAL abort.
   Device fix: append `UartPort = /dev/ttySAC4` to /system/etc/bluetooth/bt_vendor.conf (orig ~/blobsrc/bt_vendor.conf.orig).
   TODO source: add UartPort line to the bt_vendor.conf in the source tree (or set BLUETOOTH_UART_DEVICE_PORT via vnd conf).
3. Result: fd open, baud 3000000, chipset BCM4349B1, FW /vendor/firmware/bcm4359B1_V0105.0106.hcd loaded, BD addr from /efs set, fwcfg completed, adapter ON, device list visible.
- Open: pairing with a BT headset fails (under investigation). a2dp audio module missing (audio.a2dp) — expected until audio stage.
- BT profiles: A13+ disables every profile unless bluetooth.profile.*.enabled=true. Added 12 props (a2dp.source, avrcp.target, hfp.ag, hid.host/device, opp, pan.nap/panu, pbap/map server, gatt, bas.client) to device/samsung/noblelte/device.mk (PRODUCT_VENDOR_PROPERTIES; backup ~/blobsrc/device.mk.bak_btprof).
  Result: A2dpService + HeadsetService start; headset pairs + connects and is shown as audio device, but NO sound (audio stage).
- Source: UartPort = /dev/ttySAC4 -> device/samsung/noblelte/bluetooth/bt_vendor.conf.

## 41. ✅ FINGERPRINT WORKS (enroll + unlock)
Stack: AIDL android.hardware.biometrics.fingerprint-service.samsung (hardware/samsung/aidl/fingerprint) -> dlopen libbauthserver.so (Samsung legacy, +libbauthtzcommon_shim) -> MobiCore trustlet -> Synaptics sensor on /dev/vfsspi.
Fixes, in order:
1. Missing libs on device: fingerprint-V4-ndk, common-V4-ndk, common.util, keymaster-V4-ndk (built with the service) + libbauthtzcommon.so (vendor blob existed in source but was never installed).
2. libbauthserver lib64 had the shim NEEDED twice (patchelf run twice) -> cleaned to one.
3. Declared via the service's own vintf fragment (AIDL IFingerprint/default) + android.hardware.fingerprint.xml feature restored.
4. overlay config_biometric_sensors had "0:2:15" -> created an extra HIDL fingerprint@2.1 sensor that hung BiometricScheduler (FingerprintUpdateActiveUserClient never finished) -> emptied the array (AIDL sensor is auto-discovered from VINTF). Built/pushed the vendor framework-res RRO.
5. Samsung HAL reports enroll progress as a percentage -> ro.vendor.fingerprint.uses_percentage_samples=true (Session.cpp converts 100-x).
6. DO NOT set cancel_on_enroll_completion: it sends onError(5)=CANCELED before rem=0 -> "Something went wrong".
7. /data/biometrics/{meta,type} were root-owned (created when the HAL was run manually as root) -> chown -R system:system /data/biometrics.
Props (device.mk): ro.vendor.fingerprint.uses_percentage_samples=true, type=home, max_enrollments=4.

## 42. Audio groundwork + NikGApps bootloop
- Kernel: CONFIG_SND_DUMMY disabled (was =y; Fakeman: not set). The Dummy card took card0 and pushed the WM1840 codec to card1 -> the audio HAL/mixer_paths (hardcoded card 0) found none of the controls ("Control 'IN1L Mux' doesn't exist") and SIGSEGV'd (null deref) -> audioserver restart loop. Very likely also the cause of the old audio-related boot hang.
  Result (boot_audio.img = wifi fixes + SND_DUMMY off): card0 = "Noble WM1840 Sound", wlan0 OK. Backup defconfig ~/blobsrc/noblelte_defconfig.bak_snddummy
- Audio HAL = Fakeman 32-bit /vendor/lib/hw/audio.primary.universal7420.so (name matches ro.product.board=universal7420; our audio HAL service is 32-bit). Needs vendor/lib: libtinycompress.so, libsecril-client.so (32-bit), libaudioroute.so (vendor copy). Currently REMOVED from device; re-test with codec at card0.
- NikGApps: bootloop = FATAL in system_server: "Signature|privileged permissions not in privileged permission allowlist" for PrebuiltDeskClockGoogle (CONTROL_DISPLAY_COLOR_TRANSFORMS, START_FOREGROUND_SERVICES_FROM_BACKGROUND). Fixed from TWRP by deleting /system/product/priv-app/PrebuiltDeskClockGoogle_76006071 + /system/addon.d/09-05-GoogleClock.sh. build.prop has ro.control_privapp_permissions=enforce.
  TODO source: consider ro.control_privapp_permissions=log for GApps tolerance.

## 43. Source sync (no full build yet — user decision: finish audio first)
- wifiloader binary was NOT in source/out (only init.wifi.rc in vendor/samsung/noblelte) -> pulled from device to vendor/samsung/noblelte/proprietary/vendor/bin/wifiloader + PRODUCT_COPY_FILES in noblelte vendor mk (backup ~/blobsrc/*-vendor.mk.bak_wifiloader). macloader intentionally not added.
- audit_src.sh updated: wifiloader path; fingerprint.xml now REQUIRED; manifest check = no HIDL fingerprint <hal>.
- A full build was started by mistake and interrupted; old zip (20260923) was NOT flashed (sideload failed, no device).
- Pending audio: Fakeman HAL loads, mixer controls now resolve (codec card0), but still SIGSEGV null deref in HwBinder thread of the audio HAL service -> need backtrace.

## 44. cgroups permanent on device + audio 7.1 attempt (reverted)
- Pushed source cgroups.json -> /system/vendor/etc/cgroups.json (orig ~/blobsrc/cgroups.device.orig.json). After reboot /sys/fs/cgroup = drwxrwxr-x system system automatically -> no more manual chmod; fixes WebView/game soft reboots until the full build.
- RIL: phone IN_SERVICE on Asiacell LTE (voice+data registration OK).
- Audio attempt 2: Fakeman audio@7.1-impl + 4 libs (audio@7.1, audio@7.1-util, audio.common@7.1-enums, audio.common@7.1-util) + manifest IDevicesFactory 7.0->7.1 + audio.primary.universal7420.so.
  Result: 7.1 registered, HAL loaded, voice_session_init OK, AudioFlinger "Loaded primary audio interface", then SIGSEGV fault addr 0x0 right after (first openOutput) -> audio HAL service restart loop -> stuck bootanimation.
  Reverted via adb: manifest back to 7.0 (~/blobsrc/vendor_manifest.pre_audio71.xml), removed 7.1-impl + primary HAL (the 4 7.1 libs remain, harmless).
- Blocker: no backtraces anywhere — /data/tombstones always empty, crash_dump "waitpid failed". Next: fix tombstoned/crash_dump to get real backtraces.

## 45. ✅ SPEAKER AUDIO WORKS — NULL deref in out_get_presentation_position (2026-09-25)
- Real HAL source = `device/samsung/universal7420-common/hardware/audio/` (module `audio.primary.universal7420`, LOCAL_MODULE uses TARGET_BOOTLOADER_BOARD_NAME). NOT hardware/samsung/audio.
- `hardware/samsung/audio` (extracted from lineage-21) is UNUSED -> delete before full build (+ its Android.mk sed edit).
- Crash: kernel exception-trace pc=0x9110 lr=0x90bc -> llvm-addr2line on symbols/ -> audio_hw.c:3081 `list_for_each(&out->pcm_dev_list)`: list never list_init'ed (next==NULL) so list_empty() false -> deref 0x0.
- Fix (audio_hw.c ~3076): `if (out->pcm_dev_list.next != NULL && !list_empty(&out->pcm_dev_list))`. Backup ~/blobsrc/audio_hw.c.orig.
- Test: `m audio.primary.universal7420 -j2` (no re-analysis for .c edits) -> push system/vendor/lib/hw/ -> `stop/start vendor.audio-hal`.
- Debug recipe for native crashes (no tombstones): exception-trace=1 + maps loop + addr2line on out/.../symbols.
- NEXT: microphone.

## 46. ✅ MICROPHONE / RECORDING WORKS — Codec2 was disabled (2026-09-25)
- Symptom: Recorder crashes instantly; `StagefrightRecorder: Failed to create audio encoder`. AudioRecord itself opened fine (HAL input path OK).
- `dumpsys media.player` listed only OMX.Exynos video codecs, zero `c2.android.*` -> no AAC/AMR/Opus codecs at all.
- Root cause: `device/samsung/universal7420-common/system.prop:28: debug.stagefright.ccodec=0` (legacy A9/A10 setting; A15 has no OMX software codecs).
- Device test: `setprop debug.stagefright.ccodec 4; killall mediaserver` -> c2.android.aac/amrnb/opus encoders appear, recording works.
- Source fix: `debug.stagefright.ccodec=4` in system.prop (omx_default_rank lines kept: Exynos HW video via OMX stays preferred).
- Device tree fix (not framework) -> valid for A16.
- Remaining after audio: thermal HAL, headphone jack (untested), BT headset connect regression.

## 47. ✅ BLUETOOTH AUDIO (A2DP) WORKS (2026-09-25)
- Symptom: headset ACL+encryption OK then remote disconnect after ~6s; `CachedBluetoothDevice: No profiles`; `Rcvd conn req for unknown PSM`. dumpsys: Enabled Profile Services = GATT + HEARING_AID only.
- Cause: the 12 `bluetooth.profile.*.enabled` props had only been set with setprop (lost on reboot); source device.mk has them but no build yet.
- Device fix: appended all 12 props to /system/build.prop (backup /data/local/tmp/build.prop.bak) + reboot.
  NOTE: a first grep `[a-z_.]*` skipped `a2dp` (digit) -> headset showed battery only, audio stayed on speaker; added `bluetooth.profile.a2dp.source.enabled=true` separately.
- Source: device/samsung/noblelte/device.mk already had a2dp (line 80); an accidental duplicate line from sed was removed.
- Result: A2DP/AVRCP/HEADSET/... enabled, headset audio works.
- Remaining: thermal HAL, headphone jack (untested).

## 48. ✅ THERMAL HAL WORKS — declare BOTH @1.0 and @2.0 (2026-09-25)
- `android.hardware.thermal@2.0-service.exynos` (rc registers `thermal@1.0::IThermal` + `@2.0::IThermal`) exited status 1 in a loop:
  `HidlServiceManagement: ... must be in VINTF manifest in order to register/get` (side effect of kEnforceVintfManifest=true, §35).
- Earlier attempt (§39) declared only one version -> service still failed -> bootanimation hang. Declaring BOTH fixes it.
- Device test: fragment /system/vendor/etc/vintf/manifest/thermal.xml (hidl, hwbinder, 1.0 + 2.0 IThermal/default) + reboot
  -> boots, lshal shows both DM, init.svc.vendor.thermal-hal-2-0=running.
- Source: same two <hal> entries appended to device/samsung/universal7420-common/manifest.xml (no .mk change -> no soong re-analysis).
- New TODO seen: gnss@1.0 IGnss/default TIMED_OUT in lshal (gpsd link failure, already in TODO).
- Remaining: headphone jack test; then audit_src.sh + full build.

## 49. ✅ THERMAL HAL returns real temperatures (2026-09-25)
- After §48 the HAL registered but every call failed ("Couldn't get temperatures because of HAL error").
- Cause: hardware/samsung_slsi-linaro/exynos/thermal/thermal_exynos.cpp initExynosThermalHal() only accepts zone types
  BIG/MID/LITTLE/G3D/NPU (newer Exynos). Note5 kernel zones: exynos-therm, max77833-fuelgauge, ac, battery -> all skipped.
- Fix (source, backup ~/blobsrc/thermal_exynos.cpp.orig): accept "exynos-therm" as CPU, "battery" as BATTERY.
- Built with `m android.hardware.thermal@2.0-service.exynos` (no re-analysis), pushed, restarted HAL then system_server.
- Result: dumpsys thermalservice -> exynos-therm CPU temperature + static thresholds; HAL Ready.
- Known cosmetic TODO: thresholds reported in milli-degC (80000) vs temps in degC (HAL bug, framework-side throttling
  effectively never triggers; kernel TMU still throttles). Cooling devices list empty. Low priority.
- §49 addendum: Thermal.cpp filterType logic was inverted (false returned only one type, true returned FAILURE).
  Patched getCurrentTemperatures/getTemperatureThresholds: false = gather CPU/GPU/BATTERY/SKIN/NPU, true = requested type.
  Backup ~/blobsrc/Thermal.cpp.orig. Kernel readings at idle: exynos-therm 49C, battery 36C, ac 41C (normal; 71-75C seen only
  under system_server restarts). Battery line in dumpsys not yet confirmed (dumpsys ran mid-restart) - low priority.

## 50. Pre-build audit clean (2026-09-25)
- hardware/samsung/audio (unused lineage-21 extract) deleted.
- ~/audit_src.sh extended: thermal manifest/zones/filterType, audio NULL fix, ccodec=4, bt a2dp prop, SND_DUMMY off, bt UartPort, fp percentage prop.
- All checks OK -> next: `m bacon -j4`, flash via TWRP adb sideload, NO wipe (addon.d keeps GApps).
- Still untested: wired headphone jack.
- TODO carried: battery temp not listed in thermalservice dump; thresholds milli-degC; gnss/gpsd; widevine; armnn; NFC; IMS pkg; macloader; crash_dump/tombstoned.

## 51. GPS: gpsd now starts (shim for createEventQueue) (2026-09-25)
- gpsd (64-bit N-era blob) failed: CANNOT LINK `_ZN7android13SensorManager16createEventQueueENS_7String8Ei`.
  libsensor-mod.so in lib64 is actually 32-bit (hardlink dupe, §29) -> unusable.
- New shim: device/samsung/universal7420-common/shims/gpsd/{sensor_shim.cpp,Android.bp} -> libsensor_shim_gpsd (vendor, 64-bit).
  Exports old symbol via `__asm__` label, forwards to createEventQueue(String8,int,String16("")).
  (extern "C" variant fails: -Werror,-Wreturn-type-c-linkage.)
- Blob: `patchelf --add-needed libsensor_shim_gpsd.so` on vendor/.../bin/hw/gpsd.
- Device test: gpsd runs, "Broadcom,BCM4773" chip detected, libgps OnIpcConnectionEstablished, gnss@1.0 registered.
- Source: PRODUCT_PACKAGES += libsensor_shim_gpsd; patched gpsd blob in vendor tree. Fix-test outdoors pending.
- TODO (kernel): mp-cpufreq cluster1_min_freq reads garbage 172386052 and rejects writes -> A57 cluster pinned at 2.1GHz (warm, battery drain).

## 52. ✅ GPS WORKS outdoors (23+ sats in use, Google Maps fix) (2026-09-25)
- Chain: gpsd <-> lhd (PortName="lhd") <-> /dev/bbd_* (BCM4773 = sensor hub + 47531 GNSS core). Hardware path OK after §51 shim.
- gps.xml (/vendor/etc/gnss/gps.xml) changes that made it lock:
  IgnoreJniTime true->false (use Android NTP time), SuplSslMethod SSLv23_NO_TLSv1_2 -> SSLv23 (allow TLS1.2 SUPL),
  EnableLowPowerPmm true->false. RfType GL_RF_47531_BRCM_EXT_LNA is CORRECT (no 4773 RF type exists in gpsd).
- Before: 2-3 in view, 0 in use. After: 23+ in use outdoors. Indoors 0 = normal GNSS physics; indoor location comes from
  network location (Google Location Accuracy / Wi-Fi), not GNSS.
- Stale NV data cleared once: rm /data/system/gps/gldata.sto (runtime only).
- Source: same 3 edits applied to gps.xml in vendor/device tree.
- §52 addendum: indoor NETWORK location FAILS on Note5 (grey dot) while a reference phone (Huawei Nova 3i) in the same room
  resolves which side of the house the user is in. => port-side issue, OPEN.
  Known OK: network provider enabled/allowed, GMS NetworkLocationService bound, Wi-Fi scan results present, wifi_scan_always=1,
  magnetometer OK (compass calibration prompt). last location=null from network provider.
  Suspects: no cell info from Samsung RIL (getAllCellInfo), GMS Location Accuracy consent, or GMS NLP rejecting requests.
- §52 GPS indoor sensitivity (OPEN, TODO): Note5 0 sats in view indoors vs Huawei Nova 3i 23 in view at same spot;
  outdoors Note5 = 23+ in use (fine). RfType A/B (EXT_LNA vs plain) no change -> reverted to GL_RF_47531_BRCM_EXT_LNA.
  /sys/class/sec/gps exposes only GPS_PWR_EN (gpio148); no LNA control node. No lhd config file in /vendor/etc.
  Leads for later: stock N920C gps.xml/lhd.conf from Samsung firmware; kernel bbd/LNA gpio in DT.
- Network location: GMS logs `NlpInternalApi: failed to send request to NLP - not found` -> GApps (NikGApps) side,
  try updating Play Services. RIL: mCellInfo=[] (no cell info) -> TODO.

## 53. First full build (lineage-22.2-20260925-UNOFFICIAL-noblelte.zip) — regressions found (2026-09-25)
- Build OK (1h49m). Flashed via TWRP sideload, no wipe.
- REGRESSION 1 (critical): rild + gpsd fail: `library "libril_sem.so" not found` (needed by rild and libsec-ril.so).
  File exists in vendor/samsung/universal7420-common/proprietary/vendor/lib64/ but was NOT installed (not in PRODUCT_COPY_FILES).
  audit_src.sh only checked presence in tree, not install. Device fix: pushed to /system/vendor/lib64 + reboot.
  Source fix: add to PRODUCT_COPY_FILES; audit must check out/ install too.
- REGRESSION 2: GApps gone from /system (addon.d empty — 09-05 script deleted earlier with Google Clock / backup not run).
  GMS/Vending survive only as /data updates without priv perms -> SecurityException INTERACT_ACROSS_USERS / MANAGE_USERS,
  Play Store crash. Fix: re-flash NikGApps in TWRP (dirty, no wipe); never delete /system/addon.d scripts.
- Lesson: after each full build, diff proprietary tree vs out/ installed files to catch un-copied blobs.

## 54. Un-installed blobs fixed + post-build tooling (2026-09-25)
- Diff proprietary tree vs out/: 35 blobs never installed (lost from *-vendor.mk, likely by dedupe_vendor_mk.py §29):
  camera (libexynoscamera 32/64, libexynoscamera3, libhwjpeg 32/64, camera.vendor.exynos5), RIL (libril_sem 64, libsec_semRil 32),
  gps (libwrappergps 32, libsensorlistener/libsensor-mod 32), fp test libs, gatekeeper, sensors/sensorhubs HAL 32, libMcRegistry,
  bcmdhd_clm.blob.
- ~/fix_missing_blobs.sh: arch-checked (lib=ELF32, lib64=ELF64) append to PRODUCT_COPY_FILES of the matching *-vendor.mk + adb push.
  22 added. 13 skipped = ARCH MISMATCH leftovers (64-bit files sitting in lib/, 32-bit in lib64/) -> moved out of tree, not shipped.
- Device result after push+reboot: camera, microphone, headphone jack, Wi-Fi, flashlight all working.
- ~/smoke_test.sh: post-flash PASS/FAIL checklist (boot, missing libs, SIM, rild, wifi, BT A2DP, audio HAL, AAC encoder, camera,
  fingerprint, thermal, gpsd, gnss, GMS privileged, no restarting services). Release rule: 0 FAIL before XDA.
- Headphone jack: ✅ confirmed working.

## 55. Root cause of lost blobs + "nuclear" consolidation script (2026-09-25)
- WHY my §54 PRODUCT_COPY_FILES broke soong (49-min analysis then "packaging conflict"): in A15 the fsgen filesystem
  creator turns PRODUCT_COPY_FILES into arm64 prebuilt modules grouped by source dir; a .so copied to vendor/lib/ is
  installed to vendor/lib64/ -> collides with the real lib64 copy. => 32-bit blobs can NOT be shipped via PRODUCT_COPY_FILES.
  This is also why every 32-bit lib/ blob silently disappeared from the first full build (camera, sensors HAL, gatekeeper...).
- Reverted all §54 mk lines (backups ~/blobsrc/*-vendor.mk.bak_fixblobs). Removed bcmdhd_clm.blob (broke Wi-Fi; never shipped before).
- RIL kit (§30, the setup that worked): rild + libril_sem + libsecril-client + radio@2.2 + radio.bridge@2.1 from the Fakeman
  LOS21 reference (~/blobsrc/los21_system.img). radio@2.2/bridge@2.1 were only pushed to the device, never added to source.
- Device-only: ro.control_privapp_permissions=log set in TWRP (NikGApps bootanimation hang fixed, same cause as §42).
- ~/nuke_fix.sh (check | apply):
  [1] recursive 64-bit NEEDED closure of rild/libril_sem/libsec-ril(-dsds)/gpsd vs installed set; missing libs taken from
      LOS21 ref (or out/system_ext) -> tree lib64 + PRODUCT_COPY_FILES (lib64 is safe).
  [2] every ELF32 blob in proprietary/vendor/lib not installed in out/ -> generated cc_prebuilt_library_shared
      (compile_multilib "32", stem, relative_install_path hw) in <tree>/proprietary/vendor/Android.bp + PRODUCT_PACKAGES.
  [3] shim NEEDED exactly once on 32-bit libexynoscamera / libbauthserver (§31).
  [4] ro.control_privapp_permissions=log in universal7420-common/system.prop.
  [5] audit_src.sh (all §31-§52 fixes).
  Rule: build only when `check` prints MISSING=0. After flash: ~/smoke_test.sh, then reflash NikGApps (addon.d).

## 56. ✅ nuke_fix verified on device before building (2026-09-25)
- `nuke_fix.sh check` -> MISSING=0 after 2 apply passes (shim dup on 32-bit libbauthserver removed).
- Pushed exactly the tree files (RIL kit lib64 + all 32-bit blobs of the generated Android.bp) -> reboot.
- Result: RIL/SIM, camera, torch work again. smoke_test: all PASS except known TODO:
  widevine (protobuf symbol), armnn (__cxa_demangle) crash-loop "no missing libs"/"restarting"; GMS privileged (reflash NikGApps).
- smoke_test: SIM check accepts READY|LOADED; widevine/armnn reported as KNOWN (not counted) until fixed.
- Next: full build with the generated Android.bp modules (first real test of the soong side).

## 57. App hangs (ANR) = declared-but-dead HALs; widevine removed from manifest (2026-09-25)
- Turrit (org.telegram.group) ANR: main thread blocked in DrmUtils::MakeHidlFactories -> getService(drm@1.1 IDrmFactory/widevine).
  widevine is DECLARED in manifest but never registers (libwvhidl missing protobuf symbol) -> every app touching DRM waits -> ANR.
- NFC ANR (com.android.nfc): NfcAdaptation waits forever for the NFC AIDL HAL — HAL service not built
  (device-common.mk:250 commented). NFC CANNOT work in this build. User decision: leave NFC in source untouched,
  mark "untested / HAL missing"; runtime `pm disable-user com.android.nfc` only.
- Device test: removed the 2 widevine fqnames (@1.1 ICryptoFactory/IDrmFactory widevine) from /vendor/etc/vintf/manifest.xml
  + moved widevine rc out -> Turrit works, smoke_test all PASS (except GMS privileged -> reflash NikGApps).
  Backups on device: /data/local/tmp/manifest.pre_widevine.xml, /data/local/tmp/android.hardware.drm@1.1-service.widevine.rc
- Source: same 2 lines removed from the source manifest + widevine service not installed (pending exact lines).
- RULE (prevents all hangs of this class: thermal §39, NFC, widevine): only declare a HAL in VINTF if it actually registers.
  smoke_test now FAILs on any DM-declared HAL not registered in lshal.
- Real widevine fix (shim for _ZN6google8protobuf8internal13empty_string_E) stays in TODO; Netflix-like HD DRM unavailable until then.

## 58. Pre-build review (everything changed in SOURCE since the 09-25 full build)
1. §55/56 nuke_fix apply:
   - universal7420-common-vendor.mk: PRODUCT_COPY_FILES (lib64) libril_sem, android.hardware.radio.config@1.1/@1.2,
     vendor.samsung.hardware.radio.bridge@2.1, vendor.samsung.hardware.radio@2.2 (from Fakeman LOS21 ref, copied into tree lib64).
   - Generated 32-bit modules: vendor/samsung/universal7420-common/proprietary/vendor/Android.bp (15 nl32_*) and
     vendor/samsung/noblelte/proprietary/vendor/Android.bp (3 nl32_*) + one PRODUCT_PACKAGES line in each *-vendor.mk.
     FIRST soong test of these files happens in this build.
   - lib/libbauthserver.so: shim NEEDED de-duplicated to exactly one.
   - device/samsung/universal7420-common/system.prop: ro.control_privapp_permissions=log.
2. §57 widevine: 2 fqnames removed from device/samsung/universal7420-common/manifest.xml; widevine service binary + rc removed
   from universal7420-common-vendor.mk (backups ~/blobsrc/*.bak_widevine).
3. Reverted: all §54 single-line PRODUCT_COPY_FILES (backups *.bak_fixblobs), bcmdhd_clm.blob line.
4. NOT changed (by decision): NFC (untested, HAL missing), armnn (crash-loops, undeclared, TODO).
- Verified on device BEFORE build (§56/57): RIL/SIM, camera, torch, Turrit, smoke_test all PASS except GMS (reflash NikGApps).
- Gates: nuke_fix check MISSING=0 ✔; audit_src OK ✔. Post-flash gate: smoke_test 0 FAIL (except GMS until NikGApps).
- Build command: nice/ionice + -j4 + live log via tee + alarm on finish (success or failure).
- App test log (device, pre-build 09-25): Turrit ✔ (after widevine undeclare), Subway Surfers ✔ (GPU/Mali + audio + touch under game load).

## 59. Reproducible bundle: manifest + patches + build guide (2026-09-25)
- make_patchset.sh: for EVERY repo project, base = manifest revision ($REPO_LREV):
  commits ahead of base -> git format-patch --binary; uncommitted edits/deletions/symlinks/modes/new files/blobs ->
  9999-noblelte-worktree.patch (git add -N + git diff --binary HEAD, undone after). Excludes *.bak*, *.orig, *.rej, lib.bak_32bit_dupes.
  Also copies local manifest + pinned manifest (repo manifest -r) + tools + CHANGES. Reports patches > 50MB (push those as GitHub repos).
- apply_patches.sh: git am (skips already-applied by subject) then git apply --binary (skips if reverse-applies). Stops on first conflict.
- BUILD.md (English, publishable): sync, apply, env (ccache), audit gate, build (nice/ionice -j4, live log, alarm), flash, smoke gate, status, credits.
- Round-trip verified locally (edit, delete, symlink, +x mode, binary blob, .bak exclusion, idempotency).
- GPL: kernel source must be published as a full repo (fork of project289 kernel + our commits) for XDA, not only as a patch.
