---
name: response-letter
description: Helps organize reviewer comments and generate a standardized Word (.docx) response letter that maps each change to its exact location (page/paragraph/line). Use when revising a manuscript, replying to peer-review feedback, or preparing internal review responses.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)


## When to Use

- You received peer-review comments and need a point-by-point response letter for journal resubmission.
- You must clearly map every manuscript change to a specific location (page/paragraph/line) for reviewers or editors.
- You need a consistent, professional response structure across multiple reviewers and revision rounds.
- You are coordinating an internal review and want a standardized change log and execution checklist.
- You need a Word (.docx) deliverable rather than a table-based response format.

## Key Features

- Consolidates, merges, and numbers reviewer comments across reviewers.
- Separates major vs. minor comments to prioritize revision work.
- Produces a fixed, repeatable response layout per comment:
  - **Reviewer’s Comment**
  - **Response**
  - **Changes in Text**
- Requires explicit change-location marking (page/paragraph/line) and version labeling.
- Supports quoting revised manuscript text (e.g., blockquotes) to make changes auditable.
- Generates a Word (.docx) response letter plus a modification/execution checklist.
- Adds an **Overview for the Editor** section summarizing major revisions at the beginning.
- Enforces a professional, polite tone throughout.

## Dependencies

- Microsoft Word `.docx` output (Word-compatible document generation)
- Reference format guide: `references/guide.md`
- Response template: `assets/review_response_template.docx`

## Example Usage

```text
Input:
- Manuscript (tracked version or clean version + change notes)
- Reviewer comments (all reviewers, all rounds)
- Current manuscript pagination/line numbering scheme (if available)

Steps:
1) Organize comments
   - Merge all reviewer comments into a single list.
   - Number them sequentially (e.g., R1-1, R1-2…; R2-1…).
   - Tag each as Major or Minor.

2) Draft "Overview for the Editor"
   - Write one concise paragraph summarizing the major revisions and their rationale.

3) Write point-by-point responses
   For each numbered comment, output:
   - Reviewer’s Comment: (verbatim or lightly cleaned for clarity)
   - Response: (polite, direct, addresses the request)
   - Changes in Text: (what changed + where)

4) Mark locations and quote revised text
   - Provide page/paragraph/line for each change.
   - Specify additions/deletions.
   - Quote the revised paragraph when the main text is modified.

5) Generate deliverables
   - Export the full response letter as a Word document (.docx).
   - Produce a modification/execution checklist to verify all changes are applied.

Output (Word .docx structure):
- Title / Manuscript info (optional)
- Overview for the Editor
- Responses to Reviewer 1
  - R1-1
  - R1-2
  ...
- Responses to Reviewer 2
  ...
- Modification / Execution Checklist
```

## Implementation Details

- **Comment normalization and numbering**
  - Merge comments from all sources; assign stable IDs (e.g., `R{reviewer}-{index}`) to preserve traceability across revision rounds.
- **Major vs. minor classification**
  - Major: requests affecting study design, analyses, interpretation, or core claims.
  - Minor: wording, formatting, clarifications, citations, typos.
- **Per-comment fixed layout**
  - Each response must include three labeled blocks: *Reviewer’s Comment*, *Response*, *Changes in Text*.
- **Location marking**
  - Use page/paragraph/line when available; otherwise use section/subsection headings plus paragraph index.
  - Always indicate whether text was **added**, **deleted**, or **rewritten**.
- **Revised-text excerpting**
  - When the manuscript body changes, include the updated paragraph as an indented blockquote under *Changes in Text* for auditability.
- **Output constraints**
  - Final deliverable is a Word document (`.docx`).
  - Do not use table format for the response letter.
- **Formatting and checklists**
  - Follow `references/guide.md` for required output formats, checklist items, and key writing points.

## When Not to Use

- Do not proceed when required input files, identifiers, parameters, or context are missing — ask the user to provide them first.
- Do not assume capabilities beyond this skill's declared scope when the user requests external operations or inferences.
- Do not proceed without user confirmation when overwriting existing results, executing high-cost batch operations, or expanding task scope.

## Required Inputs

| Field | Required | Format/Source | Example | If Missing |
|---|---|---|---|---|
| User task description | Yes | Text | Research question, writing goal, analysis objective | Stop and ask user to provide |
| Primary input material | Depends on task | Text, file path, ID, table, or literature | PMID, PDF, CSV, DOCX, keywords, etc. | Specify which material type is missing |
| Output preference | No | Text | Language, format, target journal, template | Use skill default format |

## Output Contract

- Primary output: Structured result or target file aligned with this skill's objective.
- Optional output: Intermediate check notes, issue list, supplementary suggestions, or generated file paths.
- Format requirement: Unless the user specifies otherwise, prefer stable, reviewable Markdown or JSON; if the skill's bundled script requires a fixed format, use that format.
- If partially complete: Must explicitly mark as PARTIAL and state which steps are completed and which remain.

## Failure Handling

- Missing critical input: Explicitly state which fields, files, or identifiers are missing and pause.
- Script, template, or resource execution failure: Report the failing step, likely cause, and recovery suggestions — do not silently degrade.
- Partial completion only: Return the verified portion first, then list remaining blockers and suggested next steps.

## User Checkpoints

### Checkpoint 1: Before Drafting Overview
- After reading all reviewer comments, summarize the major revision themes and present them to the user.
- Ask: "Here are the main revision areas I identified. Do you want me to include all in the Editor Overview, or focus on specific points?"
- Wait for user confirmation before writing the Overview for the Editor.

### Checkpoint 2: Before Generating DOCX
- After drafting all point-by-point responses, summarize the total number of responses, major vs minor split, and any potentially sensitive replies (e.g., politely disagreeing with a reviewer).
- Ask: "I have drafted N responses (X major, Y minor). Do you want me to proceed to generate the final DOCX, or would you like to review/edit any responses first?"
- Wait for user confirmation before generating the deliverable.

### Checkpoint 3: Edge Case — Reviewer Comment is Incorrect or Based on a Misreading
- If a reviewer's comment appears to misunderstand the manuscript, do NOT skip it.
- Draft a polite response that:
  1. Thanks the reviewer for the comment
  2. Points to the relevant section (page/paragraph/line) where the information already exists
  3. Quotes the relevant passage as a blockquote
- Present this draft to the user for review before including in the final letter, as tone is critical here.

### Checkpoint 4: Multiple Review Rounds
- If the user provides comments from multiple revision rounds (R1, R2, etc.), ask how they want to organize: separate sections per round, or a combined response.


## Input Validation

This skill accepts requests that match the documented purpose of `response-letter` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `response-letter` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## Quick Validation

- Check that key scripts, templates, or reference file paths this skill depends on exist.
- Check that the final output contains the core fields, sections, or files specified for this task.
- Check that results clearly mark assumptions, limitations, and incomplete items.
