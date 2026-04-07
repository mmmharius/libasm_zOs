# include/libasm_zOs/

Libasm adapted for Zos, repo git : https://github.com/mmmharius/zOS
---

## Calling convention (32-bit cdecl)

```
[esp + 0] = return address
[esp + 4] = arg 1
[esp + 8] = arg 2
...

Return value → eax
Caller-saved : eax, ecx, edx
Callee-saved : ebx, esi, edi, ebp
```

---

## Build

```sh
make
make clean
make fclean
make re
```
