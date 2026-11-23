; Turn flow, calls, riichi and furiten.

ACT_DISCARD	.equ	0
ACT_TSUMO	.equ	1
ACT_KAN	.equ	2

R_PASS	.equ	0
R_RON	.equ	1
R_PON	.equ	2
R_CHI	.equ	3
R_KAN	.equ	4

; Abortive draws (abortive_draw, abort_names).
ABORT_KYUUSHU	.equ	0
ABORT_FOUR_WINDS	.equ	1
ABORT_FOUR_RIICHI	.equ	2
ABORT_FOUR_KANS	.equ	3
ABORT_THREE_RON	.equ	4

RF_RIICHI	.equ	$01
RF_CALLED	.equ	$02
; furo_attr bits. Bit 7 is tested with tst / bmi.
FURO_NO_CHANTA	.equ	$80 ; a furo without a terminal or honor
FURO_NO_TANYAO	.equ	$40 ; a furo with a terminal or honor

RINSHAN_POS	.equ	135

; Plays a hand: the player in turn draws and acts until the wall runs out.
turn_loop:
	jsr	demo_poll
	tst	draws_left
	bne	turn_loop_00
	jmp	ryukyoku
turn_loop_00:
	jsr	wall_next
	ldaa	turn
	jsr	hand_draw
	dec	draws_left
	clr	rinshan
; After a draw: shows the hand and lets the player in turn act.
after_draw:
	ldaa	turn
	staa	ai_player
	jsr	ui_nokori
	jsr	ui_turn
	ldaa	turn
	jsr	ui_hand
	ldaa	turn
	clrb
	jsr	check_win
	staa	can_win
	jsr	kyuushu_check
	tsta
	beq	after_draw_04
	ldaa	#ABORT_KYUUSHU
	jmp	abortive_draw
after_draw_04:
	ldaa	turn
	oraa	auto_play
	bne	after_draw_01
	jsr	human_turn
	bra	after_draw_02
after_draw_01:
	jsr	cpu_turn
after_draw_02:
	cmpa	#ACT_TSUMO
	bne	after_draw_03
	jmp	win_tsumo
after_draw_03:
	cmpa	#ACT_KAN
	bne	discard_step
	jmp	own_kan

; B = tile to discard, decl = 1 for a riichi declaration.
discard_step:
	ldaa	#$FF
	staa	abort_reason
	ldaa	turn
	jsr	discard
	; Four winds: the first discard of the last player, with no call before,
	; is the same wind as the first discards of the other three.
 jsr turn_player
	ldab	P_FLAG,x
	bitb	#P_FIRST
	beq	discard_step_10
	ldaa	dealer
	deca
	anda	#3
	cmpa	turn
	bne	discard_step_10
	ldaa	players+P_RIVER
	lsra
	cmpa	#K_EAST
	bcs	discard_step_10
	cmpa	#K_HAKU
	bcc	discard_step_10
	ldab	players+PSIZE+P_RIVER
	lsrb
	cba
	bne	discard_step_10
	ldab	players+PSIZE*2+P_RIVER
	lsrb
	cba
	bne	discard_step_10
	ldab	players+PSIZE*3+P_RIVER
	lsrb
	cba
	bne	discard_step_10
	ldaa	#ABORT_FOUR_WINDS
	staa	abort_reason
discard_step_10:
	; Four kans: the discard after the fourth kan, when not all four are
	; of the player in turn.
	tst	rinshan
	beq	discard_step_11
	ldaa	kans_done
	cmpa	#4
	bne	discard_step_11
	ldx	#minkan_n
	ldab	turn
	jsr	addxb
	ldaa	0,x
	adda	ankan_n-minkan_n,x
	cmpa	#4
	beq	discard_step_11
	ldaa	#ABORT_FOUR_KANS
	staa	abort_reason
discard_step_11:
 jsr turn_player
	ldaa	P_FLAG,x
	bmi	discard_step_01
	anda	#$FE
discard_step_01:
	tst	decl
	beq	discard_step_03
	bita	#P_FIRST
	beq	discard_step_02
	oraa	#P_DOUBLE
discard_step_02:
	oraa	#P_RIICHI
discard_step_03:
	anda	#$BB
	staa	P_FLAG,x
	tst	decl
	beq	discard_step_04
	ldx	#snd_riichi
	jsr	play
 jsr turn_player
	ldab	P_RLEN,x
	decb
	pshb
	addb	#P_RFLAG
	jsr	addxb
	ldab	#RF_RIICHI
	stab	0,x
	pulb
	jsr	ui_river_tile
	jsr	draw_riichi
	; Four riichi: every player has P_RIICHI (bit 7).
	ldaa	players+P_FLAG
	anda	players+PSIZE+P_FLAG
	anda	players+PSIZE*2+P_FLAG
	anda	players+PSIZE*3+P_FLAG
	bpl	discard_step_04
	ldaa	#ABORT_FOUR_RIICHI
	staa	abort_reason
discard_step_04:
	clr	rinshan
	ldaa	#$FF
	staa	kk1
	staa	kk2
	tst	pending_dora
	beq	react
	clr	pending_dora
 jsr dora_open

; The other player may win with or call the discarded tile dc_tile.
react:
	ldaa	turn
	staa	discarder
	clr	react_choice
	clr	react_winner
	clr	react_count
	clr	react_phase
	clr	react_ron_n
	clr	react_hum_ron
	ldab	#$FF
	stab	react_human
	staa	other
react_four:
	ldaa	other
	inca
	anda	#3
	staa	other
	staa	ai_player
 tst react_phase
 bne react_calls
 jsr ron_ok
 staa can_ron
 beq react_11
 ldaa other
 bne react_ron_cpu
 tst auto_play
 bne react_ron_cpu
 ; The human is asked after the CPU rons are known: 1 when no CPU before
 ; the human rons, 2 when one does.
 ldaa #1
 tst react_ron_n
 beq react_01
 inca
react_01:
 staa react_hum_ron
 bra react_11
react_ron_cpu:
 tst react_ron_n
 bne react_02
 ldaa other
 staa react_ron_first
react_02:
 inc react_ron_n
 bra react_11
react_calls:
 clr can_ron
 ldaa other
 bne react_cpu
 tst auto_play
 bne react_cpu
 ldaa react_human
 cmpa #$FF
 beq react_human_ask
 ldab react_hpat
 bra react_answer
react_human_ask:
 jsr human_react
 bra react_answer
react_cpu:
 jsr ai_call
react_answer:
	staa	react_act
	stab	react_pat
	tst	can_ron
	beq	react_save
	ldaa	other
	jsr	player
	ldaa	P_FLAG,x
	oraa	#P_SKIP
	staa	P_FLAG,x
react_save:
 tst react_phase
 bne react_save_call
 ldaa react_act
 staa react_human
 ldaa react_pat
 staa react_hpat
 bra react_11
react_save_call:
	ldaa	react_act
	beq	react_11
	cmpa	#R_CHI
	bne	react_priority
	tst	react_choice
	bne	react_11
	bra	react_10
