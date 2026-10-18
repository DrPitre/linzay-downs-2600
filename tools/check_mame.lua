-- Real 6507/TIA integration checks; run with MAME a2600 and this ROM.
local dir=os.getenv('LINZAY_TESTDIR') or 'build/check'
local symfile=os.getenv('LINZAY_SYMBOLS') or 'dist/linzay-downs.sym'
local symbols={}
local file=assert(io.open(symfile,'r'))
for line in file:lines() do
 local key,value=line:match('^(%w+)%s+([%da-fA-F]+)%s')
 if key then symbols[key]=tonumber(value,16) end
end
file:close()
local space=manager.machine.devices[':maincpu'].spaces['program']
local port=manager.machine.ioport.ports[':joyport1:joy:JOY']
local screen=manager.machine.screens[':screen']
local function read(name,offset) return space:read_u8(assert(symbols[name])+ (offset or 0)) end
local function key(name,value) port.fields[name]:set_value(value) end
local function snap(name) screen:snapshot(dir..'/'..name..'.png') end
-- The TIA's saved cycle origin is exact; emu.time() in CPU write taps
-- is scheduler-quantized and is unsuitable for sub-scanline assertions.
local origin=emu.item(assert(manager.machine.devices[':tia_video'].items['0/frame_cycles']))
local periods={}
local previous=nil
local syncs=0
os.remove(dir..'/results.txt')
vsync_tap=space:install_write_tap(0,0,'Linzay NTSC timing',function(offset,data,mask)
 if (data&2)~=0 then
  local now=origin:read(0)
  syncs=syncs+1
  if previous and syncs>2 then periods[#periods+1]=(now-previous)/76 end
  previous=now
 end
end)
emu.wait(1)
assert(read('Phase')==0,'Attract screen failed')
assert(read('Speaker')==0,'Cecil should introduce the race')
snap('attract')
key('P1 Button 1',1); emu.wait(0.1); key('P1 Button 1',0)
key('P1 Right',1); emu.wait(2.3)
assert(read('Phase')==2,'Countdown did not start race')
assert(read('Pos')>8 and read('Pos')<120,'Held Right did not move Tee-Boy')
snap('race')
key('P1 Button 1',1); emu.wait(1)
local drained=read('Stamina')
assert(drained<64,'Sprint did not consume stamina')
assert(read('Speaker')==1,'Leroy should speak after Cecil')
snap('leroy')
key('P1 Button 1',0); emu.wait(1)
assert(read('Stamina')>drained,'Stamina did not recover')
key('P1 Button 1',1)
local deadline=emu.time()+20
while read('Phase')~=3 and emu.time()<deadline do emu.wait(0.2) end
assert(read('Phase')==3 and read('Place')==1,'Sprint strategy did not win')
assert(read('Pos')==120,'Winner did not stop at the finish')
emu.wait(0.5)
assert(read('Phase')==3,'Held fire restarted after winning')
snap('win')
key('P1 Button 1',0); key('P1 Right',0); emu.wait(0.1)
key('P1 Button 1',1); emu.wait(0.1); key('P1 Button 1',0)
assert(read('Phase')==1 and read('Stamina')==64,'Replay did not reset race')
snap('replay')
deadline=emu.time()+35
while read('Phase')~=3 and emu.time()<deadline do emu.wait(0.25) end
assert(read('Phase')==3 and read('Place')==4,'Trotting should finish fourth')
snap('fourth')
for i=1,#periods do
 local scanlines=periods[i]
 assert(math.abs(scanlines-262)<0.01,string.format('Unstable frame: %.3f scanlines',scanlines))
end
local f=assert(io.open(dir..'/results.txt','w'))
f:write('PASS: attract, countdown, held Right, sprint drain, recovery, first/fourth place, held-fire protection, replay\n')
f:write(string.format('PASS: %d consecutive frames at 262 NTSC scanlines (59.92 Hz)\n',#periods))
f:close()
print('PASS: Atari 2600 integration and NTSC timing ('..#periods..' frames)')
manager.machine:exit()
