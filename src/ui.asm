; Fixed 256x192 layout: three CPU bands, human river, large human hand.
; Pixel coordinates are used for the 12x12 sprites; all tile faces are upright.
draw_hand:
ui_hand:
 staa ht_p
 beq ui_human
 jsr ui_band
 stab sm_y
 clr dh_i
 clr ui_faces
 ldaa ht_p
 jsr player
 ldaa P_LEN,x
 staa ht_n
 ldx #ui_back_n
 ldab ht_p
 jsr addxb
 ldab ht_p
 jsr player_bit
 anda reveal
 bne ui_cpu_uncached
 tst open_mode
 bne ui_cpu_uncached
ui_cpu_cache:
 ldaa 0,x
 cmpa #$FF
 beq ui_cpu_cache_new
 cmpa ht_n
 bls ui_cpu_prefix
 ldaa ht_n
ui_cpu_prefix:
 staa dh_i
ui_cpu_cache_new:
 ldaa ht_n
 staa 0,x
 bra ui_cpu_erase
ui_cpu_uncached:
 inc ui_faces
 ldaa #$FF
 staa 0,x
ui_cpu_erase:
 ldaa dh_i
 jsr mul12
 stab sm_x
ui_cpu_tiles:
 ldaa dh_i
 cmpa ht_n
 beq ui_cpu_tail
 ldaa #IMG_BACK
 tst ui_faces
 beq ui_cpu_face
 ldaa ht_p
 ldab dh_i
 jsr hand_at
 jsr img_of_b
ui_cpu_face:
 clrb
 jsr smalltile_advance
 inc dh_i
 bra ui_cpu_tiles
; The tiles and the furo are drawn over the old ones. Erases only the places
; that can become empty: after a new furo, all after the hand; else the place
; between the hand and the furo.
ui_cpu_tail:
 ldaa ht_p
 jsr player
 ldaa P_NFURO,x
 ldx #ui_furo_n
 ldab ht_p
 jsr addxb
 ldab 0,x
 staa 0,x
 cba
 beq ui_cpu_gap
 ldaa #180
 bra ui_cpu_tail_00
ui_cpu_gap:
 tab
 bsr ui_furo_x
ui_cpu_tail_00:
 suba sm_x
 beq ui_cpu_furo
 staa ui_width
 ldaa #12
 jsr ui_erase_px
ui_cpu_furo:
 ldaa ht_p
 jsr player
 ldab P_NFURO,x
 bsr ui_furo_x
 staa sm_x
 jmp ui_furo_small
; B = number of the furo of a CPU. Returns A = x of the furo (168 - 36 * B).
ui_furo_x:
 aslb
 aslb
 ldaa #168
 sba
 aslb
 aslb
 aslb
 sba
 rts
; Draws the own hand (large when ui_big is set).
ui_human:
 ldaa #ROW_OWN_HAND
 staa posy
 tst ui_big
 beq ui_human_tiles
 clr posx
 ldaa #32
 ldab #3
 jsr erase
ui_human_tiles:
 ldaa ht_p
 jsr player
 ldaa P_LEN,x
 staa ht_n
 clr dh_i
ui_human_00:
 ldaa dh_i
 cmpa ht_n
 beq ui_human_furo
 jsr ot_hand_tile_x
 ldaa #ROW_OWN_HAND
 staa posy
 ldaa ht_p
 ldab dh_i
 jsr hand_at
 jsr img_of_b
 jsr drawtile
 inc dh_i
 bra ui_human_00
ui_human_furo:
 ; The ron discard stays out of the live hand; append it only on the yaku page.
 tst ui_big
 beq ui_human_tmode
 tst tsumo_flag
 bne ui_human_tmode
 ldaa ht_n
 asla
 inca
 staa posx
 ldaa #ROW_OWN_HAND
 staa posy
 ldaa win_tile
 jsr img_of
 jsr drawtile
ui_human_tmode:
 tst ui_big
 bne ui_human_erased
 ldaa ht_n
 deca
 jsr ot_hand_tile_x
 ldaa ht_p
 jsr player
 ldaa P_DRAWN,x
 cmpa #$FF
 beq ui_human_tail
 dec posx
 ldaa #1
 ldab #3
 jsr erase
 inc posx
ui_human_tail:
 inc posx
 inc posx
 ldaa ht_p
 jsr player
 ldab P_NFURO,x
 aslb
 ldaa #32
 sba
 aslb
 sba
 suba posx
 bls ui_human_erased
 ldab #3
 jsr erase
