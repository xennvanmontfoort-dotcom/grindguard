#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${HOME}/.flutter-netlify"
FLUTTER_BIN="${FLUTTER_DIR}/bin/flutter"

echo "==> Installing Flutter SDK..."
if [ ! -f "$FLUTTER_BIN" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
export CI=true
export PUB_CACHE="${PWD}/.pub-cache"

flutter --version
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release

echo "==> Build complete: build/web"
ls -la build/web/
