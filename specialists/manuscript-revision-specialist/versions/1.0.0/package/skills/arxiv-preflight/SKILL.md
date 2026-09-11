---
name: arxiv-preflight
description: "Run a submission-readiness preflight on a manuscript before arXiv upload. Use when the user is preparing an arXiv submission, asks to check a paper before uploading, mentions hallucinated or fake references, leftover LLM meta-comments / prompts in text, placeholder data (TODO, TBD, XX%), AI-use disclosure, scholarly integrity, research integrity, or arXiv moderation risk — even if they don't say \"preflight\". Also trigger on phrases like \"check my paper before arXiv\", \"verify my references\", \"scan for AI artifacts\", \"scan for LLM residue\", \"is my submission ready\", or \"review .tex/.bib before submit\"."
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# arXiv Preflight

Submission-readiness review for a manuscript before arXiv upload. The goal is **not** to judge whether a paper was AI-written from style. The goal is to find concrete, locatable, reviewable evidence of unchecked LLM output, hallucinated references, placeholder data, unsupported claims, and arXiv-policy risks — and to hand the author a fix list.

Anchor on the actual arXiv stance: authors may use generative AI tools but are fully responsible for the content and must disclose significant use per field norms; AI tools cannot be listed as authors. See `references/arxiv_policy_notes.md` for the exact language.

This skill is intentionally platform-neutral. It should work for any AI coding/review agent that can read files and run local Python scripts; it does not require OpenAI-specific UI metadata.

Requires Python 3.9+.

## Workflow

1. **Identify inputs.** Ask for or detect: LaTeX project directory, single PDF, BibTeX file, supplementary figures/tables, or experiment data. Prefer LaTeX source over rendered PDF — PDF text extraction loses structure and produces noisier reference checks.

2. **Extract manuscript text.** Run `scripts/extract_manuscript_text.py` on the input. It merges `\input`/`\include`, strips LaTeX commands while preserving section/figure/table/citation keys, and falls back to PDF text extraction. Output: `manuscript.json` with `sections`, `figures`, `tables`, `cite_keys`, `numbers`, and `warnings`. Treat unresolved or skipped includes as review risks.

3. **Hard-red-line scan.** Run `scripts/scan_ai_artifacts.py` against the extracted text. It flags LLM meta-comments, prompt residue, placeholder content, TODO/TBD/XX%, and AI-listed-as-author. Patterns live in `references/ai_artifact_patterns.md` — extend the list when the user reports new failure modes. Any hit is a `BLOCKER` unless the user explicitly justifies it.

4. **Verify references.** Run `scripts/verify_references.py` on `.bib` (or extracted reference list). It performs (a) structural BibTeX checks, (b) external metadata lookup against Crossref / arXiv / OpenAlex / Semantic Scholar (in that order), (c) cite-key vs. \cite reconciliation. Grading and API strategy: `references/reference_verification.md`. **If network is unavailable, mark this section `INCOMPLETE` rather than skipping silently.**

5. **Cross-check claims, numbers, and figure/table references.** Use `manuscript.json` to review extracted numbers, labels, and references. This version exposes the raw structures for agent-assisted consistency review; it does not fully automate semantic claim verification. Surface candidate inconsistencies for the author to confirm, never rewrite their claims.

6. **AI-use disclosure check.** `scripts/scan_ai_artifacts.py` includes a limited disclosure heuristic for substantive LLM use. For nuanced cases, compare detected AI-assistance signals against the manuscript's Acknowledgments / Methods / Ethics sections yourself. Recommend disclosure only when significant use is evident; do not push boilerplate disclosure on every paper. Calibration: `references/arxiv_policy_notes.md`.

7. **arXiv moderation pre-check.** Do an agent-assisted scan for non-research content (opinion/proposal/course-project framing without research contribution), copyright risks (publisher PDFs, reviewer comments, unlicensed images, long third-party text), and salami/duplicate-submission signals. This version does not ship a dedicated moderation scanner. Do not predict whether arXiv will accept — only surface risk.

8. **Generate report.** Run `scripts/generate_preflight_report.py` to merge all JSON outputs into a single Markdown report. Format and decision rules: `references/report_template.md`.

## Risk levels

- `BLOCKER` — evidence that should stop submission: LLM meta-comment in body text, AI listed as author, reference that cannot be matched in any external database, unfilled placeholder in a results table.
- `HIGH` — likely integrity or policy issue: DOI/title mismatch, cite-key pointing at wrong paper, a strong claim with no supporting number in the manuscript.
- `MEDIUM` — inconsistency, missing metadata, unclear disclosure, broken \ref.
- `LOW` — polish, formatting, capitalization.

## Decision rule

- Any `BLOCKER` → `HOLD`.
- No blocker, any `HIGH`/`MEDIUM` → `PASS_WITH_FIXES`.
- Only `LOW` or clean → `PASS`.

Never upgrade a finding's severity to be safe and never silently soften it. If you are unsure, mark it `MEDIUM` and explain.

## Rules

- **Never call a paper AI-generated from writing style alone.** Style is not evidence; meta-comments, fake citations, and placeholders are.
- **Every finding must cite a location.** File + line number for `.tex`/`.bib`; for PDF input, use the PDF file plus extracted-text line unless page-aware extraction is available. Include a verbatim short snippet (≤ 25 words). A finding without a location is a suggestion, not a finding — move it to "Recommended Cleanup".
- **Treat external-metadata mismatches as leads.** A single field disagreement (e.g., page numbers) is `MEDIUM`. Title + authors + year all unmatched across all four databases is `BLOCKER`.
- **Network-incomplete is not network-pass.** If reference lookups failed for connectivity reasons, the report's reference section is `INCOMPLETE`; the overall decision cannot be `PASS`.
- **Do not rewrite the author's claims.** Provide fixes, questions, and locations. Leave the rewriting to the author.
- **Minimise false positives at the cost of recall.** This tool runs before submission; a false `BLOCKER` is more costly than a missed `LOW`.

## When to read which reference

- `references/arxiv_policy_notes.md` — when calibrating disclosure recommendations or moderation findings.
- `references/ai_artifact_patterns.md` — when extending or interpreting the artifact scanner's hits.
- `references/reference_verification.md` — when interpreting citation lookup output, deciding API order, or handling rate-limit / network failures.
- `references/report_template.md` — when writing or regenerating the final report.

## MVP scope

This skill currently ships: text extraction, AI-artifact scan, BibTeX + DOI/arXiv-ID reference verification, extracted label/citation/number structures, and Markdown report generation. Out of scope for v1: full semantic peer review, full claim/result verification, automated moderation judgement, AI-writing probability scoring, automatic rewriting, automated arXiv upload, large-scale plagiarism detection. If the user asks for these, say so explicitly rather than approximating.
