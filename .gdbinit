#  .gdbinit
#
#  Copyright (c) 2017-2022, Joshua Riek
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

exec-file bin/boot12.elf
add-symbol-file bin/boot12.elf 0x9FA00 -readnow
b reallocatedEntry
set tdesc filename target.xml

target remote localhost:1234

set confirm off
set verbose off
set prompt \033[31mgdb$ \033[0m

set output-radix 0d10
set input-radix 0d10

# These make gdb never pause in its output
set height 0
set width 0

# Intel syntax
set disassembly-flavor intel

# Real mode
set architecture i8086

set $SHOW_CONTEXT = 1

set $REAL_MODE = 1

# By default A20 is present
set $ADDRESS_MASK = 0x1FFFFF

# nb of instructions to display
set $CODE_SIZE = 10

define enable-a20
    set $ADDRESS_MASK = 0x1FFFFF
end
define disable-a20
    set $ADDRESS_MASK = 0x0FFFFF
end

# get current register values
define compute_regs
    set $rax = ((unsigned long)$eax & 0xFFFF)
    set $rbx = ((unsigned long)$ebx & 0xFFFF)
    set $rcx = ((unsigned long)$ecx & 0xFFFF)
    set $rdx = ((unsigned long)$edx & 0xFFFF)
    set $rsi = ((unsigned long)$esi & 0xFFFF)
    set $rdi = ((unsigned long)$edi & 0xFFFF)
    set $rbp = ((unsigned long)$ebp & 0xFFFF)
    set $rsp = ((unsigned long)$esp & 0xFFFF)
    set $rcs = ((unsigned long)$cs & 0xFFFF)
    set $rds = ((unsigned long)$ds & 0xFFFF)
    set $res = ((unsigned long)$es & 0xFFFF)
    set $rss = ((unsigned long)$ss & 0xFFFF)
    set $rip = ((((unsigned long)$cs & 0xFFFF) << 4) + ((unsigned long)$eip & 0xFFFF)) & $ADDRESS_MASK
    set $r_ss_sp = ((((unsigned long)$ss & 0xFFFF) << 4) + ((unsigned long)$esp & 0xFFFF)) & $ADDRESS_MASK
    set $r_ss_bp = ((((unsigned long)$ss & 0xFFFF) << 4) + ((unsigned long)$ebp & 0xFFFF)) & $ADDRESS_MASK
end

# print CPU registers
define print_regs
    printf " [32mAX: [37m0x%04X [32mBX: [37m0x%04X [0m", $rax, $rbx
    printf " [32mCX: [37m0x%04X [32mDX: [37m0x%04X[0m\n", $rcx, $rdx
    printf " [32mSI: [37m0x%04X [32mDI: [37m0x%04X [0m", $rsi, $rdi
    printf " [32mSP: [37m0x%04X [32mBP: [37m0x%04X[0m\n", $rsp, $rbp
    printf " [32mCS: [37m0x%04X [32mDS: [37m0x%04X [0m", $rcs, $rds
    printf " [32mES: [37m0x%04X [32mSS: [37m0x%04X[0m\n", $res, $rss
    printf "\n"
    printf " [32mIP: [37m0x%04X [32mEIP: [37m0x%08X[0m\n", ((unsigned short)$eip & 0xFFFF), $eip
    printf " [32mCS:IP: [37m%04X:%04X (0x%05X)[0m\n", $rcs, ((unsigned short)$eip & 0xFFFF), $rip
    printf " [32mSS:SP: [37m%04X:%04X (0x%05X)[0m\n", $rss, $rsp, $r_ss_sp
    printf " [32mSS:BP: [37m%04X:%04X (0x%05X)[0m\n", $rss, $rbp, $r_ss_bp
end

# print eflags registers
define print_eflags
    printf "\n [32mOF [37m<%d>  [32mDF  [37m<%d> [32mIF  [37m<%d> [32mTF [37m<%d>",\
          (($eflags >> 0xB) & 1), (($eflags >> 0xA) & 1), \
          (($eflags >> 9) & 1), (($eflags >> 8) & 1)
    printf "  [32mSF [37m<%d>  [32mZF [37m<%d>  [32mAF [37m<%d>  [32mPF   [37m<%d>  [32mCF [37m<%d>\n",\
          (($eflags >> 7) & 1), (($eflags >> 6) & 1),\
          (($eflags >> 4) & 1), (($eflags >> 2) & 1), ($eflags & 1)
    printf " [32mID [37m<%d>  [32mVIP [37m<%d> [32mVIF [37m<%d> [32mAC [37m<%d>",\
          (($eflags >> 0x15) & 1), (($eflags >> 0x14) & 1), \
          (($eflags >> 0x13) & 1), (($eflags >> 0x12) & 1)
    printf "  [32mVM [37m<%d>  [32mRF [37m<%d>  [32mNT [37m<%d>  [32mIOPL [37m<%d>\n",\
          (($eflags >> 0x11) & 1), (($eflags >> 0x10) & 1),\
          (($eflags >> 0xE) & 1), (($eflags >> 0xC) & 3)
end

# dump content of memory in words
# arg0 : addr
# arg1 : nb of words
define _dump_memw
    if $argc < 2
        printf "Arguments: address number_of_words\n"
    else
        set $_nb = $arg1
        set $_i = 0
        set $_addr = $arg0
        while ($_i < $_nb)
            printf "%04X ", *((unsigned short*)$_addr + $_i)
            set $_i++
        end
    end
end

# display data at given address
define print_data
    if ($argc > 0)
        set $wil = 4
        if ($argc > 2)
            set $wil = $arg2
        end

        set $seg = $arg0
        set $off = $arg1

        set $raddr = ($arg0 << 16) + $arg1
        set $maddr = ($arg0 << 4) + $arg1

        set $w = 16
        set $i = (int)0
        while ($i < $wil)
            printf "%04X %04X: ", ($seg), ($off+ $i * $w)
            set $j = (int)0
        while ($j < $w)
            printf "%02X ", *(unsigned char*)($maddr + $i * $w + $j)
            set $j++
        end
        printf " "
        set $j = (int)0
        while ($j < $w)
            set $c = *(unsigned char*)($maddr + $i * $w + $j)
            if ($c > 32) && ($c < 128)
                printf "%c", $c
            else
                printf "."
            end
            set $j++
        end
        printf "\n"
        set $i++
        end
    end
end

# print context window, i.e. regs, stack, ds:esi and disassemble cs:eip
define context
    printf "[0;34m--------------------------------------------------------------------------------[1;34m[stack][0m\n"
    _dump_memw $r_ss_sp 8
    printf "\n"
    set $_a = $r_ss_sp + 16
    _dump_memw $_a 8
    printf "\n"
    printf "[0;34m--------------------------------------------------------------------------------[1;34m[ds:si][0m\n"
    print_data $ds $rsi
    printf "[0;34m--------------------------------------------------------------------------------[1;34m[es:di][0m\n"
    print_data $es $rdi
    printf "[0;34m--------------------------------------------------------------------------------[1;34m[regs][0m\n"
    print_regs
    print_eflags
    printf "[0;34m--------------------------------------------------------------------------------[1;34m[code][0m\n"
    set $_code_size = $CODE_SIZE
    if ($_code_size > 0)
        x /i $rip
        set $_code_size--
    end
    while ($_code_size > 0)
        x /i
        set $_code_size--
    end
    printf "[0;34m--------------------------------------------------------------------------------------[0m\n"
end

define hook-stop
    compute_regs
    if ($SHOW_CONTEXT > 0)
        context
    end
end
document hook-stop
!!! FOR INTERNAL USE ONLY - DO NOT CALL !!!
end
