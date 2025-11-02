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
- Drag & Drop reorder
- Snackbar:
  - Удаление элемента: «Элемент удалён» + [Отменить] (3 сек)
  - Архивирование элемента (если реализовано): аналогично
- Empty state: «Нет элементов — добавьте первый»

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

## Deep Links
- listyb://home → /
- listyb://list/<id> → /list/:id
- listyb://search?q=<query> → /search?q=... (опц.)

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