; Yaku and points.
;
; Input:  counts (closed tiles with the winning tile), furo_tiles (tiles of
;         the furo), nfuro, the furo in btype/bkind[0..nfuro-1],
;         closed_flag, nkan, win_kind, tsumo_flag, seat_kind, round_kind,
;         dealer_flag, sflags, honba, kyotaku, dora_n, aka_n, ura_n.
; Output: best_pts (points in units of 100, 0 = no yaku), best_han, best_fu,
;         best_n and best_y (yaku numbers in increasing order).

F_RIICHI	.equ	$80
F_DOUBLE	.equ	$02
F_IPPATSU	.equ	$04
F_RINSHAN	.equ	$08
F_CHANKAN	.equ	$10
F_LAST	.equ	$20
F_FIRST	.equ	$40

M_CHI	.equ	0
M_PON	.equ	1
M_MINKAN	.equ	2
M_ANKAN	.equ	3

Y_RIICHI	.equ	0
Y_DOUBLE	.equ	1
Y_IPPATSU	.equ	2
Y_TSUMO	.equ	3
Y_PINFU	.equ	4
Y_TANYAO	.equ	5
Y_IIPEIKOU	.equ	6
Y_HAKU	.equ	7
Y_BAKAZE	.equ	10
Y_JIKAZE	.equ	11
Y_RINSHAN	.equ	12
Y_CHANKAN	.equ	13
Y_HAITEI	.equ	14
Y_HOUTEI	.equ	15
Y_SANSHOKU	.equ	16
Y_ITTSU	.equ	17
Y_CHANTA	.equ	18
Y_CHIITOI	.equ	19
Y_TOITOI	.equ	20
Y_SANANKOU	.equ	21
Y_DOUKOU	.equ	22
Y_SANKANTSU	.equ	23
Y_HONROUTOU	.equ	24
Y_SHOUSANGEN	.equ	25
Y_RYANPEIKOU	.equ	26
Y_JUNCHAN	.equ	27
Y_HONITSU	.equ	28
Y_CHINITSU	.equ	29
Y_DORA	.equ	30
Y_AKA	.equ	31
Y_URA	.equ	32
Y_TENHOU	.equ	40
Y_CHIIHOU	.equ	41
Y_KOKUSHI	.equ	42
Y_SUUANKOU	.equ	43
Y_DAISANGEN	.equ	44
Y_TSUUIISOU	.equ	45
Y_SHOUSUUSHII	.equ	46
Y_DAISUUSHII	.equ	47
Y_RYUUIISOU	.equ	48
Y_CHINROUTOU	.equ	49
Y_SUUKANTSU	.equ	50
Y_CHUUREN	.equ	51

W_RYANMEN	.equ	0
W_KANCHAN	.equ	1
W_PENCHAN	.equ	2
W_TANKI	.equ	3
W_SHANPON	.equ	4

A_YAOCHU	.equ	$01
A_HONOR	.equ	$02
A_GREEN	.equ	$04
A_T28	.equ	$08 ; a 2 or an 8
A_MAN	.equ	$10
A_PIN	.equ	$20
A_SOU	.equ	$40
A_SUITS	.equ	$70
A_M46	.equ	$80 ; a 4, 5 or 6

; Block types in btype: furo first, then the blocks of the closed hand.
B_SEQ	.equ	$01
B_OPEN	.equ	$02
B_KAN	.equ	$04

score_hand:
	clr	best_pts
	clr	best_pts+1
	clr	best_han
	clr	best_fu
	clr	best_n
	jsr	make_tot
	jsr	analyse
	jsr	find_yakuman
	ldab	nfuro
	bne	score_hand_01
	jsr	counts_chii_sh
	inca
	bne	score_hand_00
 jsr start_yaku_clr
	ldaa	#Y_CHIITOI
	jsr	add_yaku
	jsr	base_yaku
	ldaa	#25
	staa	cur_fu
	jsr	finish
score_hand_00:
	ldaa	spec_cnt+SP_YAO
	ldab	spec_cnt+SP_YPAIRS
	jsr	kok_sh
	inca
	bne	score_hand_01
	ldaa	#Y_KOKUSHI
	jsr	add_ym
 jsr start_yaku_clr
	jsr	finish
