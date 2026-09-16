'''Root a tree, treating the root as a separate inference, not a display choice.

Outgroup rooting (multiple close taxa) is preferred and checks outgroup monophyly.
Inferred trees are arbitrarily rooted -- IQ-TREE writes (OutA,OutB,ingroup) -- so root on
an ingroup tip first, then test monophyly, then root on the outgroup stem with
outgroup_branch_length for a bifurcating root.
Midpoint rooting assumes a clock and is a clock-limited fallback. For deep trees
with rate variation, prefer outgroup-free MAD / MinVar CLIs (run on the Newick file).
'''
# Reference: biopython 1.83+ | Verify API if version differs

from Bio import Phylo
from io import StringIO

tree_string = '(OutA:0.5,OutB:0.6,(((Human:0.1,Chimp:0.2):0.3,Gorilla:0.4):0.2,Macaque:0.5):0.7);'   # IQ-TREE-style layout

tree = Phylo.read(StringIO(tree_string), 'newick')
print('Arbitrarily rooted input (as written by the inference program):')
Phylo.draw_ascii(tree)

outgroup = [{'name': 'OutA'}, {'name': 'OutB'}]
print('Naive monophyly test on the input:',
      bool(tree.is_monophyletic([tree.find_any(**o) for o in outgroup])))

tree.root_with_outgroup({'name': 'Human'})            # temporary root on an ingroup tip
if tree.is_monophyletic([tree.find_any(**o) for o in outgroup]):
    stem = tree.common_ancestor(*outgroup).branch_length
    tree.root_with_outgroup(*outgroup, outgroup_branch_length=stem / 2)
    print('\nRooted on the (OutA, OutB) stem; root children:',
          [sorted(t.name for t in c.get_terminals()) for c in tree.root.clades])
    Phylo.draw_ascii(tree)
else:
    print('\nOutgroup is not monophyletic: root placement is unreliable')

midpoint_tree = Phylo.read(StringIO(tree_string), 'newick')
midpoint_tree.root_at_midpoint()
print('\nMidpoint-rooted (clock assumption; a long branch can slide the root):')
Phylo.draw_ascii(midpoint_tree)
