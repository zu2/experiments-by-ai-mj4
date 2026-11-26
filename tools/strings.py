#!/usr/bin/env python3
# usage: strings.py STRINGS OUT ASM...
# The title shows s_build: 4 digits from the sources, to tell the binaries apart.
from pathlib import Path
import sys,zlib
crc=0
for f in sorted(sys.argv[3:])+[sys.argv[1]]:crc=zlib.crc32(Path(f).read_bytes(),crc)
Path(sys.argv[2]).write_text(Path(sys.argv[1]).read_text()+f's_build\t{crc%10000:04d}\n')
