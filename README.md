# Xray Reality VPN - Автоматическая установка и настройка

Этот проект содержит полностью автоматизированный скрипт установки и настройки Xray сервера с поддержкой Reality протокола.

## ⭐ Версия 2.1.0

**Главное обновление**: скрипт генерирует **VLESS URI для каждого ShortId** и сохраняет их в `keys.txt`.

```
vless://UUID@IP:443?type=tcp&security=reality&pbk=KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
```

Просто скопируйте ссылку и вставьте в приложение (V2rayN, Clash и т.д.)! 🚀

## Что делает проект

Скрипт `setup.sh` выполняет следующие действия:

1. ✅ Устанавливает Xray
2. ✅ Генерирует пару ключей (Private/Public Key) используя `xray x25519`
3. ✅ Генерирует UUID для клиента (`xray uuid`)
4. ✅ Генерирует множество shortIds (переменное количество)
5. ✅ Создает конфиг сервера с подставленными значениями
6. ✅ Копирует конфиг в `/usr/local/etc/xray/config.json`
7. ✅ Проверяет конфиг перед запуском (`xray run -test`)
8. ✅ Конфигурирует firewall (UFW, если установлен)
9. ✅ Запускает и включает Xray сервис
10. ✅ Генерирует клиентский конфиг с правильными значениями
11. ✅ Генерирует VLESS URI для каждого ShortId (по количеству `NUM_SHORTIDS`)
12. ✅ Сохраняет ключи и VLESS URI в `keys.txt` (перезаписывается при каждом запуске)

## Структура проекта

```
xray-installer/
├── setup.sh                      # Установка, генерация конфига и запуск
├── start.sh                      # Перезапуск Xray с существующим конфигом
├── config.json.template          # Шаблон серверного конфига
├── client_config.json.template   # Шаблон клиентского конфига
├── keys.txt                      # Сгенерированные ключи и VLESS URI (не в git)
├── keys_template.txt             # Пример формата keys.txt
├── .gitignore
└── README.md                     # Этот файл
```

## Использование

### На сервере

1. **Загрузить проект на сервер:**
```bash
git clone <repository_url> /opt/xray-installer
cd /opt/xray-installer
```

Или скопировать файлы через SCP:
```bash
scp -r xray-installer/ user@server:/opt/
```

2. **Запустить установку:**
```bash
# По умолчанию: speed.cloudflare.com, 2 ShortId
sudo bash setup.sh

# С доменом и количеством ShortIds
sudo bash setup.sh example.com 5
```

3. **Скрипт выведет:**
   - Private Key
   - Public Key
   - UUID
   - ShortId (количество в зависимости от параметра)
   - **VLESS URI для каждого ShortId** (по одной ссылке на клиента)
   - Конфиг для клиента в файл `/tmp/client_config.json`
   - Ключи и все VLESS URI в `keys.txt` (в корне проекта)

### На клиенте

**Способ 1: Использовать VLESS URI (рекомендуется)**

Скопируйте VLESS URI из вывода скрипта или из `keys.txt` и импортируйте в Xray приложение. При `NUM_SHORTIDS=5` будет 5 ссылок — по одной на каждого клиента (отличаются только `sid`):

```
vless://UUID@SERVER_IP:443?type=tcp&security=reality&pbk=PUBLIC_KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
```

Пример блока в `keys.txt`:
```
VLESS URIs:
- vless://...@...&sid=abc123...&...
- vless://...@...&sid=def456...&...
```

**Способ 2: Использовать JSON конфиг**

1. **Получить конфиг с сервера:**
```bash
scp user@server:/tmp/client_config.json ./
```

2. **Использовать конфиг в Xray клиенте:**
   - Скопировать содержимое `client_config.json` в конфиг вашего Xray клиента
   - Или использовать напрямую: `xray -c client_config.json`

3. **Подключиться через SOCKS proxy:**
   - SOCKS5: `127.0.0.1:10808`
   - Использовать в браузере или приложении через proxy

## Параметры и переменные

### Переменные, которые генерируются автоматически:

| Переменная | Описание | Где используется |
|-----------|---------|-----------------|
| `{{PRIVATE_KEY}}` | Приватный ключ Reality | config.json (сервер) |
| `{{PUBLIC_KEY}}` | Публичный ключ Reality | client_config.json (клиент) |
| `{{UUID}}` | UUID клиента | config.json (сервер), client_config.json (клиент) |
| `{{SHORTIDS_JSON}}` | JSON массив всех ShortIds | config.json (сервер) |
| `{{SHORTID_1}}` | Первый (основной) ShortId | client_config.json (клиент), VLESS URI |
| `{{DOMAIN}}` | Домен маскировки | config.json (сервер), client_config.json (клиент) |
| `{{SERVER_IP}}` | IP сервера | client_config.json (клиент) |

