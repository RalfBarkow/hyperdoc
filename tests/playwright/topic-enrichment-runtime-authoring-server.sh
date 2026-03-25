#!/bin/zsh

set -euo pipefail

fixture_root="${HYPERDOC_TOPIC_ENRICHMENT_PLAYWRIGHT_ROOT:-$(mktemp -d "${TMPDIR:-/tmp}/hyperdoc-topic-enrichment-playwright.XXXXXX")}"
db_path="${fixture_root}/zotero.sqlite"
storage_root="${fixture_root}/storage"
route_data_path="${fixture_root}/topic-enrichment-route-data.lisp"

mkdir -p "${storage_root}"

cat > "${route_data_path}" <<'EOF'
(in-package :hyperdoc)

(defparameter *topic-enrichment-route-definitions*
  '())
EOF

sqlite3 "${db_path}" <<'SQL'
BEGIN;
CREATE TABLE itemTypes (itemTypeID INTEGER PRIMARY KEY, typeName TEXT);
CREATE TABLE items (
  itemID INTEGER PRIMARY KEY,
  itemTypeID INT NOT NULL,
  dateAdded TIMESTAMP NOT NULL,
  dateModified TIMESTAMP NOT NULL,
  clientDateModified TIMESTAMP NOT NULL,
  libraryID INT NOT NULL,
  key TEXT NOT NULL
);
CREATE TABLE fields (fieldID INTEGER PRIMARY KEY, fieldName TEXT);
CREATE TABLE itemDataValues (valueID INTEGER PRIMARY KEY, value TEXT);
CREATE TABLE itemData (itemID INT, fieldID INT, valueID INT);

INSERT INTO itemTypes VALUES (5, 'journalArticle');

INSERT INTO fields VALUES (1, 'title');
INSERT INTO fields VALUES (2, 'DOI');
INSERT INTO fields VALUES (3, 'citationKey');
INSERT INTO fields VALUES (4, 'date');

INSERT INTO items VALUES (501, 5, '2026-03-25 08:00:00', '2026-03-25 08:10:00', '2026-03-25 08:10:01', 1, 'CHUNK001');
INSERT INTO items VALUES (502, 5, '2026-03-25 09:00:00', '2026-03-25 09:10:00', '2026-03-25 09:10:01', 1, 'BASIS001');

INSERT INTO itemDataValues VALUES (1, 'Chunk');
INSERT INTO itemDataValues VALUES (2, '10.5555/chunk.1977');
INSERT INTO itemDataValues VALUES (3, 'mcdermottChunk1977');
INSERT INTO itemDataValues VALUES (4, '1977');
INSERT INTO itemDataValues VALUES (5, 'Basis');
INSERT INTO itemDataValues VALUES (6, '10.5555/basis.1977');
INSERT INTO itemDataValues VALUES (7, 'mcdermottBasis1977');
INSERT INTO itemDataValues VALUES (8, '1977');

INSERT INTO itemData VALUES (501, 1, 1);
INSERT INTO itemData VALUES (501, 2, 2);
INSERT INTO itemData VALUES (501, 3, 3);
INSERT INTO itemData VALUES (501, 4, 4);

INSERT INTO itemData VALUES (502, 1, 5);
INSERT INTO itemData VALUES (502, 2, 6);
INSERT INTO itemData VALUES (502, 3, 7);
INSERT INTO itemData VALUES (502, 4, 8);
COMMIT;
SQL

export HYPERDOC_ENABLE_ZOTERO=1
export HYPERDOC_ZOTERO_DB_PATH="${db_path}"
export HYPERDOC_ZOTERO_STORAGE_ROOT="${storage_root}"
export HYPERDOC_TOPIC_ENRICHMENT_ROUTE_DATA_PATH="${route_data_path}"
export HYPERDOC_RUN_TOUCH_FAHRPLAN_RUNTIME_TEST=1

echo "[topic-enrichment-playwright] fixture_root=${fixture_root}"
echo "[topic-enrichment-playwright] route_data_path=${route_data_path}"

exec nix run .
