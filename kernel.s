# kernel.s - ZudaDOS kernel (stage 2)
# Loaded by boot.s at 0x1000:0x0000 in 16-bit real mode.
# A tiny DOS-style command shell built entirely on BIOS interrupts:
#   int 0x10 - video (teletype output, set mode)
#   int 0x16 - keyboard (blocking read)
#   int 0x1A - real-time clock (time/date)
#
# Commands: HELP CLS VER ECHO DIR ABOUT TIME DATE REBOOT HALT

    .code16
    .intel_syntax noprefix
    .global _start

_start:
    # Set up segments: DS = ES = CS, and a fresh stack at the top of the 64K
    # segment. The kernel image is only a few KB, so the stack never reaches it.
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    cli
    mov     ss, ax
    mov     sp, 0xFFFE
    sti

    mov     [boot_drive], dl    # boot sector left the BIOS drive number in DL

    call    cls
    mov     si, offset banner
    call    puts
    mov     si, offset boot_msg
    call    puts
    # ~1.5s window: press ESC to drop to the DOS prompt instead of the desktop
    xor     ah, ah
    int     0x1A
    mov     [boot_ticks], dx
.boot_w:
    mov     ah, 0x01
    int     0x16
    jz      .boot_nk
    xor     ah, ah
    int     0x16
    cmp     al, 0x1B
    je      shell_loop
.boot_nk:
    xor     ah, ah
    int     0x1A
    mov     ax, dx
    sub     ax, [boot_ticks]
    cmp     ax, 27
    jb      .boot_w
    jmp     do_desktop

shell_loop:
    # if we came from a desktop-launched app, return to the desktop
    cmp     byte ptr [in_desktop], 0
    je      .sl_prompt
    jmp     do_desktop
.sl_prompt:
    mov     si, offset prompt
    call    puts
    call    read_line

    # Locate the argument (text after the first space) for ECHO.
    mov     bx, offset cmdbuf
    call    find_arg            # -> DX = arg pointer

    # Ignore empty input.
    mov     al, [cmdbuf]
    test    al, al
    jz      shell_loop

    mov     di, offset cmdbuf
    mov     si, offset kw_help
    call    match
    test    al, al
    jnz     do_help

    mov     di, offset cmdbuf
    mov     si, offset kw_cls
    call    match
    test    al, al
    jnz     do_cls

    mov     di, offset cmdbuf
    mov     si, offset kw_ver
    call    match
    test    al, al
    jnz     do_ver

    mov     di, offset cmdbuf
    mov     si, offset kw_echo
    call    match
    test    al, al
    jnz     do_echo

    mov     di, offset cmdbuf
    mov     si, offset kw_dir
    call    match
    test    al, al
    jnz     do_dir

    mov     di, offset cmdbuf
    mov     si, offset kw_about
    call    match
    test    al, al
    jnz     do_about

    mov     di, offset cmdbuf
    mov     si, offset kw_time
    call    match
    test    al, al
    jnz     do_time

    mov     di, offset cmdbuf
    mov     si, offset kw_date
    call    match
    test    al, al
    jnz     do_date

    mov     di, offset cmdbuf
    mov     si, offset kw_reboot
    call    match
    test    al, al
    jnz     do_reboot

    mov     di, offset cmdbuf
    mov     si, offset kw_halt
    call    match
    test    al, al
    jnz     do_halt

    mov     di, offset cmdbuf
    mov     si, offset kw_snake
    call    match
    test    al, al
    jnz     do_snake

    mov     di, offset cmdbuf
    mov     si, offset kw_play
    call    match
    test    al, al
    jnz     do_play

    mov     di, offset cmdbuf
    mov     si, offset kw_edit
    call    match
    test    al, al
    jnz     do_edit

    mov     di, offset cmdbuf
    mov     si, offset kw_eliza
    call    match
    test    al, al
    jnz     do_eliza

    mov     di, offset cmdbuf
    mov     si, offset kw_basic
    call    match
    test    al, al
    jnz     do_basic

    mov     di, offset cmdbuf
    mov     si, offset kw_gui
    call    match
    test    al, al
    jnz     do_gui

    mov     di, offset cmdbuf
    mov     si, offset kw_paint
    call    match
    test    al, al
    jnz     do_paint

    mov     di, offset cmdbuf
    mov     si, offset kw_desktop
    call    match
    test    al, al
    jnz     do_desktop

    mov     di, offset cmdbuf
    mov     si, offset kw_calc
    call    match
    test    al, al
    jnz     do_calc

    mov     di, offset cmdbuf
    mov     si, offset kw_mem
    call    match
    test    al, al
    jnz     do_mem

    mov     di, offset cmdbuf
    mov     si, offset kw_beep
    call    match
    test    al, al
    jnz     do_beep

    mov     di, offset cmdbuf
    mov     si, offset kw_uptime
    call    match
    test    al, al
    jnz     do_uptime

    mov     di, offset cmdbuf
    mov     si, offset kw_dice
    call    match
    test    al, al
    jnz     do_dice

    mov     di, offset cmdbuf
    mov     si, offset kw_cowsay
    call    match
    test    al, al
    jnz     do_cowsay

    mov     di, offset cmdbuf
    mov     si, offset kw_fortune
    call    match
    test    al, al
    jnz     do_fortune

    mov     di, offset cmdbuf
    mov     si, offset kw_sysinfo
    call    match
    test    al, al
    jnz     do_sysinfo

    mov     di, offset cmdbuf
    mov     si, offset kw_matrix
    call    match
    test    al, al
    jnz     do_matrix

    mov     di, offset cmdbuf
    mov     si, offset kw_guess
    call    match
    test    al, al
    jnz     do_guess

    mov     di, offset cmdbuf
    mov     si, offset kw_daw
    call    match
    test    al, al
    jnz     do_daw

    # Unknown command - classic DOS error.
    mov     si, offset msg_bad
    call    puts
    jmp     shell_loop

# ---- command handlers ----

do_help:
    mov     si, offset msg_help
    call    puts
    jmp     shell_loop

do_cls:
    call    cls
    jmp     shell_loop

do_ver:
    mov     si, offset msg_ver
    call    puts
    jmp     shell_loop

do_echo:
    mov     si, dx
    call    puts
    call    newline
    jmp     shell_loop

do_dir:
    mov     si, offset msg_dir
    call    puts
    jmp     shell_loop

do_about:
    mov     si, offset msg_about
    call    puts
    jmp     shell_loop

do_time:
    mov     si, offset msg_time
    call    puts
    mov     ah, 0x02
    int     0x1A                # CH=hour CL=min DH=sec (BCD)
    mov     al, ch
    call    print_bcd
    mov     al, ':'
    call    putc
    mov     al, cl
    call    print_bcd
    mov     al, ':'
    call    putc
    mov     al, dh
    call    print_bcd
    call    newline
    jmp     shell_loop

do_date:
    mov     si, offset msg_date
    call    puts
    mov     ah, 0x04
    int     0x1A                # CH=century CL=year DH=month DL=day (BCD)
    mov     al, dh              # month
    call    print_bcd
    mov     al, '/'
    call    putc
    mov     al, dl              # day
    call    print_bcd
    mov     al, '/'
    call    putc
    mov     al, ch              # century
    call    print_bcd
    mov     al, cl              # year
    call    print_bcd
    call    newline
    jmp     shell_loop

do_reboot:
    mov     si, offset msg_reboot
    call    puts
    # Far jump to the reset vector 0xFFFF:0x0000 (cold-ish reboot).
    .byte   0xEA
    .word   0x0000
    .word   0xFFFF

do_halt:
    mov     si, offset msg_halt
    call    puts
    cli
.hh:
    hlt
    jmp     .hh

do_play:
    mov     si, offset msg_play
    call    puts
    mov     si, offset tune
    call    play_music
    jmp     shell_loop

# ---- extra commands (v10 feature pack) ----

# CALC <expr> - evaluate an integer expression with the BASIC evaluator.
do_calc:
    mov     [pp], dx                # dx = argument pointer (from find_arg)
    mov     byte ptr [err_flag], 0
    call    eval_num
    cmp     byte ptr [err_flag], 0
    jne     .calc_err
    push    ax
    mov     si, offset msg_calc
    call    puts
    pop     ax
    call    print_int
    call    newline
    jmp     shell_loop
.calc_err:
    mov     si, offset msg_calcerr
    call    puts
    jmp     shell_loop

# MEM - conventional + extended memory.
do_mem:
    mov     si, offset msg_mem1
    call    puts
    int     0x12                    # AX = conventional KB
    call    print_dec
    mov     si, offset msg_kb
    call    puts
    mov     ah, 0x88
    int     0x15                    # AX = extended KB (above 1MB)
    jc      .mem_done
    push    ax
    mov     si, offset msg_mem2
    call    puts
    pop     ax
    call    print_dec
    mov     si, offset msg_kb
    call    puts
.mem_done:
    jmp     shell_loop

# BEEP - a short PC-speaker tone.
do_beep:
    mov     cx, 1000
    call    sound_on
    mov     word ptr [tmp_dur], 150
    call    delay_ms
    call    sound_off
    jmp     shell_loop

# UPTIME - seconds past midnight from the BIOS tick counter.
do_uptime:
    mov     si, offset msg_uptime
    call    puts
    xor     ah, ah
    int     0x1A                    # CX:DX = ticks (~18.2/s)
    test    cx, cx
    jnz     .up_long
    mov     ax, dx
    xor     dx, dx
    mov     bx, 18
    div     bx                      # AX = seconds (fits in 16 bits under 1h)
    call    print_dec
    mov     si, offset msg_sec
    call    puts
    jmp     shell_loop
.up_long:
    mov     si, offset msg_uplong
    call    puts
    jmp     shell_loop

# DICE - roll a six-sided die.
do_dice:
    call    seed_rng
    call    rand
    xor     dx, dx
    mov     bx, 6
    div     bx
    mov     ax, dx
    inc     ax
    push    ax
    mov     si, offset msg_dice
    call    puts
    pop     ax
    call    print_dec
    call    newline
    jmp     shell_loop

# COWSAY <text> - the cow says your argument.
do_cowsay:
    mov     si, offset cow_top
    call    puts
    mov     al, '<'
    call    putc
    mov     al, ' '
    call    putc
    mov     si, dx
    call    puts
    mov     al, ' '
    call    putc
    mov     al, '>'
    call    putc
    call    newline
    mov     si, offset cow_body
    call    puts
    jmp     shell_loop

# FORTUNE - a random one-liner.
do_fortune:
    mov     si, offset fortune_art
    call    puts
    call    seed_rng
    call    rand
    xor     dx, dx
    mov     bx, 6
    div     bx
    mov     bx, dx
    shl     bx, 1
    mov     si, [fortune_tbl + bx]
    call    puts
    call    newline
    jmp     shell_loop

# SYSINFO - a quick system summary.
do_sysinfo:
    mov     si, offset msg_ver
    call    puts
    mov     si, offset msg_mem1
    call    puts
    int     0x12
    call    print_dec
    mov     si, offset msg_kb
    call    puts
    mov     si, offset msg_time
    call    puts
    mov     ah, 0x02
    int     0x1A
    mov     al, ch
    call    print_bcd
    mov     al, ':'
    call    putc
    mov     al, cl
    call    print_bcd
    call    newline
    jmp     shell_loop

# MATRIX - green "digital rain" in text mode until a key is pressed.
do_matrix:
    mov     ax, 0x0003
    int     0x10
    call    seed_rng
    mov     ax, 0xB800
    mov     es, ax
.mx_loop:
    mov     ah, 0x01
    int     0x16
    jnz     .mx_exit
    mov     cx, 50
.mx_batch:
    push    cx
    call    rand
    xor     dx, dx
    mov     bx, 2000
    div     bx                      # DX = cell 0..1999
    mov     di, dx
    shl     di, 1
    call    rand
    mov     al, ah
    and     al, 0x3F
    add     al, 0x21
    mov     es:[di], al
    mov     byte ptr es:[di+1], 0x0A
    pop     cx
    dec     cx
    jnz     .mx_batch
    mov     word ptr [tmp_dur], 40
    call    delay_ms
    jmp     .mx_loop
.mx_exit:
    xor     ah, ah
    int     0x16
    call    cls
    jmp     shell_loop

# GUESS - guess my number 1..100.
do_guess:
    call    seed_rng
    call    rand
    xor     dx, dx
    mov     bx, 100
    div     bx
    inc     dx
    mov     [guess_target], dx
    mov     si, offset msg_gintro
    call    puts
.guess_loop:
    mov     si, offset msg_gprompt
    call    puts
    call    read_line
    mov     al, [cmdbuf]
    cmp     al, 'q'
    je      .guess_exit
    cmp     al, 'Q'
    je      .guess_exit
    mov     si, offset cmdbuf
    call    str_to_int
    mov     bx, [guess_target]
    cmp     ax, bx
    je      .guess_win
    jl      .guess_low
    mov     si, offset msg_ghigh
    call    puts
    jmp     .guess_loop
.guess_low:
    mov     si, offset msg_glow
    call    puts
    jmp     .guess_loop
.guess_win:
    mov     si, offset msg_gwin
    call    puts
.guess_exit:
    jmp     shell_loop

# seed_rng: seed the LCG from the BIOS tick counter.
seed_rng:
    push    ax
    push    cx
    push    dx
    xor     ah, ah
    int     0x1A
    mov     [rng_state], dx
    pop     dx
    pop     cx
    pop     ax
    ret

# ---- PC speaker (8253 PIT channel 2 + port 0x61) ----

# sound_on: start a square wave at CX Hz on the PC speaker.
# Divisor = 1193180 / freq, computed as a 32/16 divide (8086-safe).
sound_on:
    push    ax
    push    dx
    mov     dx, 0x0012
    mov     ax, 0x34DC          # DX:AX = 1193180
    div     cx                  # AX = divisor
    mov     dx, ax
    mov     al, 0xB6            # PIT: channel 2, lo/hi, mode 3 (square)
    out     0x43, al
    mov     al, dl
    out     0x42, al            # divisor low
    mov     al, dh
    out     0x42, al            # divisor high
    in      al, 0x61
    or      al, 0x03            # gate + speaker data on
    out     0x61, al
    pop     dx
    pop     ax
    ret

# sound_off: silence the speaker.
sound_off:
    push    ax
    in      al, 0x61
    and     al, 0xFC
    out     0x61, al
    pop     ax
    ret

# delay_ms: busy-wait [tmp_dur] milliseconds via BIOS int 0x15/AH=86.
delay_ms:
    pusha
    mov     ax, [tmp_dur]
    mov     bx, 1000
    mul     bx                  # DX:AX = microseconds
    mov     cx, dx
    mov     dx, ax
    mov     ah, 0x86
    int     0x15
    popa
    ret

# play_music: play the note table at SI. Each entry is (freq word, ms word);
# freq 0 ends the tune, freq 1 is a rest (silence for the duration).
play_music:
.mu1:
    mov     cx, [si]            # frequency
    test    cx, cx
    jz      .mu_end
    mov     ax, [si+2]          # duration ms
    mov     [tmp_dur], ax
    push    si
    cmp     cx, 1
    je      .mu_rest
    call    sound_on
.mu_rest:
    call    delay_ms
    call    sound_off
    mov     word ptr [tmp_dur], 25   # short gap between notes
    call    delay_ms
    pop     si
    add     si, 4
    jmp     .mu1
.mu_end:
    call    sound_off
    ret

# ---- SNAKE (BIOS keyboard + direct VGA text memory at 0xB800) ----

do_snake:
    call    cls
    mov     ax, 0xB800
    mov     es, ax              # ES -> video memory for the whole game
    mov     word ptr [score], 0
    mov     word ptr [quit_flag], 0

    # Seed the RNG from the BIOS tick counter.
    xor     ah, ah
    int     0x1A                # CX:DX = ticks since midnight
    mov     [rng_state], dx

    # Initial snake: 4 cells at y=12, x=10..13, moving right.
    mov     word ptr [length], 4
    mov     word ptr [tail_idx], 0
    mov     word ptr [head_idx], 3
    xor     cx, cx
.sn_init:
    mov     ax, cx
    add     ax, 10              # x = 10 + cx
    add     ax, 960            # linear = 12*80 + x
    mov     si, cx
    shl     si, 1
    mov     [body_off + si], ax
    mov     di, ax
    add     di, di             # *2 -> video offset
    mov     word ptr es:[di], 0x0ADB   # bright-green block
    inc     cx
    cmp     cx, 4
    jb      .sn_init
    mov     word ptr [head_x], 13
    mov     word ptr [head_y], 12
    mov     word ptr [dir_dx], 1
    mov     word ptr [dir_dy], 0

    call    draw_hud
    call    draw_border
    call    place_food
    call    draw_food

.sn_loop:
    call    read_dir
    cmp     word ptr [quit_flag], 0
    jne     .sn_over

    # Next head position.
    mov     ax, [head_x]
    add     ax, [dir_dx]
    mov     [n_x], ax
    mov     ax, [head_y]
    add     ax, [dir_dy]
    mov     [n_y], ax

    # Wall collisions (walls at x=0, x=79, y=1, y=24).
    mov     ax, [n_x]
    cmp     ax, 0
    jle     .sn_over
    cmp     ax, 79
    jge     .sn_over
    mov     ax, [n_y]
    cmp     ax, 1
    jle     .sn_over
    cmp     ax, 24
    jge     .sn_over

    call    hits_self
    test    al, al
    jnz     .sn_over

    # Eat food?
    mov     ax, [n_x]
    cmp     ax, [food_x]
    jne     .sn_move
    mov     ax, [n_y]
    cmp     ax, [food_y]
    jne     .sn_move

    # Ate: grow, beep, score, new food.
    call    grow_head
    call    beep_eat
    inc     word ptr [score]
    call    update_hud
    call    place_food
    call    draw_food
    jmp     .sn_delay

.sn_move:
    call    erase_tail
    call    grow_head
    mov     ax, [tail_idx]
    inc     ax
    cmp     ax, 512
    jb      .sn_tw
    xor     ax, ax
.sn_tw:
    mov     [tail_idx], ax

.sn_delay:
    mov     word ptr [tmp_dur], 90
    call    delay_ms
    jmp     .sn_loop

.sn_over:
    call    sound_off
    call    cls
    mov     ax, cs
    mov     es, ax              # restore ES for the shell
    mov     si, offset msg_gameover
    call    puts
    mov     ax, [score]
    call    print_dec
    call    newline
    jmp     shell_loop

# grow_head: push the new head (in n_x/n_y) onto the body buffer and draw it.
grow_head:
    mov     ax, [head_idx]
    inc     ax
    cmp     ax, 512
    jb      .gh1
    xor     ax, ax
.gh1:
    mov     [head_idx], ax
    mov     ax, [n_y]
    mov     dx, 80
    mul     dx
    add     ax, [n_x]           # AX = new linear cell
    mov     bx, [head_idx]
    shl     bx, 1
    mov     [body_off + bx], ax
    mov     di, ax
    add     di, di
    mov     word ptr es:[di], 0x0ADB
    mov     ax, [n_x]
    mov     [head_x], ax
    mov     ax, [n_y]
    mov     [head_y], ax
    inc     word ptr [length]
    ret

# erase_tail: clear the tail cell on screen (length is decremented by caller path).
erase_tail:
    mov     bx, [tail_idx]
    shl     bx, 1
    mov     ax, [body_off + bx]
    mov     di, ax
    add     di, di
    mov     word ptr es:[di], 0x0720   # blank space
    dec     word ptr [length]
    ret

# hits_self: AL=1 if (n_x,n_y) collides with any body cell.
hits_self:
    mov     ax, [n_y]
    mov     bx, 80
    mul     bx
    add     ax, [n_x]
    mov     dx, ax              # target linear cell
    mov     cx, [length]
    mov     bx, [tail_idx]
.hs1:
    test    cx, cx
    jz      .hs_no
    mov     si, bx
    shl     si, 1
    mov     ax, [body_off + si]
    cmp     ax, dx
    je      .hs_yes
    inc     bx
    cmp     bx, 512
    jb      .hs2
    xor     bx, bx
.hs2:
    dec     cx
    jmp     .hs1
