'''Draw a tree with tip labels and support labeled by its measure, export to temp SVG.

Single-number labels parse into clade.confidence. IQ-TREE -B + --alrt labels such as
'88/97' (SH-aLRT/UFBoot) stay in clade.name with confidence None, so they are split here;
a recipe that reads only .confidence would draw no support at all.'''
# Reference: biopython 1.83+, matplotlib 3.8+ | Verify API if version differs

import os
import re
import tempfile
from io import StringIO
from Bio import Phylo
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

tree_string = '((A:0.15,B:0.22)88/97:0.08,(C:0.35,D:0.41)71.5/90:0.12,E:0.3);'   # IQ-TREE SH-aLRT/UFBoot labels
tree = Phylo.read(StringIO(tree_string), 'newick')
tree.ladderize()

for clade in tree.get_nonterminals():
    if clade.confidence is None and clade.name and re.fullmatch(r'[\d.]+/[\d.]+', clade.name):
        clade.sh_alrt, clade.ufboot = (float(v) for v in clade.name.split('/'))
        clade.name = None


def tip_only(clade):
    return clade.name if clade.is_terminal() else ''


def support_label(clade):
    # the measure MUST be named in the caption; bare integers default-read as bootstrap and over-read other scales
    if clade.is_terminal():
        return ''
    if getattr(clade, 'ufboot', None) is not None:
        return f'{clade.sh_alrt:.0f}/{clade.ufboot:.0f}'
    return f'{clade.confidence:.0f}' if clade.confidence is not None else ''


labels = [support_label(c) for c in tree.get_nonterminals() if support_label(c)]
if not labels:
    print('WARNING: no internal clade has readable support')
print('Support labels drawn:', labels)

fig, ax = plt.subplots(figsize=(10, 6))
Phylo.draw(tree, axes=ax, do_show=False, label_func=tip_only, branch_labels=support_label)
ax.set_title('Node support: SH-aLRT (%) / UFBoot (%)')

out_dir = tempfile.mkdtemp(prefix='tree_viz_')
out_path = os.path.join(out_dir, 'labeled_tree.svg')   # vector for publication
fig.savefig(out_path, bbox_inches='tight')
plt.close(fig)
print('Saved to', out_path)
