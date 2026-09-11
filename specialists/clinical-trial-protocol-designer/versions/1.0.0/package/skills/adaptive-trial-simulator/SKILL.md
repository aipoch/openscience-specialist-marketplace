---
name: adaptive-trial-simulator
description: Design and simulate adaptive clinical trials with interim analyses, decision rules, and operating-characteristic summaries; use when planning adaptive designs or comparing stopping, enrichment, or sample-size re-estimation strategies.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Adaptive Trial Simulator

Statistical simulation platform for designing and validating adaptive clinical trial designs in silico. Enables optimization of interim analysis strategies, sample size adaptation, and early stopping rules while maintaining Type I error control.

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
python scripts/main.py --design group_sequential --n-simulations 50
python scripts/main.py --design adaptive_reestimate --n-simulations 25 --optimize
```

## When to Use

- Use this skill when the task is to Design and simulate adaptive clinical trials with interim analyses.
- Use this skill for protocol design tasks that require explicit assumptions, bounded scope, and a reproducible output format.
- Use this skill when the response must stay inside the documented task boundary instead of expanding into adjacent work.

## Workflow

1. Confirm the user objective, required inputs, and non-negotiable constraints before doing detailed work.
2. Validate that the request matches the documented scope and stop early if the task would require unsupported assumptions.
3. Use the packaged script path or the documented reasoning path with only the inputs that are actually available.
4. Return a structured result that separates assumptions, deliverables, risks, and unresolved items.
5. If execution fails or inputs are incomplete, switch to the fallback path and state exactly what blocked full completion.

## Features

- **Design Simulation**: Monte Carlo validation of adaptive designs
- **Sample Size Re-estimation**: Adapt sample size based on interim data
- **Early Stopping Rules**: Futility and efficacy boundary optimization
- **Type I Error Control**: Validate alpha spending strategies
- **Multi-Arm Designs**: Drop-the-loser and seamless Phase II/III
- **Power Optimization**: Identify designs with maximum power efficiency

## Usage

### Basic Usage

```text
# Run standard group sequential design
python scripts/main.py

# Adaptive design with sample size re-estimation
python scripts/main.py --design adaptive_reestimate

# Optimize design parameters
python scripts/main.py --optimize
```

### Parameters

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--design` | str | group_sequential | No | Trial design type |
| `--n-simulations` | int | 10000 | No | Number of Monte Carlo simulations |
| `--sample-size` | int | 200 | No | Initial sample size per arm |
| `--effect-size` | float | 0.3 | No | Effect size (Cohen's d) |
| `--alpha` | float | 0.05 | No | Type I error rate |
| `--power` | float | 0.80 | No | Target statistical power |
| `--interim-looks` | int | 1 | No | Number of interim analyses |
| `--spending-function` | str | obrien_fleming | No | Alpha spending function |
| `--reestimate-method` | str | promising_zone | No | Sample size re-estimation method |
| `--output` | str | results.json | No | Output file path |
| `--visualize` | flag | False | No | Generate visualization charts |
| `--optimize` | flag | False | No | Search for optimal design parameters |

### Advanced Usage

```text
# Full adaptive design with visualization
python scripts/main.py \
  --design adaptive_reestimate \
  --n-simulations 50000 \
  --sample-size 250 \
  --effect-size 0.35 \
  --interim-looks 2 \
  --spending-function obrien_fleming \
  --visualize \
  --output adaptive_results.json
```

## Design Types

| Design Type | Description | Use Case |
|-------------|-------------|----------|
| **Group Sequential** | Fixed interim looks with stopping boundaries | Standard adaptive trials |
| **Adaptive Re-estimate** | Sample size adjustment based on interim data | Uncertain effect size |
| **Drop the Loser** | Multi-arm trials dropping inferior arms | Phase II dose selection |

## Spending Functions

| Function | Characteristics | Early Boundary |
|----------|----------------|----------------|
| **O'Brien-Fleming** | Conservative early | High Z-scores early |
| **Pocock** | Aggressive early | Lower Z-scores throughout |
| **Power Family** | Moderate (ρ=3) | Balanced approach |

## Output Example

```json
{
  "design_config": {
    "design_type": "adaptive_reestimate",
    "sample_size_per_arm": 200,
    "effect_size": 0.3,
    "alpha": 0.05,
    "target_power": 0.8
  },
  "simulation_results": {
    "power": 0.8234,
    "type_i_error": 0.0481,
    "expected_sample_size": 385.2,
    "early_stop_rate": {
      "efficacy": 0.1523,
      "futility": 0.0841
    }
  }
}
```

## Technical Difficulty: **HIGH**

## References

- [references/audit-reference.md](references/audit-reference.md) - Audit-ready assumptions, supported design modes, and fallback boundaries for constrained runs

⚠️ **AI independent acceptance status**: manual inspection required
This skill requires:
- Python 3.8+ environment
- NumPy, SciPy, and Matplotlib packages
- Understanding of clinical trial statistics

## Dependencies

```text
pip install -r requirements.txt
```

### Requirements

```
numpy>=1.20.0
scipy>=1.7.0
matplotlib>=3.4.0
```

## Risk Assessment

| Risk Indicator | Assessment | Level |
|----------------|------------|-------|
| Code Execution | Python scripts with mathematical calculations | Medium |
| Network Access | No network access | Low |
| File System Access | Writes simulation results | Low |
| Instruction Tampering | Statistical parameters could affect results | Medium |
| Data Exposure | No sensitive data exposure | Low |

## Security Checklist

- [x] No hardcoded credentials or API keys
- [x] No unauthorized file system access
- [x] Output does not expose sensitive information
- [x] Input parameters validated
- [x] Error messages sanitized
- [x] Dependencies audited

## Prerequisites

```text
pip install -r requirements.txt
python scripts/main.py --help
```

## Evaluation Criteria

### Success Metrics
- [ ] Simulations run without errors
- [ ] Type I error controlled at nominal level
- [ ] Power estimates are accurate
- [ ] Visualizations generated correctly

### Test Cases
1. **Basic Simulation**: Default parameters → Valid results
2. **Different Designs**: All design types → Appropriate behavior
3. **Optimization Mode**: --optimize flag → Finds optimal parameters
4. **Visualization**: --visualize flag → Charts generated

## Lifecycle Status

- **Current Stage**: Draft
- **Next Review Date**: 2026-03-15
- **Known Issues**: Type checking warnings with numpy arrays
- **Planned Improvements**:
  - Bayesian adaptive designs
  - Multi-arm multi-stage (MAMS) support
  - Enhanced visualization options

## References

Available in `references/`:
- Adaptive design statistical theory
- Regulatory guidance documents
- Alpha spending function literature
- Sample size re-estimation methods

## Limitations

- **Statistical Complexity**: Requires biostatistics expertise
- **Simulation Time**: Large simulations may take hours
- **Simplified Models**: Does not capture all real-world complexities
- **Regulatory Consultation**: Results should be validated with regulators

---

**⚠️ DISCLAIMER: This tool provides simulation results for research and planning purposes only. All clinical trial designs should be reviewed by qualified biostatisticians and regulatory experts before implementation.**

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

This skill accepts requests that match the documented purpose of `adaptive-trial-simulator` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `adaptive-trial-simulator` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

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