score_hand_01:
	jsr	decomp_all
 ; During decomposition best_pts holds basic points; convert only once.
 ldx best_pts
 beq score_hand_10
 stx fi_basic
 jsr fi_pay
score_hand_10:
	jmp	sort_best

; work = counts + furo_tiles.
make_tot:
	ldx	#counts
make_tot_00:
	ldaa	0,x
	adda	furo_tiles-counts,x
	staa	work-counts,x
	inx
	cpx	#counts+KN
	bne	make_tot_00
	rts

; attr_and, attr_or = AND and OR of kattr over the kinds in work.
analyse:
	ldaa	#$FF
	staa	attr_and
	clr	attr_or
	ldx	#work+K_FIRST
analyse_00:
	tst	0,x
	beq	analyse_01
	stx	an_x
	ldab	an_x+1
	subb	#<work
	jsr	kattr_x
	ldaa	0,x
	tab
	anda	attr_and
	staa	attr_and
	orab	attr_or
	stab	attr_or
	ldx	an_x
analyse_01:
	inx
	cpx	#work+K_END
	bne	analyse_00
	rts

; Fills ym_n, ym_y with the yakuman that do not depend on the
; decomposition.
find_yakuman:
	clr	ym_n
	ldaa	sflags
	bita	#F_FIRST
	beq	yakuman_dragons
	tst	tsumo_flag
	beq	yakuman_dragons
	ldaa	#Y_TENHOU
	tst	dealer_flag
	bne	yakuman_first
	ldaa	#Y_CHIIHOU
yakuman_first:
	jsr	add_ym
; Kokushi is added by score_hand.
yakuman_dragons:
	ldaa	work+K_HAKU
	cmpa	#3
	bcs	yakuman_honor
	ldaa	work+K_HATSU
	cmpa	#3
	bcs	yakuman_honor
	ldaa	work+K_CHUN
	cmpa	#3
	bcs	yakuman_honor
	ldaa	#Y_DAISANGEN
	jsr	add_ym
yakuman_honor:
	ldaa	attr_and
	bita	#A_HONOR
	beq	yakuman_winds
	ldaa	#Y_TSUUIISOU
	jsr	add_ym
yakuman_winds:
	clr	fy_trip
	clr	fy_pair
	ldx	#work+K_EAST
	ldab	#4
yakuman_wloop:
	ldaa	0,x
	cmpa	#3
	bcs	yakuman_wpair
	inc	fy_trip
	bra	yakuman_wnext
yakuman_wpair:
	cmpa	#2
	bne	yakuman_wnext
	inc	fy_pair
yakuman_wnext:
	inx
	decb
	bne	yakuman_wloop
	ldaa	fy_trip
	cmpa	#4
	bne	yakuman_shou
	ldaa	#Y_DAISUUSHII
	jsr	add_ym
	bra	yakuman_green
yakuman_shou:
	cmpa	#3
	bne	yakuman_green
	ldaa	fy_pair
	cmpa	#1
	bne	yakuman_green
	ldaa	#Y_SHOUSUUSHII
	jsr	add_ym
yakuman_green:
	ldaa	attr_and
	bita	#A_GREEN
	beq	yakuman_term
	ldaa	#Y_RYUUIISOU
	jsr	add_ym
yakuman_term:
	ldaa	attr_and
	bita	#A_YAOCHU
	beq	yakuman_kan
	ldaa	attr_or
	bita	#A_HONOR
	bne	yakuman_kan
	ldaa	#Y_CHINROUTOU
	jsr	add_ym
yakuman_kan:
	ldaa	nkan
	cmpa	#4
	bne	yakuman_chuuren
	ldaa	#Y_SUUKANTSU
	jsr	add_ym
yakuman_chuuren:
	tst	nfuro
	bne	find_yakuman_00
	ldaa	attr_or
	anda	#A_SUITS+A_HONOR
	ldx	#counts+K_FIRST
	cmpa	#A_MAN
	beq	yakuman_c9
	ldx	#counts+K_FIRST+10
	cmpa	#A_PIN
	beq	yakuman_c9
	ldx	#counts+K_FIRST+20
	cmpa	#A_SOU
	bne	find_yakuman_00
