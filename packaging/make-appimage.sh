#!/usr/bin/env bash
#
# Assemble an AppDir from the Nuitka onefile build + bundled rkdeveloptool and
# package it as an AppImage. Expects:
#   dist/rkdevtoolgui     (Nuitka onefile app)
#   dist/rkdeveloptool    (bundled tool, from build-rkdeveloptool.sh)
#
set -euo pipefail

VERSION="${VERSION:-${GITHUB_REF_NAME#v}}"
[ -n "${VERSION:-}" ] || VERSION="0.0.0"

# AppImage arch string (x86_64 or aarch64); must match the host architecture.
APPIMAGE_ARCH="${APPIMAGE_ARCH:-x86_64}"

APPDIR="$PWD/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"

cp dist/rkdevtoolgui  "$APPDIR/usr/bin/rkdevtoolgui"
cp dist/rkdeveloptool "$APPDIR/usr/bin/rkdeveloptool"
chmod +x "$APPDIR/usr/bin/rkdevtoolgui" "$APPDIR/usr/bin/rkdeveloptool"

cp packaging/rkdeveloptool-gui.desktop "$APPDIR/rkdeveloptool-gui.desktop"
if [ -f packaging/rkdeveloptool-gui.png ]; then
  cp packaging/rkdeveloptool-gui.png "$APPDIR/rkdeveloptool-gui.png"
else
  # appimagetool requires an icon; generate a plain placeholder if none exists.
  convert -size 256x256 xc:'#2b6cb0' "$APPDIR/rkdeveloptool-gui.png"
fi

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export APPDIR="$HERE"
exec "$HERE/usr/bin/rkdevtoolgui" "$@"
EOF
chmod +x "$APPDIR/AppRun"

curl -fsSL -o /tmp/appimagetool \
  "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${APPIMAGE_ARCH}.AppImage"
chmod +x /tmp/appimagetool

mkdir -p dist
# Extract-and-run avoids needing FUSE on CI runners.
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH="$APPIMAGE_ARCH" /tmp/appimagetool "$APPDIR" \
  "dist/RKDevelopTool-GUI-${VERSION}-${APPIMAGE_ARCH}.AppImage"

echo "==> Built dist/RKDevelopTool-GUI-${VERSION}-${APPIMAGE_ARCH}.AppImage"
