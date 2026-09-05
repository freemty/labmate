# Paper acquisition contract

Create a normalized, inspectable packet before asking for scientific analysis.
Keep the packet and its text artifact in one temporary directory created with
`mktemp -d`. Do not put credentials or private headers in either file.

## 1. Classify the input

Classify by the fetched object's role, not only by its extension:

| `input_kind` | Includes | Excludes |
|---|---|---|
| `single_paper` | a local PDF, native paper HTML, publisher full text, pasted manuscript | abstract page, search result, bibliography |
| `literature_hub` | GitHub/Awesome reading list, proceedings index, curated bibliography, survey landing page | an individual linked paper |

If a hub links one paper the user wants, acquire that paper separately. Do not
infer its contents from the hub description.

## 2. Acquire without losing coverage

Prefer the most direct, complete source available:

- **Local or remote PDF:** keep the original page order. Use the host's native
  PDF reader or `pdftotext -layout`. Preserve form-feed page breaks or insert
  explicit `<!-- page: N -->` markers. Record `pages` in `anchors`, the source
  and extracted page counts, and the exact extractor used.
- **arXiv:** `/abs/` is metadata/abstract only. Derive the paper ID and acquire
  the native PDF or verified full-text HTML for a deep-dive. Never silently
  substitute `/abs/` for `/pdf/`.
- **Publisher or paper HTML:** verify that method, results/analysis, and
  references are present. Preserve headings and record `sections` in
  `anchors`. A page containing only title and abstract is `abstract_only`.
- **Pasted text:** mark `full_text` only when the supplied material contains the
  substantive paper body. Otherwise use `partial_text` or `abstract_only`.
- **Hub:** preserve entry names and target URLs. Record both `entries` and
  `links` in `anchors`; do not fetch every linked paper during triage.

Acquisition failure is a coverage result, not permission to guess. State what
was obtained and what is missing.

## 3. Write the packet

Save the extracted body as UTF-8 Markdown or plain text. Save a sibling JSON
file with this schema:

```json
{
  "schema_version": 1,
  "input_kind": "single_paper",
  "source_locator": "https://arxiv.org/pdf/0000.00000",
  "text_path": "paper.md",
  "provenance": "remote_pdf",
  "completeness": "full_text",
  "anchors": ["pages", "sections", "equations", "figures", "tables"],
  "anchor_index": [
    {
      "id": "equation:7",
      "start_byte": 48210,
      "end_byte": 48302,
      "span_sha256": "sha256-of-the-exact-byte-span",
      "page": 8
    }
  ],
  "extractor": "pdftotext 25.06 -layout",
  "artifact_bytes": 123456,
  "source_page_count": 12,
  "extracted_page_count": 12,
  "content_sha256": "lowercase-sha256"
}
```

The required fields are those shown. `text_path` may be absolute or relative to
the packet JSON. `source_locator` is the original user-facing locator.

Use a precise `provenance` value such as `local_pdf`, `remote_pdf`,
`arxiv_html`, `publisher_html`, `pasted_text`, `github_repo`, or `web_page`.
Allowed completeness values are `full_text`, `partial_text`, `abstract_only`,
and `hub_index`.

`extractor` records the actual reader and relevant mode/version. Set page counts
to `null` for non-paginated sources; otherwise both must be positive and equal.
`artifact_bytes` is the exact byte length. Every `anchor_index` entry binds an
ID to an exact byte span and its SHA256; `page` is required when the artifact is
paginated. IDs use `page:12`, `section:Methods`, `equation:7`, `figure:2`,
`table:3`, `entry:Paper Name`, or `link:https://...`. The bound span must visibly
contain that heading, label, equation number, figure/table caption, or URL.

Compute `artifact_bytes` and `content_sha256` from the exact artifact bytes. The
validator rejects missing artifacts, mismatched bytes/hash, incompatible routes,
non-contiguous page boundaries, page-count mismatches, and required anchors
absent from `anchor_index`.

## 4. Route only after validation

- `deep-dive` requires `single_paper`, `full_text`, and `pages` or `sections`.
- `hub-triage` requires `literature_hub`, `hub_index`, `entries`, and `links`.

Pass each equation/figure/table/page/section explicitly requested by the user as
`--require-anchor TYPE:ID`. If it is not indexed, acquire a better artifact or
scope the answer down; never manufacture the anchor.

Keep the packet path available throughout Q&A so claims can be checked against
the same immutable acquisition artifact.

## 5. Durable archive boundary

Temporary packets are working state only. When the user explicitly saves a
reading, copy the packet and exact text artifact into
`docs/papers/artifacts/{short-name}/`, rewrite only `text_path` if needed, and
re-run the same validator against the archived copy. If the original PDF is
locally available and privacy/licensing permit, copy it too and record its
SHA256; otherwise preserve the source locator and state why raw bytes are
absent. The note must link the frozen packet/artifact and their hashes.

## Supplementary media

Native text/PDF and structured scholarly retrieval are valid acquisition paths;
no optional CLI is universally required. For figures whose layout matters, inspect
the actual page/figure rather than relying on caption text alone.

For supplementary talks/demos, keep a separate evidence note with URL, timestamp
interval, observed modalities and coverage gaps. Captions establish speech only;
frames/continuous playback are needed for screen/action claims. Do not change the
paper packet schema or count a video description as paper full text.
