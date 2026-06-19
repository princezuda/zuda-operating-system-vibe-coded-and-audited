# ZudaDOS

A hand-rolled, bare-metal **16-bit operating system** in the spirit of early DOS.
No kernel framework, no libc, no emulator dependency — just a 512-byte boot
sector and a real-mode kernel that talks to the hardware through BIOS
interrupts, exactly the way MS-DOS did.

```
===========================================
 ZudaDOS 1.0  -  bare-metal real-mode shell
===========================================
Type HELP for a list of commands.

A:\>
```

## What it is

- **`boot.s`** — the boot sector (stage 1). The BIOS loads it at `0x7C00`. It
  resets the disk, reads the kernel off the disk with `int 0x13`, and far-jumps
  to it. Ends with the `0xAA55` boot signature.
- **`kernel.s`** — the kernel (stage 2), loaded at `0x1000:0x0000`. A small
  command shell with line editing (backspace), built on:
  - `int 0x10` — video / teletype output
  - `int 0x16` — keyboard input
  - `int 0x1A` — real-time clock (TIME / DATE)

It runs in **real mode** — the same 16-bit environment the original IBM PC
booted into.

## Commands

| Command  | Description                          |
|----------|--------------------------------------|
| `HELP`   | List commands                        |
| `CLS`    | Clear the screen                     |
| `VER`    | Show the version                     |
| `ECHO x` | Print text                           |
| `DIR`    | List a (virtual) directory           |
| `TIME`   | Current time from the RTC            |
| `DATE`   | Current date from the RTC            |
| `ABOUT`  | About ZudaDOS                        |
| `SNAKE`  | Play Snake (arrows/WASD, `Q` quits)  |
| `PLAY`   | Play a tune on the PC speaker        |
| `EDIT`   | Word processor (`F2` save, `F3` load, `ESC` exit) |
| `ELIZA`  | Talk to the DOCTOR chatbot (type `BYE` to leave) |
| `BASIC`  | QBASIC-flavored BASIC interpreter (`RUN`/`LIST`/`NEW`/`BYE`) |
| `REBOOT` | Restart the machine                  |
| `HALT`   | Stop the CPU                         |

Commands are case-insensitive. Unknown input gives the classic
`Bad command or file name`.

### SNAKE

A full game written straight to **VGA text memory** at segment `0xB800` — no
BIOS teletype, the kernel pokes characters and colour attributes into video RAM
directly. Keyboard is read non-blocking via `int 0x16` (AH=01 peek, AH=00 read),
so the snake keeps moving while you're not pressing anything. Eat the red
diamonds to grow and score; you lose if you hit a wall or yourself. Each apple
plays a beep on the PC speaker. Steer with the **arrow keys** or **WASD**, and
press **Q** / **Esc** to quit back to the shell.

### EDIT (word processor)

A full-screen text editor. The trick that makes it fit: the **editor code** is
tiny, and the **document** lives in a separate RAM segment (`0x20000`), so it's
independent of the kernel's small disk footprint. You get up to **32 KB** of
text (~5,000 words) with room to spare in conventional memory.

Keys:

| Key            | Action                                  |
|----------------|-----------------------------------------|
| Typing         | Insert text at the cursor               |
| Arrows         | Move the cursor                         |
| Home / End     | Start / end of line                     |
| PgUp / PgDn    | Up / down a page                        |
| Backspace / Del| Delete before / at the cursor           |
| Enter          | New line                                |
| `F2`           | **Save** the document to disk           |
| `F3`           | **Load** the document from disk         |
| `ESC`          | Exit back to the shell                  |

The editor keeps a live status bar (line, column, byte count) and scrolls both
vertically and horizontally to keep the cursor in view. Editing happens entirely
in RAM; the text buffer is a linear array that's shifted on insert/delete.

**Persistence.** `F2` writes the document to reserved disk sectors (LBA 20+) via
the BIOS disk service (`int 0x13`), past where the kernel lives, with a small
header sector holding a `ZD` magic and the length. `F3` reads it back. Your
writing survives a reboot or power-off.

