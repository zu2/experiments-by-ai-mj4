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
 ; Live winning tiles: with yaku when open; a closed hand can riichi.
 ldaa ev_yacc
 ldab nfuro
 bne evdisc_live
 ldaa wk_accept
evdisc_live:
 jsr ev_lk_x
 staa 0,x
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
 ldaa wk_accept
 cmpa ev_best_waits
 bls evdisc_next_cand
ev_discard_02:
 ldx ev_sum
 stx ev_best
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
; Returns Z clear when the 13-tile hand of ai_call has
; a winning tile with yaku (ev_sum of not calling call_kind).
ev_no_call:
 jsr ev_prepare
 ldaa call_kind
 staa wk_kind
 jsr kind_counts_x
 inc 0,x
 jsr ev_value
 jsr kind_counts_x
 dec 0,x
 ldx ev_sum
 rts

; Returns X = &ev_lk[wk_kind]. Keeps A.
ev_lk_x:
 ldab wk_kind
 ldx #ev_lk
 jmp addxb

ev_value:
 jsr ev_hand_prep
 jsr ev_acceptance
ev_value_restore:
 jsr kind_counts_x
 inc 0,x
 rts
; counts becomes the 13 tiles without wk_kind; sets ev_hand_dora, ev_hand_aka.
ev_hand_prep:
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
 ; Furiten: the own discards are in river_bits (bit ai_player + 4).
 ldab ai_player
 jsr player_bit
 asla
 asla
 asla
 asla
 staa ev_own_bit
 rts

; counts is the 13-tile hand after discarding wk_kind. A dead wait is
; still a wait for permanent furiten.
ev_acceptance:
 ldaa #$FF
 staa em_e+3
 staa em_e+6
 jsr find_waits
; The same from waits. A wait whose points em_e holds is not scored again.
ev_tally:
 clr em_wn
 clr wk_accept
 clr ev_yacc
 clr ev_furiten
 clr ev_sum
 clr ev_sum+1
 clr wk_draw
 ldx #waits
ev_acceptance_00:
 stx ev_wait_ptr
 tst 0,x
 beq ev_acceptance_11
 jsr em_wait
 ldab wk_draw
 jsr unseen_x
 ldaa 0,x
 staa wk_unseen
 adda wk_accept
 staa wk_accept
 ldx #river_bits
 ldab wk_draw
 jsr addxb
 ldaa 0,x
 anda ev_own_bit
 bne evacc_is_furiten
 ldaa wk_draw
 cmpa wk_kind
 bne evacc_live_wait
evacc_is_furiten:
 inc ev_furiten
evacc_live_wait:
 ldaa wk_unseen
 beq ev_acceptance_11
 ldx em_wx
 beq evacc_score
 ldaa 0,x
 bita #$40
 bne evacc_score
 inx
 ldab wk_unseen
 jsr ev_add_pts
 bra ev_acceptance_11
evacc_score:
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
 ldx em_wx
 beq evacc_no_slot
 ldaa best_pts
 staa 1,x
 ldaa best_pts+1
 staa 2,x
 ldaa 0,x
 anda #$3F
 staa 0,x
evacc_no_slot:
 ; At most four additions; ev_add_pts saturates at $FFFF.
 ldx #best_pts
 ldab wk_unseen
 jsr ev_add_pts
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
 ; A furiten hand wins only by tsumo: a quarter of the ron value.
 tst ev_furiten
 beq ev_acceptance_12
 ldab #2
ev_acceptance_13:
 lsr ev_sum
 ror ev_sum+1
 decb
 bne ev_acceptance_13
ev_acceptance_12:
 ldaa wk_accept
 rts
; ev_sum += B * the points at X (B > 0), saturating at $FFFF.
ev_add_pts:
 ldaa 0,x
 oraa 1,x
 beq ev_add_pts_01
 tba
 adda ev_yacc
 staa ev_yacc
ev_add_pts_02:
 ldaa ev_sum+1
 adda 1,x
 staa ev_sum+1
 ldaa ev_sum
 adca 0,x
 bcc ev_add_pts_00
 ldaa #$FF
 staa ev_sum+1
ev_add_pts_00:
 staa ev_sum
 decb
 bne ev_add_pts_02
ev_add_pts_01:
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
E1_SIZE .equ 10
ev1_discard:
 ldaa kk1
 staa e1_kk1
 ldaa kk2
 staa e1_kk2
 jsr em_begin
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
 ; best_accept, just before, kept ac_lower of the kinds in cc_order.
 ldx #cc_order
 clrb
