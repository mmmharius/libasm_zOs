# libasm_zOs

A static library of string utility functions written in x86 assembly,
designed to be used by the zOS kernel instead of relying on any C standard
library (which does not exist in bare-metal context).

This repo is included as a **git submodule** inside zOS at:
`include/libasm_zOs/`

---

## Current state

The library compiles and links into the kernel binary, but none of its
functions are actively called by the kernel code yet.
It is here as a foundation — the structure is in place, and the functions
work correctly in isolation. The integration into the kernel is the next step.

### What is in there right now

```
ft_strlen.s   → returns the length of a null-terminated string
ft_strcpy.s   → copies a string from src to dst, returns dst
ft_strcmp.s   → compares two strings, returns 0 if equal, diff otherwise
libasm.h      → declarations for the three functions above
Makefile      → builds libasm_zOs.a (static archive)
```

### Known issue — architecture mismatch

The assembly files currently compile to **elf64** (64-bit):

```makefile
NASM_FORMAT = elf64
```

But the zOS kernel is **32-bit** (compiled with `-m32`, boot.asm is `BITS 32`).

The code uses 64-bit registers (`rax`, `rdi`, `rsi`, `rbx`):

```asm
; ft_strlen.s — currently uses 64-bit registers
ft_strlen:
    xor rax, rax        ; rax is 64-bit
boucle:
    cmp byte [rdi + rax], 0
    je fini
    inc rax
    jmp boucle
fini:
    ret
```

For a proper 32-bit kernel, these would need to use 32-bit registers
(`eax`, `edi`, `esi`) and compile as `elf32`. More on this below.

### Known issue — header uses Linux system headers

`libasm.h` currently includes:

```c
#include <stddef.h>
#include <sys/types.h>
```

These headers come from the host Linux system.
In the kernel build, the `gcc` flags include `-nostdlib -nodefaultlibs`,
which means the standard system headers should not be relied upon.
The kernel has its own `include/stdint.h` for basic types.

For now this works because `libasm.h` is never included in kernel source files
directly — only the compiled `.a` archive is linked. But it will need fixing
before the functions can be called from kernel code.

---

## How it fits into zOS

The main zOS `Makefile` treats `libasm_zOs` as a sub-project:

```makefile
LIBASM_DIR = include/libasm_zOs
LIBASM     = $(LIBASM_DIR)/libasm_zOs.a

# build it
$(LIBASM): FORCE
    $(MAKE) -C $(LIBASM_DIR)

# link it in
kernel.bin: $(OBJ_DIR)/boot.o $(OBJS) $(PRINTK_LIB) $(LIBASM)
    $(LD) $(LDFLAGS) -o $@ ... $(LIBASM)
```

So every time you run `make` in zOS, it also builds `libasm_zOs.a` and
passes it to the linker. The `.a` archive is a static library — the linker
only pulls in the object files that are actually referenced. Since no kernel
code calls these functions yet, they are compiled but not included in the
final binary.

---

## How to use it from kernel code (future)

Once the architecture mismatch is fixed and the header is cleaned up,
using a function would look like this:

```c
// in a kernel .c file
#include <libasm_zOs/libasm.h>

// get the length of a string in kernel code
int len = ft_strlen("hello");

// copy a string from one buffer to another
char dst[64];
ft_strcpy(dst, "hello world");

// compare two strings (e.g. to check a command)
if (ft_strcmp(input, "help") == 0)
    show_help();
```

---

## Future: what this library will grow into

Right now the kernel barely needs string functions — it only prints fixed
strings and characters. But as the kernel grows, more string operations
will be needed. Here is what is planned:

### Fix the architecture

Switch from elf64 to elf32 and from 64-bit registers to 32-bit:

```asm
; ft_strlen — future 32-bit version
; calling convention: argument in [esp+4] (cdecl, 32-bit)
;   or adapted to use edi if the caller sets it up

BITS 32

ft_strlen:
    xor eax, eax           ; counter = 0
boucle:
    cmp byte [edi + eax], 0
    je fini
    inc eax
    jmp boucle
fini:
    ret
```

### Fix the header

Replace the Linux system includes with kernel-native types:

```c
// future libasm.h for bare-metal use
#ifndef LIBASM_H
#define LIBASM_H

#include <stdint.h>   // kernel's own stdint.h

typedef uint32_t size_t;   // or include a kernel-level stddef

size_t  ft_strlen(const char *s);
char   *ft_strcpy(char *dst, const char *src);
int     ft_strcmp(const char *s1, const char *s2);

#endif
```

### Add more functions as the kernel needs them

```
ft_memset(ptr, byte, n)    → fill memory region with a value
                             needed for: clearing screen buffers, zeroing structs

ft_memcpy(dst, src, n)     → copy raw bytes from src to dst
                             needed for: screen buffer copy, data moves

ft_memcmp(a, b, n)         → compare two memory regions
                             needed for: checking binary data

ft_strncpy(dst, src, n)    → copy at most n bytes
                             needed for: safe string handling once we have user input

ft_itoa(n, buf)            → integer to string
                             needed for: number output without printk dependency
```

The idea is that as zOS grows (paging, filesystem, shell-like interface),
it needs a solid low-level foundation. A hand-written assembly library
is both fast and avoids any dependency on external code.

---

## Build

From inside the `libasm_zOs` directory:

```sh
make          # produces libasm_zOs.a
make clean    # remove object files
make fclean   # remove .a and object files
make re       # fclean + make
```

From the main zOS directory it is built automatically as part of `make`.

---

## Register usage reference (x86 calling convention)

Understanding which registers hold arguments is key for writing
these functions correctly in assembly.

```
32-bit cdecl (used by the kernel — compiled with gcc -m32):

  Arguments are pushed on the stack before the call.
  First argument  → [esp + 4]   after the return address is pushed
  Second argument → [esp + 8]
  Return value    → eax

  Caller-saved: eax, ecx, edx   (callee can trash these freely)
  Callee-saved: ebx, esi, edi, ebp, esp  (must preserve if used)

example: ft_strlen(const char *s)
  s is at [esp + 4]
  return value goes in eax

64-bit System V AMD64 (current, wrong for this kernel):

  First  argument → rdi
  Second argument → rsi
  Return value    → rax

  This is why the current code uses rdi — it was written for 64-bit.
```

This is the core reason the 32-bit fix matters — if the kernel calls
`ft_strlen(ptr)` and the function reads from `rdi` instead of `[esp+4]`,
it will read from the wrong place and crash.
