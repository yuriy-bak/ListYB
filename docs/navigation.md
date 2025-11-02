# Navigation & Deep Links

## Routes
/ → HomePage
/list/:id → ListDetailsPage
/settings → SettingsPage
/search → (optional)

## Deep Links
listyb://home → /
listyb://list/<id> → /list/:id
listyb://search?q=<query> → /search?q=...

## AndroidManifest (intent-filter)
(см. README или основной spec)

## Back stack rules
- Deep link should open screen correctly for cold/hot start
- Back navigates to Home when appropriate