; Special-shape counters; regular-shape search is in direct.asm.
; Returns A = 6 - pairs + max(0, 7 - kinds).
sh_chiitoi:
 clr chiitoi_pairs
 clr chiitoi_kinds
 ldx #counts
sh_chiitoi_00:
 ldaa 0,x
 beq sh_chiitoi_01
 inc chiitoi_kinds
 cmpa #2
 bcs sh_chiitoi_01
 inc chiitoi_pairs
sh_chiitoi_01:
 inx
 cpx #counts+K_END
 bne sh_chiitoi_00
 ldaa #6
 suba chiitoi_pairs
 ldab #7
 subb chiitoi_kinds
 bls sh_chiitoi_02
 aba
sh_chiitoi_02:
 rts

; Sets yao_kinds (terminal and honor kinds present), yao_tiles (their tiles)
; and yao_pairs (how many of them have 2 or more).
count_yaochu:
 clr yao_kinds
 clr yao_tiles
 clr yao_pairs
 ldx #yao_offsets
count_yaochu_00:
 stx yao_ptr
 ldab 0,x
 jsr	counts_x
 ldaa 0,x
 beq count_yaochu_02
 inc yao_kinds
 cmpa #2
 bcs count_yaochu_01
 inc yao_pairs
count_yaochu_01:
 adda yao_tiles
 staa yao_tiles
count_yaochu_02:
 ldx yao_ptr
 inx
 cpx #yao_offsets+13
 bne count_yaochu_00
 rts
yao_offsets:
 .byte K_FIRST,K_FIRST+8,K_FIRST+10,K_FIRST+18,K_FIRST+20,K_FIRST+28
 .byte K_EAST,K_EAST+1,K_EAST+2,K_NORTH,K_HAKU,K_HATSU,K_CHUN
 .bss
yao_ptr: .ds 2 ; next kind in yao_offsets
 .code