yakuman_c9:
	ldaa	0,x
	cmpa	#3
	bcs	find_yakuman_00
	ldaa	8,x
	cmpa	#3
	bcs	find_yakuman_00
	ldab	#7
yakuman_cmid:
	inx
	tst	0,x
	beq	find_yakuman_00
	decb
	bne	yakuman_cmid
	ldaa	#Y_CHUUREN
	jsr	add_ym
find_yakuman_00:
	rts

; A = yakuman number. Appends it to ym_y.
add_ym:
	ldx	#ym_y
	ldab	ym_n
	jsr	addxb
	staa	0,x
	inc	ym_n
	rts

; Clears the yaku list of the current decomposition.
start_yaku_clr:
 clr ym_extra
start_yaku:
	clr	cur_n
	clr	cur_han
	rts

; A = yaku number. Adds its han and appends it.
add_yaku:
	psha
	jsr reg_yaku_han
	adda	cur_han
	staa	cur_han
	pula
; A = yaku number (for dora, append_yaku). Appends it to cur_y without adding han.
append_yaku:
	ldx	#cur_y
	ldab	cur_n
	jsr	addxb
	staa	0,x
	inc	cur_n
	rts

; Yaku that do not depend on the decomposition.
base_yaku:
	ldaa	sflags
	bita	#F_DOUBLE
	beq	base_riichi
	ldaa	#Y_DOUBLE
	jsr	add_yaku
	bra	base_ippatsu
base_riichi:
	bita	#F_RIICHI
	beq	base_ippatsu
	ldaa	#Y_RIICHI
	jsr	add_yaku
base_ippatsu:
	ldaa	sflags
	bita	#F_IPPATSU
	beq	base_tsumo
	ldaa	#Y_IPPATSU
	jsr	add_yaku
base_tsumo:
	tst	closed_flag
	beq	base_tanyao
	tst	tsumo_flag
	beq	base_tanyao
	ldaa	#Y_TSUMO
	jsr	add_yaku
base_tanyao:
	ldaa	attr_or
	bita	#A_YAOCHU
	bne	base_rinshan
	ldaa	#Y_TANYAO
	jsr	add_yaku
base_rinshan:
	ldaa	sflags
	bita	#F_RINSHAN
	beq	base_chankan
	ldaa	#Y_RINSHAN
	jsr	add_yaku
	bra	base_suit
base_chankan:
	bita	#F_CHANKAN
	beq	base_last
	ldaa	#Y_CHANKAN
	jsr	add_yaku
base_last:
	ldaa	sflags
	bita	#F_LAST
	beq	base_suit
	ldaa	#Y_HAITEI
	tst	tsumo_flag
	bne	base_last_add
	ldaa	#Y_HOUTEI
base_last_add:
	jsr	add_yaku
base_suit:
	ldaa	attr_or
	anda	#A_SUITS
	cmpa	#A_MAN
	beq	base_yaku_00
	cmpa	#A_PIN
	beq	base_yaku_00
	cmpa	#A_SOU
	bne	base_routou
base_yaku_00:
	ldaa	#Y_CHINITSU
	ldab	attr_or
	bitb	#A_HONOR
	beq	base_one_add
	ldaa	#Y_HONITSU
base_one_add:
	jsr	add_yaku
base_routou:
	ldaa	attr_and
	bita	#A_YAOCHU
	beq	base_yaku_10
	ldaa	attr_or
	bita	#A_HONOR
	beq	base_yaku_10
	bita	#A_SUITS
	beq	base_yaku_10
	ldaa	#Y_HONROUTOU
	jsr	add_yaku
base_yaku_10:
	rts

; Tries every head and every set of blocks of counts, and every place of the
; winning tile.
decomp_all:
	ldaa	nfuro
	staa	sets_n
	ldaa	#K_FIRST
	staa	se_kind
	ldx	#search
	jmp	each_head

; A = block type (0 triplet, 1 sequence), B = kind.
push_block:
	ldx	#btype
	pshb
	ldab	sets_n
	jsr	addxb
	pulb
	staa	0,x
	stab	bkind-btype,x
	inc	sets_n
	rts

