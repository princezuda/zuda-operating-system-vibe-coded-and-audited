# build.ps1 - build zudados.img on Windows from PowerShell.
#
# Requires GNU binutils on PATH: as, ld, objcopy.
#   Easiest source: MSYS2 (https://www.msys2.org) -> `pacman -S binutils`,
#   then add C:\msys64\usr\bin to PATH (or run this from an MSYS2 shell).
#
# This replaces the Makefile's `make`/`dd` steps; it assembles the 1.44MB
# floppy image with native PowerShell byte operations.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Tool($name, [string[]]$arglist) {
    & $name @arglist
    if ($LASTEXITCODE -ne 0) { throw "$name failed (exit $LASTEXITCODE)" }
}

# --- assemble + link each stage to a flat binary ---
Tool as      @("--32","-o","boot.o","boot.s")
Tool ld      @("-m","elf_i386","-Ttext","0x7C00","-e","_start","-o","boot.elf","boot.o")
Tool objcopy @("-O","binary","boot.elf","boot.bin")

Tool as      @("--32","-o","kernel.o","kernel.s")
Tool ld      @("-m","elf_i386","-Ttext","0x0000","-e","_start","-o","kernel.elf","kernel.o")
Tool objcopy @("-O","binary","kernel.elf","kernel.bin")

# --- assemble the disk image: 1.44MB of zeros, boot at LBA 0, kernel at LBA 1 ---
$boot   = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "boot.bin"))
$kernel = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "kernel.bin"))
if ($boot.Length -ne 512) { throw "boot.bin must be exactly 512 bytes (got $($boot.Length))" }

$img = New-Object byte[] (2880 * 512)            # 1,474,560 bytes, zero-filled
[Array]::Copy($boot,   0, $img, 0,   $boot.Length)
[Array]::Copy($kernel, 0, $img, 512, $kernel.Length)
[System.IO.File]::WriteAllBytes((Join-Path $PSScriptRoot "zudados.img"), $img)

Write-Host ("Built zudados.img ({0} bytes); kernel.bin = {1} bytes" -f $img.Length, $kernel.Length)
