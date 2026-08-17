# Workflow Step Template
# medical-research-gap-finder

---

## Evidence Audit Template

Whenever the skill outputs a retrieval-and-gap workflow, use the following structure.

```
Step Name:
Purpose:
Input:
Method:
Decision Rules:
Expected Output:
Failure Points:
Alternative Approaches:
```

---

## Recommended Internal Workflow Sequence

1. **Scope Narrowing and Assumption Locking**
2. **Literature Retrieval Across Required Sources**
3. **Metadata Verification and Citation Filtering**
4. **Evidence Landscape Audit**
5. **Candidate Gap Generation**
6. **Pseudo-Gap Rejection**
7. **Confidence Assignment and Prioritization**
8. **Gap-to-Study Conversion**
9. **Risk Review and Final Recommendation**

---

## Step Ordering Rules

- Retrieval must happen before any gap statement.
- Verification must happen before formal citation output.
- Pseudo-gap rejection must happen before prioritization.
- Low-confidence gaps must not be promoted into final recommendation sections.
- Final recommendation must be traceable back to the evidence audit.
