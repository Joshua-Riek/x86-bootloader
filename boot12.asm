;  boot12.asm
;
;  This FAT12 bootlader is currently configured for a 1440k floppy disk   
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
    
    %ifidn __OUTPUT_FORMAT__, elf32
      %define BOOT_SEG 0x0000                   ; Set the bootloader segments to zero when
    %else                                       ; the elf format is used (compiled with -Ttext=0x7c00),
      %define BOOT_SEG 0x07c0                   ; which is only used for debugging
    %endif

    %define STACK_SEG  0x0600                   ; (STACK_SEG * 0x10) + STACK_OFF = 0x7000
    %define STACK_OFF  0x1000

    %define BUFFER_SEG 0x07c0                   ; (BUFFER_SEG * 0x10) + BUFFER_OFF = 0x8000
    %define BUFFER_OFF 0x0400

    %define LOAD_SEG   0x0100                   ; (LOAD_SEG * 0x10) + STAEG2_OFF = 0x1000
    %define LOAD_OFF   0x0000
	
;---------------------------------------------------------------------
; Bootloader Memory Map
;---------------------------------------------------------------------
; Linear Address | Item
;       0x100000 | Top of memory hole
;       0x0f0000 | Video memory, MMIO, BIOS	
;       0x0a0000 | Bottom of memory hole
;       0x090000 | 
;       0x010000 | 
;       0x00f000 | 
;       0x00e000 | Load stack 8k         (top: 0xf000)
;       0x00d000 |              :
;       0x00c000 | Disk buffer 18k       (ends: 0xc7ff)
;       0x00b000 |              :
;       0x00a000 |              :
;       0x009000 |              :
;       0x008000 | Disk buffer 18k       (starts: 0x8000)
; ====> 0x007000 | Boot location between (0x7c00-0x7dff)
;       0x006000 | Boot stack 4k         (top: 0x7000)
;       0x005000 |              
;       0x004000 | Load location 14k     (ends: 0x47ff)
;       0x003000 |              :
;       0x002000 |              :
;       0x001000 | Load location 14k     (starts: 0x1000)
;       0x000000 | Reserved (Real Mode IVT, BDA)
;---------------------------------------------------------------------

    bits 16
 
;---------------------------------------------------
; Disk description table
;---------------------------------------------------

    jmp short bootStrap                         ; Jump over OEM / BIOS param block
    nop

    OEMName           db "CUCK ME "             ; Disk label
    bytesPerSector    dw 512                    ; Bytes per sector
    sectorsPerCluster db 1                      ; Sectors per cluster
    reservedSectors   dw 1                      ; Reserved sectors
    fats              db 2                      ; Number of fats
    rootDirEntries    dw 224                    ; Number of entries in root dir
    sectors           dw 2880                   ; Logical sectors
    mediaType         db 0xf0                   ; Media descriptor byte
    fatSectors        dw 9                      ; Sectors per FAT
    sectorsPerTrack   dw 18                     ; Sectors per track
    heads             dw 2                      ; Number of sides/heads
    hiddenSectors     dd 0                      ; Hidden sectors
    hugeSectors       dd 0                      ; LBA sectors
    biosDriveNum      db 0                      ; Drive number
    reserved          db 0                      ; This is not used
    bootSignature     db 41                     ; Drive signature
    volumeId          dd 0xdeadbeef             ; Volume ID
    volumeLabel       db "           "          ; Volume Label
    fatTypeLabel      db "FAT12   "             ; File system type

;---------------------------------------------------
; Start of the main bootloader code and entry point
;---------------------------------------------------
    
bootStrap:
    mov ax, BOOT_SEG                            ; Set segments to the location of the bootloader
    mov ds, ax
    mov gs, ax
    mov fs, ax
    
    mov bx, BUFFER_SEG                          ; NOTE: Must force the extra segment here, because when
    mov es, bx                                  ; debugging with gdb, the flag -Ttext=0x7c00 adjusts segments
    
    cli
    mov ax, STACK_SEG                           ; Get the the defined stack segment address
    mov ss, ax                                  ; Set segment register to the bottom  of the stack
    mov sp, STACK_OFF                           ; Set ss:sp to the top of the 4k stack
    sti
    
    or dl, dl                                   ; When booting from a hard drive, some of the 
    jz loadRoot                                 ; you need to call int 13h to fix some bpb entries

    mov byte [drive], dl                        ; Save boot device number

    mov ah, 8                                   ; Get Drive Parameters func of int 13h
    int 0x13                                    ; Call int 13h (BIOS disk I/O)
    jc loadRoot

    and cx, 0x003f                              ; Maximum sector number is the high bits 6-7 of cl
    mov word [sectorsPerTrack], cx              ; And whose low 8 bits are in ch

    movzx dx, dh                                ; Convert the maximum head number to a word
    add dx, 1                                   ; Head numbers start at zero, so add one
    mov word [heads], dx                        ; Save the head number
    
