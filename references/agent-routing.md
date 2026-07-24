# Portable Agent Routing

Use this contract whenever a LabMate skill delegates to one of the roles in
`<plugin-root>/agents/`.

1. If the host exposes the requested LabMate named agent, delegate to it.
2. Otherwise, if subagents are available, start a suitable subagent and tell it
   to read the matching agent file, ignore its YAML frontmatter, and follow the
   Markdown body as role instructions.
3. If subagents are unavailable or disabled, perform the same role in the main
   thread.

The workflow must not fail solely because a named agent, a specific model, or
background execution is unavailable. Do not hardcode vendor model names in
portable skill instructions.

For background work, use background execution when the host supports it.
Otherwise complete the work synchronously before reporting the artifact.

The main thread owns all user interaction, approvals, follow-up questions, and
archival decisions. Subagents return findings or artifacts to the main thread;
they do not take over the user conversation.
