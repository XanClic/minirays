;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright (c) 2014 Hanna Reitz                                               ;
;                                                                              ;
; Permission is hereby granted, free of charge, to any person obtaining a copy ;
; of this software and  associated documentation files  (the  "Software"),  to ;
; deal in the  Software without restriction,  including without limitation the ;
; rights to use, copy, modify, merge,  publish, distribute, sublicense, and/or ;
; sell copies of the Software,  and to permit  persons to whom the Software is ;
; furnished to do so, subject to the following conditions:                     ;
;                                                                              ;
; The above copyright notice and this  permission notice  shall be included in ;
; all copies or substantial portions of the Software.                          ;
;                                                                              ;
; THE SOFTWARE IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY KIND,  EXPRESS OR ;
; IMPLIED,  INCLUDING BUT NOT  LIMITED TO THE  WARRANTIES OF  MERCHANTABILITY, ;
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE ;
; AUTHORS  OR COPYRIGHT  HOLDERS BE  LIABLE FOR  ANY CLAIM,  DAMAGES OR  OTHER ;
; LIABILITY,  WHETHER IN AN  ACTION OF CONTRACT,  TORT OR  OTHERWISE,  ARISING ;
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS ;
; IN THE SOFTWARE.                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

xor     ax,ax
mov     ds,ax


jmp     _start

; 0x20 here
something_big:
objz:
dd 150.0
dd 10.0

n1:
dd 1.0

epsilon:
dd 0.01

neg_light_rev:
dd -0.5, -0.8, -0.1

;  o o   o
; o ooo oo
; o oo o o
; o o
;  o  o o
;   o ooo
objs: db 11011010b,10101101b,10001101b,01010101b,01010010b,01110100b
objs_end:

_start:


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


xorps   xmm1,xmm1

full_loop:
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
movaps  [0x7e00],xmm1
xor     bp,bp
call    trace
movaps  xmm1,[0x7e00]
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

addss   xmm1,[epsilon]
jmp full_loop


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
add     edx,12
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
movaps  xmm2,[neg_light_rev]
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

movaps  xmm1,[neg_light_rev]
dpps    xmm1,xmm4,0x7f

xorps   xmm2,xmm2
comiss  xmm1,xmm2
jb      direct
indirect:
xorps   xmm1,xmm1
direct:

subps   xmm0,xmm1
ret
ret_zero:
xorps   xmm0,xmm0
clc
ret

times 510-($-$$) db 0
dw 0xaa55
