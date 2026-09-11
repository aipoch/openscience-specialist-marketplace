# Study Patterns — Detailed Logic
# mendelian-randomization-protocol-designer

---

## Pattern A — Core One-Way Two-Sample MR

**Use when:** The user asks whether one exposure causally affects one outcome and no justified extension is clearly required.

## Pattern B — One-Way MR with Reverse-Direction Check

**Use when:** The main question is directional, but reverse causation concern is substantial enough to justify a focused reverse MR check.

## Pattern C — Fully Bidirectional MR

**Use when:** The user explicitly wants both directions treated as primary, and both traits plausibly support instrument construction.

## Pattern D — Multivariable MR-Enabled Design

**Use when:** The main question requires separating correlated exposures or adjusting for a competing genetically predicted pathway.

## Pattern E — MR with Mechanistic / Localization Follow-Up

**Use when:** The user wants stronger biological prioritization after the main MR result, such as colocalization, tissue-aware follow-up, or downstream target prioritization.

## Pattern F — Phenotype-Family or Subtype-Resolved MR

**Use when:** Exposure or outcome has meaningful subtypes, or the user wants a structured panel rather than one single pair.

---

## Pattern Combination Rules

| Combination | When Appropriate |
|---|---|
| A + E | Standard single-pair MR plus biological follow-up planning |
| B + E | One-way MR with reverse check and mechanistic prioritization |
| C + F | Bidirectional MR with subtype or phenotype-family structure |
| D + E | MVMR main design plus downstream localization / follow-up |
| A + F | One core causal question tested across related outcome subtypes |

---

## Anti-Overdesign Rule

Choose the **simplest pattern that adequately answers the user's question**.
Do not upgrade to bidirectional MR, MVMR, or mechanistic follow-up merely because those designs look more sophisticated.