; Evaluates the decomposition for every place of the winning tile.
eval_places:
	ldaa	head_kind
	cmpa	win_kind
	bne	eval_places_00
	ldaa	#W_TANKI
	staa	ed_wait
	ldaa	#$FF
 jsr eval_decomp
eval_places_00:
	ldaa	nfuro
	staa	ep_i
eval_places_01:
	ldaa	ep_i
	cmpa	sets_n
	beq	eval_places_06
	ldab	ep_i
	jsr	btype_x
	ldaa	bkind-btype,x
	staa	ep_kind
	ldab	0,x
	bne	eval_places_02
	cmpa	win_kind
	bne	eval_places_05
	ldaa	#W_SHANPON
	bra	eval_places_04
eval_places_02:
	ldab	win_kind
	subb	ep_kind
	bcs	eval_places_05
	cmpb	#3
	bcc	eval_places_05
	ldaa	#W_KANCHAN
	cmpb	#1
	beq	eval_places_04
	stab	ep_off
	ldab	ep_kind
 jsr kind_number_b
 tab
	ldaa	#W_RYANMEN
	tst	ep_off
	bne	eval_places_03
	cmpb	#7
	bne	eval_places_04
	ldaa	#W_PENCHAN
	bra	eval_places_04
eval_places_03:
	cmpb	#1
	bne	eval_places_04
	ldaa	#W_PENCHAN
eval_places_04:
	staa	ed_wait
	ldaa	ep_i
 jsr eval_decomp
eval_places_05:
	inc	ep_i
	bra	eval_places_01
eval_places_06:
	rts

; Evaluates one decomposition: head head_kind, sets_n blocks (the furo first),
; A = block of the winning tile (ed_wi), with wait ed_wait.
eval_decomp:
 staa ed_wi
	jsr	collect
	clr	ym_extra
	ldaa	n_conc
	cmpa	#4
	bne	decomp_yaku
	inc	ym_extra
decomp_yaku:
	jsr	start_yaku
	jsr	base_yaku
	jsr	head_fu
	stab	ed_yhead
	clr	ed_pinfu
	ldab	nfuro
	bne	decomp_peikou
	ldaa	n_seq
	cmpa	#4
	bne	decomp_peikou
	tst	ed_yhead
	bne	decomp_peikou
	ldaa	ed_wait
	cmpa	#W_RYANMEN
	bne	decomp_peikou
	inc	ed_pinfu
	ldaa	#Y_PINFU
	jsr	add_yaku
decomp_peikou:
	tst	closed_flag
	beq	decomp_dragons
	clra
	ldx	#seq_n+K_FIRST
decomp_pk:
	ldab	0,x
	lsrb
	aba
	inx
	cpx	#seq_n+K_HONOR
	bne	decomp_pk
	cmpa	#2
	bne	decomp_iipei
	ldaa	#Y_RYANPEIKOU
	jsr	add_yaku
	bra	decomp_dragons
decomp_iipei:
	cmpa	#1
	bne	decomp_dragons
	ldaa	#Y_IIPEIKOU
	jsr	add_yaku
decomp_dragons:
 ; Y_HAKU + i for a triplet of kind K_HAKU + i.
 ldaa #Y_HAKU
decomp_dragons_00:
 tab
 addb #K_HAKU-Y_HAKU
 jsr trip_n_x
 tst 0,x
 beq decomp_dragons_01
 psha
 jsr add_yaku
 pula
decomp_dragons_01:
 inca
 cmpa #Y_HAKU+3
 bne decomp_dragons_00
decomp_round:
	ldab	round_kind
	jsr	trip_n_x
	tst	0,x
	beq	decomp_seat
	ldaa	#Y_BAKAZE
	jsr	add_yaku
decomp_seat:
	ldab	seat_kind
	jsr	trip_n_x
	tst	0,x
	beq	decomp_sanshoku
	ldaa	#Y_JIKAZE
	jsr	add_yaku
decomp_sanshoku:
	ldx	#seq_n+K_FIRST
eval_decomp_00:
	tst	0,x
	beq	eval_decomp_01
	tst	10,x
	beq	eval_decomp_01
	tst	20,x
	beq	eval_decomp_01
	ldaa	#Y_SANSHOKU
	jsr	add_yaku
	bra	decomp_ittsu
