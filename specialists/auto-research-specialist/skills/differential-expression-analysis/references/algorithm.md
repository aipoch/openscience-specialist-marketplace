# Algorithm Details

## Statistical Methods

### 1. limma

limma uses linear models to assess differential expression. It works by:

1. Fitting a linear model to expression data: `Y = Xβ + ε`
2. Creating a contrast matrix for pairwise comparisons
3. Applying empirical Bayes moderation to borrow information across genes
4. Computing moderated t-statistics

**Assumptions:**
- Expression values are normally distributed
- Variances are similar across genes (moderated by empirical Bayes)
- Suitable for normalized expression data (FPKM, TPM, RMA-processed microarray)

### 2. DESeq2

DESeq2 uses negative binomial distribution for count data:

1. Estimating size factors for library normalization
2. Fitting a negative binomial generalized linear model
3. Testing for differential expression using Wald test or LRT

**Assumptions:**
- Count data follows negative binomial distribution
- Mean > variance (overdispersion modeled)
- Suitable for raw sequencing counts

### 3. edgeR

edgeR also uses negative binomial models:

1. Filtering low-expressed genes (CPM > 1 in at least 2 samples)
2. Normalizing by TMM (trimmed mean of M-values)
3. Estimating dispersion using empirical Bayes
4. Testing using generalized linear model (GLM)

**Normalization Methods:**
- TMM: Trimmed mean of M-values (default)
- RLE: Relative log expression
- Upperquartile: Upper quartile normalization

### 4. t-test

Simple pairwise comparison:

```
logFC = mean(treatment) - mean(control)
t_stat = logFC / sqrt(var1/n1 + var2/n2)
```

**Assumptions:**
- Normally distributed expression values
- Equal variances between groups (Welch's correction applied)

### 5. Wilcoxon Rank-Sum Test

Non-parametric alternative:

1. Ranking all values across groups
2. Computing rank-sum statistic
3. Testing for difference in distributions

**Advantages:**
- No normality assumption
- Robust to outliers

## Multiple Testing Correction

P-values are adjusted using Benjamini-Hochberg (BH) method:

```
Padj = p * n / rank
```

Where n is the total number of tests.
