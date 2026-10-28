; Hand evaluation. Input: counts (KN bytes, tiles of each kind in the closed
; hand) and nfuro (number of furo).

; Returns A = 1 if counts is a winning shape, else A = 0.
; Returns with N and Z set from A.
is_agari:
	tst	nfuro
	bne	agari_sets
	jsr	sh_chiitoi
	inca
	beq	is_agari_01
	jsr	is_kokushi
	bne	is_agari_01
; Returns A = 1 if counts is a winning regular shape (four sets and a head).
agari_sets:
	ldx	#sets_ok
	jmp	each_head
is_agari_01:
	ldaa	#1
	rts

; X = routine. Calls it once for every kind with two or more tiles in counts,
; with two of them taken out and head_kind = that kind. Stops at the first
; routine that returns A != 0. Returns A = that value (0 if none). counts is
; restored.
; Returns with N and Z set from A.
each_head:
	stx	eh_routine
	ldaa	#K_FIRST
	staa	head_kind
each_head_00:
	ldab	head_kind
	jsr	counts_x
	ldaa	0,x
	cmpa	#2
	bcs	each_head_01
	suba	#2
	staa	0,x
	ldx	eh_routine
	jsr	0,x
	psha
	ldab	head_kind
	jsr	counts_x
	inc	0,x
	inc	0,x
	pula
	tsta
	bne	each_head_02
each_head_01:
	inc	head_kind
	ldaa	head_kind
	cmpa	#K_END
	bne	each_head_00
	clra
each_head_02:
	rts

; Returns A = 1 if all tiles in counts make triplets and sequences. The
; empty kinds between the suits and the honors stop sequences.
sets_ok:
	ldx	#counts
	ldab	#KN
sets_ok_00:
	ldaa	0,x
	staa	work-counts,x
	inx
	decb
	bne	sets_ok_00
	ldx	#work+K_FIRST
sets_ok_01:
	ldaa	0,x
	cmpa	#3
	bcs	sets_ok_02
	suba	#3
sets_ok_02:
	tsta
	beq	sets_ok_03
	cmpa	1,x
	bhi	sets_ok_06
	cmpa	2,x
	bhi	sets_ok_06
	nega
	tab
	addb	1,x
	stab	1,x
	adda	2,x
	staa	2,x
sets_ok_03:
	inx
	cpx	#work+K_HONOR
	bne	sets_ok_01
sets_ok_04:
	ldaa 0,x
	beq sets_ok_05
	cmpa #3
	bne sets_ok_06
sets_ok_05:
	inx
	cpx #work+K_END
	bne sets_ok_04
	ldaa	#1
	rts
sets_ok_06:
	clra
	rts

; Returns A = 1 if counts is thirteen orphans.
; Returns with N and Z set from A.
is_kokushi:
	jsr	count_yaochu
	ldaa	yao_kinds
	cmpa	#13
	bne	is_kokushi_00
	ldaa	yao_tiles
	cmpa	#14
	bne	is_kokushi_00
	ldaa	#1
	rts
is_kokushi_00:
	clra
	rts

; Returns A = shanten number with one more furo; nfuro is restored.
shanten_furo:
 inc nfuro
 bsr shanten
 dec nfuro
 rts

; Returns A = shanten number (-1 for a winning shape).
; Returns with N and Z set from A.
shanten:
	ldaa	#8
	staa	sh_best
	tst	nfuro
	bne	shanten_10
	jsr	sh_chiitoi
	staa	sh_best
	jsr	count_yaochu
	ldaa	#13
	suba	yao_kinds
	tst	yao_pairs
	beq	shanten_00
	deca
shanten_00:
	cmpa	sh_best
	bge	shanten_01
	staa	sh_best
shanten_01:
	ldaa	sh_best
	bmi	shanten_11
	bne	shanten_10
; A special shape is tenpai. Only a regular agari can improve its zero
; (a special agari would have given -1 above).
	jsr	agari_sets
	nega
	rts
shanten_10:
	jsr	sh_general
	cmpa	sh_best
	bge	shanten_11
	staa	sh_best
shanten_11:
	ldaa	sh_best
	rts

 ; ai_discard-only entry: counts stays at fourteen tiles; X points at wk_kind.
shanten_lim:
 jsr spec_before
 cmpa sk-counts,x
 ble shanten_lim_00
 ldaa sk-counts,x
shanten_lim_00:
 rts

; greedy reads it with a one-byte offset, so it must not cross a page.
gd_transitions:
 .byte 0,8,1,9,2,0,0,0,16,1,9,2,10,0,0,0,0,1,9,2,10

; X = counts of one suit. Returns A = taatsu; X unchanged.
; Tiles match their lowest free partner.
greedy:
 ; Preserve the input X in normal RAM; use X to scan the first eight ranks.
 stx greedy_saved_x
 ldaa #8
 staa greedy_left
 clr greedy_sum
 clrb
greedy_loop:
 ldaa 0,x
 aba
 adda #<gd_transitions
 staa gd_smc_read0+2
gd_smc_read0:
 ldaa gd_transitions
 tab
 andb #24
 anda #7
 adda greedy_sum
 staa greedy_sum
 inx
 dec greedy_left
 bne greedy_loop
 ; The final rank contributes its value but does not replace B.
 ldaa 0,x
 aba
 adda #<gd_transitions
 staa gd_smc_last+2
gd_smc_last:
 ldaa gd_transitions
 anda #7
 adda greedy_sum
 ldx greedy_saved_x
 tsta
 rts

	.bss
greedy_saved_x: .ds 2 ; input X restored on return
greedy_left: .ds 1 ; ranks left in greedy_loop
; nfuro is allocated in directpage.asm.
eh_routine:	.ds	2 ; routine called for each head
al_res: .ds 1 ; al_check result
; chiitoi_pairs is allocated in directpage.asm.
fi_fu: .ds 1
; chiitoi_kinds is allocated in directpage.asm.
; yao_kinds is allocated in directpage.asm.
yao_tiles:	.ds	1
call_pat: .ds 1 ; chi pattern ai_call checks
; yao_pairs is allocated in directpage.asm.
; sh_best is allocated in directpage.asm.
; greedy_sum is allocated in directpage.asm.
 .code
