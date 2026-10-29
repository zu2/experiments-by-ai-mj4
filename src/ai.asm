; Computer players 1..3; ai_player selects the current thinker.
CC_LIMIT_MIN .equ 4
CC_LIMIT_MAX .equ 6

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
 bne call_shanten_restore
 jsr call_after_ukeire
 bne call_shanten_equal
 ldaa call_shanten_now
 inca
 bra call_shanten_restore
call_shanten_equal:
 ldaa call_shanten_now
call_shanten_restore:
 psha
 dec nfuro
 jsr pair_restore
 jsr clear_kk
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
	ldaa	ai_player
	jsr	eval_load
 jsr ai_unseen
 ; The start time for ev1_discard: $0B seconds, $0C frames (0..59), kept by the IRQ.
ai_discard_00:
 ldab $0C
 ldaa $0B
 cmpb $0C
 bne ai_discard_00
 staa e1_sec
 stab e1_frame
 jsr discard_sk
 ; draws_left / 4 draws are left for this player: fewer than min_s cannot
 ; reach tenpai without a call, so it only defends.
 ldaa draws_left
 lsra
 lsra
 cmpa min_s
 bcs ai_discard_02
	jsr	any_riichi
	beq	ai_discard_05
	ldaa	min_s
	cmpa	#2
	blt	ai_discard_03
ai_discard_02:
	ldaa	#$7F
	staa	wk_limit
	bra	ai_discard_04
ai_discard_03:
	ldaa	min_s
	staa	wk_limit
ai_discard_04:
	jsr	least_danger
	jmp	ai_discard_07
ai_discard_05:
 tst min_s
 bne ai_discard_06
 jsr ev_discard
 ; An open hand whose every tenpai has no yaku (ev_best = 0) chooses among
 ; the 1-shanten discards instead, when there is one.
 ldaa ev_best
 oraa ev_best+1
 oraa ev_best+2
 bne ai_discard_07
 jsr ai_furo_x
 ldaa minshun_n-minshun_n,x
 adda minkou_n-minshun_n,x
 adda minkan_n-minshun_n,x
 beq ai_discard_07
 clr wk_kind
ai_discard_08:
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa #1
 beq ai_discard_09
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne ai_discard_08
 bra ai_discard_07
ai_discard_09:
 staa min_s
ai_discard_06:
	jsr	set_intents
 jsr toi_prepare
 jsr tie_policy
	jsr	best_accept
	ldaa	min_s
	cmpa	#1
	bne	ai_discard_07
	jsr	ev1_discard
ai_discard_07:
	ldaa	ai_player
	ldab	ad_pick
	jmp	hand_pick


; counts = 14 tiles. Sets sk of every kind (shanten after discarding it, $7F if
; not allowed by kk1/kk2), min_s (lowest of them) and ad_forbidden_s.
discard_sk:
 jsr spec_prep14
 jsr batch_prepare
	ldaa	#$7F
	staa	min_s
 staa ad_forbidden_s
	clr	wk_kind
; sk begins as ordinary-shape results; consume and replace one kind at a time.
ad_s_loop:
 jsr ad_allowed
 beq ad_s_loop_00
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
least_danger:
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
	cmpa	wk_best
	bcc	least_danger_01
	staa	wk_best
	ldaa	wk_kind
	staa	ad_pick
least_danger_01:
	inc	wk_kind
	ldaa	wk_kind
	cmpa	#K_END
	bne	least_danger_00
	rts

; Sets ad_pick to the kind with sk = min_s that leaves the most tiles that
; lower the shanten number.
best_accept:
	jsr	flush_filter
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
 ldx #cc_bonus
 ldab cc_slot
 jsr addxb
 ldaa 0,x
 ; Acceptance is in tile units, without a cap or scaling. Other terms
 ; total at most 61 here, including the common dora offset; saturate
 ; only if their final addition overflows.
	adda	wk_score
 bcc accept_compare
 ldaa #$FF
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
	cmpa	cc_limit
	bne	best_accept_10
best_accept_22:
	rts

; Selects cc_limit kinds with sk = min_s, ordered by completed policy value.
; Zero defaults to 4; values outside 4..6 are clamped at the next selection.
choose_cands:
 ldaa cc_limit
 cmpa #CC_LIMIT_MIN
 bcc choose_cands_limit_low_ok
 ldaa #CC_LIMIT_MIN
 staa cc_limit
 bra choose_cands_limit_ok