ev1_discard_03:
 ldaa 0,x
 cmpa e1_i
 beq ev1_discard_05
 cmpa #$FF
 beq ev1_discard_04
 inx
 incb
 cmpb cc_limit
 bne ev1_discard_03
ev1_discard_04:
 jsr candidate_acceptance
 ldx #ac_lower
 bra ev1_discard_06
ev1_discard_05:
 tba
 asla
 asla
 aba
 tab
 ldx #cc_lower
 jsr addxb
ev1_discard_06:
 stx em_ptr
 ldx e1_end
 ldaa e1_i
 staa 0,x
 inx
 stx em_q
 ldx em_ptr
 ldab #5
 jsr em_move
 ldx e1_end
 clr 6,x
 clr 7,x
 ldab #E1_SIZE
 jsr addxb
 stx e1_end
 bra ev1_discard_01
ev1_discard_10:
 ; A hand - i + e - d + w has at most one more pair and one more yaochu kind
 ; than the hand: with 4 pairs and 10 yaochu kinds at most, no chiitoi (7
 ; pairs) or kokushi (13 kinds) can win or be tenpai.
 ldaa spec_off
 staa e1_spec
 ldaa nfuro
 bne ev1_discard_15
 jsr spec_prep14
 ldaa spec14+SP_PAIRS
 cmpa #5
 bcc ev1_discard_16
 ldaa spec14+SP_YAO
 cmpa #11
 bcc ev1_discard_16
ev1_discard_15:
 ldaa #SPEC_NONE
 staa spec_off
ev1_discard_16:
 ; ev_prepare depends on the hand only by ev_base_dora: ev1_draw makes it
 ; for each hand - i + e from the value of the hand.
 jsr ev_prepare
 ldaa ev_base_dora
 staa e1_dora
 ldaa ev_base_aka
 staa e1_aka
 ldaa #$FF
 staa kk1
 staa kk2
 ; Pass 2 draws the kinds that fit the intent (ev1_fits) and pass 1 the
 ; others, so a cutoff leaves out the draws that break the yaku.
 ldaa #2
 staa e1_pass
ev1_discard_14:
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
 ldaa e1_e
 jsr ev1_fits
 inca
 cmpa e1_pass
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
 dec e1_pass
 bne ev1_discard_14
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
 bls ev1_discard_33
ev1_discard_32:
 ldaa 0,x
 staa ad_pick
 ldaa 6,x
 staa e1_tot
 ldaa 7,x
 staa e1_tot+1
ev1_discard_33:
 ldab #E1_SIZE
 jsr addxb
 cpx e1_end
 bne ev1_discard_31
 jsr em_end
 ldaa e1_spec
 staa spec_off
 jmp discard_sk

; A = kind. Returns A = 1 if a draw of the kind fits the intent: the flush
; suit or an honor with iw_flush, 2-8 with iw_tanyao, any kind otherwise.
; Returns with N and Z set from A.
ev1_fits:
 tst iw_flush
 beq ev1_fits_00
 jsr off_suit
 eora #1
 rts
ev1_fits_00:
 tst iw_tanyao
 beq ev1_fits_01
 jmp is_simple
ev1_fits_01:
 ldaa #1
 rts

; Draw e1_e (unseen[e1_e] = e1_u) for every record whose tenpai draws include
; it: best = the largest ev_sum of the tenpai discards d of the hand - i + e.
; A record later than i also gets the value of its own discard d, since the
; hand - d + e - i is the same; a record earlier than i already has it. Then
; total += e1_u * best for every record.
ev1_draw:
 jsr demo_poll
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
 clr 8,x
 clr 9,x
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
 clr wk_limit
 jsr discard_sk_lim
 ldab min_s
 bne ev1_draw_30
 ldx #dora_of_kind
 ldab e1_e
 jsr addxb
 ldaa e1_dora
 adda 0,x
 ldx #dora_of_kind
 ldab e1_i
 jsr addxb
 suba 0,x
 staa ev_base_dora
 ldaa e1_aka
 staa ev_base_aka
 ; The discard i is in the river and, if it is the red five, not in the hand.
 ldx #river_bits
 ldab e1_i
 jsr addxb
 ldaa 0,x
 staa e1_river
 oraa ev_own_bit
 staa 0,x
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
 jsr em_value
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
 ldx #river_bits
 ldab e1_i
 jsr addxb
 ldaa e1_river
 staa 0,x
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
 ; total += e1_u * best, saturating at $FFFF.
 ldx #e1_rec
