#!/usr/bin/env python3
"""Quiet lifecycle state. Hooks never archive, commit, publish or grant permission."""
from __future__ import annotations

import contextlib
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


def read_json(path):
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def session_key(payload):
    if payload.get('session_id'):
        return 'session:' + str(payload['session_id'])
    if payload.get('transcript_path'):
        return 'transcript:' + hashlib.sha256(str(payload['transcript_path']).encode()).hexdigest()
    return 'date:' + datetime.now(timezone.utc).date().isoformat()


def command(payload):
    value = payload.get('tool_input') or {}
    return value if isinstance(value, str) else value.get('command', value.get('cmd', ''))


def response(payload):
    value = payload.get('tool_response', payload.get('tool_output', {}))
    if isinstance(value, str):
        match = re.search(r'(?:Process exited with code|exit code:)\s*(\d+)', value)
        return int(match[1]) if match else None, value
    if not isinstance(value, dict):
        return None, ''
    text = '\n'.join(str(value.get(k, '')) for k in ('output', 'stdout', 'stderr'))
    code = value.get('exit_code', value.get('exitCode'))
    if code is None and not value.get('interrupted') and re.search(r'\[[^\]\n]+ [0-9a-f]{7,40}\]', text):
        code = 0  # Claude Bash response may omit exit_code; require commit confirmation.
    return code, text


def invocations(text, root):
    """Recognize simple shell git invocations without executing shell text."""
    try:
        lexer = shlex.shlex(text, posix=True, punctuation_chars=';&|\n')
        lexer.whitespace = ' \t\r'
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return []
    segments, current = [], []
    for token in tokens + [';']:
        if token and all(c in ';&|\n' for c in token):
            if current:
                segments.append(current)
            current = []
        else:
            current.append(token)
    found = []
    cwd = root
    for args in segments:
        if args[:1] == ['cd'] and len(args) == 2 and not re.search(r'[$`]', args[1]):
            cwd = (cwd / args[1]).resolve()
            continue
        if not args or Path(args[0]).name != 'git':
            continue
        target, i = cwd, 1
        while i < len(args) and args[i].startswith('-'):
            if args[i] in {'-C', '-c'} and i + 1 < len(args):
                if args[i] == '-C':
                    if re.search(r'[$`]', args[i+1]):
                        break
                    target = (target / args[i+1]).resolve()
                i += 2
            else:
                break
        if i < len(args):
            found.append((target, args[i:], len(segments)))
    return found


def git(root, *args):
    result = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else ''


def skill_paths(root):
    claude = bool(os.getenv('CLAUDE_PLUGIN_ROOT')) and not (os.getenv('PLUGIN_ROOT') or os.getenv('CODEX_PLUGIN_ROOT'))
    paths = ['.claude/skills/project-skill/SKILL.md', '.agents/skills/project-skill/SKILL.md']
    if not claude:
        paths.reverse()
    return [p for p in paths if (root / p).is_file()]


def emit(event, message):
    if not message:
        return
    if os.getenv('CURSOR_PLUGIN_ROOT'):
        print(json.dumps({'additional_context': message}, ensure_ascii=False))
    else:
        print(json.dumps({'hookSpecificOutput': {'hookEventName': event, 'additionalContext': message}}, ensure_ascii=False))


@contextlib.contextmanager
def state_file(root):
    """Serialize updates and atomically replace only our state file."""
    lock = root / '.labmate-hook-state.lock'
    with lock.open('a+b') as handle:
        if os.name == 'nt':
            import msvcrt
            handle.write(b'0')
            handle.flush()
            handle.seek(0)
            msvcrt.locking(handle.fileno(), msvcrt.LK_LOCK, 1)
        else:
            import fcntl
            fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            path = root / '.labmate-hook-state.json'
            value = read_json(path)
            yield value
            fd, temp = tempfile.mkstemp(prefix='.labmate-state-', dir=root)
            try:
                with os.fdopen(fd, 'w') as stream:
                    json.dump(value, stream, ensure_ascii=False, indent=2)
                    stream.write('\n')
                os.replace(temp, path)
            finally:
                if os.path.exists(temp):
                    os.unlink(temp)
        finally:
            if os.name == 'nt':
                handle.seek(0)
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle, fcntl.LOCK_UN)


def pending(state):
    data = state.get('maintenance_v1')
    return data.get('pending', {}) if isinstance(data, dict) and isinstance(data.get('pending'), dict) else {}


def session_start(root):
    pipeline = read_json(root / '.pipeline-state.json')
    paths = skill_paths(root)
    items = pending(read_json(root / '.labmate-hook-state.json'))
    lines = []
    if pipeline:
        lines.append(f"LabMate state: exp={pipeline.get('current_exp') or 'none'}; stage={pipeline.get('stage', 'unknown')}.")
        if pipeline.get('skill_updated_at') is None:
            lines.append('Project knowledge: 尚未更新 (not refreshed yet).')
    if paths:
        lines.append('Project knowledge: ' + paths[0])
    if (root / 'docs/TODO.md').is_file() and (pipeline or paths):
        lines.append('Project tasks: docs/TODO.md')
    if items:
        lines.append(f'Pending maintenance: {len(items)} commit(s); details in .labmate-hook-state.json.')
    emit('SessionStart', '\n'.join(lines))