react_priority:
	ldab	react_choice
	beq	react_10
	cmpb	#R_CHI
	bne	react_11
react_10:
	staa	react_choice
	ldaa	react_pat
	staa	react_pattern
	ldaa	other
	staa	react_winner
react_11:
	inc	react_count
	ldaa	react_count
	cmpa	#3
	bne	react_more
 tst react_phase
 bne react_stick
 ; The human decides when the ron would win (no CPU before it) or would
 ; make three rons.
 ldab react_hum_ron
 beq react_04
 cmpb #1
 beq react_ron_ask
 ldaa react_ron_n
 cmpa #2
 bne react_04
react_ron_ask:
 clr other
 ldaa #1
 staa can_ron
 jsr human_react
 cmpa #R_RON
 bne react_ron_pass
 ldab react_hum_ron
 cmpb #1
 bne react_03
 clr react_ron_first
react_03:
 inc react_ron_n
 bra react_04
react_ron_pass:
 staa react_human
 stab react_hpat
 ldaa players+P_FLAG
 oraa #P_SKIP
 staa players+P_FLAG
react_04:
 ; One or two rons: the first from the discarder wins. Three: abortive draw.
 ldaa react_ron_n
 beq react_ron_none
 cmpa #3
 bne react_ron_win
 ldaa #ABORT_THREE_RON
 jmp abortive_draw
react_ron_win:
 ldaa react_ron_first
 staa other
 jsr ron_ok
 jmp win_ron
react_ron_none:
 ; A pending abortive draw takes no calls.
 ldaa abort_reason
 bpl react_stick
 inc react_phase
 clr react_count
 ldaa discarder
 staa other
react_more:
 jmp react_four
react_stick:
 ; The discard passed: no riichi player can ron its kind (river_bits, bits 0-3).
 ldab #3
react_stick_00:
 tba
 jsr player
 ldaa P_FLAG,x
 asla
 rol rp_bits
 decb
 bpl react_stick_00
 ldab dc_tile
 lsrb
 jsr river_bits_x
 ldaa rp_bits
 anda #$0F
 oraa 0,x
 staa 0,x
	tst	decl
	beq	react_call
	clr	decl
	ldaa	discarder
	jsr	player
	ldaa	P_SCORE+1,x
	suba	#10
	staa	P_SCORE+1,x
	ldaa	P_SCORE,x
	sbca	#0
	staa	P_SCORE,x
	inc	kyotaku
	ldaa	P_FLAG,x
	oraa	#P_IPPATSU
	staa	P_FLAG,x
	jsr	draw_info
react_call:
	jsr	mark_clear
	ldaa	abort_reason
	bmi	react_12
	jmp	abortive_draw
react_12:
	ldaa	react_choice
	bne	react_called
	ldaa	discarder
	inca
	anda	#3
	staa	turn
	jmp	turn_loop
react_called:
	staa	react_act
	ldaa	react_pattern
	staa	react_pat
	ldaa	react_winner
	staa	turn
	staa	other
	jsr	do_call
	ldaa	react_act
	cmpa	#R_KAN
	bne	call_discard
	jmp	rinshan_draw

; The player in turn called pon or chi and discards without drawing.
call_discard:
	ldab	turn
	bne	calldisc_cpu
	jsr	human_called
	bra	call_discard_00
calldisc_cpu:
	ldaa	turn
	staa	ai_player
	jsr	ai_discard
call_discard_00:
	clr	decl
	jmp	discard_step

; B = kind of the kan of the player in turn.
own_kan:
	stab	kan_kind
	ldx	#snd_kan
	jsr	play
 jsr turn_player
	ldab	kan_kind
	jsr	addxb
	ldaa	0,x
	anda	#7
	cmpa	#4
	bne	ownkan_kakan
	jsr	clear_ippatsu
	ldaa	#M_ANKAN
	staa	fmk_type
	ldaa	kan_kind
	staa	fmk_kind
	ldaa	#$FF
	staa	fmk_from
	staa	fmk_tile
 jsr furo_make
 jsr dora_open
	jmp	rinshan_draw
ownkan_kakan:
	ldaa	turn
	ldab	kan_kind
	jsr	hand_pick
	stab	dc_tile
	ldaa	#1
	staa	chankan_f
	ldaa	turn
	staa	discarder
	staa	other
	clr	react_count
own_kan_00:
	ldaa	other
	inca
	anda	#3
	staa	other
	jsr	ron_ok
	beq	own_kan_01
	ldaa	other
	bne	ownkan_chankan
	jsr	ask_ron
	tsta
	bne	ownkan_chankan
	ldaa	players+P_FLAG
	oraa	#P_SKIP
	staa	players+P_FLAG
own_kan_01:
	inc	react_count
	ldaa	react_count
	cmpa	#3
	bne	own_kan_00
	clr	chankan_f
	bra	ownkan_no_rob
ownkan_chankan:
 jmp win_ron

ownkan_no_rob:
	jsr	clear_ippatsu
	ldaa	turn
	ldab	kan_kind
	jsr	furo_upgrade
	ldaa	#1
	staa	pending_dora
; rinshan_draw -> after_draw redraws only the active hand and the header.

; Draws the replacement tile after a kan.
rinshan_draw:
	dec	draws_left
	ldab	#RINSHAN_POS
	subb	kans_done
	jsr	wall_x
	ldab	0,x
	inc	kans_done
	ldaa	turn
	jsr	hand_draw
	ldaa	#1
	staa	rinshan
	jmp	after_draw

; ---------------------------------------------------------------- own turn

; At the first draw of the player in turn, with no call before. Returns A
; nonzero if the player declares kyuushu kyuuhai (nine kinds of yaochu).
; A CPU declares only at kokushi 4-shanten (nine kinds, no pair).
kyuushu_check:
 jsr turn_player
 ldaa P_FLAG,x
 bita #P_FIRST
 beq kyuushu_check_01
 jsr turn_eval_load
 jsr spec_count
 ldaa SP_YAO,x
 cmpa #9
 bcs kyuushu_check_01
 tst turn
 bne kyuushu_check_00
 tst auto_play
 beq kyuushu_ask
kyuushu_check_00:
 cmpa #9
 bne kyuushu_check_01
 ldaa spec_cnt+SP_YPAIRS
 beq kyuushu_check_02
kyuushu_check_01:
 clra
 rts
kyuushu_check_02:
 ldaa #1
 rts

; Shows Cキュウシュキュウハイ? and waits. Returns A nonzero for C, 0 for space.
kyuushu_ask:
 ldaa #20
 staa posx
 staa posy
 ldx #act_kyuushu
 jsr drawstr
kyuushu_ask_00:
 jsr frame
 ldaa knew
 anda #KEY_C+KEY_SPACE
 beq kyuushu_ask_00
 anda #KEY_C
 psha
 ldaa #20
 staa posx
 staa posy
 ldaa #12
 jsr erase1
 pula
 rts

; Returns A = action, B = tile (discard) or kind (kan). decl = 1 for a
; riichi declaration.
human_turn:
	clr	decl
	clr	riichi_mode
	clr	riichi_reject
	jsr	kan_options
	tst	players+P_FLAG
	bpl	human_normal
	jmp	riichi_turn
