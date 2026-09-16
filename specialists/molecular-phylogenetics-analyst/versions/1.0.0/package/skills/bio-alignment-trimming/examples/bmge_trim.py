'''Trim alignment with BMGE (entropy + substitution-matrix context).

BMGE (Criscuolo & Gribaldo 2010 BMC Evol Biol) is widely used in prokaryotic phylogenomics
(e.g. GToTree). BMGE 1.12 and 2.0 use different flags: 1.12 takes the entropy threshold as
-h and types AA/CODON/DNA; 2.0 takes -e and AA/CO/NT, and prints help for -h (exit 0, no
output). Lower entropy thresholds trim much harder, so check retention and compare trees.
'''
# Reference: BMGE 1.12 and 2.0 | Verify CLI flags if version differs

import os
import subprocess
from Bio import AlignIO

TYPES_V2 = {'AA': 'AA', 'DNA': 'NT', 'CODON': 'CO'}


def run_bmge(input_fasta, output_fasta, sequence_type='AA', entropy=0.5, gap_threshold=0.2,
             matrix=None, jar='BMGE.jar', version='1.12'):
    '''sequence_type uses 1.12 names (AA, DNA, CODON); they are translated for BMGE 2.0.'''
    cmd = ['java', '-Xmx8g', '-jar', jar, '-i', input_fasta, '-g', str(gap_threshold)]
    if version.startswith('2'):
        cmd += ['-t', TYPES_V2[sequence_type], '-e', str(entropy), '-o', output_fasta]
    else:
        cmd += ['-t', sequence_type, '-h', str(entropy), '-of', output_fasta]
    if matrix:
        cmd += ['-m', matrix]
    subprocess.run(cmd, check=True)
    if not os.path.exists(output_fasta) or os.path.getsize(output_fasta) == 0:
        raise RuntimeError(f'BMGE wrote no alignment to {output_fasta}; check flags for BMGE {version}')


def trimming_summary(input_fasta, output_fasta):
    original = AlignIO.read(input_fasta, 'fasta')
    trimmed = AlignIO.read(output_fasta, 'fasta')
    return {
        'original': original.get_alignment_length(),
        'trimmed': trimmed.get_alignment_length(),
        'retention': trimmed.get_alignment_length() / original.get_alignment_length(),
    }


if __name__ == '__main__':
    version = '1.12'   # set to '2.0' for BMGE 2.0
    for entropy, label in ((0.5, 'default entropy threshold'), (0.6, 'more permissive')):
        out = f'trimmed_e{entropy}.fasta'
        run_bmge('input.fasta', out, sequence_type='AA', entropy=entropy, gap_threshold=0.2, version=version)
        s = trimming_summary('input.fasta', out)
        print(f'BMGE {version} entropy {entropy} -g 0.2 ({label}):')
        print(f'  {s["original"]} -> {s["trimmed"]} columns ({s["retention"]*100:.1f}% retained)')
        if s['retention'] < 0.6:
            print('  WARNING: more than 40% of columns removed; raise the entropy threshold or skip trimming')
