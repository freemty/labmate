---
name: analyze-experiment
description: >
  Use when an experiment has completed and results need analysis, interpretation,
  or presentation. Triggers on "analyze results", "分析实验", "interpret experiment",
  "what did exp find", "run analysis".
disable-model-invocation: true
---

# Analyze Experiment

Full analysis pipeline for the current experiment.

## Agent Routing

Read `<plugin-root>/references/agent-routing.md` before delegating. Resolve
`<plugin-root>` by going up two directories from this `SKILL.md`.

## Instructions

When this skill is invoked:

1. **Read pipeline state:**
   ```python
   import json
   state = json.load(open('.pipeline-state.json'))
   current_exp = state['current_exp']
   ```
   If `current_exp` is null, ask user which experiment to analyze.

2. **Run analysis script:**
   ```bash
   PYTHONPATH=. python exp/{current_exp}/analyze.py
   ```
   This generates `exp/{current_exp}/results/summary.md`.

3. **Run the `domain-expert` role** for interpretation:

   Follow the portable routing contract with
   `<plugin-root>/agents/domain-expert.md`.

   Provide this task:
   > Analyze experiment {current_exp}:
   > Read `exp/{current_exp}/results/summary.md` for quantitative results.
   > Read `exp/{current_exp}/README.md` for experiment context.
   > Scan `docs/papers/` for relevant domain papers.
   > Provide ~500 word domain interpretation with paper citations.

   Include the current project skill and relevant paper notes as explicit
   context. Do not assume the role has persistent memory.

4. **Merge interpretation** into `exp/{current_exp}/README.md` under the "## Findings" section.

5. **Update `exp/summary.md`** cross-experiment table: update the row for current_exp with status "Analyzed" and key finding summary (one line).

6. **Run the `slides-maker` role** for presentation:

   Follow the portable routing contract with
   `<plugin-root>/agents/slides-maker.md`.

   Provide this task:
   > mode: analysis
   > exp_id: {current_exp}
   > Generate: slides/{current_exp}-analysis.html

   Use background execution when supported. Otherwise generate the slides
   synchronously. Only report the slide path after the artifact exists; if it is
   still running in the background, report that status explicitly and continue
   monitoring until completion or a clear handoff point.

7. **Advance pipeline state:**
   - Set `stage` to "analysis" in `.pipeline-state.json`

8. **Print summary** of generated artifacts:
   - `exp/{current_exp}/results/summary.md` — quantitative analysis
   - `exp/{current_exp}/README.md` — updated with findings
   - `slides/{current_exp}-analysis.html` — presentation, or an explicit
     in-progress status if background work is still running
