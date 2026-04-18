#!/usr/bin/env python3
"""
Claude Code hook: writes per-session working/idle state to
~/.claude/sessions-state/<session_id>.json so external tools (like the
Claude Sessions menu bar app) can read an authoritative status, including
during thinking (before any token hits the transcript).

Dispatched by ~/.claude/sessions-state is updated atomically via
temp-file + rename to avoid partial reads.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import time
from pathlib import Path

STATE_DIR = Path.home() / ".claude" / "sessions-state"


def load(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def save(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".tmp-", suffix=".json")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(state, f, separators=(",", ":"))
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    session_id = data.get("session_id")
    if not session_id:
        return 0

    event = data.get("hook_event_name", "")
    state_file = STATE_DIR / f"{session_id}.json"
    state = load(state_file)
    now = time.time()

    state["session_id"] = session_id
    state["cwd"] = data.get("cwd", state.get("cwd", ""))
    state["transcript_path"] = data.get(
        "transcript_path", state.get("transcript_path", "")
    )
    state["last_event"] = event
    state["updated_at"] = now

    if event == "SessionStart":
        state.setdefault("started_at", now)
        state["working"] = False
        state["source"] = data.get("source", state.get("source", ""))
        if "model" in data:
            state["model"] = data["model"]
    elif event == "UserPromptSubmit":
        state["working"] = True
        state["working_since"] = now
    elif event == "Stop":
        state["working"] = False
        state["stopped_at"] = now
    elif event == "SubagentStop":
        # Don't flip the parent's working flag — a subagent finishing
        # doesn't mean the main turn is done.
        state["last_subagent_stop_at"] = now
    elif event == "PreToolUse":
        state["working"] = True
        state["last_tool"] = data.get("tool_name", "")
        state["last_tool_at"] = now
    elif event == "PostToolUse":
        state["last_tool"] = data.get("tool_name", "")
        state["last_tool_at"] = now
    elif event == "SessionEnd":
        try:
            state_file.unlink()
        except FileNotFoundError:
            pass
        return 0

    save(state_file, state)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # Hooks must never fail the assistant's turn.
        sys.exit(0)
