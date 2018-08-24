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

    bits 16

;---------------------------------------------------
; Demo entry-point
;---------------------------------------------------

demo:
    mov ax, cs
    mov ds, ax
    mov es, ax


    mov si, msg
    call print
    
  .stop:
    hlt                                         ; Im just going to hang myself here
    jmp .stop
    
;---------------------------------------------------
; Demo routines below
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
    
    msg db "I can boot things!", 0

