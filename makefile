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

# Output directory
OUTDIR        = obj

# Build flags
CFLAGS       +=
LDFLAGS      +=
ARFLAGS      +=
LDFLAGS      += -m elf_i386 -Ttext=0x7c00
NASMFLAGS    += -f elf -g3 -F dwarf
OBJCOPYFLAGS += -O binary

FIXTEXTFLAGS += --change-section-vma

# For Windows compatibility (I recomend using a i686-elf cross-compiler)
ifeq ($(OS), Windows_NT)
  CC         := i686-elf-gcc
  LD         := i686-elf-ld
  AR         := i686-elf-ar 
endif


.PHONY: all clean clobber

# Rule to make targets
all: $(OUTDIR)/boot12.bin $(OUTDIR)/boot16.bin $(OUTDIR)/demo.bin

# Makefile target for the FAT12 bootloader
$(OUTDIR)/boot12.elf: $(OUTDIR)/boot12.o
	$(LD) $^ $(LDFLAGS) -o $@

$(OUTDIR)/boot12.o: boot12.asm | $(OUTDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@

$(OUTDIR)/boot12.bin: $(OUTDIR)/boot12.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

# Makefile target for the FAT16 bootloader
$(OUTDIR)/boot16.o: boot16.asm | $(OUTDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@ 

$(OUTDIR)/boot16.elf: $(OUTDIR)/boot16.o
	$(LD) $^ $(LDFLAGS) -o $@

$(OUTDIR)/boot16.bin: $(OUTDIR)/boot16.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@ 

# Makefile target for the demo file
$(OUTDIR)/demo.bin: demo.asm | $(OUTDIR)
	$(NASM) $^ -f bin -o $@


# Create the output folder
$(OUTDIR):
	mkdir -p $(OUTDIR)

install:
	dd if=obj/boot16.bin of=floppy.img bs=1 skip=62 seek=62


# Clean produced files
clean:
	rm -r -f $(OUTDIR)

clobber: clean
	rm -f *.img *~ \#*\#
