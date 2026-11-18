	.setcpu	6800

VRAMHI	.equ	$09
TEXTHI	.equ	$01
COLORREG	.equ	$E890
MP1710	.equ	$E892
SCRMODE	.equ	$EFE0
KEYPORT	.equ	$EEC0

ATTR_TEXT	.equ	$07
IMG_BACK	.equ	37
LIVE_DRAWS	.equ	70
DORA_POS	.equ	130

ROW_OPP_HAND	.equ	0
ROW_OPP_RIVER	.equ	3
ROW_INFO	.equ	9
ROW_OWN_RIVER	.equ	14
ROW_OWN_HAND	.equ	21
ROW_ARROW	.equ	23

KEY_Z	.equ	$01
KEY_X	.equ	$02
KEY_SPACE	.equ	$04
KEY_T	.equ	$08
KEY_R	.equ	$10
KEY_K	.equ	$20
KEY_P	.equ	$40
KEY_C	.equ	$80

; Kinds: suit * 10 + rank (1m..9m = 1..9, 1p..9p = 11..19, 1s..9s = 21..29),
; honors 31..37 (E S W N, haku hatsu chun). Kinds 0, 10, 20 and 30 are not
; tiles: every array indexed by kind holds 0 there, so a sequence or
; neighbour lookup cannot cross a suit. A tile is kind*2, plus 1 for a red five.
K_FIRST .equ 1
K_FIVE_M .equ 5
K_FIVE_P .equ 15
K_FIVE_S .equ 25
K_EAST .equ 31
K_NORTH .equ 34
K_HAKU .equ 35
K_HATSU .equ 36
K_CHUN .equ 37
K_HONOR	.equ	K_EAST
K_END .equ 38
KN .equ 38

; Player area.
P_COUNT	.equ	0
P_LEN	.equ	KN
P_DRAWN	.equ	KN+1
P_NFURO	.equ	KN+2
P_FURO	.equ	KN+3
P_RLEN	.equ	KN+15
P_RIVER	.equ	KN+16
P_RFLAG	.equ	KN+48
P_FLAG	.equ	KN+80
P_SCORE	.equ	KN+81
PSIZE	.equ	KN+83

; Bits of P_FLAG. The bits that score_hand needs have the values of F_*.
P_RIICHI	.equ	$80
P_FIRST	.equ	$40
P_IPPATSU	.equ	$04
P_DOUBLE	.equ	$02
P_SKIP	.equ	$01

	.code
start:
	bra	start_00
; greedy reads gd_transitions and kattr_x reads kattr with a one-byte
; offset, so the tables must not cross a page. Here, right after the entry at
; $4000, they do not move.
gd_transitions:
 .byte 0,8,1,9,2,0,0,0,16,1,9,2,10,0,0,0,0,1,9,2,10
; Kind attributes: A_YAOCHU, A_HONOR, A_GREEN, A_KIND (0 for the empty
; kinds between the suits and the honors) and the suit.
kattr:
 .byte 0,25,24,24,24,24,24,24,24,25
 .byte 0,41,40,40,40,40,40,40,40,41
 .byte 0,73,76,76,76,72,76,72,76,73
 .byte 0,11,11,11,11,11,15,11
start_00:
	lds	#$3FFF
	cli
	ldx	#bss_start
clear_bss:
	clr	0,x
	inx
	cpx	#bss_all_end
	bne	clear_bss
	ldx #DP_FIRST
clear_directpage:
	clr 0,x
	inx
	cpx #DP_END
	bne clear_directpage
	ldaa	#1
	staa	MP1710
	ldaa	#$C0
	staa	SCRMODE
	ldaa	$0A
	eora	#$9E
	staa	seed
	ldaa	$0B
	eora	#$37
	staa	seed+1
	ldaa	$0C
	eora	#$79
	oraa	#1
	staa	seed+2
	ldaa	#$FF
	staa	cursor

; Title screen. Waits for space and starts a title_wait_00.
title:
	clr	game_active
	clr	auto_play
	clr	demo
	; demo_poll may leave ev1_discard in the middle.
	clr	spec_off
	jsr	draw_title
title_wait_03:
	ldaa	$0B
	staa	title_sec
title_wait:
	jsr	scan_keys
	jsr	rand
	ldaa	knew
	bita	#KEY_SPACE
	bne	title_wait_00
	tsta
	bne	title_wait_03
	; D (column 2, bit 1), or 30 seconds without a key, starts a demo game of
	; four CPU players.
	ldaa	$0B
	suba	title_sec
	cmpa	#30
	bcc	title_wait_02
	ldaa	#2
	staa	KEYPORT
	ldaa	KEYPORT
	bita	#$02
	bne	title_wait
title_wait_02:
	inc	auto_play
	inc	demo
title_wait_00:
	clra
title_wait_01:
	jsr	player
	ldab	#>250
	stab	P_SCORE,x
	ldab	#<250
	stab	P_SCORE+1,x
	inca
	cmpa	#4
	bne	title_wait_01
	clr	round
	clr	honba
	clr	kyotaku
	jsr	rand
	anda	#3
	staa	dealer

; Starts a hand: shuffles, deals and plays it.
kyoku:
	clr	result_active
	ldaa	#1
	staa	game_active
	jsr	kyoku_init_calls
	jsr	clear_screen
	jsr	shuffle
	jsr	unshown_init
	clr	wallpos
	ldaa	#LIVE_DRAWS
	staa	draws_left
	clra
kyoku_00:
	jsr	player
	ldab	#P_SCORE
kyoku_01:
	clr	0,x
	inx
	decb
	bne	kyoku_01
	jsr	player
	ldab	#$FF
	stab	P_DRAWN,x
	inca
	cmpa	#4
	bne	kyoku_00
	ldaa	#13
	staa	deal_cnt
kyoku_02:
	clr	deal_player
kyoku_03:
	jsr	wall_next
	ldaa	deal_player
	jsr	hand_add
	inc	deal_player
	ldaa	deal_player
	cmpa	#4
	bne	kyoku_03
	dec	deal_cnt
	bne	kyoku_02
	clr	deal_player
kyoku_04:
	ldaa	deal_player
	jsr	draw_hand
	inc	deal_player
	ldaa	deal_player
	cmpa	#4
	bne	kyoku_04

	jsr	draw_info
	ldaa	dealer
	staa	turn
	ldaa	#P_FIRST
	staa	players+P_FLAG
	staa	players+PSIZE+P_FLAG
	staa	players+PSIZE*2+P_FLAG
	staa	players+PSIZE*3+P_FLAG
	jmp	turn_loop


; Player other won with the discarded tile dc_tile and becomes the player
; in turn.
win_ron:
 ldaa other
 staa turn
	ldx	#s_ron
	bra	win_show

; The player in turn won by tsumo.
win_tsumo:
	ldx	#s_tsumo
win_show:
	stx	win_text
	ldx	#snd_ron
	tst	tsumo_flag
	beq	win_tsumo_00
	ldx	#snd_tsumo
win_tsumo_00:
	jsr	play
	tst	demo
	beq	win_tsumo_24
	jsr	reveal_hands
	bra	win_tsumo_25
