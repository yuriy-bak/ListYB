
```bash


dart run build_runner build -d

flutter analyze
flutter test
dart format .

# Показать список доступных эмуляторов
flutter emulators

# Запустить конкретный эмулятор (например, Pixel_9_API_31)
flutter emulators --launch Pixel_9_API_31

# После того как эмулятор запущен:
flutter run

# диплинк:
adb shell am start -a android.intent.action.VIEW -d "listyb://app/list/demo" com.yb.listyb

### Если несколько устройств
# Посмотреть список:
flutter devices

# Запустить на конкретном:
flutter run -d emulator-5554

# (`emulator-5554` — это ID из списка `flutter devices`).

---

### 4. Горячая перезагрузка и перезапуск
- **Hot reload**: `r` в консоли, когда `flutter run` активен.
- **Hot restart**: `R`.


# После завершения этапа, коммитим:

# git switch feature/data-drift
git add .
git commit -m "R1-01: Drift DB (v1) implementation"
git push origin feature/data-drift

```