eval_decomp_01:
	inx
	cpx	#seq_n+K_FIRST+7
	bne	eval_decomp_00
decomp_ittsu:
	ldx	#seq_n+K_FIRST
eval_decomp_10:
	tst	0,x
	beq	eval_decomp_11
	tst	3,x
	beq	eval_decomp_11
	tst	6,x
	beq	eval_decomp_11
	ldaa	#Y_ITTSU
	jsr	add_yaku
	bra	decomp_toitoi
eval_decomp_11:
	ldab	#10
	jsr	addxb
	cpx	#seq_n+K_FIRST+30
	bne	eval_decomp_10
decomp_toitoi:
	ldaa	n_trip
	cmpa	#4
	bne	decomp_ankou
	ldaa	#Y_TOITOI
	jsr	add_yaku
decomp_ankou:
	ldaa	n_conc
	cmpa	#3
	bne	decomp_doukou
	ldaa	#Y_SANANKOU
	jsr	add_yaku
decomp_doukou:
	ldx	#trip_n+K_FIRST
eval_decomp_20:
	tst	0,x
	beq	eval_decomp_21
	tst	10,x
	beq	eval_decomp_21
	tst	20,x
	beq	eval_decomp_21
	ldaa	#Y_DOUKOU
	jsr	add_yaku
	bra	decomp_kantsu
eval_decomp_21:
	inx
	cpx	#trip_n+K_FIRST+9
	bne	eval_decomp_20
decomp_kantsu:
	ldaa	nkan
	cmpa	#3
	bne	decomp_shou
	ldaa	#Y_SANKANTSU
	jsr	add_yaku
decomp_shou:
	ldaa	head_kind
	cmpa	#K_HAKU
	bcs	decomp_chanta
	ldaa	trip_n+K_HAKU
	adda	trip_n+K_HATSU
	adda	trip_n+K_CHUN
	cmpa	#2
	bne	decomp_chanta
	ldaa	#Y_SHOUSANGEN
	jsr	add_yaku
decomp_chanta:
	tst	n_seq
	beq	decomp_fu
	jsr	all_yaochu
	beq	decomp_fu
	ldaa	#Y_JUNCHAN
	ldab	attr_or
	bitb	#A_HONOR
	beq	decomp_chanta2
	ldaa	#Y_CHANTA
decomp_chanta2:
	jsr	add_yaku
decomp_fu:
	jsr	calc_fu
	jmp	finish

; Fills trip_n and seq_n (blocks of each kind), n_trip, n_seq and n_conc
; (concealed triplets and kans) from all blocks.
collect:
	clr	block_fu
	ldx	#trip_n
collect_00:
	clr	0,x
	clr	seq_n-trip_n,x
	inx
	cpx	#trip_n+KN
	bne	collect_00
	clr	n_seq
	clr	n_trip
	clr	n_conc
	clr	cl_i
collect_01:
	ldab	cl_i
	cmpb	sets_n
	beq	collect_06
	jsr	btype_x
	ldaa	0,x
	bita	#B_SEQ
	bne	collect_04
	ldab	cl_i
	jsr	concealed
	ldab	#2
	tsta
	beq	collect_02
	inc	n_conc
	aslb
collect_02:
	ldaa	0,x
	bita	#B_KAN
	beq	collect_03
	aslb
	aslb
collect_03:
	tba
	ldab	bkind-btype,x
	jsr	add_set_fu
	ldab	cl_i
	jsr	btype_x
	inc	n_trip
	ldab	bkind-btype,x
	ldx	#trip_n
	bra	collect_05
collect_04:
	ldab	bkind-btype,x
	inc	n_seq
	ldx	#seq_n
collect_05:
	jsr	addxb
	inc	0,x
	inc	cl_i
	bra	collect_01
collect_06:
	rts

; X = &btype[B]. Returns A = 1 if the block counts as concealed: not called,
; and not the triplet completed by ron on a shanpon wait. Keeps X.
concealed:
	ldaa	0,x
	bita	#B_OPEN
	bne	concealed_00
	cmpb	ed_wi
	bne	concealed_01
	ldaa	ed_wait
	cmpa	#W_SHANPON
	bne	concealed_01
	tst	tsumo_flag
	bne	concealed_01
concealed_00:
	clra
	rts