win_tsumo_24:
	jsr	ui_win_reveal
win_tsumo_25:
	; The existing river ▲ already identifies the ron tile. Keep it in place.
	tst	tsumo_flag
	beq	win_tsumo_20
	; Keep the ▲ source cue on the winning player's drawn tile.
	jsr mark_clear
	jsr ui_mark_tsumo
win_tsumo_20:
	clr	reveal
	ldaa	turn
	oraa	demo
	beq	win_tsumo_21
	jsr	wait_space
win_tsumo_21:
	jsr	show_result
	jsr	ui_winning_hand
	jsr	save_scores
	jsr	settle_win

	clr	kyotaku
	jsr	wait_space
	jsr	show_win_scores
	jsr	wait_space
	jsr	tobi
	bne	win_game_end
	ldaa	turn
	cmpa	dealer
	beq	win_tsumo_22
	clr	honba
	jmp	rotate
win_tsumo_22:
	ldaa	round
	cmpa	#7
	bne	win_tsumo_23
	jsr	dealer_top
	bne	win_game_end
win_tsumo_23:
	inc	honba
	jmp	kyoku
win_game_end:
	jmp	game_end

; Sounds snd_select twice with a gap, for a draw.
draw_sound:
	ldx	#snd_select
	jsr	play
	ldaa	#5
	jsr	wait_frames
	ldx	#snd_select
	jsr	play
	rts

; A = ABORT_*. Shows the hands and the reason; no payment. The dealer
; stays, one more honba, and the riichi sticks stay on the table.
abortive_draw:
	staa	abort_reason
	clr	game_active
	tst	demo
	beq	abortive_draw_00
	jsr	reveal_hands
	bra	abortive_draw_01
abortive_draw_00:
	jsr	redraw_hands
abortive_draw_01:
	clr	posx
	clr	posy
	ldaa	#22
	jsr	erase1
	ldaa	abort_reason
	asla
	tab
	ldx	#abort_names
	jsr	addxb
	jsr	drawstr_x
	ldaa	#27
	staa	posx
	ldaa	#1
	staa	posy
	ldx	#s_push
	jsr	drawstr
	jsr	draw_sound
	jsr	wait_space
	inc	honba
	jmp	kyoku
abort_names:
	.word	s_kyuushu,s_suufon,s_suucha,s_suukaikan,s_sancha

; Exhaustive draw: settles the tenpai payments and shows the hands.
ryukyoku:
	jsr	save_scores
	jsr	settle_draw
	jsr	reveal_hands
	jsr	show_draw
	jsr	draw_sound
	jsr	wait_space
	jsr	tobi
	bne	win_game_end
	inc	honba
	ldab	dealer
	jsr	bits4_x
	ldaa	0,x
	anda	ry_tenpai
	beq	rotate
	jmp	kyoku
; Moves the deal to the next player; the game ends after round 7.
rotate:
	ldaa	dealer
	inca
	anda	#3
	staa	dealer
	inc	round
	ldaa	round
	cmpa	#8
	bne	rotate_00
	jmp	game_end
rotate_00:
	jmp	kyoku

; Returns A = 1 if a player has a score below zero.
; Returns with N and Z set from A.
tobi:
	clra
tobi_00:
	jsr	player
	tst	P_SCORE,x
	bmi	tobi_01
	inca
	cmpa	#4
	bne	tobi_00
	clra
	rts
tobi_01:
	ldaa	#1
	rts

; Returns A = 1 if the dealer is strictly ahead of every other player.
; Returns with N and Z set from A.
dealer_top:
	ldaa	dealer
	jsr	player
	ldaa	P_SCORE,x
	ldab	P_SCORE+1,x
	staa	ry_v
	stab	ry_v+1
	clr	loop_p
dealer_top_00:
	ldaa	loop_p
	cmpa	dealer
	beq	dealer_top_01
	jsr	player
	ldab	ry_v+1
	subb	P_SCORE+1,x
	ldaa	ry_v
	sbca	P_SCORE,x
	bmi	dealer_top_02
	bne	dealer_top_01
	tstb
	beq	dealer_top_02
dealer_top_01:
	inc	loop_p
	ldaa	loop_p
	cmpa	#4
	bne	dealer_top_00
	ldaa	#1
	rts
dealer_top_02:
	clra
	rts


; A = player, B = 1 for ron with dc_tile, 0 for tsumo with the drawn tile.
; Returns A = 1 if the player can win (winning shape with yaku).
; Leaves the result in best_*.
; Returns with N and Z set from A.
check_win:
	staa	cw_p
	stab	cw_ron
	jsr	eval_load
	ldaa	dc_tile
	tst	cw_ron
	bne	check_win_00
	ldaa	cw_p
	jsr	player
	ldaa	P_DRAWN,x
check_win_00:
	staa	win_tile
	lsra
	staa	win_kind
	tst	cw_ron
	beq	check_win_01
	ldab	win_kind
	jsr	counts_x
	inc	0,x
check_win_01:
	jsr	is_agari
	beq	check_win_02
	jsr	setup_score
	jsr	score_hand
	ldaa	best_pts
	oraa	best_pts+1
	beq	check_win_02
	ldaa	#1
	rts
check_win_02:
	clra
	rts

; Sets the inputs of score_hand for player cw_p.
setup_score:
	jsr	setup_place
; Sets the inputs that depend on how the hand is won: sflags and ura_n.
setup_win:
	ldaa	cw_p
	jsr	player
	ldaa	P_FLAG,x
	anda	#F_RIICHI+F_DOUBLE+F_IPPATSU+F_FIRST
	tst	draws_left
	bne	setup_flags
	oraa	#F_LAST
setup_flags:
	staa	sflags
setup_special:
	ldx	#rinshan
	tst	cw_ron
	beq	setup_rinshan
	ldx	#chankan_f
	ldaa	#F_CHANKAN
	bra	setup_win_00
setup_rinshan:
	ldaa	#F_RINSHAN
setup_win_00:
	jsr	ss_flag_if
	clr	ura_n
	tst	sflags
	bpl	setup_win_11
	clr	ss_i
setup_win_10:
	ldaa	#DORA_POS
	suba	ss_i
	suba	ss_i
	tab
	jsr	wall_x
	ldaa	1,x
 jsr dora_next
	jsr	ss_count
	adda	ura_n
	staa	ura_n
	inc	ss_i
	ldaa	ss_i
	cmpa	dora_cnt
	bne	setup_win_10
setup_win_11:
	rts

; Sets the inputs of score_hand that do not depend on how the hand is won
; (sflags and ura_n are left to setup_win or to the caller).
setup_place:
	ldaa	cw_ron
	eora	#1
	staa	tsumo_flag
	clr	dealer_flag
	ldaa	cw_p
 jsr winds_of
	staa	round_kind
 stab seat_kind
	ldaa	cw_p
	cmpa	dealer
	bne	setup_dora
	inc	dealer_flag
setup_dora:
	clr	dora_n
	clr	ss_i
setup_dk:
 ldab ss_i
 jsr dora_kind_at
	jsr	ss_count
	adda	dora_n
	staa	dora_n
	inc	ss_i
	ldaa	ss_i
	cmpa	dora_cnt
	bne	setup_dk