choose_cands_limit_low_ok:
 cmpa #CC_LIMIT_MAX
 bls choose_cands_limit_ok
 ldaa #CC_LIMIT_MAX
 staa cc_limit
choose_cands_limit_ok:
 jsr lone_dora
 ldx #cc_order
 ldab cc_limit
 ldaa #$FF
cand_clear_order:
 staa 0,x
 staa cc_ranks-cc_order,x
 inx
 decb
 bne cand_clear_order
 clr wk_kind
cand_loop:
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa min_s
 bne cand_next
 ldaa wk_kind
 cmpa lone_dora_kind
 beq cand_shape
 jsr ad_flush_cand
 beq cand_next
cand_shape:
 jsr isolated_cand
 staa cc_isol_flag
 ldaa wk_kind
 cmpa lone_dora_kind
 bne choose_cands_00
 inc cc_isol_flag
choose_cands_00:
 jsr kind_counts_x
 jsr sanshoku_cut
 staa cc_sanshoku
 psha
 jsr kind_counts_x
 inc 0,x
 pula
cand_priority:
 nega
 adda #4
 staa cc_key
 jsr short_conn
 adda cc_key
 staa cc_key
 jsr dora_cut_cost
 adda cc_key
 staa cc_key
 jsr toi_bonus
 staa wk_bonus
 nega
 adda #3
 adda cc_key
 staa cc_key
 jsr intent_bias
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
 ; Complete the intent-compatible value before selecting the shortlist.
 ; Reuse it both for equal-priority ordering and final acceptance scoring.
 jsr discard_bonus
 staa cc_cand_bonus
 ldx #cc_order
 ldab cc_limit
cc_rank_scan:
	ldab cc_limit
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
 ldx #cc_order+2
 ldaa cc_limit
 cmpa #4
 beq cc_rank_03
 inx
 cmpa #6
 bne cc_rank_03
 inx
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
 ldaa pai_kind
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
scan_pai_40:
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
 ldab #P_FURO
 jsr addxb
pai_score_furo:
 stx pai_suit_ptr
 ldaa 1,x
 cmpa #K_HONOR
 bcc pai_score_next
 jsr kind_suit
 tab
 ldaa 0,x
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
scan_pai_60:
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
set_intents_60:
 ; Thresholded weights keep this pass cheap and avoid forcing a route.
 ; Kokushi and chiitoi are given up for good after a furo (a closed kan
 ; included); kokushi also when a yaochu kind is all shown.
 tst nfuro
 bne intent_no_chii
 ldaa pai_yao_kinds
 cmpa #8
 bcs intent_no_kok
 tst kokushi_dead
 bne intent_no_kok
 inc iw_kok
intent_no_kok:
 ldaa pai_pairs
 cmpa #4
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
set_intents_70:
 ; Flush stays locked with its suit until an off-suit set blocks it.
 ldaa intent_lock-minshun_n,x
 bpl intent_fl_new
 anda #3
 staa pai_max_suit
 inc iw_flush
 jsr iw_off_suit_furo
 bne intent_fl_clear
 bra intent_fl_lock
intent_fl_new:
 ldaa pai_flush_score
 adda pai_honor_pts
	 cmpa #8
 bcs set_intents_80
 inc iw_flush
intent_no_flush:
intent_fl_check:
 jsr iw_off_suit_furo
 bne intent_fl_clear
 ; Physical off-suit count; no shanten or taatsu search.
 ldaa pai_suit0
 adda pai_suit1
 adda pai_suit2
 suba pai_max
 cmpa #5
 bcc intent_fl_clear
intent_fl_lock:
 jsr ai_furo_x
 ldaa intent_lock-minshun_n,x
 anda #$40
 oraa #$80
 oraa pai_max_suit
 bra intent_fl_store
intent_fl_clear:
 clr iw_flush
 jsr ai_furo_x
 ldaa intent_lock-minshun_n,x
 anda #$40
intent_fl_store:
 staa intent_lock-minshun_n,x
set_intents_80:
 ; Central-tile growth is irrelevant to these active hand routes.
 ldaa iw_chi
 oraa iw_toi
 oraa iw_chiitoi
 oraa iw_kok
 staa iw_number_exempt
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

