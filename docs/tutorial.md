# Tutorial: your first experiment

This walks you through a complete research cycle with LabMate, from install to analysis slides. Takes about 10 minutes.

## 0. Install

```bash
claude plugin install freemty/labmate
```

Open Claude Code in your project directory. You should see a LabMate prompt suggesting `/init-project` — that's the SessionStart hook confirming the plugin loaded.

## 1. Initialize your project

```
you: /init-project
```

LabMate asks 4 questions:

```
LabMate: Project name?
you: my-nlp-project

LabMate: One-line description?
you: Comparing prompt strategies for classification tasks

LabMate: Research domain?
you: NLP

LabMate: Compute environment? (local / remote-gpu / cloud)
you: local
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
├── CLAUDE.md               # your research hub — principles, agents, workflow
└── .pipeline-state.json    # tracks current experiment + stage
```

Commit this: `git add -A && git commit -m "feat: init research skeleton"`

## 2. Create your first experiment

```
you: /new-experiment
```

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

```
you: /analyze-experiment
```

This triggers a three-part analysis:

1. `@domain-expert` interprets what the numbers mean in your field's context
2. Cross-experiment comparison against prior runs (if any)
3. `@slides-maker` generates presentation-ready HTML slides in `slides/`

LabMate also updates `exp/exp01a/README.md` with findings and `exp/summary.md` with a one-line verdict.

## 5. Save project knowledge

```
you: /update-project-skill
```

This compresses your findings into `.claude/skills/project-skill/SKILL.md` — persistent memory that survives across sessions. Next time you open this project, your agent already knows what you tried and what worked.

## 6. Iterate

```
you: /new-experiment
you: Same setup but with chain-of-thought prompting. Hypothesis: CoT beats few-shot by 5%.
```

LabMate creates `exp/exp01b/` (variant of exp01). The cycle repeats.

## What happens across sessions

When you come back tomorrow and open Claude Code:

1. SessionStart hook reads `.pipeline-state.json` and tells your agent where you left off
2. Your agent checks `exp/summary.md` for experiment history
3. `@domain-expert` still has access to your paper notes in `docs/papers/`
4. `/update-project-skill` output gives compressed context from all prior work

No more "what were we doing again?"

## Tips

- **Read your CLAUDE.md** — it's the single source of truth for your research workflow. The Research Principles section is worth internalizing.
- **Use `@domain-expert`** to read papers before designing experiments. Ask it to check `docs/papers/landscape.md` for related work.
- **Commit after each experiment** — LabMate's workflow depends on git history to track what's been tried.
- **Don't skip `/update-project-skill`** — it's what gives your agent long-term memory. Run it after every significant finding.

## Customize for your field

If you work in a specific domain, override the `@domain-expert` agent:

```bash
mkdir -p .claude/agents
```

Create `.claude/agents/domain-expert.md` with domain-specific knowledge (what baselines matter in your field, what metrics to use, which conferences to cite). Your local version takes priority over the plugin default.