setup_aka:
	clr	aka_n
	tst	cw_ron
	beq	setup_hand_red
	ldaa	win_tile
	lsra
	bcc	setup_hand_red
	inc	aka_n
setup_hand_red:
	ldaa	cw_p
	jsr	player
	tst	P_COUNT+K_FIVE_M,x
	bpl	setup_red_p
	inc	aka_n
setup_red_p:
	tst	P_COUNT+K_FIVE_P,x
	bpl	setup_red_s
	inc	aka_n
setup_red_s:
	tst	P_COUNT+K_FIVE_S,x
	bpl	ss_furo
	inc	aka_n
; The furo are the first blocks of score_hand.
ss_furo:
	ldaa	#1
	staa	closed_flag
	clr	nkan
	clr	ss_i
ss_furo_00:
	ldab	ss_i
	cmpb	nfuro
	beq	ss_furo_06
	ldaa	P_FURO,x
	bpl	ss_furo_01
	inc	aka_n
ss_furo_01:
	anda	#3
	ldab	#B_OPEN
	cmpa	#M_ANKAN
	bne	ss_furo_02
	clrb
ss_furo_02:
	cmpa	#M_MINKAN
	bcs	ss_furo_03
	orab	#B_KAN
	inc	nkan
ss_furo_03:
	tsta
	bne	ss_furo_04
	orab	#B_SEQ
ss_furo_04:
	bitb	#B_OPEN
	beq	ss_furo_05
	clr	closed_flag
ss_furo_05:
	tba
	ldab	P_FURO+1,x
	inx
	inx
	inx
	stx	ss_p
	pshb
	ldab	ss_i
	jsr	btype_x
	pulb
	staa	0,x
	stab	bkind-btype,x
	ldx	ss_p
	inc	ss_i
	bra	ss_furo_00
ss_furo_06:
	rts

; A = kind. Returns A = tiles of that kind in the hand and the furo.
ss_count:
	tab
	jsr	counts_x
	ldaa	0,x
	adda	furo_tiles-counts,x
	rts

; X = flag byte, A = F_*. Sets A in sflags if the byte is not 0.
ss_flag_if:
	tst	0,x
	beq	ss_flag_if_00
	oraa	sflags
	staa	sflags
ss_flag_if_00:
	rts

; B = indicator index (0..4); returns A = dora kind. B and X are scratch.
dora_kind_at:
 aslb
 negb
 addb #DORA_POS
 jsr wall_x
 ; Fall through with X pointing to the indicator.

; X = &indicator tile (dora_next_x) or A = indicator tile (dora_next).
; Returns A = dora kind.
dora_next_x:
 ldaa 0,x
dora_next:
 lsra
 cmpa #K_HONOR
 bcc dora_next_01
 psha
 jsr kind_number
 cmpa #9
 pula
 beq dora_next_00
 inca
 rts
dora_next_00:
 suba #8
 rts
dora_next_01:
 cmpa #K_NORTH
 beq dora_next_02
 cmpa #K_CHUN
 beq dora_next_03
 inca
 rts
dora_next_02:
 ldaa #K_EAST
 rts
dora_next_03:
 ldaa #K_HAKU
 rts

; A = player. Returns A = the round wind kind, B = the seat wind kind of
; the player.
winds_of:
	suba	dealer
	anda	#3
	tab
	ldx	#wind_kinds
	jsr	addxb
	ldab	0,x
	ldaa	round
	cmpa	#4
	ldaa	#K_EAST
	bcs	winds_of_00
	inca
winds_of_00:
	rts
wind_kinds:
	.byte	K_EAST,K_EAST+1,K_EAST+2,K_NORTH

; Dedicated result page: winner header, indicators, yaku, points and large hand.
show_result:
	clr	game_active
	inc	result_active
	jsr	clear_screen
	ldaa	#2
	staa	posx
	clr	posy
	ldaa	turn
	jsr	draw_name
	tst	turn
	beq	show_result_01
	inc	posx
show_result_01:
	inc	posx
	ldaa	turn
 jsr draw_wind_for_player
	inc	posx
	ldx	win_text
	jsr	drawstr
	jsr	ui_header_dora
 jsr turn_player
	tst	P_FLAG,x
	bpl	show_result_02
	ldaa	#22
	staa	posx
	ldaa	#2
	staa	posy
	ldx	#s_ura
	jsr	drawstr
	ldaa	#1
	staa	dd_off
	ldaa	#2
	ldab	#24
	jsr	ui_indicators
show_result_02:
	clr	sr_i
	ldaa	#2
	staa	sr_row
show_result_03:
	ldaa	sr_i
	cmpa	best_n
	beq	show_result_05
	ldab	sr_i
	jsr	best_y_x
	ldaa	0,x
	staa	sr_id
	ldaa	#4
	staa	posx
	ldaa	sr_row
	staa	posy
	; Skip sr_id names of yaku_text.
	ldab	sr_id
	ldx	#yaku_text
	bra	show_result_10
show_result_09:
	ldaa	0,x
	inx
	bpl	show_result_09
show_result_10:
	decb
	bpl	show_result_09
	jsr	drawstr
	ldaa	#17
	staa	posx
	jsr	yaku_han_of
	beq	show_result_04
 jsr print_a2
	ldx	#s_han
	jsr	drawstr
show_result_04:
	inc	sr_row
	inc	sr_i
	bra	show_result_03
show_result_05:
	ldaa	#4
	staa	posx
	ldaa	#15
	staa	posy
	ldx	#s_ko
	tst	dealer_flag
	beq	show_result_06
	dec	posx
	ldx	#s_oya
show_result_06:
	jsr	drawstr
	ldaa	#5
	staa	posx
	ldaa best_fu
 beq show_result_07
	ldab	#3
	jsr	print_byte_num
	ldx	#s_fu
	jsr	drawstr
	ldaa best_han
 ldab #3
 jsr print_byte_num
	ldx	#s_han
	jsr	drawstr
	inc	posx
show_result_07:
	ldaa honba
 ldab #3
 jsr print_byte_num
	ldx	#s_honba
	jsr	drawstr
	inc	posx
	jsr	limit_name
	cpx	#0
	beq	show_result_08
	jsr	drawstr
show_result_08:
	ldaa	#18
	staa	posx
	ldaa	#16
	staa	posy
	jmp	print_win_pts

; best_pts includes the riichi pool. Split it only for display.
print_win_pts:
	; Fewer than 26 riichi sticks, so kyotaku*10 fits a byte.
	ldaa	kyotaku
	asla
	asla
	adda	kyotaku
	asla
	staa	wk_num+1
	ldab	best_pts+1
	subb	wk_num+1
	ldaa	best_pts
	sbca	#0
	staa	wk_num
	stab	wk_num+1
	ldx	wk_num
	jsr	print_score
	ldaa	kyotaku
	beq	print_win_pts_01
	ldaa	#CH_PLUS
	jsr	drawchar
	inc	posx
	ldaa	kyotaku
	ldab	#1
	cmpa	#10
	bcs	print_win_pts_00
	incb
	cmpa	#100
	bcs	print_win_pts_00
	incb