ui_human_erased:
 tst ui_big
 bne ui_human_nocur
 jsr arrow_full
ui_human_nocur:
 jsr ui_furo_big
 tst ui_big
 bne ui_hand_done
 tst chi_mode
 beq ui_hand_done
 ldaa chi_i1
 asla
 staa posx
 ldaa #23
 staa posy
 jsr select_arrow
 ldaa chi_i2
 asla
 staa posx
 jsr select_arrow
ui_hand_done:
 rts

; A=CPU player 1..3 -> B=top pixel row.
ui_band:
 deca
 ldab #42
 jsr mul8
 addb #9
 rts

; A = player, B = furo index. Makes it the furo being drawn: df_rec = its
; record, df_type = its type (M_*), df_rot = the place of its called tile
; (0 from the player before, 1 from across, 2 from the next player; $FF for
; a concealed kan).
furo_select:
 psha
 pshb
 jsr player
 pula
 tab
 asla
 aba
 adda #P_FURO
 tab
 jsr addxb
 stx df_rec
 ldaa 0,x
 anda #3
 staa df_type
 pulb
 ldaa 2,x
 cmpa #$FF
 beq furo_select_01
 sba
 anda #3
 beq furo_select_00
 nega
 adda #3
 bra furo_select_01
furo_select_00:
 ldaa #$FF
furo_select_01:
 staa df_rot
 rts

; X = furo record, B = tile place (0-2). Returns A = image of the tile shown
; there. A chi shows the called tile first, then the other two in order; a
; concealed kan shows only its middle tile.
furo_img:
 ldaa 0,x
 anda #3
 cmpa #M_ANKAN
 bne furo_img_00
 cmpb #1
 beq furo_img_00
 ldaa #IMG_BACK
 rts
furo_img_00:
 ; df_o: place of the tile among the tiles of the furo, in kind order.
 cmpa #M_CHI
 bne furo_img_02
 ldaa 0,x
 lsra
 lsra
 anda #3
 tstb
 beq furo_img_03
 decb
 cba
 bhi furo_img_02
 incb
furo_img_02:
 tba
furo_img_03:
 staa df_o
 ldaa 1,x
 ldab 0,x
 bitb #3
 bne furo_img_04
 adda df_o
furo_img_04:
 asla
 tstb
 bpl furo_img_05
 lsrb
 lsrb
 lsrb
 lsrb
 andb #3
 cmpb df_o
 bne furo_img_05
 inca
furo_img_05:
 jmp img_of

; Draws the furo of the CPU ht_p with small tiles from sm_x at sm_y. The
; called tile is turned; an open kan shows it one row lower than a pon (the
; empty row is above the tile instead of below it).
ui_furo_small:
 ldaa ht_p
 jsr player
 ldaa P_NFURO,x
 staa df_n
 clr df_i
ui_furo_small_00:
 ldaa df_i
 cmpa df_n
 beq ui_furo_small_03
 ldaa sm_x
 adda #4
 staa sm_x
 ldaa ht_p
 ldab df_i
 jsr furo_select
 clr df_j
ui_furo_small_01:
 ldx df_rec
 ldab df_j
 jsr furo_img
 ldab sm_y
 pshb
 psha
 clrb
 ldaa df_j
 cmpa df_rot
 bne ui_furo_small_02
 ldaa df_type
 cmpa #M_MINKAN
 bne ui_furo_small_turned
 ldaa #12
 staa ui_width
 ldaa #1
 jsr ui_erase_px
 inc sm_y
ui_furo_small_turned:
 ldab #RF_RIICHI
ui_furo_small_02:
 pula
 jsr smalltile_advance
 pula
 staa sm_y
 inc df_j
 ldaa df_j
 cmpa #3
 bne ui_furo_small_01
 inc df_i
 bra ui_furo_small_00
ui_furo_small_03:
 rts

; Draws the furo of ht_p with large tiles in the own hand row, the first at
; column 26 and each next 6 columns to the left. A dot marks the called
; tile, and K marks a kan (without a fourth tile).
ui_furo_big:
 ldaa ht_p
 jsr player
 ldaa P_NFURO,x
 staa df_n
 clr df_i
 ldaa #26
 staa df_cx
ui_furo_big_00:
 ldaa df_i
 cmpa df_n
 beq ui_furo_big_03
 ldaa ht_p
 ldab df_i
 jsr furo_select
 clr df_j
