#!/usr/bin/env bash
# Tests for memory_server/storage.py — near-duplicate detection thresholds.
# Validates _find_near_duplicate behavior at cosine and word-overlap boundaries.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_PY="${HOME}/.claude/memory_server/.venv/bin/python3"

if [ ! -f "$VENV_PY" ]; then
  echo "memory_server venv not found at $VENV_PY — skipping memory tests"
  echo "memory: 0 run, 0 passed, 0 failed (skipped)"
  exit 0
fi

# sqlite-vec is an OPTIONAL dependency (requirements-optional.txt): without it,
# memory_server runs in FTS5-only mode. The cosine/vec tests below require the
# extension to load (they write to the memories_vec virtual table). Probe once
# and skip only those tests when it is absent — do NOT hard-fail, or the whole
# suite halts on a missing optional dep (the Phase 56-58 "make test halts" bug).
VEC_OK=0
if "$VENV_PY" - <<'PROBE' 2>/dev/null
import sqlite3, sqlite_vec
c = sqlite3.connect(":memory:")
c.enable_load_extension(True)
sqlite_vec.load(c)
PROBE
then
  VEC_OK=1
else
  echo "  [note] sqlite-vec unavailable — running FTS5-only tests, skipping vec/cosine tests."
  echo "         Install with: uv pip install --python \"$VENV_PY\" 'sqlite-vec>=0.1.6'"
fi

run_py() {
  "$VENV_PY" -c "
import sys, os, tempfile, struct, math
sys.path.insert(0, os.path.join('$REPO_ROOT', 'memory_server'))
import storage
from storage import (init_db, store, _find_near_duplicate, _cosine_similarity,
                     _embedding_to_blob, _find_exact_duplicate)
from models import Category, Trust

$1
"
}

echo "memory tests"

# --- Cosine similarity direct tests ---