print_win_pts_00:
	jsr	print_byte_num
 jsr draw_zero
	inc	posx
	jmp	pscore_zero
print_win_pts_01:
	rts

; Post-win score page, shown after the yaku page and before the next hand.
show_win_scores:
 ldaa #1
 bra score_page
; A = settlement detail flag (1 = win arithmetic, 0 = final scores).
score_page:
 staa result_active
 jsr clear_screen
 ldaa #10
 staa posx
 ldaa #1
 staa posy
 ldx #s_final_scores
 tst result_active
 beq page_header
 ldx #s_win_scores
page_header:
 jsr drawstr
	clr	ui_sp
score_page_00:
	; Rows 6, 9, 12 for players 1..3 and 15 for player 0, as on the table.
	ldaa	ui_sp
	deca
	anda	#3
	tab
	asla
	aba
	adda	#6
	staa	posy
	ldaa	#1
	staa	posx
	ldaa ui_sp
 jsr draw_name
page_wind:
	ldaa	#6
	staa	posx
 jsr draw_seat_wind
	ldaa	ui_sp
	jsr	player
	ldx	P_SCORE,x
	stx	ry_v
	ldaa	#24
	staa	posx
	jsr	print_score
 tst result_active
 beq page_advance
	; Net transfer includes honba and the riichi pool, using the actual scores.
	ldx	#ry_score_before
	ldab	ui_sp
	aslb
	jsr	addxb
	ldab	ry_v+1
	subb	1,x
	ldaa	ry_v
	sbca	0,x
	staa	ry_v
	stab	ry_v+1
	oraa	ry_v+1
	beq	page_advance
	ldaa	#8
	staa	posx
 jsr print_score_x
	ldaa	#15
	staa	posx
	ldaa	ry_v
	bpl	page_gain
	clra
	clrb
	subb	ry_v+1
	sbca	ry_v
	staa	ry_v
	stab	ry_v+1
	ldaa	#CH_MINUS
	bra	page_sign
page_gain:
	ldaa	#CH_PLUS
page_sign:
	psha
	ldaa	#16
	staa	posx
	ldx	ry_v
	jsr	print_score
 ; print_num already left pn_p at the first digit in its four-cell field.
 ldaa pn_p+1
 suba #<pn_buf
 adda #15
 staa posx
	pula
	jsr	drawchar
	ldaa	#23
	staa	posx
	ldx	#s_equal
	jsr	drawstr
page_advance:
	inc	ui_sp
	ldaa	ui_sp
	cmpa	#4
	bne	score_page_00
	ldaa	#27
	staa	posx
	ldaa	#22
	staa	posy
	ldx	#s_push
	jsr	drawstr
	rts

; Draw result over the four revealed hands. Each seat keeps the pre-settlement
; score with its tenpai state and point transfer directly underneath.
show_draw:
	clr	game_active
	ldaa	#2
	staa	result_active
	staa	posx
	clr	posy
	ldx	#s_ryukyoku
	jsr	drawstr
	ldaa	#27
	staa	posx
	ldaa	#1
	staa	posy
	ldx	#s_push
	jsr	drawstr
	clr	loop_p
show_draw_00:
	ldx	#rh_rows
	ldab	loop_p
	jsr	addxb
	ldaa	0,x
	staa	sr_row
	; Show pre-settlement score on the first line, replacing the post-settlement value.
	staa	posy
	ldaa	#26
	staa	posx
	ldx	#ry_score_before
	ldab	loop_p
	aslb
	jsr	addxb
 jsr print_score_x
	; Replace the second line with status and exact point transfer.
	ldaa	sr_row
	inca
	staa	posy
	ldaa	#22
	staa	posx
	ldaa	#10
 jsr erase1
 jsr ry_bits4_x
	ldaa	0,x
	anda	ry_tenpai
	beq	showdraw_noten
	ldx	#s_tenpai
	bra	showdraw_status
showdraw_noten:
	ldx	#s_noten
showdraw_status:
	jsr	drawstr
	ldaa	#CH_SP
	jsr	drawchar
	inc	posx
 ldab loop_p
 jsr noten_delta
 ldaa ry_v
 oraa ry_v+1
 beq showdraw_no_pay
 ldaa ry_v
 bpl showdraw_gain
 ldaa ry_v+1
 nega
 staa ry_v+1
 ldaa #CH_MINUS
 bra showdraw_amount
showdraw_gain:
 ldaa #CH_PLUS
showdraw_amount:
	jsr	drawchar
	inc	posx
	ldaa	ry_v+1
 jsr print_a2
 jsr draw_zero
 jsr next_zero
	bra	show_draw_10
showdraw_no_pay:
 jsr draw_zero
show_draw_10:
	inc	loop_p
	ldaa	loop_p
	cmpa	#4
	bne	show_draw_00
	rts

; Preserve each seat's score immediately before win or draw settlement.
save_scores:
	clr	loop_p
save_scores_00:
	ldaa	loop_p
	jsr	player
	ldx	P_SCORE,x
	stx	ry_v
	ldx	#ry_score_before
	ldab	loop_p
	aslb
	jsr	addxb
	ldaa	ry_v
	staa	0,x
	ldaa	ry_v+1
	staa	1,x
	inc	loop_p
	ldaa	loop_p
	cmpa	#4
	bne	save_scores_00
	rts

; Reveal all four hands in place. Keep the table, rivers and header intact.
reveal_hands:
	ldaa	#2
	staa	reveal
	jsr	draw_hands
	clr	reveal
	rts

; Redraw the hands without forcing the current CPU hand open.
redraw_hands:
	clr	reveal
draw_hands:
	ldaa	#1
	staa	ui_refresh
	clr	loop_p
draw_hands_00:
	ldaa	loop_p
	jsr	draw_hand
	inc	loop_p
	ldaa	loop_p
	cmpa	#4
	bne	draw_hands_00
	clr	ui_refresh
	rts
rh_rows:
	.byte	16,2,7,12

; Returns A = han shown for yaku sr_id (0 for yakuman).
; Returns with N and Z set from A.
yaku_han_of:
	ldaa	sr_id
	cmpa	#Y_DORA
	bcs	yaku_han_of_03
	bne	yaku_han_of_00
	ldaa	dora_n
	rts
yaku_han_of_00:
	cmpa	#Y_AKA
	bne	yaku_han_of_01
	ldaa	aka_n
	rts
yaku_han_of_01:
	cmpa	#Y_URA
	bne	yaku_han_of_02
	ldaa	ura_n
	rts
yaku_han_of_02:
	clra
	rts
yaku_han_of_03:
 jmp reg_yaku_han

; Returns X = name of the limit of best_* (0 if none).
limit_name:
	tst	best_fu
	bne	limit_name_00
	ldx	#s_yakuman
	ldaa	best_han
	cmpa	#26
	bcs	limit_name_02
	ldx	#s_double
	cmpa	#39
	bcs	limit_name_02
	ldx	#s_triple
	rts