ui_furo_big_01:
 ldx df_rec
 ldab df_j
 jsr furo_img
 ldab df_j
 aslb
 addb df_cx
 stab posx
 ldab #ROW_OWN_HAND
 stab posy
 jsr drawtile
 inc df_j
 ldaa df_j
 cmpa #3
 bne ui_furo_big_01
 ldaa df_type
 cmpa #M_MINKAN
 bcs ui_furo_big_02
 ldaa df_cx
 adda #2
 asla
 asla
 asla
 adda #5
 staa px_x
 ldaa #163
 staa px_y
 ldx #kan_icon
 jsr ui_shape_set
ui_furo_big_02:
 ldaa df_rot
 bmi ui_furo_big_next
 asla
 adda df_cx
 asla
 asla
 asla
 adda #7
 staa px_x
 ldaa #166
 staa px_y
 ldx #shape_dot
 jsr ui_shape_set
ui_furo_big_next:
 ldaa df_cx
 suba #6
 staa df_cx
 inc df_i
 bra ui_furo_big_00
ui_furo_big_03:
 rts

; A = player, B = index in the river. Called tiles are not shown; the
; others are shown in order.
draw_river_tile:
ui_river_tile:
 staa rvt_player
 stab rvt_index
 jsr player
 addb #P_RFLAG
 jsr addxb
 ldaa 0,x
 staa rvt_flag
 ldab rvt_index
 stab rvt_pos
ui_river_pos:
 ldaa rvt_player
 jsr ui_river_y
 stab sm_y
 ldaa rvt_pos
 cmpa #14
 bcs ui_river_x
 suba #14
 ldab sm_y
 addb #13
 stab sm_y
ui_river_x:
 jsr mul12
 stab sm_x
 ldaa rvt_player
 jsr player
 ldab rvt_index
 addb #P_RIVER
 jsr addxb
 ldaa 0,x
 jsr img_of
 staa rvt_img
 ldab rvt_flag
 jsr smalltile
 jsr river_footer
 ldaa rvt_flag
 bita #RF_CALLED
 beq ui_river_tile_00
 ldaa rvt_img
 cmpa #25
 bne ui_river_mleft
 ldaa #3
 bra ui_river_mark_x
ui_river_mleft:
 clra
ui_river_mark_x:
 adda sm_x
 staa px_x
 ldaa sm_y
 adda #11
 ldab rvt_flag
 bitb #RF_RIICHI
 beq ui_river_mark_y
 deca
ui_river_mark_y:
 staa px_y
 clr px_ink
 ldx #shape_gap
 jsr ui_shape
ui_river_tile_00:
 rts
; A = player. Returns B = pixel row of its river.
ui_river_y:
 tsta
 bne ui_river_y_00
 ldab #135
 rts
ui_river_y_00:
 ; One black row between the hand and the river.
 jsr ui_band
 addb #13
 rts
; A = player. Erases and redraws its river.
ui_river_draw:
 staa rr_p
 jsr ui_river_y
 stab sm_y
 clr sm_x
 ldaa #240
 staa ui_width
 ldaa #26
 jsr ui_erase_px
 clr rr_k
ui_river_draw_00:
 ldaa rr_p
 jsr player
 ldaa rr_k
 cmpa P_RLEN,x
 beq ui_river_draw_01
 ldaa rr_p
 ldab rr_k
 jsr ui_river_tile
 inc rr_k
 bra ui_river_draw_00
ui_river_draw_01:
 rts
; Redraws the header, the rivers, the hands and the scores.
redraw_all:
 jsr ui_header
 clr ui_all
redraw_all_00:
 ldaa ui_all
 jsr ui_river_draw
 inc ui_all
 ldaa ui_all
 cmpa #4
 bne redraw_all_00
 clr ui_all
redraw_all_01:
 ldaa ui_all
 jsr draw_hand
 inc ui_all
 ldaa ui_all
 cmpa #4
 bne redraw_all_01
 jmp ui_scores
; Redraws the header and the scores.
draw_info:
 jsr ui_header
 jmp ui_scores
; After a draw: the tiles left and the turn marks.
draw_nokori:
 jsr ui_nokori
 jmp ui_turn
