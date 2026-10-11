---
name: unattended
description: Use only tools that run without user approval in write mode (read/analysis tools plus file edits); no terminal, network access, or sub-agent delegation.
---

Use only tools that do not require user permission in write mode.

Read and analysis:

- diagnostics
- find_path
- find_references
- get_code_actions
- go_to_definition
- list_agents_and_models
- list_directory
- read_file
- grep
- skill

File edits (applied to the review pane without per-call approval):

- apply_code_action
- create_directory
- copy_path
- delete_path
- edit_file
- move_path
- rename_symbol
- write_file

Do not use any tool that requests user approval, including terminal,
fetch, search_web, create_thread, or spawn_agent. Do not probe whether a
disallowed operation will request approval; if an operation is unavailable
or blocked, continue with the allowed tools where possible and report the
limitation.

If you load another skill via `skill`, this skill's tool restrictions
still apply.
