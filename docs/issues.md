# Issues Templates (short)

## R1-01: Drift DB (v1)
**Tasks:** add deps, DB init, tables, DAOs, migrations, test seed  
**AC:** CRUD via DAO, stream queries, transactions for reorder  
**Tests:** create/delete list with items (cascade), reorder positions

## R1-02: Repositories & Use-cases
**Tasks:** abstract repos (domain), impl (data), mappers, Riverpod providers  
**AC:** UI only talks to use-cases; validation on titles  
**Tests:** happy & edge cases (empty/long titles)

## R1-03: Router & Deep Links
**AC:** listyb://home, listyb://list/:id work cold/hot; back stack sane

## R1-04: UI Home
**AC:** cards with counts, create/rename/archive/delete, empty state  
**Undo:** Snackbar (3s) for delete/archive with [Отменить]

## R1-05: UI ListDetails
**AC:** quick add, checkbox, filters, search, DnD, long-press menu  
**Undo:** Snackbar (3s) for delete/archive with [Отменить]

## R1-06: Settings + i18n
**AC:** theme switch, RU/EN toggle, strings all localized

## R1-07: Tests & Lint
**AC:** unit + widget pass; analyze clean

## R1-08: Android CI
**AC:** build release APK, artifact uploaded