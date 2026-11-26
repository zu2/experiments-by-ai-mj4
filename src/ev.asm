; Ron-only value for attack decisions at min_s=0.
; Sum(unseen copies * ron points/100), then shape ukeire, then kind order.
; Inputs are the 14-tile counts/furo_tiles, sk and unseen from ai_discard.
; No physical hand, river, score, flag, or wall is changed.
	.code
ev_discard:
 jsr ev_prepare
 clr ev_has_best
 clr wk_kind
evdisc_candidate:
 jsr kind_counts_x
 tst sk-counts,x
 bne evdisc_next_cand
 bsr ev_value
 ; Live winning tiles: with yaku when open; a closed hand can riichi.
 ldaa ev_yacc
 ldab nfuro
 bne evdisc_live
 ldaa wk_accept
evdisc_live:
 bsr ev_lk_x
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

; Returns X = ev_sum of the 13-tile hand of ai_call without calling
; call_kind: Z clear when it has a winning tile with yaku.
ev_no_call:
 jsr ev_prepare
 ldaa call_kind
 staa wk_kind
 jsr kind_counts_x
 inc 0,x
 bsr ev_value
 jsr kind_counts_x
 dec 0,x
 ldx ev_sum
 rts

; Returns X = &ev_lk[wk_kind]. Keeps A.
ev_lk_x:
 ldab wk_kind
 ldx #ev_lk
 jmp addxb

; Like ev_value with the waits of fw_bits (discard_sk_waits) in place of
; find_waits: for a hand with no chiitoi or kokushi.
ev_value_waits:
 bsr ev_hand_prep
 bsr fw_expand
 jsr ev_tally
 bra ev_value_restore
; Value of discarding wk_kind from the 14 tiles of counts, after ev_prepare:
; ev_sum and wk_accept of ev_tally. counts is restored.
ev_value:
 bsr ev_hand_prep
 jsr find_waits
 jsr ev_tally
ev_value_restore:
 jsr kind_counts_x
 inc 0,x
 rts
; counts becomes the 13 tiles without wk_kind; sets ev_hand_dora, ev_hand_aka.
ev_hand_prep:
 jsr kind_counts_x
 dec 0,x
 ldab wk_kind
 jsr dora_x
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

; waits from fw_bits of wk_kind, without a kind of which 4 tiles are held
; (counts is the 13 tiles), as find_waits makes them.
fw_expand:
 ldab wk_kind
 tba
 asla
 asla
 aba
 tab
 ldx #fw_bits
 jsr addxb
 stx fw_src
 ldx #counts
fw_expand_00:
 stx fw_cx
 ldx fw_src
 ldaa 0,x
 inx
 stx fw_src
 staa fw_cur
 ldaa #8
 staa fw_left
 ldx fw_cx
fw_expand_01:
 clrb
 lsr fw_cur
 bcc fw_expand_02
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #4
 bcc fw_expand_02
 ldab #2
fw_expand_02:
 stab ac_yes-counts,x
 inx
 cpx #counts+KN
 beq fw_expand_03
 dec fw_left
 bne fw_expand_01
 bra fw_expand_00
fw_expand_03:
 jmp fw_result

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
 jsr player_bit_hi
 staa ev_own_bit
 rts

; counts is the 13-tile hand after discarding wk_kind. A dead wait is
; still a wait for permanent furiten.
ev_tally:
 clr wk_accept
 clr ev_yacc
 clr ev_furiten
 clr ev_sum
 clr ev_sum+1
 clr wk_draw
 ldx #waits
ev_tally_00:
 stx ev_wait_ptr
 tst 0,x
 beq ev_tally_11
 ldab wk_draw
 jsr unseen_x
 ldaa 0,x
 staa wk_unseen
 adda wk_accept
 staa wk_accept
 ldab wk_draw
 jsr river_bits_x
 ldaa 0,x
 anda ev_own_bit
 bne evacc_is_furiten
 ldaa wk_draw
 cmpa wk_kind
 bne evacc_live_wait
evacc_is_furiten:
 ldaa #1
 staa ev_furiten
evacc_live_wait:
 ldaa wk_unseen
 beq ev_tally_11
 ; The inputs of score_hand that change with the discard and the wait.
 ldab wk_draw
 jsr counts_x
 inc 0,x
 ldaa wk_draw
 staa win_kind
 ldaa ev_hand_aka
 staa aka_n
 ldab wk_draw
 jsr dora_x
 ldaa ev_hand_dora
 adda 0,x
 staa dora_n
 jsr score_hand
 ; At most four additions; ev_add_pts saturates at $FFFF.
 ldx #best_pts
 ldab wk_unseen
 bsr ev_add_pts
 ldab wk_draw
 jsr counts_x
 dec 0,x
ev_tally_11:
 ldx ev_wait_ptr
 inx
 inc wk_draw
 ldaa wk_draw
 cmpa #K_END
 bne ev_tally_00
 ; A furiten hand wins only by tsumo: a quarter of the ron value.
 tst ev_furiten
 beq ev_tally_12
 ldab #2
ev_tally_13:
 lsr ev_sum
 ror ev_sum+1
 decb
 bne ev_tally_13
ev_tally_12:
 ldaa wk_accept
 rts