limit_name_00:
	ldaa	best_han
	ldx	#s_kazoe
	cmpa	#13
	bcc	limit_name_02
	ldx	#s_sanbaiman
	cmpa	#11
	bcc	limit_name_02
	ldx	#s_baiman
	cmpa	#8
	bcc	limit_name_02
	ldx	#s_haneman
	cmpa	#6
	bcc	limit_name_02
	ldx	#s_mangan
	cmpa	#5
	bcc	limit_name_02
 jsr fi_limit_han
	ldx	#s_mangan
	ldaa	fi_basic
	cmpa	#>2000
	bne	limit_name_01
	ldaa	fi_basic+1
	cmpa	#<2000
	beq	limit_name_02
limit_name_01:
	ldx	#0
limit_name_02:
	rts

; A = player. Loads the hand into counts, the tiles of the furo into
; furo_tiles and the number of furo into nfuro. Keeps A.
turn_eval_load:
 ldaa turn
eval_load:
	psha
	jsr	player
	ldab	P_NFURO,x
	stab	nfuro
	stx	el_src
	ldx	#counts
eval_load_00:
	stx	el_dst
	ldx	el_src
	ldaa	0,x
	inx
	stx	el_src
	ldx	el_dst
	anda	#7
	staa	0,x
	clr	furo_tiles-counts,x
	inx
	cpx	#counts+KN
	bne	eval_load_00
	pula
	ldx	#furo_tiles

; A = player, X = array indexed by kind. Adds the tiles of the player's
; furo to the array. Keeps A.
furo_counts:
	psha
	stx	fcn_dst
	jsr	player
	ldab	P_NFURO,x
	beq	furo_counts_04
	stab	fcn_n
furo_counts_00:
	stx	fcn_src
	ldaa	P_FURO,x
	ldab	P_FURO+1,x
	ldx	fcn_dst
	jsr	addxb
	anda	#3
	bne	furo_counts_01
	inc	0,x
	inc	1,x
	inc	2,x
	bra	furo_counts_03
furo_counts_01:
	ldab	#3
	cmpa	#M_PON
	beq	furo_counts_02
	incb
furo_counts_02:
	addb	0,x
	stab	0,x
furo_counts_03:
	ldx	fcn_src
	inx
	inx
	inx
	dec	fcn_n
	bne	furo_counts_00
furo_counts_04:
	pula
	rts

; Ends the title_wait_00 and shows the final scores.
game_end:
 clr game_active
 ldaa result_active
 beq game_end_01
 ldab #17
 cmpa #2
 bne game_end_00
 ldab #20
game_end_00:
 stab posy
 ldaa #24
 staa posx
 bra game_end_02
game_end_01:
 jsr draw_info
 ldaa #11
 staa posx
 ldaa #ROW_INFO+2
 staa posy
 ldaa #21
 jsr erase1
game_end_02:
 ldx #s_end
 jsr drawstr
 jsr wait_space
 jmp final_scores

; Returns B = the next live tile of the wall.
wall_next:
	ldab	wallpos
	jsr	wall_x
	ldab	0,x
	inc	wallpos
	rts

; A = player. Returns X = the player's area. Keeps A and B.
turn_player:
 ldaa turn
player:
	pshb
	tab
	aslb
	ldx	#player_base
	jsr	addxb
	ldx	0,x
	pulb
	rts
player_base:
	.word	players,players+PSIZE,players+PSIZE*2,players+PSIZE*3

; The hand is P_COUNT (tiles of each kind, bit 7 set while the red five is
; held), P_LEN and P_DRAWN. Only the functions below change them.

; A = player, B = tile. Adds the tile to the hand; hand_draw also makes it
; the drawn tile. Keeps A.
hand_draw:
	jsr	player
	stab	P_DRAWN,x
	bra	hand_add_go
hand_add:
	jsr	player
hand_add_go:
	inc	P_LEN,x
	lsrb
	bcs	hand_add_00
	jsr	addxb
	inc	0,x
	rts
hand_add_00:
	jsr	addxb
	ldab	0,x
	addb	#$81
	stab	0,x
	rts

; A = player, B = tile in the hand. Removes it. Afterwards there is no drawn
; tile. Keeps A.
hand_remove:
	jsr	player
	dec	P_LEN,x
	pshb
	ldab	#$FF
	stab	P_DRAWN,x
	pulb
	lsrb
	bcs	hand_remove_00
	jsr	addxb
	dec	0,x
	rts
hand_remove_00:
	jsr	addxb
	ldab	0,x
	subb	#$81
	stab	0,x
	rts

; A = player, B = kind in the hand. Returns B = a tile of that kind to
; discard: the red five only when it is the last tile of the kind. Keeps A.
ai_hand_pick:
 ldaa ai_player
 ldab wk_kind
hand_pick:
	pshb
	jsr	player
	jsr	addxb
	pulb
	aslb
	psha
	ldaa	0,x
	cmpa	#$81
	pula
	bne	hand_pick_00
	incb
hand_pick_00:
	rts

; A = player, B = position in the shown order: kinds in increasing order,
; the red five first in its kind, the drawn tile last. Returns B = tile.
; Keeps A.
p0_hand_at:
 clra
hand_at:
	psha
	jsr	player
	incb
	cmpb	P_LEN,x
	bne	hand_at_00
	ldaa	P_DRAWN,x
	cmpa	#$FF
	beq	hand_at_00
	tab
	pula
	rts
hand_at_00:
	stab	hat_left
	ldaa	P_DRAWN,x
	staa	hat_drawn
	ldab	#K_FIRST
	jsr	addxb
	ldab	#K_FIRST*2
hand_at_01:
	ldaa	0,x
	staa	hat_red
	anda	#7
	staa	hat_n
	tba
	eora	hat_drawn
	cmpa	#2
	bcc	hand_at_02
	dec	hat_n
	lsra
	bcc	hand_at_02
	clr	hat_red
hand_at_02:
	tst	hat_red
	bpl	hand_at_03
	dec	hat_left
	beq	hand_at_04
	dec	hat_n
hand_at_03:
	ldaa	hat_left
	cmpa	hat_n
	bls	hand_at_05
	suba	hat_n
	staa	hat_left
	inx
	addb	#2
	bra	hand_at_01
hand_at_04:
	incb
hand_at_05:
	pula
	rts

; A = player, B = tile in the hand. Moves the tile to the river.
discard:
	staa	dc_p
	stab	dc_tile
	jsr	mark_clear
	ldaa	dc_p
	ldab	dc_tile
	jsr	hand_remove
	jsr	player
	ldab	P_RLEN,x
	inc	P_RLEN,x
	stab	dc_k
	addb	#P_RIVER
	jsr	addxb
	ldab	dc_tile
	stab	0,x
	jsr	unshown_tile
 ; The kind is in the river of dc_p (river_bits, bit dc_p + 4).
 ldab dc_p
 jsr player_bit
 asla
 asla
 asla
 asla
 psha
 ldab dc_tile
 lsrb
 ldx #river_bits
 jsr addxb
 pula
 oraa 0,x
 staa 0,x
	ldaa	dc_p
	jsr	draw_hand
	ldaa	dc_p
	ldab	dc_k
	jsr	draw_river_tile
	jsr	river_mark
	ldx	#snd_discard
	jmp	play

; A = position, ht_n = tiles in the hand of ht_p. Sets posx.
ot_hand_tile_x:
 staa ot_i
