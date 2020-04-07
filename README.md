## NASM Bootloaders
Two small 512 byte programs that are capable of finding, loading,
then executing a program on a FAT12/16 formatted floppy or hard disk 
(including USB and CDs). Typically, this would be used as a boot sector
for an operating system, second stage bootloader, or low level kernel.

## Limitations
Requires an i8086 or better CPU.

The bootloader supports any size up to a maximum of 2GB. This is due to using the BIOS interrupt call [13h] service [02h] in support for older hardware. Please note that when using a hard drive that is 2GB in size, this bootloader may allocate ~256KB of RAM in order to load the entire File Allocation Table (FAT) into memory; therefore, leaving approximately 272KB of conventional memory for loading your program or kernel (assuming at least 1mb of ram).

## Requirements

To install QEMU click [here](https://www.qemu.org/download/), or type:
```
$ sudo apt-get install qemu
```

To install Nasm click [here](https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/), or type:
```
$ sudo apt-get install nasm
```

As for getting yourself an i686-elf cross-compiler you can click [here](https://wiki.osdev.org/GCC_Cross-Compiler) for more information on compiling it yourself, or just use some precompiled binaries [here](https://github.com/lordmilko/i686-elf-tools/releases). Lastly, if you are using Windows, please download a port of [dd](http://www.chrysocome.net/dd) for installing the bootsector to the floppy disk image.

## Building

To checkout the source and build:
```
$ git clone https://github.com/Joshua-Riek/NASM-Bootloader
$ cd NASM-Bootloader/
$ make
```

A build should look like this:
```
$ make
nasm src/boot12.asm -O0 -f elf -g3 -F dwarf -o obj/boot12.o
i686-elf-ld obj/boot12.o  -e entryPoint -m elf_i386 -Ttext=0x7c00 -o bin/boot12.elf
objcopy bin/boot12.elf -O binary bin/boot12.bin
nasm src/boot16.asm -O0 -f elf -g3 -F dwarf -o obj/boot16.o
i686-elf-ld obj/boot16.o  -e entryPoint -m elf_i386 -Ttext=0x7c00 -o bin/boot16.elf
objcopy bin/boot16.elf -O binary bin/boot16.bin
```

To build without a cross-compiller:
```
$ nasm src/boot12.asm -O0 -f bin -o bin/boot12.bin
$ nasm src/boot16.asm -O0 -f bin -o bin/boot16.bin
```

## Installing

To install the bootloader:
```
$ make install
```

A successful install should look like:
```
$ make install
dd if=./bin/boot12.bin of=floppy.img bs=1 skip=62 seek=62
rawwrite dd for windows version 0.6beta3.
Written by John Newbigin <jn@it.swin.edu.au>
This program is covered by terms of the GPL Version 2.

skip to 62
450+0 records in
450+0 records out
```

[13h]:    http://webpages.charter.net/danrollins/techhelp/0185.HTM
[02h]:    http://webpages.charter.net/danrollins/techhelp/0188.HTM
[42h]:    https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)
