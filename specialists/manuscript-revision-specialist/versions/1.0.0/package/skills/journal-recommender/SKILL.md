---
name: journal-recommender
description: Recommend academic journals based on manuscript topic, abstract, and impact factor expectations. Use when the user wants to find suitable journals for their research manuscript, especially when they provide a topic, abstract, and target Impact Factor.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)


## Output Format

All recommendations must follow the three-tier table format below. Each tier must recommend at least **5 journals**.

```
## Journal Recommendation Report

### Recommendation Overview
| Tier | Count | Strategy |
|---------|:------:|---------|
| Sprint | N | Impact factor higher than target, requires some luck |
| Robust | N | Impact factor matches target, higher hit rate |
| Safe | N | Impact factor lower than target, near-certain acceptance |

### Sprint Journals
| Journal | Impact Factor | Review Period | Acceptance Rate | Match Reason | Warning Risk |
|-------|:-------:|:--------:|:-----:|---------|:--------:|
| Nature | 64.8 | 3-6 months | ~8% | High topic match | Safe |

### Robust Journals
| Journal | Impact Factor | Review Period | Acceptance Rate | Match Reason | Warning Risk |
|-------|:-------:|:--------:|:-----:|---------|:--------:|

### Safe Journals
| Journal | Impact Factor | Review Period | Acceptance Rate | Match Reason | Warning Risk |
|-------|:-------:|:--------:|:-----:|---------|:--------:|

### Warning Notes
List any journals on the warning list to avoid submitting to.
```

# Journal Recommender

## Overview
This skill analyzes a research manuscript (topic, abstract, and optional full text) to extract key information (keywords, field, workload, innovation) and recommends journals in three categories: Sprint (High), Robust (Match), and Safe (Low).

## Workflow

1.  **Assess Manuscript**:
    *   Analyze the provided `topic` and `abstract`.
    *   Extract keywords and determine the specific research field.
    *   Evaluate the workload and innovation of the study.
    *   Estimate the manuscript's potential Impact Factor (IF).

2.  **Recommend Journals**:
    *   Based on the assessment and the user's `target_if`, search for and recommend journals.
    *   Categorize recommendations into:
        *   **Sprint Journals**: IF slightly higher than target (max +5).
        *   **Robust Journals**: IF matches the target and assessment.
        *   **Safe Journals**: IF lower than target, ensuring high acceptance chance.
    *   Ensure at least 5 journals per category.
    *   **Constraint**: Do not recommend journals from the CAS warning list.

## Usage

### Inputs
*   `topic` (Required): The title or topic of the manuscript.
*   `abstract` (Required): The abstract of the manuscript.
*   `target_if` (Required): The expected Impact Factor (number).
*   `manuscript` (Optional): Full text of the manuscript.
*   `article_type` (Default: "research article"): Type of the article.

### Deterministic Operations
*   **Sorting**: The recommended journals are sorted by Impact Factor in descending order using `scripts/journal_ranker.py`.

## Quality Rules
*   **IF Sorting**: Journals must be strictly sorted by IF.
*   **Safety**: No CAS warning journals are allowed.
*   **Quantity**: Minimum 5 journals per category.

## When to Use

- Use this skill when the request matches its documented task boundary.
- Use it when the user can provide the required inputs and expects a structured deliverable.
- Prefer this skill for repeatable, checklist-driven execution rather than open-ended brainstorming.

## When Not to Use

- Do not use this skill when the required source data, identifiers, files, or credentials are missing.
- Do not use this skill when the user asks for fabricated results, unsupported claims, or out-of-scope conclusions.
- Do not use this skill when a simpler direct answer is more appropriate than the documented workflow.

## Required Inputs

- A clearly specified task goal aligned with the documented scope.
- All required files, identifiers, parameters, or environment variables before execution.
- Any domain constraints, formatting requirements, and expected output destination if applicable.

## Output Contract

- Return a structured deliverable that is directly usable without reformatting.
- If a file is produced, prefer a deterministic output name such as `journal_recommender_result.md` unless the skill documentation defines a better convention.
- Include a short validation summary describing what was checked, what assumptions were made, and any remaining limitations.

## Validation and Safety Rules

- Validate required inputs before execution and stop early when mandatory fields or files are missing.
- Do not fabricate measurements, references, findings, or conclusions that are not supported by the provided source material.
- Emit a clear warning when credentials, privacy constraints, safety boundaries, or unsupported requests affect the result.
- Keep the output safe, reproducible, and within the documented scope at all times.

## Failure Handling

- If validation fails, explain the exact missing field, file, or parameter and show the minimum fix required.
- If an external dependency or script fails, surface the command path, likely cause, and the next recovery step.
- If partial output is returned, label it clearly and identify which checks could not be completed.

## Quick Validation

Run this minimal verification path before full execution when possible:

```bash
python scripts/journal_ranker.py --help
```

Expected output format:

```text
Result file: journal_recommender_result.md
Validation summary: PASS/FAIL with brief notes
Assumptions: explicit list if any
```

## User Checkpoints

- Before executing batch processing, overwriting files, long-running searches, or multi-stage generation, confirm scope and output format with the user.
- Before proceeding when a key judgment is ambiguous, evidence is insufficient, or the workflow is entering the next stage, confirm with the user.
