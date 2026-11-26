.POSIX:

PYTHON = python3
BINTOOLS = vendor/bintools
BINTOOLS_URL = https://github.com/EtchedPixels/Fuzix-Bintools
BINTOOLS_COMMIT = 791db957f9fb451dfb0b7faf8a77aa435a75ed7b

# Order of assembly: entry.asm is at $4000, end.asm ends the BSS.
SRC_HEAD = src/directpage.asm src/entry.asm
SRC_MAIN = src/main.asm src/turn.asm src/ai.asm src/ev.asm src/eval.asm \
	src/shgen.asm src/score.asm src/sound.asm src/ui.asm src/settle.asm \
	src/util.asm src/direct.asm
SRC_VOICE = src/speech.asm src/unpack.asm
ASM = $(SRC_HEAD) $(SRC_MAIN) $(SRC_VOICE) src/end.asm
GEN = tools/gen.py tools/tiles.py tools/huff.py tools/font.py tools/small.py
PCM = voice/chi.pcm voice/kan.pcm voice/pon.pcm voice/riichi.pcm \
	voice/ron.pcm voice/tsumo.pcm

all: mj4.raw

mj4.raw: build/mj4.out tools/post.py directpage.json
	$(PYTHON) tools/post.py build mj4

build/mj4.out: build/all.s $(BINTOOLS)/as6800 $(BINTOOLS)/ld6800
	cd build && ../$(BINTOOLS)/as6800 -l mj4.lst all.s
	cd build && ../$(BINTOOLS)/ld6800 -b -C 0x4000 -D 0x2F00 -B 0x2F00 \
		-m mj4.map -o mj4.out all.o

build/all.s: $(ASM) build/data.s voice/packed.s build/flags.ok
	cat $(SRC_HEAD) voice/trees.s $(SRC_MAIN) build/data.s $(SRC_VOICE) \
		voice/packed.s src/end.asm > build/all.s

build/flags.ok: $(SRC_HEAD) $(SRC_MAIN) tools/check_flags.py
	mkdir -p build
	$(PYTHON) tools/check_flags.py $(SRC_HEAD) $(SRC_MAIN)
	touch build/flags.ok

build/data.s: build/strings.txt $(GEN)
	$(PYTHON) tools/gen.py build/strings.txt build/data.s

build/strings.txt: strings.txt tools/strings.py $(ASM)
	mkdir -p build
	$(PYTHON) tools/strings.py strings.txt build/strings.txt $(ASM)

voice/packed.s: $(PCM) tools/voice_pack.py
	$(PYTHON) tools/voice_pack.py

$(BINTOOLS)/as6800: $(BINTOOLS)/Makefile
	cd $(BINTOOLS) && $(MAKE) as6800

$(BINTOOLS)/ld6800: $(BINTOOLS)/Makefile
	cd $(BINTOOLS) && $(MAKE) ld6800

$(BINTOOLS)/Makefile:
	git clone $(BINTOOLS_URL) $(BINTOOLS)
	cd $(BINTOOLS) && git checkout -q $(BINTOOLS_COMMIT)

clean:
	rm -rf build mj4.raw mj4.s19

distclean: clean
	rm -rf vendor
