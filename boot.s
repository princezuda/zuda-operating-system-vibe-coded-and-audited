# boot.s - ZudaDOS boot sector (stage 1)
# Loaded by the BIOS at physical 0x7C00 in 16-bit real mode.
# Job: load the kernel from the disk into 0x1000:0x0000 and jump to it.
#
# Assembled flat (no ELF) and placed in the first 512 bytes of the disk.
# The 0xAA55 signature at offset 510 marks it bootable.

    .code16
    .intel_syntax noprefix
    .global _start

_start:
    cli
    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0x7C00          # stack grows down from below the boot code
    sti

    mov     [boot_drive], dl    # BIOS passes the boot drive number in DL

    mov     si, offset msg_load
    call    print

    # Reset the disk system before reading.
    xor     ax, ax
    mov     dl, [boot_drive]
    int     0x13

    # Read the kernel: 17 sectors starting at sector 2 (LBA 1), cyl 0, head 0.
    # Destination = 0x1000:0x0000 (physical 0x10000).
    # 17 sectors keeps boot(1) + kernel(17) = 18 = one floppy track, so the
    # whole load stays on cylinder 0 / head 0 and we avoid CHS wraparound.
    mov     ax, 0x1000
    mov     es, ax
    xor     bx, bx
    mov     ah, 0x02            # BIOS read sectors
    mov     al, 17              # sector count
    mov     ch, 0               # cylinder 0
    mov     cl, 2               # start sector (1-based)
    mov     dh, 0               # head 0
    mov     dl, [boot_drive]
    int     0x13
    jc      disk_err

    # Read more tracks so the kernel has room to grow. Each int 0x13 stays
    # within one track (no CHS boundary crossing). Layout in memory is
    # contiguous from 0x1000:0x0000:
    #   track A: cyl 0 head 0, 17 sectors (already loaded above)  -> LBA 1..17
    #   track B: cyl 0 head 1, 18 sectors                          -> LBA 18..35
    #   track C: cyl 1 head 0, 18 sectors                          -> LBA 36..53
    mov     bx, 17 * 512        # just past track A
    mov     ah, 0x02
    mov     al, 18
    mov     ch, 0               # cylinder 0
    mov     cl, 1
    mov     dh, 1               # head 1
    mov     dl, [boot_drive]
    int     0x13
    jc      disk_err

    mov     bx, 35 * 512        # just past tracks A+B
    mov     ah, 0x02
    mov     al, 18
    mov     ch, 1               # cylinder 1
    mov     cl, 1
    mov     dh, 0               # head 0
    mov     dl, [boot_drive]
    int     0x13
    jc      disk_err

    mov     bx, 53 * 512        # track D: cyl 1 head 1 (LBA 54..71)
    mov     ah, 0x02
    mov     al, 18
    mov     ch, 1               # cylinder 1
    mov     cl, 1
    mov     dh, 1               # head 1
    mov     dl, [boot_drive]
    int     0x13
    jc      disk_err

    mov     si, offset msg_ok
    call    print

    # Hand control to the kernel: far jump to 0x1000:0x0000 with DL = drive.
    mov     dl, [boot_drive]
    .byte   0xEA                # far JMP imm16:imm16
    .word   0x0000             # offset
    .word   0x1000             # segment

disk_err:
    mov     si, offset msg_err
    call    print
hang:
    hlt
    jmp     hang

# print: write the NUL-terminated string at DS:SI via BIOS teletype.
print:
    push    ax
    push    bx
    mov     ah, 0x0E
    mov     bx, 0x0007
.pn:
    lodsb
    test    al, al
    jz      .pd
    int     0x10
    jmp     .pn
.pd:
    pop     bx
    pop     ax
    ret

boot_drive: .byte 0
msg_load:   .asciz "ZudaDOS: loading kernel...\r\n"
msg_ok:     .asciz "ZudaDOS: kernel loaded.\r\n"
msg_err:    .asciz "ZudaDOS: disk read error. Halted.\r\n"

    # Pad to 510 bytes, then the boot signature.
    . = _start + 510
    .word   0xAA55