; wk_kind = current discard kind. Return a small priority adjustment: negative
; favors discarding tiles that conflict with active intents; positive keeps
; candidates that preserve them. Only used to order the expensive top four.
; Phase 2: policy adjustments from the already determined intent flags.
intent_bias:
 ldaa wk_kind
 staa ib_kind
 clr iw_bias
 ldaa iw_kok
 beq bias_chiitoi
 ldaa ib_kind
 jsr is_yaochu
 beq bias_addc_kok
 ; A candidate that duplicates a yaochu is expendable before a unique one.
 ldab ib_kind
 jsr counts_x
 ldaa 0,x
 cmpa #2
 bcc bias_addc_kok
 inc iw_bias
 bra bias_chiitoi
bias_addc_kok:
 dec iw_bias
bias_chiitoi:
 ldaa iw_chiitoi
 oraa iw_toi
 beq bias_chanta
 ldab ib_kind
 jsr counts_x
 ldaa 0,x
 cmpa #2
 bcs bias_chanta
 inc iw_bias
bias_chanta:
 tst iw_chi
 beq bias_tanyao
 ldaa ib_kind
 cmpa #K_HONOR
 bcc bias_tanyao
 jsr kind_number
 suba #4
 cmpa #2
 bhi bias_tanyao
 dec iw_bias
bias_addc_chi:
bias_tanyao:
 ; Ordinary attack keeps central tiles even without tanyao intent.
 ; Special hand routes retain their existing priorities.
 tst iw_number_exempt
 bne bias_tanyao_old
 ldaa ib_kind
 cmpa #K_HONOR
 bcc bias_tanyao_old
 jsr number_bias
 nega
 adda iw_bias
 staa iw_bias
 bra bias_flush
bias_tanyao_old:
 tst iw_tanyao
 beq bias_flush
 ldaa ib_kind
 jsr is_simple
 bne bias_flush
 dec iw_bias
bias_flush:
 tst iw_flush
 beq intent_bias_00
 ldaa ib_kind
 jsr off_suit
 beq intent_bias_00
bias_addc_flush:
 dec iw_bias
intent_bias_00:
 ldaa iw_bias
 adda #8
 rts

 ; The rank estimate only prunes work; the completed policy value also
 ; resolves equal rank/dora keys so valuable tiles do not win by kind order.
; Returns A = how much it is better to discard kind wk_kind when the
; acceptance is equal: 4 for a singleton non-yakuhai honor, 3 for a terminal,
; 2 for 2/8, otherwise 1. Special intents are handled first.
keep_value:
 ; Higher values favour discarding. Only singleton honors are adjusted.
 jsr kv_base
 tst iw_kok
 bne keep_value_02
 psha
 ldaa wk_kind
 cmpa #K_HONOR
 bcs keep_value_01
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 bne keep_value_01
 jsr kind_unseen_x
 ldaa 0,x
 cmpa #2
 bcs keep_value_00
 bne keep_value_01
 pula
 inca
 rts
keep_value_00:
 ; 2 + seen copies = 6 - unseen copies (5 or 6).
 ins
 nega
 adda #6
 rts
keep_value_01:
 pula
keep_value_02:
 rts
; Returns A = keep_value before the singleton honor adjustment.
kv_base:
	; Never shed a unique kokushi yaochu tile as an intent tie-break.
	tst	iw_kok
	beq	keep_chiitoi
 jsr kind_is_yaochu
	beq	keep_chiitoi
 jsr kind_counts_x
	ldaa	0,x
	cmpa	#2
	bcc	keep_chiitoi
	clra
	rts
keep_chiitoi:
 ; Both pair routes preserve pairs/triplets before isolated singletons.
 ldaa iw_chiitoi
 oraa iw_toi
 beq keep_check_flush
 jsr kind_counts_x
 ldaa 0,x
 cmpa #2
 bcs keep_check_flush
 clra
 rts
keep_check_flush:
 ; The target suit and all honors remain useful under honitsu.
 tst iw_flush
 beq keep_regular
 jsr kind_off_suit
 bne keep_regular
 clra
 rts
keep_regular:
 tst iw_chi
 beq keep_no_chanta
 jsr kind_is_yaochu
 bne kv_base_01
 ldaa wk_kind
 jsr kind_number
 suba #4
 cmpa #2
 bhi kv_base_00
 ldaa #3
 rts
