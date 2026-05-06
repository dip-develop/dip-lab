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

- `web` - Traefik reverse proxy (80, 443 на хосте)
- `internal` - все сервисы (VPN-only, 10.0.0.1)
- `database` - общие PostgreSQL, Redis, MySQL
- `monitoring` - Grafana, Prometheus, Loki (изолирована)
- `mailcow` - почтовый сервер (порты 25, 465, 587, 143, 993, 110, 995, 4190, 9993 на хосте)

## Доступ и порты

### VPN доступ (10.0.0.1)

Все сервисы доступны через VPN сеть на адресе **10.0.0.1** (кроме mailcow и traefik, которые доступны наружу)

| Сервис | Порт | Описание |
|--------|------|----------|
| **Сервисы** | | |
| Vaultwarden | 10.0.0.1:8200 | Менеджер паролей |
| Portainer | 10.0.0.1:9000 | Docker UI |
| Nextcloud | 10.0.0.1:8181 | Файловый хостинг |
| Paperless | 10.0.0.1:8000 | Управление документами |
| n8n | 10.0.0.1:5678 | Автоматизация |
| Immich | 10.0.0.1:2283 | Фото галерея |
| OpenCLAW | 10.0.0.1:18789 | AI gateway |
| LLM (Ollama) | 10.0.0.1:11434 | OpenAI-compatible API |
| **Monitoring** | | |
| Grafana | 10.0.0.1:3000 | Мониторинг и логи |
| Prometheus | 10.0.0.1:9090 | Метрики |
| Loki | 10.0.0.1:3100 | Логи |
| cAdvisor | 10.0.0.1:8081 | Docker метрики |
| Node Exporter | 10.0.0.1:9100 | Системные метрики |
| **Proxy** | | |
| Traefik | 80, 443 (наружу) | Reverse proxy (HTTP/HTTPS) |

### Внешний доступ (напрямую)

Эти сервисы доступны напрямую снаружи (без VPN):

| Сервис | Порт | Описание |
|--------|------|----------|
| **Traefik** | 80, 443 | Reverse proxy (HTTPS) |
| **Mailcow SMTP** | 25, 465, 587 | Отправка писем |
| **Mailcow IMAP** | 143, 993 | Получение писем |
| **Mailcow POP3** | 110, 995 | POP3 доступ |
| **Mailcow Sieve** | 4190 | Фильтрация писем |
| **Mailcow Dovecot** | 9993 | Dovecot admin |

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

- ✅ Все сервисы доступны только через VPN (10.0.0.1) кроме Traefik и Mailcow
- ✅ Traefik и Mailcow имеют прямой доступ из интернета (для почты и reverse proxy)
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

Все сервисы доступны только через VPN с IP **10.0.0.1**:

```bash
# Vault (Vaultwarden)
http://10.0.0.1:8200

# Docker UI (Portainer)
http://10.0.0.1:9000

# Nextcloud
http://10.0.0.1:8181

# Документы (Paperless)
http://10.0.0.1:8000

# n8n
http://10.0.0.1:5678

# Immich (фото)
http://10.0.0.1:2283

# OpenCLAW (AI gateway)
http://10.0.0.1:18789

# LLM API (Ollama)
http://10.0.0.1:11434

# Monitoring
http://10.0.0.1:3000  # Grafana
http://10.0.0.1:9090  # Prometheus
```

### API доступ

```bash
# Ollama OpenAI-compatible API (внутри docker network)
http://ollama:11434/v1/chat/completions

# или через VPN
http://10.0.0.1:11434/v1/chat/completions
```

## Заметки

- 🔒 Все сервисы доступны только через VPN (10.0.0.1)
- 📊 databases запускается первым (все сервисы зависят от него)
- 🌐 Traefik слушает на 80,443 (внешний доступ) для reverse proxy
- 📧 Mailcow порты (25, 465, 587, 143, 993, 110, 995, 4190, 9993) доступны на хосте для почты
- 🔐 Сервисы изолированы в сети `internal`, порты привязаны к 10.0.0.1
- 📝 Логи в `proxy/logs/`
- 🔐 TLS сертификаты в `proxy/acme.json` (не коммитить)
- 🚫 Без DNS можно добавить записи в `/etc/hosts` на клиенте