human_normal:
	jsr	riichi_ok
	staa	can_riichi
	ldab	players+P_LEN
	decb
	stab	cursor
	jsr	draw_arrow
human_letters:
	jsr	clear_letters
	tst	riichi_mode
	bne	human_show_r
	tst	can_win
	beq	human_turn_00
 jsr add_tsumo_act
human_turn_00:
	tst	can_riichi
	beq	human_turn_10
human_show_r:
	jsr	show_riichi_hint
	tst	riichi_mode
	bne	human_turn_11
human_turn_10:
	tst	kan_n
	beq	human_turn_11
	jsr	show_kan_hint
human_turn_11:
	jsr	frame
	ldaa	knew
	bita	#KEY_T
	beq	human_turn_12
	tst	can_win
	beq	human_turn_12
	tst	riichi_mode
	bne	human_turn_12
	jsr	end_cursor
	ldaa	#ACT_TSUMO
	rts
human_turn_12:
	bita	#KEY_K
	beq	human_turn_13
	tst	kan_n
	beq	human_turn_13
	tst	riichi_mode
	bne	human_turn_13
	jsr	pick_kan
	jsr	end_cursor
	ldab	kan_kind
	ldaa	#ACT_KAN
	rts
human_turn_13:
	bita	#KEY_R
	beq	human_turn_20
	ldx	#snd_select
	jsr	play
	clr	riichi_reject
	tst	can_riichi
	bne	human_r_allowed
	inc	riichi_reject
	jsr	draw_riichi
	jmp	human_turn_11
human_r_allowed:
	ldaa	riichi_mode
	eora	#1
	staa	riichi_mode
	clra
	jsr	ui_hand
	jmp	human_letters
human_turn_20:
	bita	#KEY_SPACE
	beq	human_move
	tst	riichi_mode
	beq	human_discard
	clra
	ldab	cursor
	jsr	tenpai_without
	beq	human_turn_11
	ldaa	#1
	staa	decl
human_discard:
	jsr	end_cursor
 jsr p0_hand_at
	ldaa	#ACT_DISCARD
	rts
human_move:
	jsr	move_cursor
	jmp	human_turn_11

; After riichi: wins, kans or discards the drawn tile.
riichi_turn:
	jsr	clear_letters
	tst	can_win
	beq	riichi_turn_00
 jsr add_tsumo_act
riichi_turn_00:
	tst	kan_n
	beq	riichi_turn_01
	jsr	show_kan_hint
riichi_turn_01:
	tst	can_win
	bne	riichi_turn_02
	tst	kan_n
	bne	riichi_turn_02
	ldaa	#15
	jsr	wait_frames
	bra	riichi_turn_05
riichi_turn_02:
	jsr	frame
	ldaa	knew
	bita	#KEY_T
	beq	riichi_turn_03
	tst	can_win
	beq	riichi_turn_03
	ldaa	#ACT_TSUMO
	rts
riichi_turn_03:
	bita	#KEY_K
	beq	riichi_turn_04
	tst	kan_n
	beq	riichi_turn_04
	ldab	kan_k
	stab	kan_kind
	ldaa	#ACT_KAN
	rts
riichi_turn_04:
	bita	#KEY_SPACE
	beq	riichi_turn_02
riichi_turn_05:
	jsr	clear_letters
	ldab	players+P_DRAWN
	ldaa	#ACT_DISCARD
	rts

; Discard after pon or chi. Kinds kk1 and kk2 may not be discarded.
; Returns B = tile.
human_called:
	tst	auto_play
	bne	calldisc_cpu
	clr	riichi_mode
	clr	can_win
	ldab	players+P_LEN
	decb
	stab	cursor
	clra
	jsr	ui_hand
human_called_00:
	jsr	frame
	ldaa	knew
	bita	#KEY_SPACE
	beq	human_called_01
	clra
	ldab	cursor
	jsr	hand_at
	lsrb
	cmpb	kk1
	beq	human_called_00
	cmpb	kk2
	beq	human_called_00
	jsr	end_cursor
 jmp p0_hand_at
human_called_01:
	jsr	move_cursor
	bra	human_called_00

; Moves the cursor of the own hand with Z and X (knew in A).
move_cursor:
	tst	players+P_LEN
	beq	move_cursor_04
	ldab	cursor
	bita	#KEY_Z
	beq	move_cursor_01
	tstb
	bne	move_cursor_00
	ldab	players+P_LEN
move_cursor_00:
	decb
	bra	move_cursor_02
move_cursor_01:
	bita	#KEY_X
	beq	move_cursor_04
	incb
	cmpb	players+P_LEN
	bne	move_cursor_02
	clrb
move_cursor_02:
	stab	cursor
	tst	riichi_mode
	beq	move_cursor_03
	clra
	jmp	ui_hand
move_cursor_03:
	jsr	draw_arrow
move_cursor_04:
	rts

; Removes the cursor and the letters. Returns B = cursor.
end_cursor:
	jsr	clear_letters
	ldab	cursor
	pshb
	ldaa	#$FF
	staa	cursor
	jsr	draw_arrow
	pulb
	rts

; A = player, B = position in the hand. Returns A = 1 if the hand without
; that tile is tenpai.
; Returns with N and Z set from A.
tenpai_without:
	pshb
	jsr	eval_load
	pulb
	jsr	hand_at
	lsrb
	jsr	counts_x
 jmp has_wait_cut

; Requirements shared by human and CPU. A = player (ai_can_riichi:
; ai_player); A = boolean result.
; Returns with N and Z set from A.
ai_can_riichi:
 ldaa ai_player
riichi_allowed:
 staa ri_player
 jsr player
 tst P_FLAG,x
 bmi riichi_no
 tst P_SCORE,x
 bmi riichi_no
 bne riichi_allowed_00
 ldaa P_SCORE+1,x
 cmpa #10
 bcs riichi_no
riichi_allowed_00:
 ldaa draws_left
 cmpa #4
 bcs riichi_no
 ldaa ri_player
 jmp is_closed
riichi_yes:
 ldaa #1
 rts
riichi_no:
 clra
 rts

; Human can enter riichi selection only if some discard leaves a real wait.
riichi_ok:
 clra
 jsr riichi_allowed
 beq riichi_no
 clra
 jsr eval_load
 jsr shanten
 bgt riichi_no
 jsr has_four
 beq riichi_yes
 clr ri_kind
riichi_ok_00:
 ldab ri_kind
 jsr	counts_x
 tst 0,x
 beq riichi_ok_01
 jsr has_wait_cut
 psha
 ldab ri_kind
 jsr	counts_x
 inc 0,x
 pula
 tsta
 bne riichi_yes
riichi_ok_01:
 inc ri_kind
 ldaa ri_kind
 cmpa #K_END
 bne riichi_ok_00
 bra riichi_no

; A = player. Returns A = 1 if all furo are closed kans.
; Returns with N and Z set from A.
is_closed:
	jsr	player
	ldab	P_NFURO,x
	beq	is_closed_01
