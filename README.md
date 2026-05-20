# Xray Reality VPN - Автоматическая установка и настройка

Этот проект содержит полностью автоматизированный скрипт установки и настройки Xray сервера с поддержкой Reality протокола.

## ⭐ Версия 2.0.0 - Новое!

**Главное обновление**: теперь скрипт выводит готовую **VLESS URI** для быстрого импорта в приложения (V2rayN, Clash и т.д.)!

```
vless://UUID@IP:443?type=tcp&security=reality&pbk=KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
```

Просто скопируйте эту строку и вставьте в приложение! 🚀

## Что делает проект

Скрипт `setup.sh` выполняет следующие действия:

1. ✅ Устанавливает Xray
2. ✅ Генерирует пару ключей (Private/Public Key) используя `xray x25519`
3. ✅ Генерирует UUID для клиента
4. ✅ Генерирует множество shortIds (переменное количество) ⭐ НОВОЕ!
5. ✅ Создает конфиг сервера с подставленными значениями
6. ✅ Копирует конфиг в `/usr/local/etc/xray/config.json`
7. ✅ Конфигурирует firewall (UFW)
8. ✅ Запускает и включает Xray сервис
9. ✅ Генерирует клиентский конфиг с правильными значениями
10. ✅ Генерирует VLESS URI для импорта в приложения ⭐ НОВОЕ!
11. ✅ Генерирует альтернативные VLESS URI для каждого ShortId ⭐ НОВОЕ!

## Структура проекта

```
vpn/
├── setup.sh                      # Основной установочный скрипт
├── config.json.template          # Шаблон серверного конфига с переменными
├── client_config.json.template   # Шаблон клиентского конфига с переменными
├── config.json                   # Пример готового серверного конфига
├── client_config.json            # Пример готового клиентского конфига
├── install_xray.sh              # Справочные команды установки
├── keys.txt                      # Справочный файл для сохранения ключей
└── README.md                     # Этот файл
```

## Использование

### На сервере

1. **Загрузить проект на сервер:**
```bash
git clone <repository_url> /tmp/xray_setup
cd /tmp/xray_setup
```

Или скопировать файлы через SCP:
```bash
scp setup.sh user@server:/tmp/
```

2. **Запустить установку:**
```bash
# Со значениями по умолчанию (домен: speed.cloudflare.com, 2 ShortId)
sudo bash setup.sh

# Или с пользовательским доменом и количеством ShortIds
sudo bash setup.sh example.com 5
```

3. **Скрипт выведет:** 
   - Private Key
   - Public Key
   - UUID
   - ShortId (количество в зависимости от параметра)
   - **Готовую VLESS URI для подстановки в приложение** ⭐
   - Конфиг для клиента в файл `/tmp/client_config.json`

### На клиенте

**Способ 1: Использовать VLESS URI (рекомендуется)**

Скопируйте VLESS URI из вывода скрипта и подставьте его в Xray приложение:
```
vless://UUID@SERVER_IP:443?type=tcp&security=reality&pbk=PUBLIC_KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
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

Скрипт автоматически генерирует готовую VLESS URI для подстановки в приложение:

```
vless://UUID@SERVER_IP:443?type=tcp&security=reality&pbk=PUBLIC_KEY&fp=chrome&sni=DOMAIN&sid=SHORTID&encryption=none#reality
```

Вы можете просто скопировать эту ссылку и импортировать её в приложение (V2rayN, Clash и т.д.).

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
  - Использование: Каждый ShortId может использоваться для отдельного клиента или резервирования

## Безопасность

⚠️ **Важные замечания безопасности:**

1. Все ключи генерируются локально на сервере
2. Private Key никогда не отправляется клиенту
3. Клиент получает только Public Key
4. Клиентский конфиг сохраняется в `/tmp/` на сервере
5. Рекомендуется удалить клиентский конфиг после использования:
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
systemctl restart xray
```

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

### Пример 3: Обновление конфига без переустановки
```bash
sudo bash setup.sh newdomain.com
```

## Требования

- Ubuntu/Debian или другой Linux с поддержкой systemd
- `curl` установлен
- `openssl` установлен
- Доступ к интернету для загрузки Xray
- Root или sudo доступ

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
**Решение:** Убедитесь, что установка завершена успешно и перезагрузитесь:
```bash
sudo reboot
```

### Проблема: Порт 443 уже занят
**Решение:** Измените порт в `config.json` или завершите процесс, использующий порт:
```bash
sudo lsof -i :443
sudo kill -9 <PID>
```

## Дополнительная информация

### О Reality протоколе
Reality - это протокол маскировки, который скрывает Xray трафик под обычный HTTPS трафик к легитимному веб-сайту. Это делает его очень сложным для блокировки.

### О параметрах:
- **serverName**: Домен, к которому будет выглядеть подключение (используется в SNI)
- **shortId**: Дополнительный параметр для идентификации клиента
- **fingerprint**: Используется для имитации браузера (Chrome, Firefox, Safari и т.д.)

## Лицензия

Этот проект основан на Xray-core, который выпускается под лицензией MPL 2.0.

## Автор

Создано для облегчения развертывания Xray серверов с Reality протоколом.

## Ссылки

- [Xray-core GitHub](https://github.com/XTLS/Xray-core)
- [Xray Documentation](https://xtls.github.io/)
- [Reality Protocol Info](https://github.com/XTLS/Xray-core/blob/main/transport/internet/reality/config.proto)
