#!/usr/bin/env python3
"""Verify a BibTeX file against external metadata services.

Three layers per the strategy in references/reference_verification.md:
  1. Structural BibTeX checks (local).
  2. External metadata lookup (Crossref → arXiv → OpenAlex → Semantic Scholar).
  3. Field-agreement grading.

Usage:
    python verify_references.py --bib refs.bib --output refs.json \
        [--cites manuscript.json] [--email you@example.com] [--no-network]

`--cites` (optional) takes the `manuscript.json` produced by
`extract_manuscript_text.py` and additionally reports orphan citations (cited
keys with no BibTeX entry) and unused entries.

Stdlib only. Network failures degrade gracefully — the output's
`network_complete` flag is `false` when any external service was unavailable.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
from dataclasses import dataclass, field
from pathlib import Path

if sys.version_info < (3, 9):
    raise SystemExit(f"arxiv-preflight requires Python 3.9+; got {sys.version.split()[0]}")

DOI_RE = re.compile(r"^10\.\d{4,9}/[^\s]+$")
ARXIV_NEW = re.compile(r"^\d{4}\.\d{4,5}(v\d+)?$")
ARXIV_OLD = re.compile(r"^[a-z\-]+(\.[A-Z]{2})?/\d{7}(v\d+)?$")

REQUIRED_FIELDS = {
    "article": {"author", "title", "journal", "year"},
    "inproceedings": {"author", "title", "booktitle", "year"},
    "conference": {"author", "title", "booktitle", "year"},
    "book": {"author", "title", "publisher", "year"},
    "incollection": {"author", "title", "booktitle", "publisher", "year"},
    "phdthesis": {"author", "title", "school", "year"},
    "mastersthesis": {"author", "title", "school", "year"},
    "misc": {"title"},
    "techreport": {"author", "title", "institution", "year"},
    "unpublished": {"author", "title", "note"},
}


@dataclass
class BibEntry:
    key: str
    type: str
    fields: dict
    line: int

    def get(self, name: str) -> str | None:
        v = self.fields.get(name.lower())
        return v.strip() if v else None


def parse_bibtex(text: str) -> list[BibEntry]:
    """Forgiving BibTeX parser. Handles balanced braces and quoted values."""
    entries: list[BibEntry] = []
    i, n = 0, len(text)
    line_no = 1
    while i < n:
        ch = text[i]
        if ch == "\n":
            line_no += 1
            i += 1
            continue
        if ch != "@":
            i += 1
            continue
        entry_start_line = line_no
        i += 1
        type_match = re.match(r"[A-Za-z]+", text[i:])
        if not type_match:
            continue
        etype = type_match.group(0).lower()
        i += len(etype)
        while i < n and text[i] in " \t":
            i += 1
        if i >= n or text[i] not in "{(":
            continue
        opener = text[i]
        closer = "}" if opener == "{" else ")"
        i += 1
        # entry key up to first comma
        key_end = text.find(",", i)
        if key_end == -1:
            continue
        key = text[i:key_end].strip()
        line_no += text[i:key_end].count("\n")
        i = key_end + 1
        fields: dict[str, str] = {}
        depth = 1
        # Parse field=value pairs until matching closer with depth 0.
        while i < n and depth > 0:
            # skip whitespace and commas
            while i < n and text[i] in " \t\r\n,":
                if text[i] == "\n":
                    line_no += 1
                i += 1
            if i < n and text[i] == closer:
                depth -= 1
                i += 1
                break
            name_match = re.match(r"[A-Za-z][A-Za-z0-9_\-]*", text[i:])
            if not name_match:
                i += 1
                continue
            fname = name_match.group(0).lower()
            i += len(fname)
            while i < n and text[i] in " \t":
                i += 1
            if i >= n or text[i] != "=":
                continue
            i += 1
            while i < n and text[i] in " \t":
                i += 1
            value, consumed = _read_bib_value(text[i:])
            line_no += text[i:i + consumed].count("\n")
            fields[fname] = value
            i += consumed
        entries.append(BibEntry(key=key, type=etype, fields=fields, line=entry_start_line))
    return entries


def _read_bib_value(s: str) -> tuple[str, int]:
    if not s:
        return "", 0
    ch = s[0]
    if ch == "{":
        depth = 1
        i = 1
        while i < len(s) and depth > 0:
            if s[i] == "{":
                depth += 1
            elif s[i] == "}":
                depth -= 1
                if depth == 0:
                    return s[1:i], i + 1
            i += 1
        return s[1:], len(s)
    if ch == '"':
        i = 1
        while i < len(s):
            if s[i] == '"' and s[i - 1] != "\\":
                return s[1:i], i + 1
            i += 1
        return s[1:], len(s)
    # bare value until comma or close
    m = re.match(r"[^,\)\}\n]+", s)
    if m:
        return m.group(0).strip(), len(m.group(0))
    return "", 0


def clean_braces(value: str) -> str:
    return re.sub(r"[{}]", "", value or "").strip()


def first_author_surname(author_field: str) -> str:
    if not author_field:
        return ""
    first = author_field.split(" and ")[0].strip()
    first = clean_braces(first)
    if "," in first:
        return first.split(",")[0].strip()
    parts = first.split()
    return parts[-1] if parts else ""


def normalize_title(t: str) -> str:
    return re.sub(r"[^a-z0-9 ]+", " ", clean_braces(t).lower()).split()


def title_distance(a: str, b: str) -> float:
    """Crude normalized edit distance on whitespace-tokenised titles (0..1)."""
    A, B = normalize_title(a), normalize_title(b)
    if not A or not B:
        return 1.0
    common = sum(1 for w in A if w in B)
    return 1 - common / max(len(A), len(B))


# --- HTTP helpers --------------------------------------------------------

class ServiceUnavailable(Exception): ...


def http_get_json(url: str, headers: dict | None = None, timeout: int = 8):
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
            return json.loads(data.decode("utf-8", errors="replace"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        raise ServiceUnavailable(str(e))


def http_get_text(url: str, headers: dict | None = None, timeout: int = 8) -> str:
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, TimeoutError) as e:
        raise ServiceUnavailable(str(e))


# --- Layer 2 lookups -----------------------------------------------------

def lookup_crossref(doi: str, email: str | None) -> dict | None:
    ua = f"arxiv-preflight/1.0 (mailto:{email})" if email else "arxiv-preflight/1.0"
    data = http_get_json(f"https://api.crossref.org/works/{urllib.parse.quote(doi, safe='')}",
                         headers={"User-Agent": ua})
    msg = data.get("message", {})
    title = (msg.get("title") or [""])[0]
    authors = [f"{a.get('given','')} {a.get('family','')}".strip() for a in msg.get("author", [])]
    year = (msg.get("issued", {}).get("date-parts") or [[None]])[0][0]
    return {"source": "crossref", "title": title, "authors": authors, "year": year,
            "doi": msg.get("DOI"), "venue": (msg.get("container-title") or [""])[0]}


def lookup_arxiv(arxiv_id: str) -> dict | None:
    text = http_get_text(f"http://export.arxiv.org/api/query?id_list={urllib.parse.quote(arxiv_id)}")
    title = re.search(r"<entry>.*?<title>(.+?)</title>", text, re.DOTALL)
    authors = re.findall(r"<author>\s*<name>(.+?)</name>", text)
    year_m = re.search(r"<published>(\d{4})", text)
    if not title:
        return None
    return {"source": "arxiv", "title": title.group(1).strip(), "authors": authors,
            "year": int(year_m.group(1)) if year_m else None,
            "arxiv_id": arxiv_id}


def lookup_openalex(title: str, author: str, email: str | None) -> dict | None:
    params = {"search": title, "per-page": "1"}
    if email:
        params["mailto"] = email
    url = "https://api.openalex.org/works?" + urllib.parse.urlencode(params)
    data = http_get_json(url)
    works = data.get("results") or []
    if not works:
        return None
    w = works[0]
    authors = [a.get("author", {}).get("display_name", "") for a in w.get("authorships", [])]
    primary_location = w.get("primary_location") or {}
    source = primary_location.get("source") or {}
    return {"source": "openalex", "title": w.get("title", ""),
            "authors": authors, "year": w.get("publication_year"),
            "doi": (w.get("doi") or "").replace("https://doi.org/", "") or None,
            "venue": source.get("display_name", "")}


def lookup_semantic_scholar(title: str) -> dict | None:
    params = {"query": title, "limit": 1, "fields": "title,authors,year,externalIds,venue"}
    url = "https://api.semanticscholar.org/graph/v1/paper/search?" + urllib.parse.urlencode(params)
    data = http_get_json(url)
    items = data.get("data") or []
    if not items:
        return None
    it = items[0]
    return {"source": "semantic_scholar", "title": it.get("title", ""),
            "authors": [a.get("name", "") for a in it.get("authors", [])],
            "year": it.get("year"),
            "doi": (it.get("externalIds") or {}).get("DOI"),
            "venue": it.get("venue", "")}


# --- Per-entry verification ---------------------------------------------

def layer1(entry: BibEntry) -> dict:
    issues = []
    required = REQUIRED_FIELDS.get(entry.type, {"title"})
    for fld in required:
        if not entry.get(fld):
            issues.append({"severity": "MEDIUM", "msg": f"missing required field `{fld}`"})
    doi = entry.get("doi")
    if doi and not DOI_RE.match(doi.lower()):
        issues.append({"severity": "MEDIUM", "msg": f"DOI does not match 10.XXXX/... pattern: {doi}"})
    arxiv_id = entry.get("eprint") or entry.get("arxivid")
    if arxiv_id and not (ARXIV_NEW.match(arxiv_id) or ARXIV_OLD.match(arxiv_id)):
        issues.append({"severity": "MEDIUM", "msg": f"arXiv ID does not match expected format: {arxiv_id}"})
    year = entry.get("year")
    if year and year.isdigit():
        yi = int(year)
        from datetime import datetime
        cur = datetime.utcnow().year
        if yi < 1800 or yi > cur + 1:
            issues.append({"severity": "HIGH", "msg": f"implausible year: {year}"})
    return {"status": "ok" if not issues else "issues", "issues": issues}


def layer2(entry: BibEntry, email: str | None, unavailable: set) -> dict:
    queried, matched, candidate = [], None, None

    def try_call(name, fn):
        nonlocal matched, candidate
        if name in unavailable:
            return
        queried.append(name)
        try:
            result = fn()
            if result:
                candidate, matched = result, name
        except ServiceUnavailable:
            unavailable.add(name)

    doi = entry.get("doi")
    if doi:
        try_call("crossref", lambda: lookup_crossref(doi, email))
    arxiv_id = entry.get("eprint") or entry.get("arxivid")
    if not candidate and arxiv_id:
        try_call("arxiv", lambda: lookup_arxiv(arxiv_id))
    if not candidate:
        title = clean_braces(entry.get("title") or "")
        author = first_author_surname(entry.get("author") or "")
        if title:
            try_call("openalex", lambda: lookup_openalex(title, author, email))
        if not candidate and title:
            try_call("semantic_scholar", lambda: lookup_semantic_scholar(title))
    return {"queried": queried, "matched_by": matched, "candidate": candidate}


def layer3(entry: BibEntry, candidate: dict | None) -> dict:
    if not candidate:
        return {"disagreements": []}
    disagreements = []
    bib_title = clean_braces(entry.get("title") or "")
    cand_title = candidate.get("title") or ""
    if bib_title and cand_title:
        dist = title_distance(bib_title, cand_title)
        if dist > 0.25:
            disagreements.append({"field": "title", "bib": bib_title, "external": cand_title,
                                  "severity": "HIGH", "distance": round(dist, 3)})
    bib_author = first_author_surname(entry.get("author") or "")
    cand_authors = candidate.get("authors") or []
    cand_author = first_author_surname(cand_authors[0] if cand_authors else "")
    if bib_author and cand_author and bib_author.lower() != cand_author.lower():
        disagreements.append({"field": "first_author", "bib": bib_author, "external": cand_author,
                              "severity": "HIGH"})
    bib_year = entry.get("year")
    cand_year = candidate.get("year")
    if bib_year and bib_year.isdigit() and cand_year:
        diff = abs(int(bib_year) - int(cand_year))
        if diff > 1:
            disagreements.append({"field": "year", "bib": bib_year, "external": cand_year, "severity": "HIGH"})
        elif diff == 1:
            disagreements.append({"field": "year", "bib": bib_year, "external": cand_year, "severity": "LOW"})
    return {"disagreements": disagreements}


def verdict_for(layer1_out, layer2_out, layer3_out, formatting_tells: int) -> tuple[str, str]:
    """Return (severity, summary)."""
    has_format_tells = formatting_tells > 0
    sev_order = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "BLOCKER": 4}
    worst = "LOW"
    for issue in layer1_out["issues"]:
        if sev_order[issue["severity"]] > sev_order[worst]:
            worst = issue["severity"]
    if layer2_out["matched_by"] is None:
        if all(svc in layer2_out["queried"] for svc in ("crossref", "openalex", "semantic_scholar")) and has_format_tells:
            return "BLOCKER", "No candidate across all reachable services; entry has formatting tells consistent with fabrication."
        if layer2_out["queried"]:
            return ("HIGH" if sev_order["HIGH"] > sev_order[worst] else worst,
                    "No external candidate matched; could not be confirmed (verify manually).")
    for d in layer3_out["disagreements"]:
        if sev_order[d["severity"]] > sev_order[worst]:
            worst = d["severity"]
    # Triple-disagreement escalation: when the external service returned a
    # candidate but the title and first-author both disagree AT SCALE, the
    # service has likely surfaced an irrelevant token-overlap match. The
    # combined signal then resembles "no real match" and we escalate to
    # BLOCKER. The 0.5 distance threshold guards against the common
    # follow-up-paper pattern where the bib title is fully contained in
    # the external title (e.g. "Dense Passage Retrieval ..." ⊂ "RocketQA: ...
    # Dense Passage Retrieval ...") — that case should stay HIGH.
    title_disagreement = next(
        (d for d in layer3_out["disagreements"] if d["field"] == "title"),
        None,
    )
    author_high = any(d["field"] == "first_author" and d["severity"] == "HIGH"
                      for d in layer3_out["disagreements"])
    if (title_disagreement and title_disagreement["severity"] == "HIGH"
            and title_disagreement.get("distance", 0) >= 0.5
            and author_high):
        return ("BLOCKER",
                "Title and first author both disagree with the matched external candidate, "
                "and the title shares little content with it. The service returned an "
                "unrelated paper — the entry is unverifiable, likely fabricated.")
    summary = "OK" if worst == "LOW" and not layer3_out["disagreements"] and layer2_out["matched_by"] else f"Issues: {worst}"
    return worst, summary


def count_format_tells(entry: BibEntry) -> int:
    """Cheap version of references/ai_artifact_patterns.md §5."""
    tells = 0
    doi = entry.get("doi")
    if doi and not DOI_RE.match(doi.lower()):
        tells += 1
    year = entry.get("year")
    if year and year.isdigit():
        from datetime import datetime
        if int(year) > datetime.utcnow().year + 1:
            tells += 1
    venue = entry.get("journal") or entry.get("booktitle") or ""
    if venue and re.search(r"international conference on \w+ and \w+", venue, re.IGNORECASE):
        tells += 1
    return tells


# --- Citation reconciliation --------------------------------------------

def reconcile_citations(entries: list[BibEntry], manuscript_json: Path | None) -> list[dict]:
    if not manuscript_json or not manuscript_json.exists():
        return []
    data = json.loads(manuscript_json.read_text(encoding="utf-8"))
    defined = {e.key for e in entries}
    cited_records = data.get("cite_keys", [])
    cited = {c["key"] for c in cited_records}
    issues = []
    for c in cited_records:
        if c["key"] not in defined:
            issues.append({"severity": "HIGH", "kind": "undefined_citation",
                           "key": c["key"], "file": c["file"], "line": c["line"]})
    for e in entries:
        if e.key not in cited:
            issues.append({"severity": "LOW", "kind": "unused_entry",
                           "key": e.key, "file": "", "line": e.line})
    return issues


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bib", type=Path, required=True)
    p.add_argument("--output", type=Path, default=Path("refs.json"))
    p.add_argument("--cites", type=Path, default=None, help="manuscript.json for citation reconciliation")
    p.add_argument("--email", default=os.environ.get("ARXIV_PREFLIGHT_EMAIL"),
                   help="Contact email for Crossref polite pool and OpenAlex mailto")
    p.add_argument("--no-network", action="store_true", help="Skip layer 2 entirely")
    p.add_argument("--rate-limit-s", type=float, default=0.25, help="Delay between external calls")
    args = p.parse_args()

    text = args.bib.read_text(encoding="utf-8")
    entries = parse_bibtex(text)
    if not entries:
        print("warning: no BibTeX entries parsed", file=sys.stderr)

    # Detect duplicate keys.
    seen_keys: dict[str, int] = {}
    duplicate_keys = []
    for e in entries:
        if e.key in seen_keys:
            duplicate_keys.append({"key": e.key, "first_line": seen_keys[e.key], "duplicate_line": e.line})
        else:
            seen_keys[e.key] = e.line

    unavailable: set[str] = set()
    if args.no_network:
        unavailable.update({"crossref", "arxiv", "openalex", "semantic_scholar"})

    per_entry = []
    for e in entries:
        l1 = layer1(e)
        l2 = layer2(e, args.email, unavailable) if not args.no_network else {"queried": [], "matched_by": None, "candidate": None}
        l3 = layer3(e, l2.get("candidate"))
        verdict, summary = verdict_for(l1, l2, l3, count_format_tells(e))
        per_entry.append({
            "entry_key": e.key,
            "entry_type": e.type,
            "line": e.line,
            "layer1": l1,
            "layer2": l2,
            "layer3": l3,
            "verdict": verdict,
            "summary": summary,
        })
        if not args.no_network:
            time.sleep(args.rate_limit_s)

    citation_issues = reconcile_citations(entries, args.cites)

    network_complete = not bool(unavailable) and not args.no_network
    result = {
        "bib_file": str(args.bib),
        "entry_count": len(entries),
        "duplicate_keys": duplicate_keys,
        "per_entry": per_entry,
        "citation_issues": citation_issues,
        "network_complete": network_complete,
        "services_unavailable": sorted(unavailable),
    }
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"wrote {args.output} — {len(entries)} entries, "
          f"{len(citation_issues)} citation issues, "
          f"network_complete={network_complete}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
