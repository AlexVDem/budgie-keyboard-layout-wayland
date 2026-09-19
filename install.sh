#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "===================================================================="
echo " Установка нативного апплета раскладки клавиатуры для Budgie Wayland"
echo "===================================================================="

# 1. Зависимости
echo "[1/5] Проверка и установка зависимостей сборки..."
sudo apt update
sudo apt install -y \
    valac \
    gcc \
    libpeas-2-dev \
    budgie-core-dev \
    libgtk-3-dev \
    libgtk-layer-shell-dev \
    pkg-config \
    wtype

# 2. Выбор peas пакета
echo "[2/5] Проверка библиотеки libpeas..."
PEAS_PKG="libpeas-2"
if ! pkg-config --exists "$PEAS_PKG"; then
    PEAS_PKG="libpeas-1.0"
fi
echo "      Используется: $PEAS_PKG"

# 3. Транспиляция и компиляция в .so
echo "[3/5] Сборка нативного плагина (Vala -> C -> .so)..."
valac -C --pkg gtk+-3.0 --pkg budgie-3.0 --pkg "$PEAS_PKG" src/keyboard_layout_wayland.vala

gcc -shared -fPIC -O2 \
    src/keyboard_layout_wayland.c \
    -o libkeyboard_layout_wayland.so \
    $(pkg-config --cflags --libs gtk+-3.0 budgie-3.0 "$PEAS_PKG")

# 4. Установка в систему и домашний каталог
echo "[4/5] Установка плагина..."
SYSTEM_DIR="/usr/lib/x86_64-linux-gnu/budgie-desktop/plugins/keyboard-layout-wayland"
sudo mkdir -p "$SYSTEM_DIR"
sudo cp libkeyboard_layout_wayland.so "$SYSTEM_DIR/"
sudo cp src/KeyboardLayoutWayland.plugin "$SYSTEM_DIR/"

LOCAL_DIR="$HOME/.local/share/budgie-desktop/plugins/keyboard-layout-wayland"
mkdir -p "$LOCAL_DIR"
cp libkeyboard_layout_wayland.so "$LOCAL_DIR/"
cp src/KeyboardLayoutWayland.plugin "$LOCAL_DIR/"

# Очистка старых несовместимых python файлов если они были
rm -f "$LOCAL_DIR/keyboard_layout_wayland.py" "$LOCAL_DIR/keyboard-layout-wayland.plugin"

# 5. Настройка индикации через Scroll Lock LED в Labwc (Wayland)
echo "[5/5] Настройка переключения и LED индикатора для Labwc..."
LABWC_ENV="$HOME/.config/budgie-desktop/labwc/environment"
mkdir -p "$(dirname "$LABWC_ENV")"
if [ -f "$LABWC_ENV" ]; then
    if grep -q "XKB_DEFAULT_OPTIONS" "$LABWC_ENV"; then
        sed -i 's/XKB_DEFAULT_OPTIONS=.*/XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle,grp_led:scroll,terminate:ctrl_alt_bksp/' "$LABWC_ENV"
    else
        echo "XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle,grp_led:scroll,terminate:ctrl_alt_bksp" >> "$LABWC_ENV"
    fi
else
    cat << 'ENVEOF' > "$LABWC_ENV"
XKB_DEFAULT_LAYOUT=us,ru
XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle,grp_led:scroll,terminate:ctrl_alt_bksp
ENVEOF
fi

gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle', 'grp_led:scroll']" 2>/dev/null || true
labwc --reconfigure 2>/dev/null || true

# Автоматическое добавление на панель через gsettings
python3 - << 'PYADD'
import subprocess, ast, uuid

try:
    panels_raw = subprocess.check_output(["gsettings", "get", "com.solus-project.budgie-panel", "panels"]).decode().strip()
    panels = ast.literal_eval(panels_raw)
    if panels:
        panel_id = panels[0]
        applets_raw = subprocess.check_output(["gsettings", "get", f"com.solus-project.budgie-panel.panel:/com/solus-project/budgie-panel/panels/{panel_id}/", "applets"]).decode().strip()
        applets = ast.literal_eval(applets_raw)

        applet_name = "Keyboard Layout (Wayland)"
        found = False
        for aid in applets:
            try:
                name = subprocess.check_output(["gsettings", "get", f"com.solus-project.budgie-panel.applet:/com/solus-project/budgie-panel/applets/{aid}/", "name"]).decode().strip().strip("'\"")
                if "Keyboard Layout (Wayland)" in name:
                    found = True
                    break
            except Exception:
                pass

        if not found:
            new_uuid = "{" + str(uuid.uuid4()) + "}"
            subprocess.run(["gsettings", "set", f"com.solus-project.budgie-panel.applet:/com/solus-project/budgie-panel/applets/{new_uuid}/", "name", applet_name], check=True)
            subprocess.run(["gsettings", "set", f"com.solus-project.budgie-panel.applet:/com/solus-project/budgie-panel/applets/{new_uuid}/", "alignment", "end"], check=True)
            applets.append(new_uuid)
            subprocess.run(["gsettings", "set", f"com.solus-project.budgie-panel.panel:/com/solus-project/budgie-panel/panels/{panel_id}/", "applets", str(applets)], check=True)
            print("  -> Апплет автоматически добавлен на панель Budgie.")
        else:
            print("  -> Апплет уже присутствует на панели.")
except Exception as e:
    print("  -> Добавьте апплет вручную через Настройки рабочего стола Budgie.")
PYADD

echo "Перезапуск панели Budgie..."
killall budgie-panel 2>/dev/null || true
sleep 1
nohup budgie-panel --replace >/dev/null 2>&1 &

echo ""
echo "===================================================================="
echo " Установка завершена успешно!"
echo " Апплет раскладки активирован на панели Budgie."
echo "===================================================================="
