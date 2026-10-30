; Hand evaluation. Input: counts (KN bytes, tiles of each kind in the closed
; hand) and nfuro (number of furo).

; Returns A = 1 if counts is a winning shape, else A = 0.
; Returns with N and Z set from A.
is_agari:
	tst	nfuro
	bne	agari_sets
	jsr	spec_count
	jsr	spec_shanten
	inca
	beq	is_agari_01
; Returns A = 1 if counts is a winning regular shape (four sets and a head).
agari_sets:
	jsr	sh_general
	inca
	beq	is_agari_01
	clra
	rts
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
	jsr	spec_count
	jsr	spec_shanten
	staa	sh_best
	bmi	shanten_11
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
 ; A discard does not lower a special shape: spec_low is a lower bound.
 ldaa spec_low
 cmpa sk-counts,x
 bge shanten_lim_01
 jsr spec_before
 cmpa sk-counts,x
 ble shanten_lim_00
shanten_lim_01:
 ldaa sk-counts,x
shanten_lim_00:
 rts

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
fi_fu: .ds 1
call_pat: .ds 1 ; chi pattern ai_call checks
; sh_best is allocated in directpage.asm.
; greedy_sum is allocated in directpage.asm.
 .code