ev1_draw_50:
 ldab e1_u
ev1_draw_51:
 ldaa 7,x
 adda 9,x
 staa 7,x
 ldaa 6,x
 adca 8,x
 bcc ev1_draw_52
 ldaa #$FF
 staa 7,x
ev1_draw_52:
 staa 6,x
 decb
 bne ev1_draw_51
 ldab #E1_SIZE
 jsr addxb
 cpx e1_end
 bne ev1_draw_50
 rts

; X = record. best (bytes 8..9) = the larger of best and ev_sum.
ev1_best:
 ldaa ev_sum
 cmpa 8,x
 bhi ev1_best_00
 bcs ev1_best_01
 ldaa ev_sum+1
 cmpa 9,x
 bls ev1_best_01
ev1_best_00:
 ldaa ev_sum
 staa 8,x
 ldaa ev_sum+1
 staa 9,x
ev1_best_01:
 rts

; Results of ev_acceptance kept from the last ev1_discard of each CPU player
; (1-3). With H the hand and x0 = ad_pick when it began, B = H - x0 and a
; record (r, e) is the hand T = B - r + e of discards i, d with x0 one of
; them and r the other. Now with H' = B + y, the hand of i', d', e' is that T
; when y is i' and r is d', or y is d' and r is i', and e is e'.
; A table: em_fsig, dora_cnt, sflags, kyotaku, B (kinds, then $FF; 14 bytes), then
; EM_N records of r, e, ev_hand_aka and two (wait, points); wait bit 7 =
; none, bit 6 = points not made.
EM_N .equ 8
EM_SIZE .equ 9
EM_HEAD .equ 18
EM_STRIDE .equ EM_HEAD+EM_N*EM_SIZE

; Sets em_x0, and em_use = 1 with em_y and em_n when the table of ai_player
; is of this hand.
em_begin:
 clr em_use
 clr em_new_n
 ldaa ad_pick
 staa em_x0
 ldab ai_player
 beq em_begin_09
 ldx #em_count
 jsr addxb
 ldaa 0,x
 beq em_begin_09
 staa em_n
 jsr em_fsig
 psha
 jsr em_table_x
 pula
 cmpa 0,x
 bne em_begin_09
 ldaa dora_cnt
 cmpa 1,x
 bne em_begin_09
 ldaa kyotaku
 cmpa 3,x
 bne em_begin_09
 ; y = H' - B: B and the kinds of counts in order agree but for one tile.
 inx
 inx
 inx
 inx
 stx em_q
 clr em_t
 clr em_k
em_begin_00:
 ldab em_k
 jsr counts_x
 ldaa 0,x
 beq em_begin_03
em_begin_01:
 ldx em_q
 ldab 0,x
 cmpb em_k
 bne em_begin_02
 inx
 stx em_q
 bra em_begin_04
em_begin_02:
 bcs em_begin_09
 ldab em_k
 stab em_y
 inc em_t
em_begin_04:
 deca
 bne em_begin_01
em_begin_03:
 inc em_k
 ldab em_k
 cmpb #K_END
 bne em_begin_00
 ldx em_q
 ldaa 0,x
 inca
 bne em_begin_09
 ldaa em_t
 cmpa #1
 bne em_begin_09
 staa em_use
em_begin_09:
 rts

; X = the table of ai_player (1-3).
em_table_x:
 ldx #em_table
 ldaa ai_player
em_table_x_00:
 deca
 beq em_table_x_01
 ldab #EM_STRIDE
 jsr addxb
 bra em_table_x_00
em_table_x_01:
 rts

; A = furo + kans of ai_player: in a hand, every call and kan makes it larger.
em_fsig:
 jsr ai_furo_x
 ldaa minkan_n-minshun_n,x
 adda ankan_n-minshun_n,x
 adda nfuro
 rts

; Like ev_value for ev1_draw (wk_kind = d, e1_i = i, e1_e = e): ev_sum.
em_value:
 jsr ev_hand_prep
 jsr em_lookup
 beq em_value_01
 ; waits = the waits of the record.
 ldx #waits
 ldab #KN
