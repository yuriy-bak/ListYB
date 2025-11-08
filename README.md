
# ListYB

Списки задач и покупок с поддержкой нескольких списков, быстрых действий, диплинков и Android‑виджета (виджет — планируется в следующих итерациях). Текущая итерация фокусируется на Android и локальном хранении (Drift/SQLite). 

> **Контекст:** ListYB **R1 — Android, локально, Drift**  
> **Пакет:** `com.yb.listyb` • **minSdk:** 26 • **Схема диплинков:** `listyb://` 

---

## Возможности (R1)

- Домашний экран со списками; переход к деталям списка. 
- Экран списка: создание элементов, отметка выполнения, удаление с **Undo** (Snackbar, 3 сек), базовые фильтры/поиск по ТЗ R1. 
- Диплинки: `listyb://home`, `listyb://list/<id>`, `listyb://list/<id>/add` (QuickAdd, авто‑закрытие при холодном старте). Поддержаны также альтернативные формы `listyb://app/...`. 
- Корректное поведение **Back** для холодных/горячих диплинков (закрытие приложения при холодном переходе прямо на экран списка; возврат на Домой при горячем `push`). 
- Темы: светлая/тёмная (FlexColorScheme, Material 3). 
- Локализация и Settings запланированы и частично подготовлены (ключи i18n, экран Settings — в плане R1). 

> В R1 **нет**: облака/шаринга, сложных тегов/меток, импорта/экспорта, мультиплатформенной поставки. Виджет Android заложен в ТЗ и появится в следующих шагах. 

---

## Технологии

- **Flutter** (Material 3), **go_router** — навигация и глобальная нормализация `listyb://…` → внутренних путей приложения. 
- **Drift/SQLite** — локальная БД: таблицы `lists` и `items`, FK, индексы, миграции (v1→v2 добавляет `items.note`). Включены foreign keys (`PRAGMA foreign_keys = ON`). 
- **Riverpod** — состояние (заложено в архитектуре), clean‑слои (domain/data/presentation). 
- **FlexColorScheme** — темы, **app_links** — диплинки, **package_info_plus**, **logger** и др. (см. `docs/r1-spec.md`). 

---

## Структура проекта (сокращённо)

- `lib/app/` — `app.dart`, `router.dart`, `deeplinks.dart`, `deeplink_parser.dart`, `theme.dart`  
- `lib/data/db/` — `app_database.dart` (+ `.g.dart`), DAO (`lists_dao.dart`, `items_dao.dart`)  
- `docs/` — спецификации R1, диплинки, навигация, архитектура, i18n‑ключи, чек‑листы и шаблоны шагов  
- `android/` — `AndroidManifest.xml` с intent‑filter под `listyb://…` (включая `host=app`, `host=list`, `host=home`) 

Подробная структура и роли слоёв — в `docs/architecture.md`. 

---

## Навигация и диплинки

### Поддерживаемые ссылки
- `listyb://home` → `/` (Домой).  
- `listyb://list/<id>` → `/list/:id`.  
- `listyb://list/<id>/add` → `/list/:id?qa=1` (**QuickAdd**).  
- Альтернативы с префиксом `host=app`: `listyb://app/...` также распознаются.  
  Нерелизовано в R1 (резерв): `listyb://item/<id>/edit`. 

### Android (Intent‑filter)
В `android/app/src/main/AndroidManifest.xml` у `MainActivity` добавлен `intent-filter` со **схемой** `listyb` и явными вариантами под:
- `host="app"` с `pathPrefix="/list"` и `path="/home"`
- `host="list"` с `pathPrefix="/"`
- `host="home"` (пустой путь)  
Это позволяет надёжно открывать `listyb://list/1`, `listyb://home` и формы `listyb://app/...` на большинстве устройств. 

### Маршрутизация и Back
Глобальный `redirect` в `go_router` приводит внешние URI к внутренним путям; `DeepLinkCoordinator`:
- **Cold start**: `getInitialLink()` → `router.go(...)`, добавляет служебные флаги: `?qa=1&autoclose=1` для QuickAdd, `&cold=1` для обычного входа на список.  
- **Hot start**: поток `uriLinkStream` → `router.push(...)` (без `cold`).  
Правила Back:
- Горячий диплинк на список: **Back** → Домой.
- Холодный диплинк на список: **Back** → закрыть приложение.
- QuickAdd (cold): по завершении — автозакрытие; (hot) — возвращение назад.  
Реализации: `lib/app/deeplinks.dart`, `lib/app/deeplink_parser.dart`, `lib/app/router.dart`, `lib/features/lists/presentation/list_details_screen.dart`. 

