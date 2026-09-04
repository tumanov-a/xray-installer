# Changelog

## v2.1.1 — Упрощение (2026-09-04)

### Удалено

- `install.sh` — дублировал `setup.sh` (только обёртка с `sudo`)
- `install_xray.sh` — дублировал шаг 1 в `setup.sh`

### Осталось

- `setup.sh` — единственная точка входа для установки и настройки
- `start.sh` — опционально, для перезапуска после ручного редактирования конфига

---

## v2.1.0 — Refactoring (2026-09-04)

### Исправленные баги

- **Парсинг `xray x25519`**: поддержка нового формата Xray 26+ (`PrivateKey:` / `Password (PublicKey):` вместо `Private key:` / `Public key:`)
- **Подстановка `{{UUID}}`**: UUID теперь корректно записывается в серверный конфиг
- **Зависимость от `jq`**: удалена сломанная логика с `jq` и дублирующимся `SHORTIDS_JSON`
- **Рабочая директория**: скрипты используют `SCRIPT_DIR` и работают из любой папки
- **JSON-примеры**: удалены `//` комментарии из example-конфигов (невалидный JSON)

### Новые скрипты

| Скрипт | Назначение |
|--------|-----------|
| `start.sh` | Валидация и перезапуск сервиса без полной переустановки |

### Улучшения `setup.sh`

- `set -euo pipefail` и проверка root
- Валидация `NUM_SHORTIDS` (положительное целое)
- UUID через `xray uuid`
- Проверка конфига: `xray run -test` перед запуском
- UFW: предупреждение, если не установлен (не падает)
- Функции `parse_x25519_keys`, `apply_template`, `build_vless_uri`
- `keys.txt` перезаписывается при каждом запуске
- В `keys.txt` — по одной VLESS URI на каждый ShortId

### Структура проекта

- Добавлены `vless-tcp-reality/`, `vless-grpc-reality/`, `vless-tcp-xtls-vision-reality/`
- Добавлен `keys_template.txt`
- Обновлён `.gitignore`

---

## v2.0.0 — VLESS URI и переменные ShortIds

### Новые возможности

1. **Переменное количество ShortIds** — `sudo bash setup.sh example.com 5`
2. **VLESS URI** для импорта в V2rayN, Clash, Nekobox
3. **Несколько VLESS URI** — по одной на каждый ShortId

### Технические изменения

- `config.json.template`: `"shortIds": {{SHORTIDS_JSON}}`
- Генерация JSON-массива shortIds в цикле
- Документация по VLESS URI

---

**Готово к использованию!** 🎉
