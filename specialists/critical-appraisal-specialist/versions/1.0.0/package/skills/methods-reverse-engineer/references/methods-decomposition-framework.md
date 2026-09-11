# Methods Decomposition Framework

Reconstruct methods as an ordered chain.

## Default decomposition order
1. objective and comparison logic
2. source population / samples / datasets
3. eligibility or filtering
4. grouping / exposure / intervention assignment
5. preprocessing / normalization / sample preparation
6. primary analysis or experimental manipulation
7. secondary analyses / model building / subgroup analyses
8. validation / confirmation / replication
9. outputs and endpoint generation

## Rules
- Preserve actual order when known.
- When exact order is unclear, state the ambiguity.
- Separate acquisition steps from analytical steps.
- Separate discovery steps from validation steps.