is_closed_00:
	ldaa	P_FURO,x
	anda	#3
	cmpa	#M_ANKAN
	bne	is_closed_02
	inx
	inx
	inx
	decb
	bne	is_closed_00
is_closed_01:
	ldaa	#1
	rts
is_closed_02:
	clra
	rts

; Fills kan_k / kan_n with the kinds the player in turn can make a kan of.
kan_options:
	clr	kan_n
	tst	draws_left
	beq	kan_options_03
	ldaa	kans_done
	cmpa	#4
	bcc	kan_options_03
 jsr turn_eval_load
	clr	ko_k
kan_options_00:
	ldab	ko_k
	jsr	counts_x
	ldaa	0,x
	beq	kan_options_02
	cmpa	#4
	bne	kan_options_01
	jsr	kan_riichi_ok
	beq	kan_options_02
 jsr add_kan_option
	bra	kan_options_02
kan_options_01:
 jsr turn_player
	tst	P_FLAG,x
	bmi	kan_options_02
	ldaa	turn
	ldab	ko_k
	jsr	furo_find_pon
	cpx	#0
	beq	kan_options_02
 jsr add_kan_option
kan_options_02:
	inc	ko_k
	ldaa	ko_k
	cmpa	#K_END
	bne	kan_options_00
kan_options_03:
	rts

; Adds kind ko_k to the kan options.
add_kan_option:
 ldaa ko_k
	ldx	#kan_k
	ldab	kan_n
	jsr	addxb
	staa	0,x
	inc	kan_n
	rts

; Kind ko_k has 4 tiles in the hand. Returns A = 1 if the player may make an
; ankan (always without riichi; after riichi only with the drawn tile and the
; same waits).
; Returns with N and Z set from A.
kan_riichi_ok:
 jsr turn_player
	tst	P_FLAG,x
	bmi	kan_riichi_ok_00
	ldaa	#1
	rts
kan_riichi_ok_00:
	ldaa	P_DRAWN,x
	lsra
	cmpa	ko_k
	bne	kan_riichi_ok_03
	ldab	ko_k
	jsr	counts_x
	dec	0,x
	jsr	find_waits
	ldx	#waits
	ldab	#KN
kan_riichi_ok_01:
	ldaa	0,x
	staa	waits_old-waits,x
	inx
	decb
	bne	kan_riichi_ok_01
	ldab	ko_k
	jsr	counts_x
	ldaa	0,x
	suba	#3
	staa	0,x
 ldaa furo_tiles-counts,x
 adda #4
 staa furo_tiles-counts,x
 inc nfuro
 jsr find_waits
 jsr turn_eval_load
	ldx	#waits
	ldab	#KN
kan_riichi_ok_02:
	ldaa	0,x
	cmpa	waits_old-waits,x
	bne	kan_riichi_ok_03
	inx
	decb
	bne	kan_riichi_ok_02
	ldaa	#1
	rts
kan_riichi_ok_03:
	clra
	rts

; Sets kan_kind: the kind of the tile under the cursor if it is an option,
; otherwise the first option.
pick_kan:
	clra
	ldab	cursor
	jsr	hand_at
	tba
	lsra
	ldx	#kan_k
	ldab	kan_n
pick_kan_00:
	cmpa	0,x
	beq	pick_kan_01
	inx
	decb
	bne	pick_kan_00
	ldaa	kan_k
pick_kan_01:
	staa	kan_kind
	rts

; ---------------------------------------------------------------- reacting

; A = player. Returns A = 1 if the player can ron dc_tile (winning shape
; with yaku, not furiten).
; Returns with N and Z set from A.
ron_ok:
 staa ra_player
 jsr player
 ldab P_FLAG,x
 bitb #P_SKIP
 bne ron_no
 ldaa ra_player
 ldab #1
 jsr check_win
 beq ron_no
 ; Furiten: a kind in the own river completes the 13 tiles.
 ldaa ra_player
 jsr player
 ldab P_RLEN,x
 beq ron_yes
 stab rn_n
 jsr eval_load
 jsr find_waits
 ldaa ra_player
 jsr player
 ldab #P_RIVER
 jsr addxb
ron_ok_01:
 ldab 0,x
 lsrb
 stx rn_x
 ldx #waits
 jsr addxb
 tst 0,x
 bne ron_no
 ldx rn_x
 inx
 dec rn_n
 bne ron_ok_01
ron_yes:
 ldaa #1
 rts
ron_no:
 clra
 rts

; A = 1 if counts and furo_tiles hold 4 tiles of one kind.
; Returns with N and Z set from A.
has_four:
 ldx #counts
has_four_00:
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #4
 bcc ron_yes
 inx
 cpx #counts+KN
 bne has_four_00
 bra ron_no

; counts, furo_tiles and nfuro of a hand of 13 - 3*nfuro tiles. Sets
; waits[k] = 1 for every kind k that completes it (regular shape, chiitoi or
; kokushi), except a kind of which 4 tiles are held. counts is restored.
; Returns A = 1 if there is a wait.
; Returns with N and Z set from A. has_wait_cut: X = &counts[k]; takes one
; tile of k out first and does not put it back.
has_wait_cut:
 dec 0,x
find_waits:
 ldx #counts
find_waits_00:
 clrb
 ldaa 0,x
 adda furo_tiles-counts,x
 cmpa #4
 bcc find_waits_01
 incb
find_waits_01:
 stab ac_yes-counts,x
 inx
 cpx #counts+KN
 bne find_waits_00
 clra
 jsr acc_search
 ldab nfuro
 bne fw_result
 ; Chiitoi tenpai: the single tile.
 jsr spec_count
 ldaa SP_PAIRS,x
 ldab SP_KINDS,x
 jsr chii_sh
 bne fw_kokushi
 ldx #counts
find_waits_10:
 ldaa 0,x
 cmpa #1
 bne find_waits_11
 ldaa #2
 staa ac_yes-counts,x
find_waits_11:
 inx
 cpx #counts+KN
 bne find_waits_10
fw_kokushi:
 ; Kokushi tenpai: every yaochu kind without a pair, or the missing kind.
 ldaa spec_cnt+SP_YAO
 ldab spec_cnt+SP_YPAIRS
 jsr kok_sh
 bne fw_result
 ldx #yao_offsets
find_waits_21:
 stx yao_ptr
 ldab 0,x
 jsr counts_x
 tst spec_cnt+SP_YPAIRS
 beq find_waits_22
 tst 0,x
 bne find_waits_23
find_waits_22:
 ldaa #2
 staa ac_yes-counts,x
find_waits_23:
 ldx yao_ptr
 inx
 cpx #yao_offsets+13
 bne find_waits_21
fw_result:
 ; ac_yes 2 becomes 1, 1 and 0 become 0.
 clra
 ldx #ac_yes
find_waits_30:
 ldab 0,x
 lsrb
 stab waits-ac_yes,x
 aba
 inx
 cpx #ac_yes+KN
 bne find_waits_30
 tsta
 beq find_waits_31
 ldaa #1