; Draws the round, the honba and the dora indicators over the old ones. Each
; item keeps its place and width, and the stick of the deposits and the dora
; indicators only increase in a round (clear_screen starts each round).
ui_header:
 ldx #0*256+0
 stx posx
 ldx #s_ton
 ldaa round
 cmpa #4
 bcs ui_header_00
 ldx #s_nan
ui_header_00:
 jsr drawstr
 ldaa round
 anda #3
 adda #CH_0+1
 jsr drawchar
 ldaa #4
 staa posx
 ldaa honba
 ldab #1
 jsr print_byte_num
 ldx #s_honba
 jsr drawstr
 jsr ui_nokori
 ldaa kyotaku
 beq ui_header_dora
 ldaa #120
 staa stick_x
 ldaa #2
 staa px_y
 ldaa #1
 staa stick_ink
 jsr stick_draw
 ldaa #18
 staa posx
 ldaa kyotaku
 ldab #2
 jsr print_byte_num
; Shared by the table header and the yaku page: five indicators fit at x=192.
ui_header_dora:
 ldx #22*256+0
 stx posx
 ldx #s_dora
 jsr drawstr
 clra
; A = 0 for the dora indicators, 1 for the ura dora indicators. Draws them
; from x = 192, y = 16 * A.
ui_indicators:
 tab
 aslb
 aslb
 aslb
 aslb
 stab sm_y
 adda #DORA_POS
 staa dd_first
 ldaa #192
 staa sm_x
 clr dd_i
ui_indicators_00:
 ldaa dd_i
 cmpa dora_cnt
 beq ui_indicators_01
 tab
 aslb
 negb
 addb dd_first
 jsr wall_x
 ldaa 0,x
 jsr img_of
 clrb
 jsr smalltile_advance
 inc dd_i
 bra ui_indicators_00
ui_indicators_01:
 rts
; Draws the scores of the players.
ui_scores:
 clr ui_sp
ui_scores_00:
 ldaa ui_sp
 jsr ui_turn_mark
 inc posx
 jsr draw_seat_wind
 ldaa ui_sp
 jsr player
 ldx P_SCORE,x
 jsr print_score
 jsr ui_stick
 inc ui_sp
 ldaa ui_sp
 cmpa #4
 bne ui_scores_00
 tst demo
 beq ui_scores_05
 ldx #24*256+18
 stx posx
 ldx #s_demo_key
 jsr drawstr
 ldx #24*256+19
 stx posx
 ldx #s_demo_end
 jmp drawstr
ui_scores_05:
 rts
wind_names:
 .word s_ton,s_nan,s_sha,s_pe
; Draws the turn marks of the four players.
ui_turn:
 ldaa #3
ui_turn_00:
 psha
 bsr ui_turn_mark
 pula
 deca
 bpl ui_turn_00
 rts
; A = player. Draws his turn mark (CH_TURN in turn, else a space) at the
; start of his line of the scores, and leaves posx and posy there.
ui_turn_mark:
 psha
 tab
 ldx #ui_score_rows
 jsr addxb
 ldab 0,x
 ldaa #23
 staa posx
 stab posy
 pulb
 ldaa #CH_SP
 cmpb turn
 bne ui_turn_mark_02
 ldaa #CH_TURN
ui_turn_mark_02:
 jmp drawchar
; posy of the line of the scores of players 0-3. The lines of the CPUs are
; the first text rows in their bands (ui_band).
ui_score_rows:
 .byte 16,2,7,12
; Draws the tiles left in the header.
ui_nokori:
 ldx #9*256+0
 stx posx
 ldx #s_nokori
 jsr drawstr
 ldaa draws_left
 ldab #2
 jmp print_byte_num

; Draw one small tile, then move to the next tile position.
smalltile_advance:
 jsr smalltile
 ldaa sm_x
 adda #12
 staa sm_x
 rts

; A = image, X = set (huff.py): rows, width (1 or 2 bytes), group table,
; IMG_COUNTS counts of codes of each length, dictionary of rows. Writes the
; rows of the image to img_rows.
IMG_COUNTS .equ 10
img_decode:
 psha
 ldab 0,x
 stab td_n
 ldab 1,x
 stab td_wide
 stx td_cp
 ldx 2,x
 lsra
 lsra
 lsra
 asla
 tab
 jsr addxb
 ldx 0,x
 stx td_src
 ldx td_cp
 ldab #4
 jsr addxb
 stx td_counts
 ; td_skip = rows of the images before it in its group of 8.
 pula
 anda #7
 ldab td_n
 jsr mul8
 stab td_skip
 clr td_acc
 ldx #img_rows
 stx td_dst
