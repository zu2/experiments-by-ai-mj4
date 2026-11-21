; Computer players 1..3; ai_player selects the current thinker.
; Candidates that best_accept evaluates (choose_cands).
CC_LIMIT .equ 4

; Computer's turn. Returns A = action, B = tile or kind, decl.
cpu_turn:
	clr	decl
	tst	can_win
	beq	cpu_turn_00
	ldaa	#ACT_TSUMO
	rts
cpu_turn_00:
	ldaa	ai_player
	jsr	player
	tst	P_FLAG,x
	bpl	cpu_turn_01
	ldab	P_DRAWN,x
	ldaa	#ACT_DISCARD
	rts
cpu_turn_01:
	jsr	ai_kan
	beq	cpu_turn_02
	ldaa	#ACT_KAN
	rts
cpu_turn_02:
	jsr	ai_discard
	stab	ai_tile
	jsr	ai_riichi
	staa	decl
	ldab	ai_tile
	ldaa	#ACT_DISCARD
	rts

; Returns A = 1 and B = kind for a kan that keeps the shanten number (not
; against riichi): an ankan of four tiles in the hand, or a kakan of the one
; tile of a kind the player has a pon of.
; Returns with N and Z set from A.
ai_kan:
 jsr any_riichi
 bne ai_kan_02
 tst draws_left
 beq ai_kan_02
 ldaa kans_done
 cmpa #4
 bcc ai_kan_02
 ldaa ai_player
 jsr eval_load
 clr kan_kind
ai_kan_00:
 ldab kan_kind
 jsr counts_x
 ldaa 0,x
 cmpa #4
 beq ai_kan_03
 cmpa #1
 bne ai_kan_01
 ldaa ai_player
 ldab kan_kind
 jsr furo_find_pon
 cpx #0
 beq ai_kan_01
 ; Kakan: the hand loses the tile, the furo stays a set.
 jsr shanten
 staa ak_before
 ldab kan_kind
 jsr counts_x
 dec 0,x
 jsr shanten
 psha
 ldab kan_kind
 jsr counts_x
 inc 0,x
 bra ai_kan_04
ai_kan_03:
 jsr shanten
 staa ak_before
 ldab kan_kind
 jsr counts_x
 clr 0,x
 jsr shanten_furo
 psha
 ldab kan_kind
 jsr counts_x
 ldaa #4
 staa 0,x
ai_kan_04:
 pula
 cmpa ak_before
 bne ai_kan_01
 ldab kan_kind
 ldaa #1
 rts
ai_kan_01:
 inc kan_kind
 ldaa kan_kind
 cmpa #K_END
 bne ai_kan_00
ai_kan_02:
 clra
 rts

; Best ordinary shanten after the call and a legal mandatory discard.
; Reuse the discard batch calculator with the call's kuikae restrictions.
; B = 1 for pon, or the chi pattern.
; Prepare the no-call acceptance once per response, before trial melds.
call_before_ukeire:
 ldaa call_shanten_now
 staa min_s
 jsr ai_unseen
 ldaa call_kind
 staa wk_kind
 jsr kind_counts_x
 inc 0,x
 jsr spec_prep14
 jsr ad_rel_build
 jsr kind_counts_x
 jsr relevant
 ldaa #$FF
 staa wk_kind
 ldaa #$7F
 staa ad_forbidden_s
 jsr acceptance
 staa call_pre_acc
 rts

call_shanten:
 ldaa call_kind
 jsr chi_forbidden
 jsr pair_remove
 inc nfuro
 jsr batch_prepare
 ldaa wk_limit
 cmpa call_shanten_now
 bne call_shanten_other
 jsr call_after_ukeire
 beq call_shanten_worse
 ; A call from tenpai to tenpai must raise the value (ev_best).
 tst call_shanten_now
 bne call_shanten_05
 jsr call_ev_more
 bls call_shanten_worse
call_shanten_05:
 ldaa call_shanten_now
 bra call_shanten_restore
 ; A call to a tenpai with 4 winning tiles or fewer counts as worse than a
 ; wide no-call hand (16 tiles of acceptance or more).
call_shanten_other:
 tsta
 bne call_shanten_restore
 ldab call_pre_acc
 cmpb #16
 bcs call_shanten_restore
 ldaa min_s
 psha
 pshb
 clr min_s
 ldaa #5
 staa call_pre_acc
 jsr call_after_ukeire
 pulb
 stab call_pre_acc
 pulb
 stab min_s
 tsta
 beq call_shanten_worse
 clra
 bra call_shanten_restore
call_shanten_worse:
 ldaa call_shanten_now
 inca
call_shanten_restore:
 ; A call after which ai_discard would fold, or would fold on danger, is
 ; worse; so is a call short of tenpai when the last discard folded.
 psha
 tsta
 beq call_shanten_01
 ldab ai_player
 jsr player_bit
 anda fold_bits
 bne call_shanten_02
call_shanten_01:
 tsx
 ldaa 0,x
 jsr fold_check
 cmpa #FC_DANGER
 bcs call_shanten_04
call_shanten_02:
 pula
 ldaa call_shanten_now
 inca
 bra call_shanten_00
call_shanten_04:
 pula
call_shanten_00:
 psha
 dec nfuro
 jsr pair_restore
 jsr clear_kk
 pula
 rts

; In the call_shanten state (counts without ck_a and ck_b, nfuro + 1, sk),
; adds the meld of call_kind, ck_a and ck_b to the furo of ai_player and runs
; ev_discard. Returns flags of ev_best compared with call_ev_now (bhi when
; larger). The furo are restored.
call_ev_more:
 ldaa ai_player
 jsr player
 stx cem_x
 ldab P_NFURO,x
 inc P_NFURO,x
 tba
 asla
 aba
 tab
 jsr addxb
 ldaa ck_a
 cmpa call_kind
 bcs call_ev_more_00
 ldaa call_kind
call_ev_more_00:
 staa P_FURO+1,x
 clra
 ldab ck_a
 cmpb ck_b
 bne call_ev_more_01
 ldaa #M_PON
call_ev_more_01:
 staa P_FURO,x
 ldaa #1
 bsr cem_tiles
 jsr ev_discard
 ldaa #-1
 bsr cem_tiles
 ldx cem_x
 dec P_NFURO,x
 ldaa ev_best
 cmpa call_ev_now
 bne call_ev_more_02
 ldaa ev_best+1
 cmpa call_ev_now+1
call_ev_more_02:
 rts
; Adds A to furo_tiles of call_kind, ck_a and ck_b.
cem_tiles:
 ldab call_kind
 bsr cem_tiles_00
 ldab ck_a
 bsr cem_tiles_00
 ldab ck_b
cem_tiles_00:
 jsr counts_x
 psha
 adda furo_tiles-counts,x
 staa furo_tiles-counts,x
 pula
 rts

; counts/nfuro/kk are the same temporary state as batch_prepare.  min_s is
; the no-call shanten, and call_pre_acc is the no-call acceptance.
; Returns with N and Z set from A.
call_after_ukeire:
 jsr ad_rel_build
 ldab kk1
 jsr counts_x
 ldaa sk-counts,x
 staa ad_forbidden_s
 ldab kk2
 cmpb #$FF
 beq call_after_ready
 jsr counts_x
 ldaa sk-counts,x
 cmpa ad_forbidden_s
 bge call_after_ready
 staa ad_forbidden_s
call_after_ready:
 clr wk_kind
call_accept_loop:
 jsr ad_allowed
 beq call_accept_next
 ldaa sk-counts,x
 cmpa min_s
 bne call_accept_next
 jsr candidate_acceptance
 ldaa wk_score
 cmpa call_pre_acc
 bcc call_acc_yes
call_accept_next:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne call_accept_loop
 clra
 rts
call_acc_yes:
 ldaa #1
 rts

 .bss
call_pre_acc: .ds 1
call_ev_now: .ds 2 ; ev_sum of not calling, in tenpai (call_ev_more)
cem_x: .ds 2 ; call_ev_more: the player
ft_n: .ds 1 ; furo_threat: result
ft_left: .ds 1 ; furo_threat: furo left
ft_x: .ds 2 ; furo_threat: furo being read
oc_mask: .ds 4 ; oc_build: suits of half danger, per player
oc_p: .ds 1 ; oc_build: player
oc_s: .ds 1 ; oc_build: suit S
oc_n: .ds 1 ; oc_build: furo left, then tiles of S in the river
oc_x: .ds 2 ; oc_build: the player
rp_n: .ds 1 ; ryan_pairs: pairs found
rp_s: .ds 1 ; ryan_pairs: suits left
fold_result: .ds 1 ; input of fold_check: shanten; output: the result
threat_furo: .ds 1 ; any_threat: furo count that is a threat (5 = never)
 .code

; Returns A = 1 if the computer declares riichi with the tile ai_tile.
; It declares whenever it may: closed, tenpai after the discard, 1000
; points, 4 live draws left.
ai_riichi:
 jsr ai_can_riichi
 beq ai_riichi_00
 ; ai_discard already evaluated this exact discarded kind.
 ldab ad_pick
 jsr	counts_x
 tst sk-counts,x
 bne ai_riichi_00
 dec 0,x
 jsr find_waits
 psha
 ldab ad_pick
 jsr	counts_x
 inc 0,x
 pula
 rts
ai_riichi_00:
 clra
 rts

; Chooses the tile to discard (kinds kk1 and kk2 are not allowed).
; Returns B = tile.
ai_discard:
 ; fold_bits: the bit of ai_player is set while its last discard folded.
 ldab ai_player
 jsr player_bit
 coma
 anda fold_bits
 staa fold_bits
	ldaa	ai_player
	jsr	eval_load
 jsr ai_unseen
 jsr chii_check
 ; The start time for ev1_discard: $0B seconds, $0C frames (0..59), kept by the IRQ.
ai_discard_00:
 ldab $0C
 ldaa $0B
 cmpb $0C
 bne ai_discard_00
 staa e1_sec
 stab e1_frame
 jsr discard_sk
 ldaa min_s
 jsr fold_check
	beq	ai_discard_05
 cmpa #FC_FOLD
	bcs	ai_discard_03
ai_discard_02:
 ldab ai_player
 jsr player_bit
 oraa fold_bits
 staa fold_bits
	ldaa	#$7F
	staa	wk_limit
	bra	ai_discard_04
ai_discard_03:
 ; An open tenpai without yaku (ev_best = 0) cannot win: it only defends.
 ldab min_s
 bne ai_discard_10
 jsr ev_discard
 jsr ai_open_furo
 beq ai_discard_10
 ldx ev_best
 beq ai_discard_02
ai_discard_10:
	ldaa	min_s
	staa	wk_limit
 jsr least_danger
 ldaa fold_result
 cmpa #FC_DANGER
 bne ai_discard_13
 ; 36: danger_one 5 from one riichi (4 * dg_val[5]).
 ldaa wk_best
 cmpa #36
 bcc ai_discard_02
 bra ai_discard_07
ai_discard_13:
 ; Against a riichi, a tenpai push with at most one live winning tile (ev_lk)
 ; does not push a tile of danger 60 or more (wk_best is doubled in tenpai):
 ; it folds. In the last draws the tenpai is kept for the payment at a drawn
 ; hand, and the last place keeps pushing.
 tst min_s
 bne ai_discard_07
 ldaa draws_left
 cmpa #PUSH_FOLD_LEFT
 bcs ai_discard_07
 ldaa wk_best
 cmpa #120
 bcs ai_discard_07
 jsr any_riichi
 beq ai_discard_07
 ldaa ai_player
 jsr count_ge
 cmpb #4
 beq ai_discard_07
 ldaa ad_pick
 staa wk_kind
 jsr ev_lk_x
 ldaa 0,x
 cmpa #2
 bcs ai_discard_02
 bra ai_discard_07
ai_discard_04:
	jsr	least_danger
	jmp	ai_discard_07
ai_discard_05:
 ldab min_s
 bne ai_discard_06
 jsr ev_discard
 ; An open hand whose every tenpai has no yaku (ev_best = 0) chooses among
 ; the 1-shanten discards instead, when there is one.
 ldx ev_best
 bne ai_discard_07
 jsr ai_open_furo
 beq ai_discard_07
 ; sk above min_s is not exact (sk_exact); best_accept then needs every sk.
 clr wk_count
 clr wk_kind
