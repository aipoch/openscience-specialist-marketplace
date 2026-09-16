'''Show that converting an annotated Nexus tree with Bio.Phylo corrupts its [&...] annotations.

Bio.Phylo keeps a BEAST-style [&...] block from a Nexus file as opaque .comment text and writes
it to Newick escaped as [\\[&...\\]], which DendroPy (and treeio) can no longer parse. The script
counts DendroPy-readable posteriors before and after Phylo.convert, writing to a temp dir.'''
# Reference: BioPython 1.83+, DendroPy 5+ | Verify API if version differs

import os
import tempfile
from Bio import Phylo
import dendropy

annotated_nexus = '''#NEXUS
begin trees;
tree MCC = [&R] ((A:0.1,B:0.2)[&posterior=0.97]:0.3,(C:0.4,D:0.5)[&posterior=0.62]:0.6);
end;
'''

out = tempfile.mkdtemp(prefix='treeio_')
src = os.path.join(out, 'annotated.nex')
dst = os.path.join(out, 'converted.nwk')
with open(src, 'w', encoding='utf-8') as fh:
    fh.write(annotated_nexus)


def readable_posteriors(path, schema):
    tree = dendropy.Tree.get(path=path, schema=schema, extract_comment_metadata=True)
    return sum(node.annotations.get_value('posterior') is not None for node in tree)


Phylo.convert(src, 'nexus', dst, 'newick')
with open(dst, encoding='utf-8') as fh:
    print('Bio.Phylo Newick:', fh.read().strip())
print(f'DendroPy-readable posteriors: before={readable_posteriors(src, "nexus")}, '
      f'after={readable_posteriors(dst, "newick")}')
print('Extract annotations with DendroPy/treeio BEFORE any Bio.Phylo conversion.')
