BITS 32

section .text
global ft_strcmp

; int ft_strcmp(const char *s1, const char *s2)
; 32-bit cdecl: s1 at [esp + 4], s2 at [esp + 8]
; return value in eax: 0 if equal, s1[i] - s2[i] otherwise
; esi is callee-saved

ft_strcmp:
    push esi
    mov  edx, [esp + 8]   ; s1  (offset: 1 push = 4 + ret = 4 → +8)
    mov  esi, [esp + 12]  ; s2  (offset: +12)

boucle:
    mov  al, [edx]         ; al = *s1  (al is low byte of eax = return reg)
    mov  cl, [esi]         ; cl = *s2  (cl is low byte of ecx, caller-saved)
    cmp  al, cl
    jne  differents
    cmp  al, 0
    je   egaux
    inc  edx
    inc  esi
    jmp  boucle

differents:
    movzx eax, al          ; eax = (unsigned) *s1
    movzx ecx, cl          ; ecx = (unsigned) *s2
    sub   eax, ecx         ; return s1[i] - s2[i]
    jmp   fin

egaux:
    xor  eax, eax          ; return 0

fin:
    pop  esi
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
