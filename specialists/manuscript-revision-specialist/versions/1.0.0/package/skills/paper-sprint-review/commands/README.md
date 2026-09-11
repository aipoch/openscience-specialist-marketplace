# Command: /ps intake

Run intake to clarify venue, stage, goal, and available materials.

## Usage

```
/ps intake
```

## What It Does

1. **Detects manuscript stage** (if file provided)
2. **Asks progressive questions** for missing information
3. **Generates intake summary** with:
   - Project ID
   - Venue context
   - Stage assessment
   - Sprint estimate
   - Initial risks

## Parameters

Can be provided inline or asked interactively:

| Parameter | Description | Required |
|-----------|-------------|----------|
| `venue` | Target conference/journal | No (default: unknown) |
| `stage` | Manuscript stage | No (auto-detect) |
| `goal` | Sprint goal | No (ask if missing) |
| `file` | Manuscript file path | Recommended |

## Examples

```
/ps intake
> What is your target venue? ICIS 2026
> File path? ./my_paper.md
> [Auto-detecting stage...]
> Stage: early draft (85% confidence)
> Goal for this sprint? contribution clarity

/ps intake --venue "ECIS 2026" --file ./draft.md
```

## Output

- Intake Summary artifact
- Sprint estimate
- Initial risk assessment
- Recommended next step

---

# Command: /ps review

Run a review increment with specified reviewer lenses.

## Usage

```
/ps review
/ps review --lens contribution
/ps review --quick
```

## Options

| Option | Description |
|--------|-------------|
| `--lens` | Use specific lens (contribution, rigor, writing, venue) |
| `--quick` | Quick review (fewer dimensions) |
| `--full` | Full review (all dimensions) |

## What It Does

1. Reads manuscript sections in priority order
2. Evaluates across dimensions
3. Generates actionable critique
4. Creates/updates backlog
5. Produces decision gate

## Output

- Review Memo artifact
- Updated Backlog
- Decision gate
- Recommended next step

---

# Command: /ps amend

Run an amendment increment to address backlog items.

## Usage

```
/ps amend
/ps amend --items B001 B002
/ps amend --critical
```

## Options

| Option | Description |
|--------|-------------|
| `--items` | Specific backlog items to address |
| `--critical` | Address only critical items |
| `--high` | Address critical and high priority items |

## What It Does

1. Selects highest-priority backlog items
2. Makes changes to manuscript (or generates patch text)
3. Tracks what was changed
4. Updates backlog status

## Output

- Amendment Summary artifact
- Updated manuscript (if editable)
- Updated Backlog

---

# Command: /ps status

Show current project status and progress.

## Usage

```
/ps status
```

## What It Shows

- Current sprint number
- Sprint estimate (remaining)
- Phase (early/middle/late/rnr)
- Focus areas
- Backlog summary
- Gate check status
- Open risks

## Example Output

```
Project: PS-GENAI-20260313
Current Sprint: 2
Estimated Remaining: 6-10 sprints
Phase: Middle

Focus: Theory grounding
Backlog: 3 critical, 5 high, 4 medium

Gate Status:
- Contribution: ✅ Passed
- Rigor: ⏳ In Progress
- Writing: ⏳ Pending
- Submission: ⏳ Pending

Next Step: Address B003 (construct table)
```

---

# Command: /ps backlog

View and manage revision backlog.

## Usage

```
/ps backlog
/ps backlog critical
/ps backlog next
/ps backlog close B001
/ps backlog add
```

## Subcommands

| Command | Description |
|---------|-------------|
| `backlog` | Show all items grouped by bucket |
| `backlog critical` | Show only critical items |
| `backlog next` | Show highest priority item |
| `backlog close B001` | Mark item as closed |
| `backlog add` | Add new item interactively |

## Example Output