.hs_no:
    xor     al, al
    ret
.hs_yes:
    mov     al, 1
    ret

# read_dir: non-blocking keyboard poll; update direction (no 180 reversals).
read_dir:
    mov     ah, 0x01
    int     0x16
    jz      .rd_done
    xor     ah, ah
    int     0x16                # AL=ASCII, AH=scancode
    cmp     al, 0x1B            # ESC quits
    je      .rd_quit
    cmp     ah, 0x48
    je      .up
    cmp     ah, 0x50
    je      .down
    cmp     ah, 0x4B
    je      .left
    cmp     ah, 0x4D
    je      .right
    and     al, 0xDF            # fold to uppercase for WASD/Q
    cmp     al, 'W'
    je      .up
    cmp     al, 'S'
    je      .down
    cmp     al, 'A'
    je      .left
    cmp     al, 'D'
    je      .right
    cmp     al, 'Q'
    je      .rd_quit
    jmp     .rd_done
.up:
    cmp     word ptr [dir_dy], 1
    je      .rd_done
    mov     word ptr [dir_dx], 0
    mov     word ptr [dir_dy], -1
    jmp     .rd_done
.down:
    cmp     word ptr [dir_dy], -1
    je      .rd_done
    mov     word ptr [dir_dx], 0
    mov     word ptr [dir_dy], 1
    jmp     .rd_done
.left:
    cmp     word ptr [dir_dx], 1
    je      .rd_done
    mov     word ptr [dir_dx], -1
    mov     word ptr [dir_dy], 0
    jmp     .rd_done
.right:
    cmp     word ptr [dir_dx], -1
    je      .rd_done
    mov     word ptr [dir_dx], 1
    mov     word ptr [dir_dy], 0
    jmp     .rd_done
.rd_quit:
    mov     word ptr [quit_flag], 1
.rd_done:
    ret

# rand: 16-bit LCG -> AX.
rand:
    mov     ax, [rng_state]
    mov     dx, 25173
    mul     dx
    add     ax, 13849
    mov     [rng_state], ax
    ret

# place_food: pick a random empty-ish cell inside the play area.
place_food:
    call    rand
    xor     dx, dx
    mov     bx, 78
    div     bx                  # DX = AX mod 78 -> 0..77
    inc     dx                  # 1..78
    mov     [food_x], dx
    call    rand
    xor     dx, dx
    mov     bx, 22
    div     bx                  # DX = 0..21
    add     dx, 2               # 2..23
    mov     [food_y], dx
    ret

# draw_food: red diamond at (food_x, food_y).
draw_food:
    mov     ax, [food_y]
    mov     dx, 80
    mul     dx
    add     ax, [food_x]
    mov     di, ax
    add     di, di
    mov     word ptr es:[di], 0x0C04
    ret

# beep_eat: quick high beep when food is eaten.
beep_eat:
    mov     cx, 880
    call    sound_on
    mov     word ptr [tmp_dur], 40
    call    delay_ms
    call    sound_off
    ret

# draw_border: walls at x=0, x=79, y=1, y=24.
draw_border:
    xor     cx, cx
.dbh:
    mov     ax, cx
    mov     bx, 1
    call    put_wall
    mov     ax, cx
    mov     bx, 24
    call    put_wall
    inc     cx
    cmp     cx, 80
    jb      .dbh
    mov     cx, 1
.dbv:
    xor     ax, ax
    mov     bx, cx
    call    put_wall
    mov     ax, 79
    mov     bx, cx
    call    put_wall
    inc     cx
    cmp     cx, 25
    jb      .dbv
    ret

# put_wall: AX=x, BX=y -> draw a wall cell (preserves CX).
put_wall:
    call    cell_off
    mov     word ptr es:[di], 0x09B1
    ret

# cell_off: AX=x, BX=y -> DI = video offset. Clobbers AX,DX,DI; keeps BX,CX.
cell_off:
    push    ax
    mov     ax, bx
    mov     dx, 80
    mul     dx
    pop     dx
    add     ax, dx
    add     ax, ax
    mov     di, ax
    ret

# draw_hud: title line + score label at row 0.
draw_hud:
    mov     byte ptr [num_attr], 0x1E
    mov     si, offset hud_text
    xor     di, di
    mov     ah, 0x1E            # blue bg, yellow fg
    call    vputs
    call    update_hud
    ret

# update_hud: print the score number at column 70, row 0.
update_hud:
    mov     di, 140
    mov     ax, [score]
    call    vputnum
    ret

# vputs: write the NUL-terminated string at SI to ES:DI with attribute AH.
vputs:
    push    ax
.vp1:
    lodsb
    test    al, al
    jz      .vpd
    mov     es:[di], al
    mov     byte ptr es:[di+1], 0x1E
    add     di, 2
    jmp     .vp1
.vpd:
    pop     ax
    ret

# vputnum: write AX as decimal to ES:DI (attr yellow). Score only grows, so no
# need to blank stale digits.
vputnum:
    mov     bx, 10
    xor     cx, cx
.vn1:
    xor     dx, dx
    div     bx
    push    dx
    inc     cx
    test    ax, ax
    jnz     .vn1
.vn2:
    pop     dx
    mov     al, dl
    add     al, '0'
    mov     es:[di], al
    mov     ah, [num_attr]
    mov     es:[di+1], ah
    add     di, 2
    loop    .vn2
    ret

# print_dec: print AX as decimal to the shell via putc.
print_dec:
    mov     bx, 10
    xor     cx, cx
.pd1:
    xor     dx, dx
    div     bx
    push    dx
    inc     cx
    test    ax, ax
    jnz     .pd1
.pd2:
    pop     dx
    mov     al, dl
    add     al, '0'
    call    putc
    loop    .pd2
    ret

# ============================================================================
#  EDIT - a full-screen word processor
#
#  The document text lives in a SEPARATE RAM segment (0x2000 / physical
#  0x20000), giving up to MAXDOC bytes independent of the kernel's small disk
#  footprint. The editor keeps DS = kernel (so variables and strings work
#  normally) and flips ES between the document segment (buffer access via the
#  es: override) and video memory (0xB800) as needed.
#
#  Persistence: F2 saves the buffer to reserved disk sectors (LBA 20+) via
#  int 0x13; F3 loads it back. A header sector stores a "ZD" magic + length.
# ============================================================================

    .equ    DOCSEG,  0x2000      # document text segment (physical 0x20000)
    .equ    VIDSEG,  0xB800      # VGA text-mode video memory
    .equ    MAXDOC,  0x8000      # 32 KB max document (64 text sectors)
    .equ    DOC_LBA, 20          # first reserved disk sector for documents

do_edit:
    mov     word ptr [doc_len], 0
    mov     word ptr [cur_pos], 0
    mov     word ptr [top_line], 0
    mov     word ptr [left_col], 0
    call    cls
    call    render_screen
.ed_loop:
    xor     ah, ah
    int     0x16                 # AL = ASCII, AH = scancode
    cmp     al, 0x1B
    je      .ed_exit
    test    al, al
    jnz     .ed_ascii
    # extended keys (AL = 0): dispatch on scancode in AH
    mov     bl, ah
    cmp     bl, 0x48
    je      .k_up
    cmp     bl, 0x50
    je      .k_down
    cmp     bl, 0x4B
    je      .k_left
    cmp     bl, 0x4D
    je      .k_right
    cmp     bl, 0x47
    je      .k_home
    cmp     bl, 0x4F
    je      .k_end
    cmp     bl, 0x49
    je      .k_pgup
    cmp     bl, 0x51
    je      .k_pgdn
    cmp     bl, 0x53
    je      .k_del
    cmp     bl, 0x3C
    je      .k_save
    cmp     bl, 0x3D
    je      .k_load
    jmp     .ed_redraw
.ed_ascii:
    cmp     al, 0x0D
    je      .k_enter
    cmp     al, 0x08
    je      .k_bs
    cmp     al, 0x09
    je      .k_tab
    cmp     al, 0x20
    jb      .ed_redraw
    cmp     al, 0x7F
    jae     .ed_redraw
    call    insert_char
    jmp     .ed_redraw
.k_enter:
    mov     al, 0x0A
    call    insert_char
    jmp     .ed_redraw
.k_bs:
    call    backspace
    jmp     .ed_redraw
.k_tab:
    mov     al, ' '
    call    insert_char
    mov     al, ' '
    call    insert_char
    jmp     .ed_redraw
.k_del:
    call    delete_fwd
    jmp     .ed_redraw
.k_up:
    call    move_up
    jmp     .ed_redraw
.k_down:
    call    move_down
    jmp     .ed_redraw
.k_left:
    call    move_left
    jmp     .ed_redraw
.k_right:
    call    move_right
    jmp     .ed_redraw
.k_home:
    call    move_home
    jmp     .ed_redraw
.k_end:
    call    move_end
    jmp     .ed_redraw
.k_pgup:
    call    page_up
    jmp     .ed_redraw
.k_pgdn:
    call    page_down
    jmp     .ed_redraw
.k_save:
    call    disk_save
    jmp     .ed_redraw
.k_load:
    call    disk_load
    jmp     .ed_redraw
.ed_redraw:
    call    render_screen
    jmp     .ed_loop
.ed_exit:
    call    cls
    mov     ax, cs
    mov     es, ax
    mov     si, offset msg_edit_exit
    call    puts
    jmp     shell_loop

# render_screen: redraw the 24 text rows, the status line, and the cursor.
render_screen:
    call    calc_cursor
    call    adjust_scroll
    call    find_top_offset
    mov     word ptr [render_row], 0
.rs_loop:
    call    build_line
    call    blit_line
    inc     word ptr [render_row]
    cmp     word ptr [render_row], 24
    jb      .rs_loop
    call    draw_status
    call    place_cursor
    ret

# calc_cursor: scan from the start to cur_pos to find cursor (cur_line,cur_col).
calc_cursor:
    mov     ax, DOCSEG
    mov     es, ax
    xor     si, si
    xor     cx, cx              # line
    xor     dx, dx              # col
.cc_l:
    cmp     si, [cur_pos]
    jae     .cc_done
    mov     al, es:[si]
    cmp     al, 0x0A
    jne     .cc_notnl
    inc     cx
    xor     dx, dx
    jmp     .cc_next
.cc_notnl:
    inc     dx
.cc_next:
    inc     si
    jmp     .cc_l
.cc_done:
    mov     [cur_line], cx
    mov     [cur_col], dx
    ret

# adjust_scroll: keep the cursor visible (24 rows x 80 cols window).
adjust_scroll:
    mov     ax, [cur_line]
    cmp     ax, [top_line]
    jae     .as_v1
    mov     [top_line], ax
    jmp     .as_v2
.as_v1:
    mov     bx, [top_line]
    add     bx, 24
    cmp     ax, bx
    jb      .as_v2
    mov     bx, ax
    sub     bx, 23
    mov     [top_line], bx
.as_v2:
    mov     ax, [cur_col]
    cmp     ax, [left_col]
    jae     .as_h1
    mov     [left_col], ax
    jmp     .as_h2
.as_h1:
    mov     bx, [left_col]
    add     bx, 80
    cmp     ax, bx
    jb      .as_h2
    mov     bx, ax
    sub     bx, 79
    mov     [left_col], bx
.as_h2:
    ret

# find_top_offset: scan_ptr = byte offset where the top visible line begins.
find_top_offset:
    mov     ax, DOCSEG
    mov     es, ax
    xor     si, si
    xor     cx, cx
.fto_l:
    cmp     cx, [top_line]
    jae     .fto_done
    cmp     si, [doc_len]
    jae     .fto_done
    mov     al, es:[si]
    inc     si
    cmp     al, 0x0A
    jne     .fto_l
    inc     cx
    jmp     .fto_l
.fto_done:
    mov     [scan_ptr], si
    ret

# build_line: fill linebuf (80 cols) with the next logical line starting at
# scan_ptr, honouring left_col; advance scan_ptr past the line. ES = DOCSEG.
build_line:
    mov     ax, DOCSEG
    mov     es, ax
    xor     bx, bx
.bld_clr:
    mov     byte ptr [linebuf + bx], ' '
    inc     bx
    cmp     bx, 80
    jb      .bld_clr
    mov     si, [scan_ptr]
    xor     cx, cx              # column within the logical line
    xor     bx, bx              # fill index into linebuf
.bld_rl:
    cmp     si, [doc_len]
    jae     .bld_noeat
    mov     al, es:[si]
    cmp     al, 0x0A
    je      .bld_eat
    cmp     cx, [left_col]
    jb      .bld_skip
    cmp     bx, 80
    jae     .bld_skip
    mov     [linebuf + bx], al
    inc     bx
.bld_skip:
    inc     cx
    inc     si
    jmp     .bld_rl
.bld_eat:
    inc     si                  # consume the newline
.bld_noeat:
    mov     [scan_ptr], si
    ret

# blit_line: copy linebuf to video row [render_row] with attribute 0x07.
blit_line:
    mov     ax, VIDSEG
    mov     es, ax
    mov     ax, [render_row]
    mov     dx, 160
    mul     dx
    mov     di, ax
    mov     si, offset linebuf
    mov     cx, 80
.blt_l:
    lodsb
    mov     es:[di], al
    mov     byte ptr es:[di+1], 0x07
    add     di, 2
    loop    .blt_l
    ret

# draw_status: reverse-video status bar on row 24 with key help + position.
draw_status:
    mov     ax, VIDSEG
    mov     es, ax
    mov     byte ptr [num_attr], 0x70
    mov     di, 3840            # row 24 * 160
    mov     cx, 80
.sts_clr:
    mov     word ptr es:[di], 0x7020
    add     di, 2
    loop    .sts_clr
    mov     di, 3840
    mov     si, offset edit_status
    call    stat_puts
    mov     si, offset s_ln
    call    stat_puts
    mov     ax, [cur_line]
    inc     ax
    call    vputnum
    mov     si, offset s_col
    call    stat_puts
    mov     ax, [cur_col]
    inc     ax
    call    vputnum
    mov     si, offset s_bytes
    call    stat_puts
    mov     ax, [doc_len]
    call    vputnum
    ret

# stat_puts: write string at SI to ES:DI with attribute 0x70, advancing DI.
stat_puts:
.stp_l:
    lodsb
    test    al, al
    jz      .stp_d
    mov     es:[di], al
    mov     byte ptr es:[di+1], 0x70
    add     di, 2
    jmp     .stp_l
.stp_d:
    ret

# place_cursor: position the hardware text cursor at the edit caret.
place_cursor:
    mov     ax, [cur_line]
    sub     ax, [top_line]
    mov     dh, al
    mov     ax, [cur_col]
    sub     ax, [left_col]
    mov     dl, al
    mov     bh, 0
    mov     ah, 0x02
    int     0x10
    ret

# insert_char: insert AL at cur_pos (shift the tail of the buffer right).
insert_char:
    mov     [ins_char], al
    mov     bx, [doc_len]
    cmp     bx, MAXDOC
    jae     .ic_full
    mov     ax, DOCSEG
    mov     es, ax
    mov     cx, [doc_len]
    sub     cx, [cur_pos]
    mov     si, [doc_len]
    dec     si
    mov     di, [doc_len]
    jcxz    .ic_place
.ic_sh:
    mov     al, es:[si]
    mov     es:[di], al
    dec     si
    dec     di
    loop    .ic_sh
.ic_place:
    mov     di, [cur_pos]
    mov     al, [ins_char]
    mov     es:[di], al
    inc     word ptr [doc_len]
    inc     word ptr [cur_pos]
.ic_full:
    ret

# backspace: delete the character before the cursor.
backspace:
    mov     ax, [cur_pos]
    test    ax, ax
    jz      .bks_done
    mov     ax, DOCSEG
    mov     es, ax
    mov     si, [cur_pos]
    mov     di, [cur_pos]
    dec     di
    mov     cx, [doc_len]
    sub     cx, [cur_pos]
    jcxz    .bks_fix
.bks_sh:
    mov     al, es:[si]
    mov     es:[di], al
    inc     si
    inc     di
    loop    .bks_sh
.bks_fix:
    dec     word ptr [doc_len]
    dec     word ptr [cur_pos]
.bks_done:
    ret

# delete_fwd: delete the character at the cursor.
delete_fwd:
    mov     ax, [cur_pos]
    cmp     ax, [doc_len]
    jae     .df_done
    mov     ax, DOCSEG
    mov     es, ax
    mov     si, [cur_pos]
    inc     si
    mov     di, [cur_pos]
    mov     cx, [doc_len]
    sub     cx, [cur_pos]
    dec     cx
    jcxz    .df_fix
.df_sh:
    mov     al, es:[si]
    mov     es:[di], al
    inc     si
    inc     di
    loop    .df_sh
.df_fix:
    dec     word ptr [doc_len]
.df_done:
    ret

# line_start_of: AX = position -> BX = start offset of its line. ES = DOCSEG.
line_start_of:
    push    ax
    mov     ax, DOCSEG
    mov     es, ax
    pop     ax
    mov     bx, ax
.lso_l:
    test    bx, bx
    jz      .lso_done
    mov     si, bx
    dec     si
    mov     al, es:[si]
    cmp     al, 0x0A
    je      .lso_done
    dec     bx
    jmp     .lso_l
.lso_done:
    ret

move_left:
    mov     ax, [cur_pos]
    test    ax, ax
    jz      .mvl_done
    dec     ax
    mov     [cur_pos], ax
.mvl_done:
    ret

move_right:
    mov     ax, [cur_pos]
    cmp     ax, [doc_len]
    jae     .mvr_done
    inc     ax
    mov     [cur_pos], ax
.mvr_done:
    ret

move_home:
    mov     ax, [cur_pos]
    call    line_start_of
    mov     [cur_pos], bx
    ret

move_end:
    mov     ax, DOCSEG
    mov     es, ax
    mov     bx, [cur_pos]
.mve_l:
    cmp     bx, [doc_len]
    jae     .mve_done
    mov     al, es:[bx]
    cmp     al, 0x0A
    je      .mve_done
    inc     bx
    jmp     .mve_l
.mve_done:
    mov     [cur_pos], bx
    ret

# move_up: go to the previous line, keeping the column where possible.
move_up:
    mov     ax, [cur_pos]
    call    line_start_of
    mov     [tmp_ls], bx
    test    bx, bx
    jz      .mvu_done
    mov     ax, [cur_pos]
    sub     ax, bx
    mov     [tmp_col], ax
    mov     ax, [tmp_ls]
    dec     ax
    call    line_start_of
    mov     [tmp_pls], bx
    mov     ax, [tmp_ls]
    dec     ax
    sub     ax, bx              # AX = previous line length
    mov     dx, [tmp_col]
    cmp     dx, ax
    jbe     .mvu_min
    mov     dx, ax
.mvu_min:
    mov     ax, [tmp_pls]
    add     ax, dx
    mov     [cur_pos], ax
.mvu_done:
    ret

# move_down: go to the next line, keeping the column where possible.
move_down:
    mov     ax, DOCSEG
    mov     es, ax
    mov     ax, [cur_pos]
    call    line_start_of
    mov     ax, [cur_pos]
    sub     ax, bx
    mov     [tmp_col], ax
    mov     ax, DOCSEG
    mov     es, ax
    mov     bx, [cur_pos]
.mvd_findlf:
    cmp     bx, [doc_len]
    jae     .mvd_done
    mov     al, es:[bx]
    cmp     al, 0x0A
    je      .mvd_has
    inc     bx
    jmp     .mvd_findlf
.mvd_has:
    inc     bx
    mov     [tmp_pls], bx       # next line start
    mov     si, bx
.mvd_len:
    cmp     si, [doc_len]
    jae     .mvd_lend
    mov     al, es:[si]
    cmp     al, 0x0A
    je      .mvd_lend
    inc     si
    jmp     .mvd_len
.mvd_lend:
    mov     ax, si
    sub     ax, [tmp_pls]       # next line length
    mov     dx, [tmp_col]
    cmp     dx, ax
    jbe     .mvd_min
    mov     dx, ax
.mvd_min:
    mov     ax, [tmp_pls]
    add     ax, dx
    mov     [cur_pos], ax
.mvd_done:
    ret

page_up:
    mov     cx, 23