ai_discard_08:
 jsr ad_allowed
 beq ai_discard_09
 jsr sk_exact
 cmpa #1
 bne ai_discard_09
 staa wk_count
ai_discard_09:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne ai_discard_08
 ldaa wk_count
 beq ai_discard_07
 staa min_s
ai_discard_06:
	jsr	set_intents
 jsr toi_prepare
 jsr tie_policy
 ; Four pairs (chiitoi 2-shanten) one shanten ahead of the ordinary shape
 ; do not decide the hand: draws that lower the ordinary shape count too.
 ldaa min_s
 cmpa #2
 bne ai_discard_11
 cmpa spec_low
 bne ai_discard_11
 inca
 cmpa ad_norm_min
 bne ai_discard_11
 inc ac_both
ai_discard_11:
	jsr	best_accept
 clr ac_both
	ldaa	min_s
	cmpa	#1
	bne	ai_discard_07
	jsr	ev1_discard
ai_discard_07:
 clr spec_off
	ldaa	ai_player
	ldab	ad_pick
	jmp	hand_pick


; counts = 14 tiles. Sets spec_off to SPEC_NO_CHII for four pairs with a
; set (a triplet or three kinds in a row) or three two-sided shapes: people
; play such a hand for sets, not for chiitoi. With a furo no special shape
; is counted, so SPEC_NO_CHII changes nothing there.
chii_check:
 clr spec_off
 jsr spec_count
 ldaa SP_PAIRS,x
 cmpa #4
 bne chii_check_09
 ldx #counts+K_FIRST
 ldab #K_FIRST
chii_check_00:
 ldaa 0,x
 cmpa #3
 bcc chii_check_08
 cmpb #K_HONOR
 bcc chii_check_01
 tsta
 beq chii_check_01
 tst 1,x
 beq chii_check_01
 tst 2,x
 bne chii_check_08
chii_check_01:
 inx
 incb
 cmpb #K_END
 bne chii_check_00
 ; Kind 0 is no tile: ryan_pairs takes nothing out of the hand.
 clr wk_kind
 jsr ryan_pairs
 cmpa #3
 bcs chii_check_09
chii_check_08:
 ldaa #SPEC_NO_CHII
 staa spec_off
chii_check_09:
 rts

; counts = 14 tiles. Sets sk of every kind (shanten after discarding it, $7F if
; not allowed by kk1/kk2), min_s (lowest of them) and ad_forbidden_s.
discard_sk:
 ldaa #$7F
 staa wk_limit
discard_sk_lim:
 ldaa #8
 staa spec_low
 tst spec_off
 bmi discard_sk_00
 jsr spec_prep14
discard_sk_00:
 jsr batch_prepare_lim
	ldaa	#$7F
	staa	min_s
 staa ad_forbidden_s
 staa ad_norm_min
	clr	wk_kind
; sk begins as ordinary-shape results; consume and replace one kind at a time.
ad_s_loop:
 jsr ad_allowed
 beq ad_s_loop_00
 ldaa sk-counts,x
 staa skn-counts,x
 cmpa ad_norm_min
 bge ad_s_loop_03
 staa ad_norm_min
ad_s_loop_03:
 jsr shanten_lim
 staa sk-counts,x
 cmpa min_s
 bge ad_s_loop_02
 staa min_s
 bra ad_s_loop_02
ad_s_loop_00:
 tst 0,x
 beq ad_s_loop_01
 jsr shanten_lim
 cmpa ad_forbidden_s
 bge ad_s_loop_01
 staa ad_forbidden_s
ad_s_loop_01:
 ldaa #$7F
 staa sk-counts,x
ad_s_loop_02:
	inc	wk_kind
	ldaa	wk_kind
	cmpa	#K_END
	bne	ad_s_loop
 rts

; discard_sk keeps sk exact only up to min_s: batch_leaf skips the leaves
; above wk_limit. For an open hand (no chiitoi or kokushi), makes sk of the
; allowed kind wk_kind exact. Returns A = sk.
sk_exact:
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa min_s
 ble sk_exact_00
 dec 0,x
 jsr sh_general
 psha
 jsr kind_counts_x
 inc 0,x
 pula
 staa sk-counts,x
sk_exact_00:
 rts

; Returns A = 1 if kind wk_kind is in the hand and may be discarded, and
; X = &counts[wk_kind].
; Returns with N and Z set from A.
ad_allowed:
	jsr	kind_counts_x
	tst	0,x
	beq	ad_allowed_00
	ldaa	wk_kind
	cmpa	kk1
	beq	ad_allowed_00
	cmpa	kk2
	beq	ad_allowed_00
	ldaa	#1
	rts
ad_allowed_00:
	clra
	rts

; Sets ad_pick to the kind with sk <= wk_limit and the lowest danger.
; With wk_limit = 0 (a push in tenpai), the danger is doubled and a
; furiten tenpai adds 1, so of two equal dangers the live tenpai is taken.
least_danger:
 jsr oc_build
 jsr ev_prepare
	ldaa	#$FF
	staa	wk_best
	clr	wk_kind
least_danger_00:
	jsr	ad_allowed
	beq	least_danger_01
	ldaa	sk-counts,x
	cmpa	wk_limit
	bgt	least_danger_01
	jsr	danger
 ldab wk_limit
 bne least_danger_02
 asla
 psha
 jsr ev_value
 pula
 tst ev_furiten
 beq least_danger_02
 inca
least_danger_02:
 ; Of equal danger, the discard with the lower sk (nearer to tenpai); of
 ; equal sk too, the one with the lower connection, so that the blocks stay.
 jsr kind_counts_x
 ldab sk-counts,x
	cmpa	wk_best
 bcs least_danger_03
 bne least_danger_01
 cmpb ld_sk
 bcs least_danger_03
 bne least_danger_01
 ; A push in tenpai keeps the most live winning tiles (ev_discard).
 ldab wk_limit
 bne least_danger_05
 jsr ev_lk_x
 ldab 0,x
 cmpb ld_live
 bhi least_danger_06
 bcs least_danger_01
least_danger_05:
 jsr connection
 cmpa ld_conn
 bcc least_danger_01
 bra least_danger_04
least_danger_03:
	staa	wk_best
 stab ld_sk
 jsr ev_lk_x
 ldab 0,x
least_danger_06:
 stab ld_live
 jsr connection
least_danger_04:
 staa ld_conn
	ldaa	wk_kind
	staa	ad_pick
least_danger_01:
	inc	wk_kind
	ldaa	wk_kind
	cmpa	#K_END
	bne	least_danger_00
	rts

; Sets ad_pick to the candidate (choose_cands) that leaves the most tiles that
; lower the shanten number, and cc_lower to ac_lower of each candidate.
best_accept:
 jsr cand_build
 ; Flush keeps the off-suit candidates; toitoi and chiitoi keep their pairs
 ; and triplets: the single candidates. Each when there is one.
 clr flush_only
 tst iw_flush
 beq best_accept_01
 ldx #kind_off_suit
 jsr cand_restrict
 staa flush_only
best_accept_01:
 ldaa intents
 bita #I_TOI+I_CHII
 beq best_accept_02
 ldx #kind_single
 jsr cand_restrict
best_accept_02:
	jsr	choose_cands
 jsr ad_rel_build
	ldaa	cc_order
	staa	ad_pick
	clr	wk_best
	clr	cc_slot
best_accept_10:
	ldx	#cc_order
	ldab	cc_slot
	jsr	addxb
	ldaa	0,x
	cmpa	#$FF
	beq	best_accept_22
	staa	wk_kind
 ; Evaluate and restore this discard before adding its policy bonus.
 jsr candidate_acceptance
 ; ev1_discard reads ac_lower of this slot from cc_lower.
 ldab cc_slot
 aslb
 aslb
 addb cc_slot
 ldx #cc_lower
 jsr addxb
 ldaa ac_lower
 staa 0,x
 ldaa ac_lower+1
 staa 1,x
 ldaa ac_lower+2
 staa 2,x
 ldaa ac_lower+3
 staa 3,x
 ldaa ac_lower+4
 staa 4,x
 ; keep_value orders the candidates (cc_bonus) but is not part of the
 ; score: it compares kinds of tile, not whether the tile is in a block.
 jsr keep_value
 staa dora_unit
 ldx #cc_bonus
 ldab cc_slot
 jsr addxb
 ldaa 0,x
 suba dora_unit
 ; Acceptance is in tile units, without a cap or scaling. Other terms
 ; total at most 61 here; saturate only if their final addition overflows.
	adda	wk_score
 bcc accept_dora
 ldaa #$FF
accept_dora:
 ; Each dora lost (cc_costs) and each han of a yakuhai pair broken takes an
 ; eighth of the acceptance, at least 1: they multiply the value of the
 ; hand, not the number of winning tiles.
 psha
 ldab cc_costs-cc_bonus,x
 ldaa wk_kind
 cmpa #K_HONOR
 bcs accept_dora_03
 pshb
 jsr kind_counts_x
 ldaa 0,x
 cmpa #2
 bcs accept_dora_04
 ldaa wk_kind
 jsr is_yakuhai
 pulb
 aba
 tab
 bra accept_dora_03
accept_dora_04:
 pulb
accept_dora_03:
 tstb
 bne accept_dora_05
 pula
 bra accept_compare
accept_dora_05:
 ldaa wk_score
 lsra
 lsra
 lsra
 bne accept_dora_02
 inca
accept_dora_02:
 staa dora_unit
 pula
accept_dora_00:
 suba dora_unit
 bcs accept_dora_01
 decb
 bne accept_dora_00
 bra accept_compare
accept_dora_01:
 clra
accept_compare:
 cmpa wk_best
 bhi best_accept_20
 bcs best_accept_21
 tst tie_ukeire
 beq best_accept_21
 ldab wk_score
 cmpb ad_best_ukeire
 bls best_accept_21
 ldaa wk_best
best_accept_20:
 staa wk_best
 ldaa wk_score
 staa ad_best_ukeire
	ldaa	wk_kind
	staa	ad_pick
best_accept_21:
	inc	cc_slot
	ldaa	cc_slot
	cmpa	#CC_LIMIT
	bne	best_accept_10
best_accept_22:
	rts

; Selects CC_LIMIT kinds of cand, ordered by completed policy value.
; CC_KEY_BASE is larger than any cc_cand_bonus (at most about 80 with the
; two-sided shapes of ryan_pairs), so cc_key does not wrap.
CC_KEY_BASE .equ 90
choose_cands:
 ldx #cc_order
 ldab #CC_LIMIT
 ldaa #$FF
cand_clear_order:
 staa 0,x
 staa cc_ranks-cc_order,x
 inx
 decb
 bne cand_clear_order
 clr wk_kind
cand_loop:
 jsr kind_cand_x
 tst 0,x
 beq cand_next
 jsr isolated_cand
 staa cc_isol_flag
 jsr kind_counts_x
 jsr sanshoku_cut
 staa cc_sanshoku
 jsr kind_counts_x
 inc 0,x
 ; cc_key = connection + dora lost + CC_KEY_BASE - cc_cand_bonus: the larger
 ; the bonus of discarding it, the earlier it is chosen.
cand_priority:
 jsr short_conn
 staa cc_key
 jsr dora_cut_cost
 adda cc_key
 staa cc_key
 jsr toi_bonus
 staa wk_bonus
 jsr discard_bonus
 staa cc_cand_bonus
 nega
 adda #CC_KEY_BASE
 adda cc_key
 staa cc_key
 tst cc_isol_flag
 beq choose_cands_10
 clr cc_key
choose_cands_10:
 ; Equal priorities prefer losing less dora, then the completed bonus.
cc_rank:
 ; Kokushi discards its middle tiles first.
 tst iw_kok
 beq cc_rank_value
 jsr kind_is_yaochu
 bne cc_rank_value
 clr cc_key
cc_rank_value:
 ldx #cc_order
 ldab #CC_LIMIT
cc_rank_00:
 ldaa cc_ranks-cc_order,x
 cmpa cc_key
 bhi cc_rank_02
 bne cc_rank_01
 ldaa cc_costs-cc_order,x
 cmpa dcc_cost
 bhi cc_rank_02
 bne cc_rank_01
 ldaa cc_bonus-cc_order,x
 cmpa cc_cand_bonus
 bcs cc_rank_02
