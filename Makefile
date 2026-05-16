.PHONY: all run build debug clean

all: osall.img

osall.img: os.img test0.bin test1.bin
	cp os.img osall.img

	badfs osall.img import test0.bin test0
	badfs osall.img import test1.bin test1
os.img: boot.bin kernel.bin
	cat boot.bin > os.img
	truncate os.img --size 17k
	badfs os.img import kernel.bin KERNEL


boot.bin: boot.asm
	ma-as boot.asm
kernel.bin: kernel.asm
	ma-as kernel.asm


test0.bin: test0.asm
	ma-as test0.asm
test1.bin: test1.asm
	ma-as test1.asm


run: osall.img
	ma-vm --hda osall.img
debug: osall.img
	ma-vm --hda osall.img --dump
btrace: osall.img
	ma-vm --hda osall.img --dump --trace
ktrace: osall.img
	ma-vm --hda osall.img --dump --trace --trace-when 0x10000
utrace: osall.img
	ma-vm --hda osall.img --dump --trace --trace-when 0x20000

clean:
	rm os.img
	rm osall.img
	rm *.bin
