# Home Lab - dm-home.de

## Структура

```
dm-home.de/
├── databases/      # Shared PostgreSQL, MySQL, Redis
├── proxy/           # Traefik (reverse proxy)
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

- `web` - внешняя (Traefik)
- `internal` - LLM, OpenCLAW
- `database` - общие PostgreSQL, Redis
- `mailcow` - почтовый сервер

## Домены и порты

| Сервис | Домен | Порт | Описание |
|--------|-------|------|----------|
| Traefik | - | 4080 (http), 4443 (https) | Reverse proxy |
| Vaultwarden | vault.dm-home.de | 8200 | Менеджер паролей |
| Paperless | docs.dm-home.de | 8000 | Документы |
| Portainer | admin.dm-home.de | 9000/9443 | Docker UI |
| Nextcloud | cloud.dm-home.de | 80 | Файловый хостинг |
| n8n | flow.dm-home.de | 5678 | Автоматизация |
| Immich | photos.dm-home.de | 2283 | Фото |
| OpenCLAW | ai.dm-home.de | 18789 | AI gateway |
| Mailcow | mail.dipdev.de | 80/443 | Корппочта |
| LLM | - | 8000 | OpenAI-compatible API |

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
git clone https://github.com/your-repo/dm-home.de.git
cd dm-home.de

# 2. Создать сети и директории
./manager.sh setup

# 3. Заполнить пароли в .env файлах
vim databases/.env
vim vaultwarden/.env
vim proxy/.env
vim mailcow/mailcow.env

# 4. Исправить права
./manager.sh perm

# 5. Запустить БД и proxy первыми
./manager.sh start databases
./manager.sh start proxy

# 6. Запустить остальные сервисы
./manager.sh start
```

## Notes

- Traefik слушает на портах 4080/4443 (т.к. 80/443 могут быть заняты)
- Все сервисы за Traefik работают через HTTPS
- Zero Trust Cloudflare для веб-доступа
- Логи в `/srv/proxy/logs/`
- databases запускается первым (все сервисы зависят от него)