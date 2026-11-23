; X = &ARRAY[B] for the arrays most often indexed by a kind or a place.
wall_x:
	ldx	#wall
	bra	addxb
; kattr, unseen and counts do not cross a page (build.py): only the low
; byte is added.
kattr_x:
 addb #<kattr
 stab kattr_x_ldx+2
kattr_x_ldx:
 ldx #kattr
 rts
btype_x:
	ldx	#btype
	bra	addxb
kind_unseen_x:
 ldab wk_kind
unseen_x:
 addb #<unseen
 stab unseen_x_ldx+2
unseen_x_ldx:
 ldx #unseen
 rts
best_y_x:
	ldx	#best_y
	bra	addxb
trip_n_x:
	ldx	#trip_n
	bra	addxb
kind_counts_x:
 ldab wk_kind
counts_x:
 addb #<counts
 stab counts_x_ldx+2
counts_x_ldx:
 ldx #counts
 rts
; A = kind. Returns A = its bit (1 << kind % 8) and B = kind / 8: its place
; in a set of kinds of 5 bytes (ac_lower, fw_bits, ev1_discard records).
kind_bit:
 tab
 lsrb
 lsrb
 lsrb
 anda #7
 pshb
 tab
 jsr player_bit
 pulb
 rts
; X = X + B
addxb:
	stx	addxb_tmp
	addb	addxb_tmp+1
	stab	addxb_tmp+1
	bcc	addxb_00
	inc	addxb_tmp
addxb_00:
	ldx	addxb_tmp
	rts

; A * B -> A (high), B (low)
mul12:
 ldab #12
mul8:
 staa mul_a
 ldaa #8
 staa mul_bits
 clra
 lsrb
mul8_00:
 bcc mul8_01
 adda mul_a
mul8_01:
 rora
 rorb
 dec mul_bits
 bne mul8_00
 rts

	.bss
addxb_tmp:	.ds	2 ; X being added to
mul_a:	.ds	1 ; multiplicand
mul_bits:	.ds	1 ; bits left
; wk_num is allocated in directpage.asm.
bss_all_end:

 .code
; A = kind. Returns A = counts of this kind and of the kinds within 2 of it
; in its suit (an honor: itself only), X = ns_buf with the five counts.
; counts of 0, 10, 20 and 30 are always 0: k - 1 and k + 1 need no rank check,
; k - 2 does for a 1 and k + 2 for a 9.
near_sum:
 tab
 jsr counts_x
 ldab 0,x
 stab ns_buf+2
 clr ns_buf
 clr ns_buf+1
 clr ns_buf+3
 clr ns_buf+4
 cmpa #K_HONOR
 bcc near_sum_02
 jsr kind_number
 dex
 dex
 ldab 1,x
 stab ns_buf+1
 ldab 3,x
 stab ns_buf+3
 cmpa #1
 beq near_sum_01
 ldab 0,x
 stab ns_buf
near_sum_01:
 cmpa #9
 beq near_sum_02
 ldab 4,x
 stab ns_buf+4
near_sum_02:
 ldaa ns_buf
 adda ns_buf+1
 adda ns_buf+2
 adda ns_buf+3
 adda ns_buf+4
 ldx #ns_buf
 rts

; A = valid suited compact kind. A = rank 1..9. Preserve B and X.
kind_number_b:
 tba
kind_number:
 cmpa #20
 bcs kind_number_00
 suba #20
 rts
kind_number_00:
 cmpa #10
 bcs kind_number_01
 suba #10
kind_number_01:
 rts
; A=suited kind, returns 0/1/2 (honors return 3). Preserve B and X.
kind_suit:
 cmpa #30
 bcc kind_suit_02
 cmpa #20
 bcc kind_suit_01
 cmpa #10
 bcc kind_suit_00
 clra
 rts
kind_suit_00:
 ldaa #1
 rts
kind_suit_01:
 ldaa #2
 rts
kind_suit_02:
 ldaa #3
 rts

; B = player. Returns A = 1 shifted left by B (player_bit_hi: $10 shifted
; left by B, the bit of player B + 4). Keeps X.
player_bit_hi:
 ldaa #$10
 bra player_bit_02
player_bit:
 ldaa #1
player_bit_02:
 tstb
 beq player_bit_01
player_bit_00:
 asla
 decb
 bne player_bit_00
player_bit_01:
 rts
