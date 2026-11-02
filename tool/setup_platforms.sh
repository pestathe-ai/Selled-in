#!/usr/bin/env bash
# Genera le cartelle android/ios (non salvate nel repo) e le prepara.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --project-name selled_in --org dev.selledin --platforms=android,ios . >/dev/null
rm -f test/widget_test.dart

# minSdk 24 (richiesto da webview_flutter)
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  sed -i -E 's/minSdk *= *flutter\.minSdkVersion/minSdk = 24/; s/minSdkVersion +flutter\.minSdkVersion/minSdkVersion 24/' "$f"
done

M=android/app/src/main/AndroidManifest.xml
# Permesso Internet per la compilazione automatica (in release non c'è di default)
grep -q 'android.permission.INTERNET' "$M" || \
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
# Nome visibile dell'app
sed -i 's/android:label="selled_in"/android:label="Selled-in"/' "$M"

if [[ "$(uname)" == "Darwin" ]]; then
  P=ios/Runner/Info.plist
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Selled-in" "$P" || true
  /usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryUsageDescription string 'Per aggiungere le foto degli articoli'" "$P" || true
  /usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string 'Per fotografare gli articoli'" "$P" || true
fi

flutter pub get
dart run flutter_launcher_icons
