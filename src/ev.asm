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
 jsr ev_value
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

; Value of discarding wk_kind from the 14 tiles of counts, after ev_prepare:
; ev_sum and wk_accept of ev_acceptance. counts is restored.
ev_value:
 jsr kind_counts_x
 dec 0,x
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
 beq ev_value_00
 dec ev_hand_aka
ev_value_00:
 jsr ev_acceptance
 jsr kind_counts_x
 inc 0,x
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

; counts is the 13-tile hand after discarding wk_kind. A dead wait is
; still a wait for permanent furiten.
ev_acceptance:
 clr wk_accept
 clr ev_furiten
 clr ev_sum
 clr ev_sum+1
 clr ev_sum+2
 jsr find_waits
 clr wk_draw
 ldx #waits
ev_acceptance_00:
 stx ev_wait_ptr
 tst 0,x
 beq ev_acceptance_11
 ldab wk_draw
 jsr unseen_x
 ldaa 0,x
 staa wk_unseen
 adda wk_accept
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
 bne ev_acceptance_11
 tst wk_unseen
 beq ev_acceptance_11
 ; The inputs of score_hand that change with the discard and the wait.
 ldab wk_draw
 jsr counts_x
 inc 0,x
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
 ldab wk_draw
 jsr counts_x
 dec 0,x
ev_acceptance_11:
 ldx ev_wait_ptr
 inx
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

; 1-shanten discard by ron value, after best_accept chose ad_pick (min_s = 1,
; no riichi player). Value of a discard i = sum over draws e of unseen[e] times
; the best ev_sum of the tenpai discards d of the hand - i + e (i counts as in
; the river). Draws go from 4 unseen copies down to 1; before each draw, the
; search stops once 3 seconds have passed since ai_discard began, so every
; candidate has its value over the same draws. ad_pick changes only to a larger
; value. counts, unseen, kk1 and kk2 are restored; sk and min_s are made again.
; A record per candidate: kind, 5 bytes of tenpai draws (from ac_lower),
; total (3 bytes), best of the current draw (3 bytes).
E1_SIZE .equ 12
ev1_discard:
 ldaa kk1
 staa e1_kk1
 ldaa kk2
 staa e1_kk2
 jsr ad_rel_build
 ldx #e1_rec
 stx e1_end
 ; ad_pick first, then the other 1-shanten discards in kind order.
 ldaa #$FF
 staa e1_k
 ldaa ad_pick
 bra ev1_discard_02
ev1_discard_01:
 inc e1_k
 ldaa e1_k
 cmpa #K_END
 beq ev1_discard_10
 cmpa ad_pick
 beq ev1_discard_01
 staa wk_kind
 jsr kind_counts_x
 ldaa sk-counts,x
 cmpa #1
 bne ev1_discard_01
 ldaa e1_k
ev1_discard_02:
 staa e1_i
 staa wk_kind
 jsr candidate_acceptance
 ldx e1_end
 ldaa e1_i
 staa 0,x
 ldaa ac_lower
 staa 1,x
 ldaa ac_lower+1
 staa 2,x
 ldaa ac_lower+2
 staa 3,x
 ldaa ac_lower+3
 staa 4,x
 ldaa ac_lower+4
 staa 5,x
 clr 6,x
 clr 7,x
 clr 8,x
 ldab #E1_SIZE
 jsr addxb
 stx e1_end
 bra ev1_discard_01
ev1_discard_10:
 ldaa #$FF
 staa kk1
 staa kk2
 ldaa #4
 staa e1_u
ev1_discard_11:
 clr e1_e
ev1_discard_12:
 ldab e1_e
 jsr unseen_x
 ldaa 0,x
 cmpa e1_u
 bne ev1_discard_19
 ; Elapsed frames = seconds * 60 + frames - e1_frame; stop at 180.
