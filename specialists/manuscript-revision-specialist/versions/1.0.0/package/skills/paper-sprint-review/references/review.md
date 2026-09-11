# Review — Detailed Rules

## Reading Strategy

**Do not read the full manuscript in one pass.** Follow this priority order:

1. Title, abstract, introduction
2. Contribution statement, research design
3. Core findings, discussion, conclusion
4. Supporting sections (only when needed)

## Review Dimensions

| Dimension | Key Questions | Weight |
|-----------|---------------|--------|
| Problem importance | Is it important? Is it meaningful? | High |
| Contribution | Novel? Significant? Addresses a gap? | High |
| Theoretical grounding | Framework appropriate? Well-grounded? | High |
| Methodological rigor | Appropriate? Rigorous? Valid? | High |
| Evidence quality | Well-supported? Convincing? | High |
| Boundary conditions | Limitations clear? Scope defined? | Medium |
| Clarity and structure | Readable? Logical flow? | Medium |
| Venue fit | Matches scope? On topic? | Medium |

## Reviewer Lenses

### Default configuration: 3 reviewers + 1 editor

| Lens | Focus | Key Question |
|------|-------|--------------|
| **Contribution** | Novelty, significance | Is the contribution clear and important? |
| **Rigor** | Theory, method | Is the method rigorous and appropriate? |
| **Writing** | Clarity, structure | Is the paper well organized? |
| **Editor** | Overall fit | Is this worth publishing in this venue? |

### Venue-specific lens configurations

```
ECIS / ICIS:
- Contribution + Human/Societal Significance + Rigor + Editor

MISQ / ISR:
- Theoretical Contribution + Empirical Rigor + Practical Relevance + Editor

Generic Conference:
- Contribution + Method + Writing + Editor
```

## Review Output Template

```markdown
## Review Memo - Sprint {N}

**Reviewer Lens**: {lens name}

### Findings by Dimension

**Problem Importance**: {assessment}
- {specific observation}
- {specific observation}

**Contribution**: {assessment}
- {specific observation}

### Synthesis

**Strengths**:
- {strength 1}
- {strength 2}

**Critical Issues** (must fix):
- {issue 1} → {location}
- {issue 2} → {location}

**Suggestions** (should fix):
- {suggestion 1}

### Decision

**Gate**: {reject | major revision | minor revision | ready for human finalization}

**Confidence**: {high | medium | low}
```

## Actionable Critique Rules

Every major criticism must:
1. Point to a specific section, paragraph, or line number
2. Explain why it is a problem
3. Propose a specific fix
4. State the severity level

**Poor critique:** "The theory section is weak."

**Good critique:** "Section 3.1 (Theory) lacks a clear construct definition. The core construct 'dignity' is used throughout but never operationalized. Recommended fix: add a construct definition table, referencing [Author Year]. Severity: blocks contribution clarity."
