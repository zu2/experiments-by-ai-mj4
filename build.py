#!/usr/bin/env python3
from pathlib import Path
import subprocess,os,re,json,sys
ROOT=Path(__file__).resolve().parent
os.chdir(ROOT)
TOOLS=Path(os.environ.get('BMJR_TOOLS',ROOT/'tools/bin'))
if not (TOOLS/'as6800').is_file() or not (TOOLS/'ld6800').is_file():
 subprocess.run(['python3','tools/setup_tools.py','--output',str(TOOLS)],check=True)
subprocess.run(['python3','tools/gen.py','strings.txt','data.s'],check=True)
speech='--no-speech' not in sys.argv
# With speech, PCM_BUF ($2100) holds one byte per sample below the BSS: at most
# $3300-$2100 = 4608 samples (riichi has 4040; tools/voice_pack.py checks the same limit); the stack
# stays above STACK_LIMIT.
BSS_SPEECH=0x3300
STACK_LIMIT=0x3c00
files=['directpage','main','turn','ai','ev','eval','shgen','score','sound','ui','settle','util','direct']
# Callers branch on N and Z after routines marked "N and Z set from A" without TSTA.
subprocess.run(['python3','tools/check_flags.py',*[f'src/{n}.asm' for n in files]],check=True)
s='\n'.join('\t.code\n'+(ROOT/'src'/f'{n}.asm').read_text() for n in files)+'\n\t.code\n'+Path('data.s').read_text()
if speech:
 subprocess.run(['python3','tools/voice_pack.py'],check=True)
 s=s.replace('play:\n', 'play:\n ldaa 0,x\n cmpa #$FF\n beq pcm_play\n',1)
 a=s.index('snd_pon:');b=s.index('\n\t.bss',a)
 s=s[:a]+s[b:]+'\n .code\n'+Path('src/speech.asm').read_text()+'\n .code\n'+Path('src/unpack.asm').read_text()+'\n .code\n'+Path('voice/packed.s').read_text()
# Tail calls preserve the caller return address and remove a redundant RTS.
s=re.sub(r'(?m)^([ \t]*)jsr[ \t]+([A-Za-z_][A-Za-z_0-9]*)[ \t]*\n[ \t]*rts[ \t]*$',r'\1jmp \2',s)
s+='\n .bss\nns_buf: .ds 5\n .code\n'
s=s.replace('bss_all_end:', '')+'\n .bss\nbss_all_end:\n .code\n'
# Begin with far conditional transfers; shorten resolved local targets below.
s=re.sub(r'(?m)^(\s*)b(eq|ne|cs|cc|hi|ls|ge|gt|le|lt|mi|pl|vc|vs)\s+',r'\1j\2\t',s)
s=re.sub(r'(?m)^(\s*)bra\s+',r'\1jmp\t',s)
longnames=sorted(set(re.findall(r'(?m)^([A-Za-z_][A-Za-z_0-9]{15,}):',s)))
renames={n:f'zz{i:04d}' for i,n in enumerate(longnames)}
for n,v in renames.items():s=re.sub(r'\b'+n+r'\b',v,s)
# Mark direct and conditional transfers before assembling. Only resolved addresses
# in range are shortened; shrinking code cannot increase their displacement.
transfers=[]
def mark_transfer(m):
 name=f'zzp{len(transfers):05d}'
 transfers.append((name,m[2],m[3]))
 return name+':\n'+m[0]
s=re.sub(r'(?m)^([ \t]*)(jmp|jsr|j(?:eq|ne|cs|cc|hi|ls|ge|gt|le|lt|mi|pl|vc|vs))[ \t]+([A-Za-z_][A-Za-z_0-9]*)[ \t]*$',mark_transfer,s)
names=re.findall(r'^([A-Za-z_][A-Za-z_0-9]*):',s,re.M)
s+='\n\t.code\n'+''.join('\t.export\t'+n+'\n' for n in names)
Path('build').mkdir(exist_ok=True)
def assemble(source):
 Path('build/all.s').write_text(source)
 subprocess.run([str(TOOLS/'as6800'),'all.s'],cwd='build',check=True)
 subprocess.run([str(TOOLS/'ld6800'),'-b','-C','0x4000',*(['-D',hex(BSS_SPEECH),'-B',hex(BSS_SPEECH)] if speech else []),'-m','mj4.map','-o','mj4.out','all.o'],cwd='build',check=True)
