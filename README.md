## NASM Bootloaders
Two small 512 byte programs that are capable of finding, loading,
then executing a program on a FAT12/16 formatted floppy or hard disk 
(including USB and CDs). Typically, this would be used as a boot sector
for an operating system, second stage bootloader, or low level kernel.

## Limitations
Requires an i8086 or better CPU.

The bootloader supports any size up to a maximum of 2GB. 
This is due to using the BIOS interrupt call [13h] service [02h] in support for older hardware. 
Please note that when using a hard drive that is 2GB in size, this bootloader may allocate ~256KB
of RAM in order to load the entire File Allocation Table (FAT) into memory; therefore, leaving 
approximately 272KB of conventional memory for loading your program or kernel (assuming at least 1mb of ram).

## Features and Goals
- [x] FAT12 floppy/ hard disk support
- [x] FAT16 hard disk support

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
