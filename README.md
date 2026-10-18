# Linzay Downs — Atari 2600

An original **4 KB NTSC Atari 2600 cartridge** adaptation of the CoCo 3
Linzay Downs race, set in Eunice, Louisiana. Tee-Boy is the chestnut horse
in the top lane. Three rivals race him while old men wave beside the rail.
Cecil Brown and Leroy Pitre take turns calling out short Cajun cheers.

## Play

Open `dist/linzay-downs-ntsc.bin` in Stella, MAME's `a2600` system, or a
compatible cartridge loader on an NTSC Atari 2600.

| Control | Action |
| --- | --- |
| Joystick 1 fire | Start; replay after finishing |
| Hold joystick Right | Gallop |
| Hold Right + fire | Sprint, consuming stamina |
| Release fire | Recover stamina while galloping |
| Release Right | Trot and recover stamina faster |
| Console Reset | Return to the starting screen |

In MAME's default keyboard mapping, use **Right Arrow** and **Left Control**
(fire). Release and press fire again to replay; holding it through the
finish leaves your result visible. The turquoise bar indicates stamina.
The finishing screen shows first, second, third, or fourth place.

```sh
mame a2600 -cart dist/linzay-downs-ntsc.bin -window -skip_gameinfo
```

This is the racing mode. The dockside brawler remains a CoCo 3 program.

## Build

The cartridge is written in 6507-compatible 6502 assembly and assembled
with [DASM](https://github.com/dasm-assembler/dasm). Python 3 generates the
original text and sprite tables; it requires no third-party packages.

```sh
make                  # with dasm on PATH
make DASM=/path/to/dasm
make assets           # regenerate original art tables
python3 tools/check_rom.py
make check            # requires MAME with the a2600 system
make package
```

## Implementation and verification

The TIA's two player objects are reused in four vertical lanes, making four
32-pixel-wide horses without frame-alternating flicker. The native kernel
renders at **262 scanlines, about 59.92 Hz**. A 3x5 playfield font displays
the track, location, speaker, cheer, and race result. Spectators wave, and
hoofbeats and a finishing tone use the TIA audio channel.

Cheer text is shortened to fit ten characters per line: examples include
`LACHE PAS!`, `MAIS OUI!`, `ASTEUR!`, and `GO CHER!`. The two-line names
retain Cecil Brown and Leroy Pitre in full. This version uses the 2600's
128-byte RAM with ample space remaining for the stack. It needs no extra
cartridge RAM or bankswitching.

`tools/check_rom.py` verifies the 4 KB image, vectors, and RAM headroom.
`tools/check_mame.lua` tests attract mode, countdown, held Right, sprinting,
stamina recovery, first/fourth-place results, held-fire protection, and
replay. It checks exact scanline counts using the emulated TIA's cycle
origin rather than scheduler timestamps. The completed native run checked
2,503 consecutive frames at 262 scanlines. See `dist/test-results.txt` and
`dist/rom-info.json` for the results and cartridge checksum.

Validated in MAME. Physical-console and PAL testing have not been performed.
