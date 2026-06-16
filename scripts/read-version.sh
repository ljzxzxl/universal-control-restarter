#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${ROOT_DIR}/Info.plist"