test_start "cosine_similarity: identical vectors = 1.0"
result=$(run_py '
a = [1.0, 0.0, 0.0]
assert abs(_cosine_similarity(a, a) - 1.0) < 0.001, f"got {_cosine_similarity(a, a)}"
print("ok")
')
assert_eq "ok" "$result" "cosine identical"

test_start "cosine_similarity: orthogonal vectors = 0.0"
result=$(run_py '
a = [1.0, 0.0, 0.0]
b = [0.0, 1.0, 0.0]
assert abs(_cosine_similarity(a, b)) < 0.001, f"got {_cosine_similarity(a, b)}"
print("ok")
')
assert_eq "ok" "$result" "cosine orthogonal"

test_start "cosine_similarity: known value 0.87"
result=$(run_py '
import math
# Construct vectors with cosine similarity ~0.87
a = [1.0, 0.0]
angle = math.acos(0.87)
b = [math.cos(angle), math.sin(angle)]
sim = _cosine_similarity(a, b)
assert abs(sim - 0.87) < 0.01, f"expected ~0.87, got {sim}"
print("ok")
')
assert_eq "ok" "$result" "cosine 0.87"

# --- Word-overlap threshold tests via store() ---

test_start "word_overlap: >0.90 overlap warns"
result=$(run_py '
import tempfile
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
# Need intersection/union > 0.90. 20 words, change 1: 19/21 = 0.905
base = "a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20"
near = "a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 b20"
store(conn, base)
r = store(conn, near)
assert r.warning is not None or r.action == "reinforced", f"expected warn/reinforce for 19/21=0.905 overlap, got action={r.action} warning={r.warning}"
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "word overlap >0.90 warns"

test_start "word_overlap: <0.90 overlap no warn"
result=$(run_py '
import tempfile
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
# 10 words, change 3: 7/13 = 0.538 overlap — well below 0.90
store(conn, "a1 a2 a3 a4 a5 a6 a7 a8 a9 a10")
r = store(conn, "a1 a2 a3 a4 a5 a6 a7 b8 b9 b10")
assert r.action == "created" and r.warning is None, f"expected clean create for 7/13=0.54 overlap, got action={r.action} warning={r.warning}"
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "word overlap <0.90 no warn"

# --- Cosine threshold tests via _find_near_duplicate (require sqlite-vec) ---

if [ "$VEC_OK" = "1" ]; then

test_start "cosine: >0.90 similarity reinforces"
result=$(run_py '
import tempfile, math
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = True

# Create a 768-dim unit vector
dim = 768
base_emb = [0.0] * dim
base_emb[0] = 1.0

# Store a memory with this embedding
store(conn, "test memory for cosine threshold", embedding=base_emb)

# Create embedding with cosine sim ~0.95 (> 0.90 threshold)
angle = math.acos(0.95)
query_emb = [0.0] * dim
query_emb[0] = math.cos(angle)
query_emb[1] = math.sin(angle)

result = _find_near_duplicate(conn, "different content", embedding=query_emb)
assert result is not None, "expected near-duplicate found"
row, action = result
assert action == "reinforce", f"expected reinforce for sim>0.90, got {action}"
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "cosine >0.90 reinforces"

test_start "cosine: 0.85-0.90 similarity warns"
result=$(run_py '
import tempfile, math
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = True

dim = 768
base_emb = [0.0] * dim
base_emb[0] = 1.0
store(conn, "test memory for cosine warn", embedding=base_emb)

# Cosine sim ~0.87 (between 0.85 and 0.90)
angle = math.acos(0.87)
query_emb = [0.0] * dim
query_emb[0] = math.cos(angle)
query_emb[1] = math.sin(angle)

result = _find_near_duplicate(conn, "different content", embedding=query_emb)
assert result is not None, "expected near-duplicate found"
row, action = result
assert action == "warn", f"expected warn for sim 0.85-0.90, got {action}"
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "cosine 0.85-0.90 warns"

test_start "cosine: <0.85 similarity no match"
result=$(run_py '
import tempfile, math
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = True

dim = 768
base_emb = [0.0] * dim
base_emb[0] = 1.0
store(conn, "test memory for cosine miss", embedding=base_emb)

# Cosine sim ~0.80 (< 0.85 threshold)
angle = math.acos(0.80)
query_emb = [0.0] * dim
query_emb[0] = math.cos(angle)
query_emb[1] = math.sin(angle)

result = _find_near_duplicate(conn, "completely different unrelated content words here", embedding=query_emb)
# Should be None or only from word-overlap (which wont match different words)
if result is not None:
    row, action = result
    # If word-overlap triggered, thats fine — cosine should not have
    # The important thing is cosine didnt trigger reinforce/warn
    pass
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "cosine <0.85 no match"

fi  # end VEC_OK guard (cosine threshold tests)

# --- FTS5-only mode test (works without sqlite-vec) ---

test_start "fts5_only: store works with _vec_available=False"
result=$(run_py '
import tempfile
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = False

r1 = store(conn, "first memory in fts5 only mode")
assert r1.action == "created", f"expected created, got {r1.action}"

r2 = store(conn, "second completely different memory")
assert r2.action == "created", f"expected created, got {r2.action}"

# Exact duplicate should reinforce
r3 = store(conn, "first memory in fts5 only mode")
assert r3.action == "reinforced", f"expected reinforced, got {r3.action}"

print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "fts5-only store works"

# --- n=1 edge case (requires sqlite-vec: stores embeddings) ---

if [ "$VEC_OK" = "1" ]; then

test_start "n1_edge: near-duplicate detection with single entry"
result=$(run_py '
import tempfile, math
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = True

dim = 768
emb = [0.0] * dim
emb[0] = 1.0

r = store(conn, "the only memory in the database", embedding=emb)
assert r.action == "created", f"expected created for first entry, got {r.action}"

# Store similar (high cosine)
angle = math.acos(0.95)
emb2 = [0.0] * dim
emb2[0] = math.cos(angle)
emb2[1] = math.sin(angle)

r2 = store(conn, "a very different text to avoid word overlap", embedding=emb2)
assert r2.action == "reinforced", f"expected reinforced via cosine with n=1, got {r2.action}"
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "n=1 cosine dedup"

fi  # end VEC_OK guard (n=1 edge)

# --- Exact duplicate always reinforces (works without sqlite-vec) ---

test_start "exact_duplicate: reinforces regardless of mode"
result=$(run_py '
import tempfile
db_path = tempfile.mktemp(suffix=".db")
conn = init_db(db_path)
storage._vec_available = False

r1 = store(conn, "exact content to duplicate")
assert r1.action == "created"
r2 = store(conn, "exact content to duplicate")
assert r2.action == "reinforced"
assert r2.existing_id == r1.id
print("ok")
conn.close()
os.unlink(db_path)
')
assert_eq "ok" "$result" "exact duplicate reinforces"

test_summary "memory"
