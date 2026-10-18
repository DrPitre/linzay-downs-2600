#!/usr/bin/env python3
"""Verify cartridge layout and RAM/stack headroom from the real build."""
from pathlib import Path
import re,struct,hashlib,json
root=Path(__file__).resolve().parents[1]
rom=(root/'dist/linzay-downs-ntsc.bin').read_bytes()
syms={m[1]:int(m[2],16) for m in re.finditer(r'^(\w+)\s+([0-9a-fA-F]{4})\s', (root/'dist/linzay-downs.sym').read_text(),re.M)}
assert len(rom)==4096
assert struct.unpack('<HHH',rom[-6:])==(syms['Reset'],)*3
assert 0x80<syms['RAMEnd']<=0xc0, 'Leave at least 64 bytes for stack/headroom'
assert rom[:2]==bytes([0x78,0xd8]), 'SEI / CLD reset sequence'
info={'bytes':len(rom),'mapper':'standard 4K, no bankswitching','tv':'NTSC',
      'ram_variables':syms['RAMEnd']-0x80,'sha256':hashlib.sha256(rom).hexdigest(),
      'physical_hardware_tested':False}
(root/'dist/rom-info.json').write_text(json.dumps(info,indent=2)+'\n')
print('PASS: 4K ROM, reset vectors, reset instructions and RAM/stack headroom')