hand_tile_x:
	asla
	staa	posx
	ldab	ht_n
	decb
	cmpb	ot_i
	bne	hand_tile_x_01
	ldaa	ht_p
	jsr	player
	ldaa	P_DRAWN,x
	cmpa	#$FF
	beq	hand_tile_x_01
	inc	posx
hand_tile_x_01:
	rts

; Shows the arrow under the own tile at the cursor (none if cursor = $FF).
; Clear only the concealed-hand strip on cursor movement: 16 pixels for each
; tile and 8 for the gap before the drawn tile.
draw_arrow:
 ldaa players+P_LEN
 asla
 asla
 asla
 asla
 adda #8
 bra arrow_width
; Clears the arrow strip and draws the arrow under the cursor.
arrow_full:
 ; A hand redraw also removes old kan marks before drawing new furo.
 ldaa #248
arrow_width:
 staa ui_width
 clr sm_x
 ldaa #165
 staa sm_y
 ldaa #3
 jsr ui_erase_px
 ldaa cursor
 cmpa #$FF
 beq arrow_done
 clr ht_p
 ldab players+P_LEN
 stab ht_n
 jsr ot_hand_tile_x
; Draws the arrow under the hand cell at posx.
select_arrow:
 ldaa posx
 asla
 asla
 asla
 adda #5
 staa px_x
 ldaa #165
 staa px_y
 ldx #cursor_icon
 jmp ui_icon
arrow_done:
 rts





; X = score in units of 100. Prints it in 6 cells.
print_score_x:
 ldx 0,x
print_score:
	stx	wk_num
	ldaa	wk_num
	bpl	print_score_00
	ldaa	#CH_MINUS
	jsr	drawchar
	inc	posx
	clra
	clrb
	subb	wk_num+1
	sbca	wk_num
	staa	wk_num
	stab	wk_num+1
	ldab	#3
	jsr	print_num
	bra	pscore_zero
print_score_00:
	ldab	#4
	jsr	print_num
pscore_zero:
 jsr draw_zero
 jsr next_zero
	inc	posx
	rts

; A = unsigned byte, printed in 2 cells (print_byte_num: B cells).
print_a2:
 ldab #2
print_byte_num:
 clr wk_num
 staa wk_num+1
; wk_num = number, B = width. Prints right-aligned at posx.
print_num:
	ldx	#pn_buf
print_num_00:
	ldaa	#CH_SP
	staa	0,x
	inx
	decb
	bne	print_num_00
	ldaa	#$FF
	staa	0,x
	stx	pn_p
	ldaa	#10
	staa	dv_divisor
print_num_01:
	jsr	div8
	adda	#CH_0
	ldx	pn_p
	dex
	staa	0,x
	stx	pn_p
	ldaa	wk_num
	oraa	wk_num+1
	bne	print_num_01
	ldx	#pn_buf
	jmp	drawstr

; Title with native tile artwork and the keyboard guide.
draw_title:
	jsr	clear_screen
	clr	title_i
title_tile_loop:
	ldaa	title_i
	tab
	asla
	aba
	adda	#6
	staa	posx
	ldaa	#3
	staa	posy
	ldaa	title_i
	asla
	asla
	jsr	drawtile
	inc	title_i
	ldaa	title_i
	cmpa	#7
	bne	title_tile_loop
 ldx #title_lines
 stx tt_line
title_text:
 ldx tt_line
 ldab 0,x
 cmpb #$FF
 beq draw_title_00
 ldaa 1,x
 ldx 2,x
 jsr text_px
 ldx tt_line
 ldab #4
 jsr addxb
 stx tt_line
 bra title_text
draw_title_00:
	clr	title_i
title_dragons:
	ldaa	title_i
	asla
	asla
	adda	#11
	staa	posx
	ldaa	#21
	staa	posy
	ldaa	title_i
	adda	#31
	jsr	drawtile
	inc	title_i
	ldaa	title_i
	cmpa	#3
	bne	title_dragons
	rts
; Shows or hides the CPU hands and redraws the table.
toggle_open:
	ldaa	open_mode
	eora	#1
	staa	open_mode
	jmp	redraw_all

; ---------------------------------------------------------------- screen

; x, text row, half-row offset, string pointer; no compressed data.
title_lines:
 .byte 13*8,7*8
 .word s_title
 .byte 10*8,9*8
 .word s_subtitle
 .byte 6*8,12*8
 .word s_move_help
 .byte 6*8,13*8+4
 .word s_discard_help
 .byte 6*8,15*8
 .word s_win_help
 .byte 6*8,16*8+4
 .word s_call_help
 .byte 7*8,18*8
 .word s_start_help
 .byte 28*8,23*8
 .word s_build
 .byte $FF

; Clears the screen and the hand caches.
clear_screen:
	clr	mark_live
 ldaa #$FF
 staa ui_back_n
 staa ui_back_n+1
 staa ui_back_n+2
 staa ui_back_n+3
	clr	posx
	clr	posy
	ldaa	#32
	ldab	#24
	jmp	erase

; A = width, B = height in cells, at posx/posy.
erase1:
 ldab #1
erase:
	staa	er_w
	stab er_h
 ldaa posy
	staa	er_y
erase_01:
	ldaa	er_y
	adda	#VRAMHI
	staa	er_p
	ldaa posx
 staa er_p+1
	ldab	#8
	stab	er_cnt
erase_02:
	ldx	er_p
	ldab	er_w
erase_03:
	clr	0,x
	inx
	decb
	bne	erase_03
	ldaa	er_p+1
	adda	#32
	staa er_p+1
 bcc erase_04
 inc er_p
erase_04:
 dec er_cnt
	bne	erase_02
	ldaa	er_y
	jsr	textaddr
	ldab	er_w
	ldaa	#ATTR_TEXT
	staa	COLORREG
erase_05:
	staa	0,x
	inx
	decb
	bne	erase_05
	inc	er_y
	dec	er_h
	bne	erase_01
	rts

; A = cell row. X = text RAM address of (posx, row).
posy_textaddr:
 ldaa posy
textaddr:
	tab
	lsrb
	lsrb
	lsrb
	addb	#TEXTHI
	stab	ta_p
	anda	#7
	asla
	asla
	asla
	asla
	asla
	adda	posx
	staa	ta_p+1
	ldx	ta_p
	rts

; A = image, at posx/posy. Red fives and the red dragon have red strokes,
; the green dragon has green strokes.
drawtile:
	ldab	#$27
	cmpa	#33
	beq	tile_attr
	cmpa	#34
	bcs	tile_notred
	cmpa	#IMG_BACK
	bcs	tile_attr
tile_notred:
	ldab	#$07
	cmpa	#32
	bne	tile_attr
	ldab	#$47
tile_attr:
	stab	dt_color
	asla
	tab
	ldx	#tileaddr
	jsr	addxb
	ldx	0,x
	stx	dt_src
	ldaa	posy
	adda	#VRAMHI
	staa	dt_dst
 ldaa posx
 staa dt_dst+1
	ldaa	#24
	staa	dt_cnt
 clr dt_repeat
tile_line:
 tst dt_repeat
 beq tile_read_row
 clr dt_repeat
 ldab dt_row_id
 bra tile_row_lookup
