# Quality Checker Rules

## Quality Gate System

Quality gates are checkpoints that must be passed before proceeding to the next phase.

---

## Gate Definitions

### Contribution Gate

**Phase**: Early
**Purpose**: Verify contribution clarity

**Checks**:
| Check | Pass Criteria |
|-------|---------------|
| Problem importance | Clear problem statement, significance explained |
| Contribution statement | Explicit "contributes X by Y" statement |
| Gap identification | Gap in literature clearly stated |
| Differentiation | Positioning vs. prior work explained |

**Gate Result**:
- ✅ PASS: All checks met
- ❌ FAIL: Any critical check failed
- ⏳ PENDING: Not yet evaluated

---

### Rigor Gate

**Phase**: Middle
**Purpose**: Verify theoretical and methodological soundness

**Checks**:
| Check | Pass Criteria |
|-------|---------------|
| Theory framework | Appropriate theory, well-grounded |
| Construct definitions | All constructs defined |
| Method appropriateness | Method fits research question |
| Evidence sufficiency | Evidence supports claims |
| Limitations | Boundary conditions stated |

**Gate Result**:
- ✅ PASS: All checks met
- ❌ FAIL: Any critical check failed
- ⏳ PENDING: Not yet evaluated

---

### Writing Gate

**Phase**: Late
**Purpose**: Verify writing quality and format compliance

**Checks**:
| Check | Pass Criteria |
|-------|---------------|
| Logical flow | Clear progression, good transitions |
| Language clarity | Readable, no major issues |
| Abstract complete | All required elements present |
| Format compliance | Meets venue requirements |

**Gate Result**:
- ✅ PASS: All checks met
- ❌ FAIL: Any critical check failed
- ⏳ PENDING: Not yet evaluated

---

### Submission Gate

**Phase**: Final
**Purpose**: Verify submission readiness

**Checks**:
| Check | Pass Criteria |
|-------|---------------|
| Citation verification | All citations verified by author |
| Claim verification | All claims verified by author |
| Format check | Template compliance verified |
| Author approval | Author confirmed readiness |

**Gate Result**:
- ⏳ PENDING: Always pending until human finalization
- ❌ CANNOT PASS: Requires human verification

**This gate CANNOT be passed by PaperSprint. It requires human action.**

---

## Gate Evaluation Process

### When to Evaluate

- End of each sprint
- When changing focus areas
- Before major decisions

### Evaluation Output

```markdown
## Gate Check: Contribution Gate

| Check | Status | Evidence |
|-------|--------|----------|
| Problem importance | ✅ | Section 1, paragraph 2 |
| Contribution statement | ✅ | Abstract, Section 1.2 |
| Gap identification | ❌ | Missing explicit gap statement |
| Differentiation | ⚠️ | Partial, needs [Author Year] comparison |

**Result**: ❌ FAIL

**Required Actions**:
- Add gap statement in literature review
- Expand differentiation discussion

**Blocking**: Yes - cannot proceed to Rigor Gate until resolved
```

---

## Gate Failure Handling

### Critical Failures

If a gate fails critically:
1. STOP current focus
2. Generate required actions
3. Update backlog with gate items
4. Recommend focus shift

### Non-Critical Failures

If checks are partial:
1. Note as "needs improvement"
2. Continue with caution
3. Schedule for later sprint

---

## Gate Sequence

```
Contribution Gate (Early Phase)
        ↓
    [PASS?]
        ↓
   Rigor Gate (Middle Phase)
        ↓
    [PASS?]
        ↓
   Writing Gate (Late Phase)
        ↓
    [PASS?]
        ↓
Submission Gate (Final)
        ↓
  [HUMAN VERIFICATION]
        ↓
    [SUBMIT]
```

**Note**: Gates can be revisited. If a later gate reveals earlier issues,
return to fix.

---

## Gate Commands

```
/ps gate check contribution
/ps gate check rigor
/ps gate check writing
/ps gate status
```
