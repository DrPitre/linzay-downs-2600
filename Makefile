DASM ?= dasm
.PHONY: all assets clean
all: dist/linzay-downs-ntsc.bin
assets:
	python3 tools/make_assets.py
src/assets.inc: tools/make_assets.py
	python3 tools/make_assets.py
dist/linzay-downs-ntsc.bin: src/linzay.asm src/assets.inc
	mkdir -p dist
	cd src && $(DASM) linzay.asm -f3 -o../dist/linzay-downs-ntsc.bin -l../dist/linzay-downs.lst -s../dist/linzay-downs.sym
.PHONY: check
check: all
	python3 tools/check_rom.py
	mkdir -p build/check
	mame a2600 -cart $(abspath dist/linzay-downs-ntsc.bin) -video none -sound none -nothrottle -skip_gameinfo -snapsize 704x892 -autoboot_delay 0 -autoboot_script $(abspath tools/check_mame.lua) -seconds_to_run 80 -cfg_directory $(abspath build/cfg) -nvram_directory $(abspath build/nvram) > build/emulator.log 2>&1
	cat build/check/results.txt
.PHONY: package
package: all
	python3 tools/check_rom.py
	zip -q -r dist/linzay-downs-atari2600.zip README.md Makefile src tools screenshots dist/linzay-downs-ntsc.bin dist/rom-info.json dist/test-results.txt
