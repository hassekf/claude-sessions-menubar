#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Claude Sessions"
INSTALL_PATH="/Applications/${APP_NAME}.app"

echo "→ building release"
./build-app.sh > /dev/null

SRC_APP="./build/ClaudeSessions.app"
if [ ! -d "$SRC_APP" ]; then
    echo "✗ build artifact not found at $SRC_APP"
    exit 1
fi

echo "→ stopping running instance (if any)"
pkill -x ClaudeSessions 2>/dev/null || true
sleep 0.3

echo "→ installing to $INSTALL_PATH"
rm -rf "$INSTALL_PATH"
cp -R "$SRC_APP" "$INSTALL_PATH"

echo "→ ad-hoc codesign"
codesign --force --deep --sign - "$INSTALL_PATH" > /dev/null 2>&1 || true

echo "→ clearing quarantine"
xattr -cr "$INSTALL_PATH" 2>/dev/null || true

echo "→ launching"
open "$INSTALL_PATH"

echo ""
echo "✓ ${APP_NAME} instalado em $INSTALL_PATH"
echo "  • Icone aparece na menu bar com contagem N/M (working/total)"
echo "  • Na primeira execucao, registra-se automaticamente para iniciar no login"
echo "  • Para desativar: clique no engrenagem dentro do app > desmarcar \"Iniciar no login\""