keep_no_chanta:
	ldaa	wk_kind
	cmpa	#K_HONOR
	bcs	keep_number
	jsr	is_yakuhai
	beq	keep_honor
	bra	kv_base_00
keep_honor:
 ; Only an isolated non-yakuhai honor is weaker than an isolated terminal.
 tst iw_number_exempt
 bne keep_honor_old
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 bne keep_honor_old
 ldaa #4
 rts
keep_honor_old:
 ldaa #3
 rts
keep_number:
 tst iw_number_exempt
 bne keep_number_old
 jsr number_bias
 inca
 rts
keep_number_old:
 jsr kind_number
 cmpa #1
 beq keep_terminal
 cmpa #9
 bne kv_base_00
keep_terminal:
 ldaa #2
 rts
kv_base_00:
	ldaa	#1
	rts
kv_base_01:
	clra
	rts

; A = suited kind. Higher values prefer discarding: 1/9=2, 2/8=1.
number_bias:
 jsr kind_number
 cmpa #5
 bls number_bias_00
 nega
 adda #10
number_bias_00:
 cmpa #2
 bhi number_bias_01
 nega
 adda #3
 rts
number_bias_01:
 clra
 rts

; Small final-score bonus for discards that support an active hand intent.
; The maximum bonus is 2, so overlapping weak intents cannot overwhelm ukeire.
intent_bonus:
	clr	ibn_best

	; Tanyao: terminals/honors are unwanted; 2/8 are less connected simples.
	tst	iw_tanyao
	beq	ibn_chanta
 jsr kind_is_yaochu
	beq	intent_bonus_00
 ldaa wk_kind
 cmpa #K_HONOR
 bcc ibn_two
 tst iw_number_exempt
 bne ibn_two
 ; The ordinary terminal bonus already increased by one.
 ldaa #1
 staa ibn_best
 bra ibn_chanta
intent_bonus_00:
 ; 2/8 now receive their point in keep_value without requiring tanyao.
 tst iw_number_exempt
 beq ibn_chanta
	ldaa	wk_kind
	jsr kind_number
	cmpa	#2
	beq	intent_bonus_10
	cmpa	#8
	bne	ibn_chanta
intent_bonus_10:
	ldaa	#1
	staa	ibn_best

 ; Only 4-6 cannot participate in any chanta block. Keep 2/3/7/8
 ; available for 123/789, including completed sequences.
ibn_chanta:
 tst iw_chi
 beq ibn_kokushi
 ldaa wk_kind
 cmpa #K_HONOR
 bcc ibn_kokushi
 jsr kind_number
 suba #4
 cmpa #2
 bhi ibn_kokushi
 jmp ibn_two

	; Kokushi: favor discarding suited simples; keep unique yaochu tiles.
ibn_kokushi:
	tst	iw_kok
	beq	ibn_chiitoi
 jsr kind_is_yaochu
	bne	ibn_kokushi_00
	jmp ibn_two
ibn_kokushi_00:
 jsr kind_counts_x
	ldaa	0,x
	cmpa	#2
	bcs	ibn_chiitoi
	ldaa	#1
	staa	ibn_best

	; Chiitoi: singletons are expendable; pairs/triplets are retained.
ibn_chiitoi:
	ldaa iw_chiitoi
	oraa iw_toi
	beq	ibn_flush
 jsr kind_counts_x
	ldaa	0,x
	cmpa	#2
	bcs	ibn_chiitoi_00
	bra	ibn_flush
ibn_chiitoi_00:
 jsr kind_unseen_x
	ldaa	0,x
	beq	ibn_chiitoi_01
	cmpa	#2
	bcc	ibn_flush
	ldaa	#1
	staa	ibn_best
	bra	ibn_flush
ibn_chiitoi_01:
	jmp ibn_two

	; The candidate filter already restricts active flush discards to
	; off-suit tiles. If none exist at min_s, every candidate is compatible.
ibn_flush:
 tst flush_only
 beq ibn_flush_00
 jmp ibn_two
ibn_flush_00:
	ldaa	ibn_best
	rts
; Bonus 2.
ibn_two:
 ldaa #2
 rts

 ; Original 14-tile counts. dcc_cost and wk_bonus (toitoi) were
 ; computed by candidate ranking; cc_sanshoku is the 13-tile sanshoku value.
 ; A = complete final-score adjustment, cached with the shortlisted kind.
