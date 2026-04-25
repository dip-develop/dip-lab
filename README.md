# Home Lab - dipdev.de

## Структура

```
dipdev.de/
├── proxy/           # Traefik (reverse proxy)
├── vaultwarden/      # Password manager (Business)
├── paperless/       # Document management
├── portainer/       # Docker management UI
├── nextcloud/       # File cloud (Personal & Business)
├── n8n/             # Automation
├── immich/          # Photo gallery
├── llm/             # LLM API (vLLM)
├── openclaw/        # AI gateway
├── mailcow/        # Corporate mail (Business)
└── databases/      # Shared PostgreSQL, MySQL, Redis
```

## Ресурсы сервера

- **RAM**: 12 GB
- **NVMe**: 100 GB (для баз данных и быстрых операций)
- **Object Storage**: /mnt/object-storage (ограниченная скорость, лимит на права)

## Хранение данных

| Сервис | Путь | Описание |
|--------|-----|-----------|
| Базы данных | `/srv/database/` | PostgreSQL, MySQL, Redis |
| Фото | `/srv/immich/` | thumbnails, profiles |
| Документы | `/srv/paperless/` | OCR,全文搜索 |
| Файлы | `/mnt/object-storage/` | большие файлы, медленнее |
| Почта | `/srv/mailcow/` | корппочта |

## Сети

- `web` - внешняя (Traefik)
- `internal` - LLM, n8n, OpenCLAW
- `database` - общие БД
- `paperless_internal` - paperless
- `nextcloud_internal` - nextcloud
- `mailcow` - почтовый сервер

## Домены и порты

| Сервис | Домен | Порт | Описание |
|--------|-------|------|--------|
| Traefik | - | 4080 (http), 4443 (https) | Reverse proxy |
| Vaultwarden | vault.dipdev.de | 8200 | Менеджер паролей |
| Paperless | docs.dipdev.de | 8000 | Документы |
| Portainer | admin.dipdev.de | 9000/9443 | Docker UI |
| Nextcloud | cloud.dipdev.de | 80 | Файловый хостинг |
| n8n | flow.dipdev.de | 5678 | Автоматизация |
| Immich | photos.dipdev.de | 2283 | Фото |
| OpenCLAW | ai.dipdev.de | 18789 | AI gateway |
| Mailcow | mail.dipdev.de | 80/443 | Корппочта |
| LLM | - | 8000 | OpenAI-compatible API |

## Управление

### Скрипт manager.sh

```bash
./manager.sh <command> [service]
```

| Команда | Описание |
|---------|-----------|
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
./manager.sh start proxy  # запустить только proxy
./manager.sh logs immich   # логи immich
./manager.sh status       # статус
./manager.sh update      # обновить все
```

## Безопасность

- Все сервисы работают через HTTPS (Traefik)
- TLS 1.2+ с безопасными cipher suites
- Strict-Transport-Security заголовки
- Rate limiting на Traefik
- Vaultwarden для паролей
- Пароли не в git (используйте .env)
- Strict permissions на sensitive данные

## Развертывание с нуля

```bash
# 1. Клонировать репозиторий
git clone https://github.com/your-repo/dipdev.de.git
cd dipdev.de

# 2. Настроить .env файл (скопировать из .env.example)
cp .env.example .env
# Отредактировать .env с вашими паролями

# 3. Создать сети и директории
./manager.sh setup

# 4. Исправить права
./manager.sh perm

# 5. Запустить сервисы
./manager.sh start
```

## Notes

- Traefik слушает на портах 4080/4443 (т.к. 80/443 могут быть заняты)
- Все сервисы за Traefik работают через HTTPS
- Zero Trust Cloudflare для веб-доступа
- Логи в `/srv/proxy/logs/`