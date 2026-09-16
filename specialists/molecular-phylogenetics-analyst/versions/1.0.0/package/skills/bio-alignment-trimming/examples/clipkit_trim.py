'''Trim alignment with ClipKIT and compute retention metrics.

ClipKIT modes (Steenwyk et al 2020 PLOS Bio; `clipkit --help` lists all 15):
- smart-gap (default): dynamic gap-fraction threshold; keeps singleton and constant sites
- gappy: fixed gap threshold (-g 0.9 default)
- kpic-smart-gap: keep parsimony-informative + constant sites, then smart-gap; drops every
  singleton column, so it removes a large fraction by design and can distort outgroup
  branch lengths on unbalanced taxon sampling (topology-focused use only)
- kpi / kpi-smart-gap: parsimony-informative sites only; inflates ML branch lengths
'''
# Reference: clipkit 2.14.0 | Verify CLI flags if version differs

import subprocess
from Bio import AlignIO

GAP_BASED_MODES = {'smart-gap', 'gappy', 'gappyout', 'block-gappy'}


def run_clipkit(input_fasta, output_fasta, mode='smart-gap', gap_threshold=None, log=True):
    cmd = ['clipkit', input_fasta, '-m', mode, '-o', output_fasta]
    if gap_threshold is not None:
        cmd += ['-g', str(gap_threshold)]
    if log:
        cmd += ['--log']
    subprocess.run(cmd, check=True)


def trimming_summary(input_fasta, output_fasta):
    original = AlignIO.read(input_fasta, 'fasta')
    trimmed = AlignIO.read(output_fasta, 'fasta')
    retention = trimmed.get_alignment_length() / original.get_alignment_length()
    return {
        'original_columns': original.get_alignment_length(),
        'trimmed_columns': trimmed.get_alignment_length(),
        'retention': retention,
        'removed': original.get_alignment_length() - trimmed.get_alignment_length(),
    }


if __name__ == '__main__':
    mode = 'smart-gap'
    run_clipkit('input.fasta', 'trimmed.fasta', mode=mode)
    summary = trimming_summary('input.fasta', 'trimmed.fasta')

    print(f'Mode:              {mode}')
    print(f'Original columns:  {summary["original_columns"]}')
    print(f'Trimmed columns:   {summary["trimmed_columns"]}')
    print(f'Retention:         {summary["retention"]*100:.1f}%')

    if mode in GAP_BASED_MODES:
        if summary['retention'] < 0.6:
            print('\nWARNING: more than 40% of columns removed by gap-based trimming; too aggressive for this')
            print('alignment. Use a less aggressive setting or the untrimmed alignment, and compare trees.')
    else:
        print('\nNote: kpi/kpic modes drop singleton (kpi: also constant) columns by design, so retention is not')
        print('a quality measure. Compare topology and branch lengths (especially outgroup/stem) against a tree')
        print('from the untrimmed alignment before using this output.')
