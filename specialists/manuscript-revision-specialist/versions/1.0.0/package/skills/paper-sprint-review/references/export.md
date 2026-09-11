# Export — Detailed Rules

## Export Commands

```
/ps export                    # Export as Markdown (default)
/ps export --format md        # Export as Markdown
/ps export --format docx      # Export as Microsoft Word
/ps export --format latex     # Export as LaTeX
/ps export --format pdf       # Export as PDF
/ps export --format html      # Export as HTML
/ps export --all              # Export all formats
/ps export --output ./mydir/  # Custom output directory
```

## Export File List

| File | Contents |
|------|----------|
| `{PROJECT_ID}_Full_Report.md` | Merged report (all artifacts) |
| `{PROJECT_ID}_Intake_Summary.md` | Intake summary |
| `{PROJECT_ID}_Sprint_Brief.md` | Sprint brief |
| `{PROJECT_ID}_Review_Memo.md` | Review memo |
| `{PROJECT_ID}_Backlog.md` | Revision backlog |
| `{PROJECT_ID}_Amendment_Summary.md` | Amendment summary |
| `{PROJECT_ID}_Sprint_Review.md` | Sprint review |
| `{PROJECT_ID}_Retrospective.md` | Sprint retrospective |
| `{PROJECT_ID}_Human_Finalization.md` | Human finalization checklist |
| `{PROJECT_ID}_Process_Log.md` | Process log |

## Export Implementation

### Markdown Export
Use the Write tool to write directly to file.

### DOCX Export
Use pandoc:
```bash
pandoc {PROJECT_ID}_Full_Report.md -o {PROJECT_ID}_Report.docx
```
Fallback: Python `python-docx`

### LaTeX Export
Use pandoc:
```bash
pandoc {PROJECT_ID}_Full_Report.md -o {PROJECT_ID}_Report.tex --wrap=preserve
```

### PDF Export
Priority order:
1. pandoc + pdflatex
2. pandoc + wkhtmltopdf
3. Python fpdf2

### HTML Export
Use pandoc:
```bash
pandoc {PROJECT_ID}_Full_Report.md -o {PROJECT_ID}_Report.html --standalone --toc
```

## Export Success Output

```markdown
## Export Complete

**Output Directory**: ./papersprint_export/
**Project ID**: PS-20260316

**Generated Files**:
| File | Format | Size |
|------|--------|------|
| PS-20260316_Full_Report.md | Markdown | 45 KB |
| PS-20260316_Report.pdf | PDF | 48 KB |

**Location**: /home/user/project/papersprint_export/
```

## Error Handling

If export fails:
1. Check tool availability (pandoc, pdflatex, python packages)
2. Try fallback methods in priority order
3. If all fail, export Markdown only and notify the user
4. Provide installation instructions for any missing tools
