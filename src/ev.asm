; Ron-only value for attack decisions at min_s=0.
; Sum(unseen copies * ron points/100), then shape ukeire, then kind order.
; Inputs are the 14-tile counts/furo_tiles, sk and unseen from ai_discard.
; No physical hand, river, score, flag, or wall is changed.
ev_discard:
 jsr ev_prepare
 clr ev_has_best
 clr wk_kind
evdisc_candidate:
 jsr kind_counts_x
 tst sk-counts,x
 bne evdisc_next_cand
 jsr relevant
 ldx #dora_of_kind
 ldab wk_kind
 jsr addxb
 ldaa ev_base_dora
 suba 0,x
 staa ev_hand_dora
 ldaa ev_base_aka
 staa ev_hand_aka
 jsr ai_hand_pick
 bitb #1
 beq ev_discard_00
 dec ev_hand_aka
ev_discard_00:
 jsr ev_acceptance
 jsr kind_counts_x
 inc 0,x
ev_discard_01:
 tst ev_has_best
 beq ev_discard_02
 ldaa ev_sum
 cmpa ev_best
 bhi ev_discard_02
 bcs evdisc_next_cand
 ldaa ev_sum+1
 cmpa ev_best+1
 bhi ev_discard_02
 bcs evdisc_next_cand
 ldaa ev_sum+2
 cmpa ev_best+2
 bhi ev_discard_02
 bcs evdisc_next_cand
 ldaa wk_accept
 cmpa ev_best_waits
 bls evdisc_next_cand
ev_discard_02:
 ldx ev_sum
 stx ev_best
 ldaa ev_sum+2
 staa ev_best+2
 ldaa wk_accept
 staa ev_best_waits
 ldaa wk_kind
 staa ad_pick
 inc ev_has_best
evdisc_next_cand:
 inc wk_kind
 ldaa wk_kind
 cmpa #K_END
 bne evdisc_candidate
 rts

; The full setup is performed once on the original 14-tile hand. Per-discard
; dora and red counts are obtained by subtracting the actual physical discard.
ev_prepare:
 ldaa ai_player
 staa cw_p
 ldaa #1
 staa cw_ron
 clr win_tile
 jsr setup_place
 ldaa dora_n
 staa ev_base_dora
 ldaa aka_n
 staa ev_base_aka
 clr ura_n
 ; Only a legal new riichi is assumed: no ippatsu, future red, last-tile,
 ; rinshan, chankan or hidden ura. A first-discard declaration is double.
 clr sflags
 jsr ai_can_riichi
 beq ev_prepare_00
 ldaa #F_RIICHI
 staa sflags
 ldaa ai_player
 jsr player
 ldaa P_FLAG,x
 bita #P_FIRST
 beq ev_prepare_00
 ldaa #F_RIICHI+F_DOUBLE
 staa sflags
ev_prepare_00:
 ldx #ev_river
 ldab #KN
evprep_clear:
 clr 0,x
 inx
 decb
 bne evprep_clear
 ; Called-away own discards still count for furiten; ignore their flags.
 ldaa ai_player
 jsr player
 ldaa P_RLEN,x
 staa ev_river_n
 ldab #P_RIVER
 jsr addxb
ev_prepare_10:
 tst ev_river_n
 beq ev_prepare_20
 ldaa 0,x
 inx
 stx ev_ptr
 lsra
 tab
 ldx #ev_river
 jsr addxb
 inc 0,x
 ldx ev_ptr
 dec ev_river_n
 bra ev_prepare_10
ev_prepare_20:
 rts

; The usual candidate-specific relevance filter is reused. Unlike ordinary
; acceptance, a dead shape wait is still tested for permanent furiten.
; counts is the 13-tile hand after discarding wk_kind.
ev_acceptance:
 clr wk_accept
 clr wk_draw
 clr ev_furiten
 clr ev_sum
 clr ev_sum+1
 clr ev_sum+2
 ; A draw makes chiitoi or kokushi only from its tenpai; otherwise only the
 ; regular shape is tested.
 clr ev_special
 tst nfuro
 bne ev_acceptance_00
 jsr ad_spec_values
 jsr spec_shanten
 tsta
 bne ev_acceptance_00
 inc ev_special
ev_acceptance_00:
 ldx #rel
 ldab wk_draw
 jsr addxb
 tst 0,x
 beq ev_acceptance_11
 ldab wk_draw
 jsr unseen_x
 ldaa 0,x
 staa wk_unseen
 ldab wk_draw
 jsr counts_x
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #4
 bcc ev_acceptance_11
 inc 0,x
 tst ev_special
 beq evacc_sets
 jsr is_agari
 bra evacc_agari
evacc_sets:
 jsr agari_sets
evacc_agari:
 tsta
 beq ev_acceptance_10
 ldaa wk_accept
 adda wk_unseen
 staa wk_accept
 ldx #ev_river
 ldab wk_draw
 jsr addxb
 tst 0,x
 bne evacc_is_furiten
 ldaa wk_draw
 cmpa wk_kind
 bne evacc_live_wait
evacc_is_furiten:
 inc ev_furiten
evacc_live_wait:
 tst ev_furiten
 bne ev_acceptance_10
 tst wk_unseen
 beq ev_acceptance_10
 ; The inputs of score_hand that change with the discard and the wait.
 ldaa wk_draw
 staa win_kind
 ldaa ev_hand_aka
 staa aka_n
 ldx #dora_of_kind
 ldab wk_draw
 jsr addxb
 ldaa ev_hand_dora
 adda 0,x
 staa dora_n
 jsr score_hand
 ; At most four additions. A 24-bit sum covers 136*65535 units of 100.
 ldab wk_unseen
evacc_add_points:
 ldaa ev_sum+2
 adda best_pts+1
 staa ev_sum+2
 ldaa ev_sum+1
 adca best_pts
 staa ev_sum+1
 bcc evacc_no_carry
 inc ev_sum
evacc_no_carry:
 decb
 bne evacc_add_points
ev_acceptance_10:
 ldab wk_draw
 jsr counts_x
 dec 0,x
ev_acceptance_11:
 inc wk_draw
 ldaa wk_draw
 cmpa #K_END
 bne ev_acceptance_00
 tst ev_furiten
 beq ev_acceptance_12
 clr ev_sum
 clr ev_sum+1
 clr ev_sum+2
ev_acceptance_12:
 ldaa wk_accept
 rts

 .bss
ev_river: .ds KN
ev_sum: .ds 3 ; 24-bit sum of copies * points/100
ev_best: .ds 3 ; best ev_sum so far
ev_best_waits: .ds 1 ; its acceptance
ev_has_best: .ds 1 ; 1 once ev_best is set
ev_furiten: .ds 1 ; nonzero when a wait is in our river or is the discard
ev_special: .ds 1 ; 1 when the 13 tiles are chiitoi or kokushi tenpai
ev_base_dora: .ds 1 ; dora of the 14 tiles
ev_hand_dora: .ds 1 ; input of ev_acceptance: dora after the discard
ev_hand_aka: .ds 1 ; input of ev_acceptance: red fives after the discard
ev_base_aka: .ds 1 ; red fives of the 14 tiles
ev_ptr: .ds 2 ; next river tile
ev_river_n: .ds 1 ; river tiles left