def docs_path(path):
    return path.startswith('docs/') or Path(path).suffix.lower() in {'.md', '.rst', '.txt'}


def record_commit(root, payload):
    code, output = response(payload)
    if code != 0 or re.search(r'nothing to commit|fatal:|error:|Aborting', output, re.I):
        return
    for target, args, segments in invocations(command(payload), root):
        if args[0] != 'commit' or any(x in args for x in ('--dry-run', '--help', '-h')):
            continue
        sha = git(target, 'rev-parse', 'HEAD')
        if not sha or (segments > 1 and not any(sha.startswith(x) for x in re.findall(r'\b[0-9a-f]{7,40}\b', output))):
            continue
        changed = git(target, 'diff-tree', '--root', '--no-commit-id', '--name-only', '-r', sha).splitlines()
        if not changed:
            continue
        # Do not create state in an ordinary repository without maintained surfaces.
        known = (target / 'CHANGELOG.md').is_file() or skill_paths(target) or (target / '.pipeline-state.json').is_file()
        if not known:
            continue
        with state_file(target) as state:
            data = state.setdefault('maintenance_v1', {'pending': {}, 'seen': [], 'notified': []})
            if not isinstance(data, dict) or not isinstance(data.get('pending'), dict) or not isinstance(data.get('seen'), list):
                continue  # preserve unknown/corrupt state; do not infer completion
            if sha in data['seen']:
                continue
            data['seen'] = (data['seen'] + [sha])[-256:]
            completed = set()
            if 'CHANGELOG.md' in changed:
                completed.add('changelog')
            if any(p in {'AGENTS.md', 'CLAUDE.md', 'README.md'} or p.startswith('docs/') for p in changed):
                completed.add('docs')
            if any('/skills/project-skill/' in p for p in changed):
                completed.add('project-skill')
            for prior, entry in list(data['pending'].items()):
                entry['items'] = [i for i in entry['items'] if i['path'] not in changed]
                if not entry['items']:
                    del data['pending'][prior]
            code_paths = [p for p in changed if not docs_path(p) and not p.startswith(('.agents/', '.claude/')) and p not in {'.pipeline-state.json', '.labmate-hook-state.json'}]
            if not code_paths:
                continue
            items = []
            if (target / 'CHANGELOG.md').is_file() and 'changelog' not in completed:
                items.append({'kind': 'changelog', 'path': 'CHANGELOG.md'})
            doc_targets = [p for p in ['AGENTS.md', 'CLAUDE.md', 'README.md'] if (target / p).is_file()]
            if doc_targets and 'docs' not in completed:
                items.append({'kind': 'docs', 'path': doc_targets[0]})
            paths = skill_paths(target)
            if paths and 'project-skill' not in completed:
                items.append({'kind': 'project-skill', 'path': paths[0]})
            if items:
                data['pending'][sha] = {'subject': git(target, 'log', '-1', '--format=%s'), 'changed': code_paths, 'items': items, 'session': session_key(payload)}


def compact(root, payload):
    if not pending(read_json(root / '.labmate-hook-state.json')):
        return
    with state_file(root) as state:
        data = state.get('maintenance_v1', {})
        key = session_key(payload)
        if key in data.get('notified', []) or not data.get('pending'):
            return
        data['notified'] = (data.get('notified', []) + [key])[-128:]
        lines = ['Pending maintenance review (no automatic archival or commit):']
        for sha, item in list(data['pending'].items())[-5:]:
            paths = ', '.join(i['path'] for i in item['items'])
            lines.append(f'- {sha[:8]}: {paths}; changed: {", ".join(item["changed"][:3])}')
        if len(data['pending']) > 5:
            lines.append('Additional entries are in .labmate-hook-state.json.')
        emit('PreCompact', '\n'.join(lines))


def advisory(root, payload):
    for _, args, _ in invocations(command(payload), root):
        destructive = ((args[0] == 'reset' and '--hard' in args)
                       or (args[0] == 'clean' and any(a.startswith('-') and 'f' in a for a in args[1:]))
                       or (args[0] == 'branch' and '-D' in args)
                       or (args[0] in {'checkout', 'restore'} and '--' in args))
        if destructive:
            emit('PreToolUse', 'Git advisory: check the exact target and recoverability; an isolated git worktree may help. This is an advisory, not a permission gate.')
            return


def main():
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            return 0
    except (ValueError, OSError):
        payload = {}
    root = Path(payload.get('cwd') or os.getcwd()).resolve()
    mode = sys.argv[1]
    tool_input = payload.get('tool_input')
    if mode in {'post-maintenance', 'worktree-suggest'} and isinstance(tool_input, dict) and tool_input.get('workdir'):
        root = (root / tool_input['workdir']).resolve()
    if mode == 'session-start':
        session_start(root)
    elif mode == 'post-maintenance':
        record_commit(root, payload)
    elif mode == 'pre-compact-summary':
        compact(root, payload)
    elif mode == 'worktree-suggest':
        advisory(root, payload)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
