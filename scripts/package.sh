#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$("${ROOT_DIR}/scripts/read-version.sh")"
DIST_DIR="${ROOT_DIR}/dist"
STAGING_DIR="${ROOT_DIR}/build/dmg-staging"
APP_PATH="${ROOT_DIR}/build/UniversalControlRestart.app"
DMG_PATH="${DIST_DIR}/UniversalControlRestart-${VERSION}.dmg"

"${ROOT_DIR}/scripts/build.sh"

rm -rf "${DIST_DIR}" "${STAGING_DIR}"
mkdir -p "${DIST_DIR}" "${STAGING_DIR}"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${APP_PATH}" "${STAGING_DIR}/UniversalControlRestart.app"
/bin/ln -s /Applications "${STAGING_DIR}/Applications"

COPYFILE_DISABLE=1 /usr/bin/hdiutil create \
  -volname "UniversalControlRestart" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

(
  cd "${DIST_DIR}"
  /usr/bin/shasum -a 256 "UniversalControlRestart-${VERSION}.dmg" > "UniversalControlRestart-${VERSION}.dmg.sha256"
)

echo "Created ${DMG_PATH}"
cat "${DMG_PATH}.sha256"
