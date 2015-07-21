#!/bin/bash
set -e
set -u

rm -f android-release.apk android-release-unaligned.apk
cordova build android --release
cp platforms/android/build/outputs/apk/android-release-unsigned.apk android-release-unaligned.apk
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/fdl-release-key.keystore android-release-unaligned.apk FieldDayLab
zipalign -v 4 android-release-unaligned.apk android-release.apk
rm android-release-unaligned.apk
