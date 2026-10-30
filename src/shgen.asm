; Special shapes: chiitoi and kokushi. Regular-shape search is in direct.asm.

; A = yaochu kinds, B = 0 if no yaochu kind has a pair. Returns A = kokushi
; shanten 13 - yaochu kinds - (1 if B != 0).
; Returns with N and Z set from A.
kok_sh:
 tstb
 beq kok_sh_00
 inca
kok_sh_00:
 nega
 adda #13
 rts

; Sets spec_cnt (SP_*) of counts. Returns X = #spec_cnt.
spec_count:
 ldx #spec_cnt
 clr SP_KINDS,x
 clr SP_YAO,x
 clr SP_PAIRS,x
 clr SP_YPAIRS,x
 ldx #counts
spec_count_00:
 ldaa 0,x
 beq spec_count_01
 inc spec_cnt+SP_KINDS
 cmpa #2
 bcs spec_count_01
 inc spec_cnt+SP_PAIRS
spec_count_01:
 inx
 cpx #counts+K_END
 bne spec_count_00
 ldx #yao_offsets
spec_count_02:
 stx yao_ptr
 ldab 0,x
 jsr counts_x
 ldaa 0,x
 beq spec_count_03
 inc spec_cnt+SP_YAO
 cmpa #2
 bcs spec_count_03
 inc spec_cnt+SP_YPAIRS
spec_count_03:
 ldx yao_ptr
 inx
 cpx #yao_offsets+13
 bne spec_count_02
 ldx #spec_cnt
 rts

; A = pairs, B = kinds. Returns A = chiitoi shanten 6 - pairs + max(0, 7 - kinds).
; Returns with N and Z set from A.
chii_sh:
 nega
 adda #6
 cmpb #7
 bcc chii_sh_00
 negb
 addb #7
 aba
chii_sh_00:
 tsta
 rts

yao_offsets:
 .byte K_FIRST,K_FIRST+8,K_FIRST+10,K_FIRST+18,K_FIRST+20,K_FIRST+28
 .byte K_EAST,K_EAST+1,K_EAST+2,K_NORTH,K_HAKU,K_HATSU,K_CHUN
 .bss
yao_ptr: .ds 2 ; next kind in yao_offsets
 .code

