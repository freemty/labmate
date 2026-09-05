# HTML slide quality contract

Use this reference only for an explicitly requested HTML presentation. Research
Beamer decks retain the research-slides Speculative Decoding profile; this
reference does not override it or an existing artifact's design.

Prefer a lightweight artifact consistent with the project. A self-contained HTML
file is useful when portability matters, but an existing framework is valid.
Use system/local fonts by default unless the active design specifies another
font. Do not add gradients, animation, font downloads or new dependencies merely
to make a technical report look elaborate.

## Layout and interaction
Check the target viewport and representative smaller screens using an available
browser/CUA or renderer. Native capabilities are valid without Playwright.
Keep slide content readable and navigable; split dense material when it improves
the talk. Do not hide overflow to disguise clipping or shrink text below a useful
size. Responsive CSS, media queries and a readable fallback are implementation
choices, not mandated CSS snippets.

Verify keyboard navigation, focus, reduced-motion behavior and local asset paths
when applicable. Test the artifact's stated supported viewport range, not an
unprovable claim that every possible screen size works.

## Evidence
Each substantive claim names its source. Distinguish measured data from inference.
Figures, captions and formulas must match their source; cite specific locations.
For video material record time intervals and actual audio/visual coverage. A
single still may illustrate appearance but not establish a continuous action.

Return the completed artifact and the checks actually performed. Compilation or
file existence alone is insufficient visual QA; if rendering is unavailable,
label layout verification incomplete. Background execution is optional and must
not be reported as an existing task unless one really started.
