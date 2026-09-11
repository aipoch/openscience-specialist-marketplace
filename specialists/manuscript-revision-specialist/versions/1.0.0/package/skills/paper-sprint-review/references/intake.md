# Intake — Detailed Rules

## Progressive Questioning

**Do not** ask all questions at once. Based on what the user has already provided, ask only for the missing critical information.

## Minimum Required Information

1. Target journal or conference (or "unknown")
2. Manuscript stage (auto-detect if not specified)
3. Sprint goal for this session
4. Available materials

## Automatic Stage Detection

If the user provides a manuscript file, auto-detect the stage:

| Indicator | Criteria | Stage |
|-----------|----------|-------|
| No complete structure | Only notes, outlines, or bullet points | idea/outline |
| Structure complete but content incomplete | Method or results sections have placeholders | early_draft |
| All sections complete | 20+ citations, no placeholders | mature_draft |
| Reviewer comments present | Review comments have been provided | revision |
| Accepted, awaiting final version | Acceptance notification present | rebuttal/camera-ready |

## Intake Output Template

```markdown
## Intake Summary

**Project ID**: PS-{timestamp}
**Venue**: {venue} | {track}
**Stage**: {stage} (auto-detected | user-specified)
**Sprint Goal**: {goal}

**Materials Available**:
- [x] Main manuscript: {path}
- [ ] Prior reviews
- [ ] Venue guidelines

**Initial Assessment**:
- Estimated sprints: {range}
- Priority focus: {focus}
- Key risks: {risks}

**Next Step**: Run sprint planning
```

## Detailed Stage Detection Rules

See: `detection/stage_detector.md`
