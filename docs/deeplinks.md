# Deep Links и поведение Back (R1‑03)

**Контекст:** ListYB R1 — Android, локально, Drift  
**Схема диплинков:** `listyb://`  
**Роутер:** `go_router` (MaterialApp.router)

## Поддерживаемые ссылки

- `listyb://home` → маршрутизируется в `/` (домашний экран).  
- `listyb://list/<id>` → маршрутизируется в `/list/:id` (экран списка).  
- `listyb://list/<id>/add` → **QuickAdd**: маршрутизируется в `/list/7`).  - `listyb://list/<id>/add` → **QuickAdd**: маршрутизируется в `/list/:id?qa=1` (компактное добавление, авто‑закрытие при холодном старте).  
- `listyb://item/<id>/edit` — зарезервировано, **в R1 не реализовано**.  
Маршрутизатор нормализует URI в пути приложения (см. раздел «Маршрутизация»). [1](https://jwsite-my.sharepoint.com/personal/ibaklushin_bethel_jw_org/Documents/%D0%A4%D0%B0%D0%B9%D0%BB%D1%8B%20Microsoft%20Copilot%20Chat/listyb-20251108-1641.zip.pdf)

## Android (Intent‑filter)

В `android/app/src/main/AndroidManifest.xml` у `MainActivity` добавлен `intent-filter` с `scheme="listyb"`, включающий общую схему и частные случаи под `host="app"` и пути `/list` и `/home`. Это позволяет открывать приложение по кастомной схеме из ADB/браузера/виджета. [1](https://jwsite-my.sharepoint.com/personal/ibaklushin_bethel_jw_org/Documents/%D0%A4%D0%B0%D0%B9%D0%BB%D1%8B%20Microsoft%20Copilot%20Chat/listyb-20251108-1641.zip.pdf)

## Маршрутизация

- Конфигурация в `lib/app/router.dart`.  
- Глобальный `redirect` нормализует любые входящие `listyb://…` в «внутренние» пути приложения:
  - `listyb://home` → `/`
  - `listyb://list/<id>` → `/list/<id>`
  - `listyb://list/<id>/add` → `/list/<id>?qa=1`
  - Если кто‑то открыл `/list/:id/add` напрямую, роутер также нормализует это в `/list/:id?qa=1`.  
- Для QuickAdd при **холодном старте** координатор добавляет `autoclose=1`.  
- Для экрана списка при **холодном старте** добавляется служебный флаг `cold=1` (внутренний, нужен только для корректного Back‑поведения).  
Реализация: `lib/app/deeplinks.dart`, `lib/app/deeplink_parser.dart`, `lib/app/router.dart`. [1](https://jwsite-my.sharepoint.com/personal/ibaklushin_bethel_jw_org/Documents/%D0%A4%D0%B0%D0%B9%D0%BB%D1%8B%20Microsoft%20Copilot%20Chat/listyb-20251108-1641.zip.pdf)

## Обработка холодного/горячего старта

Компонент `DeepLinkCoordinator` использует `app_links`:
- **Cold start**: читает `getInitialLink()`, после первого кадра делает `router.go(...)`.  
  - Для QuickAdd дописывает `autoclose=1`.  
  - Для обычного открытия списка дописывает `cold=1`.  
- **Hot start**: слушает `uriLinkStream` и делает `router.push(...)` без добавления `cold`.  
Код: `lib/app/deeplinks.dart`. [1](https://jwsite-my.sharepoint.com/personal/ibaklushin_bethel_jw_org/Documents/%D0%A4%D0%B0%D0%B9%D0%BB%D1%8B%20Microsoft%20Copilot%20Chat/listyb-20251108-1641.zip.pdf)

## Правила Back

- Обычная навигация в приложении: **Back** возвращает по стеку, при корне — на Домой.  
- **Горячий диплинк** на список (`push`) → **Back** возвращает на Домой (`/`).  
- **Холодный диплинк** сразу на список (`go` + `?cold=1`) → **Back** **закрывает приложение**.  
- **QuickAdd**:  
  - Горячий диплинк → по завершении/Back возвращаемся на предыдущий экран.  
  - Холодный диплинк (`?autoclose=1`) → по завершении **закрываем приложение**.  
Back‑логика реализована на экране списка через `PopScope` / `SystemNavigator.pop()` и флаги `quickAdd`, `autoCloseWhenDone`, `isColdStart`. Код: `lib/features/lists/presentation/list_details_screen.dart`. [1](https://jwsite-my.sharepoint.com/personal/ibaklushin_bethel_jw_org/Documents/%D0%A4%D0%B0%D0%B9%D0%BB%D1%8B%20Microsoft%20Copilot%20Chat/listyb-20251108-1641.zip.pdf)

## Проверка через ADB

```bash
# Домой
adb shell am start -a android.intent.action.VIEW -d "listyb://home" com.yb.listyb

# Открыть список с id=1
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1" com.yb.listyb

# Альтернатива с host=app:
adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/1" com.yb.listyb

# QuickAdd в список id=1
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1/add" com.yb.listyb
