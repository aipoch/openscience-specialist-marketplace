# Stage Detection Rules

## Detection Process

When a manuscript file is provided, automatically detect the stage.

---

## Stage Indicators

### Idea/Outline Stage

**Indicators**:
- No complete draft structure
- Only notes, bullet points, or outline
- Research question not finalized
- No clear argument flow

**Detection Priority**:
1. Check for complete sections
2. Check for paragraph-level prose
3. Check for research question statement

**Confidence Threshold**: 0.8

---

### Early Draft Stage

**Indicators**:
- Complete structure (all major sections present)
- Paragraph-level prose throughout
- Missing or incomplete method section
- Results section has placeholders or incomplete
- Discussion section brief
- Citations incomplete

**Detection Priority**:
1. Check section completeness
2. Check method details
3. Check results content
4. Check citation count

**Confidence Threshold**: 0.7

---

### Mature Draft Stage

**Indicators**:
- All sections complete and detailed
- Citations mostly complete (20+)
- Method section fully described
- Results section has data/analysis
- Discussion section substantive
- Minor issues only (formatting, polish)

**Detection Priority**:
1. Check all sections for completeness
2. Check citation count and format
3. Check for placeholder text
4. Check discussion depth

**Confidence Threshold**: 0.75

---

### Revision Stage

**Indicators**:
- Prior reviewer comments provided
- Response letter or revision notes
- Manuscript revised from previous version
- Track changes or revision markers

**Detection Priority**:
1. Check for reviewer feedback files
2. Check for response letter
3. Check for revision markers

**Confidence Threshold**: 0.9

---

### Rebuttal/Camera-Ready Stage

**Indicators**:
- Accepted with minor revisions
- Camera-ready instructions present
- Final formatting checklist
- Very specific, targeted issues

**Detection Priority**:
1. Check for acceptance notification
2. Check for camera-ready instructions
3. Check issue specificity

**Confidence Threshold**: 0.9

---

## Detection Algorithm

```
FUNCTION detect_stage(manuscript):
  structure = analyze_structure(manuscript)

  IF has_reviewer_feedback(manuscript):
    IF has_acceptance_notice(manuscript):
      RETURN "rebuttal/camera-ready"
    ELSE:
      RETURN "revision"

  IF structure.completeness < 0.5:
    RETURN "idea/outline"

  IF structure.method_complete == False OR
     structure.results_has_placeholders == True:
    RETURN "early_draft"

  IF structure.all_complete AND
     structure.citation_count > 20 AND
     structure.no_placeholders:
    RETURN "mature_draft"

  RETURN "early_draft"  // default conservative
```

---

## Detection Output

```markdown
**Detected Stage**: {stage}

**Detection Evidence**:
- ✅ {evidence_1}
- ⚠️ {evidence_2}
- ❌ {evidence_3}

**Confidence**: {percentage}%
```

---

## User Override

User can always override detected stage:

```
Stage: early draft (auto-detected)
> Override: mature draft
```

Detection should be treated as a suggestion, not a mandate.
