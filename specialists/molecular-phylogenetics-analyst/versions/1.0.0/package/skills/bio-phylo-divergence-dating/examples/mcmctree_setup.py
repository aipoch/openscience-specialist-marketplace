'''Generate MCMCTree control files and calibrated tree files for divergence-time estimation.

A divergence date is mostly a product of the calibration prior, so this helper builds
the prior-only (usedata = 0), gradient/Hessian (usedata = 3) and approximate-likelihood
(usedata = 2 in.BV) runs, each in its own subdirectory so mcmc.txt / FigTree.tre are not
overwritten, and encodes every fossil as a soft-bounded MINIMUM, never a point.

Usage:
  python mcmctree_setup.py                      # demo: write control files to a temp dir
  python mcmctree_setup.py aln.phy calibrated.tre   # run prior -> bv -> post (mcmctree on PATH)
calibrated.tre must start with an 'ntaxa 1' header line (see write_tree_file).
'''
# Reference: PAML/MCMCTree 4.10.10 | Verify control-file syntax if version differs

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def write_control_file(outpath, seqfile, treefile, outfile='out.txt', mcmcfile='mcmc.txt',
                       ndata=1, usedata='2 in.BV', clock=2, model=4, alpha=0.5,
                       ncatg=4, cleandata=0, bdparas='1 1 0.1 m', root_age='<1.0',
                       rgene_gamma='2 20 1', sigma2_gamma='1 10 1',
                       burnin=50000, sampfreq=50, nsample=20000, seed=1234):
    '''Write an MCMCTree .ctl file.

    usedata: 0 = prior only (effective prior), 1 = exact likelihood, 3 = write out.BV,
    '2 in.BV' = approximate likelihood (PAML 4.10 needs the file name after the 2).
    clock: 1 = strict, 2 = independent rates, 3 = autocorrelated rates.
    model: 0 = JC69, 4 = HKY85, 7 = REV (GTR). RootAge is mandatory unless the root is calibrated.
    bdparas: PAML 4.10 requires a trailing flag, m (multiplicative) or c (conditional).
    '''
    lines = [
        f'seed = {seed}',
        f'seqfile = {seqfile}',
        f'treefile = {treefile}',
        f'mcmcfile = {mcmcfile}',
        f'outfile = {outfile}',
        '',
        f'ndata = {ndata}',
        f'usedata = {usedata}',
        f'clock = {clock}',
        f'RootAge = {root_age}',
        '',
        f'model = {model}',
        f'alpha = {alpha}',
        f'ncatG = {ncatg}',
        f'cleandata = {cleandata}',
        '',
        f'BDparas = {bdparas}',
        'kappa_gamma = 6 2',
        'alpha_gamma = 1 1',
        f'rgene_gamma = {rgene_gamma}',
        f'sigma2_gamma = {sigma2_gamma}',
        '',
        'print = 1',
        f'burnin = {burnin}',
        f'sampfreq = {sampfreq}',
        f'nsample = {nsample}',
    ]
    Path(outpath).write_text('\n'.join(lines) + '\n')
    return outpath


def format_calibration(cal_type, *args):
    '''Format one MCMCTree calibration string in B()/L()/U() notation.

    B(tL, tU, pL, pU) soft lower and upper bounds; L(tL, p, c, pL) minimum with Cauchy tail;
    U(tU, pU) maximum only. Times are in units of 100 Myr by convention (0.6 = 60 Ma).
    pL = pU = 0.025 is the canonical soft tail.
    '''
    params = ', '.join(str(a) for a in args)
    return f'{cal_type}({params})'


def build_calibrated_tree(newick, calibrations):
    '''Replace internal-node labels (written right after ')') with quoted calibration strings.'''
    result = newick
    for label, cal_str in calibrations.items():
        result = re.sub(r'\)' + re.escape(label) + r'(?=[,);:])', f")'{cal_str}'", result)
    return result


def write_tree_file(path, calibrated_newick, ntaxa):
    '''MCMCTree tree files need an "ntaxa ntree" header line before the Newick string.'''
    Path(path).write_text(f'{ntaxa} 1\n{calibrated_newick}\n')
    return path


def generate_prior_and_posterior_configs(seqfile, treefile, outdir, **ctl_options):
    '''Write prior/ (usedata = 0), bv/ (usedata = 3) and post/ (usedata = 2 in.BV) run directories.

    Comparing the prior-only effective prior to the posterior on each calibrated node is the
    single most important interpretation step; a posterior that matches the prior is uninformed.
    '''
    runs = {'prior': 0, 'bv': 3, 'post': '2 in.BV'}
    dirs = {}
    for name, usedata in runs.items():
        rundir = os.path.join(outdir, name)
        os.makedirs(rundir, exist_ok=True)
        shutil.copy(seqfile, os.path.join(rundir, os.path.basename(seqfile)))
        shutil.copy(treefile, os.path.join(rundir, os.path.basename(treefile)))
        write_control_file(os.path.join(rundir, 'mcmctree.ctl'), os.path.basename(seqfile),
                           os.path.basename(treefile), usedata=usedata, **ctl_options)
        dirs[name] = rundir
    return dirs


def run_mcmctree(rundir):
    subprocess.run(['mcmctree', 'mcmctree.ctl'], cwd=rundir, check=True, input='\n', text=True)


def run_pipeline(dirs):
    '''prior -> bv -> copy out.BV to post/in.BV -> post.'''
    run_mcmctree(dirs['prior'])
    run_mcmctree(dirs['bv'])
    bv = os.path.join(dirs['bv'], 'out.BV')
    if not os.path.getsize(bv):
        raise RuntimeError(f'{bv} is empty; check the usedata = 3 run')
    shutil.copy(bv, os.path.join(dirs['post'], 'in.BV'))
    run_mcmctree(dirs['post'])


if __name__ == '__main__':
    if len(sys.argv) == 3:
        outdir = tempfile.mkdtemp(prefix='mcmctree_run_')
        dirs = generate_prior_and_posterior_configs(sys.argv[1], sys.argv[2], outdir)
        run_pipeline(dirs)
        print(f'runs finished under {outdir}: compare prior/out.txt with post/out.txt node by node')
    else:
        outdir = tempfile.mkdtemp(prefix='mcmctree_demo_')
        tree = '((((human,chimp)human_chimp,gorilla)ape_root,mouse),rat);'
        calibrations = {'human_chimp': format_calibration('B', 0.06, 0.08, 0.025, 0.025),
                        'ape_root': format_calibration('L', 0.12, 0.05, 1.0, 0.025)}
        calibrated = build_calibrated_tree(tree, calibrations)
        treefile = write_tree_file(os.path.join(outdir, 'calibrated_tree.tre'), calibrated, tree.count(',') + 1)
        Path(outdir, 'alignment.phy').touch()  # placeholder; supply a real PHYLIP alignment
        dirs = generate_prior_and_posterior_configs(os.path.join(outdir, 'alignment.phy'), treefile, outdir)
        print(f'calibrated tree file: {treefile}')
        for name, rundir in dirs.items():
            print(f'{name} run directory: {rundir}')
