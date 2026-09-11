---
name: sample-size-basic
description: Basic sample size estimator for clinical research planning. Computes per-group and total N for two-sample/paired t-tests, chi-square tests, and proportion comparisons, reporting alpha, power, effect size, and statistical assumptions summary for grant proposals and preliminary ...
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Sample Size (Basic)

Basic sample size estimation for clinical research planning.

## Quick Check

Use this command to verify that the packaged script entry point can be parsed before deeper execution.

```bash
python -m py_compile scripts/main.py
```

## Audit-Ready Commands

Use these concrete commands for validation. They are intentionally self-contained and avoid placeholder paths.

```bash
python -m py_compile scripts/main.py
python scripts/main.py --help
```

## When to Use

- Use this skill when estimating sample size for grant proposals or preliminary study design.
- Use this skill when the user says "sample size", "power analysis", "how many subjects", or "n per group".
- Use this skill for basic t-test, chi-square, and proportion test sample size calculations.

## Workflow

1. **Identify test type**: Determine statistical test from user request — t_test (two-sample or paired), chi_square, or proportion comparison.
2. **Collect parameters**: Gather alpha (default 0.05), power (default 0.80), effect_size (Cohen's d for t-test, or difference in proportions), and baseline_rate (for proportion tests).
3. **Validate inputs**: Verify alpha in (0,1), power in (0,1), effect_size > 0, and baseline_rate in [0,1] when applicable. If invalid, report exact error and stop.
4. **Checkpoint**: Display input summary with assumed test type and parameters to user for confirmation before computing.
5. **Compute sample size**: Calculate per-group N and total N using the appropriate formula for the test type.
6. **Output**: Return required sample size per group, total sample size, and statistical assumptions summary (test type, alpha, power, effect size, assumptions made).
7. **Fallback**: If test type is ambiguous, present options (t-test for means, chi-square for proportions) and ask user to clarify.

## Use Cases
- Quick sample size estimates for grant proposals
- Preliminary study design calculations
- Educational purposes for statistics training

## Parameters
- `test_type`: Type of test (t_test, chi_square, proportion)
- `alpha`: Significance level (default 0.05)
- `power`: Statistical power (default 0.80)
- `effect_size`: Expected effect size
- `baseline_rate`: Baseline proportion (for proportion tests)

## Returns
- Required sample size per group
- Total sample size
- Statistical assumptions summary

## Example
Input: Two-sample t-test, alpha=0.05, power=0.80, effect_size=0.5
Output: n=64 per group, total=128 subjects

## References

- [references/audit-reference.md](references/audit-reference.md) - Supported calculation scope, audit commands, and fallback boundaries

## Risk Assessment

| Risk Indicator | Assessment | Level |
|----------------|------------|-------|
| Code Execution | Python/R scripts executed locally | Medium |
| Network Access | No external API calls | Low |
| File System Access | Read input files, write output files | Medium |
| Instruction Tampering | Standard prompt guidelines | Low |
| Data Exposure | Output files saved to workspace | Low |

## Security Checklist

- [ ] No hardcoded credentials or API keys
- [ ] No unauthorized file system access (../)
- [ ] Output does not expose sensitive information
- [ ] Prompt injection protections in place
- [ ] Input file paths validated (no ../ traversal)
- [ ] Output directory restricted to workspace
- [ ] Script execution in sandboxed environment
- [ ] Error messages sanitized (no stack traces exposed)
- [ ] Dependencies audited

## Prerequisites

```text
# Python dependencies
pip install -r requirements.txt
```

## Evaluation Criteria

### Success Metrics
- [ ] Successfully executes main functionality
- [ ] Output meets quality standards
- [ ] Handles edge cases gracefully
- [ ] Performance is acceptable

### Test Cases
1. **Basic Functionality**: Standard input → Expected output
2. **Edge Case**: Invalid input → Graceful error handling
3. **Performance**: Large dataset → Acceptable processing time

## Lifecycle Status

- **Current Stage**: Draft
- **Next Review Date**: 2026-03-06
- **Known Issues**: None
- **Planned Improvements**:
  - Performance optimization
  - Additional feature support

## Output Requirements

Every final response should make these items explicit when they are relevant:

- Objective or requested deliverable
- Inputs used and assumptions introduced
- Workflow or decision path
- Core result, recommendation, or artifact
- Constraints, risks, caveats, or validation needs
- Unresolved items and next-step checks

## Error Handling

- If required inputs are missing, state exactly which fields are missing and request only the minimum additional information.
- If the task goes outside the documented scope, stop instead of guessing or silently widening the assignment.
- If `scripts/main.py` fails, report the failure point, summarize what still can be completed safely, and provide a manual fallback.
- Do not fabricate files, citations, data, search results, or execution outcomes.

## Input Validation

This skill accepts requests that match the documented purpose of `sample-size-basic` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `sample-size-basic` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## Response Template

Use the following fixed structure for non-trivial requests:

1. Objective
2. Inputs Received
3. Assumptions
4. Workflow
5. Deliverable
6. Risks and Limits
7. Next Checks

If the request is simple, you may compress the structure, but still keep assumptions and limits explicit when they affect correctness.
