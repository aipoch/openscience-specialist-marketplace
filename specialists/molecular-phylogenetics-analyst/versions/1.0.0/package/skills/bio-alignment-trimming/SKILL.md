---
name: bio-alignment-trimming
description: Trim multiple sequence alignments using ClipKIT, trimAl, BMGE, Divvier, or HMMcleaner with mode selection guidance per downstream goal. Use when removing unreliable columns or contaminating residues before phylogenetic inference, HMM building, or selection analysis.
tool_type: mixed
primary_tool: ClipKIT
---

## Version Compatibility

Reference examples tested with: ClipKIT 2.14.0, trimAl 1.4.1, BMGE 1.12 and 2.0 (different flags, see below), MACSE 2.07, PAML 4.10.10, Divvier 1.01+, HMMcleaner (current CPAN release of `Bio::MUST::Apps::HmmCleaner`), BioPython 1.83+

Before using code patterns, verify installed versions match. If versions differ:
- CLI: `clipkit --version`, `trimal --version`, `BMGE --help`, `Divvier --help`
- Python: `pip show <package>` then `help(module.function)` to check signatures

If code throws ImportError, AttributeError, or TypeError, introspect the installed package and adapt the example to match the actual API rather than retrying.

# Alignment Trimming

**"Remove unreliable columns from this MSA"** -> Filter or split columns based on gap fraction, conservation, entropy, or per-residue quality.
- CLI: `clipkit`, `trimal`, `BMGE`, `Divvier`, `HMMcleaner`
- Python: post-process via Bio.AlignIO with custom column masks

**"Make this alignment publication-grade for phylogenetics"** -> Apply ClipKIT's `smart-gap` mode (its default), or trimAl `-automated1`, then verify via tree-stability comparison before vs after trimming.

Tool choice and aggressiveness matter more than trimming vs not-trimming. Pick a mode by dataset character (table below), and always run a sensitivity check by building trees on trimmed and untrimmed alignments.

### Pick a Trimming Mode by Dataset Character

| Dataset character | Trimming effect | Recommended approach |
|-------------------|-----------------|----------------------|
| Deep-divergence orthologs (>500 Ma), saturated 3rd codons | Aggressive trimming can hurt | No trim or light gap-based trim (`smart-gap`); report sensitivity to trimming choice |
| Mid-depth eukaryotic (animal phyla, fungal classes) | Light gap-based trimming usually neutral | ClipKIT `smart-gap`; confirm with trimmed vs untrimmed trees |
| Shallow (within-genus) | All trimmers ~equivalent | Choose for downstream-tool compatibility |
| Concatenated supermatrix with very long alignments (>10 kb) | Trimming removes gappy, poorly aligned regions | `smart-gap` or BMGE, run PER LOCUS before concatenation (trimming the concatenation invalidates partition charsets: IQ-TREE "Too large site ID") |
| Single short genes (<200 bp aligned) | Trimming amplifies stochastic error | Skip column trimming; use sequence-level outlier filtering |

**The 20%/40% rule (gap- and entropy-based trimming only).** Tan et al 2015 (Syst Biol) found that automated filtering frequently worsens single-gene trees. As an operational heuristic for modes that remove columns by gap content or entropy (ClipKIT `smart-gap`/`gappy`/`gappyout`, trimAl gap and similarity modes, BMGE, Gblocks): removing <20% of columns is light trimming; if the trimmer removes >40% (retention < 0.6), it is too aggressive for the dataset -- switch to a less aggressive setting or skip trimming. The heuristic does NOT apply to ClipKIT `kpic*`/`kpi*` modes: they drop every singleton column (`kpi*` also every constant column) by design, so they routinely remove 40-55% of a single gene. Judge those modes only by comparing topology AND branch lengths against the untrimmed alignment, never by column fraction.

Always run a sensitivity analysis: build the tree on trimmed AND untrimmed alignments. If topology and support are stable across trimming choices, the conclusion is robust; if unstable, report this and pick the result better supported by independent evidence (gene-tree concordance, biological priors).

## Goal-Driven Tool Selection

