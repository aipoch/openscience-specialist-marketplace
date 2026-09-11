# Audit Reference

## Scope

- SOP drafting for labs and clinical operations
- Procedure structure and compliance sections
- Role, responsibility, and QC section planning

## Supported Audit Paths

- `python -m py_compile scripts/main.py`
- `python scripts/main.py --help`

## Fallback Boundary

If procedure inputs are incomplete, the skill should still return:

- the missing SOP inputs
- the sections that can be drafted safely
- compliance assumptions that need confirmation
- the next checks before approving a final SOP draft
