# Algorithm Details

## Core Workflow

The skill reproduces the sample-level hierarchical clustering logic from the source analysis script:

```r
dist_mat <- dist(t(expr))
clustering <- hclust(dist_mat, method = "complete")
plot(clustering, labels = sample_infor$batch)
```

The standardized version keeps the same analytical pattern while adding CLI parameters, validation, and file outputs.

## Step 1: Matrix Orientation

The expression matrix is expected in feature-by-sample format.

- Rows: genes or other measured features
- Columns: samples

Because `dist()` computes distances between rows, the matrix is transposed before distance calculation:

```r
dist(t(expr_mat), method = distance_method)
```

This converts the data into sample-by-feature form.

## Step 2: Pairwise Distance Calculation

Distances are computed with base R `dist()`.

Supported metrics:

- `euclidean`
- `maximum`
- `manhattan`
- `canberra`
- `binary`
- `minkowski`

### Default: Euclidean Distance

For two samples `x` and `y` measured across `p` features:

```text
d(x, y) = sqrt(sum((x_i - y_i)^2))
```

This emphasizes overall expression-profile similarity between samples.

## Step 3: Hierarchical Clustering

The clustering tree is built with base R `hclust()`:

```r
hclust(distance_obj, method = linkage_method)
```

Supported linkage methods:

- `complete`
- `single`
- `average`
- `mcquitty`
- `median`
- `centroid`
- `ward.D`
- `ward.D2`

### Default: Complete Linkage

Complete linkage defines the distance between two clusters as the maximum pairwise distance between their members.

```text
D(A, B) = max(d(a, b)) for all a in A, b in B
```

This tends to produce compact and well-separated clusters and matches the original script.

## Step 4: Dendrogram Rendering

The final dendrogram is rendered to PDF using base R plotting.

- Leaf order follows `hc$order`
- Labels come from the selected metadata column
- The skill also exports the plotted leaf order to `clustering_order.csv`

## Assumptions

- The expression matrix contains numeric values only.
- Sample IDs in the metadata file match matrix column names exactly.
- The selected label column contains valid labels for every sample.
- Input data is already normalized if cross-sample scale differences should be minimized.

## Interpretation Notes

- Short branch lengths indicate more similar samples.
- Strong separation by batch labels may indicate batch effects.
- Outlier samples often appear on long isolated branches.
- Different distance or linkage settings can change tree topology.