img_decode_00:
 ; td_code = the code read so far less the first code of its length;
 ; td_base = the codes shorter than it.
 clr td_code
 clr td_base
 ldx td_counts
img_decode_01:
 ; td_acc holds the bits not used yet, then a 1.
 asl td_acc
 bne img_decode_02
 stx td_cp
 ldx td_src
 ldaa 0,x
 inx
 stx td_src
 ldx td_cp
 sec
 rola
 staa td_acc
img_decode_02:
 rol td_code
 ldaa td_code
 suba 0,x
 bcs img_decode_03
 staa td_code
 ldaa td_base
 adda 0,x
 staa td_base
 inx
 bra img_decode_01
img_decode_03:
 tst td_skip
 beq img_decode_04
 dec td_skip
 bra img_decode_00
img_decode_04:
 ldab td_code
 addb td_base
 tst td_wide
 beq img_decode_05
 aslb
img_decode_05:
 addb #IMG_COUNTS
 ldx td_counts
 jsr addxb
 ldaa 0,x
 ldab 1,x
 ldx td_dst
 tst td_wide
 beq img_decode_07
 ; Bit 0 of the second byte: the row before again (huff.REPEAT).
 bitb #1
 beq img_decode_06
 dex
 dex
 ldaa 0,x
 ldab 1,x
 inx
 inx
img_decode_06:
 stab 1,x
img_decode_07:
 staa 0,x
 inx
 tst td_wide
 beq img_decode_08
 inx
img_decode_08:
 stx td_dst
 dec td_n
 bne img_decode_00
 rts

; 12 rows * 12 pixels at sm_x (a multiple of 4) and sm_y. Preserves sm_x/sm_y.
smalltile:
 stab sm_flags
 ldx #small_set
 jsr img_decode
 ldx #img_rows
 stx sm_src
 ldaa sm_flags
 bita #RF_RIICHI
 beq small_upright
 jsr sm_turn
small_upright:
 ldaa sm_y
 ldab sm_x
 jsr pixel_address
 staa sm_dst
 stab sm_dst+1
 ldaa sm_x
 anda #4
 staa sm_align
 clr sm_row
smalltile_00:
 ldaa sm_flags
 bita #RF_RIICHI
 bne small_row_turned
 ldx sm_src
 inx
 inx
 stx sm_src
 dex
 dex
 bra small_row_bits
small_row_turned:
 ldab sm_row
 aslb
 ldx #sm_rot
 jsr addxb
small_row_bits:
 ldaa 0,x
 ldab 1,x
 staa sm_bits
 stab sm_bits+1
 ldx sm_dst
 tst sm_align
 beq small_aligned
 ldab #4
small_shift4:
 lsr sm_bits
 ror sm_bits+1
 decb
 bne small_shift4
 ldaa 0,x
 anda #$F0
 oraa sm_bits
 staa 0,x
 ldab sm_bits+1
 stab 1,x
 bra small_next_row
small_aligned:
 ldaa sm_bits
 staa 0,x
 ldab 1,x
 andb #$0F
 orab sm_bits+1
 stab 1,x
small_next_row:
 ldaa sm_dst+1
 adda #32
 staa sm_dst+1
 bcc smalltile_10
 inc sm_dst
smalltile_10:
 inc sm_row
 ldaa sm_row
 cmpa #12
 bne smalltile_00
 rts

; Turns the 11x11 face of the tile in img_rows a quarter turn
; counterclockwise into sm_rot; the border row and column stay empty.
; img_rows is used up.
sm_turn:
 ldx #sm_rot+20
 stx sm_tp
 ldab #11
 stab sm_n
sm_turn_00:
 clr sm_w
 clr sm_w+1
 ldx #img_rows
turn90_col:
 asl 1,x
 rol 0,x
 rol sm_w+1
 rol sm_w
 inx
 inx
 cpx #img_rows+22
 bne turn90_col
 ldab #5
turn90_align_w:
 asl sm_w+1
 rol sm_w
 decb
 bne turn90_align_w
 ldx sm_tp
 ldaa sm_w
 staa 0,x
 ldaa sm_w+1
 staa 1,x
 dex
 dex
 stx sm_tp
 dec sm_n
 bne sm_turn_00
 clr sm_rot+22
 clr sm_rot+23
 rts

