# Workload Configurations
# pcd-immune-oncology-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid proof-of-concept mechanism + prognosis outline |
| **Timeline** | 2–4 weeks |
| **Data** | 1 TCGA-like cohort or 1 GEO cohort with survival + curated PCD gene set |
| **Core Modules** | DEG, simple survival screen, one clustering layer or one simple risk layer, ssGSEA/GSVA, basic pathway interpretation |
| **Validation** | Internal descriptive consistency only |
| **Drug layer** | Optional and limited; hypothesis wording only |
| **Figure complexity** | 4–5 figures |
| **Strengths** | Fast, feasible, low barrier |
| **Weaknesses** | Limited robustness; not strong enough for competitive journals alone |

---

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Conventional oncology bioinformatics paper |
| **Timeline** | 1–2 months |
| **Data** | TCGA-like discovery cohort + 1 external GEO validation cohort + mutation / clinical data where available |
| **Core Modules** | Consensus clustering, survival differences, immune scoring, LASSO-Cox risk score, KM/ROC, GO/KEGG, mutation summary, checkpoint panel, oncoPredict |
| **Validation** | Internal split + external cohort + HPA/tissue plausibility |
| **Figure complexity** | 7–9 figures |
| **Strengths** | Strong baseline paper logic; matches common reviewer expectations |
| **Weaknesses** | TIDE/TMB and drug modules still remain predictive / computational |

---

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Stronger immunotherapy and translational defensibility |
| **Timeline** | 2–3 months |
| **Data** | Standard data + richer mutation data + TIDE/TMB context + multi-tool immune analysis |
| **Core Modules** | All Standard + C-index/calibration/nomogram, multi-tool immune robustness, TIDE/TMB integration, PRISM/CTRP cross-check, subtype anchoring |
| **Validation** | Broader model and immune robustness |
| **Figure complexity** | 9–11 figures |
| **Strengths** | Better reviewer-proofing; stronger translational framing |
| **Weaknesses** | More moving parts; risk of overclaiming if not tightly controlled |

---

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum computational defensibility |
| **Timeline** | 3–6 months |
| **Data** | Multi-cohort discovery/validation, subtype anchoring, possible pan-cancer context, deeper drug-support evidence |
| **Core Modules** | All Advanced + multi-cohort replication, classification anchoring (MSI/EBV/Lauren/TCGA/ACRG when available), pan-cancer context, deeper translational prioritization and reviewer-focused sensitivity analyses |
| **Validation** | Maximum feasible computational robustness |
| **Figure complexity** | 10–12 figures |
| **Strengths** | Strong publication architecture |
| **Weaknesses** | Time-intensive; still computational unless experimental work is added outside this skill |

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **TIDE / TMB-dependent interpretation** may appear only when the configuration explicitly includes the required inputs and labels them as predictive context rather than true treatment response.
2. **Drug sensitivity conclusions** may appear only when a drug-prediction module is declared, and they must remain framed as computational hypotheses.
3. **Nomogram / calibration / decision curve claims** require adequate internal + preferably external validation layers.
4. **Pan-cancer or established-subtype anchoring** may appear only when corresponding external datasets or classification metadata are declared.
5. **Minimal Executable Version** must inherit only modules declared in Lite unless explicitly labeled as an upgraded minimal variant.

### Required Self-Check Questions
Before finalizing any output, verify:
- Does any step require data that was never declared earlier?
- Does any claim imply immunotherapy efficacy without treated-cohort evidence?
- Does any drug statement exceed computational-hypothesis strength?
- Does the Minimal Executable Version contain Advanced / Publication+ modules?
- Are model-performance claims matched to actual validation depth?

### Evidence-Claim Formula Reference
Valid examples:
- DEG + survival association only
- clustering + immune context only
- risk score + external validation
- checkpoint + TIDE/TMB predictive context only
- oncoPredict-based drug sensitivity hypothesis only
