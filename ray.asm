use16
org 0x7c00


mov     eax,cr0
and     ax,0xfff3
or      ax,0x0022
mov     cr0,eax

mov     eax,cr4
or      ax,0x0600
mov     cr4,eax


mov     ax,0x13
int     0x10

cld


db 0xea
dw _start

dw 0

something_big:
objz:
dd 150.0
dd 10.0

n1:
dd 1.0

epsilon:
dd 0.01

light_rev:
dd 0.5, 0.8, 0.1

objs: db 01010001b,01001010b,01000100b,00001010b,01010001b
objs_end:

WIDTH = 7


_start:
xor     ax,ax
mov     ds,ax
mov     ss,ax
mov     esp,0x7c00

push    word 0xa000
pop     es


; Creates a grayscale palette
mov     dx,0x3C8
out     dx,al
inc     dx
palette_loop:
mov     cl,12
same_color:
out     dx,al
loop    same_color
inc     al
jnz     palette_loop


xor     di,di
mov     edx,-99
loop_y:
mov     ebx,-159
loop_x:
pushad
cvtsi2ss xmm2,ebx
cvtsi2ss xmm3,edx
unpcklps xmm2,xmm3
shufps  xmm2,[something_big],0x04
pshufd  xmm3,[something_big],0x00
divps   xmm2,xmm3
xorps   xmm1,xmm1
xor     bp,bp
call    trace
mulss   xmm0,[something_big]
popad
cvtss2si eax,xmm0
stosb
inc     ebx
cmp     bx,160
jle     loop_x
inc     edx
cmp     dx,100
jle     loop_y


cli
hlt


; Call:
;  * xmm1: start
;  * xmm2: view direction
;  *   bp: pass
; Return:
;  * xmm0: result
trace:
cmp     bp,9
jg      ret_zero

; normalize xmm2
movaps  xmm3,xmm2
dpps    xmm3,xmm3,0x7f
sqrtps  xmm3,xmm3
divps   xmm2,xmm3

; init t on xmm3
movaps  xmm3,[something_big]
; hit is on xmm4
mov     si,objs

vert_loop:
lodsb
mov     cl,0xff
horz_loop:
inc     cl
shr     al,1
jc      sphere
jz      break_horz_loop
jmp     horz_loop
sphere:

; make position in xmm5
xor     edx,edx
mov     dl,cl
shl     dl,1
sub     edx,WIDTH-1
cvtsi2ss xmm5,edx
xor     edx,edx
mov     dx,si
sub     dx,objs
shl     dl,1
sub     edx,objs_end-objs+1
cvtsi2ss xmm6,edx
unpcklps xmm5,xmm6
shufps  xmm5,[objz],0x54

; dir in xmm6
movaps  xmm6,xmm1
subps   xmm6,xmm5

; b
movaps  xmm7,xmm6
dpps    xmm7,xmm2,0x7f
; c
dpps    xmm6,xmm6,0x7f
subss   xmm6,[n1]
pshufd  xmm6,xmm6,0x00

; b * b
movaps  xmm0,xmm7
mulps   xmm0,xmm0

; b * b < c
comiss  xmm0,xmm6
jb      horz_loop

; s = sqrt(b * b - c)
subps   xmm0,xmm6
sqrtps  xmm0,xmm0

; s < 0?
xorps   xmm6,xmm6
comiss  xmm0,xmm6
jb      cmp_hit
; s >= 0 => -s
subps   xmm6,xmm0
movaps  xmm0,xmm6

cmp_hit:
; ±s - b
subps   xmm0,xmm7
; < t?
comiss  xmm0,xmm3
jnb     horz_loop
; > epsilon?
comiss  xmm0,[epsilon]
jna     horz_loop
movaps  xmm3,xmm0
movaps  xmm4,xmm5

test    bp,bp
jns     horz_loop

stc
ret


break_horz_loop:
cmp     si,objs_end
jb      vert_loop


comiss  xmm3,[something_big]
jae     ret_zero


; intersection
mulps   xmm3,xmm2
addps   xmm3,xmm1

; normal
subps   xmm4,xmm3

; reflect vector
movaps  xmm5,xmm2
dpps    xmm5,xmm4,0x7f
addps   xmm5,xmm5
mulps   xmm5,xmm4
subps   xmm2,xmm5

push    si
sub     sp,48
movups  [esp],xmm2
movups  [esp+16],xmm3
movups  [esp+32],xmm4
push    bp
mov     bp,-1
movaps  xmm1,xmm3
xorps   xmm2,xmm2
subps   xmm2,[light_rev]
call    trace
jnc     not_shadowed
mov     [esp+50],byte 0
not_shadowed:
pop     bp
inc     bp
movups  xmm1,[esp+16]
movups  xmm2,[esp]
call    trace
movups  xmm4,[esp+32]
add     sp,48
pop     ax

test    al,al
je      indirect

movaps  xmm1,[light_rev]
dpps    xmm1,xmm4,0x7f

xorps   xmm2,xmm2
comiss  xmm1,xmm2
jnb     direct
indirect:
xorps   xmm1,xmm1
direct:

addps   xmm0,xmm1
ret
ret_zero:
xorps   xmm0,xmm0
clc
ret

times 510-($-$$) db 0
dw 0xaa55
