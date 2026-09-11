#!/usr/bin/env python3
"""Extract structured text from a LaTeX project or PDF manuscript.

Usage:
    python extract_manuscript_text.py --input PATH --output manuscript.json

PATH may be a directory containing .tex files, a single .tex file, or a .pdf file.

Output JSON schema (see references/report_template.md for downstream consumers):
{
  "source_type": "latex" | "pdf",
  "root_files": [...],
  "raw_text": "<concatenated body text>",
  "sections": [{"title": "...", "level": 1, "line": 12, "file": "main.tex"}],
  "figures":  [{"label": "...", "line": ..., "file": "..."}],
  "tables":   [{"label": "...", "line": ..., "file": "..."}],
  "cite_keys":   [{"key": "smith2024", "line": ..., "file": "..."}],
  "label_defs":  [{"label": "fig:foo", "line": ..., "file": "..."}],
  "label_refs":  [{"label": "fig:foo", "line": ..., "file": "..."}],
  "numbers":     [{"value": "92.3", "context": "achieves 92.3% accuracy", "line": ..., "file": "..."}],
  "warnings": [...]
}

Stdlib only. PDF path uses `pdftotext` if available; otherwise reports a warning.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable

if sys.version_info < (3, 9):
    raise SystemExit(f"arxiv-preflight requires Python 3.9+; got {sys.version.split()[0]}")

INPUT_INCLUDE_RE = re.compile(r"\\(?:input|include|subfile)\{([^}]+)\}")
SECTION_RE = re.compile(r"\\(part|chapter|section|subsection|subsubsection|paragraph)\*?\{([^}]*)\}")
LEVEL = {"part": 0, "chapter": 1, "section": 1, "subsection": 2, "subsubsection": 3, "paragraph": 4}
FIGURE_BEGIN = re.compile(r"\\begin\{figure\*?\}")
TABLE_BEGIN = re.compile(r"\\begin\{table\*?\}")
LABEL_RE = re.compile(r"\\label\{([^}]+)\}")
REF_RE = re.compile(r"\\(?:ref|eqref|autoref|cref|Cref)\{([^}]+)\}")
CITE_RE = re.compile(r"\\(?:cite|citep|citet|citeauthor|citeyear|parencite|textcite)\*?(?:\[[^\]]*\])?(?:\[[^\]]*\])?\{([^}]+)\}")
COMMENT_RE = re.compile(r"(?<!\\)%.*?$", re.MULTILINE)
VERBATIM_BLOCK_RE = re.compile(
    r"\\begin\{(verbatim|lstlisting|minted|alltt)\*?\}.*?\\end\{\1\*?\}",
    re.DOTALL,
)
# A "number in context" — keep ≤ 30 surrounding chars before, ≤ 60 after, with a unit hint.
NUMBER_RE = re.compile(
    r"(?P<pre>.{0,30})\b(?P<num>\d+(?:\.\d+)?)(?P<unit>\s?%|\s?(?:percent|points?|ms|s|sec(?:onds)?|x|×|fold|dB|GB|MB|TB|Hz|FLOPs?))?(?P<post>.{0,60})",
    re.IGNORECASE,
)


def strip_comments_and_verbatim(text: str) -> str:
    """Remove LaTeX line comments and verbatim/code blocks.

    Returns a string with the same line count so downstream line numbers stay valid.
    """
    def blank_keeping_lines(m: re.Match) -> str:
        return "\n" * m.group(0).count("\n")

    text = VERBATIM_BLOCK_RE.sub(blank_keeping_lines, text)
    text = COMMENT_RE.sub("", text)
    return text


def discover_root_tex(root: Path) -> list[Path]:
    """Pick likely entry files: those that contain \\documentclass."""
    candidates: list[Path] = []
    for tex in root.rglob("*.tex"):
        try:
            head = tex.read_text(encoding="utf-8", errors="replace")[:4000]
        except Exception:
            continue
        if "\\documentclass" in head:
            candidates.append(tex)
    return candidates or sorted(root.rglob("*.tex"))[:1]


def resolve_include(parent: Path, target: str) -> Path | None:
    candidate = (parent.parent / target).resolve()
    if candidate.suffix == "":
        candidate = candidate.with_suffix(".tex")
    if candidate.exists():
        return candidate
    return None


def walk_tex(root_tex: Path, project_root: Path, seen: set[Path], warnings: list[str]) -> Iterable[tuple[Path, str]]:
    """Yield (file_path, raw_text_with_includes_inlined_as_marker) in include order.

    We do not actually inline file contents into one stream — downstream consumers
    want per-file line numbers. We yield each file individually.
    """
    if root_tex in seen:
        return
    seen.add(root_tex)
    try:
        text = root_tex.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return
    yield root_tex, text
    for match in INPUT_INCLUDE_RE.finditer(text):
        include_target = match.group(1)
        child = resolve_include(root_tex, include_target)
        if not child:
            warnings.append(f"{root_tex}: unresolved include `{include_target}`")
            continue
        if not child.is_relative_to(project_root):
            warnings.append(f"{root_tex}: skipped include `{include_target}` outside project root: {child}")
            continue
        yield from walk_tex(child, project_root, seen, warnings)


def _line_no(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def parse_latex_file(path: Path, text: str) -> dict:
    """Run all extractors on the whole cleaned text.

    Line-by-line scanning loses citations and refs that span lines
    (e.g., `\\cite{a,\\n b}`); scan whole-text and back-resolve line numbers.
    """
    cleaned = strip_comments_and_verbatim(text)
    sections, figures, tables = [], [], []
    cite_keys, label_defs, label_refs, numbers = [], [], [], []
    file_str = str(path)

    for m in SECTION_RE.finditer(cleaned):
        sections.append({
            "title": m.group(2).strip(),
            "level": LEVEL.get(m.group(1), 5),
            "line": _line_no(cleaned, m.start()),
            "file": file_str,
        })
    for m in LABEL_RE.finditer(cleaned):
        label = m.group(1)
        ln = _line_no(cleaned, m.start())
        label_defs.append({"label": label, "line": ln, "file": file_str})
        if label.startswith("fig:"):
            figures.append({"label": label, "line": ln, "file": file_str})
        elif label.startswith("tab:") or label.startswith("table:"):
            tables.append({"label": label, "line": ln, "file": file_str})
    for m in REF_RE.finditer(cleaned):
        ln = _line_no(cleaned, m.start())
        for label in m.group(1).split(","):
            label_refs.append({"label": label.strip(), "line": ln, "file": file_str})
    for m in CITE_RE.finditer(cleaned):
        ln = _line_no(cleaned, m.start())
        for key in m.group(1).split(","):
            key = key.strip()
            if key:
                cite_keys.append({"key": key, "line": ln, "file": file_str})
    # Numbers run line-by-line because the context window is line-local anyway.
    for idx, line in enumerate(cleaned.splitlines(), start=1):
        for m in NUMBER_RE.finditer(line):
            unit = (m.group("unit") or "").strip()
            if not unit and not _looks_like_metric(line):
                continue
            numbers.append({
                "value": m.group("num"),
                "unit": unit,
                "context": (m.group("pre") + m.group("num") + (m.group("unit") or "") + m.group("post")).strip(),
                "line": idx,
                "file": file_str,
            })
    return {
        "sections": sections,
        "figures": figures,
        "tables": tables,
        "cite_keys": cite_keys,
        "label_defs": label_defs,
        "label_refs": label_refs,
        "numbers": numbers,
        "raw_text": cleaned,
    }


def _looks_like_metric(line: str) -> bool:
    return bool(re.search(r"\b(accuracy|f1|bleu|rouge|recall|precision|mse|rmse|mae|auc|auroc|aupr|loss|perplexity|map|ndcg|wer|cer)\b", line, re.IGNORECASE))


def extract_latex(input_path: Path) -> dict:
    if input_path.is_file():
        roots = [input_path.resolve()]
        project_root = input_path.parent.resolve()
    else:
        project_root = input_path.resolve()
        roots = [p.resolve() for p in discover_root_tex(project_root)]
    if not roots:
        return {"source_type": "latex", "warnings": ["no .tex files discovered"], "raw_text": ""}
    aggregated = {
        "source_type": "latex",
        "root_files": [str(p) for p in roots],
        "raw_text": "",
        "sections": [], "figures": [], "tables": [],
        "cite_keys": [], "label_defs": [], "label_refs": [], "numbers": [],
        "warnings": [],
    }
    seen: set[Path] = set()
    for root in roots:
        for path, text in walk_tex(root, project_root, seen, aggregated["warnings"]):
            parsed = parse_latex_file(path, text)
            aggregated["raw_text"] += f"\n%%FILE {path}\n" + parsed.pop("raw_text")
            for key in ["sections", "figures", "tables", "cite_keys", "label_defs", "label_refs", "numbers"]:
                aggregated[key].extend(parsed[key])
    return aggregated


def extract_pdf(input_path: Path) -> dict:
    if not shutil.which("pdftotext"):
        return {
            "source_type": "pdf",
            "raw_text": "",
            "warnings": [
                "pdftotext not available; install poppler (`brew install poppler` / `apt install poppler-utils`)"
                " or pass the LaTeX source instead — PDF reference checks are less reliable."
            ],
            "sections": [], "figures": [], "tables": [],
            "cite_keys": [], "label_defs": [], "label_refs": [], "numbers": [],
        }
    try:
        out = subprocess.run(
            ["pdftotext", "-layout", str(input_path), "-"],
            capture_output=True, text=True, timeout=60, check=True,
        )
    except subprocess.CalledProcessError as e:
        return {"source_type": "pdf", "raw_text": "", "warnings": [f"pdftotext failed: {e}"]}
    text = out.stdout
    numbers = []
    for idx, line in enumerate(text.splitlines(), start=1):
        for m in NUMBER_RE.finditer(line):
            unit = (m.group("unit") or "").strip()
            if not unit and not _looks_like_metric(line):
                continue
            numbers.append({
                "value": m.group("num"),
                "unit": unit,
                "context": line.strip()[:140],
                "line": idx,
                "file": str(input_path),
            })
    return {
        "source_type": "pdf",
        "root_files": [str(input_path)],
        "raw_text": f"\n%%FILE {input_path.resolve()}\n{text}",
        "sections": [], "figures": [], "tables": [],
        "cite_keys": [], "label_defs": [], "label_refs": [],
        "numbers": numbers,
        "warnings": ["PDF input — section/cite/label structure not recovered; supply LaTeX source for full checks."],
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", type=Path, default=Path("manuscript.json"))
    args = p.parse_args()

    if not args.input.exists():
        print(f"error: {args.input} does not exist", file=sys.stderr)
        return 2
    if args.input.suffix.lower() == ".pdf":
        result = extract_pdf(args.input)
    else:
        result = extract_latex(args.input)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"wrote {args.output} ({len(result.get('raw_text', ''))} chars, "
          f"{len(result.get('sections', []))} sections, "
          f"{len(result.get('cite_keys', []))} citations)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
