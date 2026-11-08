---
name: unattended
description: Use only tools that run without user approval in write mode (read/analysis tools plus file edits); no terminal, network access, or sub-agent delegation.
---

Use only tools that do not require user permission in write mode.

Allowed (no user approval required):

@allowed@

Do not use (requires user approval or is denied):

@notAllowed@

Do not use `spawn_agent`, `ask_user`, or `create_thread`: sub-agent delegation,
asking the user, and spawning new threads do not complete unattended.

Do not probe whether a disallowed operation will request approval; if an
operation is unavailable or blocked, continue with the allowed tools where
possible and report the limitation.
