---
name: rct-bias-assessment-rob2
description: Automates Risk of Bias 2 (ROB2) assessment for RCT papers by analyzing text against specific domains and synthesizing a report. Use when you need to assess the quality of a clinical trial paper or evaluate risk of bias.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)


# RCT Bias Assessment (ROB2)

This skill assesses the risk of bias in Randomized Controlled Trials (RCTs) using the ROB2 tool. It analyzes the text for specific domains (Randomization, Deviations, Missing Data, Measurement, Reported Result) and synthesizes an overall judgement.

## Usage

1.  **Input**: Provide the full text or relevant sections of the RCT paper.
2.  **Process**:
    *   The skill extracts the Study Reference (Author, Year).
    *   It assesses each of the 5 ROB2 domains in parallel (conceptually) or sequentially.
    *   It synthesizes an overall risk judgement.
    *   It outputs a JSON-structured summary and a detailed report.

## Domain Assessment Guidelines

Refer to [rob2_guidelines.md](references/rob2_guidelines.md) for the detailed questions and logic for each domain.

### Workflow Steps

1.  **Extract Study Info**: Identify the first author and year (e.g., "Wang, 2018").
2.  **Assess Domains**:
    *   **Domain 1 (Randomization)**: Check allocation sequence and concealment.
    *   **Domain 2 (Deviations)**: Check blinding and protocol deviations.
    *   **Domain 3 (Missing Data)**: Check attrition and ITT analysis.
    *   **Domain 4 (Measurement)**: Check outcome measurement appropriateness.
    *   **Domain 5 (Reported Result)**: Check for selective reporting.
3.  **Synthesize**: Determine the Overall Risk of Bias based on the domain results.
    *   **High**: Any domain is High.
    *   **Some concerns**: No High, but at least one Some concerns.
    *   **Low**: All domains are Low.

## Output Format

The final output should be a JSON object compatible with the following schema:

```json
{
  "Study": "Author, Year",
  "D1": "Low/Some concerns/High",
  "D2": "Low/Some concerns/High",
  "D3": "Low/Some concerns/High",
  "D4": "Low/Some concerns/High",
  "D5": "Low/Some concerns/High",
  "Overall": "Low/Some concerns/High"
}
```

## Helper Scripts

### PDF Text Extraction

When the user provides a PDF file path, use `extract_pdf.py` to extract the text content before assessment:

```bash
python extract_pdf.py
```

This script will:
- Extract text from the PDF file (e.g., `gefitinib nejmoa0810699.pdf`)
- Save the extracted text to `full_text.txt`
- Handle multi-page documents with proper page separators

**Usage flow:**
1. User provides PDF file path
2. Run `python extract_pdf.py` to extract text
3. Read the generated `full_text.txt` file
4. Perform ROB2 assessment on the extracted text

### Text Cleaning

Use `scripts/assess_rob2.py` to clean the text output if needed (removing markdown code blocks) or to validate the JSON structure.

```python
from scripts.assess_rob2 import clean_text
# usage
cleaned_json = clean_text(llm_output)
```

## When to Use

- Use this skill when the user explicitly needs to perform the core task of rct-bias-assessment-rob2 and has provided the minimum executable input.
- Use this skill when you need a structured deliverable rather than general advice.
- Use this skill when the current task can be completed using this skill's bundled scripts, templates, or reference materials.

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

- Before executing batch processing, overwriting files, long-running searches, or multi-stage generation, confirm scope and output format with the user.
- Before proceeding when a key judgment is ambiguous, evidence is insufficient, or the workflow is entering the next stage, confirm with the user.


## Input Validation

This skill accepts requests that match the documented purpose of `rct-bias-assessment-rob2` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `rct-bias-assessment-rob2` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## Quick Validation

- Check that key scripts, templates, or reference file paths this skill depends on exist.
- Check that the final output contains the core fields, sections, or files specified for this task.
- Check that results clearly mark assumptions, limitations, and incomplete items.
