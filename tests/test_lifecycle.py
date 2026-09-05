"""Direct handler integration with temporary repositories and real git commits."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('lifecycle', ROOT / 'scripts/lifecycle.py')
life = importlib.util.module_from_spec(spec)
spec.loader.exec_module(life)


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, path, text):
        file = self.root / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(text)

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True, stderr=subprocess.STDOUT).strip()

    def init_repo(self):
        self.git('init', '-q')
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.invalid')
        for path in ['CHANGELOG.md', 'AGENTS.md', '.agents/skills/project-skill/SKILL.md']:
            self.write(path, '# Base\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'docs: base')

    def run_hook(self, handler, payload=None, **env):
        clean = {k:v for k,v in os.environ.items() if k not in {'PLUGIN_ROOT','CODEX_PLUGIN_ROOT','CLAUDE_PLUGIN_ROOT','CURSOR_PLUGIN_ROOT'}}
        result = subprocess.run(['bash', str(ROOT/'hooks'/handler)], input=json.dumps(payload or {}), cwd=self.root,
                                env={**clean, **env}, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout) if result.stdout.strip() else None

    def context(self, result, event):
        self.assertEqual(result['hookSpecificOutput']['hookEventName'], event)
        return result['hookSpecificOutput']['additionalContext']

    def commit_payload(self, field='cmd', response='tool_response'):
        self.write('sample.py', 'print(1)\n')
        self.git('add', 'sample.py')
        output = self.git('commit', '-m', 'feat: sample')
        return {'session_id':'s1', 'tool_input':{field:'git commit -m "feat: sample"'}, response:{'exit_code':0,'stdout':output}}

    def state(self):
        return json.loads((self.root/'.labmate-hook-state.json').read_text())['maintenance_v1']

    def test_command_paths_newlines_and_corrupt_state(self):
        commands=life.invocations('cd nested\ngit -C child commit -m done',self.root)
        self.assertEqual(commands[0][0],(self.root/'nested/child').resolve())
        self.init_repo()
        payload=self.commit_payload()
        payload['tool_input']['workdir']=str(self.root)
        payload['cwd']=str(self.root.parent)
        self.run_hook('post-maintenance',payload)
        self.assertTrue(self.state()['pending'])
        self.write('.labmate-hook-state.json','{"maintenance_v1": null}')
        self.assertIsNone(self.run_hook('pre-compact-summary',{}))
        self.run_hook('post-maintenance',payload)
        self.assertIsNone(json.loads((self.root/'.labmate-hook-state.json').read_text())['maintenance_v1'])

    def test_four_handlers(self):
        hooks = json.loads((ROOT/'hooks/hooks.json').read_text())['hooks']
        handlers = [x['command'].split()[-1] for entries in hooks.values() for e in entries for x in e['hooks']]
        self.assertEqual(set(handlers), {'session-start','post-maintenance','pre-compact-summary','worktree-suggest'})
        self.assertEqual(len(handlers),4)

    def test_session_surfaces_and_null(self):
        self.write('.pipeline-state.json', '{"stage":"analysis","skill_updated_at":null}')
        self.write('docs/TODO.md', '# Tasks')
        for host in ['.agents', '.claude']:
            self.write(f'{host}/skills/project-skill/SKILL.md', '# Knowledge')
        text = self.context(self.run_hook('session-start', PLUGIN_ROOT=str(ROOT), CLAUDE_PLUGIN_ROOT=str(ROOT)), 'SessionStart')
        self.assertIn('.agents/skills',text)
        self.assertIn('尚未更新',text)
        self.assertIn('docs/TODO.md',text)
        text = self.context(self.run_hook('session-start', CLAUDE_PLUGIN_ROOT=str(ROOT)), 'SessionStart')
        self.assertIn('.claude/skills',text)
        (self.root/'.claude/skills/project-skill/SKILL.md').unlink()
        self.assertIn('.agents/skills',self.context(self.run_hook('session-start', CLAUDE_PLUGIN_ROOT=str(ROOT)),'SessionStart'))
        self.assertIn('additional_context',self.run_hook('session-start', CURSOR_PLUGIN_ROOT=str(ROOT)))

    def test_ordinary_directory_and_tools_are_quiet(self):
        self.assertIsNone(self.run_hook('session-start'))
        for cmd in ['cat README.md','git status','echo "git commit -m fake"','python analyze.py', '*** Begin Patch\n*** Add File: docs/spec.md\n+x\n*** End Patch']:
            self.assertIsNone(self.run_hook('post-maintenance',{'tool_input':cmd,'tool_response':{'exit_code':0}}))
        self.assertIsNone(self.run_hook('pre-compact-summary'))
        self.assertEqual(list(self.root.iterdir()), [])

    def test_record_and_dedupe_session(self):
        self.init_repo()
        payload = self.commit_payload()
        self.assertIsNone(self.run_hook('post-maintenance',payload))
        self.run_hook('post-maintenance',payload)
        self.assertEqual(len(self.state()['pending']),1)
        items = next(iter(self.state()['pending'].values()))['items']
        self.assertEqual({i['kind'] for i in items},{'changelog','docs','project-skill'})
        self.assertIn('sample.py',self.context(self.run_hook('pre-compact-summary',{'session_id':'s1'}),'PreCompact'))
        self.assertIsNone(self.run_hook('pre-compact-summary',{'session_id':'s1'}))
        self.assertIsNotNone(self.run_hook('pre-compact-summary',{'session_id':'s2'}))
        self.assertIsNotNone(self.run_hook('pre-compact-summary',{'transcript_path':'/tmp/t'}))
        self.assertIsNone(self.run_hook('pre-compact-summary',{'transcript_path':'/tmp/t'}))
        self.assertIsNotNone(self.run_hook('pre-compact-summary'))
        self.assertIsNone(self.run_hook('pre-compact-summary'))

    def test_failed_dry_run_and_masked_failure(self):
        self.init_repo()
        payload = self.commit_payload()
        payload['tool_response']['exit_code'] = 1
        self.assertIsNone(self.run_hook('post-maintenance',payload))
        self.assertFalse((self.root/'.labmate-hook-state.json').exists())
        for cmd in ['git commit --dry-run','git commit -m fail; true']:
            self.run_hook('post-maintenance',{'tool_input':{'cmd':cmd},'tool_response':{'exit_code':0,'stdout':'nothing to commit'}})
        self.assertFalse((self.root/'.labmate-hook-state.json').exists())

    def test_claude_payload_and_docs_completion(self):
        self.init_repo()
        payload = self.commit_payload('command','tool_output')
        del payload['tool_output']['exit_code']
        self.run_hook('post-maintenance',payload)
        self.assertTrue(self.state()['pending'])
        for path in ['CHANGELOG.md','AGENTS.md','.agents/skills/project-skill/SKILL.md']:
            self.write(path,'# Updated\n')
        self.git('add','.')
        output = self.git('commit','-m','docs: close maintenance')
        self.run_hook('post-maintenance',{'tool_input':{'command':'git commit -m docs'},'tool_response':{'exit_code':0,'output':output}})
        self.assertFalse(self.state()['pending'])

    def test_docs_only_commit_no_pending(self):
        self.init_repo()
        self.write('AGENTS.md','# Changed')
        self.git('add','AGENTS.md')
        self.git('commit','-qm','docs: instructions')
        self.run_hook('post-maintenance',{'tool_input':{'cmd':'git commit -qm docs'},'tool_response':{'exit_code':0}})
        self.assertFalse(self.state()['pending'])

    def test_git_advisory(self):
        for key in ['cmd','command']:
            result = self.run_hook('worktree-suggest',{'tool_input':{key:'git -C . reset --hard HEAD~1'}})
            self.assertIn('not a permission gate', self.context(result,'PreToolUse'))
        self.assertIsNone(self.run_hook('worktree-suggest',{'tool_input':'echo "git reset --hard"'}))
        self.assertIsNone(self.run_hook('worktree-suggest',{'tool_input':{'cmd':'git status'}}))


if __name__ == '__main__':
    unittest.main()