.pgu_l:
    push    cx
    call    move_up
    pop     cx
    loop    .pgu_l
    ret

page_down:
    mov     cx, 23
.pgd_l:
    push    cx
    call    move_down
    pop     cx
    loop    .pgd_l
    ret

# disk_one: read/write one sector. [lba] = LBA, [rw_op] = 2 read / 3 write,
# ES:BX = buffer. Converts LBA to CHS for a 1.44MB floppy (18 sect, 2 heads).
disk_one:
    push    bx
    mov     ax, [lba]
    xor     dx, dx
    mov     cx, 18
    div     cx                  # AX = track, DX = sector index
    mov     [t_sec], dx
    xor     dx, dx
    mov     cx, 2
    div     cx                  # AX = cylinder, DX = head
    mov     [t_cyl], ax
    mov     [t_head], dx
    pop     bx
    mov     ah, [rw_op]
    mov     al, 1
    mov     dx, [t_cyl]
    mov     ch, dl              # cylinder (low 8 bits; <80 so high bits 0)
    mov     cl, byte ptr [t_sec]
    inc     cl                  # sectors are 1-based
    mov     dx, [t_head]
    mov     dh, dl
    mov     dl, [boot_drive]
    int     0x13
    ret

# disk_save: write the document (F2). Header sector + ceil(len/512) text sectors.
disk_save:
    mov     byte ptr [secbuf],   'Z'
    mov     byte ptr [secbuf+1], 'D'
    mov     ax, [doc_len]
    mov     [secbuf+2], ax
    mov     ax, cs
    mov     es, ax
    mov     bx, offset secbuf
    mov     word ptr [lba], DOC_LBA
    mov     byte ptr [rw_op], 0x03
    call    disk_one
    mov     ax, [doc_len]
    add     ax, 511
    mov     cl, 9
    shr     ax, cl
    mov     [tmp_secs], ax
    mov     word ptr [lba], DOC_LBA+1
    xor     bx, bx
    xor     si, si
.dsv_l:
    mov     ax, [tmp_secs]
    cmp     si, ax
    jae     .dsv_done
    mov     ax, DOCSEG
    mov     es, ax
    mov     byte ptr [rw_op], 0x03
    push    si
    call    disk_one
    pop     si
    add     bx, 512
    inc     word ptr [lba]
    inc     si
    jmp     .dsv_l
.dsv_done:
    ret

# disk_load: read the document back (F3).
disk_load:
    mov     ax, cs
    mov     es, ax
    mov     bx, offset secbuf
    mov     word ptr [lba], DOC_LBA
    mov     byte ptr [rw_op], 0x02
    call    disk_one
    cmp     byte ptr [secbuf], 'Z'
    jne     .dlo_bad
    cmp     byte ptr [secbuf+1], 'D'
    jne     .dlo_bad
    mov     ax, [secbuf+2]
    cmp     ax, MAXDOC
    jbe     .dlo_lenok
    mov     ax, MAXDOC
.dlo_lenok:
    mov     [doc_len], ax
    mov     ax, [doc_len]
    add     ax, 511
    mov     cl, 9
    shr     ax, cl
    mov     [tmp_secs], ax
    mov     word ptr [lba], DOC_LBA+1
    xor     bx, bx
    xor     si, si
.dlo_l:
    mov     ax, [tmp_secs]
    cmp     si, ax
    jae     .dlo_done
    mov     ax, DOCSEG
    mov     es, ax
    mov     byte ptr [rw_op], 0x02
    push    si
    call    disk_one
    pop     si
    add     bx, 512
    inc     word ptr [lba]
    inc     si
    jmp     .dlo_l
.dlo_done:
    mov     word ptr [cur_pos], 0
    mov     word ptr [top_line], 0
    mov     word ptr [left_col], 0
.dlo_bad:
    ret

# ============================================================================
#  ELIZA - the DOCTOR script
#
#  A Rogerian-psychotherapist chatbot. Reads a line, uppercases a copy, scans a
#  priority-ordered keyword table, and replies either with a canned line or by
#  reflecting the rest of the sentence ("I am" -> "you are", "my" -> "your")
#  into a response template. No keyword -> a rotating generic prompt.
#
#  Everything runs with DS = kernel; buffers (cmdbuf, upbuf, outbuf) and all
#  tables live in the kernel segment.
# ============================================================================

do_eliza:
    call    cls
    mov     si, offset eliza_intro
    call    puts
    mov     word ptr [gen_idx], 0
.elz_loop:
    mov     si, offset eliza_you
    call    puts
    call    read_line               # -> cmdbuf
    call    upcopy                  # uppercase copy -> upbuf

    # Quit words.
    mov     si, offset ekw_bye
    mov     di, offset upbuf
    call    find_kw
    test    al, al
    jnz     .elz_quit
    mov     si, offset ekw_quit
    mov     di, offset upbuf
    call    find_kw
    test    al, al
    jnz     .elz_quit

    # Empty line -> generic.
    mov     al, [upbuf]
    test    al, al
    jz      .elz_generic

    # Scan the keyword table.
    mov     word ptr [kw_tabptr], offset eliza_kw_table
.elz_kloop:
    mov     bx, [kw_tabptr]
    mov     si, [bx]                # keyword pointer (0 = end of table)
    test    si, si
    jz      .elz_generic
    mov     di, offset upbuf
    call    find_kw                 # AL=1/0, BX = text after the match
    test    al, al
    jnz     .elz_found
    add     word ptr [kw_tabptr], 8
    jmp     .elz_kloop

.elz_found:
    mov     [rem_ptr], bx
    mov     si, offset eliza_doc
    call    puts
    mov     bx, [kw_tabptr]
    mov     si, [bx+2]              # prefix
    call    puts
    mov     ax, [bx+6]             # reflect flag
    test    ax, ax
    jz      .elz_after
    mov     si, [rem_ptr]
    call    reflect                # build reflected remainder in outbuf
    mov     si, offset outbuf
    call    puts
    mov     bx, [kw_tabptr]
    mov     si, [bx+4]             # suffix
    call    puts
.elz_after:
    call    newline
    jmp     .elz_loop

.elz_generic:
    mov     si, offset eliza_doc
    call    puts
    mov     bx, [gen_idx]
    mov     si, [eliza_generic + bx]
    call    puts
    call    newline
    add     word ptr [gen_idx], 2
    cmp     word ptr [gen_idx], 12
    jb      .elz_loop
    mov     word ptr [gen_idx], 0
    jmp     .elz_loop

.elz_quit:
    mov     si, offset eliza_doc
    call    puts
    mov     si, offset eliza_bye
    call    puts
    call    newline
    jmp     shell_loop

# upcopy: copy cmdbuf -> upbuf, uppercasing A-Z; NUL-terminated.
upcopy:
    mov     si, offset cmdbuf
    mov     di, offset upbuf
.uc_l:
    lodsb
    test    al, al
    jz      .uc_done
    cmp     al, 'a'
    jb      .uc_st
    cmp     al, 'z'
    ja      .uc_st
    sub     al, 0x20
.uc_st:
    mov     [di], al
    inc     di
    jmp     .uc_l
.uc_done:
    mov     byte ptr [di], 0
    ret

# find_kw: substring search. SI = needle (asciz), DI = haystack (asciz).
# Out: AL = 1 if found and BX = pointer just past the match, else AL = 0.
find_kw:
.fk_outer:
    mov     al, [di]
    test    al, al
    jz      .fk_no
    push    si
    push    di
    mov     bx, di
.fk_inner:
    mov     ah, [si]
    test    ah, ah
    jz      .fk_yes
    mov     al, [bx]
    cmp     al, ah
    jne     .fk_next
    inc     si
    inc     bx
    jmp     .fk_inner
.fk_yes:
    pop     di
    pop     si
    mov     al, 1
    ret
.fk_next:
    pop     di
    pop     si
    inc     di
    jmp     .fk_outer
.fk_no:
    xor     al, al
    ret

# reflect: SI = remainder (uppercase). Build a lowercased, person-swapped copy
# in outbuf (word by word via swap_table), NUL-terminated.
reflect:
    mov     [src_ptr], si
    mov     word ptr [out_ptr], offset outbuf
.rf_loop:
    mov     si, [src_ptr]
.rf_skip:
    mov     al, [si]
    cmp     al, ' '
    jne     .rf_chk
    inc     si
    jmp     .rf_skip
.rf_chk:
    test    al, al
    jz      .rf_end
    mov     bx, si                  # word start
    xor     cx, cx                  # length
.rf_wlen:
    mov     al, [si]
    test    al, al
    jz      .rf_we
    cmp     al, ' '
    je      .rf_we
    inc     si
    inc     cx
    jmp     .rf_wlen
.rf_we:
    mov     [src_ptr], si
    call    strip_punct             # trim trailing .,!?;: from the word
    call    swap_lookup             # BX,CX -> DX = replacement or 0
    test    dx, dx
    jz      .rf_orig
    mov     si, dx
    call    out_asciz
    jmp     .rf_sep
.rf_orig:
    mov     si, bx
    call    out_word_lc
.rf_sep:
    mov     di, [out_ptr]
    mov     byte ptr [di], ' '
    inc     di
    mov     [out_ptr], di
    jmp     .rf_loop
.rf_end:
    mov     di, [out_ptr]
    cmp     di, offset outbuf
    je      .rf_term
    dec     di                      # drop the trailing space
.rf_term:
    mov     byte ptr [di], 0
    ret

# strip_punct: BX = word start, CX = len -> CX shrunk past trailing punctuation.
strip_punct:
.sp_l:
    test    cx, cx
    jz      .sp_d
    mov     si, bx
    add     si, cx
    dec     si
    mov     al, [si]
    cmp     al, '.'
    je      .sp_dec
    cmp     al, ','
    je      .sp_dec
    cmp     al, '!'
    je      .sp_dec
    cmp     al, '?'
    je      .sp_dec
    cmp     al, ';'
    je      .sp_dec
    cmp     al, ':'
    je      .sp_dec
    ret
.sp_dec:
    dec     cx
    jmp     .sp_l
.sp_d:
    ret

# swap_lookup: BX = word, CX = len -> DX = lowercase replacement (asciz) or 0.
# Preserves BX and CX.
swap_lookup:
    mov     si, offset swap_table
.sl_loop:
    mov     dx, [si]
    test    dx, dx
    jz      .sl_none
    push    si
    mov     di, bx
    mov     bp, cx
    push    dx
    mov     si, dx
.sl_cmp:
    mov     al, [si]
    test    al, al
    jz      .sl_fromend
    test    bp, bp
    jz      .sl_mism
    mov     ah, [di]
    cmp     al, ah
    jne     .sl_mism
    inc     si
    inc     di
    dec     bp
    jmp     .sl_cmp
.sl_fromend:
    test    bp, bp
    jnz     .sl_mism
    pop     dx
    pop     si
    mov     dx, [si+2]
    ret
.sl_mism:
    pop     dx
    pop     si
    add     si, 4
    jmp     .sl_loop
.sl_none:
    xor     dx, dx
    ret

# out_asciz: append asciz at SI to [out_ptr].
out_asciz:
    mov     di, [out_ptr]
.oa_l:
    mov     al, [si]
    test    al, al
    jz      .oa_d
    mov     [di], al
    inc     di
    inc     si
    jmp     .oa_l
.oa_d:
    mov     [out_ptr], di
    ret

# out_word_lc: append CX chars at SI to [out_ptr], lowercased.
out_word_lc:
    mov     di, [out_ptr]
.ow_l:
    test    cx, cx
    jz      .ow_d
    mov     al, [si]
    cmp     al, 'A'
    jb      .ow_st
    cmp     al, 'Z'
    ja      .ow_st
    add     al, 0x20
.ow_st:
    mov     [di], al
    inc     di
    inc     si
    dec     cx
    jmp     .ow_l
.ow_d:
    mov     [out_ptr], di
    ret

# ============================================================================
#  ZBASIC - a structured BASIC interpreter (QBASIC-flavored)
#
#  No line numbers: the program runs top to bottom with FOR/NEXT, WHILE/WEND,
#  IF cond THEN <stmt>, GOTO/GOSUB to labels. Integer math; string variables.
#  You type the program at the prompt; LIST shows it, NEW clears it, RUN runs
#  it, BYE exits to the shell. Parsing uses a memory cursor [pp].
# ============================================================================

    .equ    PROGMAX, 4096
    .equ    KW_FOR,   1
    .equ    KW_NEXT,  2
    .equ    KW_WHILE, 3
    .equ    KW_WEND,  4

do_basic:
    call    cls
    call    seed_rng
    mov     si, offset basic_intro
    call    puts
    mov     word ptr [prog_len], 0
    mov     word ptr [num_count], 0
    mov     word ptr [str_count], 0
.b_loop:
    call    read_line                   # into cmdbuf
    call    upcopy                      # uppercased copy -> upbuf
    call    trim_upbuf
    mov     si, offset upbuf
    mov     di, offset bcmd_bye
    call    streq
    test    al, al
    jnz     .b_exit
    mov     si, offset upbuf
    mov     di, offset bcmd_run
    call    streq
    test    al, al
    jnz     .b_run
    mov     si, offset upbuf
    mov     di, offset bcmd_list
    call    streq
    test    al, al
    jnz     .b_list
    mov     si, offset upbuf
    mov     di, offset bcmd_new
    call    streq
    test    al, al
    jnz     .b_new
    call    basic_append
    jmp     .b_loop
.b_run:
    call    basic_run
    jmp     .b_ok
.b_list:
    call    basic_list
    jmp     .b_ok
.b_new:
    mov     word ptr [prog_len], 0
    mov     word ptr [num_count], 0
    mov     word ptr [str_count], 0
.b_ok:
    mov     si, offset basic_ok
    call    puts
    jmp     .b_loop
.b_exit:
    jmp     shell_loop

# trim_upbuf: strip trailing spaces from upbuf.
trim_upbuf:
    mov     di, offset upbuf
    xor     cx, cx
.tu_len:
    mov     al, [di]
    test    al, al
    jz      .tu_trim
    inc     di
    inc     cx
    jmp     .tu_len
.tu_trim:
    test    cx, cx
    jz      .tu_d
    dec     di
    mov     al, [di]
    cmp     al, ' '
    jne     .tu_d
    mov     byte ptr [di], 0
    dec     cx
    jmp     .tu_trim
.tu_d:
    ret

# basic_append: append cmdbuf + newline to prog_buf (bounded by PROGMAX).
basic_append:
    mov     si, offset cmdbuf
    mov     bx, offset prog_buf
    add     bx, [prog_len]
.ba_l:
    mov     ax, bx
    sub     ax, offset prog_buf
    cmp     ax, PROGMAX - 2
    jae     .ba_nl
    mov     al, [si]
    test    al, al
    jz      .ba_nl
    mov     [bx], al
    inc     bx
    inc     si
    jmp     .ba_l
.ba_nl:
    mov     byte ptr [bx], 0x0A
    inc     bx
    mov     ax, bx
    sub     ax, offset prog_buf
    mov     [prog_len], ax
    ret

# basic_list: print the program (0x0A separators -> CRLF).
basic_list:
    mov     si, offset prog_buf
    mov     cx, [prog_len]
.bl_l:
    test    cx, cx
    jz      .bl_d
    mov     al, [si]
    cmp     al, 0x0A
    jne     .bl_pc
    call    newline
    jmp     .bl_n
.bl_pc:
    call    putc
.bl_n:
    inc     si
    dec     cx
    jmp     .bl_l
.bl_d:
    ret

# ---- low-level parsing helpers (operate on cursor [pp]) ----

skip_sp:
    push    bx
    push    ax                  # preserve AX: callers (ev_term/ev_arith) hold
                                # the running value here while skipping spaces
.ss_l:
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, ' '
    je      .ss_a
    cmp     al, 9
    je      .ss_a
    pop     ax
    pop     bx
    ret
.ss_a:
    inc     word ptr [pp]
    jmp     .ss_l

# peek_ident: DI = dest. Copies an identifier ([A-Za-z][A-Za-z0-9]*) uppercased
# to dest (capped 8), WITHOUT advancing [pp]. Returns CX = length, [peek_end] =
# pointer just past the identifier.
peek_ident:
    call    skip_sp
    mov     bx, [pp]
    xor     cx, cx
.pi_l:
    mov     al, [bx]
    cmp     al, 'A'
    jb      .pi_lo
    cmp     al, 'Z'
    jbe     .pi_take
.pi_lo:
    cmp     al, 'a'
    jb      .pi_dig
    cmp     al, 'z'
    jbe     .pi_low
.pi_dig:
    test    cx, cx
    jz      .pi_done
    cmp     al, '0'
    jb      .pi_done
    cmp     al, '9'
    ja      .pi_done
    jmp     .pi_store
.pi_low:
    sub     al, 0x20
    jmp     .pi_store
.pi_take:
.pi_store:
    cmp     cx, 8
    jae     .pi_skip
    mov     [di], al
    inc     di
.pi_skip:
    inc     cx
    inc     bx
    jmp     .pi_l
.pi_done:
    mov     [peek_end], bx
    mov     byte ptr [di], 0
    ret

# streq: SI, DI asciz -> AL = 1 if equal.
streq:
.se_l:
    mov     al, [si]
    mov     ah, [di]
    cmp     al, ah
    jne     .se_no
    test    al, al
    jz      .se_yes
    inc     si
    inc     di
    jmp     .se_l
.se_yes:
    mov     al, 1
    ret
.se_no:
    xor     al, al
    ret

# try_kw: DI = keyword asciz. If the identifier at [pp] equals it (and isn't a
# X$ string var), consume it and return AL=1; else leave [pp] and return AL=0.
try_kw:
    call    skip_sp
    push    di
    mov     di, offset kwbuf
    call    peek_ident
    pop     si
    test    cx, cx
    jz      .tk_no
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .tk_no
    mov     di, offset kwbuf
    call    streq
    test    al, al
    jz      .tk_no
    mov     ax, [peek_end]
    mov     [pp], ax
    mov     al, 1
    ret
.tk_no:
    xor     al, al
    ret

expect_eq:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '='
    jne     .xe_err
    inc     word ptr [pp]
    ret
.xe_err:
    mov     byte ptr [err_flag], 1
    ret

expect_lparen:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '('
    jne     .xl_err
    inc     word ptr [pp]
    ret
.xl_err:
    mov     byte ptr [err_flag], 1
    ret

expect_rparen:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, ')'
    jne     .xr_err
    inc     word ptr [pp]
    ret
.xr_err:
    mov     byte ptr [err_flag], 1
    ret

# parse_uint: digits at [pp] -> AX (advances [pp]).
parse_uint:
    xor     ax, ax
    mov     cx, 10
.pu_l:
    mov     bx, [pp]
    mov     dl, [bx]
    cmp     dl, '0'
    jb      .pu_d
    cmp     dl, '9'
    ja      .pu_d
    sub     dl, '0'
    mov     bl, dl
    xor     bh, bh
    mul     cx
    add     ax, bx
    inc     word ptr [pp]
    jmp     .pu_l
.pu_d:
    ret

# str_to_int: SI asciz -> AX (signed).
str_to_int:
    xor     ax, ax
    xor     cx, cx
.si_sp:
    mov     dl, [si]
    cmp     dl, ' '
    jne     .si_sign
    inc     si
    jmp     .si_sp
.si_sign:
    cmp     dl, '-'
    jne     .si_loop
    mov     cx, 1
    inc     si
.si_loop:
    mov     bx, 10
.si_l2:
    mov     dl, [si]
    cmp     dl, '0'
    jb      .si_done
    cmp     dl, '9'
    ja      .si_done
    push    dx
    mul     bx
    pop     dx
    sub     dl, '0'
    xor     dh, dh
    add     ax, dx
    inc     si
    jmp     .si_l2
.si_done:
    test    cx, cx
    jz      .si_ret
    neg     ax
.si_ret:
    ret

# print_int: AX signed -> teletype (uses print_dec for the magnitude).
print_int:
    test    ax, ax
    jns     .pin_pos
    push    ax
    mov     al, '-'
    call    putc
    pop     ax
    neg     ax
.pin_pos:
    call    print_dec
    ret

# ---- variable tables ----

