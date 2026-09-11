#!/usr/bin/env python3
"""Generate the final preflight Markdown report.

Consumes the JSON outputs of:
  - extract_manuscript_text.py  → manuscript.json
  - scan_ai_artifacts.py        → artifacts.json
  - verify_references.py        → refs.json

Optional inputs (provided by the orchestrating agent):
  - --label-issues             JSON file with broken \ref / orphan label findings
  - --moderation-issues        JSON file with arXiv moderation findings (free-form)
  - --disclosure-assessment    JSON file with detected AI use + recommendation

Schema for optional inputs:
  label-issues:        {"findings": [{"severity": "MEDIUM", "kind": "broken_ref", "label": "fig:foo", "file": "...", "line": 12}]}
  moderation-issues:   {"findings": [{"severity": "HIGH", "category": "copyright", "evidence": "...", "location": "..."}]}
  disclosure-assessment: {"signals": "polish-only", "disclosure_present": false, "recommendation": "...", "rationale": "..."}

Usage:
    python generate_preflight_report.py \
        --manuscript manuscript.json --artifacts artifacts.json --refs refs.json \
        --output report.md
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

if sys.version_info < (3, 9):
    raise SystemExit(f"arxiv-preflight requires Python 3.9+; got {sys.version.split()[0]}")

SEV_ORDER = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "BLOCKER": 4}


def load(path: Path | None) -> dict:
    if path and path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def fmt_finding(idx: int, severity: str, title: str, *, category: str, location: str,
                evidence: str, why: str, fix: str) -> str:
    return (
        f"### {idx}. [{severity}] {title}\n"
        f"- **Category:** {category}\n"
        f"- **Location:** {location}\n"
        f"- **Evidence:** > {evidence}\n"
        f"- **Why it matters:** {why}\n"
        f"- **Fix:** {fix}\n"
    )


CATEGORY_LABELS = {
    "llm_meta": "LLM meta-comment / assistant output",
    "prompt_residue": "Prompt residue",
    "placeholder": "Placeholder content",
    "authorship": "Authorship issue",
    "disclosure": "Disclosure issue",
    "citation_format": "Citation formatting",
    "other": "Other",
}

WHY_BY_CATEGORY = {
    "llm_meta": "Unedited assistant output is one of arXiv's explicit BLOCKER signals (see policy notes).",
    "prompt_residue": "Prompt text appearing in the manuscript is direct evidence of unchecked LLM output.",
    "placeholder": "Unfilled placeholders indicate the manuscript is not actually finished.",
    "authorship": "arXiv policy: AI tools cannot be listed as authors.",
    "disclosure": "Significant AI use must be disclosed per field norms.",
    "citation_format": "Malformed citation metadata can signal a fabricated reference.",
    "other": "Surfaced by the artifact scanner; review and act on context.",
}

FIX_BY_CATEGORY = {
    "llm_meta": "Delete the snippet or rewrite the paragraph in the author's own voice.",
    "prompt_residue": "Remove the snippet; rewrite the paragraph from scratch.",
    "placeholder": "Fill in real content or remove the section.",
    "authorship": "Remove AI tools from the author list; move disclosure to Acknowledgments.",
    "disclosure": "Add a brief disclosure in Acknowledgments / Methods describing the AI use.",
    "citation_format": "Re-check the source; verify the DOI, year, and venue.",
    "other": "Review the location and confirm whether the snippet should be present.",
}


def artifact_findings_section(artifacts: dict, start_idx: int) -> tuple[dict, int]:
    out = {"BLOCKER": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    idx = start_idx
    for f in artifacts.get("findings", []):
        sev = f["severity"]
        category = CATEGORY_LABELS.get(f["category"], f["category"])
        location = f"{f['file']}:{f['line']}"
        snippet = f.get("snippet") or f.get("match")
        snippet = snippet.replace("\n", " ").strip()
        if len(snippet) > 240:
            snippet = snippet[:237] + "..."
        block = fmt_finding(
            idx, sev,
            title=f"{CATEGORY_LABELS.get(f['category'], 'Artifact')} ({f['rule_id']})",
            category=category, location=location,
            evidence=snippet,
            why=WHY_BY_CATEGORY.get(f["category"], "Surfaced by the artifact scanner."),
            fix=FIX_BY_CATEGORY.get(f["category"], "Review and remove or rewrite."),
        )
        out[sev].append(block)
        idx += 1
    return out, idx


def reference_findings(refs: dict, start_idx: int) -> tuple[dict, int]:
    out = {"BLOCKER": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    idx = start_idx
    for entry in refs.get("per_entry", []):
        verdict = entry["verdict"]
        if verdict == "LOW" and not entry["layer3"]["disagreements"] and entry["layer1"]["status"] == "ok" and entry["layer2"].get("matched_by"):
            continue
        if not entry["layer2"].get("queried") and not entry["layer2"].get("matched_by") and entry["layer1"]["status"] == "ok":
            continue
        if verdict not in out:
            continue
        cand = entry["layer2"].get("candidate") or {}
        if entry["layer2"].get("matched_by"):
            why = f"Matched via {entry['layer2']['matched_by']} but with field disagreements."
            fix = "Confirm the cited paper; correct the BibTeX field(s) called out below."
        else:
            queried = ", ".join(entry["layer2"].get("queried", [])) or "none"
            why = f"No match in {queried}. Could be a niche venue, or a fabricated reference."
            fix = "Locate the original publication; if you cannot find it, remove the citation and the claim it supports."
        disagreement_lines = "; ".join(
            f"{d['field']}: bib={d.get('bib')!r} vs external={d.get('external')!r}"
            for d in entry["layer3"]["disagreements"]
        ) or entry.get("summary", "")
        block = fmt_finding(
            idx, verdict,
            title=f"Reference `{entry['entry_key']}` — {verdict}",
            category="Reference verification",
            location=f"{refs.get('bib_file','?')}:{entry['line']}",
            evidence=disagreement_lines or "No external candidate matched.",
            why=why, fix=fix,
        )
        out[verdict].append(block)
        idx += 1
    # citation issues (undefined cite, unused entry)
    for ci in refs.get("citation_issues", []):
        sev = ci["severity"]
        kind = ci["kind"]
        title = "Undefined citation key" if kind == "undefined_citation" else "Unused BibTeX entry"
        loc = f"{ci['file']}:{ci['line']}" if ci.get("file") else f"line {ci['line']}"
        block = fmt_finding(
            idx, sev,
            title=f"{title}: `{ci['key']}`",
            category="Reference verification",
            location=loc,
            evidence=f"Key `{ci['key']}`",
            why=("`\\cite{}` references a key that does not exist in the BibTeX file." if kind == "undefined_citation"
                 else "BibTeX entry never cited from the manuscript."),
            fix=("Add the entry to the .bib or correct the cite key." if kind == "undefined_citation"
                 else "Remove the unused entry, or cite it in the manuscript."),
        )
        out[sev].append(block)
        idx += 1
    return out, idx


def network_incomplete_findings(refs: dict, start_idx: int) -> tuple[dict, int]:
    out = {"BLOCKER": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    if refs.get("network_complete", True):
        return out, start_idx
    services = ", ".join(refs.get("services_unavailable", [])) or "external metadata services"
    out["HIGH"].append(fmt_finding(
        start_idx,
        "HIGH",
        "Reference verification incomplete",
        category="Reference verification",
        location=refs.get("bib_file", "?"),
        evidence=f"Unavailable services: {services}",
        why="Citation metadata was not checked against external databases, so fabricated or stale references may be missed.",
        fix="Rerun reference verification with network access before treating citation checks as passed.",
    ))
    return out, start_idx + 1


def extra_findings(name: str, blob: dict, start_idx: int, defaults: dict) -> tuple[dict, int]:
    out = {"BLOCKER": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    idx = start_idx
    for f in blob.get("findings", []):
        sev = f.get("severity", defaults.get("severity", "MEDIUM"))
        if sev not in out:
            continue
        loc = f.get("location") or f"{f.get('file','?')}:{f.get('line','?')}"
        block = fmt_finding(
            idx, sev,
            title=f.get("title") or f.get("kind", name),
            category=f.get("category", defaults["category"]),
            location=loc,
            evidence=f.get("evidence") or f.get("label", ""),
            why=f.get("why", defaults.get("why", "")),
            fix=f.get("fix", defaults.get("fix", "")),
        )
        out[sev].append(block)
        idx += 1
    return out, idx


def merge(*buckets: dict) -> dict:
    out = {"BLOCKER": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    for b in buckets:
        for k in out:
            out[k].extend(b.get(k, []))
    return out


def decision(counts: dict, ref_network_complete: bool) -> str:
    if counts["BLOCKER"] > 0:
        return "HOLD"
    if counts["HIGH"] > 0 or counts["MEDIUM"] > 0 or not ref_network_complete:
        return "PASS_WITH_FIXES"
    return "PASS"


def reference_table(refs: dict) -> str:
    rows = ["| Cite key | Verdict | Notes |", "| --- | --- | --- |"]
    for e in refs.get("per_entry", []):
        if not e["layer2"].get("queried") and not e["layer2"].get("matched_by") and e["layer1"]["status"] == "ok":
            rows.append(f"| {e['entry_key']} | UNVERIFIED | External metadata lookup was not run or did not start. |")
            continue
        notes = e.get("summary", "") or ""
        if e["layer2"].get("matched_by"):
            notes = f"matched via {e['layer2']['matched_by']}; {notes}".strip("; ")
        rows.append(f"| {e['entry_key']} | {e['verdict']} | {notes} |")
    return "\n".join(rows) if len(rows) > 2 else "_No references parsed._"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--manuscript", type=Path)
    p.add_argument("--artifacts", type=Path, required=True)
    p.add_argument("--refs", type=Path, required=True)
    p.add_argument("--label-issues", type=Path)
    p.add_argument("--moderation-issues", type=Path)
    p.add_argument("--disclosure-assessment", type=Path)
    p.add_argument("--output", type=Path, default=Path("preflight_report.md"))
    p.add_argument("--title", default=None)
    args = p.parse_args()

    manuscript = load(args.manuscript)
    artifacts = load(args.artifacts)
    refs = load(args.refs)
    label_issues = load(args.label_issues)
    moderation = load(args.moderation_issues)
    disclosure = load(args.disclosure_assessment)

    idx = 1
    art_buckets, idx = artifact_findings_section(artifacts, idx)
    network_buckets, idx = network_incomplete_findings(refs, idx)
    ref_buckets, idx = reference_findings(refs, idx)
    label_buckets, idx = extra_findings("Label", label_issues, idx, defaults={
        "category": "Cross-reference",
        "why": "Broken or orphan `\\ref{}` / `\\label{}` indicates a stale draft.",
        "fix": "Locate the missing/extra label and reconcile.",
    })
    mod_buckets, idx = extra_findings("Moderation", moderation, idx, defaults={
        "category": "arXiv moderation",
        "why": "Pattern often surfaced by arXiv moderators; surface and let the author decide.",
        "fix": "Review the location and remediate per arXiv policy notes.",
    })

    all_buckets = merge(art_buckets, network_buckets, ref_buckets, label_buckets, mod_buckets)
    counts = {k: len(v) for k, v in all_buckets.items()}
    ref_network_complete = refs.get("network_complete", True)
    dec = decision(counts, ref_network_complete)

    lines = []
    title = args.title or (manuscript.get("root_files", [""])[0] if manuscript else "Manuscript")
    lines.append("# arXiv Preflight Report\n")
    lines.append(f"**Manuscript:** {title}")
    lines.append(f"**Run at:** {datetime.now(timezone.utc).isoformat(timespec='seconds')}")
    inputs = []
    if manuscript: inputs.append(f"manuscript ({manuscript.get('source_type','?')})")
    if refs: inputs.append(f"bibtex ({refs.get('entry_count', 0)} entries)")
    if artifacts: inputs.append(f"artifact scan ({artifacts.get('scanned_chars', 0)} chars)")
    lines.append(f"**Inputs:** {', '.join(inputs) or 'unknown'}")
    lines.append(f"**Decision:** {dec}\n")

    lines.append("## Summary\n")
    lines.append(f"- Blockers: {counts['BLOCKER']}")
    lines.append(f"- High:     {counts['HIGH']}")
    lines.append(f"- Medium:   {counts['MEDIUM']}")
    lines.append(f"- Low:      {counts['LOW']}")
    lines.append(f"- Reference verification: {'COMPLETE' if ref_network_complete else 'INCOMPLETE — services unavailable: ' + ', '.join(refs.get('services_unavailable', [])) }")
    lines.append("")

    def emit(section_title, sev):
        items = all_buckets[sev]
        lines.append(f"## {section_title}\n")
        if not items:
            lines.append(f"_No {sev.lower()} items._\n")
            return
        lines.extend(items)

    emit("Blocking Issues", "BLOCKER")
    emit("High-priority Issues", "HIGH")
    emit("Medium-priority Issues", "MEDIUM")
    lines.append("## Low-priority / Polish\n")
    if all_buckets["LOW"]:
        lines.extend(all_buckets["LOW"])
    else:
        lines.append("_No low-priority items._\n")

    lines.append("## Reference Verification Detail\n")
    lines.append(reference_table(refs))
    lines.append("")

    lines.append("## AI-use Disclosure Assessment\n")
    if disclosure:
        lines.append(f"- Detected signals: {disclosure.get('signals', 'unknown')}")
        lines.append(f"- Disclosure present: {disclosure.get('disclosure_present', 'unknown')}")
        lines.append(f"- Recommendation: {disclosure.get('recommendation', '—')}")
        lines.append(f"- Rationale: {disclosure.get('rationale', '—')}")
    else:
        lines.append("_Not assessed — supply --disclosure-assessment to populate this section._")
    lines.append("")

    lines.append("## arXiv Moderation Risks\n")
    mod_items = moderation.get("findings", [])
    if mod_items:
        for f in mod_items:
            lines.append(f"- [{f.get('severity', 'MEDIUM')}] {f.get('category', '')}: {f.get('evidence', '')} ({f.get('location', '')})")
    else:
        lines.append("_None surfaced — supply --moderation-issues to record any._")
    lines.append("")

    lines.append("## Human Sign-off Checklist\n")
    lines.append("- [ ] Every author has reviewed the final PDF/source.")
    lines.append("- [ ] All references in this report verified or knowingly accepted.")
    lines.append("- [ ] All tables and figures contain final data (no placeholders, no `XX%`).")
    lines.append("- [ ] All `\\ref{}` and `\\cite{}` resolve.")
    lines.append("- [ ] AI use, if significant, is disclosed in line with field norms.")
    lines.append("- [ ] No AI tool appears in the author list or acknowledgments as a contributor of intellectual content.")
    lines.append("- [ ] arXiv primary category is appropriate for the manuscript format.\n")

    lines.append("## Notes & Caveats\n")
    lines.append("- Reference-database coverage is imperfect; absence of a match is not proof of fabrication on its own.")
    lines.append("- This report does not predict arXiv acceptance.")
    lines.append("- This report does not perform full plagiarism detection.\n")
    lines.append("---\n*Generated by `arxiv-preflight` skill.*")

    args.output.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {args.output} — decision: {dec} "
          f"(BLOCKER={counts['BLOCKER']} HIGH={counts['HIGH']} "
          f"MEDIUM={counts['MEDIUM']} LOW={counts['LOW']})")
    return 0 if dec != "HOLD" else 1


if __name__ == "__main__":
    raise SystemExit(main())
