#!/bin/bash
set -e

echo "Удаление апплета Keyboard Layout (Wayland)..."
sudo rm -rf "/usr/lib/x86_64-linux-gnu/budgie-desktop/plugins/keyboard-layout-wayland"
rm -rf "$HOME/.local/share/budgie-desktop/plugins/keyboard-layout-wayland"

killall budgie-panel 2>/dev/null || true
sleep 1
nohup budgie-panel --replace >/dev/null 2>&1 &

echo "Апплет успешно удален."
