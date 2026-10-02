#!/usr/bin/env python3
"""Formats `claude -p --output-format stream-json --verbose` for the demo recording."""
import getpass
import json
import os
import sys

DIM, CYAN, RED, RESET = "\033[2m", "\033[36m", "\033[31m", "\033[0m"
MAX_RESULT_LINES = 3
HOME = os.path.expanduser("~")


USER = getpass.getuser()


def emit(text):
    print(text.replace(HOME, "~").replace(f" {USER} ", " user "), flush=True)


def tool_label(name, args):
    if name == "Bash":
        return f"Bash({args.get('command', '').splitlines()[0]})"
    if name in ("Read", "Write", "Edit"):
        return f"{name}({args.get('file_path', '').rsplit('/', 1)[-1]})"
    if name == "Skill":
        return f"Skill({args.get('skill', args.get('command', ''))})"
    return name


def result_text(content):
    if isinstance(content, list):
        content = "\n".join(c.get("text", "") for c in content if isinstance(c, dict))
    return str(content).strip()


for raw in sys.stdin:
    try:
        event = json.loads(raw)
    except json.JSONDecodeError:
        continue
    message = event.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    for block in content if isinstance(content, list) else []:
        if not isinstance(block, dict):
            continue
        kind = block.get("type")
        if event.get("type") == "assistant" and kind == "text" and block["text"].strip():
            emit(f"\n{block['text'].strip()}\n")
        elif kind == "tool_use":
            label = tool_label(block["name"], block.get("input") or {})
            emit(f"{CYAN}⏺{RESET} {label if len(label) <= 96 else label[:95] + '…'}")
        elif kind == "tool_result":
            lines = [line for line in result_text(block.get("content")).splitlines() if line.strip()]
            colour = RED if block.get("is_error") else DIM
            shown = lines[:MAX_RESULT_LINES]
            if len(lines) > MAX_RESULT_LINES:
                shown.append(f"… +{len(lines) - MAX_RESULT_LINES} lines")
            for line in shown:
                emit(f"  {colour}⎿  {line[:94]}{RESET}")
    if event.get("type") == "result" and event.get("is_error"):
        emit(f"{RED}{event.get('result', 'error')}{RESET}")
