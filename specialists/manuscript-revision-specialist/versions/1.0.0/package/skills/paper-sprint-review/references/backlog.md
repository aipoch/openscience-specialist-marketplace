# Backlog — Detailed Rules

## Backlog Item Structure

Every backlog item must include all fields:

```yaml
id: B{n}
title: Short descriptive title
rationale: Why this matters (linked to a review finding)
severity: critical | high | medium | low
affected_sections:
  - Section X.Y
  - Section Z.W
proposed_action: Concrete next step
dependencies:
  - B{n-1}  # ID of item that must be completed first
done_criterion: How to verify completion
bucket: contribution | theory | method | evidence | writing | compliance
status: open | in_progress | blocked | closed
effort: small | medium | large
```

## Bucket Definitions

| Bucket | Contains |
|--------|----------|
| **contribution** | Contribution clarity, positioning, novelty |
| **theory** | Theoretical framework, literature, constructs |
| **method** | Research design, data collection, analysis |
| **evidence** | Results, findings, validation |
| **writing** | Clarity, structure, flow, language |
| **compliance** | Formatting, venue requirements, citations |

## Priority Rules

**Priority order:**
1. Items with severity = critical
2. Items blocking other items (dependency relationships)
3. Items in the current sprint focus bucket
4. Items with effort = small (quick wins)

## Backlog Commands

```
/ps backlog           # Show all items, grouped by bucket
/ps backlog critical  # Show critical items only
/ps backlog next      # Show highest-priority item
/ps backlog close B1  # Mark item as closed
/ps backlog add "..." # Interactively add a new item
```

## Backlog Output Example

```markdown
Backlog Summary (12 items)

CRITICAL (2):
- B001: Add contribution statement [OPEN]
- B002: Differentiate dignity construct [IN_PROGRESS]

HIGH (4):
- B003: Create construct table [OPEN]
- B004: Map against recent literature [BLOCKED by B001]
...

Next recommended: B002
```