# num_index: idbuf -> DI = slot*2 into num_vals (creates the var if new).
num_index:
    mov     cx, [num_count]
    xor     di, di
    mov     si, offset num_names
.ni_l:
    test    cx, cx
    jz      .ni_new
    push    si
    push    di
    mov     di, offset idbuf
    call    streq
    pop     di
    pop     si
    test    al, al
    jnz     .ni_found
    add     si, 9
    inc     di
    dec     cx
    jmp     .ni_l
.ni_found:
    shl     di, 1
    ret
.ni_new:
    mov     ax, [num_count]
    cmp     ax, 32
    jb      .ni_new2
    mov     byte ptr [err_flag], 1
    xor     di, di
    ret
.ni_new2:
    mov     bx, 9
    mul     bx
    mov     bx, offset num_names
    add     bx, ax
    mov     si, offset idbuf
.ni_cp:
    mov     al, [si]
    mov     [bx], al
    test    al, al
    jz      .ni_cpd
    inc     si
    inc     bx
    jmp     .ni_cp
.ni_cpd:
    mov     di, [num_count]
    shl     di, 1
    mov     word ptr [num_vals + di], 0
    inc     word ptr [num_count]
    ret

num_get:
    call    num_index
    mov     ax, [num_vals + di]
    ret

# str_get_ptr: idbuf -> SI = pointer to this string var's 64-byte slot.
str_get_ptr:
    mov     cx, [str_count]
    xor     di, di
    mov     si, offset str_names
.sg_l:
    test    cx, cx
    jz      .sg_new
    push    si
    push    di
    mov     di, offset idbuf
    call    streq
    pop     di
    pop     si
    test    al, al
    jnz     .sg_found
    add     si, 9
    inc     di
    dec     cx
    jmp     .sg_l
.sg_found:
    jmp     .sg_ptr
.sg_new:
    mov     ax, [str_count]
    cmp     ax, 16
    jb      .sg_new2
    mov     byte ptr [err_flag], 1
    mov     si, offset str_store
    ret
.sg_new2:
    mov     bx, 9
    mul     bx
    mov     bx, offset str_names
    add     bx, ax
    mov     si, offset idbuf
.sg_cp:
    mov     al, [si]
    mov     [bx], al
    test    al, al
    jz      .sg_cpd
    inc     si
    inc     bx
    jmp     .sg_cp
.sg_cpd:
    mov     di, [str_count]
    inc     word ptr [str_count]
.sg_ptr:
    mov     ax, di
    mov     bx, 64
    mul     bx
    mov     si, offset str_store
    add     si, ax
    ret

# ---- expression evaluator (recursive descent, integer) ----

eval_num:
    call    ev_or
    ret

ev_or:
    call    ev_and
.eo_l:
    push    ax
    mov     di, offset kw_OR
    call    try_kw
    test    al, al
    jz      .eo_d
    call    ev_and
    pop     bx
    or      ax, bx
    jmp     .eo_l
.eo_d:
    pop     ax
    ret

ev_and:
    call    ev_compare
.ea_l:
    push    ax
    mov     di, offset kw_AND
    call    try_kw
    test    al, al
    jz      .ea_d
    call    ev_compare
    pop     bx
    and     ax, bx
    jmp     .ea_l
.ea_d:
    pop     ax
    ret

ev_compare:
    call    ev_arith
    push    ax
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '='
    je      .ec_eq
    cmp     al, '<'
    je      .ec_lt
    cmp     al, '>'
    je      .ec_gt
    pop     ax
    ret
.ec_eq:
    inc     word ptr [pp]
    mov     cl, 0
    jmp     .ec_rhs
.ec_lt:
    inc     word ptr [pp]
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '='
    je      .ec_le
    cmp     al, '>'
    je      .ec_ne
    mov     cl, 1
    jmp     .ec_rhs
.ec_le:
    inc     word ptr [pp]
    mov     cl, 2
    jmp     .ec_rhs
.ec_ne:
    inc     word ptr [pp]
    mov     cl, 3
    jmp     .ec_rhs
.ec_gt:
    inc     word ptr [pp]
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '='
    je      .ec_ge
    mov     cl, 4
    jmp     .ec_rhs
.ec_ge:
    inc     word ptr [pp]
    mov     cl, 5
.ec_rhs:
    push    cx
    call    ev_arith
    pop     cx
    pop     bx
    cmp     cl, 0
    je      .ec_req
    cmp     cl, 1
    je      .ec_rlt
    cmp     cl, 2
    je      .ec_rle
    cmp     cl, 3
    je      .ec_rne
    cmp     cl, 4
    je      .ec_rgt
.ec_rge:
    cmp     bx, ax
    jge     .ec_true
    jmp     .ec_false
.ec_req:
    cmp     bx, ax
    je      .ec_true
    jmp     .ec_false
.ec_rlt:
    cmp     bx, ax
    jl      .ec_true
    jmp     .ec_false
.ec_rle:
    cmp     bx, ax
    jle     .ec_true
    jmp     .ec_false
.ec_rne:
    cmp     bx, ax
    jne     .ec_true
    jmp     .ec_false
.ec_rgt:
    cmp     bx, ax
    jg      .ec_true
    jmp     .ec_false
.ec_true:
    mov     ax, -1
    ret
.ec_false:
    xor     ax, ax
    ret

ev_arith:
    call    ev_term
.er_l:
    call    skip_sp
    mov     bx, [pp]
    mov     dl, [bx]
    cmp     dl, '+'
    je      .er_add
    cmp     dl, '-'
    je      .er_sub
    ret
.er_add:
    inc     word ptr [pp]
    push    ax
    call    ev_term
    pop     bx
    add     ax, bx
    jmp     .er_l
.er_sub:
    inc     word ptr [pp]
    push    ax
    call    ev_term
    pop     bx
    sub     bx, ax
    mov     ax, bx
    jmp     .er_l

ev_term:
    call    ev_primary
.et_l:
    call    skip_sp
    mov     bx, [pp]
    mov     dl, [bx]
    cmp     dl, '*'
    je      .et_mul
    cmp     dl, '/'
    je      .et_div
    push    ax
    mov     di, offset kw_MOD
    call    try_kw
    mov     dl, al
    pop     ax
    test    dl, dl
    jnz     .et_mod
    ret
.et_mul:
    inc     word ptr [pp]
    push    ax
    call    ev_primary
    pop     bx
    imul    bx
    jmp     .et_l
.et_div:
    inc     word ptr [pp]
    push    ax
    call    ev_primary
    mov     bx, ax
    pop     ax
    test    bx, bx
    jz      .et_dz
    cwd
    idiv    bx
    jmp     .et_l
.et_mod:
    push    ax
    call    ev_primary
    mov     bx, ax
    pop     ax
    test    bx, bx
    jz      .et_dz
    cwd
    idiv    bx
    mov     ax, dx
    jmp     .et_l
.et_dz:
    mov     byte ptr [err_flag], 1
    xor     ax, ax
    jmp     .et_l

ev_primary:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '('
    jne     .ep_neg
    inc     word ptr [pp]
    call    eval_num
    call    expect_rparen
    ret
.ep_neg:
    cmp     al, '-'
    jne     .ep_num
    inc     word ptr [pp]
    call    ev_primary
    neg     ax
    ret
.ep_num:
    cmp     al, '0'
    jb      .ep_id
    cmp     al, '9'
    ja      .ep_id
    call    parse_uint
    ret
.ep_id:
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .ep_err
    mov     si, offset idbuf
    mov     di, offset kw_NOT
    call    streq
    test    al, al
    jz      .ep_len
    mov     ax, [peek_end]
    mov     [pp], ax
    call    ev_primary
    test    ax, ax
    jz      .ep_nottrue
    xor     ax, ax
    ret
.ep_nottrue:
    mov     ax, -1
    ret
.ep_len:
    mov     si, offset idbuf
    mov     di, offset kw_LEN
    call    streq
    test    al, al
    jz      .ep_asc
    mov     ax, [peek_end]
    mov     [pp], ax
    call    expect_lparen
    call    eval_str
    call    expect_rparen
    mov     ax, [slen]
    ret
.ep_asc:
    mov     si, offset idbuf
    mov     di, offset kw_ASC
    call    streq
    test    al, al
    jz      .ep_rnd
    mov     ax, [peek_end]
    mov     [pp], ax
    call    expect_lparen
    call    eval_str
    call    expect_rparen
    mov     bx, offset sbuf1
    mov     al, [bx]
    xor     ah, ah
    ret
.ep_rnd:
    mov     si, offset idbuf
    mov     di, offset kw_RND
    call    streq
    test    al, al
    jz      .ep_abs
    mov     ax, [peek_end]
    mov     [pp], ax
    call    expect_lparen
    call    eval_num
    call    expect_rparen
    push    ax
    call    rand
    pop     bx
    test    bx, bx
    jz      .ep_rndz
    xor     dx, dx
    div     bx
    mov     ax, dx
    inc     ax
    ret
.ep_rndz:
    xor     ax, ax
    ret
.ep_abs:
    mov     si, offset idbuf
    mov     di, offset kw_ABS
    call    streq
    test    al, al
    jz      .ep_var
    mov     ax, [peek_end]
    mov     [pp], ax
    call    expect_lparen
    call    eval_num
    call    expect_rparen
    test    ax, ax
    jns     .ep_var2
    neg     ax
.ep_var2:
    ret
.ep_var:
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .ep_err
    mov     ax, [peek_end]
    mov     [pp], ax
    call    num_get
    ret
.ep_err:
    mov     byte ptr [err_flag], 1
    xor     ax, ax
    ret

# ---- string expression evaluator (literal | var$ | CHR$(n), joined by +) ----

eval_str:
    mov     ax, offset sbuf1
    mov     [sptr], ax
    call    str_prim
.es_l:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '+'
    jne     .es_d
    inc     word ptr [pp]
    call    str_prim
    jmp     .es_l
.es_d:
    mov     bx, [sptr]
    mov     byte ptr [bx], 0
    mov     ax, bx
    sub     ax, offset sbuf1
    mov     [slen], ax
    ret

str_prim:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '"'
    je      .stp_lit
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .stp_err
    mov     si, offset idbuf
    mov     di, offset kw_CHR
    call    streq
    test    al, al
    jz      .stp_var
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    jne     .stp_err
    mov     ax, [peek_end]
    inc     ax
    mov     [pp], ax
    call    expect_lparen
    call    eval_num
    call    expect_rparen
    mov     bx, [sptr]
    mov     [bx], al
    inc     bx
    mov     [sptr], bx
    ret
.stp_var:
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    jne     .stp_err
    mov     ax, [peek_end]
    inc     ax
    mov     [pp], ax
    call    str_get_ptr
.stp_vc:
    mov     al, [si]
    test    al, al
    jz      .stp_vd
    mov     bx, [sptr]
    mov     [bx], al
    inc     bx
    mov     [sptr], bx
    inc     si
    jmp     .stp_vc
.stp_vd:
    ret
.stp_lit:
    inc     word ptr [pp]
.stp_lc:
    mov     bx, [pp]
    mov     al, [bx]
    test    al, al
    jz      .stp_ld
    cmp     al, '"'
    je      .stp_le
    mov     bx, [sptr]
    mov     [bx], al
    inc     bx
    mov     [sptr], bx
    inc     word ptr [pp]
    jmp     .stp_lc
.stp_le:
    inc     word ptr [pp]
.stp_ld:
    ret
.stp_err:
    mov     byte ptr [err_flag], 1
    ret

# is_string_ctx: AL=1 if the expression at [pp] is string-typed (literal or X$).
is_string_ctx:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '"'
    je      .sc_yes
    cmp     al, 'A'
    jb      .sc_lo
    cmp     al, 'Z'
    jbe     .sc_id
.sc_lo:
    cmp     al, 'a'
    jb      .sc_no
    cmp     al, 'z'
    ja      .sc_no
.sc_id:
    mov     di, offset kwbuf
    call    peek_ident
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .sc_yes
.sc_no:
    xor     al, al
    ret
.sc_yes:
    mov     al, 1
    ret

# ---- statements ----

do_print:
.pr_l:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    test    al, al
    jz      .pr_nl
    call    is_string_ctx
    test    al, al
    jz      .pr_num
    call    eval_str
    mov     si, offset sbuf1
    call    puts
    jmp     .pr_sep
.pr_num:
    call    eval_num
    call    print_int
.pr_sep:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, ';'
    je      .pr_semi
    cmp     al, ','
    je      .pr_comma
    jmp     .pr_nl
.pr_semi:
    inc     word ptr [pp]
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    test    al, al
    jz      .pr_done
    jmp     .pr_l
.pr_comma:
    inc     word ptr [pp]
    mov     al, ' '
    call    putc
    call    putc
    call    putc
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    test    al, al
    jz      .pr_done
    jmp     .pr_l
.pr_nl:
    call    newline
.pr_done:
    ret

do_assign:
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .as_err
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .as_str
    mov     ax, [peek_end]
    mov     [pp], ax
    call    num_index
    mov     [as_slot], di
    call    expect_eq
    call    eval_num
    mov     di, [as_slot]
    mov     [num_vals + di], ax
    ret
.as_str:
    mov     ax, [peek_end]
    inc     ax
    mov     [pp], ax
    call    str_get_ptr
    mov     [as_dst], si
    call    expect_eq
    call    eval_str
    mov     di, [as_dst]
    mov     si, offset sbuf1
    mov     cx, 63
.as_cp:
    mov     al, [si]
    mov     [di], al
    test    al, al
    jz      .as_d
    inc     si
    inc     di
    dec     cx
    jnz     .as_cp
    mov     byte ptr [di], 0
.as_d:
    ret
.as_err:
    mov     byte ptr [err_flag], 1
    ret

do_input:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '"'
    jne     .in_q
    call    eval_str
    mov     si, offset sbuf1
    call    puts
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, ';'
    je      .in_p2
    cmp     al, ','
    jne     .in_q
.in_p2:
    inc     word ptr [pp]
.in_q:
    mov     al, '?'
    call    putc
    mov     al, ' '
    call    putc
    call    read_line
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .in_err
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .in_str
    mov     ax, [peek_end]
    mov     [pp], ax
    mov     si, offset cmdbuf
    call    str_to_int
    call    num_set
    ret
.in_str:
    mov     ax, [peek_end]
    inc     ax
    mov     [pp], ax
    call    str_get_ptr
    mov     di, si
    mov     si, offset cmdbuf
    mov     cx, 63
.in_cp:
    mov     al, [si]
    mov     [di], al
    test    al, al
    jz      .in_d
    inc     si
    inc     di
    dec     cx
    jnz     .in_cp
    mov     byte ptr [di], 0
.in_d:
    ret
.in_err:
    mov     byte ptr [err_flag], 1
    ret

# num_set: idbuf, AX -> store.
num_set:
    push    ax
    call    num_index
    pop     ax
    mov     [num_vals + di], ax
    ret

do_if:
    call    is_string_ctx
    test    al, al
    jz      .if_num
    call    eval_str
    mov     si, offset sbuf1
    mov     di, offset sbuf2
.if_cl:
    mov     al, [si]
    mov     [di], al
    test    al, al
    jz      .if_cld
    inc     si
    inc     di
    jmp     .if_cl
.if_cld:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    mov     cl, 0
    cmp     al, '='
    je      .if_seq
    cmp     al, '<'
    jne     .if_serr
    inc     word ptr [pp]
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, '>'
    jne     .if_serr
    inc     word ptr [pp]
    mov     cl, 1
    jmp     .if_srhs
.if_seq:
    inc     word ptr [pp]
.if_srhs:
    push    cx
    call    eval_str
    pop     cx
    mov     si, offset sbuf2
    mov     di, offset sbuf1
    call    streq
    test    cl, cl
    jz      .if_set
    xor     al, 1
.if_set:
    mov     [if_truth], al
    jmp     .if_disp
.if_num:
    call    eval_num
    mov     byte ptr [if_truth], 0
    test    ax, ax
    jz      .if_disp
    mov     byte ptr [if_truth], 1
.if_disp:
    mov     di, offset kw_THEN
    call    try_kw
    cmp     byte ptr [if_truth], 0
    je      .if_skip
    call    dispatch_one
.if_skip:
    ret
.if_serr:
    mov     byte ptr [err_flag], 1
    ret

do_goto:
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .gt_err
    mov     ax, [peek_end]
    mov     [pp], ax
    call    label_find
    cmp     ax, -1
    je      .gt_err
    mov     [next_line], ax
    ret
.gt_err:
    mov     byte ptr [err_flag], 1
    ret

do_gosub:
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .gs_err
    mov     ax, [peek_end]
    mov     [pp], ax
    call    label_find
    cmp     ax, -1
    je      .gs_err
    mov     bx, [gosub_sp]
    cmp     bx, 8
    jae     .gs_err
    push    ax
    mov     ax, [runline]
    inc     ax
    mov     di, bx
    shl     di, 1
    mov     [gosub_ret + di], ax
    inc     word ptr [gosub_sp]
    pop     ax
    mov     [next_line], ax
    ret
.gs_err:
    mov     byte ptr [err_flag], 1
    ret

do_return:
    mov     bx, [gosub_sp]
    test    bx, bx
    jz      .rt_err
    dec     bx
    mov     [gosub_sp], bx
    shl     bx, 1
    mov     ax, [gosub_ret + bx]
    mov     [next_line], ax
    ret
.rt_err:
    mov     byte ptr [err_flag], 1
    ret

do_for:
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .fr_err
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, '$'
    je      .fr_err
    mov     ax, [peek_end]
    mov     [pp], ax
    call    num_index
    mov     [for_slot_tmp], di
    call    expect_eq
    call    eval_num
    mov     di, [for_slot_tmp]
    mov     [num_vals + di], ax
    mov     di, offset kw_TO
    call    try_kw
    test    al, al
    jz      .fr_err
    call    eval_num
    mov     [for_limit_tmp], ax
    mov     word ptr [for_step_tmp], 1
    mov     di, offset kw_STEP
    call    try_kw
    test    al, al
    jz      .fr_decide
    call    eval_num
    mov     [for_step_tmp], ax
.fr_decide:
    mov     di, [for_slot_tmp]
    mov     ax, [num_vals + di]
    mov     bx, [for_limit_tmp]
    mov     cx, [for_step_tmp]
    test    cx, cx
    js      .fr_neg
    cmp     ax, bx
    jle     .fr_do
    jmp     .fr_skip
.fr_neg:
    cmp     ax, bx
    jge     .fr_do
.fr_skip:
    call    find_matching_next
    cmp     ax, -1
    je      .fr_err
    inc     ax
    mov     [next_line], ax
    ret
.fr_do:
    mov     si, [for_sp]
    cmp     si, 8
    jae     .fr_err
    shl     si, 1
    mov     ax, [for_slot_tmp]
    mov     [for_var + si], ax
    mov     ax, [for_limit_tmp]
    mov     [for_limit + si], ax
    mov     ax, [for_step_tmp]
    mov     [for_step + si], ax
    mov     ax, [runline]
    inc     ax
    mov     [for_body + si], ax
    inc     word ptr [for_sp]
    ret
.fr_err:
    mov     byte ptr [err_flag], 1
    ret

do_next:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    cmp     al, 'A'
    jb      .nx_lo
    cmp     al, 'Z'
    jbe     .nx_consume
.nx_lo:
    cmp     al, 'a'
    jb      .nx_main
    cmp     al, 'z'
    ja      .nx_main
.nx_consume:
    mov     di, offset idbuf
    call    peek_ident
    mov     ax, [peek_end]
    mov     [pp], ax
.nx_main:
    mov     si, [for_sp]
    test    si, si
    jz      .nx_err
    dec     si
    shl     si, 1
    mov     di, [for_var + si]
    mov     ax, [num_vals + di]
    add     ax, [for_step + si]
    mov     [num_vals + di], ax
    mov     bx, [for_limit + si]
    mov     cx, [for_step + si]
    test    cx, cx
    js      .nx_neg
    cmp     ax, bx
    jle     .nx_loop
    jmp     .nx_pop
.nx_neg:
    cmp     ax, bx
    jge     .nx_loop
.nx_pop:
    dec     word ptr [for_sp]
    ret
