"""Static control-flow audit of the linked source; no indirect game calls exist.
Unreachable labels are review candidates, never automatic deletion candidates.
"""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
lines=[];labels={}
for raw in (root/'build/all.s').read_text().splitlines():
    raw=raw.split(';',1)[0].strip()
    if not raw:continue
    m=re.match(r'^(\w+):',raw)
    if m:
        labels[m[1]]=len(lines)
        raw=raw[m.end():].strip()
        if not raw:continue
    lines.append(raw)
conditional={p+c for p in ('b','j') for c in ('eq','ne','cs','cc','hi','ls','ge','gt','le','lt','mi','pl','vc','vs','hs','lo')}
seen=set();pending=[labels['start']]
while pending:
    i=pending.pop()
    if i in seen or i>=len(lines):continue
    seen.add(i);parts=lines[i].split();op=parts[0].lower()
    if op in {'.byte','.word','.ds'}:continue
    if op in {'jmp','bra','jsr','bsr'}|conditional:
        target=parts[1]
        if target in labels:pending.append(labels[target])
        else:raise ValueError('unresolved transfer '+lines[i])
        if op in {'jmp','bra'}:continue
    if op not in {'rts','rti'}:pending.append(i+1)
ignored={'.byte','.word','.ds','.export','.equ','.bss','.code'}
candidates=[]
for label,i in labels.items():
    if label.startswith('zzp') or i>=len(lines) or i in seen:continue
    op=lines[i].split()[0].lower()
    if op not in ignored and not op.startswith('.'):candidates.append(label)
print('Static flow: %d reached source instructions/directives; %d unreachable code labels.'%(len(seen),len(candidates)))
for label in candidates:print(label,lines[labels[label]])
