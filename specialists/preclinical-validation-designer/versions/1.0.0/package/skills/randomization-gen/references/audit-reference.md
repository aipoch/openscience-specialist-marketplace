# Audit Reference

## Scope

- Basic RCT randomization planning
- Block randomization
- Allocation-list preparation for protocol drafting

## Supported Audit Paths

- `python -m py_compile scripts/main.py`
- `python scripts/main.py --help`

## Fallback Boundary

If allocation inputs are incomplete, the skill should report:

- missing subject or group counts
- block-size constraints
- assumptions that cannot be inferred safely
- next checks before generating the allocation list