tile_read_row:
 ldx dt_src
tile_read_row_00:
 ldab 0,x
 inx
 ; TILE_JUMP and an address: the rest of the rows are read from there.
 cmpb #TILE_JUMP
 bne tile_read_row_01
 ldx 0,x
 bra tile_read_row_00
tile_read_row_01:
 stx dt_src
 tstb
 bpl tile_row_once
 inc dt_repeat
 andb #127
tile_row_once:
 stab dt_row_id
tile_row_lookup:
 aslb
 ldx #tile_rows
 jsr addxb
 ldaa 0,x
 ldab 1,x
	ldx	dt_dst
	staa	0,x
	stab	1,x
	ldab	dt_dst+1
	addb	#32
	stab	dt_dst+1
	bcc	drawtile_00
	inc	dt_dst
drawtile_00:
	dec	dt_cnt
	bne	tile_line
tile_colors:
 jsr posy_textaddr
 ldab #3
 stab dt_cnt
tile_crow:
	ldaa	dt_color
	staa	COLORREG
	staa	0,x
	staa	1,x
	ldab	#32
	jsr	addxb
	dec	dt_cnt
	bne	tile_crow
	rts

; X = string of character codes, the last with bit 7 (or one $FF for an
; empty string), at posx/posy.
drawstr_x:
 ldx 0,x
drawstr:
	stx	dst_ptr
drawstr_00:
	ldx	dst_ptr
	ldaa	0,x
	cmpa	#$FF
	beq	drawstr_01
	inx
	stx	dst_ptr
	psha
	anda	#$7F
	jsr	drawchar
	inc	posx
	pula
	tsta
	bpl	drawstr_00
drawstr_01:
	rts

; A = character code, at posx/posy. Does not move posx.
next_zero:
 inc posx
draw_zero:
 ldaa #CH_0
drawchar:
 psha
	ldaa	posy
	adda	#VRAMHI
	staa	ch_dst
 ldaa posx
	staa	ch_dst+1
 pula
 bsr char_at
 jsr posy_textaddr
	ldaa	#ATTR_TEXT
	staa	COLORREG
	staa	0,x
	rts
; X = string (not empty) whose last character has bit 7, A = pixel row, B =
; pixel column (a multiple of 8).
text_px:
 staa tx_y
 stab tx_x
text_px_00:
 ldaa 0,x
 inx
 stx dst_ptr
 psha
 anda #$7F
 bsr char_px
 ldx dst_ptr
 pula
 tsta
 bpl text_px_00
 rts
; A = character. Draws it at tx_x, tx_y and moves tx_x to the next character.
char_px:
 psha
 ldaa tx_y
 ldab tx_x
 jsr pixel_address
 staa ch_dst
 stab ch_dst+1
 ldab tx_x
 addb #8
 stab tx_x
 pula
; A = character. Draws its 7 rows at ch_dst and clears the row below.
char_at:
 ldx #font_set
 jsr img_decode
 ldx #img_rows
 stx ch_src
	ldab	#7
	stab	ch_cnt
char_line:
	ldx	ch_src
	ldaa	0,x
	inx
	stx	ch_src
	ldx	ch_dst
	staa	0,x
	ldaa	ch_dst+1
	adda	#32
	staa	ch_dst+1
	bcc	char_no_carry
	inc	ch_dst
char_no_carry:
	dec	ch_cnt
	bne	char_line
	ldx	ch_dst
	clr	0,x
	rts

; A = tile. Returns A = image number: 0-26 for the suits, 27-33 for the
; honors, 34-36 for the red fives.
img_of_b:
 tba
img_of:
 lsra
 bcc img_of_00
 jsr kind_suit
 adda #34
 rts
img_of_00:
 tab
 ldx #image_of_kind
 jsr addxb
 ldaa 0,x
 rts
image_of_kind:
 .byte 37,0,1,2,3,4,5,6,7,8
 .byte 37,9,10,11,12,13,14,15,16,17
 .byte 37,18,19,20,21,22,23,24,25,26
 .byte 37,27,28,29,30,31,32,33

; ---------------------------------------------------------------- misc


; Waits one frame and reads the keys. knew has the keys pressed in this frame.
frame:
	wai
	jsr	rand
	jsr	scan_keys
; In a demo game, space held now returns to the title. Called often enough
; while the CPU players think.
demo_poll:
	tst	demo
	beq	demo_poll_00
	ldaa	#11
	staa	KEYPORT
	ldaa	KEYPORT
	bita	#$01
	bne	demo_poll_00
	; The title sees this press as held, not as a new one.
	ldaa	#KEY_SPACE
	staa	kprev
	lds	#$3FFF
	jmp	title
demo_poll_00:
	rts
; Reads the keys without waiting a frame (sets knew).
scan_keys:
	clr	open_cur
	clr	kcur
	ldx	#keytab
	ldaa	#1
	staa	rk_bit
scan_keys_00:
	ldaa	0,x
	staa	KEYPORT
	ldaa	KEYPORT
	staa	rk_data
	ldab	rk_bit
	cmpb	#1
	bne	scan_keys_01
	anda	#$08
	bne	scan_keys_01
	inc	open_cur
scan_keys_01:
	ldaa	rk_data
	anda	1,x
	bne	scan_keys_02
	ldaa	kcur
	oraa	rk_bit
	staa	kcur
scan_keys_02:
	inx
	inx
	asl	rk_bit
	bne	scan_keys_00
	ldaa	kprev
	coma
	anda	kcur
	staa	knew
	ldaa	kcur
	staa	kprev
	anda	#3
	beq	scan_keys_03
	inc	krep
	ldab	krep
	cmpb	#20
	bcs	scan_keys_04
	ldab	#16
	stab	krep
	oraa	knew
	staa	knew
	bra	scan_keys_04
scan_keys_03:
	clr	krep
scan_keys_04:
	jmp	apply_open

; Shared column-0 sample supplies 1; process its edge after action scanning.
apply_open:
	tst	open_cur
	bne	apply_open_00
	clr	open_prev
	rts
apply_open_00:
	tst	open_prev
	bne	apply_open_01
	inc	open_prev
	tst	game_active
	beq	apply_open_01
	ldx	#snd_select
	jsr	play
	jsr	toggle_open
apply_open_01:
	rts

; Key column and bit for Z, X, space, T, R, K, P, C.
keytab:
	.byte	0,$01,1,$01,11,$01,4,$04,3,$04,7,$02,9,$04,2,$01

; A = number of frames.
wait_frames:
	staa	wf_cnt
wait_frames_00:
	jsr	frame
	dec	wf_cnt
	bne	wait_frames_00
	rts

; Waits until space is pressed (5 seconds in a demo game).
wait_space:
	tst	demo
	beq	wait_space_00
	ldaa	#150
	jsr	wait_frames
	ldaa	#150
	jmp	wait_frames
wait_space_00:
	jsr	frame
	ldaa	knew
	bita	#KEY_SPACE
	beq	wait_space_00
	rts