; X = shape: rows, box (16 bits, bit 15 at px_x), then the bits of each row.
; From px_x, px_y down, replaces the box of each row with the bits (px_ink
; nonzero) or with 0. ui_shape_set sets px_ink. px_y ends below the shape.
ui_shape_set:
 ldaa #1
 staa px_ink
ui_shape:
 ldaa 0,x
 staa sm_n
 ldaa 1,x
 ldab 2,x
 inx
 inx
 inx
 stx sm_src
 bsr ui_shape_shift
 coma
 comb
 staa sm_w
 stab sm_w+1
ui_shape_00:
 ldx sm_src
 ldaa 0,x
 ldab 1,x
 inx
 inx
 stx sm_src
 tst px_ink
 bne ui_shape_01
 clra
 clrb
ui_shape_01:
 bsr ui_shape_shift
 ldaa px_y
 ldab px_x
 jsr pixel_address
 staa px_addr
 stab px_addr+1
 ldx px_addr
 ldaa 0,x
 anda sm_w
 oraa sm_bits
 staa 0,x
 ldaa 1,x
 anda sm_w+1
 oraa sm_bits+1
 staa 1,x
 inc px_y
 dec sm_n
 bne ui_shape_00
 rts
; Returns A:B (and sm_bits) = A:B shifted right by px_x & 7.
ui_shape_shift:
 staa sm_bits
 stab sm_bits+1
 ldab px_x
 andb #7
 beq ui_shape_shift_01
ui_shape_shift_00:
 lsr sm_bits
 ror sm_bits+1
 decb
 bne ui_shape_shift_00
ui_shape_shift_01:
 ldaa sm_bits
 ldab sm_bits+1
 rts
shape_mark:
 .byte 3,$F8,0,$20,0,$70,0,$F8,0
shape_tsumo:
 .byte 4,$FF,$E0,4,0,$0E,0,$1F,0,0,0
shape_footer:
 .byte 2,$FF,$F0,$FF,$E0,0,0
shape_gap:
 .byte 1,$C0,0,0,0
shape_dot:
 .byte 1,$80,0,$80,0
cursor_icon:
 .byte 3,$F8,0,$F8,0,$70,0,$20,0
kan_icon:
 .byte 5,$F8,0,$88,0,$90,0,$E0,0,$90,0,$88,0

; A = rows. Erases ui_width pixels of each row at sm_x, sm_y.
ui_erase_px:
 ; Hand suffixes start on a byte or half-byte; river erases start at x=0.
 staa ui_height
 ldaa sm_x
 anda #4
 staa ui_first
 ldaa ui_width
 suba ui_first
 staa ui_bytes
 anda #7
 staa ui_tail
 ldaa ui_bytes
 lsra
 lsra
 lsra
 staa ui_bytes
 ldaa sm_y
 ldab sm_x
 jsr pixel_address
 staa ui_dst
 stab ui_dst+1
ui_erase_px_00:
 ldx ui_dst
 tst ui_first
 beq ui_erase_px_01
 ldaa 0,x
 anda #$F0
 staa 0,x
 inx
ui_erase_px_01:
 ldab ui_bytes
ui_erase_px_02:
 clr 0,x
 inx
 decb
 bne ui_erase_px_02
 tst ui_tail
 beq ui_erase_px_03
 ldaa 0,x
 anda #$0F
 staa 0,x
ui_erase_px_03:
 ldaa ui_dst+1
 adda #32
 staa ui_dst+1
 bcc ui_erase_px_04
 inc ui_dst
ui_erase_px_04:
 dec ui_height
 bne ui_erase_px_00
 rts
 .bss
; sm_x is allocated in directpage.asm.
; sm_y is allocated in directpage.asm.
img_rows: .ds 48 ; output of img_decode: the rows of the image
td_src: .ds 2 ; img_decode: next byte of the code
td_acc: .ds 1 ; img_decode: bits of the byte not used yet, then a 1
td_dst: .ds 2 ; img_decode: next row of img_rows
td_counts: .ds 2 ; img_decode: counts of the set, then the dictionary
td_wide: .ds 1 ; img_decode: 1 for rows of 2 bytes
td_skip: .ds 1 ; img_decode: rows to read past
td_cp: .ds 2 ; img_decode: next count
td_code: .ds 1 ; img_decode: code less the first code of its length
td_base: .ds 1 ; img_decode: codes shorter than td_code
td_n: .ds 1 ; img_decode: rows left
; sm_src is allocated in directpage.asm.
sm_bits: .ds 2 ; row bits
sm_row: .ds 1 ; row index
; px_x is allocated in directpage.asm.
; px_y is allocated in directpage.asm.
; px_ink is allocated in directpage.asm.
px_addr: .ds 2 ; pixel byte address
ui_width: .ds 1 ; width
ui_height: .ds 1 ; height
ui_all: .ds 1 ; player whose river is redrawn
; ui_sp is allocated in directpage.asm.

 .code
