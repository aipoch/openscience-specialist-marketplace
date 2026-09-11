# Audit Reference

## Scope

- Adaptive trial design planning
- Interim analysis simulation
- Sample-size re-estimation
- Early-stopping boundary review

## Supported Audit Paths

- `python -m py_compile scripts/main.py`
- `python scripts/main.py --help`
- `python scripts/main.py --design group_sequential --n-simulations 50`
- `python scripts/main.py --design adaptive_reestimate --n-simulations 25 --optimize`

## Fallback Boundary

If a full simulation run is too slow or the environment is constrained, the skill should still return:

- the requested design type
- core assumptions
- a bounded simulation plan
- risks, limits, and next checks