concealed_01:
	ldaa	#1
	rts

; Returns B = head fu, including both winds when they coincide.
head_fu:
 clrb
 ldaa head_kind
 cmpa #K_HAKU
 bcs head_fu_00
 addb #2
head_fu_00:
 cmpa seat_kind
 bne head_fu_01
 addb #2
head_fu_01:
 cmpa round_kind
 bne head_fu_02
 addb #2
head_fu_02:
 rts

; Returns A = 1 if the head and every block have a terminal or an honor.
; Returns with N and Z set from A.
all_yaochu:
	ldab	head_kind
	jsr	kattr_x
	ldaa	0,x
	bita	#A_YAOCHU
	beq	all_yaochu_04
 clr ab_index
all_yaochu_00:
 ldab ab_index
 cmpb sets_n
 beq all_yaochu_03
 jsr btype_x
 ldab bkind-btype,x
 ldaa 0,x
 bita #B_SEQ
 beq all_yaochu_01
 jsr kind_number_b
 cmpa #1
 beq all_yaochu_02
 cmpa #7
 bne all_yaochu_04
 bra all_yaochu_02
all_yaochu_01:
 jsr kattr_x
 ldaa 0,x
 bita #A_YAOCHU
 beq all_yaochu_04
all_yaochu_02:
 inc ab_index
 bra all_yaochu_00
all_yaochu_03:
	ldaa	#1
	rts
all_yaochu_04:
	clra
	rts

; Sets cur_fu for the decomposition.
calc_fu:
	tst	ed_pinfu
	beq	calc_fu_01
	ldaa	#20
	tst	tsumo_flag
	bne	calc_fu_00
	ldaa	#30
calc_fu_00:
	staa	cur_fu
	rts
calc_fu_01:
	ldaa	#20
	staa	cur_fu
	tst	closed_flag
	beq	calc_fu_02
	tst	tsumo_flag
	bne	calc_fu_02
	ldaa	#10
	jsr	add_fu
calc_fu_02:
	tst	tsumo_flag
	beq	calc_fu_03
 jsr add_fu2
calc_fu_03:
 ldaa ed_yhead
 jsr add_fu
	ldaa	ed_wait
	cmpa	#W_KANCHAN
	beq	calc_fu_05
	cmpa	#W_PENCHAN
	beq	calc_fu_05
	cmpa	#W_TANKI
	bne	calc_fu_06
calc_fu_05:
 jsr add_fu2
calc_fu_06:
 ldaa block_fu
 jsr add_fu
	ldaa	cur_fu
	cmpa	#20
	bne	calc_fu_08
	tst	closed_flag
	bne	calc_fu_08
	ldaa	#30
calc_fu_08:
	adda	#9
	clrb
calc_fu_09:
	cmpa	#10
	bcs	calc_fu_10
	suba	#10
	addb	#10
	bra	calc_fu_09
calc_fu_10:
	stab	cur_fu
	rts

add_fu2:
 ldaa #2
; A = fu. Adds it to cur_fu (add_fu2: 2 fu).
add_fu:
	adda	cur_fu
	staa	cur_fu
	rts

; A = fu of a simple set, B = kind. Doubles it for a terminal or honor.
add_set_fu:
	psha
	jsr	kattr_x
	ldab	0,x
	pula
	bitb	#A_YAOCHU
	beq	add_set_fu_00
	asla
add_set_fu_00:
	adda	block_fu
	staa	block_fu
	rts

; Computes the points of the current yaku and keeps the best.
finish:
	ldaa	ym_n
	adda	ym_extra
	beq	finish_normal
	ldab	#13
	jsr	mul8
	stab	fi_han
	clr	fi_fu
	jsr	yakuman_basic
	jsr	fi_better
	beq	finish_00
	ldx	#ym_y
	ldab	ym_n
 jsr fi_copy
	tst	ym_extra
	beq	finish_00
	ldab	best_n
	jsr	best_y_x
	ldaa	#Y_SUUANKOU
	staa	0,x
	inc	best_n
	rts
finish_normal:
	tst	cur_n
	beq	finish_00
	ldaa	dora_n
	beq	finish_aka
	ldaa	#Y_DORA
	jsr	append_yaku