; Draws the hand of the player in turn large.
ui_winning_hand:
 ldaa #1
 staa ui_big
 ldaa turn
 staa ht_p
 jsr ui_human
 clr ui_big
 rts

; Reveal and redraw only the winner's hand, preserving the table and the river marker.
ui_win_reveal:
 ldab turn
 jsr player_bit
 staa reveal
 ldaa turn
 jsr draw_hand
 clr reveal
 rts

; Draw the source triangle under the winning tile on a tsumo.
ui_mark_tsumo:
 ldaa turn
 staa ht_p
 jsr player
 ldaa P_LEN,x
 staa ht_n
 deca
 staa ot_i
 ldab ht_p
 bne ui_mark_tsumo_00
 jsr hand_tile_x
 ldaa posx
 asla
 asla
 asla
 adda #7
 staa mark_tip
 ldab #164
 bra ui_mark_tsumo_01
ui_mark_tsumo_00:
 ldaa ot_i
 jsr mul12
 addb #5
 stab mark_tip
 ldaa turn
 jsr ui_band
 ; The tip sits on the black row between the hand and the river.
 addb #12
ui_mark_tsumo_01:
 stab mark_top
	ldaa	#1
	staa	mark_live
	staa	px_ink
	; A black box as wide as the tile keeps the mark visible over a white river tile.
	ldx	#shape_tsumo
	ldab	#5
	jmp	rmark_shape
; Redraws the scores and the riichi-denied message.
draw_riichi:
 jsr ui_scores
 tst riichi_reject
 beq draw_riichi_01
 ldaa #27
 staa posx
 staa riichi_hint_x
 ldaa #19
 staa posy
 ldaa #1
 staa riichi_hint_live
 ldx #s_riichi_denied
 jsr drawstr
draw_riichi_01:
 rts
 .bss
ui_big: .ds 1 ; nonzero for large tiles
ui_faces: .ds 1 ; nonzero when ui_hand draws the faces of CPU tiles
df_rec: .ds 2 ; furo record being drawn
df_rot: .ds 1 ; place of the called tile ($FF for none)
df_o: .ds 1 ; place of the tile among the tiles of the furo (furo_img)

sm_dst: .ds 2 ; screen address
sm_align: .ds 1 ; bit offset
sm_n: .ds 1 ; rows left
sm_w: .ds 2 ; bits of the column
sm_tp: .ds 2 ; pointer into sm_rot

sm_rot: .ds 24 ; rotated face
ui_dst: .ds 2 ; screen address
ui_tail: .ds 1 ; pixels after the last whole byte
ui_bytes: .ds 1 ; whole bytes

ui_back_n: .ds 4 ; hidden tiles drawn for each player ($FF = none)
ui_furo_n: .ds 4 ; furo drawn for each CPU

ui_first: .ds 1 ; pixels before the first whole byte
 .code
; Redraw the most recent discard, including its updated flags.
ui_latest_discard:
 ldaa discarder
 jsr player
 ldab P_RLEN,x
 decb
 ldaa discarder
 jmp ui_river_tile

; Latest discard marker and native-font reaction keys.
hint_start:
 jsr ui_latest_discard
 ldaa sm_x
 adda #19
 anda #$F8
 cmpa #224
 bls hint_start_00
 ldaa #224
hint_start_00:
 staa hint_origin
 staa hint_x
 ldaa sm_y
 ; The letters are centered on the 11 pixel face of the discard.
 adda #2
 staa hint_y
 rts
; B = hint character index. Adds it to the hint row.
hint_add:
 ldx #hint_chars
 jsr addxb
 ldaa hint_y
 ldab hint_x
 jsr ui_glyphs_px
 ldab hint_x
 addb #8
 stab hint_x
 rts
