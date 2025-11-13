# Use-cases (Application Layer)

## Lists
- CreateList(title)
- RenameList(listId, title)
- ArchiveList(listId, archived)
- DeleteList(listId)
- WatchLists(includeArchived=false)
- GetListCounts(listId) -> (items, open)

## Items
- AddItem(listId, title)
- UpdateItem(item) [title, note, dueAt]
- ToggleItem(itemId, completed)
- ReorderItems(listId, orderedItemIds)
- DeleteItem(itemId)
- WatchItems(listId)                                       # «сырые» элементы без фильтра/поиска
- WatchItemsFiltered(listId, query?, completed?)           # фильтры + строка поиска

``