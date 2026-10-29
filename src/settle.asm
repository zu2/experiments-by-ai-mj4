; Point values are in units of 100. Signed 16-bit scores.
; basic points remain ordinary points until rounded per payer.

; Valid basic points are multiples of 20 (including 25-fu hands).
; ceil(basic*factor/100) = ceil((basic/20)*factor/5) = (4 + (basic/20)*factor)/5.
; Divide before multiplying so multiple yakuman cannot overflow 16 bits.
payer_amount:
 ldx fi_basic
 stx wk_num
 ldaa #20
 jsr div8_a
 ldx wk_num
 stx pay_basic
 clr wk_num
 ldaa #4
 staa wk_num+1
 ldab pay_factor
payer_amount_00:
 ldaa wk_num+1
 adda pay_basic+1
 staa wk_num+1
 ldaa wk_num
 adca pay_basic
 staa wk_num
 decb
 bne payer_amount_00
 ldaa #5
 jsr div8_a
 ldx wk_num
 stx pay_amt
 rts

; Correct tsumo total: round each payer separately, then add honba/pool.
score_total:
 tst tsumo_flag
 bne score_total_01
 ldaa #4
 tst dealer_flag
 beq score_total_00
 ldaa #6
score_total_00:
 staa pay_factor
 jsr payer_amount
 ldx pay_amt
 stx wk_num
 rts
score_total_01:
 ldaa #2
 staa pay_factor
 jsr payer_amount
 ldx pay_amt
 stx total_tmp
 tst dealer_flag
 bne score_total_03
 ldaa #1
 staa pay_factor
 jsr payer_amount
score_total_03:
 ldab pay_amt+1
 ldaa pay_amt
 aslb
 rola
 addb total_tmp+1
 adca total_tmp
 staa wk_num
 stab wk_num+1
 rts

; Moves the points of a win.
settle_win:
 ; Winning result is still in best_* and tsumo_flag/dealer_flag.
 ldaa best_fu
 bne settle_normal
 ldaa best_han
 jsr yakuman_basic
 bra settle_payers
settle_normal:
 ldaa best_han
 jsr fi_limit_han
settle_payers:
 clr settle_p
settle_win_00:
 ldaa settle_p
 cmpa turn
 beq settle_win_10
 tst tsumo_flag
 bne settle_tsumo
 cmpa discarder
 bne settle_win_10
 ldaa #4
 tst dealer_flag
 beq settle_factor
 ldaa #6
 bra settle_factor
settle_tsumo:
 ldaa #2
 tst dealer_flag
 bne settle_factor
 ldab settle_p
 cmpb dealer
 beq settle_factor
 ldaa #1
settle_factor:
 staa pay_factor
 jsr payer_amount
 ; Someone goes below zero long before 86 honba, so honba*3 fits a byte.
 ldab honba
 clra
 tst tsumo_flag
 bne settle_honba
 aslb
 addb honba
settle_honba:
 addb pay_amt+1
 adca pay_amt
 staa pay_amt
 stab pay_amt+1
 ldaa settle_p
 jsr player
 ldab P_SCORE+1,x
 subb pay_amt+1
 stab P_SCORE+1,x
 ldab P_SCORE,x
 sbcb pay_amt
 stab P_SCORE,x
settle_win_10:
 inc settle_p
 ldaa settle_p
 cmpa #4
 bne settle_win_00
 jsr turn_player
 ldab P_SCORE+1,x
 addb best_pts+1
 stab P_SCORE+1,x
 ldab P_SCORE,x
 adcb best_pts
 stab P_SCORE,x
 rts

; Moves the tenpai payments of a draw.
settle_draw:
 clr ry_tenpai
 clr ry_n
 clr loop_p
settle_draw_00:
 ldaa loop_p
 jsr eval_load
 jsr find_waits
 beq settle_draw_01
 inc ry_n
 jsr ry_bits4_x
 ldaa 0,x
 oraa ry_tenpai
 staa ry_tenpai
settle_draw_01:
 inc loop_p
 ldaa loop_p
 cmpa #4
 bne settle_draw_00
 ldaa ry_n
 beq settle_draw_04
 cmpa #4
 beq settle_draw_04
 clr loop_p
settle_draw_02:
 ldab loop_p
 jsr noten_delta
settle_draw_03:
 ldaa loop_p
 jsr player
 ldab P_SCORE+1,x
 addb ry_v+1
 stab P_SCORE+1,x
 ldab P_SCORE,x
 adcb ry_v
 stab P_SCORE,x
 inc loop_p
 ldaa loop_p
 cmpa #4
 bne settle_draw_02
settle_draw_04:
 rts
bits4: .byte 1,2,4,8
tenpai_pay: .byte 0,30,15,10
noten_pay: .byte 0,246,241,226
 .bss
pay_basic: .ds 2 ; basic points
; pay_factor is allocated in directpage.asm.
total_tmp: .ds 2 ; running total
settle_p: .ds 1 ; player being settled
settle_han: .ds 1 ; han of the win
ry_n: .ds 1 ; tenpai players

	.bss

 .code
; B = player index; ry_n / ry_tenpai describe the completed draw.
; Output ry_v = signed transfer in units of 100 points, including zero.
noten_delta:
 clr ry_v
 clr ry_v+1
 ldaa ry_n
 beq noten_delta_01
 cmpa #4
 beq noten_delta_01
 jsr bits4_x
 ldaa 0,x
 ldx #tenpai_pay
 anda ry_tenpai
 bne noten_delta_00
 dec ry_v
 ldx #noten_pay
noten_delta_00:
 ldab ry_n
 jsr addxb
 ldaa 0,x
 staa ry_v+1
noten_delta_01:
 rts
