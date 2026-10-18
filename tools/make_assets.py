#!/usr/bin/env python3
"""Generate original 3x5 TIA text and 16x16 galloping horse graphics."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
font={
'A':[2,5,7,5,5],'B':[6,5,6,5,6],'C':[3,4,4,4,3],'D':[6,5,5,5,6],
'E':[7,4,6,4,7],'F':[7,4,6,4,4],'G':[3,4,5,5,3],'H':[5,5,7,5,5],
'I':[7,2,2,2,7],'J':[1,1,1,5,2],'K':[5,5,6,5,5],'L':[4,4,4,4,7],
'M':[5,7,7,5,5],'N':[5,7,7,7,5],'O':[2,5,5,5,2],'P':[6,5,6,4,4],
'Q':[2,5,5,3,1],'R':[6,5,6,5,5],'S':[3,4,2,1,6],'T':[7,2,2,2,2],
'U':[5,5,5,5,7],'V':[5,5,5,5,2],'W':[5,5,7,7,5],'X':[5,5,2,5,5],
'Y':[5,5,2,2,2],'Z':[7,1,2,4,7],'-':[0,0,7,0,0],'!':[2,2,2,0,2],
':':[0,2,0,2,0],'1':[2,6,2,2,7],'2':[6,1,2,4,7],'3':[6,1,2,1,6],
'4':[5,5,7,1,1],' ':[0]*5}
lines=[('Linzay','LINZAY'),('Downs','DOWNS'),('Eunice','EUNICE LA'),
('Cecil','CECIL'),('Brown','BROWN'),('Leroy','LEROY'),('Pitre','PITRE'),
('Start','FIRE: RACE'),('Ready','GET READY'),('Run','FIRE:BOOST'),
('First','1ST PLACE'),('Second','2ND PLACE'),('Third','3RD PLACE'),('Fourth','4TH PLACE'),
('Cheer0','ALLEZ!'),('Cheer1','LACHE PAS!'),('Cheer2','MAIS OUI!'),('Cheer3','COURS!'),
('Cheer4','ASTEUR!'),('Cheer5','GO CHER!'),('Cheer6','TIENS BON!'),('Cheer7','AU RAS!'),
('Cheer8','VAS-Y!'),('Cheer9','MAIS CHER!'),('Cheer10','BRAVO!'),('Cheer11','TEE-BOY!')]
def pf(bits):
    return [sum(bits[i]<<(i+4) for i in range(4)),sum(bits[4+i]<<(7-i) for i in range(8)),sum(bits[12+i]<<i for i in range(8))]
def data(values): return '        byte '+','.join('$%02x'%v for v in values)+'\n'
out=['; Generated original art. Each text record is page-safe and 60 bytes.\n']
for i,(name,text) in enumerate(lines): out.append('TXT_'+name.upper()+' = '+str(i)+'\n')
out.append('        align 256\nTextLo\n');out.append('        byte '+','.join('<Text'+n for n,t in lines)+'\nTextHi\n');out.append('        byte '+','.join('>Text'+n for n,t in lines)+'\n')
for name,text in lines:
    assert len(text)<=10
    text=text.center(10); out.append('        align 64\nText'+name+'\n')
    for y in range(5):
        bits=[]
        for c in text: bits.extend([(font[c][y]>>i)&1 for i in (2,1,0)]+[0])
        row=pf(bits[:20])+pf(bits[20:]);out.append(data(row));out.append(data(row))
# Jockey and long-necked horse, followed by four distinct leg positions.
upper=[0x0100,0x0380,0x0180,0x03c0,0x07b0,0x0336,0x0fff,0x3ffe,0xfff8,0x5ff0,0x1fe0]
legs=[[0x14a0,0x2480,0x2248,0x624c,0x0000],[0x1240,0x0920,0x1160,0x3140,0],
      [0x1920,0x2480,0x4280,0x6300,0],[0x1520,0x2240,0x4440,0x66c0,0]]
poses=[upper+l for l in legs]
out.append('        align 256\nHorseLeft\n')
for pose in poses: out.append(data([v>>8 for v in pose]))
out.append('HorseRight\n')
for pose in poses: out.append(data([v&255 for v in pose]))
colors=[0x36,0x0e,0xf4,0x46]
for side in ('Left','Right'):
 out.append('HorseColor'+side+'\n')
 for color in colors:
  rows=[0x1e,0x1e,0x0e,0xae,0xae,0xae]+[color]*7+[color&0xf6,0x0e,0]
  if side=='Right': rows=[color]*14+[0x0e,0]
  out.append(data(rows))
out.append('        align 64\nMen\n')
men=[0x38,0x7c,0xfe,0x38,0x6c,0x7c,0x10,0x7c,0xfe,0x92,0x92,0x38,0x28,0x28,0x6c,0]
wave=[0x38,0x7c,0xfe,0x39,0x6d,0x7d,0x13,0x7e,0xfc,0x90,0x90,0x38,0x28,0x28,0x6c,0]
out.append(data(men));out.append(data(wave));out.append('MenColor\n');out.append(data([0x1e]*3+[0x3e]*3+[0x0e]+[0x9c]*4+[0x02]*4+[0]))
(ROOT/'src/assets.inc').write_text(''.join(out))
print('Generated',len(lines),'text panels and four horse poses.')
if __name__=='__main__': pass
