
'DOC'
# Deep Links и Intents (R1)

## Схемы
- Custom scheme: `listyb://`
- Пример: `listyb://list/:id`

## Android Intents
- ACTION_SEND (text/plain) → диалог «Добавить как новый элемент» с выбором списка.

## Тестирование
- adb: `adb shell am start -a android.intent.action.VIEW -d "listyb://list/123"`
DOC