| Downstream goal | First-line tool | Rationale |
|----------------|-----------------|-----------|
| Phylogenetic-tree input (concatenated genes) | ClipKIT `smart-gap`, per locus (Steenwyk et al 2020 PLOS Bio) | ClipKIT 2.14.0 default; removes only gappy columns, so branch lengths stay close to the untrimmed tree |
| Phylogenetic-tree input (single gene) | ClipKIT `smart-gap` | Default mode; dynamic gap-threshold determination |
| HMM profile building (HMMER, HHsuite) | trimAl `-gappyout` (Capella-Gutierrez et al 2009 Bioinf) | Aggressive gap removal acceptable; profile quality benefits |
| Selection / dN/dS analysis (PAML, HyPhy) | TCS column masking or GUIDANCE2 (NOT aggressive trimming) | Removing columns causes false-positive selection signals (Fletcher & Yang 2010 MBE) |
| Deep prokaryotic phylogenomics | BMGE (Criscuolo & Gribaldo 2010 BMC Evol Biol) | Entropy-based with BLOSUM62 context; standard in GToTree pipeline |
| Cross-contaminated sequences | HMMcleaner (Di Franco et al 2019 BMC Evol Biol) | Per-residue cleaning; targets contamination not column quality |
| Preserve phylogenetic signal in indels | Divvier (Ali, Bogusz & Whelan 2019 MBE) | Splits ambiguous columns rather than removing them |
| Column-mapping retention for site analysis | trimAl `-colnumbering` | Outputs original-column indices for downstream cross-reference |
| Codon-aware trimming | MACSE `trimAlignment` (Ranwez et al 2018 MBE) | Preserves codon boundaries; pairs with MACSE codon MSA |

## ClipKIT Modes

Pick a `-m` mode by what the downstream task needs the alignment to KEEP. Run `clipkit --help` for the full list of 15 modes.