; ev_sum += B * the points at X (B > 0), saturating at $FFFF; ev_yacc += B
; when the points are not 0.
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
; A = 1 (push_value against a riichi): compute a value even for ad_pick alone.
; A record per candidate: kind, 5 bytes of tenpai draws (from ac_lower),
; total (3 bytes), best of the current draw (3 bytes).
E1_SIZE .equ 10
ev1_discard:
 staa e1_all
 ldaa kk1
 staa e1_kk1
 ldaa kk2
 staa e1_kk2
 ldx #e1_rec
 stx e1_end
 ; Record ad_pick first so it wins a tie. Score the remaining candidates
 ; with the same tenpai evaluation, including dora, red fives and yaku.
 ldaa #2
 staa e1_pass
ev1_discard_00:
 clr e1_k
ev1_discard_01:
 ldab e1_k
 ldx #cc_order
 jsr addxb
 ldaa 0,x
 cmpa #$FF
 beq ev1_discard_09
 cmpa ad_pick
 bne ev1_discard_02
 ldab e1_pass
 cmpb #2
 beq ev1_discard_05
 bra ev1_discard_08
ev1_discard_02:
 ldab e1_pass
 cmpb #2
 beq ev1_discard_08
ev1_discard_05:
 staa e1_i
 ; best_accept kept ac_lower of each cc_order slot in cc_lower.
 ldab e1_k
 aslb
 aslb
 addb e1_k
 ldx #cc_lower
 jsr addxb
ev1_discard_06:
 stx e1_src
 ldx e1_end
 ldaa e1_i
 staa 0,x
 inx
 stx e1_dst
 ldab #5
ev1_discard_07:
 ldx e1_src
 ldaa 0,x
 inx
 stx e1_src
 ldx e1_dst
 staa 0,x
 inx
 stx e1_dst
 decb
 bne ev1_discard_07
 ldx e1_end
 clr 6,x
 clr 7,x
 ldab #E1_SIZE
 jsr addxb
 stx e1_end
ev1_discard_08:
 inc e1_k
 ldaa e1_k
 cmpa #CC_LIMIT
 bne ev1_discard_01
ev1_discard_09:
 dec e1_pass
 bne ev1_discard_00
 ; With ad_pick alone there is nothing to compare.
 tst e1_all
 bne ev1_discard_10
 ldx e1_end
 cpx #e1_rec+E1_SIZE
 bne ev1_discard_10
 rts
ev1_discard_10:
 ; A hand - i + e - d + w has at most one more pair and one more yaochu kind
 ; than the hand: with 4 pairs and 10 yaochu kinds at most, no chiitoi (7
 ; pairs) or kokushi (13 kinds) can win or be tenpai.
 ldaa spec_off
 staa e1_spec
 clr e1_reg
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
 inc e1_reg
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
 bsr ev1_draw
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
 jsr kind_bit
 stab e1_ebyte
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
 jeq ev1_draw_40
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
 tst e1_reg
 beq ev1_draw_03
 jsr discard_sk_waits
 bra ev1_draw_04
ev1_draw_03:
 jsr discard_sk_lim
ev1_draw_04:
 ldab min_s
 jne ev1_draw_30
 ldab e1_e
 jsr dora_x
 ldaa e1_dora
 adda 0,x
 ldab e1_i
 jsr dora_x
 suba 0,x
 staa ev_base_dora
 ldaa e1_aka
 staa ev_base_aka
 ; The discard i is in the river and, if it is the red five, not in the hand.
 ldab e1_i
 jsr river_bits_x
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
 tst e1_reg
 beq ev1_draw_25
 jsr ev_value_waits
 bra ev1_draw_26
ev1_draw_25:
 jsr ev_value
ev1_draw_26:
 ldx e1_j
 bsr ev1_best
 ldx e1_other
 beq ev1_draw_29
 bsr ev1_best
ev1_draw_29:
 inc e1_d
 ldaa e1_d
 cmpa #K_END
 bne ev1_draw_20
 ldab e1_i
 jsr river_bits_x
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
 jne ev1_draw_10
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

 .bss
e1_spec: .ds 1 ; spec_off before ev1_discard
e1_reg: .ds 1 ; 1 when ev1_discard set SPEC_NONE: ev1_draw takes waits from batch_leaf
fw_src: .ds 2 ; fw_expand: next byte of fw_bits
fw_cx: .ds 2 ; fw_expand: &counts[kind]
fw_cur: .ds 1 ; fw_expand: bits left of the byte
fw_left: .ds 1 ; fw_expand: bits left in fw_cur
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
ev_furiten: .ds 1 ; 1 when a wait is in our river or is the discard, else 0
ev_base_dora: .ds 1 ; dora of the 14 tiles
ev_hand_dora: .ds 1 ; input of ev_tally: dora after the discard
ev_hand_aka: .ds 1 ; input of ev_tally: red fives after the discard
ev_base_aka: .ds 1 ; red fives of the 14 tiles
ev_wait_ptr: .ds 2 ; &waits[wk_draw] (ev_tally)
e1_rec: .ds 14*E1_SIZE ; records of ev1_discard (at most 14 kinds in a hand)
e1_end: .ds 2 ; end of the records
e1_j: .ds 2 ; record of the discard i being tried
e1_other: .ds 2 ; record of the discard d, 0 if d has none
e1_tot: .ds 2 ; largest total so far
e1_k: .ds 1 ; cc_order slot ev1_discard checks for a record
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
e1_all: .ds 1 ; A of ev1_discard: 1 scores even a single candidate
e1_src: .ds 2 ; ev1_discard: source of the tenpai draws
; e1_dst is allocated in directpage.asm.
