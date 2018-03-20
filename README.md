# NASM Bootloader
This minimal bootloader is currently able to find, load, and execute
a program on any FAT12 formatted floppy or hard disk (including usb devices).

## Features and Goals
- [x] FAT12 floppy disk support
- [x] FAT12 hard disk support
- [x] Works on any allowed FAT12 size
- [ ] FAT16 hard disk support
- [ ] Works on any allowed FAT16 size
- [ ] FAT32 hard disk support
- [ ] Works on any allowed FAT32 size

## Memory Map
TODO

# Compiling
TODO

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