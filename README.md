# Home Lab - dm-home.de

## Структура

```
dm-home.de/
├── databases/      # Shared PostgreSQL, MySQL, Redis
├── proxy/           # Traefik (reverse proxy)
├── monitoring/      # Grafana, Prometheus, Loki
├── vaultwarden/      # Password manager
├── paperless/       # Document management
├── portainer/       # Docker management UI
├── nextcloud/       # File cloud (Personal)
├── n8n/             # Automation
├── immich/          # Photo gallery
├── llm/             # LLM API (vLLM)
├── openclaw/        # AI gateway
└── mailcow/        # Corporate mail (Business)
```

## Ресурсы сервера

- **RAM**: 12 GB
- **NVMe**: 100 GB (для баз данных и быстрых операций)
- **Object Storage**: /mnt/object-storage (ограниченная скорость, лимит на права)

## База данных

Общая PostgreSQL и Redis для всех сервисов:

| Сервис | База данных | Описание |
|--------|-------------|----------|
| databases | PostgreSQL, Redis | Общие БД |
| mailcow | MySQL (встроенная) | Почта |

## Сети

- `web` - внешняя (Traefik) - **БУДЕТ УДАЛЕНА** после PR #1
- `internal` - LLM, OpenCLAW (VPN-only)
- `database` - общие PostgreSQL, Redis
- `mailcow` - почтовый сервер (остаётся внешним)

## Доступ и порты

### VPN доступ (10.0.0.1)

Все сервисы доступны **ТОЛЬКО** через VPN сеть на адресе **10.0.0.1**

| Сервис | VPN Порт | Описание |
|--------|----------|----------|
| Grafana | 10.0.0.1:3000 | Мониторинг и логи |
| Vaultwarden | 10.0.0.1:8200 | Менеджер паролей |
| Paperless | 10.0.0.1:8000 | Управление документами |
| Portainer | 10.0.0.1:9000 | Docker UI (HTTP) |
| Portainer SSL | 10.0.0.1:9443 | Docker UI (HTTPS) |
| Nextcloud | 10.0.0.1:80 | Файловый хостинг |
| Nextcloud SSL | 10.0.0.1:443 | Файловый хостинг (HTTPS) |
| n8n | 10.0.0.1:5678 | Автоматизация |
| Immich | 10.0.0.1:2283 | Фото галерея |
| OpenCLAW | 10.0.0.1:18789 | AI gateway |
| LLM (vLLM) | 10.0.0.1:8000 | OpenAI-compatible API |
| Traefik Dashboard | 10.0.0.1:8080 | Управление маршрутами (внутренний) |

### Внешний доступ (только Mailcow)

| Сервис | Порт | Описание |
|--------|------|----------|
| Mailcow SMTP | 25, 465, 587 | Отправка писем |
| Mailcow IMAP | 143, 993 | Получение писем |
| Mailcow Web | 80, 443 | Web интерфейс (mail.dipdev.de) |

### База данных (внутренняя сеть)

| Сервис | Хост | Порт | Описание |
|--------|------|------|----------|
| PostgreSQL | database-postgres | 5432 | Основная БД (Vaultwarden, Paperless, Nextcloud, Immich, n8n) |
| MySQL | database-mysql | 3306 | Mailcow MySQL |
| Redis | database-redis | 6379 | Кэш и очереди |

## Управление

### Скрипт manager.sh

```bash
./manager.sh <command> [service]
```

| Команда | Описание |
|---------|----------|
| `start [svc]` | Запустить все или конкретный сервис |
| `stop` | Остановить все сервисы |
| `restart [svc]` | Перезапустить |
| `update [svc]` | Обновить (pull) |
| `logs svc` | Логи сервиса |
| `status` | Статус всех сервисов |
| `setup` | Создать сети и /srv/ директории |
| `perm` | Исправить права |

### Примеры

```bash
./manager.sh setup           # создать сети и папки
./manager.sh start          # запустить все
./manager.sh start databases  # ВСЕГДА БД ПЕРВЫМИ
./manager.sh start proxy     # Потом proxy
./manager.sh start           # Потом остальное
./manager.sh logs immich     # логи immich
./manager.sh status          # статус
./manager.sh update          # обновить все
```

## Безопасность

- ✅ Все сервисы работают только через VPN (10.0.0.1)
- ✅ Нет прямого доступа через интернет кроме Mailcow
- ✅ TLS 1.2+ с безопасными cipher suites
- ✅ Strict-Transport-Security заголовки
- ✅ Rate limiting на Traefik
- ✅ Vaultwarden для управления паролями
- ✅ Пароли не в git (используйте .env)
- ✅ Strict permissions на sensitive данные

## Развертывание с нуля

```bash
# 1. Клонировать репозиторий
git clone https://github.com/Dimoshka/server.git
cd server

# 2. Создать сети и директории
./manager.sh setup

# 3. Заполнить пароли в .env файлах
vim databases/.env
vim vaultwarden/.env
vim nextcloud/.env
vim mailcow/mailcow.env

# 4. Исправить права
./manager.sh perm

# 5. Запустить БД и proxy первыми (КРИТИЧНО!)
./manager.sh start databases
./manager.sh start proxy

# 6. Запустить остальные сервисы
./manager.sh start

# 7. Проверить статус
./manager.sh status
```

## Доступ к сервисам

### Подключение к VPN

Все сервисы доступны тол��ко через VPN с IP **10.0.0.1**:

```bash
# Подключиться к Grafana через VPN
https://10.0.0.1:3000

# Vault (Vaultwarden)
https://10.0.0.1:8200

# Документы (Paperless)
https://10.0.0.1:8000

# Docker UI (Portainer)
https://10.0.0.1:9443

# Nextcloud
https://10.0.0.1

# n8n
https://10.0.0.1:5678

# Immich (фото)
https://10.0.0.1:2283
```

### API доступ

```bash
# vLLM OpenAI-compatible API (внутри docker network)
http://llm:8000/v1/chat/completions

# или через VPN
http://10.0.0.1:8000/v1/chat/completions
```

## Заметки

- 🔒 **PR #1**: Миграция на VPN-only доступ (внешний: только Mailcow)
- 📊 databases запускается первым (все сервисы зависят от него)
- 🔄 Traefik больше не слушает на 80/443 (только на внутренних портах)
- 🛡️ Zero Trust Cloudflare для веб-доступа (отключено во время миграции)
- 📝 Логи в `/srv/proxy/logs/`
- 🔐 TLS сертификаты в `proxy/certs/` (не коммитить)