.nx_loop:
    mov     ax, [for_body + si]
    mov     [next_line], ax
    ret
.nx_err:
    mov     byte ptr [err_flag], 1
    ret

do_while:
    call    eval_num
    test    ax, ax
    jnz     .wh_true
    call    find_matching_wend
    cmp     ax, -1
    je      .wh_err
    inc     ax
    mov     [next_line], ax
    ret
.wh_true:
    ret
.wh_err:
    mov     byte ptr [err_flag], 1
    ret

do_wend:
    call    find_matching_while
    cmp     ax, -1
    je      .we_err
    mov     [next_line], ax
    ret
.we_err:
    mov     byte ptr [err_flag], 1
    ret

# ---- run engine ----

basic_run:
    mov     byte ptr [err_flag], 0
    mov     byte ptr [halt], 0
    mov     word ptr [for_sp], 0
    mov     word ptr [gosub_sp], 0
    call    build_lines
    mov     word ptr [runline], 0
.br_l:
    mov     ax, [runline]
    cmp     ax, [num_lines]
    jae     .br_d
    inc     ax
    mov     [next_line], ax
    call    load_line_work
    call    exec_line
    cmp     byte ptr [err_flag], 0
    jne     .br_err
    cmp     byte ptr [halt], 0
    jne     .br_d
    mov     ax, [next_line]
    mov     [runline], ax
    jmp     .br_l
.br_err:
    mov     si, offset basic_errmsg
    call    puts
.br_d:
    ret

# build_lines: index every line; register labels.
build_lines:
    mov     word ptr [num_lines], 0
    mov     word ptr [lbl_count], 0
    mov     cx, [prog_len]
    test    cx, cx
    jz      .bln_d
    xor     bx, bx
.bln_start:
    mov     di, [num_lines]
    cmp     di, 256
    jae     .bln_scan
    shl     di, 1
    mov     [line_index + di], bx
    inc     word ptr [num_lines]
    push    bx
    push    cx
    call    register_label_at
    pop     cx
    pop     bx
.bln_scan:
    test    cx, cx
    jz      .bln_d
    mov     al, [prog_buf + bx]
    inc     bx
    dec     cx
    cmp     al, 0x0A
    jne     .bln_scan
    test    cx, cx
    jz      .bln_d
    jmp     .bln_start
.bln_d:
    ret

# register_label_at: BX = line offset. If the line is "name:", register the
# label -> current line index (num_lines-1).
register_label_at:
    mov     ax, offset prog_buf
    add     ax, bx
    mov     [pp], ax
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .rla_no
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, ':'
    jne     .rla_no
    mov     ax, [lbl_count]
    cmp     ax, 32
    jae     .rla_no
    mov     bx, 9
    mul     bx
    mov     di, offset lbl_names
    add     di, ax
    mov     si, offset idbuf
.rla_cp:
    mov     al, [si]
    mov     [di], al
    test    al, al
    jz      .rla_cpd
    inc     si
    inc     di
    jmp     .rla_cp
.rla_cpd:
    mov     ax, [lbl_count]
    shl     ax, 1
    mov     di, ax
    mov     bx, [num_lines]
    dec     bx
    mov     [lbl_line + di], bx
    inc     word ptr [lbl_count]
.rla_no:
    ret

# label_find: idbuf -> AX = line index, or -1.
label_find:
    mov     cx, [lbl_count]
    xor     bx, bx
    mov     si, offset lbl_names
.lf_l:
    test    cx, cx
    jz      .lf_no
    push    si
    push    bx
    mov     di, offset idbuf
    call    streq
    pop     bx
    pop     si
    test    al, al
    jnz     .lf_found
    add     si, 9
    inc     bx
    dec     cx
    jmp     .lf_l
.lf_found:
    shl     bx, 1
    mov     ax, [lbl_line + bx]
    ret
.lf_no:
    mov     ax, -1
    ret

# load_line_work: copy line [runline] into line_work (NUL-terminated); pp = it.
load_line_work:
    mov     ax, [runline]
    shl     ax, 1
    mov     bx, ax
    mov     ax, [line_index + bx]
    mov     si, offset prog_buf
    add     si, ax
    mov     di, offset line_work
    xor     cx, cx
.llw_l:
    mov     al, [si]
    test    al, al
    jz      .llw_d
    cmp     al, 0x0A
    je      .llw_d
    cmp     cx, 250
    jae     .llw_d
    mov     [di], al
    inc     di
    inc     si
    inc     cx
    jmp     .llw_l
.llw_d:
    mov     byte ptr [di], 0
    mov     word ptr [pp], offset line_work
    ret

# exec_line: skip an optional leading "label:" then dispatch one statement.
exec_line:
    call    skip_sp
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .el_disp
    mov     bx, [peek_end]
    mov     al, [bx]
    cmp     al, ':'
    jne     .el_disp
    mov     ax, [peek_end]
    inc     ax
    mov     [pp], ax
.el_disp:
    call    dispatch_one
    ret

# dispatch_one: parse and execute a single statement at [pp].
dispatch_one:
    call    skip_sp
    mov     bx, [pp]
    mov     al, [bx]
    test    al, al
    jz      .d_ret
    cmp     al, 0x27
    je      .d_ret
    mov     di, offset idbuf
    call    peek_ident
    test    cx, cx
    jz      .d_ret
    mov     si, offset idbuf
    mov     di, offset kw_REM
    call    streq
    test    al, al
    jnz     .d_ret
    mov     si, offset idbuf
    mov     di, offset kw_PRINT
    call    streq
    test    al, al
    jnz     .d_print
    mov     si, offset idbuf
    mov     di, offset kw_LET
    call    streq
    test    al, al
    jnz     .d_let
    mov     si, offset idbuf
    mov     di, offset kw_IF
    call    streq
    test    al, al
    jnz     .d_if
    mov     si, offset idbuf
    mov     di, offset kw_FOR
    call    streq
    test    al, al
    jnz     .d_for
    mov     si, offset idbuf
    mov     di, offset kw_NEXT
    call    streq
    test    al, al
    jnz     .d_next
    mov     si, offset idbuf
    mov     di, offset kw_WHILE
    call    streq
    test    al, al
    jnz     .d_while
    mov     si, offset idbuf
    mov     di, offset kw_WEND
    call    streq
    test    al, al
    jnz     .d_wend
    mov     si, offset idbuf
    mov     di, offset kw_GOTO
    call    streq
    test    al, al
    jnz     .d_goto
    mov     si, offset idbuf
    mov     di, offset kw_GOSUB
    call    streq
    test    al, al
    jnz     .d_gosub
    mov     si, offset idbuf
    mov     di, offset kw_RETURN
    call    streq
    test    al, al
    jnz     .d_return
    mov     si, offset idbuf
    mov     di, offset kw_INPUT
    call    streq
    test    al, al
    jnz     .d_input
    mov     si, offset idbuf
    mov     di, offset kw_CLS
    call    streq
    test    al, al
    jnz     .d_cls
    mov     si, offset idbuf
    mov     di, offset kw_END
    call    streq
    test    al, al
    jnz     .d_end
    mov     si, offset idbuf
    mov     di, offset kw_STOP
    call    streq
    test    al, al
    jnz     .d_end
    call    do_assign
    ret
.d_print:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_print
    ret
.d_let:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_assign
    ret
.d_if:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_if
    ret
.d_for:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_for
    ret
.d_next:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_next
    ret
.d_while:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_while
    ret
.d_wend:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_wend
    ret
.d_goto:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_goto
    ret
.d_gosub:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_gosub
    ret
.d_return:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_return
    ret
.d_input:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    do_input
    ret
.d_cls:
    mov     ax, [peek_end]
    mov     [pp], ax
    call    cls
    ret
.d_end:
    mov     byte ptr [halt], 1
.d_ret:
    ret

# first_keyword_of: [scan_line] -> AL = KW_FOR/NEXT/WHILE/WEND or 0.
first_keyword_of:
    mov     ax, [scan_line]
    shl     ax, 1
    mov     bx, ax
    mov     ax, [line_index + bx]
    mov     si, offset prog_buf
    add     si, ax
.fkw_sp:
    mov     al, [si]
    cmp     al, ' '
    jne     .fkw_id
    inc     si
    jmp     .fkw_sp
.fkw_id:
    mov     di, offset kwbuf2
    xor     cx, cx
.fkw_l:
    mov     al, [si]
    cmp     al, 'A'
    jb      .fkw_lo
    cmp     al, 'Z'
    jbe     .fkw_take
.fkw_lo:
    cmp     al, 'a'
    jb      .fkw_end
    cmp     al, 'z'
    ja      .fkw_end
    sub     al, 0x20
.fkw_take:
    cmp     cx, 8
    jae     .fkw_skip
    mov     [di], al
    inc     di
.fkw_skip:
    inc     cx
    inc     si
    jmp     .fkw_l
.fkw_end:
    mov     byte ptr [di], 0
    mov     si, offset kwbuf2
    mov     di, offset kw_FOR
    call    streq
    test    al, al
    jnz     .fkw_rfor
    mov     si, offset kwbuf2
    mov     di, offset kw_NEXT
    call    streq
    test    al, al
    jnz     .fkw_rnext
    mov     si, offset kwbuf2
    mov     di, offset kw_WHILE
    call    streq
    test    al, al
    jnz     .fkw_rwhile
    mov     si, offset kwbuf2
    mov     di, offset kw_WEND
    call    streq
    test    al, al
    jnz     .fkw_rwend
    xor     al, al
    ret
.fkw_rfor:
    mov     al, KW_FOR
    ret
.fkw_rnext:
    mov     al, KW_NEXT
    ret
.fkw_rwhile:
    mov     al, KW_WHILE
    ret
.fkw_rwend:
    mov     al, KW_WEND
    ret

find_matching_next:
    mov     word ptr [scan_depth], 1
    mov     ax, [runline]
.fmn_l:
    inc     ax
    cmp     ax, [num_lines]
    jae     .fmn_no
    mov     [scan_line], ax
    call    first_keyword_of
    cmp     al, KW_FOR
    jne     .fmn_c
    inc     word ptr [scan_depth]
    jmp     .fmn_n
.fmn_c:
    cmp     al, KW_NEXT
    jne     .fmn_n
    dec     word ptr [scan_depth]
    cmp     word ptr [scan_depth], 0
    jne     .fmn_n
    mov     ax, [scan_line]
    ret
.fmn_n:
    mov     ax, [scan_line]
    jmp     .fmn_l
.fmn_no:
    mov     ax, -1
    ret

find_matching_wend:
    mov     word ptr [scan_depth], 1
    mov     ax, [runline]
.fmw_l:
    inc     ax
    cmp     ax, [num_lines]
    jae     .fmw_no
    mov     [scan_line], ax
    call    first_keyword_of
    cmp     al, KW_WHILE
    jne     .fmw_c
    inc     word ptr [scan_depth]
    jmp     .fmw_n
.fmw_c:
    cmp     al, KW_WEND
    jne     .fmw_n
    dec     word ptr [scan_depth]
    cmp     word ptr [scan_depth], 0
    jne     .fmw_n
    mov     ax, [scan_line]
    ret
.fmw_n:
    mov     ax, [scan_line]
    jmp     .fmw_l
.fmw_no:
    mov     ax, -1
    ret

find_matching_while:
    mov     word ptr [scan_depth], 1
    mov     ax, [runline]
.fmwh_l:
    test    ax, ax
    jz      .fmwh_no
    dec     ax
    mov     [scan_line], ax
    call    first_keyword_of
    cmp     al, KW_WEND
    jne     .fmwh_c
    inc     word ptr [scan_depth]
    jmp     .fmwh_n
.fmwh_c:
    cmp     al, KW_WHILE
    jne     .fmwh_n
    dec     word ptr [scan_depth]
    cmp     word ptr [scan_depth], 0
    jne     .fmwh_n
    mov     ax, [scan_line]
    ret
.fmwh_n:
    mov     ax, [scan_line]
    jmp     .fmwh_l
.fmwh_no:
    mov     ax, -1
    ret

# ============================================================================
#  GUI - a graphical desktop (VGA mode 13h, 320x200x256)
#
#  Stage 1: enter graphics mode, paint a desktop and a window with a title bar
#  and text (rendered with the BIOS 8x8 font, which works in graphics modes).
#  Mouse + draggable windows come next.
# ============================================================================

do_gui:
    mov     ax, 0x0013          # 320x200, 256 colours
    int     0x10

    # desktop background (teal)
    mov     word ptr [gx], 0
    mov     word ptr [gy], 0
    mov     word ptr [gw], 320
    mov     word ptr [gh], 200
    mov     byte ptr [gcolor], 3
    call    grect

    # window: white frame, black interior
    mov     word ptr [gx], 48
    mov     word ptr [gy], 36
    mov     word ptr [gw], 224
    mov     word ptr [gh], 128
    mov     byte ptr [gcolor], 15
    call    grect
    mov     word ptr [gx], 50
    mov     word ptr [gy], 38
    mov     word ptr [gw], 220
    mov     word ptr [gh], 124
    mov     byte ptr [gcolor], 0
    call    grect

    # title bar (blue)
    mov     word ptr [gx], 50
    mov     word ptr [gy], 38
    mov     word ptr [gw], 220
    mov     word ptr [gh], 12
    mov     byte ptr [gcolor], 1
    call    grect

    # title + content text
    mov     byte ptr [gtcolor], 15
    mov     byte ptr [grow], 5
    mov     byte ptr [gcol], 7
    mov     si, offset gui_title
    call    gtext
    mov     byte ptr [grow], 8
    mov     byte ptr [gcol], 7
    mov     si, offset gui_l1
    call    gtext
    mov     byte ptr [grow], 10
    mov     byte ptr [gcol], 7
    mov     si, offset gui_l2
    call    gtext
    mov     byte ptr [grow], 12
    mov     byte ptr [gcol], 7
    mov     si, offset gui_l3
    call    gtext
    mov     byte ptr [grow], 14
    mov     byte ptr [gcol], 7
    mov     si, offset gui_l4
    call    gtext
    mov     byte ptr [gtcolor], 14
    mov     byte ptr [grow], 18
    mov     byte ptr [gcol], 7
    mov     si, offset gui_l5
    call    gtext

    # close button (red) at the top-right of the title bar
    mov     word ptr [gx], 256
    mov     word ptr [gy], 39
    mov     word ptr [gw], 12
    mov     word ptr [gh], 10
    mov     byte ptr [gcolor], 12
    call    grect
    mov     byte ptr [gtcolor], 15
    mov     byte ptr [grow], 4
    mov     byte ptr [gcol], 32
    mov     si, offset gui_x
    call    gtext

    # desktop icons
    mov     word ptr [gx], 14
    mov     word ptr [gy], 20
    mov     word ptr [gw], 20
    mov     word ptr [gh], 16
    mov     byte ptr [gcolor], 14
    call    grect
    mov     word ptr [gx], 14
    mov     word ptr [gy], 64
    mov     word ptr [gw], 20
    mov     word ptr [gh], 16
    mov     byte ptr [gcolor], 11
    call    grect

    # taskbar
    mov     word ptr [gx], 0
    mov     word ptr [gy], 190
    mov     word ptr [gw], 320
    mov     word ptr [gh], 10
    mov     byte ptr [gcolor], 7
    call    grect
    mov     byte ptr [gtcolor], 1
    mov     byte ptr [grow], 24
    mov     byte ptr [gcol], 1
    mov     si, offset gui_task
    call    gtext

    # bring up the PS/2 mouse and run the cursor loop
    call    mouse_init
    mov     word ptr [mouse_x], 156
    mov     word ptr [mouse_y], 96
    mov     byte ptr [mouse_btn], 0
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
.gui_loop:
    mov     ah, 0x01
    int     0x16                # a key exits
    jnz     .gui_exit
    test    byte ptr [mouse_btn], 1   # left click: only the close box exits
    jz      .gui_chkmove
    mov     ax, [mouse_x]
    cmp     ax, 256
    jl      .gui_chkmove
    cmp     ax, 268
    jg      .gui_chkmove
    mov     ax, [mouse_y]
    cmp     ax, 38
    jl      .gui_chkmove
    cmp     ax, 50
    jg      .gui_chkmove
    jmp     .gui_exit
.gui_chkmove:
    mov     ax, [mouse_x]       # redraw only when the pointer moved
    cmp     ax, [cur_drawn_x]
    jne     .gui_move
    mov     ax, [mouse_y]
    cmp     ax, [cur_drawn_y]
    jne     .gui_move
    jmp     .gui_loop
.gui_move:
    call    cursor_restore
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
    jmp     .gui_loop
.gui_exit:
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    jmp     shell_loop

# grect: fill rectangle [gx,gy,gw,gh] with colour [gcolor]. ES -> 0xA000.
grect:
    mov     ax, 0xA000
    mov     es, ax
    mov     cx, [gh]
    mov     bx, [gy]
.grc_row:
    test    cx, cx
    jz      .grc_done
    mov     ax, bx
    mov     dx, 320
    mul     dx
    add     ax, [gx]
    mov     di, ax
    mov     al, [gcolor]
    push    cx
    mov     cx, [gw]
    rep     stosb
    pop     cx
    inc     bx
    dec     cx
    jmp     .grc_row
.grc_done:
    ret

# gtext: print the string at SI starting at char cell [grow],[gcol] in colour
# [gtcolor], using the BIOS 8x8 font (works in graphics mode).
gtext:
    push    si
    mov     ah, 0x02
    mov     bh, 0
    mov     dh, [grow]
    mov     dl, [gcol]
    int     0x10
    pop     si
.gtx_l:
    lodsb
    test    al, al
    jz      .gtx_d
    mov     ah, 0x0E
    mov     bl, [gtcolor]
    mov     bh, 0
    int     0x10
    jmp     .gtx_l
.gtx_d:
    ret

# get_font: fetch the ROM 8x8 font pointer (chars 0-127) into font_seg:font_off.
get_font:
    push    bp
    mov     ax, 0x1130
    mov     bh, 0x03
    int     0x10                # -> ES:BP = font, 8 bytes/char
    mov     [font_seg], es
    mov     [font_off], bp
    pop     bp
    ret

# draw_char: render AL as an 8x8 glyph at [gpx],[gpy] in colour [gtcolor] with a
# TRANSPARENT background (only set pixels are drawn).
draw_char:
    push    ax
    xor     ah, ah
    mov     bx, ax
    shl     bx, 3               # char * 8
    add     bx, [font_off]
    mov     ax, [font_seg]
    mov     es, ax
    mov     si, bx
    mov     di, offset glyphbuf
    mov     cx, 8
.dch_copy:
    mov     al, es:[si]
    mov     [di], al
    inc     si
    inc     di
    dec     cx
    jnz     .dch_copy
    pop     ax
    mov     ax, 0xA000
    mov     es, ax
    xor     bp, bp
.dch_row:
    cmp     bp, 8
    jae     .dch_done
    mov     ax, [gpy]
    add     ax, bp
    mov     dx, 320
    mul     dx
    add     ax, [gpx]
    mov     di, ax
    mov     bx, offset glyphbuf
    add     bx, bp
    mov     dl, [bx]            # this row's 8 bits
    mov     cx, 8
    mov     ah, 0x80            # leftmost pixel first
.dch_col:
    test    dl, ah
    jz      .dch_skip
    mov     al, [gtcolor]
    mov     es:[di], al
.dch_skip:
    inc     di
    shr     ah, 1
    dec     cx
    jnz     .dch_col
    inc     bp
    jmp     .dch_row
.dch_done:
    ret

# gtext_t: draw the string at SI at pixel [gpx],[gpy] in [gtcolor], transparent.
gtext_t:
    mov     al, [si]
    test    al, al
    jz      .gtt_d
    push    si
    call    draw_char
    pop     si
    add     word ptr [gpx], 8
    inc     si
    jmp     gtext_t
.gtt_d:
    ret

# ---- PS/2 mouse (8042 controller + IRQ12 ISR, polled cursor loop) ----

# kbc_wait_in: wait until the controller input buffer is empty (status bit 1=0).
kbc_wait_in:
    push    cx
    mov     cx, 0xFFFF
