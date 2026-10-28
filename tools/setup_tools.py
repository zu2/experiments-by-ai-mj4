#!/usr/bin/env python3
"""Build the bundled MC6800 assembler/linker offline; only host cc is needed."""
from pathlib import Path
import argparse, hashlib, json, os, shlex, shutil, subprocess
ROOT=Path(__file__).resolve().parent.parent

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',required=True,type=Path,help='Private directory for host executables')
    p.add_argument('--cc',default=os.environ.get('CC','cc'))
    a=p.parse_args();dst=a.output.resolve();dst.mkdir(parents=True,exist_ok=True)
    src=ROOT/'vendor/bintools'
    names=['as.h','obj.h','ld.h','ar.h','as0.c','as2.c','as3.c','as4.c','as1-6800.c','as6-6800.c','ld.c']
    digest=hashlib.sha256(b''.join((src/n).read_bytes() for n in names)).hexdigest()
    manifest=dst/'tools.json'
    expected={'source_sha256':digest,'compiler':a.cc}
    if manifest.exists() and json.loads(manifest.read_text())==expected and all(os.access(dst/n,os.X_OK) for n in ['as6800','ld6800']):
        print(dst);return
    cc=shlex.split(a.cc)
    if not cc or not shutil.which(cc[0]):raise SystemExit('A host C compiler (cc/gcc/clang) is required.')
    common=cc+['-O2','-Wall','-pedantic','-I',str(src)]
    for name,extra,sources in [
        ('as6800',['-DTARGET_6800'],['as0.c','as2.c','as3.c','as4.c','as1-6800.c','as6-6800.c']),
        ('ld6800',[],['ld.c'])]:
        temp=dst/(name+'.building')
        subprocess.run(common+extra+['-o',str(temp)]+[str(src/n) for n in sources],check=True,timeout=180)
        temp.replace(dst/name)
    manifest.write_text(json.dumps(expected,indent=2)+'\n')
    print(dst)
if __name__=='__main__':main()
