# Tutorial: your first experiment

This walks you through a complete research cycle with LabMate, from install to analysis slides. Takes about 10 minutes.

## 0. Install

Claude Code interactive commands:

```text
/plugin marketplace add freemty/labmate-marketplace
/plugin install labmate@labmate-marketplace
```

Codex terminal commands, from a `yuanbo-skills` checkout:

```bash
codex plugin marketplace add /path/to/yuanbo-skills
codex plugin add labmate@yuanbo-skills
```

Open your agentic coding tool in the project directory. Claude Code invokes
skills as `/labmate:<skill>`; Codex uses `$labmate:<skill>` or `/skills`.
Other Agent Skills hosts can be asked to use a LabMate skill by name.

## 1. Initialize your project

Use LabMate's `init-project` skill.

LabMate infers the project information and asks you to confirm it:

```
LabMate:
- Project: my-nlp-project
- Description: Comparing prompt strategies for classification tasks
- Domain: NLP
- Compute environment: local
- Type: research

you: looks right
```

After answering, LabMate creates:

```
my-nlp-project/
├── exp/
│   ├── summary.md          # cross-experiment overview (empty for now)
│   └── .gitkeep
├── docs/
│   ├── papers/
│   │   ├── landscape.md    # literature map placeholder
│   │   └── .gitkeep
│   ├── specs/
│   ├── weekly/
│   └── archive/
├── scripts/
│   ├── launch_exp.py
│   ├── monitor_exp.sh
│   └── download_results.sh
├── viewer/
│   └── app.py
├── slides/
├── CLAUDE.md or AGENTS.md  # your research hub — principles, roles, workflow
└── .pipeline-state.json    # tracks current experiment + stage
```

Commit this: `git add -A && git commit -m "feat: init research skeleton"`

## 2. Create your first experiment

Use LabMate's `new-experiment` skill.

LabMate asks what you want to test. Say something like:

```
you: I want to compare zero-shot vs few-shot prompting on a sentiment classification task.
     Hypothesis: few-shot with 3 examples will beat zero-shot by at least 10% accuracy.
```

LabMate scaffolds `exp/exp01a/` with:

```
exp/exp01a/
├── README.md       # hypothesis, method, expected results, findings (fill in as you go)
├── config.yaml     # experiment parameters
├── run.py          # execution script
└── analyze.py      # analysis script
```

The README already has your hypothesis and expected results pre-filled. The config has parameters you can adjust.

## 3. Run your experiment

Edit `exp/exp01a/run.py` to implement the actual comparison. This is where you write your research code — LabMate handles the scaffolding, you handle the science.

```bash
python exp/exp01a/run.py
```

Results land in `exp/exp01a/results/`.

## 4. Analyze results

Use LabMate's `analyze-experiment` skill.

This triggers a three-part analysis:

1. The domain-expert role interprets what the numbers mean in context
2. Cross-experiment comparison against prior runs (if any)
3. The slides-maker role generates presentation-ready HTML slides in `slides/`

Claude Code can use named agents for these roles. Codex uses ordinary
subagents, with a main-thread fallback when subagents are unavailable.

LabMate also updates `exp/exp01a/README.md` with findings and `exp/summary.md` with a one-line verdict.

## 5. Save project knowledge

Use LabMate's `update-project-skill` skill.

This compresses your findings into the project-local skill (`.agents/skills/project-skill/SKILL.md` for Codex/Antigravity or `.claude/skills/project-skill/SKILL.md` for Claude Code) — persistent memory that survives across sessions. Next time you open this project, your agent already knows what you tried and what worked.

## 6. Iterate

Use `new-experiment` again and provide:

> Same setup but with chain-of-thought prompting. Hypothesis: CoT beats
> few-shot by 5%.

LabMate creates `exp/exp01b/` (variant of exp01). The cycle repeats.

## What happens across sessions

When you come back tomorrow and open Claude Code, Codex, or Antigravity:

1. SessionStart hook reads `.pipeline-state.json` and tells your agent where you left off
2. Your agent checks `exp/summary.md` for experiment history
3. The domain-expert role reads your paper notes in `docs/papers/`
4. `update-project-skill` output provides compressed context from prior work

No more "what were we doing again?"

## Tips

- **Read your project instruction file** — `CLAUDE.md` for Claude Code, `AGENTS.md` for Codex/Antigravity. It is the source of truth for workflow routing. If both exist, keep them behaviorally aligned.
- **Use LabMate's `read-paper` skill** before designing experiments; it applies
  the domain-expert role and checks `docs/papers/landscape.md`.
- **Commit after each experiment** — LabMate's workflow depends on git history to track what's been tried.
- **Don't skip `update-project-skill`** — it gives your agent durable project
  context. Run it after every significant finding.

## Customize for your field

Claude Code users can override the named domain-expert agent:

```bash
mkdir -p .claude/agents
```

Create `.claude/agents/domain-expert.md` with domain-specific knowledge. Codex
does not require a custom agent: LabMate reads the bundled role body and falls
back to an ordinary subagent or the main thread. For project memory, mirror
`.claude/skills/project-skill/` and `.agents/skills/project-skill/` when both
platforms are active.
