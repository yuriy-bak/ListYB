-- Drift Schema v1 for ListYB

CREATE TABLE lists (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  archived_at INTEGER NULL
);

CREATE TABLE items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  list_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  note TEXT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  due_at INTEGER NULL,
  position INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE
);

CREATE INDEX idx_items_list ON items(list_id);
CREATE INDEX idx_items_list_completed ON items(list_id, completed);
CREATE INDEX idx_items_list_position ON items(list_id, position);