;---------------------------------------------------
; Load the root directory from the disk
;---------------------------------------------------

loadRoot:
    xor cx, cx

    mov ax, 32                                  ; Size of root dir = (rootDirEntries * 32) / bytesPerSector
    mul word [rootDirEntries]                   ; Multiply by the total size of the root directory
    div word [bytesPerSector]                   ; Divided by the number of bytes used per sector
    xchg cx, ax
        
    mov al, byte [fats]                         ; Location of root dir = (fats * fatSectors) + reservedSectors
    mul word [fatSectors]                       ; Multiply by the sectors used
    add ax, word [reservedSectors]              ; Increase ax by the reserved sectors

    mov word [userData], ax                     ; start of user data = startOfRoot + numberOfRoot
    add word [userData], cx                     ; Therefore, just add the size and location of the root directory

    mov bx, BUFFER_OFF                          ; Set es:bx and load the root directory into the disk buffer
    call readSectors                            ; Read the sectors

;---------------------------------------------------
; Find the file to load from the loaded root dir
;---------------------------------------------------
    
loadedRoot:
    mov di, BUFFER_OFF                          ; Set es:di to the 18k disk buffer
    
    mov cx, word [rootDirEntries]               ; Search through all of the root dir entrys for the kernel
    xor ax, ax                                  ; Clear ax for the file entry offset

  searchRoot:
    xchg cx, dx                                 ; Save current cx value to look for the filename
    mov si, filename                            ; Load the filename
    mov cx, 11                                  ; Compare first 11 bytes
    rep cmpsb                                   ; Compare si and di cx times
    je loadFat                                  ; We found the file :)

    add ax, 32                                  ; File entry offset
    mov di, BUFFER_OFF                          ; Point back to the start of the entry
    add di, ax                                  ; Add the offset to point to the next entry
    xchg dx, cx
    loop searchRoot                             ; Continue to search for the file

    mov si, fileNotFound                        ; Could not find the file
    call print
    jmp reboot
    
;---------------------------------------------------
; Load the fat from the found file   
;--------------------------------------------------

loadFat:
    mov ax, word [es:di + 15]                   ; Get the file cluster at offset 26
    mov word [cluster], ax                      ; Store the FAT cluster
    
    xor ax, ax                                  ; Size of fat = (fats * fatSectors)
    mov al, byte [fats]                         ; Move number of fats into al
    mul word [fatSectors]                       ; Move fat sectors into bx
    mov cx, ax                                  ; Store in cx
    
    mov ax, word [reservedSectors]              ; Convert the first fat on the disk

    mov bx, BUFFER_OFF                          ; Set es:bx and load the fat sectors into the disk buffer
    call readSectors                            ; Read the sectors

;---------------------------------------------------
; Load the clusters of the file and jump to it
;---------------------------------------------------
    
