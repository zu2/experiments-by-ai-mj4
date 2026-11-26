#!/usr/bin/env python3
# usage: post.py WORK OUT
# Reads WORK/mj4.out, mj4.map and mj4.lst from as6800 and ld6800, checks the
# placement, and writes OUT.raw, OUT.s19, WORK/symbols.h and WORK/symbols.json.
from pathlib import Path
import json,re,sys
work=Path(sys.argv[1]);out_name=sys.argv[2]
STACK_LIMIT=0x3c00
base={}
for line in (work/'mj4.map').read_text().splitlines():
 p=line.split()
 if len(p)==3:base[p[2]]=int(p[0],16)
segment={0:0,1:base['__code'],2:base['__data'],3:base['__bss']}
syms={}
for line in (work/'mj4.lst').read_text().splitlines():
 m=re.match(r'(\d+) ([0-9A-F]{4}) :.{25}([A-Za-z_]\w*):',line)
 if m:syms[m[3]]=segment[int(m[1])]+int(m[2],16)
out=(work/'mj4.out').read_bytes();assert out[:0x4000]==bytes(0x4000)
raw=out[0x4000:];assert len(raw)<=0x7000
assert (syms['gd_transitions'] & 255)+21 <= 256, 'greedy table crosses page'
assert syms['gd_smc_read0'] >= 0x4000, 'SMC must be in program RAM'
for name in ('counts', 'kattr', 'unseen'):
 assert (syms[name] & 255)+38 < 256, name + ' crosses page'
assert syms['voice_tree0']>>8==(syms['boot']-1)>>8 and syms['voice_tree0']&255>=32, 'voice trees cross a page'
assert syms['ac_yes']-syms['counts'] < 256, 'ac_yes-counts,x out of range'
assert syms['pai_suit_work']==syms['work']+4, 'flush scores must alias work+4..6'
assert 0<=syms['pai_suit0']-syms['pai_suit_work']<=255, 'flush physical-count offset out of range'
assert all(syms[n]>>8==(syms[n]+k-1)>>8 for n,k in (('ym_y',12),('cur_y',16))), 'fi_copy lists must stay within a page'
assert syms['bss_all_end']<=STACK_LIMIT, 'RAM overrun'
used=set()
for item in json.loads(Path('directpage.json').read_text()):
 a=item['address'];size=item['bytes']
 assert 0x72<=a and a+size<=0xf2
 assert not (set(range(a,a+size)) & used)
 used.update(range(a,a+size));syms[item['name']]=a
syms['DP_FIRST']=0x72;syms['DP_END']=0xf2
consts={}
for n,e in re.findall(r'(?m)^([A-Za-z_][A-Za-z_0-9]*)[ \t]+\.equ[ \t]+([^;\n]+?)[ \t]*$',Path('src/main.asm').read_text()):
 consts[n]=eval(re.sub(r'\b[A-Za-z_][A-Za-z_0-9]*',lambda m:str(consts[m[0]]),e.replace('$','0x')))
(work/'symbols.h').write_text(''.join(f'#define S_{n} 0x{v:04x}\n' for n,v in syms.items())+''.join(f'#define {n} {v}\n' for n,v in consts.items()))
(work/'symbols.json').write_text(json.dumps(syms,indent=2))
lines=[]
for i in range(0,len(raw),16):
 addr=0x4000+i;b=bytes([len(raw[i:i+16])+3,addr>>8,addr&255])+raw[i:i+16]
 lines.append('S1'+b.hex().upper()+f'{(~sum(b))&255:02X}')
lines.append('S9034000BC')
# Write the outputs last, so that make does not take a failed check as done.
Path(out_name+'.raw').write_bytes(raw);Path(out_name+'.s19').write_text('\n'.join(lines)+'\n')
print(f'MC6800 start=$4000, {len(raw)} bytes, end=${0x4000+len(raw)-1:04X}, BSS end=${syms["bss_all_end"]:04X}')
