## NASM Bootloaders
A small collection of homemade bootloaders capable of finding, loading,
then executing a program on a FAT12/16 formatted floppy or hard disk 
(including USB and CDs). Typically, this would be used for a bootloader 
for an operating system, second stage bootloader, or low level kernel.

#### Notes
Please note that the max file size of a program that you may load is
just about 20kb, this is before overflowing into the bootloader's stack,
their are no checks in place to prevent this. If you wish to move around
the memory map/location please be my guest and make it suitable for your needs.

#### FAT12
WIP

#### FAT16
WIP 

## Features and Goals
- [x] FAT12 floppy disk support
- [x] FAT12 hard disk support
- [x] Works on any allowed FAT12 size
- [x] FAT16 hard disk support
- [ ] Works on any allowed FAT16 size
- [ ] FAT32 hard disk support
- [ ] Works on any allowed FAT32 size

## Compiling
Their are two ways that the bootloader can be compiled, you can either run
`make` in the directory (on windows you must have a cross-compiller) or you
can simply follow the example below.
```batch
nasm -f bin foo.asm -o foo.bin
```

## Resources
* [OSDev] Is a great website for any Hobby OS developer.
* [NASM] Used for the bootloader.
* [imdisk] & [dd] To write the system files to a floppy image or hard disk.
* [QEMU] Image emulator for testing the bootloader.

[QEMU]:   http://www.qemu.org/
[imdisk]: http://www.ltr-data.se/opencode.html/
[dd]:     http://uranus.chrysocome.net/linux/rawwrite/dd-old.htm
[OSDev]:  http://wiki.osdev.org/Main_Page
[NASM]:   http://www.nasm.us/index.php