> ⚠️ Save/load assumes standard **1.44 MB floppy geometry** (18 sectors/track,
> 2 heads) for its LBA→CHS conversion. That's correct when booted as a floppy or
> via USB **floppy** emulation (USB-FDD). If your BIOS boots the USB stick as a
> *hard disk* (USB-HDD) the geometry differs, so persistence may land on the
> wrong sectors — the in-RAM editing still works fine either way. QEMU `-fda`
> and real floppies are the surest targets for save/load. (A future version
> could use int 0x13 LBA extensions to be geometry-independent.)

### BASIC (a structured, QBASIC-flavored interpreter)

A real BASIC interpreter — write a program, `RUN` it. **No line numbers**: it's
structured like QBASIC, running top-to-bottom with `FOR`/`NEXT`, `WHILE`/`WEND`,
`IF`/`THEN`, and `GOTO`/`GOSUB` to named labels. A recursive-descent expression
evaluator handles `+ - * / MOD`, parentheses, comparisons, and `AND`/`OR`/`NOT`.

```
ZudaDOS BASIC  (QBASIC-flavored)
Type program lines, then RUN. Commands: RUN  LIST  NEW  BYE

INPUT "What is your name"; N$
PRINT "Hello, "; N$
FOR I = 1 TO 5
PRINT I; " squared is "; I * I
NEXT I
C = 0
WHILE C < 3
PRINT "tick"
C = C + 1
WEND
RUN
```

**Statements:** `PRINT` (`;` and `,` separators, trailing `;` suppresses the
newline), `LET`/implicit assignment, `INPUT`, `IF cond THEN <statement>`,
`FOR/NEXT` (with `STEP`), `WHILE/WEND`, `GOTO`, `GOSUB`/`RETURN`, labels
(`name:`), `CLS`, `REM` / `'`, `END`/`STOP`.

**Variables:** integer numerics with multi-char names (`COUNT`, `X1`), and
string variables (`A$`). **Functions:** `LEN(s$)`, `ASC(s$)`, `CHR$(n)`, plus
`+` to concatenate strings.

**Editor commands:** `RUN`, `LIST`, `NEW`, `BYE`. You type program lines at the
prompt; they accumulate until you `RUN`.

#### Honest limits (by design)

This is the *core* of Microsoft BASIC, not the full QBASIC IDE:

- **Integer only.** 16-bit signed math, no floating point. (`PRINT 7/2` is `3`.)
- **`IF ... THEN <statement>` is single-line, with no `ELSE`.** Chain with a
  second `IF` or a `GOTO` — the classic MS-BASIC idiom. (`ELSE` substring-
  splitting is the most bug-prone piece and was cut for reliability.)
- **No** `SUB`/`FUNCTION`, `DIM` arrays, `DATA`/`READ`, `SELECT CASE`, or the
  blue full-screen IDE.
- Limits: ~4 KB of program text, 256 lines, 32 numeric vars, 16 string vars
  (≤63 chars each), 8-deep `FOR` and `GOSUB` nesting, 32 labels.
- To make room, the boot sector now loads **three disk tracks** (~27 KB of
  kernel space).

It's enough to actually write programs — loops, conditionals, subroutines,
string handling — in the language a lot of us started on.

### ELIZA (the DOCTOR script)

Weizenbaum's 1966 Rogerian-psychotherapist chatbot, running on bare metal.
You'd think it couldn't fit — it fits fine, because ELIZA is mechanically
simple: it doesn't "understand" anything, it pattern-matches.

```
DOCTOR: How do you do. Please tell me what is bothering you.

YOU: I am unhappy about my job
DOCTOR: Why are you unhappy about your job?

YOU: because my boss is unfair
DOCTOR: Is that the real reason?

YOU: I need a break
DOCTOR: Why do you need a break?

YOU: bye
DOCTOR: Goodbye. It was nice talking to you.
```

How it works:

1. **Read** a line and make an uppercased copy for matching.
2. **Scan** a priority-ordered keyword table (`COMPUTER`, `SORRY`, `I AM`,
   `I NEED`, `I FEEL`, `MOTHER`, `BECAUSE`, `YOU`, ...). First match wins.
