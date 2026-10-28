"""Check the saved reference with an independent exhaustive set/taatsu search.
The native implementation enumerates complete sets and greedily matches taatsu;
this oracle explicitly explores pairs, adjacent tiles and gapped tiles.
"""
from pathlib import Path
from functools import lru_cache

@lru_cache(maxsize=200000)
def search(c,m,t,h):
    i=next((i for i,v in enumerate(c) if v),34)
    if i==34:return 8-2*m-h-min(t,4-m)
    best=8
    def take(indices,mm,tt,hh):
        nonlocal best
        a=list(c)
        for k in indices:a[k]-=1
        best=min(best,search(tuple(a),mm,tt,hh))
    # Ignore this kind, or use it in every possible complete/incomplete set.
    take([i]*c[i],m,t,h)
    if m<4:
        if c[i]>=3:take([i]*3,m+1,t,h)
        if i<27 and i%9<7 and c[i+1] and c[i+2]:take([i,i+1,i+2],m+1,t,h)
    if c[i]>=2 and not h:take([i,i],m,t,1)
    if m+t<4:
        if c[i]>=2:take([i,i],m,t+1,h)
        if i<27:
            if i%9<8 and c[i+1]:take([i,i+1],m,t+1,h)
            if i%9<7 and c[i+2]:take([i,i+2],m,t+1,h)
    return best

def main():
    data=(Path(__file__).resolve().parents[1]/'test/shanten-reference.bin').read_bytes()
    assert len(data)==1024*36
    for offset in range(0,len(data),36):
        row=data[offset:offset+36]
        expected=int.from_bytes(row[35:36],signed=True)
        actual=search(tuple(row[:34]),row[34],0,0)
        assert actual==expected,(offset//36,actual,expected)
    print('PASS independent exhaustive shanten oracle: 1024 reference shapes.')
if __name__=='__main__':main()