cc_rank_01:
 inx
 decb
 bne cc_rank_00
 bra cand_next
cc_rank_02:
 stx cc_insert_x
 decb
 beq cc_rank_04
 ldx #cc_order+CC_LIMIT-2
cc_rank_03:
 ldaa 0,x
 staa 1,x
 ldaa cc_ranks-cc_order,x
 staa cc_ranks-cc_order+1,x
 ldaa cc_bonus-cc_order,x
 staa cc_bonus-cc_order+1,x
 ldaa cc_costs-cc_order,x
 staa cc_costs-cc_order+1,x
 dex
 decb
 bne cc_rank_03
cc_rank_04:
 ldx cc_insert_x
 ldaa wk_kind
 staa 0,x
 ldaa cc_key
 staa cc_ranks-cc_order,x
 ldaa cc_cand_bonus
 staa cc_bonus-cc_order,x
 ldaa dcc_cost
 staa cc_costs-cc_order,x
cand_next:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne cand_loop
 rts

; Collects the facts pai_* of the tiles of the computer player (hand and
; furo tiles counted together), kind by kind; makes no decision.
scan_pai:
 ldx #pai_acc_start
 ldab #pai_acc_end-pai_acc_start
pai_clear:
 clr 0,x
 inx
 decb
 bne pai_clear
 ldaa #K_FIRST
 staa pai_kind
scan_pai_00:
 ldab pai_kind
 jsr counts_x
 ldaa pai_kind
 jsr kind_number
 cmpa #1
 beq pai_edge
 cmpa #7
 bne scan_pai_10
pai_edge:
 ldaa pai_kind
 cmpa #K_HONOR
 bcc scan_pai_10
 ; Disjoint complete 123/789 sequences; the terminal is counted below.
 ldaa 0,x
 cmpa 1,x
 bls pai_edge_min
 ldaa 1,x
pai_edge_min:
 cmpa 2,x
 bls pai_edge_add
 ldaa 2,x
pai_edge_add:
 asla
 adda pai_chanta_seq
 staa pai_chanta_seq
scan_pai_10:
 ldaa 0,x
 adda furo_tiles-counts,x
 beq scan_pai_50
 staa wk_count
 ldab pai_kind
 jsr is_dora_kind
 beq pai_dora_seen
 ; A dora is usable when paired or with a hand tile of its suit within 2.
 ldab wk_count
 cmpb #2
 bcc pai_dora_ok
 ldaa pai_kind
 cmpa #K_HONOR
 bcc pai_dora_seen
 ldx #counts
 jsr near_sum
 ldab 2,x
 cba
 beq pai_dora_seen
pai_dora_ok:
 addb pai_dora_use
 stab pai_dora_use
 ldaa pai_kind
 jsr is_simple
 beq pai_dora_seen
 inc pai_dora_tan
pai_dora_seen:
 ldaa wk_count
 cmpa #2
 bcs pai_notpair
 inc pai_pairs
 cmpa #3
 bcs pai_toi_value
 inc pai_trips
pai_toi_value:
 ldaa pai_kind
 jsr is_yakuhai
 beq pai_pair_dora
 inc pai_ypairs
 adda pai_toi_yaku
 staa pai_toi_yaku
 ldaa wk_count
 cmpa #3
 bcs pai_toi_ydora
 inc pai_toi_yaku
 inc pai_ytrips
pai_toi_ydora:
 ldaa dora_hits
 beq pai_notpair
 inc pai_toi_yaku
 bra pai_notpair
pai_pair_dora:
pai_notpair:
 ldaa pai_kind
 cmpa #K_HONOR
 bcc pai_honor
 jsr kind_suit
 tab
 ldx #pai_suit0
 jsr addxb
pai_sadd:
 ldab wk_count
 addb 0,x
 stab 0,x
 ; Record completed blocks while the same suit is already being counted.
 stx pai_suit_ptr
 ldab pai_kind
 jsr counts_x
 ldaa pai_kind
 jsr kind_number
 ldab wk_count
 cmpb #3
 bcc pai_block
 cmpa #7
 bhi scan_pai_21
 ldab 1,x
 addb furo_tiles-counts+1,x
 beq scan_pai_21
 ldab 2,x
 addb furo_tiles-counts+2,x
 beq scan_pai_21
 cmpa #7
 beq scan_pai_20
pai_block:
 ; Chanta must cut a block of ranks 2-8 other than 789: count it as 3.
 cmpa #1
 beq scan_pai_20
 cmpa #9
 beq scan_pai_20
 ldab #3
 addb pai_chanta_cut
 stab pai_chanta_cut
scan_pai_20:
 inc pai_blocks
 ldx pai_suit_ptr
 ldab #1
 stab pai_block0-pai_suit0,x
scan_pai_21:
 ; Ranks 4-6 that are paired or have a hand tile of their suit within 2;
 ; such a red five also counts as connected.
 suba #4
 cmpa #2
 bhi scan_pai_30
 ldaa pai_kind
 ldx #counts
 jsr near_sum
 ldab 2,x
 cba
 bne pai_c46_add
 cmpb #2
 bcs scan_pai_30
pai_c46_add:
 addb pai_chanta_cut
 stab pai_chanta_cut
 ldaa ai_player
 jsr player
 ldab pai_kind
 jsr addxb
 tst 0,x
 bpl scan_pai_30
 inc pai_dora_use
 inc pai_dora_tan
 bra scan_pai_30
pai_honor:
 ; Score each honor kind by group size: singleton=0, pair=1,
 ; triplet or kan=2. This is a soft contribution, not a requirement.
 ldaa wk_count
 cmpa #2
 bcs scan_pai_30
pai_hon_pair:
 cmpa #3
 bcc pai_hon_trip
 inc pai_honor_pts
 bra scan_pai_30
pai_hon_trip:
 inc pai_honor_pts
 inc pai_honor_pts
scan_pai_30:
pai_is_yao:
 ldaa pai_kind
 jsr is_yaochu
 beq pai_add_simple
 inc pai_yao_kinds
 ldab wk_count
 addb pai_yaochu
 stab pai_yaochu
 bra scan_pai_50
pai_add_simple:
 ldab wk_count
 addb pai_simple
 stab pai_simple
scan_pai_50:
 inc pai_kind
 ldaa pai_kind
 cmpa #K_END
 bne scan_pai_00
 ; Keep physical counts intact. work+4..6 is scratch here: a numbered
 ; fixed meld contributes 2, not its 3/4 tiles. This location also puts
 ; pai_suit0..2 within the unsigned indexed addressing range.
 ldx pai_suit0
 stx pai_suit_work
 ldaa pai_suit2
 staa pai_suit_work+2
 ldaa nfuro
 staa wk_count
 beq pai_score_max
 ldaa ai_player
 jsr player
pai_score_furo:
 stx pai_suit_ptr
 ldaa P_FURO+1,x
 cmpa #K_HONOR
 bcc pai_score_next
 jsr kind_suit
 tab
 ldaa P_FURO,x
 ; Type bit 1 distinguishes kans: subtract 1 for chi/pon, 2 for kan.
 anda #2
 lsra
 inca
 nega
 ldx #pai_suit_work
 jsr addxb
 adda 0,x
 staa 0,x
pai_score_next:
 ldx pai_suit_ptr
 inx
 inx
 inx
 dec wk_count
 bne pai_score_furo
pai_score_max:
 ldx #pai_suit_work
 clrb
 clra
pai_max_loop:
 cmpa 0,x
 bcc pai_max_next
 ldaa 0,x
 stab pai_max_suit
 pshb
 ldab pai_suit0-pai_suit_work,x
 stab pai_max
 pulb
pai_max_next:
 inx
 incb
 cmpb #3
 bcs pai_max_loop
 ; The pointer is dead after this scan; reuse its first byte for the score.
 staa pai_flush_score
 rts

; Phase 1: determine all compatible hand intents before scoring any tile.
; Recompute the coarse hand intents on every discard decision. These are
; hints, except that flush intent prefers off-suit equal-shanten discards.
; Reads the facts of scan_pai and of the furo (ai_furo_x).
set_intents:
 jsr scan_pai
 ldx #intent_flags
 ldab #intent_flags_end-intent_flags
set_intents_00:
 clr 0,x
 inx
 decb
 bne set_intents_00
 ; Thresholded weights keep this pass cheap and avoid forcing a route.
 ; Kokushi and chiitoi are given up for good after a furo (a closed kan
 ; included); kokushi also when a yaochu kind is all shown.
 ldab nfuro
 bne intent_no_chii
 ldaa pai_yao_kinds
 cmpa #8
 bcs intent_no_kok
 tst kokushi_dead
 bne intent_no_kok
 inc iw_kok
intent_no_kok:
 ldaa pai_pairs
 cmpa #5
 bcs intent_no_chii
 inc iw_chiitoi
intent_no_chii:
 jsr ai_furo_x
 tst furo_attr-minshun_n,x
 bmi intent_no_chi
 ldaa pai_chanta_cut
 cmpa #3
 bcc intent_no_chi
 ldaa pai_yaochu
 ; A chi counts 2, as a 123/789 sequence in pai_chanta_seq does.
 adda pai_chanta_seq
 ; X still points to this player's furo facts through the toitoi test.
 adda 0,x
 adda 0,x
 cmpa #8
 bcs intent_no_chi
 inc iw_chi
intent_no_chi:
 ldaa pai_simple
 cmpa #8
 bcs intent_no_tanyao
 ldaa furo_attr-minshun_n,x
 bita #FURO_NO_TANYAO
 bne intent_no_tanyao
 ; A usable simple dora supports an earlier tanyao route (8 simples,
 ; at most 5 yaochu), but a yaochu furo still forbids it.
 ldab #5
 tst pai_dora_tan
 beq intent_tan_limit
 ldab #6
intent_tan_limit:
 stab wk_left
 ldaa pai_yaochu
 cmpa wk_left
 bcc intent_no_tanyao
 inc iw_tanyao
intent_no_tanyao:
 ; Toitoi: no minshun, at least three pairs, and pairs (triplets
 ; included) + triplets + pai_toi_yaku >= 8. Tanyao/dora value is
 ; not evidence of a triplet shape.
 ; Toitoi stays locked (intent_lock) until a chi.
 tst 0,x
 bne intent_toi_off
 ldaa intent_lock-minshun_n,x
 bita #$40
 bne intent_toi_on
 ldaa pai_pairs
 cmpa #3
 bcs intent_toi_off
intent_toi_sum:
 adda pai_trips
 adda pai_toi_yaku
intent_toi_cmp:
 cmpa #8
 bcs intent_toi_off
intent_toi_on:
 inc iw_toi
 ldaa intent_lock-minshun_n,x
 oraa #$40
 bra intent_toi_store
intent_toi_off:
 ldaa intent_lock-minshun_n,x
 anda #$BF
intent_toi_store:
 staa intent_lock-minshun_n,x
 ; Flush: only when the off-suit tiles do not help: the hand without them
 ; has the same shanten number (sh_general) as the whole hand. A pair of an
 ; honor with no unseen copy counts there as a single tile, since it makes
 ; no set. Before two shanten the hand waits: off-suit isolated tiles go
 ; first anyway.
 ldaa pai_flush_score
 adda pai_honor_pts
 cmpa #8
 bcs set_intents_80
 inc iw_flush
 jsr iw_off_suit_furo
 bne intent_fl_clear
 jsr sh_general
 staa wk_left
 cmpa #3
 bcc intent_fl_clear
 ldab #K_END-1
intent_fl_save:
 pshb
 jsr counts_x
 pulb
 tba
 jsr off_suit
 bne intent_fl_save_00
 cmpb #K_HONOR
 bcs intent_fl_save_01
 tst unseen-counts,x
 bne intent_fl_save_01
 ldaa 0,x
 psha
 cmpa #2
 bcs intent_fl_save_01
 ldaa #1
 staa 0,x
 bra intent_fl_save_01
intent_fl_save_00:
 ldaa 0,x
 psha
 clr 0,x
intent_fl_save_01:
 decb
 bne intent_fl_save
 jsr sh_general
 suba wk_left
 staa wk_left
 ldab #1
