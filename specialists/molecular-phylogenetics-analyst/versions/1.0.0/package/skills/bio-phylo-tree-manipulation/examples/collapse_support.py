'''Collapse low-support branches into SOFT (uncertainty) polytomies.

Bio.Phylo parses a single-number internal-node label into clade.confidence, but keeps an
IQ-TREE -B + --alrt label such as '90.3/92' (SH-aLRT/UFBoot) whole in clade.name with
confidence None -- a collapse that reads only .confidence then silently does nothing.
Collapsing below a support cutoff produces soft polytomies meaning 'order unresolved'
-- NOT hard polytomies meaning 'simultaneous radiation'. The cutoff depends on the
support scale: 70 for standard bootstrap, 95 for UFBoot2 (different scales).
'''
# Reference: biopython 1.83+ | Verify API if version differs

from Bio import Phylo
from io import StringIO


def support(clade):
    if clade.confidence is not None:
        return clade.confidence
    if clade.name and '/' in clade.name:
        return float(clade.name.split('/')[-1])   # last field = UFBoot
    return None


def collapse(tree_string, cutoff, label):
    tree = Phylo.read(StringIO(tree_string), 'newick')
    print(f'{label}: (confidence, name) per internal node:',
          [(c.confidence, c.name) for c in tree.get_nonterminals()])
    assert any(support(c) is not None for c in tree.get_nonterminals()), 'no readable support'
    tree.collapse_all(lambda c: support(c) is not None and support(c) < cutoff)
    print(f'After collapsing support < {cutoff} (soft polytomy = unresolved):')
    Phylo.draw_ascii(tree)


# Standard bootstrap after the closing paren: (A,B)40
collapse('(((Human:0.1,Chimp:0.1)40:0.2,Gorilla:0.3)95:0.4,Orangutan:0.5);', 70, 'bootstrap')

# IQ-TREE dual labels: SH-aLRT/UFBoot, collapse on UFBoot < 95
collapse('(((Human:0.1,Chimp:0.1)90.3/92:0.2,Gorilla:0.3)99.8/100:0.4,Orangutan:0.5);', 95, 'SH-aLRT/UFBoot')
