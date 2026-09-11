#!/usr/bin/env python3
"""Scan a manuscript for LLM meta-comments, prompt residue, and placeholders.

Patterns are defined in `references/ai_artifact_patterns.md`. This script reads
that file as data and parses the markdown tables, so updates to the pattern
library do not require a code change.

Usage:
    python scan_ai_artifacts.py --input manuscript.json --output artifacts.json
    python scan_ai_artifacts.py --raw path/to/file.tex --output artifacts.json

Output schema:
{
  "findings": [
    {
      "rule_id": "META-01",
      "severity": "BLOCKER",
      "category": "llm_meta",
      "file": "...",
      "line": 42,
      "snippet": "...",
      "match": "as an AI language model"
    }
  ],
  "counts": {"BLOCKER": 1, "HIGH": 0, "MEDIUM": 0, "LOW": 0},
  "scanned_chars": 12345,
  "warnings": [...]
}
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

if sys.version_info < (3, 9):
    raise SystemExit(f"arxiv-preflight requires Python 3.9+; got {sys.version.split()[0]}")

THIS_DIR = Path(__file__).resolve().parent
PATTERN_FILE = THIS_DIR.parent / "references" / "ai_artifact_patterns.md"

CATEGORY_BY_PREFIX = {
    "META": "llm_meta",
    "PROMPT": "prompt_residue",
    "PLACE": "placeholder",
    "AUTH": "authorship",
    "DISC": "disclosure",
    "CITE-FORM": "citation_format",
}
SEVERITIES = {"BLOCKER", "HIGH", "MEDIUM", "LOW"}

# Structural rules are excluded from the regex pass (they would either fail to
# compile as plain regex or match too liberally) and handled by dedicated scanners
# below: scan_authors (AUTH-*), scan_disclosure (DISC-*), scan_tables (PLACE-08/09).
STRUCTURAL_RULES = {"PLACE-08", "PLACE-09", "AUTH-01", "DISC-01"}
# Rules currently implemented as dedicated scanners (subset of STRUCTURAL_RULES).
IMPLEMENTED_STRUCTURAL = {"AUTH-01", "DISC-01"}

AUTHOR_RE = re.compile(r"\\author\s*(?:\[[^\]]*\])?\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}", re.IGNORECASE)
AI_TOOL_NAMES_RE = re.compile(
    r"\b(ChatGPT|GPT-?[345](?:\.[0-9]+)?|GPT|Claude(?:\s+\d(?:\.\d+)?)?|Gemini|Bard|Copilot|LLaMA|Llama|Mistral|PaLM|Anthropic|OpenAI)\b",
    re.IGNORECASE,
)
# Phrases that indicate the *paper itself* describes substantive AI/LLM use
# (as opposed to e.g. quoting an AI's output, which is caught by META-* rules).
SUBSTANTIVE_USE_RE = re.compile(
    r"\bwe\s+(?:used|employed|ran|applied|prompted|asked|queried|leveraged|adopted|utili[sz]ed|fine[- ]tuned|trained)\b"
    r"[^.]{0,80}?"
    r"\b(?:ChatGPT|GPT-?[345]|Claude|Gemini|Bard|Copilot|LLaMA|Llama|large language model|language model|LLM)\b",
    re.IGNORECASE,
)
DISCLOSURE_SECTION_RE = re.compile(
    r"^(?:acknowledg(?:e?)ments?|disclosure|ai\s+use|generative\s+ai|ethics?|ethical\s+considerations?|"
    r"limitations?|reproducibility|data\s+availability|competing\s+interests?)\b",
    re.IGNORECASE,
)


@dataclass
class Rule:
    rule_id: str
    pattern: re.Pattern
    severity: str
    category: str
    note: str = ""


@dataclass
class Finding:
    rule_id: str
    severity: str
    category: str
    file: str
    line: int
    snippet: str
    match: str


RULE_ROW_RE = re.compile(
    r"^\|\s*(?P<id>[A-Z][A-Z0-9\-]+)\s*\|\s*`(?P<regex>.+?)`\s*\|\s*(?P<sev>BLOCKER|HIGH|MEDIUM|LOW)\s*\|\s*(?P<note>.*?)\s*\|\s*$",
    re.IGNORECASE,
)


def parse_pattern_library(md_path: Path) -> list[Rule]:
    """Parse rule rows of the form `| ID | \`regex\` | SEVERITY | note |`.

    Splits on `|` are unsafe because the regex itself contains pipes; we extract
    the regex as the backtick-delimited cell instead.
    """
    text = md_path.read_text(encoding="utf-8")
    rules: list[Rule] = []
    for raw in text.splitlines():
        m = RULE_ROW_RE.match(raw.strip())
        if not m:
            continue
        rule_id = m.group("id")
        if rule_id == "ID":
            continue
        if rule_id in STRUCTURAL_RULES:
            continue
        severity = m.group("sev").upper()
        if severity not in SEVERITIES:
            continue
        regex_src = m.group("regex")
        try:
            flags = 0 if rule_id == "PLACE-01" else re.IGNORECASE
            compiled = re.compile(regex_src, flags)
        except re.error:
            continue
        prefix = rule_id.split("-")[0]
        rules.append(Rule(
            rule_id=rule_id,
            pattern=compiled,
            severity=severity,
            category=CATEGORY_BY_PREFIX.get(prefix, "other"),
            note=m.group("note"),
        ))
    return rules


def load_text_units(input_arg: Path, raw: bool) -> list[tuple[str, str]]:
    """Return a list of (file_label, text) units to scan.

    For raw mode, one unit per input file. For manuscript.json mode, we use the
    aggregated `raw_text` keyed by the `%%FILE ...` markers the extractor inserts.
    """
    if raw:
        return [(str(input_arg), input_arg.read_text(encoding="utf-8", errors="replace"))]
    data = json.loads(input_arg.read_text(encoding="utf-8"))
    raw_text = data.get("raw_text", "")
    if not raw_text:
        return []
    units: list[tuple[str, str]] = []
    chunks = re.split(r"\n%%FILE ([^\n]+)\n", raw_text)
    # split returns [pre, label1, body1, label2, body2, ...]
    if len(chunks) == 1:
        return [("manuscript", chunks[0])]
    for i in range(1, len(chunks), 2):
        label = chunks[i].strip()
        body = chunks[i + 1] if i + 1 < len(chunks) else ""
        units.append((label, body))
    return units


def _line_no(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def scan_authors(file_label: str, text: str) -> list[Finding]:
    """AUTH-01: detect AI tools listed in the \\author{} block."""
    findings: list[Finding] = []
    for m in AUTHOR_RE.finditer(text):
        author_field = m.group(1)
        line = _line_no(text, m.start())
        for am in AI_TOOL_NAMES_RE.finditer(author_field):
            tool = am.group(0)
            # Skip very common false positives: "GPT" alone is too short and
            # may legitimately appear inside an author affiliation acronym.
            if tool.lower() == "gpt":
                continue
            findings.append(Finding(
                rule_id="AUTH-01",
                severity="BLOCKER",
                category="authorship",
                file=file_label,
                line=line,
                snippet=("\\author{" + author_field + "}").replace("\n", " ").strip()[:240],
                match=tool,
            ))
    return findings


def scan_disclosure(file_label: str, text: str, section_titles: list[str]) -> list[Finding]:
    """DISC-01: substantive AI/LLM use described in body, no dedicated disclosure-style section.

    Heuristic — fires only when the manuscript itself describes using an LLM
    (e.g. "we used a commercial large language model"), to avoid double-firing
    on META-* matches (where an LLM artifact is in the text but the paper is
    not claiming substantive use).
    """
    use_match = SUBSTANTIVE_USE_RE.search(text)
    if not use_match:
        return []
    has_disclosure = any(DISCLOSURE_SECTION_RE.match(t.strip()) for t in section_titles)
    if has_disclosure:
        return []
    line = _line_no(text, use_match.start())
    return [Finding(
        rule_id="DISC-01",
        severity="MEDIUM",
        category="disclosure",
        file=file_label,
        line=line,
        snippet=use_match.group(0).strip()[:240],
        match=use_match.group(0).strip(),
    )]


def scan_text(file_label: str, text: str, rules: list[Rule]) -> list[Finding]:
    findings: list[Finding] = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        for rule in rules:
            for m in rule.pattern.finditer(line):
                snippet = line.strip()
                if len(snippet) > 200:
                    start = max(0, m.start() - 60)
                    end = min(len(line), m.end() + 60)
                    snippet = ("..." if start > 0 else "") + line[start:end].strip() + ("..." if end < len(line) else "")
                findings.append(Finding(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    category=rule.category,
                    file=file_label,
                    line=line_no,
                    snippet=snippet,
                    match=m.group(0),
                ))
    return findings


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--input", type=Path, help="manuscript.json from extract_manuscript_text.py")
    src.add_argument("--raw", type=Path, help="scan a single .tex / .md / .txt file directly")
    p.add_argument("--output", type=Path, default=Path("artifacts.json"))
    p.add_argument("--pattern-file", type=Path, default=PATTERN_FILE)
    args = p.parse_args()

    if not args.pattern_file.exists():
        print(f"error: pattern file not found: {args.pattern_file}", file=sys.stderr)
        return 2
    rules = parse_pattern_library(args.pattern_file)
    if not rules:
        print("error: no patterns parsed from library", file=sys.stderr)
        return 2

    input_path = args.input or args.raw
    units = load_text_units(input_path, raw=args.raw is not None)

    # Pull section titles from manuscript.json (when available) for DISC-01.
    section_titles: list[str] = []
    if args.input is not None:
        try:
            manuscript_data = json.loads(args.input.read_text(encoding="utf-8"))
            section_titles = [s.get("title", "") for s in manuscript_data.get("sections", [])]
        except Exception:
            pass

    findings: list[Finding] = []
    scanned_chars = 0
    for label, body in units:
        scanned_chars += len(body)
        findings.extend(scan_text(label, body, rules))
        findings.extend(scan_authors(label, body))
        findings.extend(scan_disclosure(label, body, section_titles))

    counts = {sev: 0 for sev in SEVERITIES}
    for f in findings:
        counts[f.severity] += 1

    still_deferred = sorted(STRUCTURAL_RULES - IMPLEMENTED_STRUCTURAL)
    warnings_out = []
    if still_deferred:
        warnings_out.append(
            f"Structural rules {still_deferred} are not yet implemented (table-level "
            "cell-repetition checks). Other structural rules are now handled by dedicated scanners."
        )

    result = {
        "findings": [f.__dict__ for f in findings],
        "counts": counts,
        "scanned_chars": scanned_chars,
        "rules_loaded": len(rules),
        "structural_rules_implemented": sorted(IMPLEMENTED_STRUCTURAL),
        "structural_rules_deferred": still_deferred,
        "warnings": warnings_out,
    }
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"wrote {args.output} — {sum(counts.values())} findings "
          f"(BLOCKER={counts['BLOCKER']} HIGH={counts['HIGH']} "
          f"MEDIUM={counts['MEDIUM']} LOW={counts['LOW']}) "
          f"using {len(rules)} regex rules over {scanned_chars} chars")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