intent_fl_rest:
 pshb
 jsr counts_x
 pulb
 tba
 jsr off_suit
 bne intent_fl_rest_00
 cmpb #K_HONOR
 bcs intent_fl_rest_01
 tst unseen-counts,x
 bne intent_fl_rest_01
intent_fl_rest_00:
 pula
 staa 0,x
intent_fl_rest_01:
 incb
 cmpb #K_END
 bne intent_fl_rest
 tst wk_left
 beq set_intents_80
intent_fl_clear:
 clr iw_flush
set_intents_80:
 ; intents: one bit for each byte of intent_flags (I_*), in their order.
 clra
 ldx #intent_flags
set_intents_81:
 asla
 tst 0,x
 beq set_intents_82
 inca
set_intents_82:
 inx
 cpx #intent_flags_end
 bne set_intents_81
 staa intents
 rts

; A completed sequence or triplet outside the target suit blocks flush intent.
; Counts include concealed tiles; furo_tiles adds tiles from existing furo.
iw_off_suit_furo:
 ldx #pai_block0
 ldab pai_max_suit
 jsr addxb
 clr 0,x
 ldaa pai_block0
 oraa pai_block1
 oraa pai_block2
 rts

; How much better it is to discard kind wk_kind, added by discard_bonus:
; keep_value (the base) + intent_bonus (against an intent). best_accept
; takes keep_value out again: it only orders the candidates.
; Both return A = the value of the first rule of their table that matches the
; intents and the facts of wk_kind (counts = 14 tiles). A rule is the
; intents and the facts that must all be set, and the result.
; intent_bonus lists its rules from the largest value down: the first match
; is the largest.
keep_value:
 ldx #kv_rules
 bra rule_value
intent_bonus:
 ldx #ib_rules
rule_value:
 stx rv_rule
 ldaa intents
 tst flush_only
 beq rule_value_02
 oraa #I_FONLY
rule_value_02:
 staa rv_intent
 ; Second fact byte: tiles in the hand, unseen copies (0, 1, 2 or more).
 jsr kind_counts_x
 ldab #F_C1
 ldaa 0,x
 cmpa #1
 beq rule_value_10
 ldab #F_C2
rule_value_10:
 stab rv_fact+1
 jsr kind_unseen_x
 ldaa 0,x
 cmpa #3
 bcc rule_value_13
 ldab #F_U0
rule_value_11:
 deca
 bmi rule_value_12
 aslb
 bra rule_value_11
rule_value_12:
 orab rv_fact+1
 stab rv_fact+1
rule_value_13:
 ; First fact byte: F_YAO, F_HONOR, F_T28 and F_M46 are the bits of kattr.
 ldab wk_kind
 jsr kattr_x
 ldaa 0,x
 anda #F_YAO+F_HONOR+F_T28+F_M46
 bita #F_YAO
 bne rule_value_14
 oraa #F_NYAO
rule_value_14:
 staa rv_fact
 bita #F_HONOR
 beq rule_value_22
 ldaa wk_kind
 jsr is_yakuhai
 beq rule_value_22
 ldaa rv_fact
 oraa #F_YAKU
 staa rv_fact
rule_value_22:
 jsr kind_off_suit
 bne rule_value_30
 ldaa rv_fact
 oraa #F_KEEP
 staa rv_fact
rule_value_30:
 ldx rv_rule
rule_value_31:
 ldaa rv_intent
 anda 0,x
 cmpa 0,x
 bne rule_value_32
 ldaa rv_fact
 anda 1,x
 cmpa 1,x
 bne rule_value_32
 ldaa rv_fact+1
 anda 2,x
 cmpa 2,x
 bne rule_value_32
 ldaa 3,x
 rts
rule_value_32:
 inx
 inx
 inx
 inx
 bra rule_value_31

; Bits of intents (set_intents) and rv_intent (also flush_only).
I_FONLY .equ $40
I_TOI .equ $20
I_KOK .equ $10
I_CHI .equ $08
I_CHII .equ $04
I_TAN .equ $02
I_FLUSH .equ $01
F_YAO .equ A_YAOCHU
F_HONOR .equ A_HONOR
F_YAKU .equ $04
F_T28 .equ A_T28
F_KEEP .equ $10 ; the flush suit or an honor (not kind_off_suit)
F_NYAO .equ $20 ; not yaochu
F_M46 .equ A_M46
F_C1 .equ $01 ; one tile in the hand
F_C2 .equ $02 ; two or more
F_U0 .equ $04 ; unseen copies 0
F_U1 .equ $08
F_U2 .equ $10

; Intents (I_*), facts of the first and of the second byte (F_*), result.
kv_rules:
 .byte I_KOK,F_YAO,F_C1,0
 .byte 0,F_HONOR,F_C1+F_U0,6
 .byte 0,F_HONOR,F_C1+F_U1,5
 .byte 0,F_HONOR,F_C1+F_U2,5 ; a single honor with a copy seen seldom makes a set
 .byte I_CHII,0,F_C2,0
 .byte I_TOI,0,F_C2,0
 .byte I_FLUSH,F_HONOR+F_YAKU,F_C1,0 ; flush keeps a single yakuhai over another honor
 .byte I_FLUSH,F_HONOR,F_C1,1
 .byte I_FLUSH,F_KEEP,0,0
 .byte I_CHI,F_YAO,0,0
 .byte I_CHI,F_M46,0,3
 .byte I_CHI,0,0,1
 .byte 0,F_HONOR+F_YAKU,0,1
 .byte 0,F_HONOR,F_C1,4
 .byte 0,F_HONOR,0,3
 .byte 0,F_YAO,0,3 ; a 1 or a 9: the honors matched above
 .byte 0,F_T28,0,2
 .byte 0,0,0,1
ib_rules:
 .byte I_FONLY,0,0,2
 .byte I_TAN,F_HONOR,0,2
 .byte I_CHI,F_M46,0,2
 .byte I_KOK,F_NYAO,0,2
 .byte I_CHII,0,F_C1+F_U0,2
 .byte I_TOI,0,F_C1+F_U0,2
 .byte I_TAN,F_YAO,0,1 ; a 1 or a 9: the honors matched above
 .byte I_KOK,F_YAO,F_C2,1
 .byte I_CHII,0,F_C1+F_U1,1
 .byte I_TOI,0,F_C1+F_U1,1
 .byte 0,0,0,0

 ; Original 14-tile counts. dcc_cost and wk_bonus (toitoi) were
 ; computed by candidate ranking; cc_sanshoku is the 13-tile sanshoku value.
 ; A = complete final-score adjustment, cached with the shortlisted kind.
 ; The dora lost (dcc_cost) and a yakuhai pair broken are taken from the
 ; acceptance in best_accept.
discard_bonus:
 ldaa #46
 adda wk_bonus
 adda cc_sanshoku
 staa wk_bonus
 jsr keep_value
 adda wk_bonus
 staa wk_bonus
 jsr intent_bonus
 adda wk_bonus
 staa wk_bonus
 ; 2 for each two-sided shape left, without a toitoi or kokushi intent
 ; (chiitoi keeps its pairs by cand_restrict in best_accept instead).
 ldaa intents
 bita #I_TOI+I_KOK
 bne discard_bonus_01
 jsr ryan_pairs
 asla
 adda wk_bonus
 staa wk_bonus
discard_bonus_01:
 ldaa wk_bonus
 rts

; Returns A = the pairs of kinds n, n+1 (n = 2 to 7) of one suit in counts
; without one wk_kind: the two-sided shapes, counting a sequence as two.
ryan_pairs:
 jsr kind_counts_x
 dec 0,x
 clr rp_n
 ldx #counts+2
 ldaa #3
 staa rp_s
ryan_pairs_00:
 ldab #6
ryan_pairs_01:
 tst 0,x
 beq ryan_pairs_02
 tst 1,x
 beq ryan_pairs_02
 inc rp_n
ryan_pairs_02:
 inx
 decb
 bne ryan_pairs_01
 inx
 inx
 inx
 inx
 dec rp_s
 bne ryan_pairs_00
 jsr kind_counts_x
 inc 0,x
 ldaa rp_n
 rts

; A = kind. Returns A = 1 for terminals and honors, with N and Z set from A.
; Preserves B and X.
kind_is_yaochu:
 ldaa wk_kind
is_yaochu:
 cmpa #K_HONOR
 bcc is_yaochu_00
 jsr kind_number
 cmpa #1
 beq is_yaochu_00
 cmpa #9
 beq is_yaochu_00
 clra
 rts
is_yaochu_00:
 ldaa #1
 rts

; Returns a retention weight for shortlist ranking (lower is discarded first).
; Numbers use nearby tile count. Honors have no sequence connections:
; singleton=1, pair=4, completed triplet/quad=8.
connection:
 ldaa wk_kind
 cmpa #K_HONOR
 bcs connection_00
 jsr kind_counts_x
 ldab 0,x
 ldx #cn_honor_weights
 jsr addxb
 ldaa 0,x
 rts
connection_00:
 ldx #counts
 jmp near_sum
cn_honor_weights:
 .byte 0,1,4,8,8

; Shortlist only: a duplicate may be cut while preserving a complete sequence.
; connection leaves X at the five-cell ns_buf for numbers. Isolation is unchanged.
short_conn:
 jsr connection
 ldab intents
 bitb #I_TOI+I_KOK
 bne short_conn_02
 ldab wk_kind
 cmpb #K_HONOR
 bcc short_conn_02
 ldab 2,x
 cmpb #2
 bne short_conn_02
 tst 1,x
 beq short_conn_00
 tst 0,x
 bne short_conn_01
 tst 3,x
 bne short_conn_01
short_conn_00:
 tst 3,x
 beq short_conn_02
 tst 4,x
 beq short_conn_02
short_conn_01:
 suba #3
short_conn_02:
 rts

; Marks the candidates of best_accept in cand: sk = min_s, and with ac_both
; also skn = ad_norm_min (four pairs do not decide for chiitoi).
cand_build:
 clr wk_kind
cand_build_00:
 jsr kind_cand_x
 clr 0,x
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa min_s
 beq cand_build_01
 cmpa #$7F
 beq cand_build_02
 tst ac_both
 beq cand_build_02
 ldaa skn-counts,x
 cmpa ad_norm_min
 bne cand_build_02
cand_build_01:
 jsr kind_cand_x
 inc 0,x
cand_build_02:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne cand_build_00
 rts

; Returns X = &cand[wk_kind].
kind_cand_x:
 ldab wk_kind
 ldx #cand
 jmp addxb

; X = routine that tests kind wk_kind (A = 1 if it has the property). If a
; candidate has the property, removes the candidates without it and returns
; A = 1; else returns A = 0 and keeps them.
; Returns with N and Z set from A.
cand_restrict:
 stx cr_test
 clr wk_count
cand_restrict_00:
 clr wk_kind
cand_restrict_01:
 jsr kind_cand_x
 tst 0,x
 beq cand_restrict_03
 ldx cr_test
 jsr 0,x
 tst wk_count
 bne cand_restrict_02
 tsta
 beq cand_restrict_03
 inc wk_count
 bra cand_restrict_00
cand_restrict_02:
 tsta
 bne cand_restrict_03
 jsr kind_cand_x
 clr 0,x
cand_restrict_03:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne cand_restrict_01
 ldaa wk_count
 rts

; Returns A = 1 if the hand has one tile of kind wk_kind.
; Returns with N and Z set from A.
kind_single:
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 beq kind_single_00
 clra
 rts
kind_single_00:
 tsta
 rts

; Returns A = 1 if the hand (counts) has a pair of an off-suit kind, or two
; off-suit tiles of one suit within 2 of each other.
; Returns with N and Z set from A.
off_suit_shape:
 clr wk_kind
off_suit_shape_00:
 jsr kind_off_suit
 beq off_suit_shape_02
 jsr kind_counts_x
 ldaa 0,x
 beq off_suit_shape_02
 cmpa #2
 bcc off_suit_shape_03
 ldaa wk_kind
 jsr kind_number
 ; The kind after 9 is a gap (count 0); 8 and 9 have no kind 2 above.
 cmpa #8
 ldab 1,x
 bcc off_suit_shape_01
 addb 2,x
off_suit_shape_01:
 bne off_suit_shape_03
off_suit_shape_02:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_HONOR
 bne off_suit_shape_00
 clra
 rts
off_suit_shape_03:
 ldaa #1
 rts