| Pick this mode | When |
|----------------|------|
| `smart-gap` | Default for single genes and supermatrices (ClipKIT's own default); keeps singleton and constant columns, so branch lengths are preserved |
| `kpic-smart-gap` | Topology-focused option for taxonomically balanced datasets only. Drops all singleton columns (typically 40-55% of a gene). Always compare outgroup/stem branch lengths before vs after; do not use when branch lengths feed dating, rate estimates or rooting |
| `gappy` / `gappyout` | Need an explicit gap threshold or trimAl-like behaviour |
| `kpi-smart-gap` / `kpi` | Parsimony-only input. Drops constant AND singleton columns, which inflates ML branch lengths; do not use for ML/Bayesian trees |
| `c3` / `cst` / `entropy` / `block-gappy` / `composition-bias` / `heterotachy` | Specialist needs: third-codon stripping, manual masks, entropy thresholding, conserved-block preservation, long-branch mitigation, or heterotachy filtering -- consult `clipkit --help` |

**Goal:** Run ClipKIT on an MSA with the mode appropriate to the downstream goal.

**Approach:** Pick a `-m` mode from the table above, optionally enable `--log` for reproducibility, and write the trimmed alignment in the desired format.

```bash
clipkit input.fasta -m smart-gap -o trimmed.fasta
clipkit input.fasta -m gappy -g 0.9 -o trimmed.fasta
clipkit input.fasta -m smart-gap -of phylip -o trimmed.phy
clipkit input.fasta -m smart-gap --log -o trimmed.fasta
```

The `--log` flag writes `<output>.log` with a per-column kept/removed record -- essential for reproducibility audits. ClipKIT also has a Python API (`clipkit.api.clipkit`) for in-memory trimming.

### ClipKIT kpic Failure Modes

`kpic` keeps parsimony-informative sites ("at least 2 sequences with each of at least 2 different residues") and constant sites, and removes singletons. On taxonomically unbalanced datasets (e.g. many close relatives + a few outgroups), a column where a single outgroup carries a private state is a singleton and is removed, so much of the outgroup-vs-ingroup signal is lost. In a simulated 30-strain + 3-outgroup DNA alignment, `kpic-smart-gap` removed most such columns: topology was unchanged, but the ingroup/outgroup stem length went from 0.44 to 1.2 substitutions/site (true 0.44) and one outgroup's terminal branch collapsed to 0. `smart-gap` left every branch length unchanged. Mitigations:
- Use `smart-gap` on unbalanced datasets and whenever branch lengths matter (dating, rates, rooting)
- If `kpic-smart-gap` is used, compare outgroup stem and terminal branch lengths before vs after trimming; if they move, discard the kpic result
- ClipKIT's site classification is count-based and unweighted (no sequence weighting by clade); manual subsampling to balance clades is the practical fix

BMGE's `-w` option is a sliding window for smoothing entropy values (default 3), not a clade-aware weighting.

## trimAl Modes

Pick a trimAl mode by downstream tool. `-gappyout` for HMM profile builds, `-gappyout` or explicit `-strict` for ML tree input (`-strictplus` is documented by trimAl as optimized for Neighbour Joining), `-automated1` (documented as optimized for ML) only when audit-grade reproducibility is not required (heuristic has changed across point releases).

| Mode | Flag | Description |
|------|------|-------------|
| Automated heuristic | `-automated1` | Picks `gappyout`, `strict`, or `strictplus` based on alignment characteristics |
| Gap-only | `-gappyout` | Automatic gap-fraction threshold from gap distribution |
| Strict | `-strict` | Combined gap + similarity criterion |
| Strict-plus | `-strictplus` | Stricter than `-strict`; optimized for Neighbour Joining per trimAl help |
| Manual gap | `-gt 0.5` | Remove columns with > 50% gaps (set fraction explicitly) |
| Manual similarity | `-st 0.5` | Remove columns with similarity below threshold |
| Manual conservation | `-cons 60` | Keep at least 60% of original columns regardless of other criteria |
| Sequence-quality | `-resoverlap 0.8 -seqoverlap 75` | Remove sequences with poor residue/sequence overlap |
| HTML report | `-htmlout report.html` | Visual diff of kept/removed columns |
| Column mapping | `-colnumbering` | Output original column indices preserved |

**Goal:** Trim an MSA with trimAl using a heuristic or manual threshold suited to the downstream tool.

**Approach:** Select an automated mode (`-automated1`, `-gappyout`, `-strict`; `-strictplus` for NJ) for typical use, or compose `-gt`, `-st`, `-cons` thresholds for manual control; export an HTML diff or column index mapping when audit-grade reproducibility is required.

```bash
trimal -in input.fasta -out trimmed.fasta -automated1
trimal -in input.fasta -out trimmed.fasta -gappyout
trimal -in input.fasta -out trimmed.fasta -strictplus -htmlout report.html
trimal -in input.fasta -out trimmed.fasta -gt 0.3 -st 0.5 -cons 60 -colnumbering > columns.txt
```

`-gappyout` is the recommended choice for HMM profile building (HMMER `hmmbuild` benefits from aggressive gap removal). For ML tree input use `-gappyout` or `-strict`; `-strictplus` is NJ-oriented and was the only trimAl mode that lost topological accuracy in a 10-replicate simulated check. `-automated1` is the fallback when characterising the dataset is impractical (it chose `-strict` and removed 61% of columns on one 15-sequence protein alignment -- check retention).

**Reproducibility note:** `trimAl -automated1` selects between `gappyout`, `strict`, and `strictplus` via internal heuristics that have changed between releases. For audit-grade reproducibility, do NOT use `-automated1`; specify the underlying mode explicitly and record `trimal --version` in pipeline manifests.

## BMGE: Block Mapping and Gathering with Entropy

Use BMGE for deep prokaryotic phylogenomics (the GToTree default) or whenever entropy-based, matrix-aware column filtering is preferred over gap-only heuristics.

**Goal:** Filter MSA columns by matrix-aware entropy and gap-rate thresholds, particularly for deep prokaryotic phylogenomics.

**Approach:** Invoke BMGE with `-t` (sequence type) and tune the entropy and gap-rate thresholds against the divergence depth of the dataset; recalibrate the entropy threshold if the substitution matrix is changed via `-m`. BMGE 1.12 and 2.0 use different flags: on 2.0, `-h` prints help and exits 0 without writing anything, so always check that the output file exists and is non-empty.

```bash
# BMGE 1.12
java -jar BMGE.jar -i input.fasta -t AA  -h 0.5 -g 0.2 -of trimmed.fasta
java -jar BMGE.jar -i input.fasta -t DNA -m DNAPAM100:2 -h 0.5 -g 0.2 -of trimmed.fasta

# BMGE 2.0 (entropy is -e; types AA|CO|NT; output -o or -of)
java -jar BMGE.jar -i input.fasta -t AA -e 0.5 -g 0.2 -o trimmed.fasta
java -jar BMGE.jar -i input.fasta -t NT -m DNAPAM100:2 -e 0.5 -g 0.2 -o trimmed.fasta

test -s trimmed.fasta || echo "BMGE wrote no alignment: check flags against the installed version"
```

| Meaning | BMGE 1.12 | BMGE 2.0 |
|---------|-----------|----------|
| Entropy threshold (lower = more aggressive) | `-h`, default 0.5 | `-e`, default 0.5 |
| Gap rate threshold | `-g`, default 0.2 | `-g`, default 0.5 |
| Substitution matrix | `-m`, default BLOSUM62 (AA) | `-m`, default BLOSUM30 (AA) / DNAPAM180:2 (NT) |
| Sequence type (required) | `-t AA`, `CODON`, `DNA` | `-t AA`, `CO`, `NT` |
| Minimum block size | `-b`, default 5 | `-b`, default 3 |
| Help | -- | `-h` |

Lower entropy thresholds trim much harder: on a simulated deep 16-taxon protein supermatrix, BMGE 1.12 `-h 0.4 -g 0.2` removed 87% of columns, shrank tree length from 12.5 (true) to 8.4 and lowered support, while `-h 0.5` removed 71%. Check retention against the 20%/40% rule and compare trees before lowering the threshold.

**Matrix-aware threshold:** BMGE computes entropy weighted by the chosen substitution-matrix probabilities. Entropy thresholds are calibrated for the version's default matrix (BLOSUM62 in 1.12, BLOSUM30 in 2.0). Switching to `-m BLOSUM30` (deep phylogenomics) makes the same numeric `-h` more permissive; `-m BLOSUM90` (close orthologs) makes it more aggressive. When using a non-default matrix, recalibrate by running on a known-good benchmark before applying.

## Divvier: Column Splitting Instead of Removal

Use Divvier when phylogenetic signal in indels matters and pure removal would discard block-boundary information; it splits ambiguous columns rather than dropping them.

```bash
# Divvier ships as a compiled binary; invoke as ./divvier or `divvier` if on PATH
./divvier -divvy input.fasta

./divvier -partial -mincol 4 -divvygap input.fasta
```

`-divvy` (default) outputs `input.fasta.divvy.fas` (full divvying); `-partial` only filters individual ambiguous characters. `-mincol N` sets the minimum number of confident characters required to keep a split column (integer count, default 2). `-divvygap` writes gaps instead of asterisks for phylogenetics-tool compatibility. Divvier is particularly useful when input alignments have many short conserved blocks separated by ambiguous regions -- removing the regions discards information about block boundaries that splitting preserves.

Maintenance note: Divvier's last release was 2019 (`simonwhelan/Divvier`); the tool is no longer actively maintained but results remain reproducible with the v2019 binary.

## HMMcleaner: Per-Residue Cleaning

Run HMMcleaner before column trimming when cross-contamination or annotation errors are suspected; it masks suspect residues with `X` rather than removing columns. Apply only to alignments with >= 15 sequences (below that the per-residue pHMM has too little signal and over-flags divergent residues).

```bash
HmmCleaner.pl input.fasta
```

Output is `input_hmm.fasta` with low-confidence residues masked. Used in OrthoMaM and Compositional Heterogeneity-aware phylogenomic pipelines where cross-contamination from sequencing or annotation errors is suspected.

**Sample-size sensitivity:** HMMcleaner builds a per-residue HMM from the OTHER sequences at each position, so on small alignments (<15 sequences) the HMM has insufficient signal and over-flags real divergent residues as contamination. Di Franco et al 2019 show two related effects: pHMMs built from few sequences carry less signal, lowering HMMcleaner sensitivity, and its false positives are driven mainly by evolutionary divergence -- specificity falls with gap frequency, evolutionary rate, and the fraction of ambiguously-aligned regions rather than by a fixed sequence count (global specificity ~94% at default settings). OrthoMaM v11 and PhyloHerb pipelines apply HMMcleaner only to alignments with >= 15 sequences. For smaller alignments, manual inspection or BLAST-based contamination screening is more reliable.

## Gblocks: The Legacy Default

Use Gblocks only when matching a legacy pipeline; prefer ClipKIT or trimAl for new work. Default parameters are too aggressive -- relax them. `-b1` and `-b2` are integer sequence COUNTS, not percentages: `-b1` must be greater than half the number of sequences N (default N/2 + 1), and `-b2` at least `-b1` (default 85% of N). Relaxed example for N = 20 sequences:

```bash
Gblocks input.fasta -t=p -b1=11 -b2=11 -b3=10 -b4=5 -b5=h
```

## PhyIN: Phylogenetic Incompatibility Trimming

PhyIN (Maddison 2024 PeerJ) is a complementary trimmer that flags neighbouring columns whose split patterns are phylogenetically incompatible (i.e. cannot share a tree). It targets a different failure mode than gap-based or entropy-based trimmers: ClipKIT, trimAl, and BMGE all evaluate columns independently, so a region with consistent gap structure passes their filters even if its character patterns are pairwise tree-incompatible (alignment artefact). PhyIN catches that case.

```bash
# PhyIN v1.0 is a single Python script; DNA/RNA FASTA alignments only
python phyin.py -input input.fasta -output trimmed.fasta -b 10 -d 2 -p 0.5
```

`-b` block length over which conflict is assessed, `-d` neighbour distance surveyed, `-p` proportion of conflicting neighbours that triggers removal; `-e` / `-not.e` treat gaps as an extra state or not. Use PhyIN as a SECOND-PASS trimmer after ClipKIT/trimAl when alignment artefact is the suspected source of incongruence in a phylogenomic dataset; not a replacement for first-pass column filtering. PhyIN's incompatibility test is signal-direction agnostic, so it does not distinguish "the alignment is wrong here" from "true incongruent locus" (e.g. introgression, ILS); only gene-tree comparison after tree-building can disambiguate. Reference: PeerJ 2024 paper.

## Decision Tree by Downstream Goal

```
What is the next step?
+- Phylogenetic ML tree (RAxML, IQ-TREE)
|  +- Concatenated supermatrix? -> ClipKIT smart-gap per locus, then concatenate
|  +- Single gene? -> ClipKIT smart-gap or trimAl -automated1
|  +- Topology only, balanced taxa? -> kpic-smart-gap allowed, with the branch-length check
|  +- Deep prokaryotic? -> BMGE at its default entropy threshold; check retention
|  +- Suspected cross-contamination? -> HMMcleaner first, then ClipKIT
|
+- Bayesian inference (MrBayes, BEAST)
|  +- Same as ML; trimming is acceptable but log column mapping
|
+- HMM profile (HMMER hmmbuild, HHsuite)
|  +- trimAl -gappyout (aggressive gap removal helps profile quality)
|
+- Selection analysis (PAML codeml, HyPhy)
|  +- DO NOT aggressively trim
|  +- Use TCS column masking (T-Coffee -evaluate) or GUIDANCE2
|  +- See alignment/multiple-alignment confidence assessment
|
+- Sequence logo / motif scan
   +- Light gap-only trim (trimAl -gt 0.5)
   +- Preserve all variable positions
```

## TCS Column Masking for Selection Analysis

TCS (Chang et al 2014 MBE) scores each column on a 0-9 scale by consistency across a pairwise-alignment library. The recommended dN/dS workflow:

**Goal:** Mask unreliable columns before selection analysis to prevent alignment errors from inflating false-positive dN/dS calls.

**Approach:** Build a library-rich consistency score via M-Coffee, evaluate the alignment against that library to obtain per-column TCS scores, then keep columns at or above a chosen confidence threshold using `seq_reformat`.

```bash
# 1. Generate library-rich consistency scores via M-Coffee (combines libraries from MAFFT, MUSCLE, ClustalW, ProbCons)
t_coffee input.fasta -mode mcoffee -output fasta_aln -outfile aligned.fasta

# 2. Compute per-column TCS scores; T-Coffee writes aligned.score_ascii itself (not to stdout)
t_coffee -infile aligned.fasta -mode evaluate -output score_ascii

# 3. Filter COLUMNS at a chosen threshold (5-9 = retain columns scoring 5 or higher).
#    +use_cons +keep acts on column scores; +keep alone keeps individual residues within the range.
t_coffee -other_pg seq_reformat -in aligned.fasta -struc_in aligned.score_ascii \
    -struc_in_f number_aln -action +use_cons +keep '[5-9]' -output fasta_aln > aligned_tcs5.fasta
```

Threshold guidance: TCS >= 5 retains columns confidently aligned by the majority of library methods; TCS >= 7 is a stricter operational convention on the seq_reformat 0-9 display scale. Chang et al 2014 do not prescribe an integer 5/7 cutoff -- on BAliBASE 3 and PREFAB 4 structural benchmarks they keep residues scoring above ~0.6 on the native 0-1 scale and drop columns scoring below 2, with TCS outperforming GUIDANCE and HoT. TCS-from-mcoffee gives substantially better column-confidence ranking than TCS-from-default-tcoffee because the library is more diverse. For the PAML branch-site test, Fletcher & Yang 2010 showed alignment errors inflate false positives dramatically (up to ~0.99 with ClustalW, ~0.13 even with codon-aware PRANK) and that removing gappy columns did not reduce them; confidence-based column masking (TCS, GUIDANCE2) is a common mitigation but was not evaluated in that study, since TCS postdates it (Chang et al 2014).

## MACSE Frameshift Markers Need Post-Processing

MACSE encodes detected frameshifts as `!` (within-codon insertion) and `*` (premature stop) in the nucleotide output. PAML codeml does not accept `!`: codeml 4.10.10 stops with "Error in sequence data file" (and still exits 0), so replace `!` before every codeml run; HyPhy `BUSTED`/`MEME` interpret `!` as `N` but `*` triggers a parse error mid-sequence. Standard cleanup before downstream analysis:

**Goal:** Convert MACSE frameshift and stop markers into formats that PAML and HyPhy will parse correctly.

**Approach:** Replace `!` with gaps for PAML, and use MACSE's own `exportAlignment` sub-program to replace both frameshift codons and internal stops for HyPhy-safe output.

```bash
# Convert frameshift markers to gaps (PAML)
sed -e '/^>/!s/!/-/g' aligned_nt.fasta > aligned_paml.fasta
# Replace frameshift codons and internal stops (HyPhy); checked on MACSE 2.07
java -jar macse_v2.jar -prog exportAlignment -align aligned_nt.fasta \
    -codonForFinalStop --- -codonForInternalStop NNN \
    -codonForInternalFS --- -charForRemainingFS - \
    -out_NT aligned_hyphy.fasta -out_AA aligned_hyphy_aa.fasta
```

`-codonForInternalStop NNN` replaces internal stops with `NNN`; `-codonForInternalFS ---` and `-charForRemainingFS -` remove the `!` frameshift markers, which `exportAlignment` otherwise leaves in place. Without this step, the dN/dS run silently produces results that do not correspond to the alignment shown.

## Aggressiveness Cap

For gap- and entropy-based modes, compute the retained-column fraction and apply the 20%/40% rule above: warn if retention drops below 0.6 (more than 40% removed).

```python
def trimming_fraction(input_alignment, trimmed_alignment):
    return trimmed_alignment.get_alignment_length() / input_alignment.get_alignment_length()
```

If retention drops below 0.6, switch to a less aggressive setting or accept the original alignment unfiltered. For ClipKIT `kpic*`/`kpi*` modes the fraction is not informative (they remove singleton columns by design); compare the trimmed tree's topology and branch lengths with the untrimmed tree instead.

## Column Mapping for Reproducibility

When trimming for phylogenetic input, retain the column-index mapping so downstream site-specific analyses (selection per site, structure-mapped residues, etc.) can be back-traced:

```bash
trimal -in input.fasta -out trimmed.fasta -automated1 -colnumbering > kept_columns.txt

clipkit input.fasta -m smart-gap --log -o trimmed.fasta
```

These two flags emit different formats (checked on trimAl 1.4.1 and ClipKIT 2.14.0). `trimal -colnumbering` prints one line on stdout: `#ColumnsMap`, a tab, then a comma-separated list of the 0-based original column indices that survived (`#ColumnsMap	0, 1, 2, 4, ...`). `clipkit --log` writes `<output>.log` with one space-separated row per original column: 1-based position, `keep`/`trim`, site class (`constant`, `parsimony-informative`, `singleton`, `other`), gap fraction (e.g. `1 keep constant 0.0`). Parse both into the same 0-based kept-column list:

```python
kept_trimal = [int(x) for x in open('kept_columns.txt').read().split('\t', 1)[1].split(',')]
kept_clipkit = [int(row.split()[0]) - 1 for row in open('trimmed.fasta.log') if row.split()[1] == 'keep']
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| ClipKIT empty output | All columns failed `kpic` filter | Switch to `smart-gap` mode (less aggressive); check input for non-amino-acid characters |
| trimAl "all sequences are identical" | Input has duplicates with no variation | Remove duplicate sequences first |
| BMGE Java OutOfMemoryError | Default JVM heap too small | `java -Xmx16g -jar BMGE.jar` |
| Divvier crashes on large input | Memory limits | Run on per-gene alignments rather than concatenated supermatrices |
| HMMcleaner reports "no contamination" | Input alignment too small (< 5 sequences) | Pool more sequences or skip per-residue cleaning |
| Trimming removes 80%+ of columns | Mode too aggressive for divergent input | Switch to `smart-gap`, raise the BMGE entropy threshold, or skip trimming (`kpic-gappy` is no less aggressive than `kpic-smart-gap`) |
| BMGE exits 0, prints usage, writes no file | BMGE 1.12 flags (`-h`, `-t DNA`) on BMGE 2.0 | Use `-e` and `-t NT`/`CO` on 2.0; check the output with `test -s` |
| IQ-TREE "Too large site ID" after trimming | Concatenated matrix trimmed; charsets still use untrimmed coordinates | Trim each locus, then concatenate and rebuild charsets |
| codeml "Error in sequence data file" on MACSE output | `!` frameshift characters left in the alignment | Replace `!` (sed, or MACSE `exportAlignment -codonForInternalFS ---`) |

## Related Skills

- alignment/multiple-alignment - Generate the input MSA before trimming; confidence assessment (GUIDANCE2, TCS, MUSCLE5 ensemble) for selection-analysis input
- alignment/msa-parsing - Parse the trimmed alignment; sequence weighting; coordinate mapping
- alignment/msa-statistics - Compute conservation and gap statistics to inform mode selection
- alignment/structural-alignment - Trim structural MSAs the same way as sequence MSAs
- phylogenetics/modern-tree-inference - Build trees from trimmed alignments

## References

- Steenwyk JL, Buida TJ, Li Y, Shen XX, Rokas A. 2020. ClipKIT: a multiple sequence alignment trimming software for accurate phylogenomic inference. PLOS Bio 18:e3001007.
- Capella-Gutierrez S, Silla-Martinez JM, Gabaldon T. 2009. trimAl: a tool for automated alignment trimming in large-scale phylogenetic analyses. Bioinf 25:1972-1973.
- Criscuolo A, Gribaldo S. 2010. BMGE: a new software for selection of phylogenetic informative regions from multiple sequence alignments. BMC Evol Biol 10:210.
- Maddison WP. 2024. PhyIN: trimming alignments by phylogenetic incompatibilities among neighbouring sites. PeerJ 12:e18504.
- Tan G, Muffato M, Ledergerber C, Herrero J, Goldman N, Gil M, Dessimoz C. 2015. Current methods for automated filtering of multiple sequence alignments frequently worsen single-gene phylogenetic inference. Syst Biol 64:778-791.
- Fletcher W, Yang Z. 2010. The effect of insertions, deletions, and alignment errors on the branch-site test of positive selection. MBE 27:2257-2267.
- Chang JM, Di Tommaso P, Notredame C. 2014. TCS: a new multiple sequence alignment reliability measure. MBE 31:1625-1637.
