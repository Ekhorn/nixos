# Tested on
# Zed 1.23.2 – /nix/store/6qgdyx85hkh9w7vj8aymjig5brdc8bin-zed-editor-1.23.2/libexec/zed-editor
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <old-path> <new-path>" >&2
  exit 1
fi

old_path=$1
new_path=$2

threads_db="$HOME/.local/share/zed/threads/threads.db"
sidebar_db="$HOME/.local/share/zed/db/0-stable/db.sqlite"

for db in "$threads_db" "$sidebar_db"; do
  if [[ ! -f $db ]]; then
    echo "error: $db not found" >&2
    exit 1
  fi
done

echo "threads affected: $(sqlite3 "$threads_db" "SELECT COUNT(*) FROM threads WHERE folder_paths = '${old_path}';")"
sqlite3 "$threads_db" "
UPDATE threads
SET folder_paths = '${new_path}'
WHERE folder_paths = '${old_path}';
"

echo "sidebar_threads affected: $(sqlite3 "$sidebar_db" "SELECT COUNT(*) FROM sidebar_threads WHERE folder_paths = '${old_path}' OR main_worktree_paths = '${old_path}';")"
sqlite3 "$sidebar_db" "
UPDATE sidebar_threads
SET folder_paths = CASE WHEN folder_paths = '${old_path}' THEN '${new_path}' ELSE folder_paths END,
    main_worktree_paths = CASE WHEN main_worktree_paths = '${old_path}' THEN '${new_path}' ELSE main_worktree_paths END
WHERE folder_paths = '${old_path}'
   OR main_worktree_paths = '${old_path}';
"
