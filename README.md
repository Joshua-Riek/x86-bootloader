## x86 Bootloader

A collection of small 512 byte programs that are capable of finding, 
loading, then executing a program on a FAT12/16 formatted floppy or hard disk 
(including USB and CDs). Typically, this would be used as a boot sector
for an operating system, second stage bootloader, or low level kernel.

## Limitations and Implementation Details

Requires an i8086 or better CPU.

This bootloader may allocate up to 128KB of RAM in order to load the entire 
File Allocation Table (FAT) into memory; therefore, leaving approximately 
400KB for loading your program or kernel (assuming at least 640KB of available 
conventional memory). The bootloader will reallocate itself to the top of 
conventional memory, allocate space for the stack and FAT. Then finally search for and 
load the program *DEMO.BIN* at the physical address specified by *LOAD_ADDR*.

## Requirements

Please install the packages below, or type:
```
$ sudo apt-get install gdb nasm qemu dosfstools mtools
```
> This project uses an optional i686-elf cross-compiler, you can click 
[here](https://wiki.osdev.org/GCC_Cross-Compiler) for more 
information on compiling it yourself, or use some precompiled binaries 
[here](https://github.com/lordmilko/i686-elf-tools/releases).

## Building

To checkout the source and build:
```
$ git clone https://github.com/Joshua-Riek/x86-bootloader
$ cd x86-bootloader
$ make
```

## Virtual Machine

To run the bootloader in a virtual machine:
```
$ make run
```

## Virtual Machine Debugging

Start a virtual machine with a GDB stub:
```
$ make debug
```

Open another ternimal and connect to the virtual machine's GDB stub:
```
$ make gdb
```
> For debug symbols to be generated, you must compile with an i686-elf cross-compiller.
