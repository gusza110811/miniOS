.PHONY: all run build debug clean

all: os.img

build: os.img

os.img: boot.bin kernel.bin
	cat boot.bin > os.img
	truncate os.img --size 17k
	badfs os.img import kernel.bin KERNEL

boot.bin: boot.asm
	ma-as boot.asm

kernel.bin: kernel.asm
	ma-as kernel.asm

run: os.img
	ma-vm --hda os.img

debug: os.img
	ma-vm --hda os.img --dump

trace: os.img
	ma-vm --hda os.img --dump --trace

clean:
	rm os.img
	rm *.bin