em_value_00:
 clr 0,x
 inx
 decb
 bne em_value_00
 ldaa em_e+3
 jsr em_set_wait
 ldaa em_e+6
 jsr em_set_wait
 jsr ev_tally
 bra em_value_02
em_value_01:
 jsr ev_acceptance
em_value_02:
 jsr em_keep
 jmp ev_value_restore
; A = wait byte of em_e: sets waits of its kind.
em_set_wait:
 tsta
 bmi em_set_wait_00
 anda #$3F
 tab
 ldx #waits
 jsr addxb
 inc 0,x
em_set_wait_00:
 rts
; A = y or x0. When it is e1_i or wk_kind: B = the other and A = 1, else A = 0.
; Returns with N and Z set from A.
em_other:
 ldab wk_kind
 cmpa e1_i
 beq em_other_00
 ldab e1_i
 cmpa wk_kind
 beq em_other_00
 clra
 rts
em_other_00:
 ldaa #1
 rts

; Returns A = 1 with em_e+3 to em_e+8 copied from a record of the hand, 0 if
; none.
; Returns with N and Z set from A.
em_lookup:
 tst em_use
 beq em_lookup_09
 ldaa em_y
 jsr em_other
 beq em_lookup_09
 stab em_r
 jsr em_table_x
 ldaa sflags
 cmpa 2,x
 bne em_lookup_09
 ldab #EM_HEAD
 jsr addxb
 ldaa em_n
 staa em_k
em_lookup_01:
 ldaa 0,x
 cmpa em_r
 bne em_lookup_02
 ldaa 1,x
 cmpa e1_e
 bne em_lookup_02
 ldaa 2,x
 cmpa ev_hand_aka
 bne em_lookup_02
 inx
 inx
 inx
 ldab #6
 jsr em_move_e3
 ldaa #1
 rts
em_lookup_02:
 ldab #EM_SIZE
 jsr addxb
 dec em_k
 bne em_lookup_01
em_lookup_09:
 clra
 rts

; In ev_tally, at the wait wk_draw: em_wx = its place in em_e if it is one of
; the first two, else 0; the place keeps its points if it is of wk_draw, else
; it becomes wk_draw without points. em_wn counts the waits.
em_wait:
 ldx #0
 stx em_wx
 ldab em_wn
 inc em_wn
 cmpb #2
 bcc em_wait_09
 ldx #em_e+3
 tstb
 beq em_wait_00
 inx
 inx
 inx
em_wait_00:
 stx em_wx
 ldaa 0,x
 eora wk_draw
 anda #$BF
 beq em_wait_09
 ldaa wk_draw
 oraa #$40
 staa 0,x
em_wait_09:
 rts

; After em_lookup or ev_acceptance: em_e becomes a record of em_new when x0
; is i or d, em_new has room and there are at most two waits.
em_keep:
 tst ai_player
 beq em_keep_09
 ldaa em_wn
 cmpa #3
 bcc em_keep_09
 ldaa em_new_n
 cmpa #EM_N
 bcc em_keep_09
 ldaa em_x0
 jsr em_other
 beq em_keep_09
 stab em_e
 ldaa e1_e
 staa em_e+1
 ldaa ev_hand_aka
 staa em_e+2
 ldx #em_new
 ldaa em_new_n
 inc em_new_n
em_keep_01:
 tsta
 beq em_keep_02
 ldab #EM_SIZE
 jsr addxb
 deca
 bra em_keep_01
em_keep_02:
 stx em_q
 ldx #em_e
 ldab #EM_SIZE
 jmp em_move
em_keep_09:
 rts

; Copies B bytes from X to em_q (em_move_e3: to em_e+3).
em_move_e3:
 stx em_ptr
 ldx #em_e+3
 stx em_q
 ldx em_ptr
em_move:
 ldaa 0,x
 inx
 stx em_ptr
 ldx em_q
 staa 0,x
 inx
 stx em_q
 ldx em_ptr
 decb
 bne em_move
 rts

; End of ev1_discard: keeps em_new for the next call when ad_pick is x0.
em_end:
 ldab ai_player
 beq em_end_09
 ldx #em_count
 jsr addxb
 ldaa ad_pick
 cmpa em_x0
 beq em_end_00
 clr 0,x
 rts
em_end_00:
 ldaa em_new_n
 staa 0,x
 beq em_end_09
 jsr em_fsig
 psha
 jsr em_table_x
 pula
 staa 0,x
 ldaa dora_cnt
 staa 1,x
 ldaa sflags
 staa 2,x
 ldaa kyotaku
 staa 3,x
 ; B: the kinds of counts without one x0, then $FF.
 inx
 inx
 inx
 inx
 stx em_q
 clr em_k
