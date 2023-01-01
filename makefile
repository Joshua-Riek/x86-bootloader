#  makefile
#
#  Copyright (c) 2017-2023, Joshua Riek
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Build tools
CC           := i686-elf-gcc
LD           := i686-elf-ld
AR           := i686-elf-ar
OBJCOPY      := i686-elf-objcopy
NASM         := nasm

# Output directory
SRCDIR        = ./src
OBJDIR        = ./obj
BINDIR        = ./bin

# Build flags
CFLAGS       +=
LDFLAGS      +=
ARFLAGS      +=
LDFLAGS      += -m elf_i386 -Ttext=0x0000
NASMFLAGS    += -f elf -g3 -F dwarf
OBJCOPYFLAGS += -O binary


# Set phony targets
.PHONY: all clean clobber demo bootloader image debug run gdb


# Rule to make targets
all: bootloader demo image


# Makefile target for both bootloaders
ifeq ($(and $(shell which $(LD)),$(shell which $(OBJCOPY))),)
bootloader: $(BINDIR)/boot12.bin $(BINDIR)/boot16.bin

$(BINDIR)/boot12.bin: $(SRCDIR)/boot12.asm | $(BINDIR)
	$(NASM) $^ -f bin -o $@

$(BINDIR)/boot16.bin: $(SRCDIR)/boot16.asm | $(BINDIR)
	$(NASM) $^ -f bin -o $@
else
bootloader: $(BINDIR)/boot12.bin $(BINDIR)/boot16.bin

$(BINDIR)/boot12.bin: $(BINDIR)/boot12.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

$(BINDIR)/boot12.elf: $(OBJDIR)/boot12.o | $(BINDIR)
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot12.o: $(SRCDIR)/boot12.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@

$(BINDIR)/boot16.bin: $(BINDIR)/boot16.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

$(BINDIR)/boot16.elf: $(OBJDIR)/boot16.o | $(BINDIR)
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot16.o: $(SRCDIR)/boot16.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@
endif


# Makefile target for the demo file
demo: $(BINDIR)/demo.bin

$(BINDIR)/demo.bin: $(SRCDIR)/demo.asm | $(BINDIR)
	$(NASM) $^ -f bin -o $@


# Makefile target to create both disk images
image: $(BINDIR)/boot12.img $(BINDIR)/boot16.img

$(BINDIR)/boot12.img: $(BINDIR)/boot12.bin $(BINDIR)/demo.bin
	dd if=/dev/zero of=$@ bs=1024 count=1440 status=none
	mkfs.vfat -F12 $@ 1> /dev/null
	mcopy -n -i $@ $(BINDIR)/demo.bin ::
	dd if=$< of=$@ bs=1 skip=62 seek=62 conv=notrunc status=none

$(BINDIR)/boot16.img: $(BINDIR)/boot16.bin $(BINDIR)/demo.bin
	dd if=/dev/zero of=$@ bs=1024 count=16384 status=none
	mkfs.vfat -F16 $@ 1> /dev/null
	mcopy -i $@ $(BINDIR)/demo.bin ::
	dd if=$< of=$@ bs=1 skip=62 seek=62 conv=notrunc status=none


# Create the obj dir
$(OBJDIR):
	@mkdir -p $@

# Create the bin dir
$(BINDIR):
	@mkdir -p $@


# Clean produced files
clean:
	rm -f $(OBJDIR)/* $(BINDIR)/*

# Clean files from emacs
clobber: clean
	rm -f $(SRCDIR)/*~ $(SRCDIR)\#*\# ./*~


# Makefile target to run or debug both disk images
ifeq ($(FAT), 16)
run: image
	qemu-system-i386 -serial stdio -rtc base=localtime -drive file=bin/boot16.img,format=raw

debug: image
	qemu-system-i386 -serial stdio -rtc base=localtime -S -s -drive file=bin/boot16.img,format=raw

gdb: image
	-gdb -q -ex "exec-file bin/boot16.elf" -ex "add-symbol-file bin/boot16.elf 0x9FA00 -readnow" -ex "break reallocatedEntry"
else
run: image
	qemu-system-i386 -serial stdio -rtc base=localtime -drive file=bin/boot12.img,format=raw,if=floppy

debug: image
	qemu-system-i386 -serial stdio -rtc base=localtime -S -s -drive file=bin/boot12.img,format=raw,if=floppy

gdb: image
	-gdb -q -ex "exec-file bin/boot12.elf" -ex "add-symbol-file bin/boot12.elf 0x9FA00 -readnow" -ex "break reallocatedEntry"
endif