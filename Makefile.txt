# ZudaDOS build
# Produces zudados.img: a 1.44MB bootable floppy image.
# Tools: GNU as / ld / objcopy / dd (no NASM, no emulator required).

AS      := as
LD      := ld
OBJCOPY := objcopy

.PHONY: all clean run

all: zudados.img

boot.o: boot.s
	$(AS) --32 -o $@ $<

kernel.o: kernel.s
	$(AS) --32 -o $@ $<

# Link each stage as a flat binary at its load address.
boot.bin: boot.o
	$(LD) -m elf_i386 -Ttext 0x7C00 -e _start -o boot.elf boot.o
	$(OBJCOPY) -O binary boot.elf $@

kernel.bin: kernel.o
	$(LD) -m elf_i386 -Ttext 0x0000 -e _start -o kernel.elf kernel.o
	$(OBJCOPY) -O binary kernel.elf $@

# Assemble the disk image: boot sector at LBA 0, kernel from LBA 1 onward,
# padded to a standard 1.44MB floppy.
zudados.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin   of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "Built $@ ($$(wc -c < $@) bytes)"

# Convenience target if QEMU is ever installed.
run: zudados.img
	qemu-system-i386 -fda zudados.img

clean:
	rm -f *.o *.elf *.bin zudados.img