em_end_01:
 ldab em_k
 jsr counts_x
 ldaa 0,x
 ldab em_k
 cmpb em_x0
 bne em_end_02
 deca
em_end_02:
 tsta
 beq em_end_04
 ldx em_q
em_end_03:
 stab 0,x
 inx
 deca
 bne em_end_03
 stx em_q
em_end_04:
 inc em_k
 ldaa em_k
 cmpa #K_END
 bne em_end_01
 ldx em_q
 ldaa #$FF
 staa 0,x
 ; The records.
 jsr em_table_x
 ldab #EM_HEAD
 jsr addxb
 stx em_q
 clra
 ldab em_new_n
em_end_05:
 adda #EM_SIZE
 decb
 bne em_end_05
 tab
 ldx #em_new
 jmp em_move
em_end_09:
 rts

 .bss
e1_spec: .ds 1 ; spec_off before ev1_discard
e1_dora: .ds 1 ; ev_base_dora of the hand (14 tiles)
e1_aka: .ds 1 ; ev_base_aka of the hand
ev_own_bit: .ds 1 ; ev_prepare: bit of the computer's own discards in river_bits
e1_river: .ds 1 ; river_bits of e1_i before ev1_draw sets the own bit
ev_sum: .ds 2 ; sum of copies * points/100 (saturating)
ev_best: .ds 2 ; best ev_sum so far
ev_best_waits: .ds 1 ; its acceptance
ev_lk: .ds KN ; live winning tiles of each tenpai discard (ev_discard)
ev_yacc: .ds 1 ; live winning tiles with yaku of ev_value
ev_has_best: .ds 1 ; 1 once ev_best is set
ev_furiten: .ds 1 ; nonzero when a wait is in our river or is the discard
ev_base_dora: .ds 1 ; dora of the 14 tiles
ev_hand_dora: .ds 1 ; input of ev_acceptance: dora after the discard
ev_hand_aka: .ds 1 ; input of ev_acceptance: red fives after the discard
ev_base_aka: .ds 1 ; red fives of the 14 tiles
ev_wait_ptr: .ds 2 ; &waits[wk_draw] (ev_acceptance)
e1_rec: .ds 14*E1_SIZE ; records of ev1_discard (at most 14 kinds in a hand)
e1_end: .ds 2 ; end of the records
e1_j: .ds 2 ; record of the discard i being tried
e1_other: .ds 2 ; record of the discard d, 0 if d has none
e1_tot: .ds 2 ; largest total so far
e1_k: .ds 1 ; kind ev1_discard checks for a record
; e1_i is allocated in directpage.asm.
e1_d: .ds 1 ; tenpai discard d
e1_e: .ds 1 ; draw e
e1_u: .ds 1 ; unseen copies of the draws in this pass (4 down to 1)
e1_pass: .ds 1 ; 2: draws that fit the intent, 1: the others
e1_ebyte: .ds 1 ; byte of e in the tenpai draws
e1_ebit: .ds 1 ; bit of e in that byte
e1_tmp: .ds 1 ; seconds * 4
e1_kk1: .ds 1 ; kk1 of the caller
e1_kk2: .ds 1 ; kk2 of the caller
e1_sec: .ds 1 ; $0B when ai_discard began
e1_frame: .ds 1 ; $0C when ai_discard began
em_table: .ds 3*EM_STRIDE ; tables of players 1-3
em_new: .ds EM_N*EM_SIZE ; records of this ev1_discard
em_new_n: .ds 1 ; records in em_new
em_e: .ds EM_SIZE ; record being made (ev_acceptance writes the waits)
em_wn: .ds 1 ; waits ev_acceptance found
em_wx: .ds 2 ; place of the current wait in em_e, 0 if none
em_use: .ds 1 ; 1 when the table of ai_player is of this hand
em_n: .ds 1 ; records in that table
em_x0: .ds 1 ; ad_pick when ev1_discard began
em_y: .ds 1 ; H' - B
em_r: .ds 1 ; r em_lookup looks for
em_t: .ds 1 ; tiles of H' not in B
em_k: .ds 1 ; kind or record count
em_ptr: .ds 2 ; source of em_move
; em_q is allocated in directpage.asm.
