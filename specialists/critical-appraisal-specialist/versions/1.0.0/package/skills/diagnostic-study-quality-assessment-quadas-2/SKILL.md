---
name: diagnostic-study-quality-assessment-quadas-2
description: Analyzes clinical diagnostic accuracy studies for bias using the QUADAS-2 tool. Use when Claude needs to assess the quality, risk of bias, or applicability of diagnostic accuracy studies (e.g., "Assess this paper using QUADAS-2").
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)


# Clinical Study Bias Assessment (QUADAS-2)

This skill evaluates clinical diagnostic accuracy studies for bias and applicability concerns using the Quality Assessment of Diagnostic Accuracy Studies-2 (QUADAS-2) tool.

## Workflow

To assess a study, follow these steps:

1.  **Analyze Patient Selection**:
    *   Assess if the sample was consecutive or random.
    *   Check for case-control design (should be avoided).
    *   Check for inappropriate exclusions.
    *   See `references/quadas_2_criteria.md` for detailed signaling questions.

2.  **Analyze Index Test**:
    *   Assess if the index test results were interpreted without knowledge of the reference standard.
    *   Check if the threshold was pre-specified.

3.  **Analyze Reference Standard**:
    *   Assess if the reference standard correctly classifies the target condition.
    *   Check if reference standard results were interpreted without knowledge of the index test.

4.  **Analyze Flow and Timing**:
    *   Assess the interval between index test and reference standard.
    *   Check if all patients received the reference standard (and the same one).
    *   Check if all patients were included in the analysis.

## Output Format

For each domain (Patient Selection, Index Test, Reference Standard, Flow and Timing), you MUST output the findings in the following structure:

```markdown
### [Domain Name]

**[Signaling Question 1]?**
- Comments: [Explanation in Chinese]
- Quote: [Original text quote]
- Answer: [Yes/No/Unclear]

... (Repeat for all signaling questions)
```

## Quality Rules

1.  **Language**: Explanations (Comments) must be in Chinese.
2.  **Evidence**: Every judgment must be supported by a direct quote from the paper.
3.  **Strictness**: If information is missing, select "Unclear". Do not guess.

## PDF Parsing Tool

For processing PDF literature, you can use the provided Python script:

```bash
# Install dependencies
pip install PyPDF2

# Extract full text
python scripts/pdf_extractor.py "paper.pdf"

# Extract specific page range
python scripts/pdf_extractor.py "paper.pdf" 5 15
```

The script will automatically extract the text, which you can then copy and send to me for QUADAS-2 assessment.


## Input Validation

This skill accepts requests that match the documented purpose of `diagnostic-study-quality-assessment-quadas-2` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `diagnostic-study-quality-assessment-quadas-2` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## References

-   [QUADAS-2 Criteria](references/quadas_2_criteria.md): Detailed signaling questions and judgment guidelines.

## When to Use

- Use this skill when the user explicitly needs to perform the core task of diagnostic-study-quality-assessment-quadas-2 and has provided the minimum executable input.
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

## Quick Validation

- Check that key scripts, templates, or reference file paths this skill depends on exist.
- Check that the final output contains the core fields, sections, or files specified for this task.
- Check that results clearly mark assumptions, limitations, and incomplete items.
