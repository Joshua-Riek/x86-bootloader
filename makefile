#  makefile
#
#  Copyright (c) 2017-2020, Joshua Riek
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
NASM         := nasm
OBJCOPY      := objcopy
DD           := dd

# Other tools
QEMU         ?= qemu-system-i386

# Output directory
SRCDIR        = ./src
OBJDIR        = ./obj
BINDIR        = ./bin

# Build flags
CFLAGS       +=
LDFLAGS      +=
ARFLAGS      +=
LDFLAGS      += -e entryPoint -m elf_i386 -Ttext=0x7c00
NASMFLAGS    += -O0 -f elf -g3 -F dwarf
OBJCOPYFLAGS += -O binary

# Disk image file
DISKIMG       = floppy.img

# NOTE: Using DD from MinGW seems to work better for me
ifeq ($(OS), Windows_NT)
  DD         := D:\Compilers\MinGW\bin\dd
endif


# Set phony targets
.PHONY: all clean clobber run debug install boot12 boot16 demo


# Rule to make targets
all: boot12 boot16 demo


# Makefile target for the FAT12 bootloader
boot12: $(BINDIR)/boot12.bin

$(BINDIR)/boot12.bin: $(BINDIR)/boot12.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

$(BINDIR)/boot12.elf: $(OBJDIR)/boot12.o | $(BINDIR)
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot12.o: $(SRCDIR)/boot12.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@


# Makefile target for the FAT16 bootloader
boot16: $(BINDIR)/boot16.bin

$(BINDIR)/boot16.bin: $(BINDIR)/boot16.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

$(BINDIR)/boot16.elf: $(OBJDIR)/boot16.o | $(BINDIR)
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot16.o: $(SRCDIR)/boot16.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@


# Makefile target for the demo file
demo: $(BINDIR)/demo.bin

$(BINDIR)/demo.bin: $(SRCDIR)/demo.asm | $(OBJDIR)
	$(NASM) $^ -f bin -o $@


# Create the obj dir
$(OBJDIR):
	@mkdir -p $@

# Create the bin dir
$(BINDIR):
	@mkdir -p $@


# Clean produced files
clean:
	rm -f $(OBJDIR)/* $(OBJDIR)/* $(BINDIR)/*

# Clean files from emacs
clobber: clean
	rm -f $(SRCDIR)/*~ $(SRCDIR)\#*\#


# Write the bootloader to a disk image
install: 
	$(DD) if=$(BINDIR)/boot12.bin of=floppy.img bs=1 skip=62 seek=62

# Run the disk image
run:
	$(QEMU) -fda $(DISKIMG)

# Start a debug session with qemu
debug:
	$(QEMU) -S -s -fda $(DISKIMG)