.kwi_l:
    in      al, 0x64
    test    al, 2
    jz      .kwi_d
    loop    .kwi_l
.kwi_d:
    pop     cx
    ret

# kbc_wait_out: wait until output buffer is full (status bit 0=1).
kbc_wait_out:
    push    cx
    mov     cx, 0xFFFF
.kwo_l:
    in      al, 0x64
    test    al, 1
    jnz     .kwo_d
    loop    .kwo_l
.kwo_d:
    pop     cx
    ret

# mouse_init: install the IRQ12 handler, unmask the PIC, enable the aux device
# and data reporting.
mouse_init:
    mov     byte ptr [mpkt_idx], 0
    # install ISR at IVT vector 0x74 (IRQ12)
    cli
    xor     ax, ax
    mov     es, ax
    mov     word ptr es:[0x74*4], offset mouse_isr
    mov     word ptr es:[0x74*4+2], cs
    # unmask IRQ12 (slave bit 4) and IRQ2 cascade (master bit 2)
    in      al, 0xA1
    and     al, 0xEF
    out     0xA1, al
    in      al, 0x21
    and     al, 0xFB
    out     0x21, al
    # enable the auxiliary (mouse) device
    call    kbc_wait_in
    mov     al, 0xA8
    out     0x64, al
    # read the controller config byte, enable IRQ12 + mouse clock
    call    kbc_wait_in
    mov     al, 0x20
    out     0x64, al
    call    kbc_wait_out
    in      al, 0x60
    or      al, 0x02            # enable IRQ12
    and     al, 0xDF            # enable mouse clock
    mov     bl, al
    call    kbc_wait_in
    mov     al, 0x60
    out     0x64, al
    call    kbc_wait_in
    mov     al, bl
    out     0x60, al
    # enable data reporting (0xF4) on the mouse
    call    kbc_wait_in
    mov     al, 0xD4
    out     0x64, al
    call    kbc_wait_in
    mov     al, 0xF4
    out     0x60, al
    call    kbc_wait_out
    in      al, 0x60            # eat the ACK
    sti
    ret

# mouse_off: disable reporting and mask IRQ12 again.
mouse_off:
    # mask IRQ12 first so the ISR stops firing during teardown
    in      al, 0xA1
    or      al, 0x10
    out     0xA1, al
    # tell the mouse to stop reporting: 0xD4 (address aux), then 0xF5 to the
    # DATA port (0x60) - the original bug sent it to 0x64, so the mouse kept
    # streaming and flooded the keyboard controller after exit.
    call    kbc_wait_in
    mov     al, 0xD4
    out     0x64, al
    call    kbc_wait_in
    mov     al, 0xF5
    out     0x60, al
    call    kbc_wait_out
    in      al, 0x60            # eat the ACK
    # drain any leftover bytes from the controller output buffer
.moff_flush:
    in      al, 0x64
    test    al, 1
    jz      .moff_done
    in      al, 0x60
    jmp     .moff_flush
.moff_done:
    ret

# mouse_isr: IRQ12 handler. Reads one byte, assembles 3-byte packets, applies
# movement, and sends EOI to both PICs.
mouse_isr:
    push    ax
    push    bx
    push    ds
    mov     ax, 0x1000
    mov     ds, ax
    in      al, 0x64
    test    al, 0x20            # is it really aux (mouse) data?
    jz      .isr_eoi
    in      al, 0x60
    mov     bl, [mpkt_idx]
    cmp     bl, 0
    je      .isr_b0
    cmp     bl, 1
    je      .isr_b1
    mov     [mpkt2], al
    mov     byte ptr [mpkt_idx], 0
    call    mouse_apply
    jmp     .isr_eoi
.isr_b0:
    test    al, 0x08            # sync bit must be set on byte 0
    jz      .isr_eoi
    mov     [mpkt0], al
    mov     byte ptr [mpkt_idx], 1
    jmp     .isr_eoi
.isr_b1:
    mov     [mpkt1], al
    mov     byte ptr [mpkt_idx], 2
.isr_eoi:
    mov     al, 0x20
    out     0xA0, al            # EOI to slave PIC
    out     0x20, al            # EOI to master PIC
    pop     ds
    pop     bx
    pop     ax
    iret

# mouse_apply: turn the completed packet into a new cursor position + buttons.
mouse_apply:
    mov     al, [mpkt0]
    and     al, 7
    mov     [mouse_btn], al
    mov     al, [mpkt1]
    cbw                         # sign-extend dx
    add     [mouse_x], ax
    mov     ax, [mouse_x]
    test    ax, ax
    jns     .ma_xhi
    mov     word ptr [mouse_x], 0
    jmp     .ma_y
.ma_xhi:
    cmp     ax, 312
    jle     .ma_y
    mov     word ptr [mouse_x], 312
.ma_y:
    mov     al, [mpkt2]
    cbw                         # sign-extend dy
    sub     [mouse_y], ax       # screen Y is inverted vs PS/2
    mov     ax, [mouse_y]
    test    ax, ax
    jns     .ma_yhi
    mov     word ptr [mouse_y], 0
    ret
.ma_yhi:
    cmp     ax, 188
    jle     .ma_done
    mov     word ptr [mouse_y], 188
.ma_done:
    ret

# cursor_save: copy the 8x12 area under the cursor into cur_bg.
cursor_save:
    mov     ax, 0xA000
    mov     es, ax
    mov     si, offset cur_bg
    xor     bp, bp
.cs_row:
    cmp     bp, 12
    jae     .cs_done
    mov     ax, [cur_drawn_y]
    add     ax, bp
    mov     bx, 320
    mul     bx
    add     ax, [cur_drawn_x]
    mov     di, ax
    mov     cx, 8
.cs_col:
    mov     al, es:[di]
    mov     [si], al
    inc     si
    inc     di
    dec     cx
    jnz     .cs_col
    inc     bp
    jmp     .cs_row
.cs_done:
    ret

# cursor_restore: write cur_bg back to the screen.
cursor_restore:
    mov     ax, 0xA000
    mov     es, ax
    mov     si, offset cur_bg
    xor     bp, bp
.cr_row:
    cmp     bp, 12
    jae     .cr_done
    mov     ax, [cur_drawn_y]
    add     ax, bp
    mov     bx, 320
    mul     bx
    add     ax, [cur_drawn_x]
    mov     di, ax
    mov     cx, 8
.cr_col:
    mov     al, [si]
    mov     es:[di], al
    inc     si
    inc     di
    dec     cx
    jnz     .cr_col
    inc     bp
    jmp     .cr_row
.cr_done:
    ret

# cursor_draw: draw the arrow sprite (0=transparent, 1=black, 2=white).
cursor_draw:
    mov     ax, 0xA000
    mov     es, ax
    mov     si, offset cur_sprite
    xor     bp, bp
.cd_row:
    cmp     bp, 12
    jae     .cd_done
    mov     ax, [cur_drawn_y]
    add     ax, bp
    mov     bx, 320
    mul     bx
    add     ax, [cur_drawn_x]
    mov     di, ax
    mov     cx, 8
.cd_col:
    mov     al, [si]
    test    al, al
    jz      .cd_skip
    cmp     al, 1
    jne     .cd_white
    mov     byte ptr es:[di], 0
    jmp     .cd_skip
.cd_white:
    mov     byte ptr es:[di], 15
.cd_skip:
    inc     si
    inc     di
    dec     cx
    jnz     .cd_col
    inc     bp
    jmp     .cd_row
.cd_done:
    ret

# ============================================================================
#  PAINT - a Paintbrush-style drawing program (VGA mode 13h + PS/2 mouse)
#
#  Hold the left button to draw with a 3x3 brush in the current colour. Click
#  a swatch in the 16-colour palette along the bottom to change colour. Press
#  C to clear, ESC to quit. Reuses the GUI's mouse driver and cursor.
# ============================================================================

do_paint:
    mov     ax, 0x0013
    int     0x10
    # white canvas (top rows; palette occupies the bottom, within cursor reach)
    mov     word ptr [gx], 0
    mov     word ptr [gy], 0
    mov     word ptr [gw], 320
    mov     word ptr [gh], 178
    mov     byte ptr [gcolor], 15
    call    grect
    call    draw_palette
    mov     byte ptr [current_color], 0
    mov     byte ptr [painting], 0
    mov     byte ptr [prev_btn], 0

    call    mouse_init
    mov     word ptr [mouse_x], 156
    mov     word ptr [mouse_y], 90
    mov     byte ptr [mouse_btn], 0
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw

.paint_loop:
    # keyboard: ESC quits, C clears
    mov     ah, 0x01
    int     0x16
    jz      .pl_btn
    xor     ah, ah
    int     0x16
    cmp     al, 0x1B
    je      .paint_exit
    cmp     al, 'c'
    je      .pl_clear
    cmp     al, 'C'
    je      .pl_clear
    test    byte ptr [mouse_btn], 2   # right click also quits
    jnz     .paint_exit
.pl_btn:
    # edge-detect the left button
    mov     al, [mouse_btn]
    and     al, 1
    mov     [cur_btn], al
    cmp     al, [prev_btn]
    je      .pl_act
    test    byte ptr [cur_btn], 1
    jz      .pl_up_edge
    # button just pressed
    mov     ax, [mouse_y]
    cmp     ax, 178
    jl      .pl_start_paint
    # in the palette: pick a colour (x / 20)
    mov     ax, [mouse_x]
    mov     bl, 20
    div     bl
    mov     [current_color], al
    jmp     .pl_act
.pl_start_paint:
    call    cursor_restore      # hide the arrow while drawing
    mov     byte ptr [painting], 1
    jmp     .pl_act
.pl_up_edge:
    cmp     byte ptr [painting], 1
    jne     .pl_act
    mov     byte ptr [painting], 0
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
.pl_act:
    mov     al, [cur_btn]
    mov     [prev_btn], al
    cmp     byte ptr [painting], 1
    jne     .pl_movecursor
    # painting: stamp the brush (canvas area only)
    mov     ax, [mouse_y]
    cmp     ax, 176
    jge     .paint_loop
    call    paint_brush
    jmp     .paint_loop
.pl_movecursor:
    mov     ax, [mouse_x]
    cmp     ax, [cur_drawn_x]
    jne     .pl_move
    mov     ax, [mouse_y]
    cmp     ax, [cur_drawn_y]
    jne     .pl_move
    jmp     .paint_loop
.pl_move:
    call    cursor_restore
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
    jmp     .paint_loop
.pl_clear:
    mov     word ptr [gx], 0
    mov     word ptr [gy], 0
    mov     word ptr [gw], 320
    mov     word ptr [gh], 178
    mov     byte ptr [gcolor], 15
    call    grect
    call    cursor_save
    call    cursor_draw
    jmp     .paint_loop
.paint_exit:
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    jmp     shell_loop

# draw_palette: 16 colour swatches along the bottom (each 20px wide).
draw_palette:
    xor     bp, bp
.dp_l:
    cmp     bp, 16
    jae     .dp_done
    mov     ax, bp
    mov     bx, 20
    mul     bx
    mov     [gx], ax
    mov     word ptr [gy], 178
    mov     word ptr [gw], 20
    mov     word ptr [gh], 12
    mov     ax, bp
    mov     [gcolor], al
    call    grect
    inc     bp
    jmp     .dp_l
.dp_done:
    ret

# paint_brush: stamp a 3x3 block of [current_color] at the cursor.
paint_brush:
    mov     ax, 0xA000
    mov     es, ax
    xor     bp, bp
.pb_row:
    cmp     bp, 3
    jae     .pb_done
    mov     ax, [mouse_y]
    add     ax, bp
    mov     bx, 320
    mul     bx
    add     ax, [mouse_x]
    mov     di, ax
    mov     al, [current_color]
    mov     cx, 3
    rep     stosb
    inc     bp
    jmp     .pb_row
.pb_done:
    ret

# ============================================================================
#  DESKTOP - a Windows 95-style shell (taskbar, Start menu, clock, 3D windows)
#
#  Not the actual 32-bit multitasking OS (impossible here) - the recognizable
#  Win95 *desktop experience*: a Start button that opens a menu launching the
#  apps, a taskbar clock from the RTC, and grey 3D-beveled window chrome.
# ============================================================================

# draw_bevel: 3D rectangle [btx,bty,btw,bth], grey face, [bev_tl] top/left edge,
# [bev_br] bottom/right edge.
draw_bevel:
    mov     ax, [btx]
    mov     [gx], ax
    mov     ax, [bty]
    mov     [gy], ax
    mov     ax, [btw]
    mov     [gw], ax
    mov     ax, [bth]
    mov     [gh], ax
    mov     byte ptr [gcolor], 7
    call    grect
    mov     ax, [btx]
    mov     [gx], ax
    mov     ax, [bty]
    mov     [gy], ax
    mov     ax, [btw]
    mov     [gw], ax
    mov     word ptr [gh], 1
    mov     al, [bev_tl]
    mov     [gcolor], al
    call    grect
    mov     ax, [btx]
    mov     [gx], ax
    mov     ax, [bty]
    mov     [gy], ax
    mov     word ptr [gw], 1
    mov     ax, [bth]
    mov     [gh], ax
    mov     al, [bev_tl]
    mov     [gcolor], al
    call    grect
    mov     ax, [btx]
    mov     [gx], ax
    mov     ax, [bty]
    add     ax, [bth]
    dec     ax
    mov     [gy], ax
    mov     ax, [btw]
    mov     [gw], ax
    mov     word ptr [gh], 1
    mov     al, [bev_br]
    mov     [gcolor], al
    call    grect
    mov     ax, [btx]
    add     ax, [btw]
    dec     ax
    mov     [gx], ax
    mov     ax, [bty]
    mov     [gy], ax
    mov     word ptr [gw], 1
    mov     ax, [bth]
    mov     [gh], ax
    mov     al, [bev_br]
    mov     [gcolor], al
    call    grect
    ret

draw_raised:
    mov     byte ptr [bev_tl], 15
    mov     byte ptr [bev_br], 8
    call    draw_bevel
    ret

draw_sunken:
    mov     byte ptr [bev_tl], 8
    mov     byte ptr [bev_br], 15
    call    draw_bevel
    ret

# get_time_str: build "HH:MM" from the RTC into clockbuf.
get_time_str:
    mov     ah, 0x02
    int     0x1A                # CH=hours CL=min (BCD)
    mov     al, ch
    mov     bl, al
    shr     al, 4
    add     al, '0'
    mov     [clockbuf+0], al
    mov     al, bl
    and     al, 0x0F
    add     al, '0'
    mov     [clockbuf+1], al
    mov     byte ptr [clockbuf+2], ':'
    mov     al, cl
    mov     bl, al
    shr     al, 4
    add     al, '0'
    mov     [clockbuf+3], al
    mov     al, cl
    and     al, 0x0F
    add     al, '0'
    mov     [clockbuf+4], al
    mov     byte ptr [clockbuf+5], 0
    ret

# draw_taskbar: the grey taskbar, raised Start button, and sunken clock.
draw_taskbar:
    mov     word ptr [gx], 0
    mov     word ptr [gy], 182
    mov     word ptr [gw], 320
    mov     word ptr [gh], 18
    mov     byte ptr [gcolor], 7
    call    grect
    mov     word ptr [gx], 0
    mov     word ptr [gy], 182
    mov     word ptr [gw], 320
    mov     word ptr [gh], 1
    mov     byte ptr [gcolor], 15
    call    grect
    # Start button
    mov     word ptr [btx], 2
    mov     word ptr [bty], 184
    mov     word ptr [btw], 50
    mov     word ptr [bth], 14
    call    draw_raised
    mov     byte ptr [gtcolor], 0
    mov     word ptr [gpy], 184
    mov     word ptr [gpx], 10
    mov     si, offset ds_start
    call    gtext_t
    # clock panel
    mov     word ptr [btx], 266
    mov     word ptr [bty], 184
    mov     word ptr [btw], 52
    mov     word ptr [bth], 14
    call    draw_sunken
    call    get_time_str
    mov     byte ptr [gtcolor], 0
    mov     word ptr [gpy], 184
    mov     word ptr [gpx], 274
    mov     si, offset clockbuf
    call    gtext_t
    ret

# draw_desk: paint the whole desktop (background, icons, window, taskbar).
draw_desk:
    mov     word ptr [gx], 0
    mov     word ptr [gy], 0
    mov     word ptr [gw], 320
    mov     word ptr [gh], 182
    mov     byte ptr [gcolor], 3
    call    grect
    mov     byte ptr [gtcolor], 15
    mov     word ptr [gpx], 118
    mov     word ptr [gpy], 4
    mov     si, offset ds_hint
    call    gtext_t
    call    draw_icons
    call    draw_taskbar
    ret

# draw_icons: 8 app icons (coloured box + label) at their stored positions.
draw_icons:
    mov     word ptr [icon_i], 0
.di_l:
    mov     bx, [icon_i]
    cmp     bx, 9
    jae     .di_done
    shl     bx, 1
    mov     ax, [icon_x + bx]
    mov     [gx], ax
    mov     ax, [icon_y + bx]
    mov     [gy], ax
    mov     word ptr [gw], 28
    mov     word ptr [gh], 22
    mov     bx, [icon_i]
    mov     al, [ic_colors + bx]
    mov     [gcolor], al
    call    grect
    mov     bx, [icon_i]
    shl     bx, 1
    mov     ax, [icon_x + bx]
    mov     [gpx], ax
    mov     ax, [icon_y + bx]
    add     ax, 24
    mov     [gpy], ax
    mov     byte ptr [gtcolor], 15
    mov     bx, [icon_i]
    shl     bx, 1
    mov     si, [ic_labels + bx]
    call    gtext_t
    inc     word ptr [icon_i]
    jmp     .di_l
.di_done:
    ret

# init_icons: lay the 9 icons out in a 3-column grid.
init_icons:
    mov     word ptr [icon_i], 0
.ii_l:
    mov     ax, [icon_i]
    cmp     ax, 9
    jae     .ii_done
    xor     dx, dx
    mov     bx, 3
    div     bx                      # AX = row (i/3), DX = col (i%3)
    push    ax
    mov     ax, dx
    mov     bx, 68
    mul     bx
    add     ax, 12
    mov     bx, [icon_i]
    shl     bx, 1
    mov     [icon_x + bx], ax
    pop     ax
    mov     bx, 44
    mul     bx
    add     ax, 6
    mov     bx, [icon_i]
    shl     bx, 1
    mov     [icon_y + bx], ax
    inc     word ptr [icon_i]
    jmp     .ii_l
.ii_done:
    ret

# icon_hit: AX = icon index under (mouse_x,mouse_y), or -1.
icon_hit:
    mov     word ptr [icon_i], 0
.ih_l:
    mov     bx, [icon_i]
    cmp     bx, 9
    jae     .ih_no
    shl     bx, 1
    mov     dx, [icon_x + bx]
    mov     cx, [mouse_x]
    cmp     cx, dx
    jb      .ih_next
    add     dx, 44
    cmp     cx, dx
    jae     .ih_next
    mov     bx, [icon_i]
    shl     bx, 1
    mov     dx, [icon_y + bx]
    mov     cx, [mouse_y]
    cmp     cx, dx
    jb      .ih_next
    add     dx, 34
    cmp     cx, dx
    jae     .ih_next
    mov     ax, [icon_i]
    ret
.ih_next:
    inc     word ptr [icon_i]
    jmp     .ih_l
.ih_no:
    mov     ax, -1
    ret

# icon_launch: AX = icon index -> tear down the mouse and jump to that app.
icon_launch:
    mov     [icon_i], ax
    mov     byte ptr [in_desktop], 1   # apps launched here return to the desktop
    call    mouse_off
    mov     ax, [icon_i]
    cmp     ax, 1
    je      .il_paint
    cmp     ax, 3
    je      .il_basic
    cmp     ax, 4
    je      .il_eliza
    cmp     ax, 5
    je      .il_matrix
    cmp     ax, 8
    je      .il_daw
    # text-mode apps: snake(0), edit(2), guess(6), MS-DOS(7)
    mov     bx, ax
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    cmp     bx, 0
    je      do_snake
    cmp     bx, 2
    je      do_edit
    cmp     bx, 6
    je      do_guess
    mov     byte ptr [in_desktop], 0   # MS-DOS icon -> stay at the DOS prompt
    jmp     shell_loop
