# include/libasm_zOs/ — kernel string/memory utility library

A static library of utility functions written in x86 assembly.
The goal is to give the kernel basic operations (string manipulation,
memory copy, etc.) without depending on any external C library.

This repo is a **git submodule** inside zOS, hosted at:
`git@github.com:mmmharius/libasm_zOs.git`

Builds into `libasm_zOs.a`, linked into every kernel binary.

---

## Current state

The library compiles and links into the kernel. None of its functions
are called by kernel code yet — it is the foundation, not the roof.

### What exists

```
ft_strlen.s    length of a null-terminated string
ft_strcpy.s    copy string from src to dst, returns dst
ft_strcmp.s    compare two strings, returns 0 if equal
libasm.h       declarations for the three functions
Makefile       builds libasm_zOs.a
```

### Known issue — architecture mismatch (elf64 vs elf32)

The assembly files compile as **64-bit ELF**:
```makefile
NASM_FORMAT = elf64
```

The zOS kernel is **32-bit**:
```makefile
# main Makefile
ASMFLAGS = -f elf32
CFLAGS   = ... -m32 ...
LDFLAGS  = -m elf_i386 ...
```

The functions use 64-bit registers (`rax`, `rdi`, `rsi`):

```asm
; ft_strlen.s — current version uses 64-bit registers
ft_strlen:
    xor rax, rax          ; rax = 64-bit register
boucle:
    cmp byte [rdi + rax], 0
    je fini
    inc rax
    jmp boucle
fini:
    ret
```

The linker does not complain because these functions are never referenced.
But if you tried to call one from 32-bit kernel code, it would read arguments
from the wrong place and crash (see calling convention section below).

### Known issue — header uses Linux system headers

```c
// current libasm.h
#include <stddef.h>
#include <sys/types.h>
```

These come from the host Linux system, not from the kernel.
The kernel build uses `-nostdlib -nodefaultlibs`, so these headers should
not be relied upon. They need to be replaced with the kernel's own types.

---

## How it fits into the main zOS build

The main `Makefile` treats `libasm_zOs` as a sub-project:

```makefile
LIBASM_DIR = include/libasm_zOs
LIBASM     = $(LIBASM_DIR)/libasm_zOs.a

$(LIBASM): FORCE
    $(MAKE) -C $(LIBASM_DIR)       # build libasm_zOs.a

kernel.bin: ... $(LIBASM)
    $(LD) ... $(LIBASM)            # link it in
```

Every `make` in zOS rebuilds this library. The linker only pulls in
object files that are actually referenced — since nothing calls these
functions yet, they are built but not included in the final binary.

---

## Where it will plug in (future)

Once the architecture is fixed, these are the concrete places in the
kernel that will use it:

### Clearing screen buffers — ft_memset (to be added)

```c
// current code in screen_init() (screen_core.c)
for (int j = 0; j < VGA_WIDTH * VGA_HEIGHT; j++)
    scr.screens[i].buffer[j] = ' ';

// future, with libasm
ft_memset(scr.screens[i].buffer, ' ', VGA_WIDTH * VGA_HEIGHT);
```

### Scrolling — ft_memcpy (to be added)

```c
// current code in scroll() (screen_utils.c)
for (int row = s->start_row; row < VGA_HEIGHT - 1; row++)
    for (int col = 0; col < width; col++)
        s->buffer[row * 80 + col] = s->buffer[(row+1) * 80 + col];

// future
ft_memcpy(s->buffer + start_row * 80,
          s->buffer + (start_row + 1) * 80,
          (VGA_HEIGHT - start_row - 1) * 80);
```

### Command comparison (once a command system exists) — ft_strcmp

```c
if (ft_strcmp(input_buffer, "help") == 0)
    show_help();
```

---

## Planned functions

```
Currently:
  ft_strlen(s)          length of string s
  ft_strcpy(dst, src)   copy string, return dst
  ft_strcmp(s1, s2)     compare strings, 0 if equal

Planned (priority order):
  ft_memset(ptr, c, n)    fill n bytes with value c
  ft_memcpy(dst, src, n)  copy n bytes
  ft_memcmp(a, b, n)      compare n bytes
  ft_strnlen(s, max)      length up to max bytes
  ft_strncpy(dst, src, n) copy up to n bytes
```

`ft_memset` and `ft_memcpy` are the most immediately useful —
they speed up buffer clearing and scrolling.

---

## What needs to be fixed before using it

**1. Switch to elf32 and 32-bit registers**

In `Makefile`:
```makefile
# change:
NASM_FORMAT = elf64
# to:
NASM_FORMAT = elf32
```

And rewrite functions using 32-bit registers.
Example for `ft_strlen` (see calling convention below):

```asm
; ft_strlen — 32-bit version
BITS 32

section .text
global ft_strlen

ft_strlen:
    push edi               ; save callee-saved register
    mov  edi, [esp + 8]    ; first argument: const char *s  (after push + ret addr)
    xor  eax, eax          ; counter = 0
boucle:
    cmp  byte [edi + eax], 0
    je   fini
    inc  eax
    jmp  boucle
fini:
    pop  edi
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
```

**2. Fix the header**

```c
// replace:
#include <stddef.h>
#include <sys/types.h>

// with:
#include <stdint.h>    // kernel's own stdint.h
typedef uint32_t size_t;
```

---

## x86 calling convention reference

Understanding this is key for writing correct assembly functions.

```
32-bit cdecl (what the kernel uses — gcc -m32):

  All arguments are pushed on the stack, right to left.
  After the call instruction, the stack looks like:

  [esp + 0] = return address
  [esp + 4] = first  argument
  [esp + 8] = second argument
  ...

  Return value → eax
  Caller-saved: eax, ecx, edx   (callee can trash these)
  Callee-saved: ebx, esi, edi, ebp  (must save/restore if used)

64-bit System V (current code, wrong for this kernel):

  Arguments → rdi, rsi, rdx, rcx, r8, r9  (registers, not stack)
  Return    → rax

  This is why the current ft_strlen reads from rdi — it was written
  for 64-bit. In a 32-bit call, rdi contains garbage.
```

---

## Build

```sh
# from inside include/libasm_zOs/
make          # builds libasm_zOs.a
make clean    # remove object files
make fclean   # remove .a and objects
make re       # fclean + make
```

The main zOS `make` builds this automatically before linking.
