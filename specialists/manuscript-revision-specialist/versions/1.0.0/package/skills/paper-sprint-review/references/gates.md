# Quality Gates — Detailed Rules

## Gate System

Quality gates are checkpoints that must be passed before proceeding to the next phase.

## Gate Definitions

### Contribution Gate (Early Phase)

**Purpose:** Verify contribution clarity

| Check | Pass Criteria |
|-------|---------------|
| Problem importance | Clear problem statement with explanation of significance |
| Contribution statement | Explicit "contributes X by Y" statement |
| Gap identification | Gap in the literature clearly stated |
| Differentiation | Positioning relative to prior work explained |

### Rigor Gate (Middle Phase)

**Purpose:** Verify theoretical and methodological soundness

| Check | Pass Criteria |
|-------|---------------|
| Theoretical framework | Appropriate theory, well-grounded |
| Construct definitions | All constructs defined |
| Method appropriateness | Method fits the research question |
| Evidence sufficiency | Evidence supports all claims |
| Limitations | Boundary conditions stated |

### Writing Gate (Late Phase)

**Purpose:** Verify writing quality and format compliance

| Check | Pass Criteria |
|-------|---------------|
| Logical flow | Clear progression, good transitions |
| Language clarity | Readable, no major issues |
| Abstract completeness | All required elements present |
| Format compliance | Meets venue requirements |

### Submission Gate (Final)

**Purpose:** Verify submission readiness

| Check | Pass Criteria |
|-------|---------------|
| Citation verification | All citations verified by the author |
| Claim verification | All claims verified by the author |
| Format check | Template compliance verified |
| Author approval | Author confirms readiness |

**This gate cannot be passed by PaperSprint. Human verification is required.**

## Gate Assessment Output

```markdown
## Gate Check: Contribution Gate

| Check | Status | Evidence |
|-------|--------|----------|
| Problem importance | ✅ | Section 1, paragraph 2 |
| Contribution statement | ✅ | Abstract, Section 1.2 |
| Gap identification | ❌ | Missing explicit gap statement |
| Differentiation | ⚠️ | Partial — needs [Author Year] comparison |

**Result**: ❌ FAIL

**Required Actions**:
- Add gap statement in literature review
- Expand differentiation discussion

**Blocking**: Yes — cannot proceed to Rigor Gate until resolved
```

## Prerequisite Guards

Before executing any gate check, verify the following prerequisites:

| Command | Prerequisite | Response if not met |
|---------|-------------|---------------------|
| `/ps gate check contribution` | Manuscript provided | "Gate check requires a manuscript. Please provide your manuscript or run `/ps intake` first." |
| `/ps gate check rigor` | Contribution Gate passed + at least one `/ps review` completed | "Rigor Gate check requires Contribution Gate to pass first. Run `/ps gate check contribution` to begin." |
| `/ps gate check writing` | Rigor Gate passed | "Writing Gate check requires Rigor Gate to pass first." |
| `/ps gate check submission` | Writing Gate passed | This gate is human-only. PaperSprint does not execute it. |

**Gate sequence rule:** Gate checks must follow the sequence: Contribution → Rigor → Writing → Submission. Skipping a gate is only permitted with an explicit user override (`--force`) and must be declared in the output: "⚠️ Gate sequence override: Rigor Gate skipped by user request."

## Gate Commands

```
/ps gate check contribution
/ps gate check rigor
/ps gate check writing
/ps gate status
```

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
