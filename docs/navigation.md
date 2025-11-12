# Навигация и диплинки (R1‑03)

**Роутер:** `go_router`  
**Основные экраны:** Домой, Список, Настройки

## Маршруты

- `/` → **Home (ListsScreen)**
- `/list/:id` → **ListDetailsScreen**
- `/settings` → **SettingsScreen**
- `/about` → **AboutScreen**
- `/search` → опционально

Все маршруты именованы: `home`, `list`, `settings`, `about`. Конфигурация — `lib/app/router.dart`. 

## Нормализация URI

Глобальный `redirect` в роутере преобразует внешние URI в «внутренний» путь:

- `listyb://home` → `/`
- `listyb://list/<id>` → `/list/<id>`
- `listyb://list/<id>/add` → `/list/<id>?qa=1`
- `/list/:id/add` → `/list/:id?qa=1` (защита от «сырого» пути без схемы)

Логика парсинга — `lib/app/deeplink_parser.dart`. 

## Обработка диплинков

Координатор `DeepLinkCoordinator` (`lib/app/deeplinks.dart`, `app_links`):

- **Cold**: читает `getInitialLink()` и делает `router.go(...)`.
  - Для QuickAdd добавляет `autoclose=1`.
  - Для обычного открытия списка добавляет `cold=1` (служебный флаг).
- **Hot**: слушает `uriLinkStream` и делает `router.push(...)` (без `cold`).

Это гарантирует ожидаемый стек и корректный Back. 

## Back‑поведение

- Если есть куда `pop()` — `pop`.
- Если стек пуст и это **холодный старт списка** (`?cold=1`, **не** QuickAdd) — `SystemNavigator.pop()` (закрыть приложение).
- Иначе — `go('/')` (Домой).
Реализовано в `ListDetailsScreen` через `PopScope` и флаги `quickAdd`, `autoCloseWhenDone`, `isColdStart`. 

## Примеры ADB

```bash
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1" com.yb.listyb
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1/add" com.yb.listyb
```

## Известные ограничения

- QuickEdit (`listyb://item/<id>/edit`) — не реализован в R1.  
- `ACTION_SEND` внешних приложений — вне скоупа R1.  
Код маршрутизации и обработчиков — см. `lib/app/*.dart`.