.il_paint:
    jmp     do_paint
.il_basic:
    jmp     do_basic
.il_eliza:
    jmp     do_eliza
.il_matrix:
    jmp     do_matrix
.il_daw:
    jmp     do_daw



do_desktop:
    mov     ax, 0x0013
    int     0x10
    call    get_font
    cmp     byte ptr [desktop_inited], 0   # lay out icons only on first entry,
    jne     .dt_noinit                     # so dragged positions persist
    call    init_icons
    mov     byte ptr [desktop_inited], 1
.dt_noinit:
    call    draw_desk
    call    mouse_init
    mov     word ptr [mouse_x], 156
    mov     word ptr [mouse_y], 100
    mov     byte ptr [mouse_btn], 0
    mov     byte ptr [prev_btn], 0
    mov     byte ptr [menu_open], 0
    mov     word ptr [drag_icon], -1
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
.dt_loop:
    mov     ah, 0x01
    int     0x16
    jnz     .dt_exit
    mov     al, [mouse_btn]
    and     al, 1
    mov     [cur_btn], al
    cmp     al, [prev_btn]
    je      .dt_held
    mov     [prev_btn], al
    test    byte ptr [cur_btn], 1
    jnz     .dt_press
    call    desk_release
    jmp     .dt_move
.dt_press:
    call    desk_press
    jmp     .dt_move
.dt_held:
    cmp     word ptr [drag_icon], -1
    je      .dt_move
    call    drag_move
.dt_move:
    mov     ax, [mouse_x]
    cmp     ax, [cur_drawn_x]
    jne     .dt_redraw
    mov     ax, [mouse_y]
    cmp     ax, [cur_drawn_y]
    jne     .dt_redraw
    jmp     .dt_loop
.dt_redraw:
    call    cursor_restore
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
    jmp     .dt_loop
.dt_exit:
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    mov     byte ptr [in_desktop], 0   # leaving the desktop -> DOS prompt
    jmp     shell_loop

# desk_press: left button just went down.
desk_press:
    cmp     byte ptr [menu_open], 1
    je      .dpr_menu
    mov     ax, [mouse_x]
    cmp     ax, 52
    jae     .dpr_nostart
    mov     ax, [mouse_y]
    cmp     ax, 184
    jb      .dpr_nostart
    call    open_menu
    ret
.dpr_nostart:
    call    icon_hit
    cmp     ax, -1
    je      .dpr_done
    mov     [drag_icon], ax
    mov     bx, ax
    shl     bx, 1
    mov     dx, [mouse_x]
    sub     dx, [icon_x + bx]
    mov     [grab_dx], dx
    mov     dx, [mouse_y]
    sub     dx, [icon_y + bx]
    mov     [grab_dy], dx
    mov     ax, [mouse_x]
    mov     [press_mx], ax
    mov     ax, [mouse_y]
    mov     [press_my], ax
.dpr_done:
    ret
.dpr_menu:
    call    menu_click
    ret

# desk_release: left button just went up. A barely-moved press = a click
# (launch the icon); a moved press = a drag (just drop it).
desk_release:
    cmp     word ptr [drag_icon], -1
    je      .dr_done
    mov     ax, [mouse_x]
    sub     ax, [press_mx]
    test    ax, ax
    jns     .dr_ax
    neg     ax
.dr_ax:
    mov     dx, [mouse_y]
    sub     dx, [press_my]
    test    dx, dx
    jns     .dr_dx
    neg     dx
.dr_dx:
    add     ax, dx
    cmp     ax, 5
    ja      .dr_drop
    mov     ax, [drag_icon]
    mov     word ptr [drag_icon], -1
    jmp     icon_launch
.dr_drop:
    mov     word ptr [drag_icon], -1
.dr_done:
    ret

# drag_move: button held over a grabbed icon -> move it and repaint.
drag_move:
    mov     bx, [drag_icon]
    shl     bx, 1
    mov     ax, [mouse_x]
    sub     ax, [grab_dx]
    test    ax, ax
    jns     .drm_x1
    xor     ax, ax
.drm_x1:
    cmp     ax, 290
    jbe     .drm_x2
    mov     ax, 290
.drm_x2:
    mov     cx, ax
    mov     ax, [mouse_y]
    sub     ax, [grab_dy]
    test    ax, ax
    jns     .drm_y1
    xor     ax, ax
.drm_y1:
    cmp     ax, 150
    jbe     .drm_y2
    mov     ax, 150
.drm_y2:
    mov     dx, ax
    cmp     cx, [icon_x + bx]
    jne     .drm_upd
    cmp     dx, [icon_y + bx]
    jne     .drm_upd
    ret
.drm_upd:
    mov     [icon_x + bx], cx
    mov     [icon_y + bx], dx
    call    draw_desk
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
    ret

# open_menu: draw the Start menu panel and its items.
open_menu:
    call    cursor_restore      # lift the cursor before painting the menu
    mov     byte ptr [menu_open], 1
    # menu panel (raised) above the Start button
    mov     word ptr [btx], 2
    mov     word ptr [bty], 78
    mov     word ptr [btw], 116
    mov     word ptr [bth], 104
    call    draw_raised
    # blue branding stripe down the left
    mov     word ptr [gx], 4
    mov     word ptr [gy], 80
    mov     word ptr [gw], 14
    mov     word ptr [gh], 100
    mov     byte ptr [gcolor], 1
    call    grect
    # items
    mov     byte ptr [gtcolor], 0
    mov     word ptr [gpx], 24
    mov     word ptr [gpy], 84
    mov     si, offset ds_m1
    call    gtext_t
    mov     word ptr [gpx], 24
    mov     word ptr [gpy], 108
    mov     si, offset ds_m2
    call    gtext_t
    mov     word ptr [gpx], 24
    mov     word ptr [gpy], 132
    mov     si, offset ds_m3
    call    gtext_t
    mov     word ptr [gpx], 24
    mov     word ptr [gpy], 156
    mov     si, offset ds_m4
    call    gtext_t
    # the cursor was painted over; re-establish it
    call    cursor_save
    call    cursor_draw
    ret

# menu_click: a click while the Start menu is open. Items occupy x 20..116;
# rows ~80,104,128,152 (24px tall each). Anything else closes the menu.
menu_click:
    mov     byte ptr [menu_open], 0
    mov     ax, [mouse_x]
    cmp     ax, 20
    jb      .mc_close
    cmp     ax, 118
    jae     .mc_close
    mov     ax, [mouse_y]
    cmp     ax, 78
    jb      .mc_close
    cmp     ax, 102
    jae     .mc_i2
    jmp     .mc_paint           # row 1: Paint
.mc_i2:
    cmp     ax, 126
    jae     .mc_i3
    jmp     .mc_snake           # row 2: Snake
.mc_i3:
    cmp     ax, 150
    jae     .mc_i4
    jmp     .mc_prompt          # row 3: MS-DOS Prompt
.mc_i4:
    cmp     ax, 182
    jae     .mc_close
    jmp     .mc_reboot          # row 4: Shut Down
.mc_paint:
    mov     byte ptr [in_desktop], 1
    call    mouse_off
    jmp     do_paint
.mc_snake:
    mov     byte ptr [in_desktop], 1
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    jmp     do_snake
.mc_prompt:
    mov     byte ptr [in_desktop], 0
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    jmp     shell_loop
.mc_reboot:
    call    mouse_off
    jmp     do_reboot
.mc_close:
    # just repaint the desktop to erase the menu, then redraw the cursor
    call    draw_desk
    call    cursor_save
    call    cursor_draw
    ret

# ============================================================================
#  DAW - a PC-speaker step sequencer ("Beep Studio")
#
#  A 16-step x 8-pitch grid. Click a cell to place a note (monophonic - one
#  note per column). P/Enter plays the sequence on the PC speaker, C clears,
#  ESC exits. Reuses the mouse driver, cursor, and the PIT speaker code.
# ============================================================================

do_daw:
    mov     ax, 0x0013
    int     0x10
    call    get_font
    call    daw_clear
    call    daw_draw
    call    mouse_init
    mov     word ptr [mouse_x], 156
    mov     word ptr [mouse_y], 100
    mov     byte ptr [mouse_btn], 0
    mov     byte ptr [prev_btn], 0
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
.daw_loop:
    mov     ah, 0x01
    int     0x16
    jz      .daw_btn
    xor     ah, ah
    int     0x16
    cmp     al, 0x1B
    je      .daw_exit
    cmp     al, 'p'
    je      .daw_play
    cmp     al, 'P'
    je      .daw_play
    cmp     al, 0x0D
    je      .daw_play
    cmp     al, 'c'
    je      .daw_clr
    cmp     al, 'C'
    je      .daw_clr
.daw_btn:
    mov     al, [mouse_btn]
    and     al, 1
    mov     [cur_btn], al
    cmp     al, [prev_btn]
    je      .daw_cur
    mov     [prev_btn], al
    test    byte ptr [cur_btn], 1
    jz      .daw_cur
    call    daw_click
.daw_cur:
    mov     ax, [mouse_x]
    cmp     ax, [cur_drawn_x]
    jne     .daw_redraw
    mov     ax, [mouse_y]
    cmp     ax, [cur_drawn_y]
    jne     .daw_redraw
    jmp     .daw_loop
.daw_redraw:
    call    cursor_restore
    mov     ax, [mouse_x]
    mov     [cur_drawn_x], ax
    mov     ax, [mouse_y]
    mov     [cur_drawn_y], ax
    call    cursor_save
    call    cursor_draw
    jmp     .daw_loop
.daw_play:
    call    daw_play_seq
    call    daw_draw
    call    cursor_save
    call    cursor_draw
    jmp     .daw_loop
.daw_clr:
    call    daw_clear
    call    daw_draw
    call    cursor_save
    call    cursor_draw
    jmp     .daw_loop
.daw_exit:
    call    mouse_off
    mov     ax, 0x0003
    int     0x10
    mov     ax, cs
    mov     es, ax
    jmp     shell_loop

# daw_clear: empty every step.
daw_clear:
    xor     bx, bx
.dcl_l:
    cmp     bx, 16
    jae     .dcl_d
    mov     byte ptr [daw_grid + bx], 0xFF
    inc     bx
    jmp     .dcl_l
.dcl_d:
    ret

# daw_draw: paint the grid (16 cols x 8 rows) and help text.
daw_draw:
    mov     word ptr [gx], 0
    mov     word ptr [gy], 0
    mov     word ptr [gw], 320
    mov     word ptr [gh], 200
    mov     byte ptr [gcolor], 0
    call    grect
    mov     byte ptr [gtcolor], 14
    mov     word ptr [gpx], 32
    mov     word ptr [gpy], 4
    mov     si, offset daw_title
    call    gtext_t
    mov     word ptr [daw_col], 0
.dd_col:
    mov     ax, [daw_col]
    cmp     ax, 16
    jae     .dd_cdone
    mov     word ptr [daw_row], 0
.dd_row:
    mov     ax, [daw_row]
    cmp     ax, 8
    jae     .dd_rdone
    mov     ax, [daw_col]
    mov     bx, 16
    mul     bx
    add     ax, 32
    mov     [gx], ax
    mov     ax, [daw_row]
    mov     bx, 18
    mul     bx
    add     ax, 20
    mov     [gy], ax
    mov     word ptr [gw], 15
    mov     word ptr [gh], 17
    mov     bx, [daw_col]
    mov     al, [daw_grid + bx]
    mov     bl, [daw_row]
    cmp     al, bl
    jne     .dd_off
    mov     byte ptr [gcolor], 10
    jmp     .dd_fill
.dd_off:
    mov     byte ptr [gcolor], 8
.dd_fill:
    call    grect
    inc     word ptr [daw_row]
    jmp     .dd_row
.dd_rdone:
    inc     word ptr [daw_col]
    jmp     .dd_col
.dd_cdone:
    mov     byte ptr [gtcolor], 15
    mov     word ptr [gpx], 16
    mov     word ptr [gpy], 178
    mov     si, offset daw_help
    call    gtext_t
    ret

# daw_click: toggle the note under the cursor.
daw_click:
    mov     ax, [mouse_x]
    cmp     ax, 32
    jb      .dck_ret
    sub     ax, 32
    cmp     ax, 256
    jae     .dck_ret
    mov     bl, 16
    div     bl
    mov     dl, al                  # column
    mov     ax, [mouse_y]
    cmp     ax, 20
    jb      .dck_ret
    sub     ax, 20
    cmp     ax, 144
    jae     .dck_ret
    mov     bl, 18
    div     bl
    mov     dh, al                  # row
    mov     bl, dl
    xor     bh, bh
    mov     al, [daw_grid + bx]
    cmp     al, dh
    jne     .dck_set
    mov     byte ptr [daw_grid + bx], 0xFF
    jmp     .dck_redraw
.dck_set:
    mov     [daw_grid + bx], dh
.dck_redraw:
    call    daw_draw
    call    cursor_save
    call    cursor_draw
.dck_ret:
    ret

# daw_play_seq: play each step's note on the PC speaker, with a step marker.
daw_play_seq:
    mov     word ptr [daw_col], 0
.dps_l:
    mov     ax, [daw_col]
    cmp     ax, 16
    jae     .dps_done
    mov     ah, 0x01
    int     0x16
    jnz     .dps_abort
    # clear marker row, then draw the current-step marker
    mov     word ptr [gx], 32
    mov     word ptr [gy], 14
    mov     word ptr [gw], 256
    mov     word ptr [gh], 4
    mov     byte ptr [gcolor], 0
    call    grect
    mov     ax, [daw_col]
    mov     bx, 16
    mul     bx
    add     ax, 32
    mov     [gx], ax
    mov     word ptr [gy], 14
    mov     word ptr [gw], 15
    mov     word ptr [gh], 4
    mov     byte ptr [gcolor], 14
    call    grect
    # play the note for this step (0xFF = rest)
    mov     bx, [daw_col]
    mov     al, [daw_grid + bx]
    cmp     al, 0xFF
    je      .dps_rest
    mov     bl, al
    xor     bh, bh
    shl     bx, 1
    mov     cx, [daw_freq + bx]
    call    sound_on
    jmp     .dps_dur
.dps_rest:
    call    sound_off
.dps_dur:
    mov     word ptr [tmp_dur], 170
    call    delay_ms
    call    sound_off
    inc     word ptr [daw_col]
    jmp     .dps_l
.dps_abort:
    xor     ah, ah
    int     0x16
.dps_done:
    call    sound_off
    ret

# ---- routines ----

# cls: set 80x25 colour text mode (clears the screen as a side effect).
cls:
    push    ax
    mov     ax, 0x0003
    int     0x10
    pop     ax
    ret

# putc: print the character in AL via BIOS teletype.
putc:
    push    ax
    push    bx
    mov     ah, 0x0E
    mov     bx, 0x0007
    int     0x10
    pop     bx
    pop     ax
    ret

# puts: print the NUL-terminated string at DS:SI.
puts:
    push    ax
    push    bx
    mov     ah, 0x0E
    mov     bx, 0x0007
.p1:
    lodsb
    test    al, al
    jz      .p2
    int     0x10
    jmp     .p1
.p2:
    pop     bx
    pop     ax
    ret

# newline: emit CR LF.
newline:
    push    ax
    mov     al, 0x0D
    call    putc
    mov     al, 0x0A
    call    putc
    pop     ax
    ret

# print_bcd: print AL as two BCD digits. Preserves CX and DX.
print_bcd:
    push    ax
    shr     al, 4
    add     al, '0'
    call    putc
    pop     ax
    push    ax
    and     al, 0x0F
    add     al, '0'
    call    putc
    pop     ax
    ret

# read_line: read a line of input into cmdbuf, NUL-terminated, with echo
# and backspace handling. Blocks via int 0x16.
read_line:
    mov     di, offset cmdbuf
    xor     cx, cx
.rl1:
    xor     ah, ah
    int     0x16                # AL = ASCII, AH = scancode
    cmp     al, 0x0D            # Enter
    je      .rl_done
    cmp     al, 0x08            # Backspace
    je      .rl_bs
    cmp     al, 0x20            # ignore non-printables
    jb      .rl1
    cmp     cx, 126
    jae     .rl1                # buffer full
    mov     [di], al
    inc     di
    inc     cx
    call    putc                # echo
    jmp     .rl1
.rl_bs:
    test    cx, cx
    jz      .rl1
    dec     di
    dec     cx
    mov     al, 0x08
    call    putc
    mov     al, ' '
    call    putc
    mov     al, 0x08
    call    putc
    jmp     .rl1
.rl_done:
    mov     byte ptr [di], 0
    call    newline
    ret

# find_arg: BX -> buffer. Returns DX -> first non-space char after the first
# space, or the terminating NUL if there is no argument.
find_arg:
    mov     si, bx
.fa1:
    mov     al, [si]
    test    al, al
    jz      .fa_done
    cmp     al, ' '
    je      .fa_space
    inc     si
    jmp     .fa1
.fa_space:
    mov     al, [si]
    cmp     al, ' '
    jne     .fa_done
    inc     si
    jmp     .fa_space
.fa_done:
    mov     dx, si
    ret

# match: compare keyword at SI (uppercase, NUL-terminated) against the command
# token at DI (case-insensitive). The token must end at a space or NUL.
# Returns AL = 1 on match, 0 otherwise.
match:
.m1:
    mov     bl, [si]
    test    bl, bl
    jz      .m_kwend
    mov     al, [di]
    cmp     al, 'a'
    jb      .m_noup
    cmp     al, 'z'
    ja      .m_noup
    sub     al, 0x20            # to upper
.m_noup:
    cmp     al, bl
    jne     .m_no
    inc     si
    inc     di
    jmp     .m1
.m_kwend:
    mov     al, [di]
    test    al, al
    jz      .m_yes
    cmp     al, ' '
    je      .m_yes
.m_no:
    xor     al, al
    ret
.m_yes:
    mov     al, 1
    ret

# ---- data ----

banner:
    .ascii  "===========================================\r\n"
    .ascii  " ZudaDOS 10  -  bare-metal real-mode shell\r\n"
    .ascii  "===========================================\r\n"
    .asciz  "Type HELP for a list of commands.\r\n\r\n"

prompt:     .asciz "A:\\> "
boot_msg:   .asciz "Starting desktop...  (press ESC for the DOS prompt)\r\n"

msg_help:
    .ascii  "Commands:\r\n"
    .ascii  "  HELP    Show this help\r\n"
    .ascii  "  CLS     Clear the screen\r\n"
    .ascii  "  VER     Show the ZudaDOS version\r\n"
    .ascii  "  ECHO    Print text  (ECHO hello)\r\n"
    .ascii  "  DIR     List the (virtual) directory\r\n"
    .ascii  "  TIME    Show the current time\r\n"
    .ascii  "  DATE    Show the current date\r\n"
    .ascii  "  ABOUT   About ZudaDOS\r\n"
    .ascii  "  SNAKE   Play Snake (arrows/WASD, Q quits)\r\n"
    .ascii  "  PLAY    Play a tune on the PC speaker\r\n"
    .ascii  "  EDIT    Word processor (F2 save, F3 load, ESC exit)\r\n"
    .ascii  "  ELIZA   Talk to the DOCTOR chatbot (type BYE to leave)\r\n"
    .ascii  "  BASIC   QBASIC-flavored BASIC interpreter (RUN/LIST/NEW/BYE)\r\n"
    .ascii  "  GUI     Graphical desktop (VGA mode 13h)\r\n"
    .ascii  "  PAINT   Mouse paint program (C clear, ESC quit)\r\n"
    .ascii  "  DESKTOP Windows 95-style desktop with a Start menu\r\n"
    .ascii  "  CALC    Evaluate an expression (CALC 2+3*4)\r\n"
    .ascii  "  MEM     Show memory   SYSINFO  System summary\r\n"
    .ascii  "  BEEP    Speaker beep  UPTIME   Time since midnight\r\n"
    .ascii  "  DICE    Roll a die    GUESS    Number guessing game\r\n"
    .ascii  "  COWSAY  ASCII cow     FORTUNE  Random quote\r\n"
    .ascii  "  MATRIX  Digital rain (any key to stop)\r\n"
    .ascii  "  DAW     PC-speaker step sequencer (mouse)\r\n"
    .ascii  "  REBOOT  Restart the machine\r\n"
    .asciz  "  HALT    Stop the CPU\r\n"

