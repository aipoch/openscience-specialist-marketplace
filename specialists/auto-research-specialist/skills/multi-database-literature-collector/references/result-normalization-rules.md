# Result Normalization Rules

Cross-database literature collection is only useful if the records are normalized.

## Minimum Record Fields
- Title
- Authors
- Year
- Journal / Venue
- Database Source
- Abstract or snippet when available
- Study Type
- Direct Link
- DOI when available
- PMID when available
- Evidence Status
- Preliminary Tier

## DOI Rule
- Include DOI when available and verified
- If the paper lacks a DOI or the DOI cannot be confirmed, write:
  - `DOI not available`
  - or `DOI not verified`
- Never insert placeholder DOI strings

## Link Rule
Every formal record must include a real direct link to a verifiable source page.
Acceptable examples include:
- DOI landing page
- PubMed
- PMC
- journal page
- preprint server page

## Source Preservation Rule
Never strip source metadata. Keep the original database source for each record.