3. **Reply** either with a canned line (e.g. `BECAUSE` → "Is that the real
   reason?") or by **reflecting** the rest of the sentence into a template —
   swapping first/second person word by word (`I am` → `you are`, `my` →
   `your`, `me` → `you`) so "I am sad about my life" becomes
   "Why are you sad about your life?".
4. **No keyword** → a rotating generic nudge ("Please go on.", "How does that
   make you feel?", ...).

It's all string work — substring search, a word-swap table, and template
assembly — so the whole thing is a couple of KB of code and text. To make room,
the boot sector now loads a **second disk track**, giving the kernel ~17.5 KB
of space instead of one track's worth. Type `BYE` or `QUIT` to return to the
shell.

### PLAY (PC speaker music)

`PLAY` plays a melody on the PC speaker by programming **8253 PIT channel 2**
(ports `0x42`/`0x43`) and toggling the speaker gate on port `0x61` — the same
trick DOS games used for sound. Notes live in a small `(frequency, duration)`
table in `kernel.s` (`tune:`); edit it to play your own. The divisor is computed
with a 32-by-16-bit divide so it stays 8086-compatible.

## Build

Needs only the GNU binutils toolchain (`as`, `ld`, `objcopy`) and `dd` —
**no NASM, no emulator**.

```sh
make
```

This produces **`zudados.img`**, a 1.44 MB bootable floppy image:
- LBA 0 — the boot sector
- LBA 1+ — the kernel

`make clean` removes build artifacts.

## Run it on bare metal

> ⚠️ This is a **legacy BIOS / MBR** boot image. It boots on real machines with
> BIOS or with UEFI's CSM ("Legacy Boot") enabled. Pure UEFI-only machines need
> CSM turned on.

**Write to a USB stick** (this erases the stick — pick the right device!):

```sh
lsblk                       # find your USB, e.g. /dev/sdX
sudo dd if=zudados.img of=/dev/sdX bs=512 conv=fsync
```

Then reboot the target machine, enter the boot menu, enable Legacy/CSM boot,
and select the USB drive.

**Write to a real 3.5" floppy** (if you have a drive):

```sh
sudo dd if=zudados.img of=/dev/fd0 bs=512 conv=fsync
```

## Run it in a VM (optional)

Any emulator that boots a floppy image works:

```sh
qemu-system-i386 -fda zudados.img      # or: make run
# VirtualBox: attach zudados.img as a floppy controller image
# Bochs: floppya: 1_44=zudados.img, status=inserted
```

## How the handoff works

```
BIOS  ──loads sector 0──▶  boot.s @ 0x7C00
                              │  int 0x13: read 17 sectors -> 0x1000:0x0000
                              ▼
                          kernel.s @ 0x1000:0x0000  (ljmp 0x1000:0x0000)
                              │  set DS=ES=SS=CS, stack at 0xFFFE
                              ▼
                          shell loop (int 0x16 read, int 0x10 echo)
```

The boot sector deliberately loads only 17 kernel sectors so that boot (1) +
kernel (17) = 18 sectors = one floppy track, keeping the whole load on
cylinder 0 / head 0 and avoiding CHS wraparound.

## Memory map

| Address           | Contents                          |
|-------------------|-----------------------------------|
| `0x07C00`         | Boot sector (stage 1)             |
| `0x10000`         | Kernel (stage 2), DS=ES=CS=0x1000 |
| `0x1FFFE`         | Top of kernel stack (SP=0xFFFE)   |

## Requirements

Runs on any PC with a BIOS (or UEFI with CSM/Legacy boot). The PC-speaker music
and Snake timing use `int 0x15`/AH=86 for delays, available on 286-class BIOSes
and later — i.e. essentially every PC built since the late 1980s.

## Roadmap ideas

- A FAT12 driver so `DIR` / `TYPE` read the actual floppy
- Read a second program off disk and exec it (a real `COMMAND.COM` split)
- Protected-mode jump + a minimal 32-bit kernel
- More games, and audio-reactive visuals in text mode
