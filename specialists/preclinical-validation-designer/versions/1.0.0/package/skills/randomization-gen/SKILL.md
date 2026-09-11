---
name: randomization-gen
description: Generates randomization sequences for RCTs including simple, blocked, and stratified allocation. Produces sealed randomization lists ready for allocation concealment.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Randomization Gen

RCT randomization table generator.

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

- Use this skill when designing trial randomization, generating allocation sequences, or creating block randomization tables.
- Use this skill when the user says "randomization", "random allocation", "block randomization", "stratified randomization", or "RCT design".
- Use this skill when you need sealed randomization lists ready for allocation concealment.

## Workflow

1. **Collect parameters**: Gather n_subjects (total sample size), n_groups (number of arms), block_size (must be multiple of n_groups), and optional stratification factors.
2. **Validate inputs**: Verify n_subjects > 0, n_groups >= 2, block_size is a multiple of n_groups, and n_subjects is divisible by block_size. If invalid, report exact constraint violated and stop.
3. **Checkpoint**: Display allocation plan summary (N per group, block structure, total blocks) to user for confirmation before generating sequence.
4. **Generate sequence**: Create randomization list using blocked randomization. Shuffle block contents using a reproducible seed if provided.
5. **Output**: Return sealed randomization list with block assignments and allocation concealment metadata.
6. **Fallback**: If block_size is not a multiple of n_groups, suggest the nearest valid block sizes and proceed only after user confirmation.

## Use Cases
- Clinical trial design
- Animal study randomization
- Blocked randomization
- Stratified allocation

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `n_subjects` | int | Yes | Total sample size |
| `n_groups` | int | Yes | Number of arms/groups |
| `block_size` | int | Yes | Block size (must be multiple of n_groups) |
| `--output` | string | No | Output file path (default: randomization.txt) |

## Returns
- Randomization sequence
- Block assignments
- Allocation concealment ready

## Example
Input: n=120, 3 groups, block=6
Output: Sealed randomization list

## References

- [references/audit-reference.md](references/audit-reference.md) - Supported randomization modes, audit commands, and fallback boundaries

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

No additional Python packages required.

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

This skill accepts requests that match the documented purpose of `randomization-gen` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `randomization-gen` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

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