discard_bonus:
 ldaa #46
 suba dcc_cost
 adda wk_bonus
 adda cc_sanshoku
 staa wk_bonus
 jsr keep_value
 adda wk_bonus
 staa wk_bonus
 jsr intent_bonus
 adda wk_bonus
 rts

; A = kind. Return nonzero for terminals and honors.
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
 tst iw_chiitoi
 bne short_conn_02
 tst iw_toi
 bne short_conn_02
 tst iw_kok
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

; Restrict equal-shanten attack candidates to off-suit discards when possible.
; Defense and the minimum-shanten calculation are unchanged.
flush_filter:
 clr flush_only
 tst iw_flush
 beq flush_filter_23
 clr wk_kind
flush_filter_21:
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa min_s
 bne flush_filter_22
 jsr kind_off_suit
 beq flush_filter_22
 inc flush_only
 rts
flush_filter_22:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne flush_filter_21
flush_filter_23:
 rts
; Returns A = 1 if kind wk_kind may be a candidate under the flush filter.
; Returns with N and Z set from A.
ad_flush_cand:
 tst flush_only
 beq ad_flush_cand_00
 jmp kind_off_suit
ad_flush_cand_00:
 ldaa #1
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
 ldab 1,x
 cmpa #8
 bcc off_suit_shape_01
 addb 2,x
off_suit_shape_01:
 tstb
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
; A = kind, returns 1 for a numbered tile outside pai_max_suit, otherwise 0.
; Returns with N and Z set from A.
kind_off_suit:
 ldaa wk_kind
off_suit:
 cmpa #K_HONOR
 bcc off_suit_01
 jsr kind_suit
off_suit_00:
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

; Record the only geometric singleton when it is a dora.
; Count all isolated kinds, including those that cannot be discarded.
; sk = min_s is still required by choose_cands. Never an instant cut.
lone_dora:
 ldaa #$FF
 staa lone_dora_kind
 clr wk_kind
lone_dora_00:
 jsr kind_counts_x
 ldaa 0,x
 cmpa #1
 bne lone_dora_01
 jsr connection
 cmpa #1
 bne lone_dora_01
 ldaa lone_dora_kind
 cmpa #$FF
 bne lone_dora_02
 ldaa wk_kind
 staa lone_dora_kind
lone_dora_01:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne lone_dora_00
 ldaa lone_dora_kind
 cmpa #$FF
 beq lone_dora_03
 staa wk_kind
 jsr dora_cut_cost
 bne lone_dora_03
lone_dora_02:
 ldaa #$FF
 staa lone_dora_kind
lone_dora_03:
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
 ldaa min_s
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
 tst rel-counts,x
 bne acceptance_01
 tst ac_kok_active
 beq acceptance_04
 ldaa wk_draw
 jsr is_yaochu
 beq acceptance_04
acceptance_01:
 ldaa unseen-counts,x
 beq acceptance_04
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
acceptance_05:
 ldaa wk_accept
 rts

 ; Acceptance needs only to know whether the shanten value drops.
accept_eval:
 tst nfuro
 bne acceval_regular
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
 tst nfuro
 bne relevant_00
 jsr ad_spec_values
 ldaa #13
 suba spec_yao13
 suba spec_ypair13
 cmpa min_s
 bne relevant_00
 inc ac_kok_active
relevant_00:
 tst min_s
 beq rel_tenpai
relevant_01:
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
 ldaa 0,x
 adda dcc_count
 tab
 ldx #dcc_honor_table
 jsr addxb
 ldaa 0,x
 staa dcc_count
dora_cut_cost_01:
 ldaa wk_kind
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

; A=kind, return the number of matching dora indicators (0..5).
is_dora_kind:
 tab
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
	ldab	#K_EAST
	ldaa	round
	cmpa	#4
	bcs	is_yakuhai_00
	incb
is_yakuhai_00:
	clra
	cmpb	iyk_kind
	bne	is_yakuhai_01
	inca
is_yakuhai_01:
	ldab	ai_player
	subb	dealer
	andb	#3
	ldx	#wind_kinds
	jsr	addxb
	ldab	0,x

is_yakuhai_02:
	cmpb	iyk_kind
	bne	is_yakuhai_03
	inca
is_yakuhai_03:
	tsta
	rts
is_yakuhai_04:
	ldaa	#1
	rts

