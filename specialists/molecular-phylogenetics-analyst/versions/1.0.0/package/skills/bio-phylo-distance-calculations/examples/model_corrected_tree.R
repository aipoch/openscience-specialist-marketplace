# Model-corrected distance tree in ape. Deliverable: a TN93+gamma distance matrix and a FastME
# balanced-minimum-evolution tree with bootstrap -- the correction is where the biology lives,
# unlike Biopython's identity-only DistanceCalculator. Outputs go to tempdir(), no strays.
# Reference: ape 5.8+ | Verify API if version differs

library(ape)

aln <- as.DNAbin(matrix(c(
  strsplit('ATGCATGCATGCATGCATGC', '')[[1]],
  strsplit('ATGCATGCATGAATGCATGC', '')[[1]],
  strsplit('ATGCATGAATGCATGCATGC', '')[[1]],
  strsplit('ATGAATGCATGCATGCATGC', '')[[1]],
  strsplit('ATGAATGAATGCATGCATGC', '')[[1]]),
  nrow = 5, byrow = TRUE,
  dimnames = list(c('Human', 'Chimp', 'Gorilla', 'Mouse', 'Rat'), NULL)))

# TN93 = two transition rates + unequal base freqs; gamma applies ASRV (alpha < 1 = strong heterogeneity).
# FastME balanced minimum evolution: the modern best distance tree (searches, not a single greedy pass).
# Define the method ONCE so the bootstrap replicates use exactly the correction that built the tree.
alpha <- 0.5
method <- function(x) fastme.bal(dist.dna(x, model = 'TN93', gamma = alpha), nni = TRUE, spr = TRUE)
tree <- method(aln)

# Bootstrap: 100-1000 reps standard; this is sampling PRECISION, not accuracy.
set.seed(42)
bs <- boot.phylo(tree, as.matrix(aln), method, B = 100, quiet = TRUE)
tree$node.label <- bs                               # attach support (replicate counts out of B)
cat('Bootstrap counts per internal node (of 100):', bs, '\n')

out <- file.path(tempdir(), 'distance_tree.nwk')
write.tree(tree, out)
cat('Wrote model-corrected FastME tree to', out, '\n')
print(tree)