assemble(s)
# Re-evaluate direct transfers after each monotone shrinking pass.
# The assembler leaves far conditional pseudos intact, so handle them here too.
short={}
def shorten(m):
 return m[1]+':\n'+m[2]+short.get(m[1],m[3])+' '+m[4]
while True:
 positions={p[2]:int(p[0],16) for l in Path('build/mj4.map').read_text().splitlines() if len(p:=l.split())==3}
 added={name:('bra' if op=='jmp' else 'bsr' if op=='jsr' else 'b'+op[1:]) for name,op,target in transfers if name not in short and target in positions and -128<=positions[target]-positions[name]-2<=127}
 if not added:break
 short.update(added)
 s=re.sub(r'(?m)^(zzp[0-9]+):\n([ \t]*)(jmp|jsr|j(?:eq|ne|cs|cc|hi|ls|ge|gt|le|lt|mi|pl|vc|vs))[ \t]+([A-Za-z_][A-Za-z_0-9]*)[ \t]*$',shorten,s)
 assemble(s)
print('Short transfers:',len(short),'of',len(transfers),'; conditional:',sum(op.startswith('j') and op not in ('jmp','jsr') and name in short for name,op,target in transfers))
out=Path('build/mj4.out').read_bytes();assert out[:0x4000]==bytes(0x4000)
raw=out[0x4000:];assert len(raw)<=0x7000
Path('mj4.raw').write_bytes(raw)
lines=[]
for i in range(0,len(raw),16):
 addr=0x4000+i;b=bytes([len(raw[i:i+16])+3,addr>>8,addr&255])+raw[i:i+16]
 lines.append('S1'+b.hex().upper()+f'{(~sum(b))&255:02X}')
lines+=['S9034000BC'];Path('mj4.s19').write_text('\n'.join(lines)+'\n')
syms={p[2]:int(p[0],16) for l in Path('build/mj4.map').read_text().splitlines() if len(p:=l.split())==3}
for n,v in renames.items():
 if v in syms:syms[n]=syms[v]
assert (syms['gd_transitions'] & 255)+21 <= 256, 'greedy table crosses page'
assert syms['gd_smc_read0'] >= 0x4000, 'SMC must be in program RAM'
assert (syms['counts'] & 255)+38 < 256, 'counts crosses page'
assert syms['ac_yes']-syms['counts'] < 256, 'ac_yes-counts,x out of range'
assert syms['pai_suit_work']==syms['work']+4, 'flush scores must alias work+4..6'
assert 0<=syms['pai_suit0']-syms['pai_suit_work']<=255, 'flush physical-count offset out of range'
assert syms['bss_all_end']<=(STACK_LIMIT if speech else 0xb000), 'RAM overrun'
# Export absolute direct RAM symbols for the emulator harnesses as well.
directpage=json.loads(Path('directpage.json').read_text())
used=set()
for item in directpage:
 a=item['address'];size=item['bytes']
 assert 0x72<=a and a+size<=0xf2
 assert not (set(range(a,a+size)) & used)
 used.update(range(a,a+size));syms[item['name']]=a
syms['DP_FIRST']=0x72;syms['DP_END']=0xf2
Path('build/symbols.h').write_text(''.join(f'#define S_{n} 0x{v:04x}\n' for n,v in syms.items()))
Path('build/symbols.json').write_text(json.dumps(syms,indent=2))
print(f'MC6800 start=$4000, {len(raw)} bytes, end=${0x4000+len(raw)-1:04X}, BSS end=${syms["bss_all_end"]:04X}')