loadedFat:
    mov si, BUFFER_SEG                          ; The ds register is ebing used by the local vars,
    mov gs, si                                  ; so i will just use the gs regsiter
    
    mov ax, LOAD_SEG
    mov es, ax                                  ; Set es:bx to where the file will load (0x1000:0x0000)
    xor bx, bx
    
  loadFileSector:
    xor dx, dx
    xor cx, cx

    mov ax, word [cluster]                      ; Get the cluster start = (cluster - 2) * sectorsPerCluster + userData
    sub ax, 2                                   ; Subtract 2
    mov bl, byte [sectorsPerCluster]            ; Sectors per cluster is a byte value
    mul bx                                      ; Multiply (cluster - 2) * sectorsPerCluster
    add ax, word [userData]                     ; Add the userData 
    
    mov cl, byte [sectorsPerCluster]            ; Sectors to read
    mov bx, LOAD_SEG                          ; Segment address of the buffer
    mov es, bx                                  ; Point es:bx to where we will load
    mov bx, word [pointer]                      ; Increase the buffer by the pointer offset
    call readSectors                            ; Read the sectors

  calculateNextSector:
    mov ax, word [cluster]                      ; Current cluster number
    xor dx, dx                                  ; We want to multiply by 1.5 (6/4 is equal to 1.5)
    mov bx, 6                                   ; Multiply the cluster by the numerator
    mul bx                                      ; Return value in ax and remainder in dx
    mov bx, 4                                   ; Divide the cluster by the denominator
    div bx    
   
    mov si, BUFFER_OFF                          ; Get the fat entry in gs:si
    add si, ax                                  ; Point to the next cluster in the FAT entry
    mov ax, word [gs:si]                        ; Load ax to the next cluster in FAT

    or dx, dx                                   ; Is the cluster caluclated even?
    jz evenSector

  oddSector:
    shr ax, 4                                   ; Drop the first 4 bits of the next cluster
    jmp nextSectorCalculated

  evenSector:
    and ax, 0x0fff                              ; Drop the last 4 bits of next cluster

  nextSectorCalculated:
    mov word [cluster], ax                      ; Store the new cluster

    cmp ax, 0x0ff8                              ; Are we at the end of the file?
    jae fileJump

    add word [pointer], 512                     ; Add to the pointer offset
    jmp loadFileSector                          ; Load the next file sector

  fileJump:
    mov dl, byte [drive]                        ; We still need the boot device info
    jmp LOAD_SEG:LOAD_OFF                   ; Jump to the file loaded!

    hlt                                         ; This should never be hit


;---------------------------------------------------
; Bootloader routines below
;---------------------------------------------------


;---------------------------------------------------
readSectors:
;
; Read sectors starting at a given sector by 
; the given times and load into a buffer.
;
; @param: CX => Number of sectors to read
; @param: AX => Starting sector
; @param: ES:BX => Buffer to read to
; @return: None
;
;---------------------------------------------------
    pusha

  .sectorMain:
    mov di, 5                                   ; Try five times to read the sector

  .sectorLoop:
    pusha
    push ax                                     ; Calculate absoluteSector
    xor dx, dx                                  ; Prep ax:dx for output
    div word [sectorsPerTrack]                  ; Divide LBA by SectorsPerTrack
    inc dl                                      ; Add one to output
    mov cl, dl                                  ; Move the absoluteSector to cl for int 13h

    pop ax                                      ; Calculate absoluteHead and absoluteTrack
    xor dx, dx                                  ; Prep ax:dx for output
    div word [sectorsPerTrack]                  ; Divide LBA by SectorsPerTrack
    xor dx, dx                                  ; Prep ax:dx for output
    div word [heads]                            ; Now divide by Heads
    mov dh, dl                                  ; Move the absoluteHead to dh for int 13h
    mov ch, al                                  ; Move the absoluteTrack to ch for int 13h

    mov dl, byte [drive]                        ; Set correct device for int 13h
    mov ax, 0x0201                              ; Read Sectors func of int 13h, read one sector

    int 0x13                                    ; Call int 13h (BIOS disk I/O)
    jnc .sectorRead                             ; If no carry set, the sector has been read

    xor ah, ah                                  ; Reset Drive func of int 13h
    int 0x13                                    ; Call int 13h (BIOS disk I/O)
    popa
    
    dec di                                      ; Decrease read attempt counter

    jnz .sectorLoop                             ; Try to read the sector again
    jmp reboot

  .sectorRead:
    popa
    add bx, word [bytesPerSector]               ; Add to the buffer address for the next sector
    inc ax                                      ; Increase the next sector to read
    loop .sectorMain                            ; Read next sector for cx times

    popa
    ret

;---------------------------------------------------
reboot:
;
; What the fuck do you think this does. 
;
; @return: None
;
;---------------------------------------------------
    xor ax, ax
    int 0x16                                    ; Get a single keypress

    xor ax, ax
    int 0x19                                    ; Reboot the system


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
; Bootloader varables below
;---------------------------------------------------


    filename       db "DEMO    BIN"             ; Kernel/Stage2 bootloader filename 
    fileNotFound   db "File not found!", 0

    userData       dw 0                         ; Start of the data sectors
    drive          db 0                         ; Boot device number
    cluster        dw 0                         ; Cluster of the file that is being loaded
    pointer        dw 0                         ; Pointer into Buffer, for loading the file

                   times 510 - ($ - $$) db 0    ; Pad remainder of boot sector with zeros
                   dw 0xaa55                    ; Boot signature
