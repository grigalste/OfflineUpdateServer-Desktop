# Локальный сервер обновлений для Десктопа

Скрипт создает локальную копию сервера обновлений.

Используйте: updateserver.sh [PARAMETER] [[PARAMETER], ...]
    Параметры:
       domain, --domain            задает адрес будущего сервера обновления, в формате http://domain.name;
       nginx,  --nginx             используйте для установки NGINX (true|false);
       cron,   --cron              используйте для добавления правила в CRON (true|false);
       -?, -h, --help              справка.
       
## Пример
### Создать локальный сервер обновления доступного по адресу `http://domain.name`:
		bash updateserver.sh --domain http://domain.name
### Создать локальный сервер обновления и добавить правило CRON:
		bash updateserver.sh --domain http://domain.name --cron true
### Создать локальный сервер обновления, установить NGINX и добавить правило CRON:
		bash updateserver.sh --nginx true --domain http://domain.name --cron true
### При запуске без указания параметра `domain`, адрес будет запрошен в интерактивном режиме:
		bash updateserver.sh

## Настройка клиента
Reg файлы автоматически добавляют настройки праметров обновления.
Адрес сервера обновлений необходимо передать в параметре `--updates-appcast-url=""`