```
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

---

# Command: /ps next

Execute the next highest-priority backlog item.

## Usage

```
/ps next
```

## What It Does

1. Identifies highest-priority open item
2. Checks dependencies
3. Executes review or amendment as needed
4. Updates backlog status

---

# Command: /ps export

Export all artifacts to files in specified format.

## Usage

```
/ps export                        # Export to Markdown (default)
/ps export --format md            # Export to Markdown
/ps export --format docx          # Export to Microsoft Word
/ps export --format latex         # Export to LaTeX
/ps export --format pdf           # Export to PDF
/ps export --format html          # Export to HTML
/ps export --all                  # Export to all formats
/ps export --output ./mydir/      # Custom output directory
```

## Options

| Option | Description |
|--------|-------------|
| `--format` | Output format: md, docx, latex, pdf, html (default: md) |
| `--output` | Output directory (default: ./papersprint_export/) |
| `--all` | Export to all available formats |

## What It Does

1. Gathers all generated artifacts from current session
2. Creates output directory if not exists
3. Writes artifacts in specified format(s)
4. Generates consolidated report and export summary

## Exported Files

| File | Content |
|------|---------|
| `{PROJECT_ID}_Full_Report.md` | Consolidated report with all artifacts |
| `{PROJECT_ID}_Intake_Summary.md` | Intake summary |
| `{PROJECT_ID}_Sprint_Brief.md` | Sprint brief(s) |
| `{PROJECT_ID}_Review_Memo.md` | Review memo(s) |
| `{PROJECT_ID}_Backlog.md` | Revision backlog |
| `{PROJECT_ID}_Amendment_Summary.md` | Amendment summary |
| `{PROJECT_ID}_Sprint_Review.md` | Sprint review(s) |
| `{PROJECT_ID}_Retrospective.md` | Retrospective(s) |
| `{PROJECT_ID}_Human_Finalization.md` | Human finalization note |
| `{PROJECT_ID}_Process_Log.md` | Process log |
| `{PROJECT_ID}_Report.docx` | Word document (if --format docx) |
| `{PROJECT_ID}_Report.tex` | LaTeX source (if --format latex) |
| `{PROJECT_ID}_Report.pdf` | PDF document (if --format pdf) |
| `{PROJECT_ID}_Report.html` | HTML document (if --format html) |

## Implementation Notes

**Markdown Export**: Uses Write tool directly - always available.

**DOCX/LaTeX/HTML Export**: Requires `pandoc`. Auto-installs if missing.

**PDF Export**: Tries pandoc first, falls back to Python fpdf2.

## Example Output

```
## Export Complete

**Output Directory**: ./papersprint_export/
**Project ID**: PS-20260313

**Generated Files**:
| File | Format | Size |
|------|--------|------|
| PS-20260313_Full_Report.md | Markdown | 45 KB |
| PS-20260313_Report.docx | DOCX | 52 KB |
| PS-20260313_Report.pdf | PDF | 48 KB |

**Location**: /home/user/project/papersprint_export/
```

---

# Command: /ps reset

Reset current project session.

## Usage

```
/ps reset
/ps reset --keep-log
```

## Options

| Option | Description |
|--------|-------------|
| `--keep-log` | Preserve process log |

## Warning

This clears current session state. Use with caution.

---

# Command: /ps checkpoint

Save a compact snapshot of current session state for later resumption.

## Usage

```
/ps checkpoint
```

## What It Does

Outputs a portable state block containing:
- Project ID and venue
- Current stage and sprint number
- All backlog items with status
- Gate check results
- Focus area

The block can be copied and pasted back into a new session using `/ps resume`.

## Output Format

```yaml
## PaperSprint Checkpoint
project_id: PS-{timestamp}
venue: {venue}
stage: {stage}
sprint: {n}
gate_status:
  contribution: pass | fail | not_checked
  rigor: pass | fail | not_checked
  writing: pass | fail | not_checked
backlog:
  - id: B001
    title: {title}
    severity: critical
    status: open | in_progress | closed
    bucket: {bucket}
focus: {current_focus}
```

## Auto-Trigger

After 20+ exchanges in a session, the agent will offer:
"This session is getting long. Run `/ps checkpoint` to save your progress in case context is lost."

---

# Command: /ps resume

Re-initialize session state from a checkpoint block.

## Usage

```
/ps resume
[paste checkpoint YAML block]
```

## What It Does

1. Parses the checkpoint block
2. Restores: project ID, stage, sprint number, gate results, backlog items
3. Confirms restored state to user
4. Recommends next action based on restored context

## Output

```
✅ Session restored from checkpoint PS-{timestamp}
Stage: {stage} | Sprint: {n} | Open backlog items: {count}
Gate status: Contribution ✅ | Rigor ❌ | Writing —
Recommended next: /ps gate check rigor
```
