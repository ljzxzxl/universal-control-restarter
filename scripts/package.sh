#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$("${ROOT_DIR}/scripts/read-version.sh")"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${ROOT_DIR}/build/UniversalControlRestart.app"
ZIP_PATH="${DIST_DIR}/UniversalControlRestart-${VERSION}.zip"

"${ROOT_DIR}/scripts/build.sh"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc "${APP_PATH}" "${ZIP_PATH}"
/usr/bin/shasum -a 256 "${ZIP_PATH}" > "${ZIP_PATH}.sha256"

echo "Created ${ZIP_PATH}"
cat "${ZIP_PATH}.sha256"
