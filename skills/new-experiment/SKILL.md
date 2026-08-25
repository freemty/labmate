---
name: new-experiment
description: Use when starting a new experiment or creating a variant of an existing `expNNx` run. Triggers on "new experiment", "新实验", "scaffold exp", "set up experiment", "create experiment".
disable-model-invocation: true
---

# New Experiment

Use the bundled scaffold interface so experiment naming, files, summary rows,
and pipeline state stay consistent.

1. Establish a one-line motivation and optional parent. Infer the next ID unless
   the user supplied one.
2. Resolve `<plugin-root>` and preview:

   ```bash
   python3 <plugin-root>/scripts/new_experiment.py plan \
     --motivation "<motivation>" [--parent expNNx] [--exp-id expNNx]
   ```

3. Confirm only if the proposed ID or parent is ambiguous. Rerun with `apply`,
   then `check` using the returned experiment ID.
4. Report the new paths and exact launch command. Monitoring remains a separate
   one-shot workflow.

Never reuse an existing experiment directory. A parent config may be copied,
but code and results are not. Generated `run.py` refuses a live run until its
experiment body is implemented.