finish_aka:
	ldaa	aka_n
	beq	finish_ura
	ldaa	#Y_AKA
	jsr	append_yaku
finish_ura:
	ldaa	ura_n
	beq	finish_han_total
	ldaa	#Y_URA
	jsr	append_yaku
finish_han_total:
	ldaa	cur_han
	adda	dora_n
	adda	aka_n
	adda	ura_n
	staa	fi_han
	ldaa	cur_fu
 jsr fi_limit
	jsr	fi_better
	beq	finish_00
	ldx	#cur_y
	ldab	cur_n
 jsr fi_copy
finish_00:
	rts

; X = list, B = count. Copies it to best_y and sets best_pts, best_han,
; best_fu.
fi_copy:
	stab	best_n
	stx	fi_copy_ld+1
	ldx	fi_basic
	stx	best_pts
	ldaa	fi_han
	staa	best_han
	ldaa	fi_fu
	staa	best_fu
	tstb
	beq	fi_copy_01
	; The operand of fi_copy_ld walks the list (ym_y or cur_y, each within
	; one page; build.py checks it), so X stays on best_y.
	ldx	#best_y
fi_copy_ld:
	ldaa	cur_y
	staa	0,x
	inx
	inc	fi_copy_ld+2
	decb
	bne	fi_copy_ld
fi_copy_01:
	rts

; Sorts best_y in increasing order.
sort_best:
 ldx #best_y
 ldab best_n
; X = byte array, B = length. Adjacent exchange sort, including length 0/1.
sort_bytes:
 cmpb #2
 bcs sort_bytes_03
 stx sort_base
 stab sort_n
sort_bytes_00:
 clr sbt_swapped
 ldx sort_base
 ldab sort_n
 decb
sort_bytes_01:
 ldaa 0,x
 cmpa 1,x
 bls sort_bytes_02
 psha
 ldaa 1,x
 staa 0,x
 pula
 staa 1,x
 inc sbt_swapped
sort_bytes_02:
 inx
 decb
 bne sort_bytes_01
 tst sbt_swapped
 bne sort_bytes_00
sort_bytes_03:
 rts

; fi_basic = basic points of fi_han, fi_fu. A = han and fu = best_fu
; (fi_limit_han), or A = fu with fi_han set (fi_limit).
fi_limit_han:
 staa fi_han
 ldaa best_fu
fi_limit:
 staa fi_fu
	ldx	#8000
	ldaa	fi_han
	cmpa	#13
	bcc	fi_limit_02
	ldx	#6000
	cmpa	#11
	bcc	fi_limit_02
	ldx	#4000
	cmpa	#8
	bcc	fi_limit_02
	ldx	#3000
	cmpa	#6
	bcc	fi_limit_02
	ldx	#2000
	cmpa	#5
	bcc	fi_limit_02
	clr	fi_basic
	ldaa	fi_fu
	staa	fi_basic+1
	ldab	fi_han
	addb	#2
fi_limit_00:
	asl	fi_basic+1
	rol	fi_basic
	decb
	bne	fi_limit_00
	ldaa	fi_basic
	cmpa	#>2000
	bcs	fi_limit_03
	bhi	fi_limit_01
	ldaa	fi_basic+1
	cmpa	#<2000
	bls	fi_limit_03
fi_limit_01:
	ldx	#2000
fi_limit_02:
	stx	fi_basic
fi_limit_03:
	rts

; Convert winning basic points to best_pts, including honba and pool.
fi_pay:
	jsr	score_total
	; Someone goes below zero long before 86 honba or 26 riichi sticks, so
	; honba*3 and kyotaku*10 fit a byte each; their sum may carry into A.
	ldab	honba
	aslb
	addb	honba
	ldaa	kyotaku
	asla
	asla
	adda	kyotaku
	asla
	aba
	tab
	ldaa	#0
	rola
	addb	wk_num+1
	adca	wk_num
	staa	best_pts
	stab	best_pts+1
	rts

; B = total yakuman han (13,26,...). Returns fi_basic; preserves no registers.
yakuman_basic:
 clr fi_basic
 clr fi_basic+1
yakuman_basic_00:
 ldaa fi_basic+1
 adda #<8000
 staa fi_basic+1
 ldaa fi_basic
 adca #>8000
 staa fi_basic
 subb #13
 bne yakuman_basic_00
 rts