ev1_discard_13:
 ldab $0C
 ldaa $0B
 cmpb $0C
 bne ev1_discard_13
 suba e1_sec
 cmpa #4
 bcc ev1_discard_30
 asla
 asla
 staa e1_tmp
 asla
 asla
 asla
 asla
 suba e1_tmp
 aba
 suba e1_frame
 cmpa #180
 bcc ev1_discard_30
 jsr ev1_draw
ev1_discard_19:
 inc e1_e
 ldaa e1_e
 cmpa #K_END
 bne ev1_discard_12
 dec e1_u
 bne ev1_discard_11
ev1_discard_30:
 ldaa e1_kk1
 staa kk1
 ldaa e1_kk2
 staa kk2
 ; The largest total; the first record (ad_pick) wins a tie.
 ldx #e1_rec
 bra ev1_discard_32
ev1_discard_31:
 ldaa 6,x
 cmpa e1_tot
 bhi ev1_discard_32
 bcs ev1_discard_33
 ldaa 7,x
 cmpa e1_tot+1
 bhi ev1_discard_32
 bcs ev1_discard_33
 ldaa 8,x
 cmpa e1_tot+2
 bls ev1_discard_33
ev1_discard_32:
 ldaa 0,x
 staa ad_pick
 ldaa 6,x
 staa e1_tot
 ldaa 7,x
 staa e1_tot+1
 ldaa 8,x
 staa e1_tot+2
ev1_discard_33:
 ldab #E1_SIZE
 jsr addxb
 cpx e1_end
 bne ev1_discard_31
 jmp discard_sk

; Draw e1_e (unseen[e1_e] = e1_u) for every record whose tenpai draws include
; it: best = the largest ev_sum of the tenpai discards d of the hand - i + e.
; A record later than i also gets the value of its own discard d, since the
; hand - d + e - i is the same; a record earlier than i already has it. Then
; total += e1_u * best for every record.
ev1_draw:
 ldaa e1_e
 tab
 lsrb
 lsrb
 lsrb
 stab e1_ebyte
 anda #7
 tab
 ldaa #1
ev1_draw_00:
 decb
 bmi ev1_draw_01
 asla
 bra ev1_draw_00
ev1_draw_01:
 staa e1_ebit
 ldx #e1_rec
ev1_draw_02:
 clr 9,x
 clr 10,x
 clr 11,x
 ldab #E1_SIZE
 jsr addxb
 cpx e1_end
 bne ev1_draw_02
 ldx #e1_rec
 stx e1_j
ev1_draw_10:
 ldx e1_j
 ldab e1_ebyte
 jsr addxb
 ldaa 1,x
 anda e1_ebit
 beq ev1_draw_40
 ; The hand - i + e; e is no longer unseen.
 ldx e1_j
 ldab 0,x
 stab e1_i
 jsr counts_x
 dec 0,x
 ldab e1_e
 jsr counts_x
 inc 0,x
 ldab e1_e
 jsr unseen_x
 dec 0,x
 jsr discard_sk
 tst min_s
 bne ev1_draw_30
 jsr ev_prepare
 ; The discard i is in the river and, if it is the red five, not in the hand.
 ldx #ev_river
 ldab e1_i
 jsr addxb
 inc 0,x
 ldaa e1_i
 staa wk_kind
 jsr ai_hand_pick
 bitb #1
 beq ev1_draw_11
 dec ev_base_aka
ev1_draw_11:
 clr e1_d
ev1_draw_20:
 ldab e1_d
 jsr counts_x
 tst sk-counts,x
 bne ev1_draw_29
 ; Skip d of an earlier record; otherwise find the record of d at or after i.
 ldx #e1_rec
ev1_draw_21:
 cpx e1_j
 beq ev1_draw_22
 ldaa 0,x
 cmpa e1_d
 beq ev1_draw_29
 ldab #E1_SIZE
 jsr addxb
 bra ev1_draw_21
ev1_draw_22:
 cpx e1_end
 beq ev1_draw_23
 ldaa 0,x
 cmpa e1_d
 beq ev1_draw_24
 ldab #E1_SIZE
 jsr addxb
 bra ev1_draw_22
ev1_draw_23:
 ldx #0
