;  demo.asm
;
;  This is just a demo file for the bootloader.  
;  Copyright (c) 2017-2018, Joshua Riek
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
    
    STACK_SEG     equ 0x0f00                    ; (STACK_SEG * 0x10) + STACK_OFF = 0x10000
    STACK_OFF     equ 0x1000

    BUFFER_SEG    equ 0x1000                    ; (BUFFER_SEG * 0x10) + BUFFER_OFF = 0x10000
    BUFFER_OFF    equ 0x0000

    STAGE2_SEG    equ 0x4000                    ; (STAGE2_SEG * 0x10) + STAEG2_OFF = 0x40000
    STAGE2_OFF    equ 0x0000
	
	
;---------------------------------------------------------------------
; Bootloader Memory Map
;---------------------------------------------------------------------
; Linear Address | Item
;       0x100000 | Top of memory hole
;       0x0f0000 | Video memory, MMIO, BIOS	
;       0x0a0000 | Bottom of memory hole
;       0x090000 |
;       0x080000 |
;       0x070000 |
;       0x060000 |
;       0x050000 |
; ====> 0x040000 | Load location ~400k (starts: 0x040000)   
;       0x030000 | Disk buffer    128k (ends:   0x030000)
;       0x020000 | 
;       0x010000 | Disk buffer    128k (starts: 0x010000)
;       0x00f000 | Load Stack       4k (top:    0x010000)
;       0x00e000 |
;       0x00d000 |
;       0x00c000 |
;       0x00b000 |
;       0x00a000 |
;       0x009000 |
;       0x008000 |
;       0x007000 | Boot location   512b (start: 0x007c00)
;       0x006000 | Boot stack        4k (top:   0x007000)
;       0x005000 |              
;       0x004000 |
;       0x003000 |
;       0x002000 |
;       0x001000 |
;       0x000000 | Reserved (Real Mode IVT, BDA)
;---------------------------------------------------------------------

    bits 16

;---------------------------------------------------
; Stage2 entry-point
;---------------------------------------------------

stage2:
    mov ax, STAGE2_SEG                          ; Set segments to the location of the bootloader
    mov ds, ax
    mov gs, ax
    mov fs, ax
    mov es, ax
    
    cli
    mov ax, STACK_SEG                           ; Get the the defined stack segment address
    mov ss, ax                                  ; Set segment register to the bottom  of the stack
    mov sp, STACK_OFF                           ; Set ss:sp to the top of the 4k stack
    sti
    
    or dl, dl                                   ; Test for a hard disk or floppy
    jz flp

  hda:                                          ; Booted from a hard disk!
    mov si, drive
    call print
    jmp hang
     
  flp:                                          ; Booted from a floppy disk!
    mov si, floppy
    call print
    
  hang:                                         ; Im just going to hang myself here :)
    hlt
    jmp hang
    
;---------------------------------------------------
; Stage2 routines below
;---------------------------------------------------
    
;---------------------------------------------------
print:
;
; Print out a simple string.
;
; @param: SI => String
; @return: None
;
;---------------------------------------------------
    lodsb                                       ; Load byte from si to al
    or al, al                                   ; If al is empty stop looping
    jz .done                                    ; Done looping and return
    mov ah, 0x0e                                ; Teletype output
    int 0x10                                    ; Video interupt
    jmp print                                   ; Loop untill string is null
  .done:
    ret

;---------------------------------------------------
; Stage2 varables below
;---------------------------------------------------
    
    floppy db "Loaded on a floppy disk!", 0
    drive  db "Loaded on a hard drive!", 0

