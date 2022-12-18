;  boot16.asm
;
;  This program is a FAT16 bootloader
;  Copyright (c) 2017-2022, Joshua Riek
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

    %define LOAD_ADDR   0x001000                ; Physical load address (where the program loads)

    %define LOAD_SEG    (LOAD_ADDR >> 4)        ; (LOAD_SEG   << 4) + LOAD_OFF   = LOAD_ADDR
    %define LOAD_OFF    (LOAD_ADDR & 0xf)
    
    bits 16                                     ; Ensure 16-bit code
    cpu  8086                                   ; Assemble with the 8086 instruction set

;---------------------------------------------------
; Disk description table
;---------------------------------------------------

    jmp short _start                            ; Jump over OEM / BIOS param block
    nop

    %define OEMName           bp+0x03           ; Disk label
    %define bytesPerSector    bp+0x0b           ; Bytes per sector
    %define sectorsPerCluster bp+0x0d           ; Sectors per cluster
    %define reservedSectors   bp+0x0e           ; Reserved sectors
    %define fats              bp+0x10           ; Number of fats
    %define rootDirEntries    bp+0x11           ; Number of entries in root dir
    %define sectors           bp+0x13           ; Logical sectors
    %define mediaType         bp+0x15           ; Media descriptor byte
    %define fatSectors        bp+0x16           ; Sectors per FAT
    %define sectorsPerTrack   bp+0x18           ; Sectors per track
    %define heads             bp+0x1a           ; Number of sides/heads
    %define hiddenSectors     bp+0x1c           ; Hidden sectors
    %define hugeSectors       bp+0x20           ; LBA sectors
    %define biosDriveNum      bp+0x24           ; Drive number
    %define reserved          bp+0x25           ; This is not used
    %define bootSignature     bp+0x26           ; Drive signature
    %define volumeId          bp+0x27           ; Volume ID
    %define volumeLabel       bp+0x2b           ; Volume Label
    %define fatTypeLabel      bp+0x36           ; File system type
    
    times 0x3b db 0x00

;---------------------------------------------------
; Start of the main bootloader code and entry point
;---------------------------------------------------

global _start
_start:
    cld

    int 0x12                                    ; Get Conventional memory size in kb
    
    mov cl, 6                                   ; Shift bits left (ax*(2^6))
    shl ax, cl                                  ; Convert the memory to 16-byte paragraphs

    sub ax, 512 >> 4                            ; Reserve 512 bytes for the boot sector
    mov es, ax                                  ; Set the segment register to the new boot sector location
    xor di, di                                  ; Now es:di points to the new bs

    mov ds, di                                  ; Set the segment register to the current boot sector location
    mov si, 0x7c00                              ; Now ds:si points to the current bs
    
    sub ax, 4096 >> 4                           ; Reserve 4k bytes for the stack 
    mov ss, ax                                  ; Set segment register to the bottom of the stack
    mov sp, 4096                                ; Now ss:sp points to the top of the 4k stack

    mov cx, 256                                 ; 256 words (512 bytes)
    rep movsw                                   ; Copy cx times from ds:si to es:di

    mov ax, reallocatedEntry                    ; Now we want to jump to this label

    push es                                     ; The new Code Segment
    push ax                                     ; The new Instruction Pointer
    retf                                        ; Far jump to the reallocated boot sector! 

;---------------------------------------------------
; Jump here after allocating the boot sector
;---------------------------------------------------

reallocatedEntry:
    push cs
    pop ds

    mov bp, sp                                  ; Correct bp for the disk description table

    mov byte [drive], dl                        ; Save boot device number

    xor di, di                                  ; To guard against BIOS bugs
    mov es, di                                  ; http://www.ctyme.com/intr/rb-0621.htm

    mov ah, 0x08                                ; Get Drive Parameters func of int 13h
    int 0x13                                    ; Call int 13h (BIOS disk I/O)
    jc loadRoot

    and cx, 0x003f                              ; Maximum sector number is the high bits 6-7 of cl
    mov word [sectorsPerTrack], cx              ; And whose low 8 bits are in ch

    mov dl, dh                                  ; Convert the maximum head number to a word
    xor dh, dh
    inc dx                                      ; Head numbers start at zero, so add one
    mov word [heads], dx                        ; Save the head number

;---------------------------------------------------
; Reserve memory for the disk buffer and FAT (128kb max)
;---------------------------------------------------

allocDiskbuffer:
    xor ax, ax
    mov dx, ax                                  ; Calculate the size of fat in sectors
    mov al, byte [fats]                         ; Take the number of fats
    mul word [fatSectors]                       ; And multiply that by the number of sectors per fat

    push ax                                     ; Save the size of the fat in sectors for later 
    push ax                                     ; Save it again to calculate the starting sector of the root dir

    mov bx, word [bytesPerSector]               ; Get the size of fat in 16-byte paragraphs
    mov cl, 4                                   ; Shift bits left (ax*(2^4))
    shr bx, cl                                  ; Align to 16-byte paragraphs
    mul bx

    mov di, ss                                  ; Allocate space after the stack
    sub di, ax                                  ; Reserve (ax*(2^4)) bytes for the disk buffer 
    
    mov es, di                                  ; Set the segment register to the disk buffer location
    xor di, di                                  ; Now es:di points to the allocated disk buffer 