; xorshift24 (shifts 8, 1, 11; period 2^24-1; the state must not be 0).
; Returns A = random byte.
rand:
	ldaa	seed+1
	eora	seed
	staa	seed
	ldaa	seed+2
	eora	seed+1
	staa	seed+1
	ldaa	seed
	lsra
	staa	rnd_t0
	ldaa	seed+1
	rora
	staa	rnd_t1
	ldaa	seed+2
	rora
	eora	seed+2
	staa	seed+2
	ldaa	seed+1
	eora	rnd_t1
	staa	seed+1
	ldaa	seed
	eora	rnd_t0
	staa	seed
	ldaa	seed+2
	ldab	seed+1
	asla
	rolb
	asla
	rolb
	asla
	rolb
	eorb	seed
	stab	seed
	eora	seed+1
	staa	seed+1
	ldaa	seed
	rts

; A = n. Returns A = random number in 0..n-1.
rand_below:
	staa	rb_n
	jsr	rand
	ldab	rb_n
	jsr	mul8
	rts

; Fills the wall with the 136 tiles in kind order (the first five of each
; suit is red) and shuffles it.
shuffle:
	ldx	#wall
	ldaa	#K_FIRST
shuffle_kind:
	tab
	aslb
	psha
	jsr	kind_number
	cmpa	#5
	pula
	bne	shuffle_put
	incb
shuffle_put:
	stab	0,x
	andb	#$FE
	stab	1,x
	stab	2,x
	stab	3,x
	inx
	inx
	inx
	inx
	cmpa	#K_HONOR
	bcc	shuffle_honor
	; After a 9 comes the kind that is not a tile.
	psha
	jsr	kind_number
	cmpa	#9
	pula
	bne	shuffle_next
	inca
shuffle_next:
	inca
	bra	shuffle_kind
shuffle_honor:
	inca
	cmpa	#K_END
	bne	shuffle_kind
	ldaa	#135
	staa	shf_left
shuffle_00:
	ldaa	shf_left
	inca
	jsr	rand_below
	tab
	jsr	wall_x
	stx	shf_pj
	ldab	shf_left
	jsr	wall_x
	stx	shf_pi
	ldaa	0,x
	ldx	shf_pj
	ldab	0,x
	staa	0,x
	ldx	shf_pi
	stab	0,x
	dec	shf_left
	bne	shuffle_00
	rts

	.bss
bss_start:
; seed is allocated in directpage.asm.
rnd_t0:	.ds	1 ; rand scratch
rnd_t1:	.ds	1 ; rand scratch
; posx is allocated in directpage.asm.
; posy is allocated in directpage.asm.
; knew is allocated in directpage.asm.
kcur:	.ds	1 ; keys held now
kprev:	.ds	1 ; keys held in the last frame
krep:	.ds	1 ; frames a key has been held
rk_bit:	.ds	1 ; key bit scan_keys checks
wf_cnt:	.ds	1 ; frames left
rb_n:	.ds	1 ; rand_below limit
shf_left:	.ds	1 ; tiles left to shuffle
shf_pi:	.ds	2 ; &wall[i]
shf_pj:	.ds	2 ; &wall[j]
; round is allocated in directpage.asm.
honba:	.ds	1 ; honba counter
; kyotaku is allocated in directpage.asm.
; title_i is allocated in directpage.asm.
title_sec:	.ds	1 ; $0B (seconds) when the title began to wait
demo:	.ds	1 ; nonzero in a demo game (D at the title; auto_play is set too)
open_mode:	.ds	1 ; nonzero when CPU hands are shown
game_active:	.ds	1 ; nonzero during a hand
result_active:	.ds	1 ; nonzero on a result page
open_prev:	.ds	1 ; open key held in the last frame
open_cur:	.ds	1 ; open key held now
rk_data:	.ds	1 ; key port data
; turn is allocated in directpage.asm.
wallpos:	.ds	1 ; next live tile in wall
draws_left:	.ds	1 ; live draws left
deal_cnt:	.ds	1 ; deal steps left
wall:	.ds	136 ; 136 tiles, dead wall at the end
players:	.ds	PSIZE*4 ; four player areas (PSIZE each)
; dc_p is allocated in directpage.asm.
dc_k:	.ds	1 ; kind of dc_tile
; cursor is allocated in directpage.asm.
; cw_p is allocated in directpage.asm.
cw_ron:	.ds	1 ; 1 for ron, 0 for tsumo (check_win)
win_tile:	.ds	1 ; tile of the ron (setup_score)
; ss_i is allocated in directpage.asm.
ss_p:	.ds	2 ; next furo (setup_score)
; ry_tenpai is allocated in directpage.asm.
; ry_v is allocated in directpage.asm.
ry_score_before:	.ds	8 ; scores before the settlement
sr_i:	.ds	1 ; yaku index on the result page
; sr_row is allocated in directpage.asm.
sr_id:	.ds	1 ; yaku number shown
can_win:	.ds	1 ; nonzero when the player in turn can tsumo
reveal:	.ds	1 ; 1=reveal turn hand, 2=reveal all hands
win_text:	.ds	2 ; win title string
el_src:	.ds	2 ; player area being copied
el_dst:	.ds	2 ; counts being filled
fcn_dst:	.ds	2 ; array furo are added to
fcn_src:	.ds	2 ; next furo
fcn_n:	.ds	1 ; furo left
hat_left:	.ds	1 ; position left to skip
hat_n:	.ds	1 ; tiles left of the kind
hat_red:	.ds	1 ; 1 while the red five is first
hat_drawn:	.ds	1 ; drawn tile
; ot_i is allocated in directpage.asm.
; ht_n is allocated in directpage.asm.
; dh_i is allocated in directpage.asm.
rvt_player:	.ds	1 ; river tile player
rvt_index:	.ds	1 ; river tile index
rvt_flag:	.ds	1 ; river tile flags
rvt_pos:	.ds	1 ; river tile position
rvt_img:	.ds	1 ; river tile image
pn_buf:	.ds	8 ; digits of print_num
pn_p:	.ds	2 ; next digit cell
er_w:	.ds	1 ; erase width
er_h:	.ds	1 ; erase height
er_y:	.ds	1 ; erase row
er_p:	.ds	2 ; erase address
er_cnt:	.ds	1 ; rows left in the cell
ta_p:	.ds	2 ; text RAM address
dt_color:	.ds	1 ; drawtile color
dt_src:	.ds	2 ; drawtile image row
dt_dst:	.ds	2 ; drawtile screen address
dt_cnt:	.ds	1 ; drawtile rows left
dst_ptr:	.ds	2 ; next character
; ch_src is allocated in directpage.asm.
tx_x: .ds 1 ; pixel column of text_px
tx_y: .ds 1 ; pixel row of text_px
ch_dst:	.ds	2 ; drawchar screen address
ch_cnt:	.ds	1 ; drawchar rows left

	.bss
	.bss
deal_player:	.ds	1 ; player being dealt

	.code

 .bss
dt_repeat: .ds 1 ; nonzero to repeat the row
dt_row_id: .ds 1 ; row lookup index

 .code
; Shows the final scores and returns to the title.
final_scores:
 clra
 jsr score_page
 jsr wait_space
 jmp title

 .bss
tt_line: .ds 2 ; next title line
 .code
