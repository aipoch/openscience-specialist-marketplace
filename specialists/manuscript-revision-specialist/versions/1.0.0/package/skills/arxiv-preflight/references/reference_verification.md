# Reference Verification

Goal: decide for each cited reference whether it (a) parses as a well-formed BibTeX entry, (b) corresponds to a real publication, and (c) the cited fields (title, authors, year, venue, DOI/arXiv ID) agree with external metadata.

The biggest single risk we are guarding against is **fabricated references** — entries that look plausible but do not match any real paper. The verifier should be conservative: a single failed lookup is not proof of fabrication, but failure across all reachable databases combined with format tells (see `ai_artifact_patterns.md` §5) is strong evidence.

---

## Three-layer check

### Layer 1 — structural

Performed locally, no network. Output is per-entry.

- Required fields present for the entry type (e.g., `@article` needs `author`, `title`, `journal`, `year`).
- DOI string matches `^10\.\d{4,9}/[^\s]+$` if present.
- arXiv ID matches new (`\d{4}\.\d{4,5}(v\d+)?`) or old (`[a-z\-]+(\.[A-Z]{2})?/\d{7}(v\d+)?`) style if present.
- Year is plausible (1800 ≤ year ≤ current year + 1).
- BibTeX keys are unique within the file.
- Every `\cite{KEY}` in the manuscript resolves to a defined key; every defined key is cited at least once.

Output: `LOW` for missing optional fields, `MEDIUM` for structural problems (bad DOI format, key collisions), `HIGH` for `\cite` of an undefined key.

### Layer 2 — external metadata lookup

Performed in this order; stop at the first authoritative hit:

1. **DOI lookup via Crossref** — `https://api.crossref.org/works/{doi}`. Free, no auth, rate-limited (~50 req/s). Authoritative when DOI is present.
2. **arXiv ID lookup via arXiv API** — `http://export.arxiv.org/api/query?id_list={id}`. Free, no auth. Authoritative when arXiv ID is present.
3. **Title + first-author lookup via OpenAlex** — `https://api.openalex.org/works?search={title}&filter=author.display_name.search:{first_author}`. Free, no auth, rate-limited; include a `mailto=` parameter for the polite pool.
4. **Title + first-author lookup via Semantic Scholar** — `https://api.semanticscholar.org/graph/v1/paper/search?query={title}`. Free with optional API key; rate-limited.

Optional domain-specific:

- **PubMed** for biomedical entries — `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=...`.
- **ACL Anthology** for NLP entries — title search against `https://aclanthology.org/`. No formal API; treat as confirmatory only.

### Layer 3 — field agreement

Compare returned metadata against the BibTeX entry:

| Field disagreement | Severity |
| --- | --- |
| Title differs by > 25% normalized edit distance | HIGH |
| First author surname differs | HIGH |
| Year differs by more than 1 | HIGH |
| Year differs by exactly 1 (publication-vs-acceptance) | LOW |
| Venue / journal differs | MEDIUM |
| Page numbers or volume differ | LOW |
| DOI in BibTeX does not resolve, but title+author do match in another DB | MEDIUM |

If no DB returns any candidate for the title and any author across all four primary services, escalate to `BLOCKER`. This is the fabricated-reference signal.

---

## Network handling

- All HTTP calls must use a default timeout of 8 s and a single retry with exponential backoff.
- If a service returns a non-2xx response or times out, mark that service as "unavailable" for this run and continue with the next.
- If **all** services are unavailable, the verification section of the report is `INCOMPLETE` and the overall decision **cannot** be `PASS` (it becomes `PASS_WITH_FIXES` at best, with the reference section explicitly flagged).
- Respect rate limits; default to ≤ 5 req/s when no service-specific guidance is given. Crossref's polite pool requires a `User-Agent` with an email; set one.
- Cache responses keyed by DOI / arXiv ID / normalized (title + first author) in a local JSON file for the duration of one preflight run.

## Output schema

```json
{
  "entry_key": "smith2024fake",
  "layer1": {"status": "ok", "issues": []},
  "layer2": {
    "queried": ["crossref", "arxiv", "openalex", "semantic_scholar"],
    "matched_by": "openalex",
    "candidate": {"title": "...", "authors": [...], "year": 2023, "doi": "..."}
  },
  "layer3": {
    "disagreements": [{"field": "year", "bib": 2024, "external": 2023, "severity": "LOW"}]
  },
  "verdict": "MEDIUM",
  "summary": "Year off by 1; otherwise matches."
}
```

## Grading rule (verdict per entry)

- `LOW` — only structural polish issues or single low-severity field disagreement.
- `MEDIUM` — multiple low / one medium disagreement, or layer-2 only matched via fuzzy title.
- `HIGH` — DOI or arXiv ID points at a different paper, or title/year/first-author mismatch.
- `BLOCKER` — no candidate found across all reachable services, **and** the entry has citation-formatting tells (see `ai_artifact_patterns.md` §5).

A single "no match" without formatting tells is `HIGH`, not `BLOCKER` — many real papers (workshops, theses, regional venues) are missing from these databases.