;---------------------------------------------------
; Load the root directory from the disk
;---------------------------------------------------

loadRoot:
    pop cx
    add cx, word [reservedSectors]              ; Increase cx by the reserved sectors

    xor dx, dx
    mov ax, 32                                  ; Calculate the size of the root dir in sectors
    mul word [rootDirEntries]                   ; Multiply the number of root dir entries by 32
    div word [bytesPerSector]                   ; Divide by the number of bytes used per sector
    xchg cx, ax

    mov word [startOfData], ax                  ; Calculate the first data sector
    add word [startOfData], cx                  ; Just add the size and location of the root dir

    xor dx, dx
    call readSectors                            ; Load the root directory into the disk buffer

;---------------------------------------------------
; Find the file to load from the loaded root dir
;---------------------------------------------------

findFile:
    mov dx, word [rootDirEntries]               ; Search through all of the root dir entrys for the kernel
    push di

  .searchRoot:
    push di
    mov si, filename                            ; Load the filename
    mov cx, 11                                  ; Compare first 11 bytes
    rep cmpsb                                   ; Compare si and di cx times
    pop di
    je loadFat                                  ; We found the file :)

    add di, 32                                  ; Point to the next entry
    dec dx                                      ; Continue to search for the file
    jnz .searchRoot

    jmp error                                   ; Could not find the file

;---------------------------------------------------
; Load the fat from the found file   
;--------------------------------------------------

loadFat:
    mov bx, word [es:di+26]                     ; Get the file cluster at offset 26

    pop di                                      ; Offset into disk buffer
    pop cx                                      ; Size of fat in sectors

    xor dx, dx
    mov ax, word [reservedSectors]              ; Convert the first fat on the disk
    call readSectors                            ; load the fat sectors into the disk buffer

;---------------------------------------------------
; Load the clusters of the file and jump to it
;---------------------------------------------------

loadFile:
    mov si, es
    mov ds, si                                  ; Set ds:si to the loaded fat
    mov si, di

    mov di, LOAD_SEG
    mov es, di                                  ; Set es:di to where the file will load
    mov di, LOAD_OFF

    push es
    push di                                     ; Push the load addr to the stack 

    mov ax, bx                                  ; File cluster
    call readClusters                           ; Read clusters from the file

    mov dl, byte [cs:drive]                     ; Pass the boot drive into dl
    retf                                        ; Far jump to the file loaded!

    hlt                                         ; This should never be hit 


;---------------------------------------------------
; Bootloader routines below
;---------------------------------------------------


;---------------------------------------------------
readClusters:
;
; Read file clusters, starting at the given cluster,
; expects FAT to be loaded into the disk buffer.
;
; Expects: DS:SI = Location of FAT
;          ES:DI = Location to load clusters
;          AX    = Starting cluster
;
; Returns: None
;
;--------------------------------------------------
  .clusterLoop:
    push ax

    dec ax
    dec ax
    xor dx, dx
    xor bh, bh                                  ; Calculate the first sector of the given cluster in ax
    mov bl, byte [sectorsPerCluster]            ; First subtract 2 from the cluster
    mul bx                                      ; Multiply the cluster by the sectors per cluster
    add ax, word [cs:startOfData]               ; Finally add the first data sector

    xor ch, ch
    mov cl, byte [sectorsPerCluster]            ; Sectors to read
    call readSectors                            ; Read the sectors

    pop ax

  .loadNextCluster:
    push ds
    push si

    xor dx, dx
    mov cx, 2                                   ; Get the next cluster for FAT16 
    mul cx                                      ; Multiply the cluster by 2

    xor bx, bx
    add si, ax                                  ; Add the offset into the FAT16 table
    adc bx, dx                                  ; Make sure to adjust for carry 

    mov cl, 4
    shl bl, cl                                  ; Correct the segment based on the offset into the FAT16 table
    mov dx, ds                                  ; Shift left by 4 bits
    add dh, bl                                  ; Then add the higher half to the segment
    mov ds, dx

    mov ax, word [ds:si]                        ; Load ax to the next cluster in the FAT16 table

    pop si
    pop ds

  .nextClusterCalculated:
    cmp ax, 0xfff8                              ; Are we at the end of the file?
    jae .done

    xchg bx, ax
    xor dx, dx
    xor ah, ah                                  ; Calculate the size in bytes per cluster
    mov al, byte [sectorsPerCluster]            ; So, take the sectors per cluster
    mul word [bytesPerSector]                   ; And mul that by the bytes per sector
    xchg bx, ax                                 ; Bytes per cluster in bx:dx

    mov cl, 4
    shl dx, cl                                  ; Correct the segment offset based on the bytes per cluster
    mov cx, es                                  ; Shift left by 4 bits
    add ch, dl                                  ; Then add the lower half to the segment
    mov es, cx

    clc                                         ; Add to the pointer offset
    add di, bx
    jnc .clusterLoop 

  .fixBuffer:                                   ; An error will occur if the buffer in memory
    mov dx, es                                  ; overlaps a 64k page boundry, when di overflows
    add dh, 0x10                                ; it will trigger the carry flag, so correct
    mov es, dx                                  ; extra segment by 0x1000

    jmp .clusterLoop                            ; Load the next file cluster

  .done:
    ret

