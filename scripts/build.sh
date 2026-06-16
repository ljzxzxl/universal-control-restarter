#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="UniversalControlRestart"
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICONSET_DIR="${BUILD_DIR}/${APP_NAME}.iconset"
ICON_GENERATOR="${BUILD_DIR}/GenerateIcon"

rm -rf "${APP_DIR}" "${ICONSET_DIR}" "${ICON_GENERATOR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}" "${ICONSET_DIR}"

cp "${ROOT_DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"

compile_swift() {
  local output="$1"
  shift

  swiftc -O -framework Cocoa "$@" -o "${output}"
}

compile_swift "${MACOS_DIR}/${APP_NAME}" "${ROOT_DIR}/Sources/main.swift"
compile_swift "${ICON_GENERATOR}" "${ROOT_DIR}/Sources/GenerateIcon.swift"

"${ICON_GENERATOR}" "${ICONSET_DIR}"
iconutil -c icns -o "${RESOURCES_DIR}/${APP_NAME}.icns" "${ICONSET_DIR}"

chmod +x "${MACOS_DIR}/${APP_NAME}"
codesign --force --sign - "${APP_DIR}" >/dev/null

echo "Built ${APP_DIR}"
