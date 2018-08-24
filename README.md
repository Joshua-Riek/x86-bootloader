## NASM Bootloaders
A small collection of homemade bootloaders capable of finding, loading,
then executing a program on a FAT12/16 formatted floppy or hard disk 
(including USB and CDs). Typically, this would be used as a boot sector
for an operating system, second stage bootloader, or low level kernel.

## Limitations
Both *fat12.asm* and *fat16.asm* where created in mind for older hardware; therefore, requires an i8086 or better CPU and a recomended 256KB of ram.



The file *fat16.asm* supports drives with a minimum size of 16MB and a maximum of 2GB. This is due to using the BIOS interrupt call [13h] service [02h] in support for older hardware. Please note that this may allocate up to 128KB of RAM in order to load the entire File Allocation Table (FAT) into memory; therefore, leaving approximately 400KB of conventional memory for loading your program or kernel.

## Features and Goals
- [x] FAT12 floppy disk support
- [x] FAT16 hard disk support
- [ ] FAT32 hard disk support

## Resources
* [OSDev] Is a great website for any Hobby OS developer.
* [NASM] Assembler used to write the bootloader.
* [imdisk] & [dd] To write the system files to a floppy image or hard disk.
* [QEMU] Image emulator for testing the bootloader.

[QEMU]:   http://www.qemu.org/
[imdisk]: http://www.ltr-data.se/opencode.html/
[dd]:     http://uranus.chrysocome.net/linux/rawwrite/dd-old.htm
[OSDev]:  http://wiki.osdev.org/Main_Page
[NASM]:   http://www.nasm.us/index.php

[13h]:    http://webpages.charter.net/danrollins/techhelp/0185.HTM
[02h]:    http://webpages.charter.net/danrollins/techhelp/0188.HTM
[42h]:    https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)
