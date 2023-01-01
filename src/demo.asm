;  demo.asm
;
;  This is just a demo file for the bootloader
;  Copyright (c) 2017-2023, Joshua Riek
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

    bits 16                                     ; Ensure 16-bit code
    cpu  8086                                   ; Assemble with the 8086 instruction set

;---------------------------------------------------
; Demo entry-point
;---------------------------------------------------

demo:
    mov ax, cs
    mov ds, ax                                  ; Just set the segments equal to the code segment 
    mov es, ax

    xor bx, bx
    mov ah, 0x0e                                ; Teletype output
    mov al, 0x4f
    int 0x10                                    ; Video interupt
    mov al, 0x77
    mov ah, 0x0e 
    int 0x10                                    ; Video interupt
    mov al, 0x4f
    mov ah, 0x0e 
    int 0x10                                    ; Video interupt

    xor ax, ax
    int 0x16                                    ; Get a single keypress

    xor bx, bx
    mov ah, 0x0e                                ; Teletype output
    mov al, 0x0d                                ; Carriage return
    int 0x10                                    ; Video interupt
    mov al, 0x0a                                ; Line feed
    int 0x10                                    ; Video interupt
    mov al, 0x0a                                ; Line feed
    int 0x10                                    ; Video interupt

    xor ax, ax
    int 0x19                                    ; Reboot the system

    hlt
