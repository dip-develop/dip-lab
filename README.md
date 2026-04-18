# Home Lab

## Структура

```
dm-home.de/
├── proxy/           # Traefik (reverse proxy)
├── vaultwarden/     # Password manager
├── paperless/      # Document management
├── portainer/       # Docker management
├── nextcloud/       # File cloud
├── n8n/            # Automation
├── immich/          # Photo gallery
├── llm/            # LLM API (vLLM, CPU)
└── openclaw/       # AI gateway
```

## Порты и домены

| Сервис | Домен | Порт | Описание |
|--------|-------|------|----------|
| Traefik | - | 4080 (http), 4443 (https) | Reverse proxy |
| Vaultwarden | vault.dm-home.de | 8200 | Менеджер паролей |
| Paperless | docs.dm-home.de | 8000 | Документы |
| Portainer | admin.dm-home.de | 9000/9443 | Docker UI |
| Nextcloud | cloud.dm-home.de | 80 | Файловый хостинг |
| n8n | flow.dm-home.de | 5678 | Автоматизация |
| Immich | photos.dm-home.de | 2283 | Фото |
| LLM | - | 8000 | OpenAI-compatible API (CPU) |
| OpenCLAW | ai.dm-home.de | 18789 | AI gateway |

## Команды

```bash
./manager.sh <command> [service]
```

## Сети

- `web` - внешняя сеть для Traefik
- `internal` - внутренняя сеть для LLM

## Управление

### Скрипт manager.sh

```bash
./manager.sh <command> [service]
```

| Команда | Описание |
|---------|-----------|
| `start` | Запустить все или конкретный сервис |
| `stop` | Остановить все сервисы |
| `restart` | Перезапустить все или конкретный сервис |
| `update` | Обновить (pull) все или конкретный сервис |
| `logs` | Логи сервиса (follow) |
| `status` | Статус всех сервисов |
| `perm` | Выставить права и владельца |
| `setup` | Создать сети и .env файлы |

### Примеры

```bash
./manager.sh start                # запустить все
./manager.sh start proxy        # запустить только proxy
./manager.sh stop              # остановить все
./manager.sh restart all       # перезапустить все
./manager.sh update immich     # обновить immich
./manager.sh logs nextcloud   # логи nextcloud
./manager.sh status          # статус всех
./manager.sh perm           # выставить права
```

## Notes

- Traefik слушает на нестандартных портах 4080/4443 (вместо 80/443)
- Все сервисы за Traefik работают через HTTPS
- Zero Trust Cloudflare для веб-доступа
- LLM API доступен без Zero Trust по внутренней сети
- Basic Auth для dashboard Traefik в `proxy/dynamic/auth.yml`
- Логи в `/srv/proxy/logs/`

## Health Checks

Все сервисы имеют health check через 30s интервал.

## Логирование

- Traefik access логи: `/srv/proxy/logs/access.log`
- Traefik error логи: `/srv/proxy/logs/traefik.log`
- Формат: JSON