; Compare basic points, then han and fu; payout is monotone on legal inputs.
; Returns with N and Z set from A.
fi_better:
	ldaa	fi_basic
	cmpa	best_pts
	bhi	fi_better_01
	bcs	fi_better_00
	ldaa	fi_basic+1
	cmpa	best_pts+1
	bhi	fi_better_01
	bcs	fi_better_00
	ldaa	fi_han
	cmpa	best_han
	bhi	fi_better_01
	bcs	fi_better_00
	ldaa	fi_fu
	cmpa	best_fu
	bhi	fi_better_01
fi_better_00:
	clra
	rts
fi_better_01:
	ldaa	#1
	rts

; wk_num = wk_num / dv_divisor (div8_a: A), A = remainder.
div8_a:
 staa dv_divisor
div8:
	clra
	ldab	#16
div8_00:
	asl	wk_num+1
	rol	wk_num
	rola
	cmpa	dv_divisor
	bcs	div8_01
	suba	dv_divisor
	inc	wk_num+1
div8_01:
	decb
	bne	div8_00
	rts

; Han closed, han open (0 = closed only).
yaku_han:
	.byte	1,0,2,0,1,0,1,0,1,0,1,1,1,0,1,1
	.byte	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.byte	2,1,2,1,2,1,2,0,2,2,2,2,2,2,2,2
	.byte	2,2,2,2,3,0,3,2,3,2,6,5

	.bss
; win_kind is allocated in directpage.asm.
tsumo_flag:	.ds	1 ; 1 for tsumo
seat_kind:	.ds	1 ; seat wind kind
round_kind:	.ds	1 ; round wind kind
dealer_flag:	.ds	1 ; 1 for the dealer
; sflags is allocated in directpage.asm.
; dora_n is allocated in directpage.asm.
; aka_n is allocated in directpage.asm.
; ura_n is allocated in directpage.asm.
; best_fu is allocated in directpage.asm.
; best_n is allocated in directpage.asm.
best_y:	.ds	16 ; yaku of the best result
closed_flag:	.ds	1 ; 1 when the hand is closed
nkan:	.ds	1 ; kans
; attr_and is allocated in directpage.asm.
an_x:	.ds	2 ; work entry analyse checks
fy_trip:	.ds	1 ; wind triplets
fy_pair:	.ds	1 ; wind pairs
ym_extra:	.ds	1 ; extra yakuman han
cur_n:	.ds	1 ; yaku of the decomposition
cur_han:	.ds	1 ; its han
; cur_fu is allocated in directpage.asm.
; head_kind is allocated in directpage.asm.
btype:	.ds	4 ; block types
bkind:	.ds	4 ; block kinds
ep_i:	.ds	1 ; block index
ep_kind:	.ds	1 ; first kind of the block
ep_off:	.ds	1 ; place of the winning tile in the sequence
; ed_wait is allocated in directpage.asm.
ed_wi:	.ds	1 ; block of the winning tile
ed_yhead:	.ds	1 ; fu of the head (head_fu): nonzero for a yakuhai head
ed_pinfu:	.ds	1 ; 1 for pinfu
n_seq:	.ds	1 ; sequences
n_trip:	.ds	1 ; triplets
n_conc:	.ds	1 ; concealed triplets and kans
trip_n:	.ds	KN ; triplets of each kind
seq_n:	.ds	KN ; sequences from each kind
cl_i:	.ds	1 ; block index
ab_index:	.ds	1 ; block index
block_fu:	.ds	1 ; fu of the block
; fi_han is allocated in directpage.asm.

sbt_swapped:	.ds	1 ; nonzero when a pass swapped
; dv_divisor is allocated in directpage.asm.
sort_base: .ds 2 ; array being sorted
sort_n: .ds 1 ; its length

 .code
; A = regular yaku number (0..29), returns A = han for closed_flag.
; Returns with N and Z set from A.
reg_yaku_han:
 asla
 tab
 ldx #yaku_han
 jsr addxb
 tst closed_flag
 bne reg_yaku_han_00
 inx
reg_yaku_han_00:
 ldaa 0,x
 rts
