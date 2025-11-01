# ListYB

## Current Iteration Context (R1)

### Short Context
Context: ListYB R1 — Android local (без Isar)
Repo: https://github.com/yuriy-bak/ListYB
App: ListYB (package: com.yb.listyb), Deep links: listyb://
minSdk: 26

Статус:
- Архитектура, роутинг (go_router), темы (FlexColorScheme), экраны-заглушки.
- Хранилище: In-memory репозиторий.
- Freezed/json_serializable подключены.
- Исключено: isar / isar_flutter_libs / isar_generator.

Проверка:
- build_runner: flutter pub run build_runner build --delete-conflicting-outputs
- запуск: flutter run
- диплинк: adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/demo" com.yb.listyb

---

### Detailed Context
Project: ListYB
Repo: https://github.com/yuriy-bak/ListYB
Bundle/Id: com.yb.listyb
Deep links: listyb://app, listyb://app/list/:id
minSdk: 26
Target: Android (приоритет), Desktop/Web — для отладки UI.

R1:
- Dependencies: go_router, flutter_riverpod, freezed_annotation, json_annotation, collection, intl, shared_preferences, url_launcher, flex_color_scheme, logger, package_info_plus, uni_links
- Dev deps: build_runner, freezed, json_serializable
- Архитектура папок: lib/app, lib/core/utils, lib/features/{lists,settings,about,import_export}, bootstrap.dart, main.dart
- Роуты: '/', '/list/:id', '/settings', '/about', '/import'
- AndroidManifest: intent-filter для listyb://app
- Repo: InMemoryListsRepo с демо-данными (listId=demo)

---

### Plan R2
- Drift/SQLite:
  - runtime: drift, sqlite3, sqlite3_flutter_libs
  - dev: drift_dev, build_runner
- Структура: lib/core/db/drift/{database.dart,tables/*.dart,daos/*.dart}
- Функции: CRUD в ListDetails, фильтры, быстрые теги, локализация (ru/en/tr), переключатель темы.


## Run on Android emulator / Deep links

**Run:**
```bash
flutter emulators --launch <your_avd_name>
flutter run -d <emulator_id>
```

**Check the deep link:**
```bash
adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/demo" com.yb.listyb
```

> Требования: в `android/app/build.gradle` задано
> `namespace "com.yb.listyb"` и `applicationId "com.yb.listyb"`.
> В `AndroidManifest.xml` внутри `MainActivity` добавлен `<intent-filter>`
> со схемой `listyb`, хостом `app` и `pathPrefix="/list"`.