; Returns A = danger of discarding kind wk_kind against the riichi of
; player 0 (0 = safe ... 8).
danger_one:
	ldaa	wk_kind
	jsr	in_opp_river
	bne	danger_one_06
	ldaa	wk_kind
	cmpa	#K_HONOR
	bcs	danger_one_00
 jsr kind_unseen_x
	ldaa	0,x
	cmpa	#2
	bcs	danger_one_07
	beq	danger_one_08
	ldaa	#6
	rts
danger_one_00:
	tab
 jsr kind_number_b
 tab
	stab	dg_rank
	clr	dg_suji
	clr	dg_sides
	cmpb	#4
	bcs	danger_one_01
	inc	dg_sides
	ldaa	wk_kind
	suba	#3
	jsr	in_opp_river
	beq	danger_one_01
	inc	dg_suji
danger_one_01:
	ldab	dg_rank
	cmpb	#7
	bcc	danger_one_02
	inc	dg_sides
	ldaa	wk_kind
	adda	#3
	jsr	in_opp_river
	beq	danger_one_02
	inc	dg_suji
danger_one_02:
	ldaa	dg_suji
	cmpa	dg_sides
	bne	danger_one_05
	ldab	dg_rank
	cmpb	#1
	beq	danger_one_03
	cmpb	#9
	beq	danger_one_03
	cmpb	#2
	beq	danger_one_04
	cmpb	#8
	beq	danger_one_04
	ldaa	#5
	rts
danger_one_03:
	ldaa	#3
	rts
danger_one_04:
	ldaa	#4
	rts
danger_one_05:
	ldaa	#7
	rts
danger_one_06:
	clra
	rts
danger_one_07:
	ldaa	#1
	rts
danger_one_08:
	ldaa	#2
	rts

; A = kind. Z = 0 if player 0 discarded it.
in_opp_river:
	staa	ir_kind
	ldaa	danger_player
	jsr	player
	ldab	P_RLEN,x
	beq	in_opp_river_01
in_opp_river_00:
	ldaa	P_RIVER,x
	lsra
	cmpa	ir_kind
	beq	in_opp_river_02
	inx
	decb
	bne	in_opp_river_00
in_opp_river_01:
	clra
	rts
in_opp_river_02:
	ldaa	#1
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
 ; A flush call needs the off-suit tiles to be isolated.
 jsr off_suit_shape
 beq ai_call_20
 clr call_flush
ai_call_20:
	jsr	shanten
	staa	call_shanten_now
 jsr call_before_ukeire
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
	; Same-shanten pon may also continue chanta or tanyao.
	jsr	call_flush_ok
	oraa	iw_toi
	oraa	iw_chi
	oraa	iw_tanyao
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
	ldaa	rp_chi
	ldab	call_pat
	beq	call_bit
call_shift:
	lsra
	decb
	bne	call_shift
call_bit:
	bita	#1
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
	; Same-shanten chi needs an active route that call_chi_yaku kept.
	jsr	call_flush_ok
	oraa	iw_chi
	oraa	iw_tanyao
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
	jmp	is_simple
call_chi_yaku_03:
	ldaa	call_kind
	psha
	ldaa	#$FF
	staa	call_kind
	jsr	call_yaku_ok
	tab
	pula
	staa	call_kind
	tba
	rts

; A = kind. Returns A = 1 for 2-8 of a suit.
; Returns with N and Z set from A.
call_is_simple:
 ldaa call_kind
is_simple:
	cmpa	#K_HONOR
	bcc	is_simple_00
	tab
	jsr	kattr_x
	ldaa	0,x
	bita	#A_YAOCHU
	bne	is_simple_00
	ldaa	#1
	rts
is_simple_00:
	clra
	rts


	.bss
; unshown sits before counts and work right after it: ai_unseen reads counts
; as counts-unshown,x, and make_tot writes work as work-counts,x.
unshown: .ds KN ; tiles of each kind not yet shown on the table (turn.asm)
counts: .ds KN ; tiles of each kind in the closed hand (eval_load)
work: .ds 4 ; make_tot scratch: 37 contiguous bytes in total
pai_suit_work: .ds 3 ; scan-only suit scores; alias inside work, no added RAM
 .ds KN-7
