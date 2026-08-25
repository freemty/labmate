#!/usr/bin/env python3
"""Validate the auditable input contract for LabMate read-paper."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = {
    "schema_version",
    "input_kind",
    "source_locator",
    "text_path",
    "provenance",
    "completeness",
    "anchors",
    "anchor_index",
    "extractor",
    "artifact_bytes",
    "source_page_count",
    "extracted_page_count",
    "content_sha256",
}
INPUT_KINDS = {"single_paper", "literature_hub"}
COMPLETENESS = {"full_text", "partial_text", "abstract_only", "hub_index"}
ANCHOR_FIELDS = {"id", "start_byte", "end_byte", "span_sha256", "page"}
ANCHOR_KINDS = {
    "page": "pages",
    "section": "sections",
    "equation": "equations",
    "figure": "figures",
    "table": "tables",
    "entry": "entries",
    "link": "links",
}


def fail(message: str) -> None:
    print(f"paper packet invalid: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_packet(packet_path: Path) -> dict[str, Any]:
    try:
        value = json.loads(packet_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"packet does not exist: {packet_path}")
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        fail(f"cannot read JSON: {exc}")
    if not isinstance(value, dict):
        fail("root must be a JSON object")
    return value


def validate_string_list(packet: dict[str, Any], field: str) -> list[str]:
    value = packet[field]
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item.strip() for item in value
    ):
        fail(f"{field} must be a list of non-empty strings")
    return value


def validate_common(
    packet: dict[str, Any], packet_path: Path
) -> tuple[Path, bytes, set[str], list[Any]]:
    missing = sorted(REQUIRED_FIELDS - packet.keys())
    if missing:
        fail(f"missing fields: {', '.join(missing)}")
    if packet["schema_version"] != 1:
        fail("schema_version must be 1")
    if packet["input_kind"] not in INPUT_KINDS:
        fail(f"unsupported input_kind: {packet['input_kind']!r}")
    if packet["completeness"] not in COMPLETENESS:
        fail(f"unsupported completeness: {packet['completeness']!r}")
    for field in (
        "source_locator",
        "text_path",
        "provenance",
        "extractor",
        "content_sha256",
    ):
        if not isinstance(packet[field], str) or not packet[field].strip():
            fail(f"{field} must be a non-empty string")
    anchors = set(validate_string_list(packet, "anchors"))
    anchor_index = packet["anchor_index"]
    if not isinstance(anchor_index, list) or not anchor_index:
        fail("anchor_index must be a non-empty list")
    if (
        isinstance(packet["artifact_bytes"], bool)
        or not isinstance(packet["artifact_bytes"], int)
        or packet["artifact_bytes"] <= 0
    ):
        fail("artifact_bytes must be a positive integer")
    for field in ("source_page_count", "extracted_page_count"):
        value = packet[field]
        if value is not None and (
            isinstance(value, bool) or not isinstance(value, int) or value <= 0
        ):
            fail(f"{field} must be null or a positive integer")

    artifact_path = Path(packet["text_path"])
    if not artifact_path.is_absolute():
        artifact_path = packet_path.parent / artifact_path
    if not artifact_path.is_file():
        fail(f"text artifact does not exist: {artifact_path}")
    try:
        body = artifact_path.read_bytes()
    except OSError as exc:
        fail(f"cannot read text artifact: {exc}")
    if not body:
        fail("text artifact is empty")
    if packet["artifact_bytes"] != len(body):
        fail("artifact_bytes does not match the text artifact")
    actual_sha = hashlib.sha256(body).hexdigest()
    if packet["content_sha256"].lower() != actual_sha:
        fail("content_sha256 does not match the text artifact")
    return artifact_path.resolve(), body, anchors, anchor_index


def validate_extraction(
    packet: dict[str, Any], body: bytes, anchors: set[str]
) -> dict[int, tuple[int, int]]:
    source_pages = packet["source_page_count"]
    extracted_pages = packet["extracted_page_count"]
    if "pages" in anchors:
        if source_pages is None or extracted_pages is None:
            fail("pages anchor requires source_page_count and extracted_page_count")
        if source_pages != extracted_pages:
            fail("source and extracted page counts differ")

        marker_matches = list(
            re.finditer(rb"<!--\s*page:\s*(\d+)\s*-->", body)
        )
        marker_values = [int(match.group(1)) for match in marker_matches]
        if marker_matches:
            expected = list(range(1, extracted_pages + 1))
            if marker_values != expected:
                fail("page markers must be continuous from 1 through extracted_page_count")
            page_ranges = {
                page: (
                    marker_matches[index].start(),
                    marker_matches[index + 1].start()
                    if index + 1 < len(marker_matches)
                    else len(body),
                )
                for index, page in enumerate(marker_values)
            }
        else:
            page_ranges = {}
            start = 0
            page = 1
            for match in re.finditer(rb"\f", body):
                page_ranges[page] = (start, match.start())
                page += 1
                start = match.end()
            if start < len(body) or not body.endswith(b"\f"):
                page_ranges[page] = (start, len(body))
            if len(page_ranges) != extracted_pages:
                fail("artifact page boundaries do not match extracted_page_count")
    elif source_pages is not None or extracted_pages is not None:
        fail("page counts require a pages anchor")
    else:
        page_ranges = {}

    if packet["completeness"] == "full_text" and "pages" not in anchors:
        if "sections" not in anchors:
            fail("full_text requires pages or sections anchors")
        text = body.decode("utf-8", errors="replace")
        headings = re.findall(r"(?m)^#{1,6}\s+(.+?)\s*$", text)
        if len(headings) < 3:
            fail("section-preserving full_text requires at least three indexed headings")
    return page_ranges


def marker_visible(anchor_id: str, span: bytes) -> bool:
    kind, label = anchor_id.split(":", 1)
    kind = kind.casefold()
    label = label.strip()
    text = span.decode("utf-8", errors="replace")
    folded = text.casefold()
    escaped = re.escape(label.casefold())
    if kind == "equation":
        explicit_patterns = (
            rf"\\tag\s*\{{\s*{escaped}\s*\}}",
            rf"\b(?:eq(?:uation)?\.?)\s*\(?\s*{escaped}\s*\)?",
        )
        if any(re.search(pattern, folded) for pattern in explicit_patterns):
            return True
        numbered_math = bool(re.search(rf"\(\s*{escaped}\s*\)", folded))
        math_signal = bool(re.search(r"[=+*/∑∏∫]|\\[a-zA-Z]+", text))
        return numbered_math and math_signal
    if kind == "figure":
        return bool(re.search(rf"\b(?:figure|fig\.?)\s*{escaped}\b", folded))
    if kind == "table":
        return bool(re.search(rf"\btable\s*{escaped}\b", folded))
    if kind == "page":
        return bool(
            re.search(rf"<!--\s*page:\s*{escaped}\s*-->", folded)
            or re.search(rf"\bpage\s+{escaped}\b", folded)
        )
    if kind == "section":
        return bool(
            re.search(rf"(?m)^\s*(?:#{{1,6}}\s*)?{escaped}(?:\s|$)", folded)
        )
    return label.casefold() in folded


def validate_anchor_index(
    raw_index: list[Any], body: bytes, anchors: set[str],
    page_ranges: dict[int, tuple[int, int]], packet: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for position, value in enumerate(raw_index):
        if not isinstance(value, dict):
            fail(f"anchor_index[{position}] must be an object")
        missing = ANCHOR_FIELDS - value.keys()
        if missing:
            fail(f"anchor_index[{position}] missing fields: {', '.join(sorted(missing))}")
        anchor_id = value["id"]
        if not isinstance(anchor_id, str) or ":" not in anchor_id:
            fail(f"anchor_index[{position}].id must be TYPE:ID")
        kind, label = anchor_id.split(":", 1)
        kind = kind.casefold()
        if not label.strip() or kind not in ANCHOR_KINDS:
            fail(f"unsupported anchor id: {anchor_id!r}")
        if ANCHOR_KINDS[kind] not in anchors:
            fail(f"{anchor_id} requires {ANCHOR_KINDS[kind]} in anchors")
        normalized_id = anchor_id.casefold()
        if normalized_id in index:
            fail(f"duplicate anchor id: {anchor_id}")

        start = value["start_byte"]
        end = value["end_byte"]
        if any(isinstance(offset, bool) or not isinstance(offset, int) for offset in (start, end)):
            fail(f"{anchor_id} byte offsets must be integers")
        if not (0 <= start < end <= len(body)):
            fail(f"{anchor_id} byte span is outside the artifact")
        span = body[start:end]
        span_sha = value["span_sha256"]
        if not isinstance(span_sha, str) or hashlib.sha256(span).hexdigest() != span_sha.lower():
            fail(f"{anchor_id} span_sha256 does not match its byte span")
        if not marker_visible(anchor_id, span):
            fail(f"{anchor_id} marker is not visible in its bound byte span")

        page = value["page"]
        if page is not None and (
            isinstance(page, bool) or not isinstance(page, int) or page <= 0
        ):
            fail(f"{anchor_id}.page must be null or a positive integer")
        if page is not None:
            if page not in page_ranges:
                fail(f"{anchor_id} references an unavailable page")
            page_start, page_end = page_ranges[page]
            if not (page_start <= start < end <= page_end):
                fail(f"{anchor_id} byte span is not inside page {page}")
        elif page_ranges and kind in {"section", "equation", "figure", "table"}:
            fail(f"{anchor_id} must name its page for a paginated artifact")

        index[normalized_id] = value

    if packet["completeness"] == "full_text" and "pages" not in anchors:
        section_count = sum(key.startswith("section:") for key in index)
        if section_count < 3:
            fail("section-preserving full_text requires at least three bound section anchors")
    return index


def validate_route(
    packet: dict[str, Any], anchors: set[str], anchor_index: dict[str, dict[str, Any]], mode: str,
    required_anchors: list[str],
) -> None:
    if mode == "deep-dive":
        if packet["input_kind"] != "single_paper":
            fail("deep-dive requires input_kind=single_paper")
        if packet["completeness"] != "full_text":
            fail("deep-dive requires completeness=full_text")
        if not ({"pages", "sections"} & anchors):
            fail("deep-dive requires a pages or sections anchor")
        missing_requested = [
            value for value in required_anchors if value.casefold() not in anchor_index
        ]
        if missing_requested:
            fail(f"requested anchors unavailable: {', '.join(missing_requested)}")
        return

    if packet["input_kind"] != "literature_hub":
        fail("hub-triage requires input_kind=literature_hub")
    if packet["completeness"] != "hub_index":
        fail("hub-triage requires completeness=hub_index")
    missing = {"entries", "links"} - anchors
    if missing:
        fail(f"hub-triage missing anchors: {', '.join(sorted(missing))}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet", type=Path, help="path to the packet JSON")
    parser.add_argument("--mode", choices=("deep-dive", "hub-triage"), required=True)
    parser.add_argument(
        "--require-anchor",
        action="append",
        default=[],
        metavar="TYPE:ID",
        help="require an indexed anchor such as equation:7 or table:3",
    )
    args = parser.parse_args()

    packet_path = args.packet.expanduser().resolve()
    packet = load_packet(packet_path)
    artifact_path, body, anchors, raw_anchor_index = validate_common(packet, packet_path)
    page_ranges = validate_extraction(packet, body, anchors)
    anchor_index = validate_anchor_index(
        raw_anchor_index, body, anchors, page_ranges, packet
    )
    validate_route(packet, anchors, anchor_index, args.mode, args.require_anchor)
    print(
        json.dumps(
            {
                "ok": True,
                "mode": args.mode,
                "input_kind": packet["input_kind"],
                "completeness": packet["completeness"],
                "artifact_path": str(artifact_path),
                "artifact_bytes": packet["artifact_bytes"],
                "source_page_count": packet["source_page_count"],
                "extracted_page_count": packet["extracted_page_count"],
                "content_sha256": packet["content_sha256"].lower(),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