find_waits_31:
 rts

; The own player reacts to dc_tile. Returns A = R_*, B = chi pattern.
human_react:
	clr	rp_pon
	clr	rp_kan
	clr	rp_chi
	clr	can_win
	tst	draws_left
	beq	hreact_show
	tst	players+P_FLAG
	bmi	hreact_show
	clra
	jsr	call_options
hreact_show:
	ldaa	can_ron
	oraa	rp_pon
	oraa	rp_kan
	oraa	rp_chi
	bne	hreact_ask
	clra
	rts
hreact_ask:
 ldx #snd_select
 jsr play
 jsr clear_letters
 jsr hint_start
 tst rp_chi
 beq human_react_00
 clrb
 jsr hint_add
human_react_00:
 tst rp_pon
 beq human_react_01
 ldab #1
 jsr hint_add
human_react_01:
 tst rp_kan
 beq human_react_02
 ldab #2
 jsr hint_add
human_react_02:
 tst can_ron
 beq human_react_03
 ldab #3
 jsr hint_add
human_react_03:
	jsr	frame
	ldaa	knew
	bita	#KEY_R
	beq	human_react_04
	tst	can_ron
	beq	human_react_04
	jsr	clear_letters
	ldaa	#R_RON
	rts
human_react_04:
	bita	#KEY_P
	beq	human_react_05
	tst	rp_pon
	beq	human_react_05
	jsr	clear_letters
	ldaa	#R_PON
	rts
human_react_05:
	bita	#KEY_K
	beq	human_react_06
	tst	rp_kan
	beq	human_react_06
	jsr	clear_letters
	ldaa	#R_KAN
	rts
human_react_06:
	bita	#KEY_C
	beq	human_react_07
	tst	rp_chi
	beq	human_react_07
	jmp	choose_chi
human_react_07:
	bita	#KEY_SPACE
	beq	human_react_03
	jsr	clear_letters
	ldaa	#R_PASS
	rts

 ; Select a whole chi pattern; highlight its two hand tiles.
choose_chi:
	jsr	clear_letters
	ldaa	rp_chi
	jsr	single_bit
	tstb
	bmi	choose_chi_00
	ldaa	#R_CHI
	rts
choose_chi_00:
	clr	chi_pat
	ldaa	#1
	staa	chi_mode
	ldaa	#$FF
	staa	cursor
	ldaa	rp_chi
	bita	#1
	bne	choose_chi_01
	ldaa	#KEY_X
	jsr	chi_step
choose_chi_01:
	jsr	chi_preview
choose_chi_02:
	jsr	frame
	ldaa	knew
	bita	#$84
	bne	choose_chi_03
	bita	#3
	beq	choose_chi_02
	jsr	chi_step
	jsr	chi_preview
	bra	choose_chi_02
choose_chi_03:
	clr	chi_mode
	clra
	jsr	ui_hand
	ldab	chi_pat
	ldaa	#R_CHI
	rts

; A = Z/X key. Skip unavailable patterns and wrap at either end.
chi_step:
	staa	chi_key
chi_step_00:
	ldaa	chi_key
	bita	#KEY_Z
	beq	chi_step_01
	dec	chi_pat
	bpl	chi_step_02
	ldaa	#2
	staa	chi_pat
	bra	chi_step_02
chi_step_01:
	inc	chi_pat
	ldaa	chi_pat
	cmpa	#3
	bcs	chi_step_02
	clr	chi_pat
chi_step_02:
	ldab	chi_pat
 jsr chi_pat_ok
	beq	chi_step_00
	rts

; B = chi pattern (0..2). Returns A = 1 if rp_chi allows it.
; Returns with N and Z set from A.
chi_pat_ok:
	ldaa	rp_chi
	tstb
	beq	chi_pat_ok_01
chi_pat_ok_00:
	lsra
	decb
	bne	chi_pat_ok_00
chi_pat_ok_01:
	anda	#1
	rts

; Shows the hand tiles of chi pattern chi_pat.
chi_preview:
	ldaa	dc_tile
	lsra
	ldab	chi_pat
	jsr	chi_kinds
	ldaa	ck_a
	jsr	cp_position
	stab	chi_i1
	ldaa	ck_b
	jsr	cp_position
	stab	chi_i2
	clra
	jmp	ui_hand

; A = kind in the own hand. Returns B = position of its first tile.
cp_position:
	staa	cp_k
	clrb
cp_position_00:
	pshb
 jsr p0_hand_at
	lsrb
	cmpb	cp_k
	pulb
	beq	cp_position_01
	incb
	bra	cp_position_00
cp_position_01:
	rts

; A = mask. Returns B = bit number if exactly one bit is set, else B < 0.
single_bit:
	clrb
	cmpa	#1
	beq	single_bit_00
	incb
	cmpa	#2
	beq	single_bit_00
	incb
	cmpa	#4
	beq	single_bit_00
	ldab	#$FF
single_bit_00:
	rts

; A = called kind, B = pattern. Sets ck_a, ck_b (the two hand kinds).
chi_kinds:
	staa	ck_a
	staa	ck_b
	tstb
	bne	chi_kinds_00
	dec	ck_a
	dec	ck_a
	dec	ck_b
	rts
chi_kinds_00:
	cmpb	#1
	bne	chi_kinds_01
	dec	ck_a
	inc	ck_b
	rts
chi_kinds_01:
	inc	ck_a
	inc	ck_b
	inc	ck_b
	rts

; A = player. Sets rp_pon, rp_kan, rp_chi for the player and dc_tile.
call_options:
	staa	call_player
	clr	rp_pon
	clr	rp_kan
	clr	rp_chi
	jsr	eval_load
	ldab	dc_tile
	lsrb
	stab	cop_t
	jsr	counts_x
	ldaa	0,x
	cmpa	#2
	bcs	options_chi
	psha
	ldaa	#$FF
	staa	kk2
	ldaa	cop_t
	staa	kk1
	staa	ck_a
	staa	ck_b
	jsr	kuikae_ok
	staa	rp_pon
	pula
	cmpa	#3
	bcs	options_chi
	ldaa	kans_done
	cmpa	#4
	bcc	options_chi
	ldaa	#1
	staa	rp_kan
options_chi:
	ldaa	discarder
	inca
	anda	#3
	cmpa	call_player
	bne	clear_kk
	ldaa	cop_t
	cmpa	#K_HONOR
	bcc	clear_kk
	clr	cop_pat
options_ploop:
	ldaa	cop_t
	ldab	cop_pat
	jsr	chi_valid
	beq	options_pnext
	ldaa	cop_t
	ldab	cop_pat
	jsr	chi_forbidden
	jsr	kuikae_ok
	beq	options_pnext
	ldab	cop_pat
	jsr	player_bit
	oraa	rp_chi
	staa	rp_chi
options_pnext:
	inc	cop_pat
	ldaa	cop_pat
	cmpa	#3
	bne	options_ploop
clear_kk:
	ldaa	#$FF
	staa	kk1
	staa	kk2
	rts