; Returns A = the off-suit tiles in the hand (counts).
off_suit_tiles:
 clr wk_count
 clr wk_kind
off_suit_tiles_00:
 jsr kind_off_suit
 beq off_suit_tiles_01
 jsr kind_counts_x
 ldaa 0,x
 adda wk_count
 staa wk_count
off_suit_tiles_01:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_HONOR
 bne off_suit_tiles_00
 ldaa wk_count
 rts
; A = kind, returns 1 for a numbered tile outside pai_max_suit, otherwise 0.
; kind_off_suit (wk_kind) also returns 1 for a single honor with a copy seen,
; which seldom makes a set; it keeps X = &counts[wk_kind] for an honor.
; Returns with N and Z set from A.
kind_off_suit:
 ldaa wk_kind
 cmpa #K_HONOR
 bcs off_suit
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 bne off_suit_01
 jsr kind_unseen_x
 ldaa 0,x
 jsr kind_counts_x
 cmpa #3
 bcc off_suit_01
 ldaa #1
 rts
off_suit:
 cmpa #K_HONOR
 bcc off_suit_01
 jsr kind_suit
 cmpa pai_max_suit
 beq off_suit_01
 ldaa #1
 rts
off_suit_01:
 clra
 rts
; A non-dora singleton with no neighbour within two, before discard.
; Minimum-shanten and flush legality are checked by the caller.
; Returns with N and Z set from A.
isolated_cand:
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 bne isolated_cand_00
 jsr connection
 cmpa #1
 bne isolated_cand_00
 jsr dora_cut_cost
 bne isolated_cand_00
 ldaa #1
 rts
isolated_cand_00:
 clra
 rts

; wk_kind = discard. Count its acceptance in wk_score, then restore counts
; and the relevance filter so another candidate can be evaluated.
candidate_acceptance:
 jsr kind_counts_x
 jsr relevant
 jsr acceptance
 staa wk_score
 jsr kind_counts_x
 inc 0,x
 jsr rel_restore
 rts

; counts = the hand after the discard (shanten min_s). Returns A = number
; of unseen tiles that lower the shanten number, and sets bit (k & 7) of
; ac_lower[k >> 3] for every such kind k.
acceptance:
	jsr	demo_poll
 ldaa min_s
 adda ac_both
 jsr acc_mark
 clr wk_accept
 clr wk_draw
 ldx #ac_lower
 ldab #5
acceptance_10:
 clr 0,x
 inx
 decb
 bne acceptance_10
 ldx #counts
acceptance_00:
 stx ac_ptr
 ; acc_mark asked the draws that can lower a shape, with unseen copies only.
 tst ac_yes-counts,x
 beq acceptance_04
 ldaa unseen-counts,x
 staa wk_unseen
 inc 0,x
 ldab wk_draw
 cmpb wk_kind
 bne acceptance_02
 ldaa ad_forbidden_s
 bra acceptance_03
acceptance_02:
 jsr accept_eval
acceptance_03:
 psha
 ldx ac_ptr
 dec 0,x
 pula
 cmpa min_s
 bge acceptance_04
 ldaa wk_accept
 adda wk_unseen
 staa wk_accept
 ldaa wk_draw
 tab
 lsrb
 lsrb
 lsrb
 ldx #ac_lower
 jsr addxb
 anda #7
 tab
 ldaa #1
acceptance_11:
 decb
 bmi acceptance_12
 asla
 bra acceptance_11
acceptance_12:
 oraa 0,x
 staa 0,x
acceptance_04:
 ldx ac_ptr
 inx
 inc wk_draw
 ldaa wk_draw
 cmpa #K_END
 bne acceptance_00
 ldaa wk_accept
 rts

 ; Acceptance needs only to know whether the shanten value drops.
accept_eval:
 tst spec_near
 beq acceval_regular
 jmp ac_special
acceval_regular:
 ldx ac_ptr
 ldaa ac_yes-counts,x
 cmpa #2
 beq acceval_yes
 ldaa min_s
 rts
acceval_yes:
	ldaa	min_s
	deca
	rts

 ; Keep neighborhood sums in rel, rather than rebuilding boolean flags.
; Each candidate changes only its own kind and its suited neighbors.
ad_rel_build:
 clr wk_first
ad_rel_build_00:
 ldab wk_first
 jsr kattr_x
 ldaa 0,x
 beq ad_rel_build_01
 ldaa wk_first
 ldx #counts
 jsr near_sum
ad_rel_build_01:
 ldx #rel
 ldab wk_first
 jsr addxb
 staa 0,x
 inc wk_first
 ldaa wk_first
 cmpa #K_END
 bne ad_rel_build_00
 rts

; X = &counts[wk_kind]. Removes that tile and prepares rel for the 13-tile hand.
relevant:
 dec 0,x
 clr ac_kok_active
 clr spec_near
 ldab nfuro
 bne relevant_00
 ; A draw lowers a special shape by one at most, and no shape of the 13
 ; tiles is below min_s: only a special shape at min_s can go below.
 jsr ad_spec_values
 ldx #spec13
 jsr spec_shanten
 cmpa min_s
 bne relevant_00
 inc spec_near
 ldaa spec13+SP_YAO
 ldab spec13+SP_YPAIRS
 jsr kok_sh
 cmpa min_s
 bne relevant_00
 inc ac_kok_active
relevant_00:
 ldab min_s
 beq rel_tenpai
 ldaa #$FF
 bra rel_adjust
rel_restore:
 ldaa #1
rel_adjust:
 staa ad_rel_delta
 ldaa wk_kind
 staa wk_first
 staa ara_last
 cmpa #K_HONOR
 bcc rel_restore_01
 jsr kind_number
 cmpa #1
 beq rel_restore_00
 dec wk_first
 cmpa #2
 beq rel_restore_00
 dec wk_first
rel_restore_00:
 cmpa #9
 beq rel_restore_01
 inc ara_last
 cmpa #8
 beq rel_restore_01
 inc ara_last
rel_restore_01:
 ldx #rel
 ldab wk_first
 jsr addxb
rel_restore_02:
 ldaa 0,x
 adda ad_rel_delta
 staa 0,x
 ldaa wk_first
 cmpa ara_last
 beq rel_restore_03
 inc wk_first
 inx
 bra rel_restore_02
rel_restore_03:
 rts
 .bss
ad_rel_delta: .ds 1 ; +1 or -1 for rel
ac_kok_active: .ds 1 ; 1 when kokushi is tied for best
spec_near: .ds 1 ; 1 when a special shape of the 13 tiles is at min_s
 .code

; Tenpai scoring uses only rel[j] != 0, so reuse raw neighborhood sums.
; Add all yaochu kinds when kokushi is tied for best.
rel_tenpai:
 jsr ad_rel_build
 tst ac_kok_active
 beq rel_tenpai_01
	clr	wk_first
rel_tenpai_00:
	ldx	#yao_offsets
	ldab	wk_first
	jsr	addxb
	ldab	0,x
	ldx	#rel
	jsr	addxb
	ldaa	#1
	staa	0,x
	inc	wk_first
	ldaa	wk_first
	cmpa	#13
	bne	rel_tenpai_00
rel_tenpai_01:
 rts

; Prepare live/dead concealed pair counts once per attacking discard.
; set_intents never sets iw_toi with a minshun. unseen counts our future discard as seen.
toi_prepare:
 clr toi_dead
 clr toi_live
 tst iw_toi
 beq toi_prepare_03
 ldaa #K_FIRST
 staa tp_kind
toi_prepare_00:
 ldab tp_kind
 jsr counts_x
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #2
 bne toi_prepare_02
 ldaa unseen-counts,x
 beq toi_prepare_01
 adda toi_live
 staa toi_live
 bra toi_prepare_02
toi_prepare_01:
 inc toi_dead
toi_prepare_02:
 inc tp_kind
 ldaa tp_kind
 cmpa #K_END
 bne toi_prepare_00
toi_prepare_03:
 rts

; Original 14-tile counts, candidate wk_kind. No hand changes.
; 8-2*m-min(p,5-m), reserving at most one exhausted pair as head.
; +2 at normal min_s, +1 one step behind; +1 if a live pair remains.
; Distant routes get no bonus. The main minimum-shanten filter is unchanged.
toi_bonus:
 tst iw_toi
 beq toi_bonus_00
 ldaa pai_trips
 staa tb_n_trips
 ldaa pai_pairs
 suba pai_trips
 staa tb_n_pairs
 ldaa toi_dead
 staa tb_n_dead
 ldaa toi_live
 staa tb_n_live
 jsr kind_counts_x
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #3
 beq toib_trip
 cmpa #2
 bne toib_shape
 dec tb_n_pairs
 jsr kind_unseen_x
 ldaa 0,x
 beq toib_drop_dead
 staa wk_left
 ldaa tb_n_live
 suba wk_left
 staa tb_n_live
 bra toib_shape
toib_drop_dead:
 dec tb_n_dead
 bra toib_shape
toib_trip:
 dec tb_n_trips
 inc tb_n_pairs
 jsr kind_unseen_x
 ldaa 0,x
 beq toib_add_dead
 adda tb_n_live
 staa tb_n_live
 bra toib_shape
toib_add_dead:
 inc tb_n_dead
toib_shape:
 ldaa #5
 suba tb_n_trips
 staa toi_slots
 ldaa tb_n_pairs
 suba tb_n_dead
 tst tb_n_dead
 beq toib_cap
 inca
toib_cap:
 cmpa toi_slots
 bls toib_used
 ldaa toi_slots
toib_used:
 staa toi_slots
 ldaa tb_n_trips
 asla
 adda toi_slots
 staa toi_slots
 ldaa #8
 suba toi_slots
 suba min_s
 bcs toib_equal
 cmpa #2
 bcc toi_bonus_00
 nega
 adda #2
 bra toib_live
toib_equal:
 ldaa #2
toib_live:
 tst tb_n_live
 beq toib_done
 inca
toib_done:
 rts
toi_bonus_00:
 clra
 rts

; Numbered dora loss per indicator is the original concealed copy count.
; Honors use [copies][unseen] below; each matching indicator adds that loss.
; Red adds one only if actually discarded. Maximum loss is 9*5=45.
; A=cost, B/X scratch. Original counts and physical hand stay unchanged.
; Returns with N and Z set from A.
dora_cut_cost:
 jsr kind_counts_x
 ldaa 0,x
 staa dcc_count
 ldaa wk_kind
 cmpa #K_HONOR
 bcs dora_cut_cost_01
 ; Approximate middle/late game after 24 tiles leave the live wall.
 ldaa dcc_count
 cmpa #1
 bne dora_cut_cost_00
 ldaa draws_left
 cmpa #LIVE_DRAWS-24+1
 bcc dora_cut_cost_00
 bra dora_cut_cost_01
dora_cut_cost_00:
 ldaa dcc_count
 asla
 asla
 staa dcc_count
 jsr kind_unseen_x
 ldab 0,x
 addb dcc_count
 ldx #dcc_honor_table
 jsr addxb
 ldaa 0,x
 staa dcc_count
dora_cut_cost_01:
 ldab wk_kind
 jsr is_dora_kind
 tab
 beq dora_cut_cost_03
 clra
dora_cut_cost_02:
 adda dcc_count
 decb
 bne dora_cut_cost_02
dora_cut_cost_03:
 staa dcc_cost
 jsr ai_hand_pick
 bitb #1
 beq dora_cut_cost_04
 inc dcc_cost
dora_cut_cost_04:
 ldaa dcc_cost
 rts

; Rows: concealed copies 0..4; columns: unseen copies 0..3.
; Impossible combinations are zero. All callers supply a held legal kind.
dcc_honor_table:
 .byte 0,0,0,0
 .byte 1,1,2,2
 .byte 3,3,4,0
 .byte 5,6,0,0
 .byte 6,0,0,0

; B=kind, return the number of matching dora indicators (0..5).
is_dora_kind:
 ldx #dora_of_kind
 jsr addxb
 ldaa 0,x
 staa dora_hits
 rts

; A = kind. Returns A = 1 for a dragon, the round wind or the seat wind of
; the computer, 2 for a double wind (Z set for 0).
is_yakuhai:
	cmpa	#K_HAKU
	bcc	is_yakuhai_04
	staa	iyk_kind
 ldaa ai_player
 jsr winds_of
 pshb
 clrb
	cmpa	iyk_kind
	bne	is_yakuhai_00
	incb
