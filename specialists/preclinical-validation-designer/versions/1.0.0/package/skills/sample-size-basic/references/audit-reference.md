# Audit Reference

## Scope

- Basic sample-size planning
- Early protocol sizing assumptions
- Quick educational or grant-planning estimates

## Supported Audit Paths

- `python -m py_compile scripts/main.py`
- `python scripts/main.py --help`

## Fallback Boundary

If required statistical inputs are incomplete, the skill should return:

- the missing inputs
- the test family that appears intended
- assumptions that cannot be inferred safely
- the next checks before a final calculation
