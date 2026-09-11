# arXiv Policy Notes — Authoritative Excerpts and Calibration

Sources (consult the live pages if a finding hinges on exact wording):

- arXiv Code of Conduct — <https://info.arxiv.org/help/policies/code_of_conduct.html>
- arXiv Content Moderation & generative-AI policy — <https://info.arxiv.org/help/moderation/index.html>
- Research Information, 2026-05-18 — "arXiv imposes one-year ban for unchecked AI-generated content" — <https://www.researchinformation.info/news/arxiv-imposes-one-year-ban-for-unchecked-ai-generated-content/>

## What arXiv actually requires

Paraphrased from the moderation page (verify before quoting verbatim in a report):

1. Authors **may** use generative-AI language tools (translation, polishing, search assistance, ideation, code).
2. Authors are **fully responsible** for everything in the manuscript regardless of the tools used.
3. Significant use of AI tools should be **disclosed according to the norms of the field** — e.g., in Methods, Acknowledgments, or an Ethics/Limitations section.
4. AI tools **cannot be listed as authors**. Authorship requires accountability and consent that a tool cannot give.
5. Manuscripts containing obvious unchecked AI output — fabricated references, residual prompt text, AI-meta commentary, placeholder data presented as results — can be rejected and the authors may be banned for up to a year (per the Research Information report).

## How to calibrate disclosure findings

Map detected AI signals to one of three recommendations. Do **not** push boilerplate disclosure on every paper.

| Detected use | Recommendation | Severity if absent |
| --- | --- | --- |
| Only formatting, spell-check, grammar polish, translation | No disclosure required | not a finding |
| Language polishing of full sections, summary drafting, paraphrasing | Brief disclosure in Acknowledgments or Methods if customary in the field | `LOW` / `MEDIUM` |
| AI used in research design, code generation, data analysis, figure creation, or non-trivial text generation | Disclose tool, scope of use, human verification process, and accountability | `HIGH` |
| AI listed as author or co-author | Remove AI from author list | `BLOCKER` |
| Manuscript contains obvious unverified AI output (fake refs, meta-comments, placeholder results) | Remediate before submission; disclosure alone does not fix this | `BLOCKER` |

The disclosure spectrum is field-dependent. ML/NLP venues are increasingly explicit about disclosure; pure-math and many physics subareas treat polish-only use as non-reportable. When in doubt, recommend the lighter touch and explain the reasoning.

## Moderation risks to flag (not predict)

arXiv moderation can reject or reclassify submissions. The skill should surface risk patterns, not predict outcomes.

- **Non-research format**: opinion / position / proposal / course project / lecture notes / dissertation chapter without clear research contribution. Flag as `MEDIUM` and recommend the author confirm the chosen primary category accepts the format.
- **Self-containedness**: paper requires unpublished supplementary material to be understood, or relies entirely on a private dataset. `MEDIUM`.
- **Copyright**: copy-pasted publisher PDF passages, screenshots of figures from other papers without permission, large verbatim quotes (>100 words) from copyrighted work, unredacted peer-review comments. `HIGH` or `BLOCKER` depending on extent.
- **Personal / political / commercial content**: ad hominem, marketing material, political advocacy. `HIGH`.
- **Salami / duplicate**: text or experiments appearing in multiple recent arXiv submissions by the same authors. `MEDIUM` — surface and ask the author to confirm not a split-paper situation.

## What this skill does *not* claim

- It does **not** decide whether arXiv will accept a paper. arXiv moderation is human-in-the-loop and context-dependent.
- It does **not** detect AI-authored text from stylistic features. Style is not evidence; meta-comments, fabricated citations, and placeholders are.
- It does **not** perform plagiarism detection at scale. It flags obvious copy-paste signals (e.g., quoted publisher text) but is not a substitute for iThenticate / Turnitin.
- It does **not** rewrite the author's claims. It locates and explains; the author decides.
