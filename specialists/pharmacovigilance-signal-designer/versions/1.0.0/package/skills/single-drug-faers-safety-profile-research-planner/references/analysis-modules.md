# Analysis Module Library
# single-drug-faers-safety-profile-research-planner

---

## FAERS Core Modules

| Module | Purpose | When Required |
|---|---|---|
| Case extraction and de-duplication logic | Define analyzable FAERS case set consistently | Always |
| Drug exposure definition | Fix suspect/concomitant inclusion and naming normalization | Always |
| AE dictionary mapping | Define SOC/PT/HLT-level safety scope reproducibly | Always |
| Core disproportionality analysis | Establish primary signal-detection framework | Always |
| Signal visualization | Forest, heatmap, ranking, or bubble summary for interpretable outputs | Lite+ |
| Signal filtering and threshold logic | Prevent arbitrary downstream emphasis | Always |

## Comparative / Profiling Modules

| Module | Purpose | When Required |
|---|---|---|
| Comparator restriction | Reduce denominator mismatch and therapeutic-context distortion | Comparative pattern, Standard+ |
| Within-class contrast | Compare subclass or pharmacologic differences systematically | Comparative pattern C, Standard+ |
| Whole-profile PT/SOC atlas | Map one-drug global safety distribution | Single-drug pattern A, Lite+ |
| Fixed SOC / PT panel focus | Keep the story inside one clinically coherent safety theme | Comparative pattern B / D |
| Multi-metric signal comparison | Cross-check ROR / PRR / IC / EBGM-style outputs where appropriate | Standard+ |
| Signal ranking compression | Reduce a long signal table into a reviewer-usable endpoint set | Standard+ |

## Characterization Modules

| Module | Purpose | When Required |
|---|---|---|
| Age / sex subgroup analysis | Add demographic characterization while controlling scope | When subgroup angle requested |
| Reporter-type or region stratification | Evaluate reporting-structure sensitivity | Advanced+ |
| Seriousness outcome profiling | Add hospitalization / death / life-threatening context | When seriousness angle requested |
| Onset-time characterization | Add time-to-onset or early-vs-late signal description | When onset angle requested |
| Label-gap framing | Distinguish known, under-discussed, and potentially novel signals | When label-context requested |

## Robustness and Reporting Modules

| Module | Purpose | When Required |
|---|---|---|
| Sensitivity restriction logic | Show the signal survives alternate case filters or denominator choices | Standard+ |
| Evidence-label matrix | Separate signal, comparative, characterization, and excluded inference tiers | Always |
| Figure dependency map | Ensure story flows from extraction to final safety conclusion | Standard+ |
| Risk and downgrade review | Control overclaiming and infeasible overdesign | Always |
| Literature support layer | Justify safety background, methods, and novelty gap | Always |