; A = called kind (a number tile), B = pattern. Returns A = 1 if both hand
; kinds are in counts. Sets ck_a, ck_b. A kind out of the suit is empty.
; Returns with N and Z set from A.
chi_valid:
 jsr chi_kinds
 jsr kind_number
 tstb
 bne chi_valid_00
 cmpa #3
 bcs chi_valid_03
 bra chi_valid_02
chi_valid_00:
 cmpb #1
 bne chi_valid_01
 cmpa #2
 bcs chi_valid_03
 cmpa #8
 bhi chi_valid_03
 bra chi_valid_02
chi_valid_01:
 cmpa #7
 bhi chi_valid_03
chi_valid_02:
 ldab ck_a
 jsr cv_check
 beq chi_valid_03
 ldab ck_b
 jmp cv_check
chi_valid_03:
 clra
 rts

; B = kind. Returns A = 1 if it is in counts.
; Returns with N and Z set from A.
cv_check:
	jsr	counts_x
	ldaa	0,x
	beq	cv_check_00
	ldaa	#1
cv_check_00:
	rts

; A = called kind, B = pattern. Sets kk1 (the called kind) and kk2 (the
; kind on the other side of the sequence, or $FF). A kind out of the suit
; is never in the hand.
chi_forbidden:
 staa kk1
 ldaa #$FF
 staa kk2
 ldaa kk1
 jsr kind_number
 tstb
 bne chi_forbidden_00
 cmpa #4
 bcs chi_forbidden_02
 ldaa kk1
 suba #3
 bra chi_forbidden_01
chi_forbidden_00:
 cmpb #1
 beq chi_forbidden_02
 cmpa #6
 bhi chi_forbidden_02
 ldaa kk1
 adda #3
chi_forbidden_01:
 staa kk2
chi_forbidden_02:
 rts

; counts (own hand) without ck_a and ck_b (one tile each; the same kind for
; pon twice). Returns A = 1 if a tile other than kk1 and kk2 remains.
; Returns with N and Z set from A.
kuikae_ok:
	jsr	pair_remove
	clr	ku_ok
	ldx	#counts
	clrb
kuikae_ok_00:
	tst	0,x
	beq	kuikae_ok_01
	tba
	cmpa	kk1
	beq	kuikae_ok_01
	cmpa	kk2
	beq	kuikae_ok_01
	inc	ku_ok
	bra	kuikae_ok_02
kuikae_ok_01:
	inx
	incb
	cmpb	#K_END
	bne	kuikae_ok_00
kuikae_ok_02:
	jsr	pair_restore
	ldaa	ku_ok
	rts

; ck_a/ck_b may name the same kind. Both helpers preserve their values.
pair_remove:
	ldab	ck_a
	jsr	counts_x
	dec	0,x
	ldab	ck_b
	jsr	counts_x
	dec	0,x
	rts
pair_restore:
	ldab	ck_a
	jsr	counts_x
	inc	0,x
	ldab	ck_b
	jsr	counts_x
	inc	0,x
	rts

; The player in turn calls dc_tile: react_act = R_PON, R_CHI (react_pat) or
; R_KAN.
do_call:
	ldx	#snd_pon
	ldaa	react_act
	cmpa	#R_PON
	beq	docall_sound
	ldx	#snd_chi
	cmpa	#R_CHI
	beq	docall_sound
	ldx	#snd_kan
docall_sound:
	jsr	play
	ldaa	discarder
	jsr	player
	ldab	P_RLEN,x
	decb
	addb	#P_RFLAG
	jsr	addxb
	ldab	0,x
	orab	#RF_CALLED
	stab	0,x
	jsr	ui_latest_discard
	jsr	clear_ippatsu
	ldaa	dc_tile
	staa	fmk_tile
	lsra
	staa	dcl_kind
	staa	fmk_kind
	ldaa	discarder
	staa	fmk_from
	ldaa	react_act
	cmpa	#R_CHI
	beq	docall_chi
	ldab	#M_PON
	cmpa	#R_PON
	beq	docall_pon
	ldaa	#1
	staa	pending_dora
	ldab	#M_MINKAN
	bra	docall_add
docall_pon:
	ldaa	dcl_kind
	staa	kk1
	ldaa	#$FF
	staa	kk2
	bra	docall_add
docall_chi:
	ldaa	dcl_kind
	ldab	react_pat
	jsr	chi_kinds
	jsr	chi_forbidden
	ldaa	ck_a
	cmpa	dcl_kind
	bcs	docall_chi_first
	ldaa	dcl_kind
docall_chi_first:
	staa	fmk_kind
	ldab	#M_CHI
docall_add:
	stab	fmk_type
 jsr furo_make
	ldaa	turn
	jsr	ui_hand
	jsr	draw_arrow
 jmp ui_turn

; Clears the first-turn and ippatsu flags of all players.
clear_ippatsu:
	ldaa	#4
	ldx	#players+P_FLAG
clear_ippatsu_00:
	psha
	ldaa	0,x
	anda	#$BB
	staa	0,x
	ldab	#PSIZE
	jsr	addxb
	pula
	deca
	bne	clear_ippatsu_00
	rts

; ---------------------------------------------------------------- furo

; A furo is 3 bytes: M_TYPE (type in bits 0-1; for a chi, bits 2-3 the place
; of the called tile; bit 7 set if a red five is in the furo, bits 4-5 its
; place among the tiles), M_KIND (the first kind)
; and M_FROM (the player called from, $FF for a closed kan). Only
; furo_make and furo_upgrade change P_NFURO and P_FURO.

; The player in turn makes a furo of fmk_type with first kind fmk_kind, called tile
; fmk_tile ($FF for a closed kan) from fmk_from, and removes its other tiles
; from the hand. A red five in the hand goes into the furo.
furo_make:
 ldaa turn
	staa	fmk_p
	clr	fmk_red
	clr	fmk_j
	ldab	fmk_tile
	cmpb	#$FF
	beq	furo_make_00
	jsr	fmk_note
furo_make_00:
	ldaa	fmk_type
	bne	furo_make_03
	ldaa	fmk_kind
	staa	fmk_k
	ldaa	#3
	staa	fmk_n
furo_make_01:
	ldab	fmk_tile
	lsrb
	cmpb	fmk_k
	beq	furo_make_02
	ldab	fmk_k
	jsr	fmk_take
furo_make_02:
	inc	fmk_k
	dec	fmk_n
	bne	furo_make_01
	bra	furo_make_05
furo_make_03:
	inca
	staa	fmk_n
furo_make_04:
	ldab	fmk_kind
	jsr	fmk_take
	dec	fmk_n
	bne	furo_make_04
furo_make_05:
	ldaa	fmk_p
	jsr	player
	ldab	P_NFURO,x
	inc	P_NFURO,x
	stab	fmk_k
	aslb
	addb	fmk_k
	addb	#P_FURO
	jsr	addxb
	ldaa	fmk_type
	bne	furo_make_06
	; A chi keeps the place of the called tile in bits 2-3.
	ldab	fmk_tile
	lsrb
	subb	fmk_kind
	aslb
	aslb
	tba
