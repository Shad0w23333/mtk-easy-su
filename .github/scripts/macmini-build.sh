#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
# The original Gradle 6.5 / Android Gradle Plugin 4.1.3 project uses JDK 11.
export JAVA_HOME="${MTK_EASY_SU_CI_JAVA_HOME:-/Users/Shared/macmini-ci/toolchains/jdk11}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/Users/Shared/macmini-ci/toolchains/android-sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

if [[ ! -x "$JAVA_HOME/bin/java" || ! -x "$JAVA_HOME/bin/javac" ]]; then
  echo 'mtk-easy-su CI requires the Gradle 6.5-compatible JDK 11 toolchain.' >&2
  exit 1
fi
for required in licenses/android-sdk-license platforms/android-30/android.jar build-tools/29.0.3/package.xml; do
  if [[ ! -s "$ANDROID_HOME/$required" ]]; then
    echo "Android SDK prerequisite missing: $required. The owner must complete SDK license review and installation." >&2
    exit 1
  fi
done

# Preserve the original build, lint and configured test lifecycle and BuildConfig environment.
bash gradlew --no-daemon build
shopt -s nullglob
apks=(app/build/outputs/apk/debug/*.apk)
if (( ${#apks[@]} == 0 )); then
  echo 'Gradle completed without the declared debug APK product.' >&2
  exit 1
fi
for apk in "${apks[@]}"; do test -s "$apk"; done