is_yakuhai_00:
 pula
	cmpa	iyk_kind
	bne	is_yakuhai_01
	incb
is_yakuhai_01:
 tba
	rts
is_yakuhai_04:
	ldaa	#1
	rts

; Returns A = danger of discarding kind wk_kind against the riichi of
; player danger_player (0 = safe ... 7), ordered by the deal-in rates
; measured in checks/20261118_fold_tenpai/danger_rate.md:
;   honor, unseen 0-1 / 2 / 3+          1 / 2 / 5
;   number, rank 1 2 3 4 5 6 7 8 9
;     all suji sides passed             3 5 6 4 4 4 6 5 3
;     no suji side passed               6 7 7 7 7 7 7 7 6
;     4-6 with one of two sides passed  6
; A number one lower (not below 2) when no sequence with it can be made
; from unseen tiles (kabe).
danger_one:
	ldab	wk_kind
	jsr	in_opp_river
	beq	danger_one_00
	clra
	rts
danger_one_00:
	ldaa	wk_kind
	cmpa	#K_HONOR
	bcs	danger_one_01
 jsr kind_unseen_x
	ldab	0,x
	ldx	#dg_honor_tab
	jsr	addxb
	ldaa	0,x
	rts
danger_one_01:
 jsr kind_number
	staa	dg_rank
	clr	dg_suji
	clr	dg_sides
	cmpa	#4
	bcs	danger_one_02
	inc	dg_sides
	ldab	wk_kind
	subb	#3
	jsr	in_opp_river
	beq	danger_one_02
	inc	dg_suji
danger_one_02:
	ldab	dg_rank
	cmpb	#7
	bcc	danger_one_03
	inc	dg_sides
	ldab	wk_kind
	addb	#3
	jsr	in_opp_river
	beq	danger_one_03
	inc	dg_suji
danger_one_03:
	ldx	#dg_suji_tab-1
	ldaa	dg_suji
	cmpa	dg_sides
	beq	danger_one_04
	ldx	#dg_none_tab-1
	tsta
	beq	danger_one_04
	ldaa	#6
	bra	danger_one_05
danger_one_04:
	ldab	dg_rank
	jsr	addxb
	ldaa	0,x
danger_one_05:
	; kabe: none of (k-2,k-1), (k-1,k+1), (k+1,k+2) is all unseen
	ldab	wk_kind
	subb	#2
	jsr	unseen_x
	ldab	1,x
	beq	danger_one_06
	ldab	3,x
	bne	danger_one_08
	ldab	0,x
	bne	danger_one_08
	bra	danger_one_07
danger_one_06:
	ldab	3,x
	beq	danger_one_07
	ldab	4,x
	bne	danger_one_08
danger_one_07:
	cmpa	#3
	bcs	danger_one_08
	deca
danger_one_08:
	rts
dg_honor_tab:
 .byte 1,1,2,5,5
dg_suji_tab:
 .byte 3,5,6,4,4,4,6,5,3
dg_none_tab:
 .byte 6,7,7,7,7,7,7,7,6

; B = kind. Returns A nonzero if the riichi player danger_player cannot ron
; it: it is in his river, or it passed after his riichi (river_bits).
; Returns with N and Z set from A.
in_opp_river:
 ldx #river_bits
 jsr addxb
 ldaa 0,x
 ldab danger_player
 beq in_opp_river_01
in_opp_river_00:
 lsra
 decb
 bne in_opp_river_00
in_opp_river_01:
 anda #$11
 rts

; unseen[k] = tiles of kind k the computer cannot see: unshown[k] less
; its own tiles. Made once from the 14-tile hand; the thinking changes counts
; to try discards and draws, but unseen keeps the 14-tile view.
ai_unseen:
 ldx #unshown
ai_unseen_00:
 ldaa 0,x
 suba counts-unshown,x
 staa unseen-unshown,x
 inx
 cpx #unshown+KN
 bne ai_unseen_00
 rts

; ---------------------------------------------------------------- calls

; The computer reacts to dc_tile (no ron). Returns A = R_PASS, R_PON or
; R_CHI with B = pattern.
ca_none:
	clra
	rts
ai_call:
	ldaa	ai_player
	jsr	player
	tst	P_FLAG,x
	bmi	ca_none
	tst	draws_left
	beq	ca_none
	ldaa	ai_player
	jsr	call_options
	ldaa	rp_pon
	oraa	rp_chi
	beq	ca_none
 ; A call from 4 tiles leaves one tile (hadaka tanki), which cannot defend:
 ; only when nobody is a threat (any_threat).
 ldaa ai_player
 jsr player
 ldaa P_LEN,x
 cmpa #4
 bne ai_call_01
 jsr any_threat
 bne ca_none
ai_call_01:
	ldaa	dc_tile
	lsra
	staa	call_kind
	tst	rp_pon
	beq	ai_call_10
	; No pon from a held triplet. ai_call does not return R_KAN, so the
	; computer never declares an open kan.
	tst	rp_kan
	beq	ai_call_00
	clr	rp_pon
	bra	ai_call_10
ai_call_00:
	ldaa	call_kind
	jsr	is_yakuhai
	staa	call_yakuhai
ai_call_10:
	; Remaining calls need both intent and shanten; counts are restored.
	jsr	set_intents
 ldaa iw_flush
 staa call_flush
 ; A flush call needs the off-suit tiles to be isolated, or at most two
 ; of them; best_accept keeps them as the only candidates after the call.
 jsr off_suit_shape
 beq ai_call_20
 jsr off_suit_tiles
 cmpa #3
 bcs ai_call_20
 clr call_flush
ai_call_20:
	jsr	shanten
	staa	call_shanten_now
 jsr call_before_ukeire
 ; In tenpai, the value of not calling for call_ev_more.
 tst call_shanten_now
 bne ai_call_22
 jsr ev_no_call
 stx call_ev_now
ai_call_22:
	tst	rp_pon
	beq	call_chi
ai_call_21:
 tst call_yakuhai
 bne yakuhai_call
call_pon_route:
 tst iw_toi
 bne call_pon_shanten
	jsr	call_yaku_ok
	beq	call_chi
call_pon_shanten:
	ldaa	call_kind
	staa	ck_a
	staa	ck_b
	ldab	#1
	jsr	call_shanten
	cmpa	call_shanten_now
	blt	ai_call_30
	bgt	call_chi
	; A qualified yakuhai is already a guaranteed yaku.
 tst call_yakuhai
 bne ai_call_30
	; Same-shanten pon may also continue chanta. Not tanyao: such a
	; call only makes the hand cheaper.
	jsr	call_flush_ok
	oraa	iw_toi
	oraa	iw_chi
	beq	call_chi
ai_call_30:
	ldaa	#R_PON
	rts

; If yakuhai value is insufficient, try other routes without relaxing shanten.
; Another yakuhai: 3 han (2 for the dealer) of the yakuhai and usable dora
; (pai_dora_use), a set, a furo, another yakuhai pair, or for the dealer
; two other blocks. The shanten may stay the same.
yakuhai_call:
	; A double wind skips the extra value test, not the shanten check.
	ldaa	call_yakuhai
	cmpa	#2
	beq	yakuhai_call_00
	ldaa	pai_dora_use
	ldab	ai_player
	cmpb	dealer
	bne	call_yakuhai_han
	inca
call_yakuhai_han:
	cmpa	#2
	bcc	yakuhai_call_00
	ldaa	nfuro
	oraa	pai_trips
	oraa	pai_blocks
	bne	yakuhai_call_00
	ldaa	pai_ypairs
	cmpa	#2
	bcc	yakuhai_call_00
	ldab	ai_player
	cmpb	dealer
	bne	call_pon_route
	jsr	leaf_parts
	cmpa	#3
	bcs	call_pon_route
yakuhai_call_00:
	bra	call_pon_shanten
call_chi:
	ldaa	rp_chi
	beq	yakuhai_call_10
	tst iw_chi
	bne call_chanta_pats
	jsr	call_yaku_ok
	beq	yakuhai_call_10
call_chanta_pats:
	clr	call_pat
call_ploop:
	ldab	call_pat
 jsr chi_pat_ok
	beq	call_pnext
	ldaa	call_kind
	ldab	call_pat
	jsr	chi_kinds
	jsr	call_chi_yaku
	beq	call_pnext
	ldab	call_pat
	jsr	call_shanten
	cmpa	call_shanten_now
	blt	call_paccept
	bgt	call_pnext
	; Same-shanten chi needs an active route that call_chi_yaku kept
	; (not tanyao, as for pon).
	jsr	call_flush_ok
	oraa	iw_chi
	beq	call_pnext
call_paccept:
	ldab	call_pat
	ldaa	#R_CHI
	rts
call_pnext:
	inc	call_pat
	ldaa	call_pat
	cmpa	#3
	bne	call_ploop
yakuhai_call_10:
	clra
	rts

; Returns A = 1 if the computer already has a yakuhai triplet (closed or
; melded), or if all its tiles and call_kind are simples (tanyao).
; Returns with N and Z set from A.
call_yaku_ok:
 tst iw_chi
 beq call_yaku_ok_00
 ldaa call_kind
 cmpa #K_END
 bcc call_yaku_ok_00
 jsr is_yaochu
 beq call_yaku_ok_00
 ; Calling fixes chanta: only a hand without central shapes calls for it.
 tst pai_chanta_cut
 beq call_yaku_ok_10
call_yaku_ok_00:
 jsr call_flush_ok
 bne call_yaku_ok_10
 ; These facts were collected by set_intents before any call trial.
 tst pai_ytrips
 bne call_yaku_ok_10
 tst pai_yaochu
 bne call_yaku_ok_11
 jmp call_is_simple
call_yaku_ok_10:
	ldaa	#1
	rts
call_yaku_ok_11:
	clra
	rts

; A flush call uses eligibility cached before the trials and must stay within
; the target suit (or honors). Other yaku are checked by the caller.
; Returns with N and Z set from A.
call_flush_ok:
 tst call_flush
 beq call_flush_ok_00
 ldaa call_kind
 cmpa #K_END
 bcc call_flush_ok_00
 cmpa #K_HONOR
 bcc cflush_yes
 jsr off_suit
 bne call_flush_ok_00
cflush_yes:
 ldaa #1
 rts
call_flush_ok_00:
 clra
 rts
KUITAN_LEFT .equ 40

; Returns A = 1 if the chi of ck_a and ck_b keeps a yaku.
; Returns with N and Z set from A.
call_chi_yaku:
 jsr call_flush_ok
 bne cflush_yes
 tst iw_chi
 beq call_chi_yaku_02
 tst pai_chanta_cut
 bne call_chi_yaku_02
 ldaa call_kind
 cmpa ck_a
 bls call_chi_yaku_00
 ldaa ck_a
call_chi_yaku_00:
 cmpa ck_b
 bls call_chi_yaku_01
 ldaa ck_b
call_chi_yaku_01:
 jsr kind_number
 cmpa #1
 beq cflush_yes
 cmpa #7
 beq cflush_yes
 bra call_chi_yaku_03
call_chi_yaku_02:
 ; Tanyao needs a hand and furo without yaochu, as in call_yaku_ok.
 tst pai_yaochu
 bne call_chi_yaku_03
 jsr call_is_simple
	beq	call_chi_yaku_03
	ldaa	ck_a
	jsr	is_simple
	beq	call_chi_yaku_03
	ldaa	ck_b
	jsr	is_simple
	beq	call_chi_yaku_03
	; Early, a closed hand with fewer than two usable dora keeps a two-sided
	; block for riichi: tanyao does not chi with it (two simples next to each
	; other are always two-sided).
	tst	nfuro
	bne	call_chi_yaku_04
	ldaa	draws_left
	cmpa	#KUITAN_LEFT
	bcs	call_chi_yaku_04
	ldaa	pai_dora_use
	cmpa	#2
	bcc	call_chi_yaku_04
	ldaa	ck_b
	suba	ck_a
	cmpa	#1
	beq	call_chi_yaku_03
	cmpa	#$FF
	beq	call_chi_yaku_03
call_chi_yaku_04:
	ldaa	#1
	rts
