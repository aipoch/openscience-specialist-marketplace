'''Generate a bootstrap consensus tree from an alignment with rooted replicates.

majority_consensus counts ROOTED clades, and every NJ replicate is rooted arbitrarily, so
feeding unrooted replicates (bootstrap_consensus with an NJ constructor) splits each clade's
count with its complement and deflates support. Root every replicate on the same outgroup first.'''
# Reference: biopython 1.83+ | Verify API if version differs

import random
from Bio import Phylo
from Bio.Phylo.TreeConstruction import DistanceCalculator, DistanceTreeConstructor
from Bio.Phylo.Consensus import bootstrap_trees, majority_consensus
from Bio.Align import MultipleSeqAlignment
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

random.seed(42)   # bootstrap resampling uses the random module

sequences = [
    SeqRecord(Seq('ATGCATGCATGCATGC'), id='Human'),
    SeqRecord(Seq('ATGCATGCATGAATGC'), id='Chimp'),
    SeqRecord(Seq('ATGCATGAATGCATGC'), id='Gorilla'),
    SeqRecord(Seq('ATGAATGCATGCATGC'), id='Mouse'),
    SeqRecord(Seq('ATGAATGAATGCATGC'), id='Rat'),
]
alignment = MultipleSeqAlignment(sequences)

calculator = DistanceCalculator('identity')   # identity-only p-distance; ape dist.dna needed for model correction
constructor = DistanceTreeConstructor(calculator, 'nj')

print('Building 50 bootstrap replicates, each rooted on Rat...')
replicates = []
for rep in bootstrap_trees(alignment, 50, constructor):
    rep.root_with_outgroup({'name': 'Rat'})
    replicates.append(rep)
consensus_tree = majority_consensus(replicates, cutoff=0.5)
consensus_tree.ladderize()

print('\nMajority Rule Consensus Tree:')
Phylo.draw_ascii(consensus_tree)
for clade in consensus_tree.get_nonterminals():
    if clade.confidence is not None:
        print(f'{sorted(t.name for t in clade.get_terminals())}: {clade.confidence:.0f}%')

# Support is % of replicates: <50 weak, 50-70 moderate, 70-90 good, >90 strong.
# Caveat: support is sampling PRECISION, not accuracy -- a bias in the distances reproduces every replicate.
