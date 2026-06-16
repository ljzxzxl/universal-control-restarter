#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="UniversalControlRestart"
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICON_SOURCE="${ROOT_DIR}/Resources/${APP_NAME}.icns"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
DEPLOYMENT_TARGET="12.0"
ARCHS=(x86_64 arm64)

rm -rf "${APP_DIR}" "${BUILD_DIR}/arch"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

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

if [[ ! -f "${ICON_SOURCE}" ]]; then
  echo "Missing icon: ${ICON_SOURCE}" >&2
  exit 1
fi

cp "${ICON_SOURCE}" "${RESOURCES_DIR}/${APP_NAME}.icns"

chmod +x "${MACOS_DIR}/${APP_NAME}"
codesign --force --sign - "${APP_DIR}" >/dev/null

echo "Built ${APP_DIR}"
