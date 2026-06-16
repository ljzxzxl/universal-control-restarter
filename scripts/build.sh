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
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
DEPLOYMENT_TARGET="12.0"
ARCHS=(x86_64 arm64)

rm -rf "${APP_DIR}" "${ICONSET_DIR}" "${ICON_GENERATOR}" "${BUILD_DIR}/arch"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}" "${ICONSET_DIR}"

cp "${ROOT_DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"

compile_swift_arch() {
  local output="$1"
  local arch="$2"
  shift
  shift

  swiftc -O \
    -framework Cocoa \
    -sdk "${SDK_PATH}" \
    -target "${arch}-apple-macos${DEPLOYMENT_TARGET}" \
    "$@" \
    -o "${output}"
}

compile_universal_swift() {
  local output="$1"
  local name="$2"
  shift
  shift

  local slices=()
  local arch_output
  mkdir -p "${BUILD_DIR}/arch"

  for arch in "${ARCHS[@]}"; do
    arch_output="${BUILD_DIR}/arch/${name}-${arch}"
    compile_swift_arch "${arch_output}" "${arch}" "$@"
    slices+=("${arch_output}")
  done

  lipo -create -output "${output}" "${slices[@]}"
  lipo "${output}" -verify_arch "${ARCHS[@]}"
}

compile_universal_swift "${MACOS_DIR}/${APP_NAME}" "${APP_NAME}" "${ROOT_DIR}/Sources/main.swift"
compile_universal_swift "${ICON_GENERATOR}" "GenerateIcon" "${ROOT_DIR}/Sources/GenerateIcon.swift"

"${ICON_GENERATOR}" "${ICONSET_DIR}"
iconutil -c icns -o "${RESOURCES_DIR}/${APP_NAME}.icns" "${ICONSET_DIR}"

chmod +x "${MACOS_DIR}/${APP_NAME}"
codesign --force --sign - "${APP_DIR}" >/dev/null

echo "Built ${APP_DIR}"
