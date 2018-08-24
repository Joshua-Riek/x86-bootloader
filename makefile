#  makefile
#
#  Copyright (c) 2017-2018, Joshua Riek
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
CC           ?= gcc
LD           ?= ld
AR           ?= ar
NASM         ?= nasm
OBJCOPY      ?= objcopy
DD           ?= dd

# Output directory
SRCDIR        = ./src
OBJDIR        = ./obj
BINDIR        = ./bin

# Build flags
CFLAGS       +=
LDFLAGS      +=
ARFLAGS      +=
LDFLAGS      += -m elf_i386 -Ttext=0x7c00
NASMFLAGS    += -f elf -g3 -F dwarf
OBJCOPYFLAGS += -O binary


# For Windows compatibility (I recomend using a i686-elf cross-compiler)
ifeq ($(OS), Windows_NT)
  CC         := i686-elf-gcc
  LD         := i686-elf-ld
  AR         := i686-elf-ar 
endif


# Set phony targets
.PHONY: all clean clobber fat12 fat16 demo


# Rule to make targets
all: fat12 fat16 demo


# Makefile target for the FAT12 bootloader
fat12: $(BINDIR)/boot12.bin

$(BINDIR)/boot12.elf: $(OBJDIR)/boot12.o
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot12.o: $(SRCDIR)/boot12.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@

$(BINDIR)/boot12.bin: $(BINDIR)/boot12.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@


# Makefile target for the FAT16 bootloader
fat16: $(BINDIR)/boot16.bin

$(BINDIR)/boot16.elf: $(OBJDIR)/boot16.o
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/boot16.o: $(SRCDIR)/boot16.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@

$(BINDIR)/boot16.bin: $(BINDIR)/boot16.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@


# Makefile target for the demo file
demo: $(BINDIR)/demo.bin

$(BINDIR)/demo.bin: $(SRCDIR)/demo.asm | $(OBJDIR)
	$(NASM) $^ -f bin -o $@


# Clean produced files
clean:
	rm -f $(OBJDIR)/* $(OBJDIR)/*

# Clean files from emacs
clobber: clean
	rm -f $(SRCDIR)/*~ $(SRCDIR)\#*\#


# Write the bootloader to a disk image
install:
	$(DD) if=$(BINDIR)/boot16.bin of=../floppy.img bs=1 skip=62 seek=62


