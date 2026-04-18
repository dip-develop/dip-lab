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
├── llm/            # LLM API (vLLM)
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
| LLM | - | 8000 | OpenAI-compatible API |
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

### Примеры

```bash
./manager.sh start                # запустить все
./manager.sh start proxy        # запустить только proxy
./manager.sh stop              # остановить все
./manager.sh restart all       # перезапустить все
./manager.sh update immich     # обновить immich
./manager.sh logs nextcloud   # логи nextcloud
./manager.sh status          # статус всех
```

## Notes

- Traefik слушает на нестандартных портах 4080/4443 (вместо 80/443)
- Все сервисы за Traefik работают через HTTPS
- Zero Trust Cloudflare для веб-доступа
- LLM API доступен без Zero Trust по внутренней сети