msg_ver:    .asciz "ZudaDOS [Version 10]\r\n"

msg_dir:
    .ascii  " Volume in drive A is ZUDADOS\r\n"
    .ascii  " Directory of A:\\\r\n\r\n"
    .ascii  "COMMAND  COM        8,192   06-19-2026\r\n"
    .ascii  "README   TXT        1,024   06-19-2026\r\n"
    .ascii  "ZUDA     SYS        4,096   06-19-2026\r\n"
    .asciz  "        3 file(s)        13,312 bytes\r\n"

msg_about:
    .ascii  "ZudaDOS - a hand-rolled 16-bit operating system.\r\n"
    .ascii  "Boots from a 512-byte boot sector, runs on bare metal,\r\n"
    .asciz  "and talks to the hardware through BIOS interrupts.\r\n"

msg_time:   .asciz "Current time: "
msg_date:   .asciz "Current date: "
msg_reboot: .asciz "Rebooting...\r\n"
msg_halt:   .asciz "System halted. It is now safe to power off.\r\n"
msg_bad:    .asciz "Bad command or file name\r\n"

msg_play:   .asciz "Playing tune...\r\n"
msg_gameover: .asciz "GAME OVER!  Snake score: "

hud_text:   .asciz " ZudaDOS SNAKE   arrows/WASD to move, Q to quit          Score:"

# Note table for PLAY: (frequency Hz, duration ms) pairs; freq 0 ends the tune,
# freq 1 is a rest. This is "Twinkle, Twinkle, Little Star".
tune:
    .word   262,300, 262,300, 392,300, 392,300, 440,300, 440,300, 392,600
    .word   349,300, 349,300, 330,300, 330,300, 294,300, 294,300, 262,600
    .word   0,0

kw_help:    .asciz "HELP"
kw_cls:     .asciz "CLS"
kw_ver:     .asciz "VER"
kw_echo:    .asciz "ECHO"
kw_dir:     .asciz "DIR"
kw_about:   .asciz "ABOUT"
kw_time:    .asciz "TIME"
kw_date:    .asciz "DATE"
kw_reboot:  .asciz "REBOOT"
kw_halt:    .asciz "HALT"
kw_snake:   .asciz "SNAKE"
kw_play:    .asciz "PLAY"
kw_edit:    .asciz "EDIT"
kw_eliza:   .asciz "ELIZA"
kw_basic:   .asciz "BASIC"
kw_gui:     .asciz "GUI"
kw_paint:   .asciz "PAINT"
kw_desktop: .asciz "DESKTOP"
kw_calc:    .asciz "CALC"
kw_mem:     .asciz "MEM"
kw_beep:    .asciz "BEEP"
kw_uptime:  .asciz "UPTIME"
kw_dice:    .asciz "DICE"
kw_cowsay:  .asciz "COWSAY"
kw_fortune: .asciz "FORTUNE"
kw_sysinfo: .asciz "SYSINFO"
kw_matrix:  .asciz "MATRIX"
kw_guess:   .asciz "GUESS"
kw_daw:     .asciz "DAW"

daw_title:  .asciz "ZudaDOS DAW - Beep Studio"
daw_help:   .asciz "Click=note  P=play  C=clear  ESC=exit"
daw_freq:   .word 1047, 988, 880, 784, 698, 659, 587, 523

msg_calc:    .asciz "= "
msg_calcerr: .asciz "Bad expression\r\n"
msg_mem1:    .asciz "Conventional memory: "
msg_mem2:    .asciz "Extended memory: "
msg_kb:      .asciz " KB\r\n"
msg_uptime:  .asciz "Up "
msg_sec:     .asciz " seconds (since midnight)\r\n"
msg_uplong:  .asciz "over an hour\r\n"
msg_dice:    .asciz "You rolled a "
cow_top:     .asciz " _________________\r\n"
cow_body:
    .ascii  "        \\   ^__^\r\n"
    .ascii  "         \\  (oo)\\_______\r\n"
    .ascii  "            (__)\\       )\\/\\\r\n"
    .ascii  "                ||----w |\r\n"
    .asciz  "                ||     ||\r\n"
fortune_art:
    .ascii  "      _.-'''''-._\r\n"
    .ascii  "    .'  .     .  '.\r\n"
    .ascii  "   /   ( o ) ( o ) \\\r\n"
    .ascii  "   |       <       |\r\n"
    .ascii  "   |    '._____.'   |\r\n"
    .ascii  "    \\             /\r\n"
    .ascii  "     '._       _.'\r\n"
    .ascii  "    .-''-#####-''-.\r\n"
    .asciz  " The orb whispers...\r\n"
fortune_tbl: .word f_1, f_2, f_3, f_4, f_5, f_6
f_1:         .asciz "The best way to predict the future is to invent it."
f_2:         .asciz "It works on my machine."
f_3:         .asciz "There are 10 kinds of people: those who get binary."
f_4:         .asciz "Real programmers count from zero."
f_5:         .asciz "Ship it and let reality file the bug report."
f_6:         .asciz "640K ought to be enough for anybody."
msg_gintro:  .asciz "I'm thinking of a number 1-100. (Q to quit)\r\n"
msg_gprompt: .asciz "Guess: "
msg_ghigh:   .asciz "Too high!\r\n"
msg_glow:    .asciz "Too low!\r\n"
msg_gwin:    .asciz "You got it!\r\n"

ds_start:   .asciz "Start"
ds_icon1:   .asciz "My PC"
ds_icon2:   .asciz "Trash"
ds_wtitle:  .asciz "ZudaDOS 95"
ds_w1:      .asciz "Welcome to"
ds_w2:      .asciz "ZudaDOS 95!"
ds_w3:      .asciz "Click Start."
ds_m1:      .asciz "Paint"
ds_m2:      .asciz "Snake"
ds_m3:      .asciz "MS-DOS"
ds_m4:      .asciz "Shut Down"
ds_hint:    .asciz "ZudaDOS 10  -  click or drag an icon"
ic_colors:  .byte 10, 12, 15, 14, 11, 2, 13, 8, 9
ic_labels:  .word icl_0, icl_1, icl_2, icl_3, icl_4, icl_5, icl_6, icl_7, icl_8
icl_0:      .asciz "Snake"
icl_1:      .asciz "Paint"
icl_2:      .asciz "Edit"
icl_3:      .asciz "BASIC"
icl_4:      .asciz "Eliza"
icl_5:      .asciz "Matrix"
icl_6:      .asciz "Guess"
icl_7:      .asciz "MS-DOS"
icl_8:      .asciz "DAW"

gui_title:  .asciz "ZudaDOS"
gui_l1:     .asciz "Welcome to ZudaDOS 10"
gui_l2:     .asciz "A real OS in ~24 KB."
gui_l3:     .asciz "Graphics + PS/2 mouse"
gui_l4:     .asciz "Move the pointer!"
gui_l5:     .asciz "Click [X] or a key."
gui_x:      .asciz "x"
gui_task:   .asciz "ZudaDOS  *  GUI desktop"

# Arrow cursor: 8 wide x 12 tall, 0=transparent 1=black 2=white.
cur_sprite:
    .byte 1,0,0,0,0,0,0,0
    .byte 1,1,0,0,0,0,0,0
    .byte 1,2,1,0,0,0,0,0
    .byte 1,2,2,1,0,0,0,0
    .byte 1,2,2,2,1,0,0,0
    .byte 1,2,2,2,2,1,0,0
    .byte 1,2,2,2,2,2,1,0
    .byte 1,2,2,2,1,1,1,0
    .byte 1,2,1,2,2,1,0,0
    .byte 1,1,0,1,2,2,1,0
    .byte 1,0,0,0,1,2,1,0
    .byte 0,0,0,0,0,1,1,0

msg_edit_exit: .asciz "Left the editor.\r\n"
edit_status:   .asciz " ZudaDOS EDIT   F2 Save  F3 Load  ESC Exit  "
s_ln:          .asciz "  Ln "
s_col:         .asciz "  Col "
s_bytes:       .asciz "  Bytes "

# ---- ELIZA / DOCTOR data ----

eliza_intro:
    .ascii  "ZudaDOS DOCTOR  (ELIZA)\r\n"
    .ascii  "-----------------------\r\n"
    .ascii  "Talk to me about whatever is on your mind. Type BYE to leave.\r\n\r\n"
    .asciz  "DOCTOR: How do you do. Please tell me what is bothering you.\r\n"
eliza_you:  .asciz "\r\nYOU: "
eliza_doc:  .asciz "DOCTOR: "
eliza_bye:  .asciz "Goodbye. It was nice talking to you."

# Quit keywords.
ekw_bye:    .asciz "BYE"
ekw_quit:   .asciz "QUIT"

# Keyword entries: keyword_ptr, prefix_ptr, suffix_ptr, reflect_flag (0 = canned).
# Priority order: distinctive phrases first; terminated by a 0 keyword_ptr.
eliza_kw_table:
    .word   k_computer, r_computer, e_empty, 0
    .word   k_sorry,    r_sorry,    e_empty, 0
    .word   k_dream,    r_dream,    e_empty, 0
    .word   k_hello,    r_hello,    e_empty, 0
    .word   k_maybe,    r_maybe,    e_empty, 0
    .word   k_mother,   r_family,   e_empty, 0
    .word   k_father,   r_family,   e_empty, 0
    .word   k_friend,   r_friend,   e_empty, 0
    .word   k_iremem,   r_iremem,   e_q,     1
    .word   k_ineed,    r_ineed,    e_q,     1
    .word   k_iwant,    r_iwant,    e_q,     1
    .word   k_icant,    r_icant,    e_q,     1
    .word   k_ifeel,    r_ifeel,    e_dot,   1
    .word   k_iam,      r_iam,      e_q,     1
    .word   k_im,       r_iam,      e_q,     1
    .word   k_ithink,   r_ithink,   e_q,     1
    .word   k_because,  r_because,  e_empty, 0
    .word   k_yes,      r_yes,      e_empty, 0
    .word   k_no,       r_no,       e_empty, 0
    .word   k_you,      r_you,      e_empty, 0
    .word   0

k_computer: .asciz "COMPUTER"
k_sorry:    .asciz "SORRY"
k_dream:    .asciz "DREAM"
k_hello:    .asciz "HELLO"
k_maybe:    .asciz "MAYBE"
k_mother:   .asciz "MOTHER"
k_father:   .asciz "FATHER"
k_friend:   .asciz "FRIEND"
k_iremem:   .asciz "I REMEMBER"
k_ineed:    .asciz "I NEED"
k_iwant:    .asciz "I WANT"
k_icant:    .asciz "I CAN'T"
k_ifeel:    .asciz "I FEEL"
k_iam:      .asciz "I AM"
k_im:       .asciz "I'M"
k_ithink:   .asciz "I THINK"
k_because:  .asciz "BECAUSE"
k_yes:      .asciz "YES"
k_no:       .asciz "NO"
k_you:      .asciz "YOU"

r_computer: .asciz "Do computers worry you?"
r_sorry:    .asciz "Please don't apologize."
r_dream:    .asciz "What does that dream suggest to you?"
r_hello:    .asciz "Hello. How are you feeling today?"
r_maybe:    .asciz "You don't seem quite certain."
r_family:   .asciz "Tell me more about your family."
r_friend:   .asciz "Tell me more about your friends."
r_iremem:   .asciz "Do you often think of "
r_ineed:    .asciz "Why do you need "
r_iwant:    .asciz "What would it mean to you if you got "
r_icant:    .asciz "How do you know you can't "
r_ifeel:    .asciz "Tell me more about feeling "
r_iam:      .asciz "Why are you "
r_ithink:   .asciz "Do you doubt "
r_because:  .asciz "Is that the real reason?"
r_yes:      .asciz "You seem quite positive."
r_no:       .asciz "Are you saying no just to be negative?"
r_you:      .asciz "We were discussing you, not me."

e_empty:    .asciz ""
e_q:        .asciz "?"
e_dot:      .asciz "."

# Generic fallback responses, rotated by gen_idx.
eliza_generic:
    .word   g_go, g_more, g_feel, g_tell, g_elab, g_why
g_go:       .asciz "Please go on."
g_more:     .asciz "Tell me more."
g_feel:     .asciz "How does that make you feel?"
g_tell:     .asciz "I see. And what does that tell you?"
g_elab:     .asciz "Can you elaborate on that?"
g_why:      .asciz "Why do you say that?"

# Person-reflection table: from (uppercase) -> to (lowercase). Applied word by
# word to the remainder of the sentence. Terminated by a 0 from-pointer.
swap_table:
    .word   sf_im,    st_youare
    .word   sf_i,     st_you
    .word   sf_me,    st_you
    .word   sf_my,    st_your
    .word   sf_mine,  st_yours
    .word   sf_myself,st_yourself
    .word   sf_am,    st_are
    .word   sf_your,  st_my
    .word   sf_yours, st_mine
    .word   sf_you,   st_i
    .word   sf_are,   st_am
    .word   0

sf_im:     .asciz "I'M"
sf_i:      .asciz "I"
sf_me:     .asciz "ME"
sf_my:     .asciz "MY"
sf_mine:   .asciz "MINE"
sf_myself: .asciz "MYSELF"
sf_am:     .asciz "AM"
sf_your:   .asciz "YOUR"
sf_yours:  .asciz "YOURS"
sf_you:    .asciz "YOU"
sf_are:    .asciz "ARE"

st_youare:   .asciz "you are"
st_you:      .asciz "you"
st_your:     .asciz "your"
st_yours:    .asciz "yours"
st_yourself: .asciz "yourself"
st_are:      .asciz "are"
st_my:       .asciz "my"
st_mine:     .asciz "mine"
st_i:        .asciz "I"
st_am:       .asciz "am"

# ---- ZBASIC data ----

basic_intro:
    .ascii  "ZudaDOS BASIC  (QBASIC-flavored)\r\n"
    .ascii  "--------------------------------\r\n"
    .ascii  "Type program lines, then RUN. Commands: RUN  LIST  NEW  BYE\r\n"
    .asciz  "Integer math; string vars A$; IF/FOR/WHILE/GOTO/GOSUB. No ELSE.\r\n\r\n"
basic_errmsg: .asciz "?Syntax error\r\n"
basic_ok:     .asciz "Ok\r\n"

bcmd_run:   .asciz "RUN"
bcmd_list:  .asciz "LIST"
bcmd_new:   .asciz "NEW"
bcmd_bye:   .asciz "BYE"

kw_PRINT:   .asciz "PRINT"
kw_LET:     .asciz "LET"
kw_IF:      .asciz "IF"
kw_THEN:    .asciz "THEN"
kw_FOR:     .asciz "FOR"
kw_TO:      .asciz "TO"
kw_STEP:    .asciz "STEP"
kw_NEXT:    .asciz "NEXT"
kw_WHILE:   .asciz "WHILE"
kw_WEND:    .asciz "WEND"
kw_GOTO:    .asciz "GOTO"
kw_GOSUB:   .asciz "GOSUB"
kw_RETURN:  .asciz "RETURN"
kw_INPUT:   .asciz "INPUT"
kw_CLS:     .asciz "CLS"
kw_END:     .asciz "END"
kw_STOP:    .asciz "STOP"
kw_REM:     .asciz "REM"
kw_MOD:     .asciz "MOD"
kw_AND:     .asciz "AND"
kw_OR:      .asciz "OR"
kw_NOT:     .asciz "NOT"
kw_LEN:     .asciz "LEN"
kw_ASC:     .asciz "ASC"
kw_CHR:     .asciz "CHR"
kw_RND:     .asciz "RND"
kw_ABS:     .asciz "ABS"

# ---- mutable state (BSS-style, zero-initialised in the image) ----
boot_drive: .byte 0
num_attr:   .byte 0x1E
ins_char:   .byte 0
tmp_dur:    .word 0
rng_state:  .word 0
score:      .word 0
quit_flag:  .word 0
length:     .word 0
head_idx:   .word 0
tail_idx:   .word 0
head_x:     .word 0
head_y:     .word 0
dir_dx:     .word 0
dir_dy:     .word 0
n_x:        .word 0
n_y:        .word 0
food_x:     .word 0
food_y:     .word 0
body_off:   .space 1024         # circular buffer of up to 512 body cells

# EDIT state
doc_len:    .word 0
cur_pos:    .word 0
top_line:   .word 0
left_col:   .word 0
cur_line:   .word 0
cur_col:    .word 0
scan_ptr:   .word 0
render_row: .word 0
tmp_col:    .word 0
tmp_ls:     .word 0
tmp_pls:    .word 0
tmp_secs:   .word 0
lba:        .word 0
rw_op:      .byte 0
t_sec:      .word 0
t_cyl:      .word 0
t_head:     .word 0
linebuf:    .space 80
secbuf:     .space 512

# ELIZA state
gen_idx:    .word 0
kw_tabptr:  .word 0
rem_ptr:    .word 0
src_ptr:    .word 0
out_ptr:    .word 0
upbuf:      .space 130
outbuf:     .space 400          # holds reflected remainder; sized for worst-case word expansion

# ZBASIC state
pp:         .word 0
peek_end:   .word 0
err_flag:   .byte 0
halt:       .byte 0
if_truth:   .byte 0
prog_len:   .word 0
num_lines:  .word 0
runline:   .word 0
next_line:  .word 0
scan_line:  .word 0
scan_depth: .word 0
for_sp:     .word 0
gosub_sp:   .word 0
num_count:  .word 0
str_count:  .word 0
lbl_count:  .word 0
slen:       .word 0
sptr:       .word 0
as_slot:    .word 0
as_dst:     .word 0
for_slot_tmp:  .word 0
for_limit_tmp: .word 0
for_step_tmp:  .word 0
idbuf:      .space 12
kwbuf:      .space 12
kwbuf2:     .space 12
line_work:  .space 256
sbuf1:      .space 256
sbuf2:      .space 256
line_index: .space 512          # 256 line-start offsets
for_var:    .space 16
for_limit:  .space 16
for_step:   .space 16
for_body:   .space 16
gosub_ret:  .space 16
num_names:  .space 288          # 32 numeric vars x 9-byte names
num_vals:   .space 64
str_names:  .space 144          # 16 string vars x 9-byte names
str_store:  .space 1024         # 16 string slots x 64 bytes
lbl_names:  .space 288          # 32 labels x 9-byte names
lbl_line:   .space 64
prog_buf:   .space 4096

# GUI state
gx:         .word 0
gy:         .word 0
gw:         .word 0
gh:         .word 0
gcolor:     .byte 0
grow:       .byte 0
gcol:       .byte 0
gtcolor:    .byte 0

# font engine state (transparent 8x8 text)
font_seg:   .word 0
font_off:   .word 0
gpx:        .word 0
gpy:        .word 0
glyphbuf:   .space 8

# mouse / cursor state
mouse_x:    .word 0
mouse_y:    .word 0
mouse_btn:  .byte 0
mpkt_idx:   .byte 0
mpkt0:      .byte 0
mpkt1:      .byte 0
mpkt2:      .byte 0
cur_drawn_x: .word 0
cur_drawn_y: .word 0
cur_bg:     .space 96

# PAINT state
current_color: .byte 0
painting:   .byte 0
prev_btn:   .byte 0
cur_btn:    .byte 0

# DESKTOP / Win95 state
btx:        .word 0
bty:        .word 0
btw:        .word 0
bth:        .word 0
bev_tl:     .byte 0
bev_br:     .byte 0
menu_open:  .byte 0
icon_i:     .word 0
drag_icon:  .word -1
grab_dx:    .word 0
grab_dy:    .word 0
press_mx:   .word 0
press_my:   .word 0
icon_x:     .space 18
icon_y:     .space 18
clockbuf:   .space 8
guess_target: .word 0
daw_col:    .word 0
daw_row:    .word 0
daw_grid:   .space 16
in_desktop: .byte 0
desktop_inited: .byte 0
boot_ticks: .word 0

cmdbuf:     .space 128
