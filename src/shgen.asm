; Special shapes: chiitoi and kokushi. Regular-shape search is in direct.asm.

; A = yaochu kinds, B = 0 if no yaochu kind has a pair. Returns A = kokushi
; shanten 13 - yaochu kinds - (1 if B != 0).
; Returns with N and Z set from A.
	.code
kok_sh:
 tstb
 beq kok_sh_00
 inca
kok_sh_00:
 nega
 adda #13
 rts

; Sets spec_cnt (SP_*) of counts. Returns X = #spec_cnt. With SPEC_NONE all
; four are 0: chiitoi and kokushi are 13 shanten.
spec_count:
 ldx #spec_cnt
 clr SP_KINDS,x
 clr SP_YAO,x
 clr SP_PAIRS,x
 clr SP_YPAIRS,x
 tst spec_off
 bmi spec_count_04
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
 ; The 13 yaochu kinds, at fixed places of counts.
 ldx #counts
 ldaa K_FIRST,x
 bsr spec_count_yao
 ldaa K_FIRST+8,x
 bsr spec_count_yao
 ldaa K_FIRST+10,x
 bsr spec_count_yao
 ldaa K_FIRST+18,x
 bsr spec_count_yao
 ldaa K_FIRST+20,x
 bsr spec_count_yao
 ldaa K_FIRST+28,x
 bsr spec_count_yao
 ldab #7
spec_count_02:
 ldaa K_EAST,x
 bsr spec_count_yao
 inx
 decb
 bne spec_count_02
 ldx #spec_cnt
spec_count_04:
 rts
; A = tiles of a yaochu kind: counts it in SP_YAO and SP_YPAIRS. Keeps B and X.
spec_count_yao:
 beq spec_count_05
 inc spec_cnt+SP_YAO
 cmpa #2
 bcs spec_count_05
 inc spec_cnt+SP_YPAIRS
spec_count_05:
 rts

; Returns A = chiitoi shanten of counts.
counts_chii_sh:
 bsr spec_count
 ldaa SP_PAIRS,x
 ldab SP_KINDS,x
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