ev1_draw_24:
 stx e1_other
 ldaa e1_d
 staa wk_kind
 jsr ev_value
 ldx e1_j
 jsr ev1_best
 ldx e1_other
 beq ev1_draw_29
 jsr ev1_best
ev1_draw_29:
 inc e1_d
 ldaa e1_d
 cmpa #K_END
 bne ev1_draw_20
ev1_draw_30:
 ldab e1_i
 jsr counts_x
 inc 0,x
 ldab e1_e
 jsr counts_x
 dec 0,x
 ldab e1_e
 jsr unseen_x
 inc 0,x
ev1_draw_40:
 ldx e1_j
 ldab #E1_SIZE
 jsr addxb
 stx e1_j
 cpx e1_end
 bne ev1_draw_10
 ; total += e1_u * best, saturating at $FFFFFF.
 ldx #e1_rec
ev1_draw_50:
 ldab e1_u
ev1_draw_51:
 ldaa 8,x
 adda 11,x
 staa 8,x
 ldaa 7,x
 adca 10,x
 staa 7,x
 ldaa 6,x
 adca 9,x
 staa 6,x
 bcc ev1_draw_52
 ldaa #$FF
 staa 6,x
 staa 7,x
 staa 8,x
ev1_draw_52:
 decb
 bne ev1_draw_51
 ldab #E1_SIZE
 jsr addxb
 cpx e1_end
 bne ev1_draw_50
 rts

; X = record. best (bytes 9..11) = the larger of best and ev_sum.
ev1_best:
 ldaa ev_sum
 cmpa 9,x
 bhi ev1_best_00
 bcs ev1_best_01
 ldaa ev_sum+1
 cmpa 10,x
 bhi ev1_best_00
 bcs ev1_best_01
 ldaa ev_sum+2
 cmpa 11,x
 bls ev1_best_01
ev1_best_00:
 ldaa ev_sum
 staa 9,x
 ldaa ev_sum+1
 staa 10,x
 ldaa ev_sum+2
 staa 11,x
ev1_best_01:
 rts

 .bss
ev_river: .ds KN
ev_sum: .ds 3 ; 24-bit sum of copies * points/100
ev_best: .ds 3 ; best ev_sum so far
ev_best_waits: .ds 1 ; its acceptance
ev_has_best: .ds 1 ; 1 once ev_best is set
ev_furiten: .ds 1 ; nonzero when a wait is in our river or is the discard
ev_base_dora: .ds 1 ; dora of the 14 tiles
ev_hand_dora: .ds 1 ; input of ev_acceptance: dora after the discard
ev_hand_aka: .ds 1 ; input of ev_acceptance: red fives after the discard
ev_base_aka: .ds 1 ; red fives of the 14 tiles
ev_ptr: .ds 2 ; next river tile
ev_wait_ptr: .ds 2 ; &waits[wk_draw] (ev_acceptance)
ev_river_n: .ds 1 ; river tiles left
e1_rec: .ds 14*E1_SIZE ; records of ev1_discard (at most 14 kinds in a hand)
e1_end: .ds 2 ; end of the records
e1_j: .ds 2 ; record of the discard i being tried
e1_other: .ds 2 ; record of the discard d, 0 if d has none
e1_tot: .ds 3 ; largest total so far
e1_k: .ds 1 ; kind ev1_discard checks for a record
e1_i: .ds 1 ; kind of the discard i
e1_d: .ds 1 ; tenpai discard d
e1_e: .ds 1 ; draw e
e1_u: .ds 1 ; unseen copies of the draws in this pass (4 down to 1)
e1_ebyte: .ds 1 ; byte of e in the tenpai draws
e1_ebit: .ds 1 ; bit of e in that byte
e1_tmp: .ds 1 ; seconds * 4
e1_kk1: .ds 1 ; kk1 of the caller
e1_kk2: .ds 1 ; kk2 of the caller
e1_sec: .ds 1 ; $0B when ai_discard began
e1_frame: .ds 1 ; $0C when ai_discard began