furo_make_06:
	oraa	fmk_red
	staa	0,x
	ldaa	fmk_kind
	staa	1,x
	ldaa	fmk_from
	staa	2,x
; The facts of the furo of each player change only when a furo is made
; (here) or a pon becomes a kan (furo_upgrade); the thinking reads them.
; Counts the new furo of fmk_p and marks the yaku it forbids.
furo_facts:
	ldab	fmk_p
	ldx	#minshun_n
	jsr	addxb
	ldab	fmk_type
	aslb
	aslb
	jsr	addxb
	inc	0,x
	ldaa	fmk_kind
	ldab	fmk_type
	bne	furo_facts_00
	; A chi has a terminal only when it is 123 or 789.
	jsr	kind_number
	cmpa	#1
	beq	furo_facts_01
	cmpa	#7
	beq	furo_facts_01
	bra	furo_facts_02
furo_facts_00:
	jsr	is_yaochu
	bne	furo_facts_01
furo_facts_02:
	ldaa	#FURO_NO_CHANTA
	bra	furo_facts_03
furo_facts_01:
	ldaa	#FURO_NO_TANYAO
furo_facts_03:
	psha
	ldab	fmk_p
	ldx	#furo_attr
	jsr	addxb
	pula
	oraa	0,x
	staa	0,x
	rts

; Returns X = &minshun_n[ai_player]; the other facts are at fixed offsets.
ai_furo_x:
	ldab	ai_player
	ldx	#minshun_n
	jmp	addxb

; B = kind. Removes a tile of the kind from the hand of fmk_p, the red five
; first, and notes it.
fmk_take:
	pshb
	jsr	unshown_kind
	pulb
	ldaa	fmk_p
	jsr	player
	pshb
	jsr	addxb
	pulb
	aslb
	tst	0,x
	bpl	fmk_take_00
	incb
fmk_take_00:
	pshb
	jsr	hand_remove
	pulb
; B = tile of the furo. Notes the place of a red five, then moves to the
; next place.
fmk_note:
	pshb
	lsrb
	bcc	fmk_note_02
	ldaa	fmk_type
	bne	fmk_note_00
	subb	fmk_kind
	bra	fmk_note_01
fmk_note_00:
	ldab	fmk_j
fmk_note_01:
	aslb
	aslb
	aslb
	aslb
	orab	#$80
	stab	fmk_red
fmk_note_02:
	inc	fmk_j
	pulb
	rts

; A = player, B = kind of a pon of the player and of one tile in the hand.
; Turns the pon into an open kan with that tile (place 3).
furo_upgrade:
	psha
	pshb
	jsr	unshown_kind
	; The minkou becomes a minkan.
	tsx
	ldab	1,x
	ldx	#minkou_n
	jsr	addxb
	dec	0,x
	inc	minkan_n-minkou_n,x
	pulb
	pula
	jsr	furo_find_pon
	stx	fup_x
	ldab	fp_k
	jsr	hand_pick
	pshb
	jsr	hand_remove
	pulb
	ldx	fup_x
	ldaa	0,x
	anda	#$F0
	oraa	#M_MINKAN
	lsrb
	bcc	furo_upgrade_00
	oraa	#$B0
furo_upgrade_00:
	staa	0,x
	rts

; A = player, B = kind. Returns X = the player's pon of the kind, or X = 0.
; Keeps A.
furo_find_pon:
	stab	fp_k
	jsr	player
	ldab	P_NFURO,x
	beq	furo_find_pon_02
	stab	fp_n
	ldab	#P_FURO
	jsr	addxb
furo_find_pon_00:
	ldab	0,x
	andb	#3
	cmpb	#M_PON
	bne	furo_find_pon_01
	ldab	1,x
	cmpb	fp_k
	beq	furo_find_pon_03
furo_find_pon_01:
	inx
	inx
	inx
	dec	fp_n
	bne	furo_find_pon_00
furo_find_pon_02:
	ldx	#0
furo_find_pon_03:
	rts

; unshown[k] = tiles of kind k not yet shown on the table: 4 less the rivers,
; the furo (a called tile counts once, when discarded) and the dora
; indicators. Updated when a tile is shown; ai_unseen reads it. It is
; allocated next to counts in ai.asm.
unshown_init:
	clr	kokushi_dead
	ldx	#unshown
	ldaa	#4
unshown_init_00:
	staa	0,x
	inx
	cpx	#unshown+KN
	bne	unshown_init_00
	; Kinds 0, 10, 20 and 30 are not tiles.
	clr	unshown
	clr	unshown+10
	clr	unshown+20
	clr	unshown+30
	bra	unshown_dora

; Opens one more dora indicator and draws it.
dora_open:
	inc	dora_cnt
	jsr	unshown_dora
	jmp	ui_header

; The newest dora indicator (dora_cnt - 1) is shown, and its dora kind is
; counted in dora_of_kind.
unshown_dora:
	ldab	dora_cnt
	decb
	aslb
	negb
	addb	#DORA_POS
	jsr	wall_x
	ldab	0,x
	pshb
	tba
	jsr	dora_next
	tab
	jsr	dora_x
	inc	0,x
	pulb
; B = tile. One more tile of its kind is shown.
unshown_tile:
	lsrb
; B = kind. One more tile of the kind is shown. When the last tile of a
; yaochu kind is shown, nobody can make kokushi any more.
unshown_kind:
	pshb
	ldx	#unshown
	jsr	addxb
	pulb
	dec	0,x
	bne	unshown_kind_00
	tba
	jsr	is_yaochu
	beq	unshown_kind_00
	staa	kokushi_dead
unshown_kind_00:
	rts

; ---------------------------------------------------------------- drawing

; Removes the riichi and kan hints, the call letters beside the latest
; discard and the action letters of the own hand.
clear_letters:
 jsr hide_riichi
 jsr hint_clear
 tst let_n
 beq clear_letters_00
 ldaa own_hint_x
 staa sm_x
 ldaa own_hint_y
 staa sm_y
 ; act_ron and act_tsumo are three characters.
 ldaa #24
 staa ui_width
 ldaa #8
 jsr ui_erase_px
 clr let_n
clear_letters_00:
 rts
; Shows an action string (X; add_tsumo_act shows tsumo) in the own hint row.
add_tsumo_act:
 ldx #act_tsumo
add_action:
 stx own_hint_str
 cpx #act_ron
 beq add_action_01
 ldaa players+P_LEN
 deca
 staa ot_i
 clr ht_p
 ldab players+P_LEN
 stab ht_n
 jsr hand_tile_x
 ldaa posx
 adda #2
 cmpa #28
 bls add_action_00
 ldaa #28
add_action_00:
 asla
 asla
 asla
 staa own_hint_x
 ldaa #20*8
 bra add_action_02
add_action_01:
 jsr hint_start
 ldaa hint_origin
 staa own_hint_x
 ldaa hint_y
add_action_02:
 staa own_hint_y
 ldab own_hint_x
 ldx own_hint_str
 jsr ui_glyphs_px
 inc let_n
 rts