; Removes the hint row.
hint_clear:
 ldaa hint_x
 ldab hint_origin
 stab hint_x
 sba
 beq hint_clear_00
 staa ui_width
 stab sm_x
 ldaa hint_y
 staa sm_y
 ldaa #8
 jsr ui_erase_px
 ; Four letters beside the last tile of the first river row reach the riichi
 ; stick of the discarder (a CPU); draw the stick again.
 ldaa discarder
 staa ui_sp
 jsr ui_turn_mark
 jmp ui_stick
hint_clear_00:
 rts
hint_chars:
 ; One-character strings for ui_glyphs_px.
 .byte CH_C+$80,CH_P+$80,CH_K+$80,CH_R+$80
; Erase the previous marker before drawing the next discard.
mark_clear:
 tst mark_live
 beq river_mark_done
 clr px_ink
 jsr rmark_pixels
 clr mark_live
river_mark_done:
 rts
; Draws the marker under the last discard.
river_mark:
 tst dc_p
 beq river_mark_done
 ldaa sm_x
 adda #5
 staa mark_tip
 ldaa sm_y
 adda #13
 staa mark_top
 ldaa #1
 staa mark_live
 staa px_ink
; Draws the marker (widths 1, 3, 5) with px_ink.
rmark_pixels:
 ldx #shape_mark
 ldab #2
; X = shape, B = its pixels left of mark_tip. Draws it from mark_top.
rmark_shape:
 ldaa mark_tip
 sba
 staa px_x
 ldaa mark_top
 staa px_y
 jmp ui_shape
 .bss
hint_x: .ds 1 ; pixel column of the next hint letter
hint_origin: .ds 1 ; pixel column of the first hint letter
hint_y: .ds 1 ; hint pixel row
mark_live: .ds 1 ; nonzero while the river marker is shown
; mark_tip is allocated in directpage.asm.
mark_top: .ds 1 ; marker top row

 .code
; Fixed under the seat name, outside the two-row river.
ui_stick:
 clr stick_ink
 ldaa ui_sp
 jsr player
 tst P_FLAG,x
 bpl ui_stick_00
 inc stick_ink
ui_stick_00:
 ldaa posy
 asla
 asla
 asla
 adda #10
 staa px_y
 ldaa #192
 staa stick_x
; Draws a riichi stick (24 x 3 pixels, a dot at 11-13 of the middle row) at
; stick_x (a multiple of 8) and px_y; stick_ink = 0 erases it.
stick_draw:
 ldaa px_y
 ldab stick_x
 jsr pixel_address
 staa px_addr
 stab px_addr+1
 ldx px_addr
 ldaa #$FF
 ldab #$E3
 tst stick_ink
 bne stick_draw_00
 clra
 clrb
stick_draw_00:
 staa 0,x
 staa 1,x
 staa 2,x
 staa 32,x
 stab 33,x
 staa 34,x
 staa 64,x
 staa 65,x
 staa 66,x
 rts
 .bss

stick_ink: .ds 1 ; riichi stick color

; stick_x is allocated in directpage.asm.
 .code
; A = player index. Draw at current posx/posy, preserving screen layout.
draw_name:
 psha
 ldx #s_result_self
 tsta
 beq draw_name_00
 ldx #s_result_cpu
draw_name_00:
 jsr drawstr
 pula
 tsta
 beq draw_name_01
 adda #CH_0
 jmp drawchar
draw_name_01:
 rts
; ui_sp = player index. Selects its current seat wind and draws it.
draw_seat_wind:
 ldaa ui_sp
; A = player index. Draw the player's seat wind at the current position.
draw_wind_for_player:
 suba dealer
 anda #3
 asla
 tab
 ldx #wind_names
 jsr addxb
 jmp drawstr_x

; A=y, B=x. Return A:B = $0900 + y*32 + x/8.
pixel_address:
 pshb
 clrb
 lsra
 rorb
 lsra
 rorb
 lsra
 rorb
 adda #9
 staa addxb_tmp
 pula
 lsra
 lsra
 lsra
 aba
 tab
 ldaa addxb_tmp
 rts

; Draws the 2 rows under the 11-row face of a river tile (sm_x, sm_y + 11):
; white under an upright tile, black under a turned (riichi) one.
river_footer:
 ldaa sm_y
 adda #11
 staa px_y
 ldaa sm_x
 staa px_x
 clr px_ink
 ldaa sm_flags
 bita #RF_RIICHI
 bne river_footer_00
 inc px_ink
river_footer_00:
 ldx #shape_footer
 jmp ui_shape