furo_tiles: .ds KN ; tiles of each kind in the furo
sk:	.ds	KN ; shanten after discarding each kind ($7F = not allowed)
rel:	.ds	KN ; kinds that can lower the shanten (sum of nearby tiles)
unseen: .ds KN ; tiles of each kind the computer cannot see (ai_unseen)
ac_yes: .ds KN ; acc_mark result per kind: 0 no, 1 asked, 2 lowers the shanten
cc_insert_x:	.ds	2 ; cc_order slot to insert at
; cc_key is allocated in directpage.asm.
cc_slot:	.ds	1 ; cc_order slot being scored
cc_limit:	.ds	1 ; active shortlist size, 4..6 (zero defaults to 4)
; cc_order, cc_ranks, cc_bonus and cc_costs are read as offsets from a
; cc_order entry (cc_ranks-cc_order,x and so on).
cc_order:	.ds	6 ; up to 6 candidate kinds ($FF = none)
cc_ranks: .ds 6 ; their ranks
cc_bonus: .ds 6 ; their discard_bonus values
cc_costs: .ds 6 ; their dora costs
cc_cand_bonus: .ds 1 ; discard_bonus of the candidate being ranked
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
; set_intents clears intent_flags..intent_flags_end.
intent_flags:
iw_toi: .ds 1 ; toitoi intent
iw_kok: .ds 1 ; kokushi intent
iw_chi: .ds 1 ; chanta intent
iw_chiitoi: .ds 1 ; chiitoi intent
iw_tanyao: .ds 1 ; tanyao intent
iw_flush: .ds 1 ; flush intent
intent_flags_end:
pai_flush_score: ; alias: valid after scan_pai, until the next scan
pai_suit_ptr: .ds 2 ; scan-only pointer; first byte is pai_flush_score afterward
call_yakuhai: .ds 1 ; nonzero when call_kind is yakuhai
; pai_kind is allocated in directpage.asm.
; ib_kind is allocated in directpage.asm.
iw_bias:	.ds	1 ; intent_bias result
; ibn_best is allocated in directpage.asm.
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
ir_kind:	.ds	1 ; kind in_opp_river looks for
call_shanten_now:	.ds	1 ; shanten before the call
; call_kind is allocated in directpage.asm.
call_flush: .ds 1 ; cached flush call eligibility before pattern trials
flush_only:	.ds	1 ; output of flush_filter: 1 when only off-suit discards are candidates
	.code
; Returns A = 1 if another player is in riichi.
; Returns with N and Z set from A.
any_riichi:
	ldab	#3
any_riichi_00:
	cmpb	ai_player
	beq	any_riichi_01
	tba
	jsr	player
	tst	P_FLAG,x
	bmi	any_riichi_02
any_riichi_01:
	decb
	bpl	any_riichi_00
	clra
	rts
any_riichi_02:
	ldaa	#1
	rts

; Returns A = highest danger of discarding wk_kind over the riichi players.
danger:
	clr	danger_player
	clr	danger_max
danger_00:
	ldaa	danger_player
	cmpa	ai_player
	beq	danger_01
	ldaa	danger_player
	jsr	player
	tst	P_FLAG,x
	bpl	danger_01
	jsr	danger_one
	cmpa	danger_max
	bls	danger_01
	staa	danger_max
danger_01:
	inc	danger_player
	ldaa	danger_player
	cmpa	#4
	bne	danger_00
	ldaa	danger_max
	rts
	.bss
; ai_player is allocated in directpage.asm.
danger_max:	.ds	1 ; highest danger over the riichi players
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
 tst nfuro
 beq sanshoku_shape
 pshb
 ldaa ai_player
 jsr player
 ldab #P_FURO
 jsr addxb
 ldab nfuro
sanshoku_near_00:
 ldaa 0,x
 anda #3
 bne sanshoku_near_01
 ldaa 1,x
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

iw_number_exempt: .ds 1 ; nonzero when a special route keeps its own tile order

 .code
 ; Count special-shape features once for the original fourteen-tile hand.
spec_prep14:
 tst nfuro
 bne spec_prep14_00
 jsr sh_chiitoi
 ldaa chiitoi_pairs
 staa spec_pairs14
 ldaa chiitoi_kinds
 staa spec_kinds14
 jsr count_yaochu
 ldaa yao_kinds
 staa spec_yao14
 ldaa yao_pairs
 staa spec_ypairs14
spec_prep14_00:
 rts

