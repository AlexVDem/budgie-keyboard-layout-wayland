# Budgie Keyboard Layout Applet for Wayland (Labwc)

Нативный апплет переключателя и индикатора раскладки клавиатуры (**EN** / **RU**) для **Ubuntu Budgie (сессия Wayland / Labwc)**.

Специально разработан для **Ubuntu Budgie 26.04+ (и 24.04)**, где рабочий стол Budgie переведён на `libpeas-2` и сессию Wayland (`labwc`), из-за чего старый `budgie-keyboard-applet` был убран, а Python-плагины больше не поддерживаются панелью.

---

## Особенности

- 🚀 **Нативный плагин (`Loader=C`)**: Скомпилирован в shared library (`.so`) с поддержкой `libpeas-2` и `budgie-3.0`.
- ⚡ **Мгновенный отклик в Wayland**: Отслеживание смены раскладки выполняется через аппаратный регистр `grp_led:scroll` композитора Labwc (с fallback на `ibus`).
- 🖱️ **Клик мышью**: Поддерживает смену языка кликом по апплету на панели (через `wtype` / `ibus`).
- 🎨 **Стилизация под тему Budgie**: Аккуратный индикатор с цветовым выделением активного языка (например, акцентный синий цвет для `RU`).
- 🛠️ **Автоматическая установка**: Скрипт сам собирает библиотеку, настраивает `labwc/environment` и добавляет апплет на панель.

---

## Требования

- Ubuntu Budgie 24.04 / 26.04+ (сессия Budgie Wayland / Labwc)
- `budgie-panel` (10.9 / 10.10+)
- `wtype` (для эмуляции переключения кликом мыши)

---

## Установка

Клонируйте репозиторий и запустите скрипт установки:

```bash
git clone https://github.com/YOUR_USERNAME/budgie-keyboard-layout-wayland.git
cd budgie-keyboard-layout-wayland
bash install.sh
```

Скрипт автоматически:
1. Установит необходимые зависимости для компиляции (`valac`, `gcc`, `budgie-core-dev`, `libpeas-2-dev`, `libgtk-layer-shell-dev` и др.).
2. Скомпилирует плагин в `libkeyboard_layout_wayland.so`.
3. Установит файлы плагина в системную директорию `/usr/lib/x86_64-linux-gnu/budgie-desktop/plugins/` и локальный каталог пользователя.
4. Пропишет опцию индикатора `grp_led:scroll` в `~/.config/budgie-desktop/labwc/environment`.
5. Добавит апплет на панель и перезапустит `budgie-panel`.

---

## Ручное добавление на панель

Если апплет не добавился автоматически:
1. Откройте **«Настройки рабочего стола Budgie»** (*Budgie Desktop Settings*).
2. Перейдите в раздел **«Панель»** (*Panel*).
3. Нажмите кнопку **«+» (Добавить апплет)**.
4. Выберите из списка **«Keyboard Layout (Wayland)»** и нажмите «Добавить».

---

## Удаление

Чтобы удалить плагин:

```bash
bash uninstall.sh
```

---

## Лицензия

GPL-3.0 / MIT