call_chi_yaku_03:
	ldab	call_kind
	pshb
	ldaa	#$FF
	staa	call_kind
	jsr	call_yaku_ok
	pulb
	stab	call_kind
	tsta
	rts

; A = kind. Returns A = 1 for 2-8 of a suit.
; Returns with N and Z set from A. Preserves B and X.
call_is_simple:
 ldaa call_kind
is_simple:
	cmpa	#K_HONOR
	bcc	is_simple_00
 jsr is_yaochu
 eora #1
	rts
is_simple_00:
	clra
	rts


	.bss
; unshown sits before counts and work right after it: ai_unseen reads counts
; as counts-unshown,x, and make_tot writes work as work-counts,x.
unshown: .ds KN ; tiles of each kind not yet shown on the table (turn.asm)
counts: .ds KN ; tiles of each kind in the closed hand (eval_load)
sg_stop: .ds 1 ; sg_init sets $80: the end of counts for sg_entry_x
work: .ds 4 ; make_tot scratch: 37 contiguous bytes in total
pai_suit_work: .ds 3 ; scan-only suit scores; alias inside work, no added RAM
 .ds KN-7
furo_tiles: .ds KN ; tiles of each kind in the furo
sk:	.ds	KN ; shanten after discarding each kind ($7F = not allowed)
unseen: .ds KN ; tiles of each kind the computer cannot see (ai_unseen)
ac_yes: .ds KN ; acc_mark result per kind: 0 no, 1 asked, 2 lowers the shanten
skn: .ds KN ; discard_sk: ordinary-shape shanten after discarding each allowed kind
; scan_pai clears pai_acc_start..pai_acc_end. pai_block0..2 follow
; pai_suit0..2 (written as pai_block0-pai_suit0,x).
pai_acc_start:
pai_ytrips: .ds 1 ; yakuhai triplets
pai_trips: .ds 1 ; triplets (hand and furo)
pai_toi_yaku: .ds 1 ; toitoi value of yakuhai pairs and triplets
pai_chanta_seq: .ds 1 ; 2 per complete 123/789 sequence in the hand
pai_pairs: .ds 1 ; kinds with 2 or more tiles
pai_yao_kinds: .ds 1 ; yaochu kinds
pai_yaochu: .ds 1 ; yaochu tiles
pai_simple: .ds 1 ; simple tiles
pai_suit0: .ds 1 ; man tiles
pai_suit1: .ds 1 ; pin tiles
pai_suit2: .ds 1 ; sou tiles
pai_block0: .ds 1 ; 1 if man has a complete block
pai_block1: .ds 1 ; 1 if pin has a complete block
pai_block2: .ds 1 ; 1 if sou has a complete block
pai_max: .ds 1 ; physical tiles of the suit selected by the flush score
pai_max_suit: .ds 1 ; suit with the largest flush score (0..2)
pai_honor_pts: .ds 1 ; honor pairs 1, triplets 2
pai_ypairs: .ds 1 ; yakuhai kinds with 2 or more tiles
pai_blocks: .ds 1 ; complete blocks of the suits
pai_dora_use: .ds 1 ; usable dora tiles (paired or with a tile within 2)
pai_dora_tan: .ds 1 ; usable simple dora kinds
pai_chanta_cut: .ds 1 ; tiles chanta must cut (a non-chanta block counts 3)
pai_acc_end:
rel:	.ds	KN ; kinds that can lower the shanten (sum of nearby tiles)
; The candidate list sits after the pai_ block: pai_suit0-pai_suit_work,x
; must stay within 255.
cc_insert_x:	.ds	2 ; cc_order slot to insert at
; cc_key is allocated in directpage.asm.
cc_slot:	.ds	1 ; cc_order slot being scored
; cc_order, cc_ranks, cc_bonus and cc_costs are read as offsets from a
; cc_order entry (cc_ranks-cc_order,x and so on).
cc_order:	.ds	CC_LIMIT ; candidate kinds ($FF = none)
cc_ranks: .ds CC_LIMIT ; their ranks
cc_bonus: .ds CC_LIMIT ; their discard_bonus values
cc_costs: .ds CC_LIMIT ; their dora costs
dora_unit: .ds 1 ; best_accept: acceptance taken for each dora lost
cc_lower: .ds CC_LIMIT*5 ; ac_lower of each cc_order slot that best_accept evaluated
cc_cand_bonus: .ds 1 ; discard_bonus of the candidate being ranked
; set_intents clears intent_flags..intent_flags_end.
intent_flags:
iw_toi: .ds 1 ; toitoi intent
iw_kok: .ds 1 ; kokushi intent
iw_chi: .ds 1 ; chanta intent
iw_chiitoi: .ds 1 ; chiitoi intent
iw_tanyao: .ds 1 ; tanyao intent
iw_flush: .ds 1 ; flush intent
intent_flags_end:
intents: .ds 1 ; set_intents: one bit for each byte of intent_flags (I_*)
pai_flush_score: ; alias: valid after scan_pai, until the next scan
pai_suit_ptr: .ds 2 ; scan-only pointer; first byte is pai_flush_score afterward
call_yakuhai: .ds 1 ; nonzero when call_kind is yakuhai
; pai_kind is allocated in directpage.asm.
danger_player: .ds 1 ; riichi player danger_one is checking
; wk_limit is allocated in directpage.asm.
; wk_best is allocated in directpage.asm.
; wk_score is allocated in directpage.asm.
ai_tile:	.ds	1 ; tile ai_discard chose
ak_before:	.ds	1 ; shanten before the kan
; wk_accept is allocated in directpage.asm.
; wk_unseen is allocated in directpage.asm.
ara_last:	.ds	1 ; last kind rel_adjust changes
iyk_kind:	.ds	1 ; kind is_yakuhai checks
dg_rank:	.ds	1 ; rank of wk_kind (1..9)
dg_suji:	.ds	1 ; suji sides already discarded
dg_sides:	.ds	1 ; suji sides that exist
call_shanten_now:	.ds	1 ; shanten before the call
; call_kind is allocated in directpage.asm.
call_flush: .ds 1 ; cached flush call eligibility before pattern trials
flush_only:	.ds	1 ; 1 when best_accept keeps only off-suit candidates
rv_rule: .ds 2 ; rule_value: the rule being matched
rv_intent: .ds 1 ; rule_value: I_* of intent_flags
rv_fact: .ds 2 ; rule_value: F_* of wk_kind
cr_test: .ds 2 ; routine of cand_restrict
	.code
; Returns A = the open furo of ai_player (chi, pon and open kan; an ankan
; leaves the hand closed). Returns with N and Z set from A.
ai_open_furo:
 jsr ai_furo_x
 ldaa minshun_n-minshun_n,x
 adda minkou_n-minshun_n,x
 adda minkan_n-minshun_n,x
 rts

; Returns A = 1 if another player has a riichi (any_riichi), or a riichi or
; two furo (any_threat). Returns with N and Z set from A.
; oc_mask[p] = suits whose danger from player p is half. For a player
; without riichi, with 10 river tiles or more, whose furo of numbered tiles
; are all of one suit S: 0 to 2 tiles of S in his river make the other two
; suits half (he may be on a one-suit hand), 3 or more make S half.
oc_build:
 ldaa #3
oc_build_00:
 staa oc_p
 clrb
 cmpa ai_player
 beq oc_build_06
 jsr player
 tst P_FLAG,x
 bmi oc_build_06
 ldaa P_RLEN,x
 cmpa #10
 bcs oc_build_06
 ldaa P_NFURO,x
 beq oc_build_06
 staa oc_n
 stx oc_x
 ; B = S, $FF while only honor furo are read.
 ldab #$FF
oc_build_01:
 ldaa P_FURO+1,x
 jsr kind_suit
 cmpa #3
 beq oc_build_02
 tstb
 bmi oc_build_03
 cba
 bne oc_build_05
oc_build_03:
 tab
oc_build_02:
 inx
 inx
 inx
 dec oc_n
 bne oc_build_01
 tstb
 bmi oc_build_05
 stab oc_s
 ; oc_n = tiles of S in the river.
 ldx oc_x
 ldab P_RLEN,x
oc_build_04:
 ldaa P_RIVER,x
 lsra
 jsr kind_suit
 cmpa oc_s
 bne oc_build_07
 inc oc_n
oc_build_07:
 inx
 decb
 bne oc_build_04
 ldaa #1
 ldab oc_s
 beq oc_build_09
oc_build_08:
 asla
 decb
 bne oc_build_08
oc_build_09:
 ldab oc_n
 cmpb #3
 bcc oc_build_10
 eora #7
oc_build_10:
 tab
 bra oc_build_06
oc_build_05:
 clrb
oc_build_06:
 ; oc_mask[oc_p] = B.
 pshb
 ldab oc_p
 ldx #oc_mask
 jsr addxb
 pulb
 stab 0,x
 ldaa oc_p
 deca
 bpl oc_build_00
 rts

; A = shanten of the hand ai_player keeps. Returns A = fold_result with N and Z:
; FC_ATTACK  nobody is a threat (any_threat).
; FC_PUSH    a threat, but the hand is near: push with the least danger.
; FC_DANGER  a riichi, 1-shanten and fewer than 40 draws left: fold when
;            every discard that keeps the shanten has danger 5 or more.
; FC_FOLD    fold: draws_left / 4 draws cannot reach tenpai, or a threat
;            and 2-shanten or more.
; ai_discard and ai_call (call_shanten) both use it, so a call never makes
; a hand that folds. X and B are scratch.
PUSH_FOLD_LEFT .equ 10
FC_ATTACK .equ 0
FC_PUSH .equ 1
FC_DANGER .equ 2
FC_FOLD .equ 3
fold_check:
 staa fold_result
 ldab draws_left
 lsrb
 lsrb
 ldaa #FC_FOLD
 cmpb fold_result
 bcs fold_check_01
 jsr any_threat
 beq fold_check_01
 ldab fold_result
 ldaa #FC_FOLD
 cmpb #2
 bcc fold_check_01
 ldaa #FC_PUSH
 decb
 bne fold_check_01
 jsr any_riichi
 beq fold_check_00
 ldaa draws_left
 cmpa #40
 ldaa #FC_DANGER
 bcs fold_check_01
fold_check_00:
 ldaa #FC_PUSH
fold_check_01:
 staa fold_result
 rts

any_riichi:
 ldaa #5
 bra any_riichi_03
; A threat is a riichi or furo_threat of at least 2, or 3 while 50 draws or
; more are left (two furo are seldom tenpai so early).
any_threat:
 ldaa #2
 ldab draws_left
 cmpb #50
 bcs any_riichi_03
 inca
any_riichi_03:
 staa threat_furo
	ldab	#3
any_riichi_00:
	cmpb	ai_player
	beq	any_riichi_01
	tba
	jsr	player
	tst	P_FLAG,x
	bmi	any_riichi_02
 pshb
 jsr furo_threat
 pulb
 cmpa threat_furo
 bcc any_riichi_02
any_riichi_01:
	decb
	bpl	any_riichi_00
	clra
	rts
any_riichi_02:
	ldaa	#1
	rts

; X = player. Returns A = his furo, one more with a pon or an open kan of a
; dora. X and B are scratch.
furo_threat:
 ldab P_NFURO,x
 stab ft_left
 stab ft_n
 beq furo_threat_02
furo_threat_00:
 ldaa P_FURO,x
 anda #3
 beq furo_threat_01
 cmpa #M_ANKAN
 beq furo_threat_01
 ldab P_FURO+1,x
 stx ft_x
 ldx #dora_of_kind
 jsr addxb
 ldaa 0,x
 ldx ft_x
 tsta
 beq furo_threat_01
 inc ft_n
 bra furo_threat_02
furo_threat_01:
 inx
 inx
 inx
 dec ft_left
 bne furo_threat_00
furo_threat_02:
 ldaa ft_n
 rts

; Returns A = danger of discarding wk_kind: the sum over the other players
; of weight * dg_val[danger_one], at most 126. The weight follows the
; tenpai rate measured in CPU games: riichi 4; else by furo_threat 0, 1,
; 2, 3 or more: 0, 1, 2, 3 (25%, 50%, 69% tenpai).
danger:
	clr	danger_player
	clr	danger_max
