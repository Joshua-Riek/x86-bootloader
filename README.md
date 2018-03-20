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
        0x100000 | Top of the memory hole |
        0x0F0000 | Video memory, MMIO, BIOS |
        0x0A0000 | Bottom of the memory hole |
        0x090000 | |
        0x010000 | |
        0x00F000 | |
        0x00E000 | Stage2 top of stack (0xf000) |
        0x00D000 | : |
        0x00C000 | Buffer location ends (0xc7ff) |
        0x00B000 | : |
        0x00A000 | : |
        0x009000 | : |
        0x008000 | Buffer location starts (0x8000) |
        0x007000 | Boot location between  (0x7c00-0x7dff) |
        0x006000 | Boot top of stack (0x7000)|
        0x005000 | |
        0x004000 | Stage2 location ends (0x47ff) |
        0x003000 | : |
        0x002000 | : |
        0x001000 | Stage2 location starts (0x1000) |
        0x000000 | Reserved (Real Mode IVT, BDA) |

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