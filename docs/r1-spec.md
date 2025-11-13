# ListYB — R1 Spec (Android, локально, Drift)

## Scope
- Lists & Items: CRUD, complete, reorder (DnD)
- Filters (All/Open/Done), text search
- Navigation + deep links (listyb://)
- Themes: System/Light/Dark
- i18n: RU/EN
- Undo для удаления и архивирования (списков и элементов)
- No export/import, no cloud sync
- Local DB: Drift (SQLite), schema v1

## Non-Functional
- Perf: open list ≤100ms, smooth scroll
- Reliability: transactions for reorder & undo
- MinSdk: 26
- Accessibility: Material 3 guidelines

## Data Model (Drift v1)
- tables: lists, items (см. /docs/db/schema.sql)
- counts computed via queries (no triggers)

## Architecture
- Flutter, Riverpod, go_router, Drift
- Clean layering (domain/data/presentation)
- Stream-based repos; use-cases encapsulate rules

## UI
### Home
- Cards: title + badge (open/total)
- Actions: create, rename, archive/unarchive, delete
- Snackbar:
  - Удаление: «Список удалён» + [Отменить] (3 сек)
  - Архивирование: «Список архивирован» + [Отменить] (3 сек)
- Empty state: «Нет списков — создайте первый»

### ListDetails
- Quick add field
- Filters: All/Open/Done
- Search by substring
- Drag & Drop reorder (включается только при фильтре «Все» и пустой строке поиска)
- Snackbar:
  - Удаление элемента: «Элемент удалён» + [Отменить] (3 сек)
  - Архивирование элемента (если реализовано): аналогично
- Empty state: «Нет элементов — добавьте первый»

#### Жесты
- Свайп вправо по элементу — редактирование (диалог ввода нового названия)
- Свайп влево по элементу — удаление с показом Snackbar (Undo)

#### Поиск
- Регистронезависимый (Unicode-safe), фильтрация выполняется на клиенте

### Settings
- Theme: System/Light/Dark
- Language: RU/EN
- About: MIT License

## Undo UX
- Snackbar с кнопкой «Отменить»
- Таймер: 3 сек
- При Undo:
  - Восстановить объект в прежнем состоянии (название, позиция)
  - Для списка: вернуть из архива или восстановить удалённый
  - Для элемента: вернуть в список на прежнюю позицию
- Реализация: хранить копию удалённого объекта в памяти до истечения таймера; при Undo — вставить обратно в БД транзакцией

## Navigation
- Навигация: `go_router` (MaterialApp.router).
- Маршруты:
  - `/` — Домой (списки).
  - `/list/:id` — экран списка.
  - `/settings` — настройки.
  - `/about` — «О приложении».
  - `/search` — опционально.
- Нормализация путей:
  - `listyb://home` → `/`
  - `listyb://list/<id>` → `/list/<id>`
  - `listyb://list/<id>/add` → `/list/<id>?qa=1`
  - `/list/:id/add` → `/list/:id?qa=1` (если пришёл «сырой» путь без схемы).

## Deep Links

- Схема: `listyb://`.
- Поддерживаемые команды:
  - `listyb://home` → Домой.
  - `listyb://list/<id>` → экран списка `<id>`.
  - `listyb://list/<id>/add` → QuickAdd (компактное добавление).
  - `listyb://item/<id>/edit` — **не реализовано в R1** (резерв).
- Обработка:
  - **Cold start**: `DeepLinkCoordinator` (на базе `app_links`) выполняет `router.go(...)`, добавляет служебные флаги:
    - `autoclose=1` для QuickAdd (авто‑закрытие после действия).
    - `cold=1` для обычного открытия списка (для корректного Back).
  - **Hot start**: выполняется `router.push(...)` без флага `cold`.
- Правила Back:
  - Обычная навигация — `pop()` по стеку, на корне — Домой.
  - Горячий диплинк на список — Back ведёт на Домой.
  - Холодный диплинк на список — Back **закрывает приложение**.
  - QuickAdd (cold) — по завершении **закрываем приложение**; (hot) — возвращаемся назад.

**Файлы:**
 `lib/app/router.dart`, `lib/app/deeplinks.dart`, `lib/app/deeplink_parser.dart`, `lib/features/lists/presentation/list_details_screen.dart`, `android/app/src/main/AndroidManifest.xml`. 

## Testing & CI
- Unit: repos/use-cases (CRUD, undo)
- Widget: Home, ListDetails (Undo flows)
- Analyze clean
- GitHub Actions builds release APK

## DoD
- CRUD списков и элементов, DnD устойчив
- Фильтры и поиск корректны
- go_router + диплинки открываются с ADB
- Темы и i18n переключаются без перезапуска
- Undo для удаления/архивирования работает
- Тесты зелёные, анализ без варнингов
- CI собрал APK, артефакт загружен
- LICENSE (MIT) присутствует