; Special shapes (chiitoi, kokushi) of the 13 tiles after discarding wk_kind,
; from the 14-tile values of spec_prep14. counts is not changed.
; relevant and ac_special read the 13-tile values; shanten_lim reads A.
ad_spec_values:
 jsr kind_counts_x
 ldab 0,x
 bra spec_cut
; X = &counts[wk_kind] of the 14 tiles. Returns A = special-shape shanten
; after discarding one tile of wk_kind (8 with a furo). Keeps X.
spec_before:
 ldaa #8
 tst nfuro
 bne spec_shanten_01
 ldab 0,x
 decb
 bsr spec_cut
; Returns A = special-shape shanten of spec_*13 (no furo). Keeps X.
spec_shanten:
 ldaa #6
 suba spec_pairs13
 ldab #7
 subb spec_kinds13
 bls spec_shanten_00
 aba
spec_shanten_00:
 ldab #13
 subb spec_yao13
 subb spec_ypair13
 cba
 ble spec_shanten_01
 tba
spec_shanten_01:
 rts
; B = tiles of wk_kind left after the discard. Makes spec_*13. Keeps X.
spec_cut:
 ldaa spec_pairs14
 cmpb #1
 bne spec_cut_00
 ; A pair of the kind is broken.
 deca
spec_cut_00:
 staa spec_pairs13
 ldaa spec_kinds14
 tstb
 bne spec_cut_01
 ; The kind is gone.
 deca
spec_cut_01:
 staa spec_kinds13
 jsr kind_is_yaochu
 bne spec_cut_02
 ldaa spec_yao14
 staa spec_yao13
 ldaa spec_ypairs14
 bra spec_cut_04
spec_cut_02:
 ldaa spec_yao14
 tstb
 bne spec_cut_03
 deca
spec_cut_03:
 staa spec_yao13
 ldaa spec_ypairs14
 cmpb #1
 bne spec_cut_04
 deca
spec_cut_04:
 ; spec_ypair13 is 1 when a yaochu pair is left.
 tsta
 beq spec_cut_05
 ldaa #1
spec_cut_05:
 staa spec_ypair13
 rts
 .bss
spec_pairs14: .ds 1 ; output of spec_prep14: pairs of the 14 tiles
spec_kinds14: .ds 1 ; output of spec_prep14: kinds of the 14 tiles
spec_yao14: .ds 1 ; output of spec_prep14: yaochu kinds of the 14 tiles
spec_ypairs14: .ds 1 ; output of spec_prep14: yaochu pairs of the 14 tiles
spec_pairs13: .ds 1 ; output of spec_cut: pairs of the 13 tiles
spec_kinds13: .ds 1 ; output of spec_cut: kinds of the 13 tiles
spec_yao13: .ds 1 ; output of spec_cut: yaochu kinds of the 13 tiles
spec_ypair13: .ds 1 ; output of spec_cut: 1 when the 13 tiles have a yaochu pair
 .code
; Compute special shanten after this draw from cached thirteen-tile counts.
ac_special:
 ldx ac_ptr
 ldab 0,x
 ldaa #6
 suba spec_pairs13
 cmpb #2
 bne ac_special_00
 deca
ac_special_00:
 psha
 ldaa #7
 suba spec_kinds13
 cmpb #1
 bne ac_special_01
 deca
ac_special_01:
 tsta
 ble ac_special_02
 pulb
 aba
 bra ac_special_03
ac_special_02:
 pula
ac_special_03:
 cmpa min_s
 blt ac_special_08
 ldaa wk_draw
 jsr is_yaochu
 beq ac_special_07
 ldx ac_ptr
 ldab 0,x
 ldaa #13
 suba spec_yao13
 cmpb #1
 bne ac_special_04
 deca
ac_special_04:
 tst spec_ypair13
 bne ac_special_05
 cmpb #2
 bcs ac_special_06
ac_special_05:
 deca
ac_special_06:
 cmpa min_s
 blt ac_special_08
ac_special_07:
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
cc_isol_flag: .ds 1 ; 1 for an isolated or lone dora candidate
; lone_dora_kind is allocated in directpage.asm.
ad_best_ukeire: .ds 1 ; acceptance of the best candidate
tie_ukeire: .ds 1 ; output of tie_policy: 1 when equal scores compare acceptance
 .code

 .bss
ac_ptr: .ds 2 ; &counts[draw]
ac_lower: .ds 5 ; output of acceptance: 1 bit for each kind that lowers the shanten
 .code