### VLESS URI

Скрипт генерирует **по одной VLESS URI на каждый ShortId**. Количество ссылок = значению `NUM_SHORTIDS` (по умолчанию 2).

Все URI сохраняются в `keys.txt` (файл перезаписывается при каждом запуске `setup.sh` и исключён из git через `.gitignore`).

```
vless://UUID@SERVER_IP:443?type=tcp&security=reality&pbk=PUBLIC_KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
```

Каждый клиент может использовать свою ссылку с уникальным `sid`.

## Параметры скрипта

### Синтаксис:
```bash
sudo bash setup.sh [DOMAIN] [NUM_SHORTIDS]
```

### Параметры:
- `DOMAIN` (опционально): Домен для маскировки Reality подключения
  - По умолчанию: `speed.cloudflare.com`
  - Пример: `sudo bash setup.sh example.com`

- `NUM_SHORTIDS` (опционально): Количество ShortId для генерации
  - По умолчанию: `2`
  - Пример: `sudo bash setup.sh example.com 5` (создаст 5 ShortId)
  - Использование: Каждый ShortId может использоваться для отдельного клиента

## Безопасность

⚠️ **Важные замечания безопасности:**

1. Все ключи генерируются локально на сервере
2. Private Key никогда не отправляется клиенту
3. Клиент получает только Public Key
4. Клиентский конфиг сохраняется в `/tmp/` на сервере
5. `keys.txt` содержит приватные ключи — не коммитьте и не публикуйте
6. Рекомендуется удалить клиентский конфиг после использования:
   ```bash
   rm /tmp/client_config.json
   ```

## Логирование

Все действия логируются в `/tmp/xray_setup.log`:
```bash
tail -f /tmp/xray_setup.log
```

## Восстановление и Отладка

### Проверить статус Xray:
```bash
systemctl status xray
```

### Просмотреть логи Xray:
```bash
journalctl -u xray -f
```

### Перезагрузить конфиг:
```bash
sudo bash start.sh
# или
systemctl restart xray
```

`start.sh` проверяет конфиг (`xray run -test`) перед перезапуском сервиса.

### Остановить Xray:
```bash
systemctl stop xray
```

## Примеры использования

### Пример 1: Быстрая установка со значениями по умолчанию
```bash
sudo bash setup.sh
```

### Пример 2: Установка с пользовательским доменом
```bash
sudo bash setup.sh myproxy.com
```

### Пример 3: Пять клиентов — пять VLESS URI
```bash
sudo bash setup.sh example.com 5
cat keys.txt
```

## Требования

- Ubuntu/Debian или другой Linux с поддержкой systemd
- `curl` установлен
- `openssl` установлен
- Root или sudo доступ (обязательно для `setup.sh`)
- Доступ к интернету для загрузки Xray

## Поддерживаемые ОС

- Ubuntu 18.04+
- Debian 10+
- CentOS 7+ (с systemd)
- Другие системы на основе Linux

## Возможные проблемы

### Проблема: "Permission denied"
**Решение:** Используйте `sudo`:
```bash
sudo bash setup.sh
```

### Проблема: "Command not found: xray"
**Решение:** Запустите полную установку:
```bash
sudo bash setup.sh
```

### Проблема: Порт 443 уже занят
**Решение:** Измените порт в `config.json` или завершите процесс, использующий порт:
```bash
sudo lsof -i :443
sudo kill -9 <PID>
```

### Проблема: Пустые Private/Public Key
**Решение:** Обновите `setup.sh` — старые версии не поддерживали новый формат вывода `xray x25519` (Xray 26+).

## Дополнительная информация

### О Reality протоколе
Reality — протокол маскировки, который скрывает Xray трафик под обычный HTTPS трафик к легитимному веб-сайту.

### О параметрах:
- **serverName**: Домен, к которому будет выглядеть подключение (используется в SNI)
- **shortId**: Дополнительный параметр для идентификации клиента
- **fingerprint**: Используется для имитации браузера (Chrome, Firefox, Safari и т.д.)

## Лицензия

Этот проект основан на Xray-core, который выпускается под лицензией MPL 2.0.

## Ссылки

- [Xray-core GitHub](https://github.com/XTLS/Xray-core)
- [Xray Documentation](https://xtls.github.io/)
- [Reality Protocol Info](https://github.com/XTLS/Xray-core/blob/main/transport/internet/reality/config.proto)
