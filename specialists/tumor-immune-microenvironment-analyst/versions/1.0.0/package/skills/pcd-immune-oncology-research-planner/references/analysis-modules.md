# Analysis Module Library
# pcd-immune-oncology-research-planner

---

## Core Expression and Gene-Set Modules

| Module | Purpose | When Required |
|---|---|---|
| Curated PCD / RCD gene-set assembly | Define mechanism scope from published sources | Always |
| DEG analysis (tumor vs normal or risk high vs low) | Identify disease- or subgroup-associated genes | Always |
| Univariate Cox screening | Narrow genes associated with survival | Standard+ |
| Correlation network | Explore gene-gene relationships within curated mechanism | Lite+ |
| CNV visualization | Show structural alteration tendency of mechanism genes | Standard+ |
| Pan-cancer expression context | Assess whether mechanism extends beyond one cancer | Publication+ |

## Molecular Stratification Modules

| Module | Purpose | When Required |
|---|---|---|
| Consensus clustering | Discover stable patient subtypes | Standard+ |
| PCA / t-SNE / UMAP on samples | Visualize subtype separation | Standard+ |
| Heatmap of subtype-clinical associations | Link clusters to stage / grade / survival / covariates | Standard+ |
| Survival comparison across clusters | Show subtype prognostic difference | Standard+ |
| Subtype anchoring against existing classes | Compare with TCGA / ACRG / MSI / immune classes | Advanced+ |

## Prognostic Modeling Modules

| Module | Purpose | When Required |
|---|---|---|
| LASSO feature reduction | Prevent overfitting in candidate-gene selection | Standard+ |
| Multivariable Cox model | Build final risk score | Standard+ |
| Kaplan–Meier stratification | Compare high- vs low-risk outcomes | Standard+ |
| Time-dependent ROC | Evaluate 1/3/5-year performance | Standard+ |
| C-index / calibration | Assess model discrimination and calibration | Advanced+ |
| Nomogram | Translational presentation of survival prediction | Advanced+ |
| Internal train/test split | Reduce optimistic bias | Standard+ |
| External cohort validation | Test generalizability | Standard+ |

## Immune Landscape Modules

| Module | Purpose | When Required |
|---|---|---|
| ssGSEA / GSVA immune scoring | Estimate immune activity from transcriptome | Lite+ |
| Multi-tool immune deconvolution (xCell, TIMER, MCPcounter, CIBERSORT-like) | Strengthen immune-infiltration robustness | Advanced+ |
| Checkpoint gene expression panel | Examine immune-escape / ICI-relevant markers | Standard+ |
| TIDE score | Predictive context for potential ICI responsiveness | Advanced+ |
| TMB integration | Add mutation burden context | Advanced+ |
| Combined risk + TIDE / TMB stratification | Explore layered prognostic separation | Advanced+ |

## Genomic Alteration Modules

| Module | Purpose | When Required |
|---|---|---|
| Somatic mutation summary | Characterize top mutated genes in risk groups | Standard+ |
| Waterfall plot | Visualize mutation heterogeneity | Standard+ |
| CNV frequency plot | Mechanism-gene alteration context | Standard+ |
| Genomic subgroup comparison | Associate mutation patterns with risk / clusters | Advanced+ |

## Functional Interpretation Modules

| Module | Purpose | When Required |
|---|---|---|
| GO / KEGG enrichment | Biological interpretation of DEGs | Standard+ |
| Hallmark or pathway GSVA | Quantify process-level activity (EMT, angiogenesis, cell cycle) | Standard+ |
| Correlation with oncogenic hallmarks | Relate PCD score to aggressive traits | Advanced+ |
| Integrated mechanistic model figure | Summarize subtype-risk-immune-drug logic | All configs |

## Drug Sensitivity / Translational Modules

| Module | Purpose | When Required |
|---|---|---|
| oncoPredict + GDSC | In silico drug sensitivity estimation from transcriptome | Standard+ |
| PRISM / CTRP cross-check | Secondary support for drug hypotheses | Advanced+ |
| Drug-class grouping | Interpret compounds mechanistically rather than as a flat list | Advanced+ |
| HPA / GTEx protein or tissue validation | Support biomarker plausibility | Standard+ |
| Reviewer-safe wording audit | Prevent overclaiming computational drug outputs | Always when drug module used |
