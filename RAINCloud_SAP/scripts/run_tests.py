# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
"""Run from any directory with Icarus or --simulator questa --bin <Questa bin>.
Uses only the standard library. Never silently treats missing simulation as PASS.
"""
from pathlib import Path
import argparse, os, shutil, subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--simulator', choices=['icarus', 'questa'], default='icarus')
parser.add_argument('--bin', type=Path, help='Directory containing simulator executables')
parser.add_argument('--license', type=Path,
                    help='Questa license file; sets SALT_LICENSE_SERVER for this run only')
args = parser.parse_args()
env = os.environ.copy()
if args.bin:
    env['PATH'] = str(args.bin.resolve()) + os.pathsep + env.get('PATH', '')
if args.license:
    if args.simulator != 'questa' or not args.license.is_file():
        parser.error('--license requires Questa and an existing license file')
    env['SALT_LICENSE_SERVER'] = str(args.license.resolve())
names = ['vlib', 'vmap', 'vlog', 'vsim'] if args.simulator == 'questa' else ['iverilog', 'vvp']
tools = {name: shutil.which(name, path=env.get('PATH')) for name in names}
if not all(tools.values()):
    raise SystemExit(f'{args.simulator} tools are required; use --bin. Tests NOT RUN.')
out = root/('build/questa' if args.simulator == 'questa' else 'build/sim')
out.mkdir(parents=True, exist_ok=True)
tops = ['tb_clock', 'tb_inputs', 'tb_alu', 'tb_output', 'tb_cpu']

def run(command, log_name, pass_marker=None, workdir=root):
    try:
        result = subprocess.run(command, cwd=workdir, env=env, capture_output=True,
                                text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired) as error:
        (out/log_name).write_text(f'BLOCKED: {error}\n', encoding='utf-8')
        raise SystemExit(f'{log_name}: BLOCKED: {error}')
    transcript = result.stdout+result.stderr
    (out/log_name).write_text(transcript, encoding='utf-8')
    print(transcript, end='')
    if result.returncode:
        raise SystemExit(f'{log_name}: FAILED ({result.returncode})')
    if pass_marker and pass_marker not in transcript:
        raise SystemExit(f'{log_name}: no explicit PASS; verification incomplete')

if args.simulator == 'questa':
    library = out/'work'
    if not library.exists():
        run([tools['vlib'], str(library)], 'vlib.log')
    # vopt requires a logical library name, not a Windows drive/path in -lib.
    # Keep the mapping local so the installation's modelsim.ini is untouched.
    ini = out/'modelsim.ini'
    if not ini.exists():
        run([tools['vmap'], '-c'], 'vmap-init.log', workdir=out)
    run([tools['vmap'], '-ini', ini.as_posix(), 'work', library.as_posix()], 'vmap.log')
    run([tools['vlog'], '-ini', ini.as_posix(), '-sv', '-timescale', '1ns/1ps', '-work', 'work',
         '-f', 'sim/sources.f'] + ['sim/'+top+'.sv' for top in tops], 'compile.log')
    batch = out/'regression.do'
    batch.write_text('onerror {quit -code 1}\nrun -all\nquit -code 0\n', encoding='utf-8')
    for top in tops:
        run([tools['vsim'], '-ini', ini.as_posix(), '-c', '-onfinish', 'stop', '-lib', 'work', top,
             '-l', (out/(top+'.transcript.log')).as_posix(),
             '-wlf', (out/(top+'.wlf')).as_posix(),
             '-do', 'do {'+batch.as_posix()+'}'],
            top+'.run.log', f'PASS {top}')
else:
    for top in tops:
        image = out/(top+'.vvp')
        run([tools['iverilog'], '-g2012', '-s', top, '-o', str(image),
             '-c', 'sim/sources.f', 'sim/'+top+'.sv'], top+'.compile.log')
        run([tools['vvp'], str(image)], top+'.run.log', f'PASS {top}')
print('PASS all regression tests')