;---------------------------------------------------
readSectors:
;
; Read sectors starting at a given sector by 
; the given times and load into a buffer.
;
; Expects: AX:DX = Starting sector/ lba
;          ES:DI = Location to load sectors
;          CX    = Number of sectors to read
;
; Returns: None
;
;--------------------------------------------------
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov bx, di                                  ; Convert es:di to es:bx for int 13h

  .sectorLoop:
    push ax
    push cx
    push dx

    div word [sectorsPerTrack]                  ; Divide the lba (value in ax:dx) by sectorsPerTrack
    mov cx, dx                                  ; Save the absolute sector value 
    inc cx

    xor dx, dx                                  ; Divide by the number of heads
    div word [heads]                            ; to get absolute head and track values
    mov dh, dl                                  ; Move the absolute head into dh

    mov ch, al                                  ; Low 8 bits of absolute track
    push cx
    mov cl, 6                                   ; High 2 bits of absolute track
    shl ah, cl
    pop cx
    or cl, ah                                   ; Now cx is set with respective track and sector numbers

    mov dl, byte [cs:drive]                     ; Set correct drive for int 13h

    mov di, 5                                   ; Try five times to read the sector

  .attemptRead:
    mov ax, 0x0201                              ; Read Sectors func of int 13h, read one sector
    int 0x13                                    ; Call int 13h (BIOS disk I/O)
    jnc .readOk                                 ; If no carry set, the sector has been read

    xor ah, ah                                  ; Reset Drive func of int 13h
    int 0x13                                    ; Call int 13h (BIOS disk I/O)

    dec di                                      ; Decrease read attempt counter
    jnz .attemptRead                            ; Try to read the sector again

    push cs
    pop ds

    jmp error                                   ; Error reading the disk

  .readOk:
    pop dx
    pop cx
    pop ax

    clc
    add ax, 1                                   ; Add one for the the next lba value
    adc dx, 0                                   ; Make sure to adjust dx for carry

    clc
    add bx, word [bytesPerSector]               ; Add to the buffer address for the next sector
    jnc .nextSector 

  .fixBuffer:
    push dx                                     ; An error will occur if the buffer in memory
    mov dx, es                                  ; overlaps a 64k page boundry, when di overflows
    add dh, 0x10                                ; it will trigger the carry flag, so correct
    mov es, dx                                  ; es segment by 0x1000
    pop dx

  .nextSector:
    loop .sectorLoop

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

;---------------------------------------------------
print:
;
; Print out a simple string.
;
; Expects: DS:SI = String to print
;
; Returns: None
;
;---------------------------------------------------
    lodsb                                       ; Load byte from ds:si to al
    or al, al                                   ; If al is empty stop looping
    jz .done                                    ; Done looping and return
    mov ah, 0x0e                                ; Teletype output
    int 0x10                                    ; Video interupt
    jmp print                                   ; Loop untill string is null
  .done:
    ret


;---------------------------------------------------
error:
;
; Print out an error message and wait for input
; before rebooting.
;
; Expects: None
;
; Returns: None
;
;---------------------------------------------------
    mov si, errorMsg
    call print

    xor ax, ax
    int 0x16                                    ; Get a single keypress

    mov ah, 0x0e                                ; Teletype output
    mov al, 0x0d                                ; Carriage return
    int 0x10                                    ; Video interupt
    mov al, 0x0a                                ; Line feed
    int 0x10                                    ; Video interupt
    int 0x10                                    ; Video interupt

    xor ax, ax
    int 0x19                                    ; Reboot the system

    hlt


;---------------------------------------------------
; Bootloader varables below
;---------------------------------------------------

    errorMsg       db "Error!", 0               ; Error reading disk or file was not found

    startOfData    dw 0                         ; Start of the data sectors
    drive          db 0                         ; Boot drive number

    filename       db "DEMO    BIN"             ; Filename

                   times 510 - ($ - $$) db 0    ; Pad remainder of boot sector with zeros
                   dw 0xaa55                    ; Boot signature