; Shows R:ロン and waits. Returns A nonzero for ron (R), 0 for pass (space).
ask_ron:
	ldx	#snd_select
	jsr	play
	jsr	clear_letters
	ldx	#act_ron
	jsr	add_action
ask_ron_00:
	jsr	frame
	ldaa	knew
	anda	#KEY_R+KEY_SPACE
	beq	ask_ron_00
	anda	#KEY_R
	psha
	jsr	clear_letters
	pula
	rts

	.bss
; dora_cnt is allocated in directpage.asm.
kans_done:	.ds	1 ; kans in this hand
rinshan:	.ds	1 ; nonzero after a kan draw
pending_dora:	.ds	1 ; kan dora to open after the discard
; Cleared at the start of a hand from river_bits to furo_facts_end.
river_bits:	.ds	KN ; bit p: the kind passed after the riichi of player p; bit p+4: player p discarded it
rp_bits:	.ds	1 ; react_stick: riichi players
dora_of_kind:	.ds	KN ; open dora indicators that point to each kind (unshown_dora)
; Facts of the furo of each player (index = player), in this order:
; ai_furo_x and furo_upgrade read them as offsets from minshun_n.
minshun_n:	.ds	4 ; minshun (chi)
minkou_n:	.ds	4 ; minkou (pon)
minkan_n:	.ds	4 ; minkan (open kan, added kan included)
ankan_n:	.ds	4 ; ankan (closed kan)
furo_attr:	.ds	4 ; FURO_NO_CHANTA, FURO_NO_TANYAO
intent_lock:	.ds	4 ; set_intents: bit 6 toitoi
fold_bits:	.ds	1 ; bit of each player whose last ai_discard folded (ai.asm)
furo_facts_end:
kokushi_dead:	.ds	1 ; nonzero when a yaochu kind is all shown (no kokushi for anyone)
chankan_f:	.ds	1 ; nonzero for chankan
decl:	.ds	1 ; 1 for a riichi declaration
; other is allocated in directpage.asm.
can_ron:	.ds	1 ; nonzero when ron is possible
can_riichi:	.ds	1 ; nonzero when the human may riichi
riichi_mode:	.ds	1 ; nonzero while choosing the riichi discard
; react_act is allocated in directpage.asm.
; react_pat is allocated in directpage.asm.
kan_n:	.ds	1 ; kan options
kan_k:	.ds	4 ; their kinds
; ko_k is allocated in directpage.asm.
; kk2 is allocated in directpage.asm.
ra_player:	.ds	1 ; player ron_ok checks
rn_n:	.ds	1 ; river tiles left (ron_ok)
rn_x:	.ds	2 ; next river tile
rp_pon:	.ds	1 ; pon possible
rp_kan:	.ds	1 ; open kan possible
; rp_chi is allocated in directpage.asm.
; ck_b is allocated in directpage.asm.
; cop_t is allocated in directpage.asm.
; cop_pat is allocated in directpage.asm.
ku_ok:	.ds	1 ; kuikae_ok result
; dcl_kind is allocated in directpage.asm.
; fmk_type is allocated in directpage.asm.
fmk_from:	.ds	1 ; player called from
fmk_tile:	.ds	1 ; called tile ($FF for a closed kan)
fmk_p:	.ds	1 ; player of furo_make
; fmk_k is allocated in directpage.asm.
fmk_n:	.ds	1 ; tiles left to take
fmk_j:	.ds	1 ; place in the furo
fmk_red:	.ds	1 ; place of the red five
fup_x:	.ds	2 ; pon being upgraded
fp_k:	.ds	1 ; kind furo_find_pon looks for
fp_n:	.ds	1 ; furo left
cp_k:	.ds	1 ; kind cp_position looks for
df_n:	.ds	1 ; furo left
df_i:	.ds	1 ; furo index
; df_j is allocated in directpage.asm.
df_cx:	.ds	1 ; x of the first furo
rr_p:	.ds	1 ; river player
rr_k:	.ds	1 ; river index
dd_i:	.ds	1 ; dora indicator index
dd_first:	.ds	1 ; wall position of the first indicator drawn
let_n:	.ds	1 ; nonzero while the action letters are shown

	.code
; Clears the state of dora, calls, riichi and kans at the start of a hand.
kyoku_init_calls:
	ldx	#river_bits
kyoku_init_calls_00:
	clr	0,x
	inx
	cpx	#furo_facts_end
	bne	kyoku_init_calls_00
	ldaa	#1
	staa	dora_cnt
	jsr	clear_kk
	staa	cursor
	clr	kans_done
	clr	rinshan
	clr	pending_dora
	clr	chankan_f
	clr	decl
	rts

	.bss
chi_mode:	.ds	1 ; nonzero while choosing a chi
; chi_pat is allocated in directpage.asm.
chi_key:	.ds	1 ; last chi key
chi_i1:	.ds	1 ; hand position of the first chi tile
chi_i2:	.ds	1 ; hand position of the second chi tile

riichi_reject:	.ds	1 ; nonzero after R was pressed when riichi is not allowed
abort_reason:	.ds	1 ; ABORT_* pending after the discard ($FF = none)

; discarder is allocated in directpage.asm.
react_phase:	.ds	1 ; 0 ron, 1 calls
react_human:	.ds	1 ; human answer ($FF = ask)
react_hpat:	.ds	1 ; human chi pattern
react_count:	.ds	1 ; players asked so far
react_choice:	.ds	1 ; nonzero once a call is chosen
react_winner:	.ds	1 ; player of the chosen call
react_pattern:	.ds	1 ; chi pattern of the call
react_ron_n:	.ds	1 ; players who ron
react_ron_first:	.ds	1 ; first of them from the discarder
react_hum_ron:	.ds	1 ; human can ron: 1 first, 2 after a CPU ron
call_player:	.ds	1 ; player call_options checks
auto_play:	.ds	1 ; nonzero when every player is a CPU

ri_player: .ds 1 ; player riichi_ok checks
ri_kind: .ds 1 ; kind tried

 .code
; Shows the riichi hint (show_kan_hint: the kan hint).
show_riichi_hint:
 ldx #act_riichi
 ldaa #19
 bra show_own_hint
show_kan_hint:
 ldx #act_kan
 ldaa #19
 tst riichi_hint_live
 beq show_own_hint
 deca
show_own_hint:
 staa posy
 ldaa #27
 staa riichi_hint_x
 staa posx
 jsr drawstr
 ldaa #1
 staa riichi_hint_live
 rts
; Removes the riichi hint.
hide_riichi:
 tst riichi_hint_live
 beq hide_riichi_00
 ldaa riichi_hint_x
 staa posx
 ldaa #18
 staa posy
 ldaa #4
 ldab #2
 jsr erase
 clr riichi_hint_live
hide_riichi_00:
 rts
 .bss
riichi_hint_x: .ds 1 ; x of the riichi hint
riichi_hint_live: .ds 1 ; nonzero while the hint is shown

own_hint_x: .ds 1 ; pixel column of the own hint
own_hint_y: .ds 1 ; pixel row of the own hint
own_hint_str: .ds 2 ; own hint string
 .code
