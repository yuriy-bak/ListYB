# Architecture

## Layers
- domain: entities, repositories (abstract), use-cases
- data: Drift DAOs, mappers, repository impl
- presentation: Riverpod providers, pages, widgets
- app: router/theme/localization bootstrap
- services/db: database init, migrations

## State
- Riverpod: stream providers for lists/items; action use-cases as providers
- Decoupled to allow future Signals migration

## Navigation
- go_router with routes: /, /list/:id, /settings, (/search opt.)

## Error Handling
- Domain errors mapped to user-friendly messages
- Transactions for reorder & cascade deletes
