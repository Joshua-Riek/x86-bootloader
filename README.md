# NASM Bootloader
This minimal bootloader is currently able to find, load, and execute
a program on any FAT12 formatted floppy or hard disk (including usb devices).

Please note that the original max file size that the bootloader can load
is 14kb, but this can be streached to around 20k before overflowing into
the bottom of the bootloaders' stack, their are no checks in place to
prevent this. If you wish to move around the memory map please be my
guest and make it suitable for your needs.


## Features and Goals
- [x] FAT12 floppy disk support
- [x] FAT12 hard disk support
- [x] Works on any allowed FAT12 size
- [ ] FAT16 hard disk support
- [ ] Works on any allowed FAT16 size
- [ ] FAT32 hard disk support
- [ ] Works on any allowed FAT32 size

## Compiling
Their are two ways that the bootloader can be compiled, you can either run
`make` in the directory (on windows you must have a cross-compiller) or you
can simply follow the example below.
```batch
nasm -f bin boot12.asm -o boot12.bin
```

## Memory Map
| Linear Address | Item                       |
| -------------: | :-------------------------------- |
|        0x00e000 | Stage2 stack 8k (top: 0xf000) |
|        0x00d000 | : |
|        0x00c000 | Disk buffer 18k (ends: 0xc7ff) |
|        0x00b000 | : |
|        0x00a000 | : |
|        0x009000 | : |
|        0x008000 | Disk buffer 18k (starts: 0x8000) |
|        0x007000 | Boot location between  (0x7c00-0x7dff) |
|        0x006000 | Boot stack 4k (top: 0x7000)|
|        0x005000 | |
|        0x004000 | Stage2 location 14k (ends: 0x47ff) |
|        0x003000 | : |
|        0x002000 | : |
|        0x001000 | Stage2 location 14k (starts: 0x1000) |

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