### Проверка через ADB
```bash
# Домой
adb shell am start -a android.intent.action.VIEW -d "listyb://home" com.yb.listyb

# Открыть список id=1
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1" com.yb.listyb

# Альтернатива с host=app
adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/1" com.yb.listyb

# QuickAdd в список id=1
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1/add" com.yb.listyb
```


---

## База данных (Drift)

### Схема (v1 → v2)
- **lists**: `id (PK, AUTOINC)`, `title TEXT`, `archived BOOL DEFAULT 0`, `sort_order INT DEFAULT 0`, `created_at`, `updated_at`.
- **items**: `id (PK, AUTOINC)`, `list_id (FK → lists.id ON DELETE CASCADE)`, `title TEXT`, `is_done BOOL DEFAULT 0`, `position INT DEFAULT 0`, `created_at`, `updated_at`, `completed_at?`, `note?` (добавлено в v2).  
Включены индексы и каскады; миграция **v1→v2** добавляет колонку `items.note`. В `beforeOpen` включены `foreign_keys`. См. `lib/data/db/app_database.dart`, `docs/db/schema.sql`, `docs/db-migrations.md`. 

---

## Сборка и запуск

### Требования
- Java 17, Android SDK (minSdk 26), Flutter stable. CI использует `actions/setup-java@v4` (Temurin 17) и `subosito/flutter-action@v2`. 

### Команды
```bash
# Установить зависимости
flutter pub get

# Анализ кода
flutter analyze

# Тесты
flutter test --reporter=expanded

# Build Runner (если потребуется пересборка генерации)
dart run build_runner build -d

# Сборка APK (debug|release)
flutter build apk --debug
# или
# flutter build apk --release
```


---

## CI (GitHub Actions)

Есть два workflow:
- `Flutter CI` — базовый пайплайн (analyze, test, debug apk).  
- `Android CI` — полный цикл для Android: format‑check, analyze, test, `flutter build apk --debug`, артефакты в `actions/upload-artifact`.  
Файлы: `.github/workflows/flutter.yml`, `.github/workflows/android.yml`. Добавь бэйдж позже при переносе в публичный репозиторий/актуальный путь workflow. 

---

## Документация

- `docs/r1-spec.md` — итоговое ТЗ R1 (объём фич, UX Undo, маршруты, диплинки). 
- `docs/navigation.md` — маршруты, нормализация URI, ADB примеры. 
- `docs/deeplinks.md` — схема диплинков, Intent‑filter, поведение Back и QuickAdd. 
- `docs/architecture.md` — слои, state‑mgmt, error handling. 
- `docs/i18n/keys.md` — ключи локализации. 
- `docs/checklist-release.md`, `docs/issues.md`, `docs/templates/*` — чек‑листы, планы итераций, команды. 

---

## Дорожная карта

### R1 (текущая)
- Drift БД v1/v2 (+ миграция `note`).  
- Домой/Список, QuickAdd, Undo (3 сек), корректный Back для диплинков.  
- Темы, заготовка Settings/i18n (RU/EN).  
- Тесты (unit/widget) и чистый `flutter analyze`.  
- CI собирает APK, артефакты загружаются. 

### Дальше (R2+)
- Расширение UI: фильтры/поиск, быстрые теги, локализация RU/EN/TR, переключатель темы в Settings.  
- Виджет Android (RemoteViews): заголовок с «+», до 20 активных элементов, «…» при >20, тап по элементу → компактные действия; запрет дубликатов конфигураций.  
- ACTION_SEND (share) → быстрый диалог добавления.  
- Экспорт/импорт, облако — позже. 

---

## Лицензия

MIT — см. `LICENSE`. 

---

## Полезные команды

```bash
# Генерация, линт, тесты
dart run build_runner build -d
dart format .
flutter analyze
flutter test

# Эмуляторы
flutter emulators
flutter emulators --launch <your_avd>
flutter run -d <device_id>

# Диплинки ADB
adb shell am start -a android.intent.action.VIEW -d "listyb://home" com.yb.listyb
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1" com.yb.listyb
adb shell am start -a android.intent.action.VIEW -d "listyb://list/1/add" com.yb.listyb
# Альтернатива:
adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/1" com.yb.listyb
```