danger_00:
	ldaa	danger_player
	cmpa	ai_player
	beq	danger_01
	ldaa	danger_player
	jsr	player
 jsr furo_threat
 tab
	ldaa	danger_player
	jsr	player
 ; C = riichi: weight 3 + C.
 ldaa P_FLAG,x
 asla
 bcs danger_02
 tstb
 beq danger_01
 cmpb #3
 bls danger_03
danger_02:
 ldab #3
 adcb #0
danger_03:
 stab dg_weight
	jsr	danger_one
 ; oc_mask: suits whose danger from this player is half. kind_suit gives 3
 ; for an honor, a bit that oc_mask never has.
 psha
 ldab danger_player
 ldx #oc_mask
 jsr addxb
 ldab 0,x
 ldaa wk_kind
 jsr kind_suit
danger_05:
 lsrb
 deca
 bpl danger_05
 pula
 bcc danger_06
 lsra
danger_06:
 tab
 ldx #dg_val
 jsr addxb
 ldab dg_weight
 clra
danger_07:
 adda 0,x
 decb
 bne danger_07
 adda danger_max
 bcc danger_08
 ldaa #$FF
danger_08:
 staa danger_max
danger_01:
	inc	danger_player
	ldaa	danger_player
	cmpa	#4
	bne	danger_00
	ldaa	danger_max
 ; least_danger doubles it and adds 1: stay below its start $FF.
 cmpa #$7F
 bcs danger_09
 ldaa #$7E
danger_09:
	rts
; danger_one 0..7 to a value in proportion to the deal-in rate.
dg_val:
 .byte 0,1,2,4,6,9,16,22
	.bss
; ai_player is allocated in directpage.asm.
danger_max:	.ds	1 ; sum of the danger over the players
dg_weight:	.ds	1 ; weight of danger_player in danger
ld_sk:	.ds	1 ; least_danger: sk of ad_pick
ld_conn:	.ds	1 ; least_danger: connection of ad_pick
ld_live:	.ds	1 ; least_danger: ev_lk of ad_pick
; find_waits writes waits as waits-ac_yes,x: waits stays within 255 bytes after ac_yes.
waits: .ds KN ; output of find_waits: 1 for each winning kind
waits_old: .ds KN ; waits before an ankan (kan_riichi_ok)

	.bss
 .bss
 .bss
 .code
; Independent three-colour progress, original or post-discard counts.
; At least one full sequence, each suit represented, six of nine kinds.
; Bonus = distinct covered kinds - 5 (1..4), best target only.
; Every missing required kind must have an unseen copy. A minshun supplies
; its exact sequence; a pon/kan furo supplies nothing. No hand mutation.
sanshoku_cut:
 dec 0,x
sanshoku_near:
 clr s3_best
 ldaa #K_FIRST
sanshoku_pattern:
 staa s3_start
 staa s3_kind
 clr s3_full
 clr s3_total
sanshoku_suit:
 ldab s3_kind
 jsr counts_x
 clrb
 tst 0,x
 beq sanshoku_tile2
 incb
sanshoku_tile2:
 tst 1,x
 beq sanshoku_tile3
 incb
sanshoku_tile3:
 tst 2,x
 beq sanshoku_furo
 incb
sanshoku_furo:
 cmpb #3
 beq sanshoku_shape
 ldaa nfuro
 beq sanshoku_shape
 pshb
 ldaa ai_player
 jsr player
 ldab nfuro
sanshoku_near_00:
 ldaa P_FURO,x
 anda #3
 bne sanshoku_near_01
 ldaa P_FURO+1,x
 cmpa s3_kind
 beq sanshoku_full
sanshoku_near_01:
 inx
 inx
 inx
 decb
 bne sanshoku_near_00
sanshoku_back:
 pulb
 bra sanshoku_shape
sanshoku_full:
 ins
 ldab #3
sanshoku_shape:
 tstb
 beq sanshoku_near_20
 stab s3_n
 cmpb #3
 beq sanshoku_alive
 ; Missing tiles must be available; counts and unseen use identical kind indices.
 ldab s3_kind
 jsr counts_x
 ldab #3
sanshoku_missing:
 tst 0,x
 bne sanshoku_near_10
 tst unseen-counts,x
 beq sanshoku_near_20
sanshoku_near_10:
 inx
 decb
 bne sanshoku_missing
sanshoku_alive:
 ldab s3_n
 cmpb #3
 bne sanshoku_total
 inc s3_full
sanshoku_total:
 addb s3_total
 stab s3_total
sanshoku_nsuit:
 ldaa s3_kind
 adda #10
 staa s3_kind
 cmpa #K_HONOR
 bcs sanshoku_suit
 tst s3_full
 beq sanshoku_near_20
 ldaa s3_total
 suba #5
 bls sanshoku_near_20
 cmpa s3_best
 bls sanshoku_near_20
 staa s3_best
sanshoku_near_20:
 ldaa s3_start
 inca
 cmpa #K_FIRST+7
 bne sanshoku_pattern
 ldaa s3_best
 rts
 .bss
s3_start: .ds 1 ; first kind of the tried pattern
; s3_kind is allocated in directpage.asm.
s3_full: .ds 1 ; 1 when the pattern has a full sequence
s3_total: .ds 1 ; kinds the pattern covers
s3_best: .ds 1 ; best pattern value
s3_n: .ds 1 ; tiles of the suit in the pattern
; cc_sanshoku is allocated in directpage.asm.
 .bss
; dcc_count is allocated in directpage.asm.
; dcc_cost is allocated in directpage.asm.
; wk_bonus is allocated in directpage.asm.
 .code

 .bss
dora_hits: .ds 1 ; indicators that match (is_dora_kind)
toi_dead: .ds 1 ; concealed pairs with no unseen copy
toi_live: .ds 1 ; concealed pairs with an unseen copy
tp_kind: .ds 1 ; kind toi_prepare checks
tb_n_trips: .ds 1 ; triplets
tb_n_pairs: .ds 1 ; pairs that are not triplets
tb_n_dead: .ds 1 ; dead pairs
; tb_n_live is allocated in directpage.asm.
wk_left: .ds 1 ; shared work: tanyao yaochu limit (set_intents), toitoi slots left (toi_bonus)
 .code

 .bss
 .code

 .bss


 .code
 ; Special-shape values of a hand, a set of 4 bytes: kinds held, yaochu kinds
; held, kinds with 2 or more tiles, yaochu kinds with 2 or more tiles.
SP_KINDS .equ 0
SP_YAO .equ 1
SP_PAIRS .equ 2
SP_YPAIRS .equ 3
; spec14 of the 14 tiles of ai_discard (spec_prep14), spec13 after the
; discard of wk_kind (spec_cut), spec_drawn after one more draw (spec_add).
spec_prep14:
 ldaa #8
 tst nfuro
 bne spec_prep14_00
 jsr spec_count
 ldab #4
spec_prep14_01:
 ldaa 0,x
 staa 4,x
 inx
 decb
 bne spec_prep14_01
 ldx #spec14
 jsr spec_shanten
spec_prep14_00:
 staa spec_low
 rts

; Makes spec13 for the discard of wk_kind (counts has the 13 tiles).
ad_spec_values:
 jsr kind_counts_x
 ldab 0,x
 ldaa wk_kind
 bra spec_cut
; X = &counts[wk_kind] of the 14 tiles. Returns A = special-shape shanten
; after discarding one tile of wk_kind (8 with a furo). Keeps X.
spec_before:
 ldaa #8
 tst nfuro
 bne spec_before_00
 tst spec_off
 bmi spec_before_00
 stx spec_x
 ldab 0,x
 decb
 ldaa wk_kind
 bsr spec_cut
 ldx #spec13
 bsr spec_shanten
 ldx spec_x
spec_before_00:
 rts
; X = a set. Returns A = the lower of the chiitoi and kokushi shanten that
; spec_off counts (8 with SPEC_NONE). Keeps X.
spec_shanten:
 ldaa #8
 tst spec_off
 bmi spec_shanten_00
 ldaa SP_YAO,x
 ldab SP_YPAIRS,x
 jsr kok_sh
 ldab spec_off
 bne spec_shanten_00
 psha
 ldaa SP_PAIRS,x
 ldab SP_KINDS,x
 jsr chii_sh
 pulb
 cba
 ble spec_shanten_00
 tba
spec_shanten_00:
 rts
; A = kind, B = its tiles left after one of them is discarded. spec13 =
; spec14 without that tile.
spec_cut:
 psha
 ldaa #-1
 ldx #spec14
 bra spec_step
; A = kind, B = its tiles before one more is drawn. spec_drawn = spec13 with
; that tile.
spec_add:
 psha
 ldaa #1
 ldx #spec13
; X = set, A = 1 or -1 on the stack the kind, B = tiles of the kind without
; the tile. The set at 4,x is the set at X with the tile added or removed.
spec_step:
 staa spec_delta
 stab spec_tiles
 stx spec_save
 pula
 jsr is_yaochu
 staa spec_yaochu
 ldab #4
spec_step_00:
 ldaa 0,x
 staa 4,x
 inx
 decb
 bne spec_step_00
 ldx spec_save
 ; The kind (and yaochu kind) count changes with 0 other tiles of the kind,
 ; the pair (and yaochu pair) count with 1.
 ldab spec_tiles
 cmpb #1
 bhi spec_step_01
 aslb
 jsr addxb
 ldaa 4+SP_KINDS,x
 adda spec_delta
 staa 4+SP_KINDS,x
 tst spec_yaochu
 beq spec_step_01
 ldaa 4+SP_YAO,x
 adda spec_delta
 staa 4+SP_YAO,x
spec_step_01:
 rts
 .bss
; spec_off: the special shapes not counted. ai_discard sets SPEC_NO_CHII (chii_check)
; and clears it at its end; ev1_discard sets SPEC_NONE and puts back the value
; it found.
SPEC_NO_CHII .equ $01
SPEC_NONE .equ $81
spec_off: .ds 1 ; SPEC_NO_CHII, SPEC_NONE or 0
; spec_cnt, spec14, spec13 and spec_drawn are in this order: spec_prep14 and
; spec_step write at 4,x.
spec_cnt: .ds 4 ; special-shape values of counts (spec_count)
spec14: .ds 4 ; special-shape values of the 14 tiles (SP_*)
spec13: .ds 4 ; ... after the discard of wk_kind
spec_drawn: .ds 4 ; ... after one more draw
ad_norm_min: .ds 1 ; lowest ordinary-shape shanten of discard_sk
ac_both: .ds 1 ; 1 while acceptance also counts the ordinary shape one shanten behind
spec_low: .ds 1 ; special-shape shanten of spec14: no discard goes below it
spec_save: .ds 2 ; the set of spec_step
spec_x: .ds 2 ; X kept by spec_before
spec_delta: .ds 1 ; 1 or -1 in spec_step
spec_tiles: .ds 1 ; tiles of the kind without the tile in spec_step
spec_yaochu: .ds 1 ; 1 if the kind of spec_step is yaochu
 .code
; Compute special shanten after this draw from cached thirteen-tile counts.
ac_special:
 ; With the draw (counts at ac_ptr has it).
 ldx ac_ptr
 ldab 0,x
 decb
 ldaa wk_draw
 bsr spec_add
 ldx #spec_drawn
 jsr spec_shanten
 cmpa min_s
 blt ac_special_08
 jmp acceval_regular
ac_special_08:
 jmp acceval_yes

 .code

 .code
; Prefer ukeire on exact final-score ties only in a closed hand without triplets.
; This leaves triplet/kan hands on their previous tie policy.
tie_policy:
 clr tie_ukeire
 tst nfuro
 bne tie_policy_01
 ldx #counts
 ldab #KN
tie_policy_00:
 ldaa 0,x
 cmpa #3
 bcc tie_policy_01
 inx
 decb
 bne tie_policy_00
 inc tie_ukeire
tie_policy_01:
 rts
 .bss
cc_isol_flag: .ds 1 ; 1 for an isolated candidate
ad_best_ukeire: .ds 1 ; acceptance of the best candidate
tie_ukeire: .ds 1 ; output of tie_policy: 1 when equal scores compare acceptance
 .code

 .bss
ac_ptr: .ds 2 ; &counts[draw]
cand: .ds KN ; candidates of best_accept (cand_build, cand_restrict)
ac_lower: .ds 5 ; output of acceptance: 1 bit for each kind that lowers the shanten
 .code
