; Fixed 256x192 layout: three CPU bands, human river, large human hand.
; Pixel coordinates are used for the 12x12 sprites; all tile faces are upright.
draw_hand:
ui_hand:
 staa ht_p
 tsta
 beq ui_human
 jsr ui_band
 staa sm_y
 clr dh_i
 clr ui_faces
 ldaa ht_p
 jsr player
 ldaa P_LEN,x
 staa ht_n
 ldx #ui_back_n
 ldab ht_p
 jsr addxb
 tst reveal
 beq ui_cpu_open_mode
 ldaa reveal
 cmpa #2
 beq ui_cpu_uncached
 ldaa ht_p
 cmpa turn
 beq ui_cpu_uncached
 bra ui_cpu_cache
ui_cpu_open_mode:
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
 ldaa #180
 suba sm_x
 staa ui_width
 ldaa #12
 jsr ui_erase_px
ui_cpu_tiles:
 ldaa dh_i
 cmpa ht_n
 beq ui_cpu_furo
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
ui_cpu_furo:
 ldaa ht_p
 jsr player
 ldab P_NFURO,x
 aslb
 aslb
 ldaa #168
 sba
 aslb
 aslb
 aslb
 sba
 staa sm_x
 jsr ui_furo
 tst ui_refresh
 bne ui_hand_done
 jmp ui_scores
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
 jsr ui_furo
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

; A=CPU player 1..3 -> A=top pixel row.
ui_band:
 deca
 ldab #42
 jsr mul8
 tba
 adda #9
 rts

; Draws the furo of player ht_p.
ui_furo:
 ldaa ht_p
 staa df_p
 tab
 tst ui_big
 beq ui_furo_01
 clrb
ui_furo_01:
 stab df_small
 jsr player
 ldaa P_NFURO,x
 staa df_n
 clr df_i
ui_furo_00:
 ldaa df_i
 cmpa df_n
 beq ui_furo_31
 ldaa df_p
 jsr player
 ldab df_i
 stab df_type
 aslb
 addb df_type
 addb #P_FURO
 jsr addxb
 ldaa 0,x
 staa df_red
 anda #3
 staa df_type
 ldaa 1,x
 staa df_kind
 ; df_rot: the place of the called tile, turned on the CPU furo
 ; (0 left from the player before, 1 across, 2 right from the next player).
 ldab #$FF
 ldaa 2,x
 cmpa #$FF
 beq ui_furo_02
 suba df_p
 anda #3
 beq ui_furo_02
 nega
 adda #3
 tab
ui_furo_02:
 stab df_rot
 tst df_small
 beq ui_furo_large
 ldaa sm_x
 adda #4
 staa sm_x
 bra ui_furo_begin
ui_furo_large:
 ldaa #26
 ldab df_i
ui_furo_lx:
 tstb
 beq ui_furo_10
 suba #6
 decb
 bra ui_furo_lx
ui_furo_10:
 staa df_cx
ui_furo_begin:
 clr df_j
ui_furo_tile:
 ; df_o: the place among the tiles of the tile drawn at df_j. A chi shows
 ; the called tile first, then the other two in order.
 ldaa df_j
 tst df_type
 bne ui_furo_03
 ldab df_red
 lsrb
 lsrb
 andb #3
 tsta
 bne ui_furo_04
 tba
 bra ui_furo_03
ui_furo_04:
 deca
 cba
 bcs ui_furo_03
 inca
ui_furo_03:
 staa df_o
 ldaa df_kind
 ldab df_type
 bne ui_furo_kind
 adda df_o
ui_furo_kind:
 asla
 ldab df_red
 bpl ui_furo_img
 lsrb
 lsrb
 lsrb
 lsrb
 andb #3
 cmpb df_o
 bne ui_furo_img
 inca
ui_furo_img:
 jsr img_of
 ldab df_type
 cmpb #M_ANKAN
 bne ui_furo_face
 ldab df_j
 cmpb #1
 beq ui_furo_face
 ldaa #IMG_BACK
ui_furo_face:
 tst df_small
 beq ui_furo_big
 ldab sm_y
 pshb
 clrb
 psha
 ldaa df_j
 cmpa df_rot
 bne ui_furo_flat
 ldab #RF_RIICHI
 ldaa df_type
 cmpa #M_MINKAN
 bne ui_furo_flat
 ; An open kan shows its turned tile one row lower than a pon: the empty
 ; row is above the tile instead of below it.
 inc sm_y
ui_furo_flat:
 pula
 jsr smalltile_advance
 pula
 staa sm_y
 bra ui_furo_20
ui_furo_big:
 psha
 ldaa df_j
 asla
 adda df_cx
 staa posx
 ldaa #ROW_OWN_HAND
 staa posy
 pula
 jsr drawtile
ui_furo_20:
 inc df_j
 ldaa df_j
 cmpa #3
 bne ui_furo_tile
 ; Mark large kans with K, without a fourth tile.
 ldaa df_type
 cmpa #M_MINKAN
 bcs ui_furo_advance
 tst df_small
 bne ui_furo_advance
ui_kan_big:
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
 jsr ui_icon
ui_furo_advance:
 tst df_small
 bne ui_furo_30
 jsr ui_call_mark
ui_furo_30:
 inc df_i
 jmp ui_furo_00
ui_furo_31:
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
 staa sm_y
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
 jsr ui_pixel_clr
 inc px_x
 jsr ui_pixel
ui_river_tile_00:
 rts
; A = player. Returns A = pixel row of its river.
ui_river_y:
 tsta
 bne ui_river_y_00
 ldaa #135
 rts
ui_river_y_00:
 ; One black row between the hand and the river.
 jsr ui_band
 adda #13
 rts
; A = player. Erases and redraws its river.
ui_river_draw:
 staa rr_p
 jsr ui_river_y
 staa sm_y
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
 ldaa #1
 staa ui_refresh
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
 clr ui_refresh
 jmp ui_scores
; Redraws the header and the scores.
draw_info:
draw_nokori:
draw_nokori_00:
 jsr ui_header
 jmp ui_scores
; Draws the round, the honba and the dora indicators.
ui_header:
 clr posx
 clr posy
 ldaa #32
 jsr erase1
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
 ldaa #9
 staa posx
 ldx #s_nokori
 jsr drawstr
 ldaa draws_left
 ldab #2
 jsr print_byte_num
 tst kyotaku
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
 clr posy
 ldaa #22
 staa posx
 ldx #s_dora
 jsr drawstr
 clr dd_off
 clr sm_y
 ldaa #192
 staa sm_x
 jmp ui_ind_start
; A = row, B = cell. Draws the dora indicators.
ui_indicators:
 ; Existing result screen supplies row A and cell B.
 psha
 tba
 asla
 asla
 asla
 staa sm_x
 pula
 asla
 asla
 asla
 staa sm_y
ui_ind_start:
 clr dd_i
ui_indicators_00:
 ldaa dd_i
 cmpa dora_cnt
 beq ui_indicators_01
 ldaa #DORA_POS
 suba dd_i
 suba dd_i
 adda dd_off
 tab
 jsr	wall_x
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
 beq ui_scores_01
 jsr ui_band
 adda #7
 lsra
 lsra
 lsra
 bra ui_scores_02
ui_scores_01:
 ldaa #16
ui_scores_02:
 staa posy
 ldaa #23
 staa posx
 ldaa #9
 jsr erase1
 ldaa ui_sp
 cmpa turn
 bne ui_scores_03
 ldaa #CH_TURN
 jsr drawchar
ui_scores_03:
 inc posx
 jsr draw_seat_wind
 ldaa ui_sp
 jsr player
 ldx P_SCORE,x
 jsr print_score
ui_scores_04:
 jsr ui_stick
 inc ui_sp
 ldaa ui_sp
 cmpa #4
 bne ui_scores_00
 tst demo
 beq ui_scores_05
 ldaa #24
 staa posx
 ldaa #18
 staa posy
 ldx #s_demo_key
 jsr drawstr
 ldaa #24
 staa posx
 inc posy
 ldx #s_demo_end
 jmp drawstr
ui_scores_05:
 rts
wind_names:
 .word s_ton,s_nan,s_sha,s_pe

; Draw one small tile, then move to the next tile position.
smalltile_advance:
 jsr smalltile
 ldaa sm_x
 adda #12
 staa sm_x
 rts

; Expands small_lz (made by tools/small.py) into small_img: 12 rows of 2 bytes
; for each of the 38 small tiles.
small_unpack:
 ldx #small_lz
 stx su_src
 ldx #small_img
 stx su_dst
small_unpack_00:
 ldab #1
 bsr su_bits
 bne small_unpack_02
 ; A row: the 11 face bits, then column 11 and the low 4 bits are 0.
 ldab #11
 bsr su_bits
 ldab #5
small_unpack_01:
 asl su_w+1
 rol su_w
 decb
 bne small_unpack_01
 ldx #su_w
 ldab #2
 bra small_unpack_03
small_unpack_02:
 ; Copy rows from row su_w of small_img.
 ldab #9
 bsr su_bits
 ldaa su_w+1
 ldab su_w
 asla
 rolb
 adda #<small_img
 adcb #>small_img
 staa su_from+1
 stab su_from
 ldab #3
 bsr su_bits
 ldab su_w+1
 addb #2
 aslb
 ldx su_from
small_unpack_03:
 ldaa 0,x
 inx
 stx su_from
 ldx su_dst
 staa 0,x
 inx
 stx su_dst
 ldx su_from
 decb
 bne small_unpack_03
 ldx su_dst
 cpx #small_img+912
 bne small_unpack_00
 rts
; B = bits. Returns su_w = the next B bits of su_src, with Z set from the low
; byte. su_acc holds the bits not used yet, then a 1 (0 after clear_bss: no bits).
su_bits:
 clr su_w
 clr su_w+1
su_bits_00:
 asl su_acc
 bne su_bits_01
 ldx su_src
 ldaa 0,x
 inx
 stx su_src
 sec
 rola
 staa su_acc
su_bits_01:
 rol su_w+1
 rol su_w
 decb
 bne su_bits_00
 tst su_w+1
 rts

; 12 rows * 12 pixels. Generic unaligned bit writer, preserves sm_x/sm_y.
smalltile:
 stab sm_flags
 ldab #24
 jsr mul8
 addb #<small_img
 adca #>small_img
 staa sm_src
 stab sm_src+1
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

; Turns the 11x11 face of the tile at sm_src a quarter turn
; counterclockwise into sm_rot; the border row and column stay empty.
sm_turn:
 ldx #sm_tmp
 stx sm_tp
 ldab #11
 stab sm_n
turn90_fetch:
 ldx sm_src
 ldaa 0,x
 ldab 1,x
 inx
 inx
 stx sm_src
 ldx sm_tp
 staa 0,x
 stab 1,x
 inx
 inx
 stx sm_tp
 dec sm_n
 bne turn90_fetch
 ldx #sm_rot+20
 stx sm_tp
 ldab #11
 stab sm_n
sm_turn_00:
 clr sm_w
 clr sm_w+1
 ldx #sm_tmp
turn90_col:
 asl 1,x
 rol 0,x
 rol sm_w+1
 rol sm_w
 inx
 inx
 cpx #sm_tmp+22
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

; Sets (px_ink nonzero) or clears the pixel at px_x, px_y; ui_pixel_clr clears it.
ui_pixel_clr:
 clr px_ink
ui_pixel:
 ldaa px_y
 ldab px_x
 jsr pixel_address
 staa px_addr
 stab px_addr+1
 ldaa px_x
 anda #7
 tab
 ldx #pixel_masks
 jsr addxb
 ldaa 0,x
 ldx px_addr
 tst px_ink
 beq ui_pixel_00
 oraa 0,x
 staa 0,x
 rts
ui_pixel_00:
 coma
 anda 0,x
 staa 0,x
 rts
pixel_masks:
 .byte $80,$40,$20,$10,8,4,2,1

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
small_img: .ds 912 ; 12 rows of 2 bytes of each small tile (small_unpack)
su_src: .ds 2 ; next byte of small_lz
su_acc: .ds 1 ; bits of su_src not used yet, then a 1
su_dst: .ds 2 ; next byte of small_img
su_from: .ds 2 ; next byte copied
su_w: .ds 2 ; bits read by su_bits
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

; Reveal and redraw only the winner's hand, preserving the table and river ▲.
ui_win_reveal:
 ldaa #1
 staa reveal
 staa ui_refresh
 ldaa turn
 jsr draw_hand
 clr ui_refresh
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
 tst ht_p
 bne ui_mark_tsumo_00
 jsr hand_tile_x
 ldaa posx
 asla
 asla
 asla
 adda #7
 staa mark_tip
 ldaa #164
 bra ui_mark_tsumo_01
ui_mark_tsumo_00:
 ldaa ot_i
 jsr mul12
 addb #5
 stab mark_tip
 ldaa turn
 jsr ui_band
 ; The tip sits on the black row between the hand and the river.
 adda #12
ui_mark_tsumo_01:
 staa mark_top
 ldaa #1
 staa mark_live
 ; A black box as wide as the tile keeps the mark visible over a white river tile.
 clr px_ink
 ldaa #11
 ldab #4
 jsr rmark_rows
 inc px_ink
 jmp rmark_pixels
; Redraws the scores and the riichi-denied message.
draw_riichi:
draw_riichi_00:
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
df_small: .ds 1 ; nonzero when ui_furo draws small CPU tiles
df_kind: .ds 1 ; furo kind
df_red: .ds 1 ; furo red place
df_rot: .ds 1 ; place of the called tile ($FF for none)
df_o: .ds 1 ; place among the tiles of the tile drawn

 .code
; Draws the dot over the called tile of a large furo.
ui_call_mark:
 ldaa df_rot
 bmi ui_call_mark_02
 asla
 adda df_cx
 asla
 asla
 asla
 adda #7
 staa px_x
 ldaa #166
 staa px_y
 ldaa #1
 staa px_ink
 jsr ui_pixel
ui_call_mark_02:
 rts
 .bss
sm_dst: .ds 2 ; screen address
sm_align: .ds 1 ; bit offset
sm_n: .ds 1 ; rows left
sm_w: .ds 2 ; bits of the column
sm_tp: .ds 2 ; pointer into sm_tmp
sm_tmp: .ds 22 ; turned face
sm_rot: .ds 24 ; rotated face
ui_dst: .ds 2 ; screen address
ui_tail: .ds 1 ; pixels after the last whole byte
ui_bytes: .ds 1 ; whole bytes

 .bss
ui_refresh: .ds 1 ; nonzero to redraw revealed hands
ui_back_n: .ds 4 ; hidden tiles drawn for each player ($FF = none)

 .bss
ui_first: .ds 1 ; pixels before the first whole byte
 .code
; Redraw the most recent discard, including its updated flags.
ui_latest_discard:
 ldaa discarder
 jsr player
 ldab P_RLEN,x
 decb
 ldaa discarder
 jsr ui_river_tile
 rts

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
; A = hint character index. Adds it to the hint row.
hint_add:
 tab
 ldx #hint_chars
 jsr addxb
 ldaa hint_y
 staa tx_y
 ldab hint_x
 stab tx_x
 ldaa 0,x
 jsr char_px
 ldaa tx_x
 staa hint_x
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
 jsr ui_band
 adda #7
 lsra
 lsra
 lsra
 staa posy
 jmp ui_stick
hint_clear_00:
 rts
hint_chars:
 .byte CH_C,CH_P,CH_K,CH_R
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
 ldaa #1
 ldab #3
; A = first width, B = rows. Draws rows centered on mark_tip from mark_top,
; each 2 pixels wider than the row above until the width is 7 or more, with px_ink.
rmark_rows:
 staa mark_width
 stab mark_rows
 ldaa mark_top
 staa px_y
rmark_rows_00:
 ldaa mark_width
 lsra
 nega
 adda mark_tip
 staa px_x
 ldab mark_width
 jsr ui_pixel_line
 inc px_y
 ldaa mark_width
 cmpa #7
 bcc rmark_rows_01
 adda #2
 staa mark_width
rmark_rows_01:
 dec mark_rows
 bne rmark_rows_00
 rts
 .bss
hint_x: .ds 1 ; pixel column of the next hint letter
hint_origin: .ds 1 ; pixel column of the first hint letter
hint_y: .ds 1 ; hint pixel row
mark_live: .ds 1 ; nonzero while the river marker is shown
; mark_tip is allocated in directpage.asm.
mark_top: .ds 1 ; marker top row
mark_width: .ds 1 ; marker width
mark_rows: .ds 1 ; marker rows left


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
; Draws a riichi stick at stick_x.
stick_draw:
 clr stick_row
stick_draw_00:
 ldaa stick_x
 staa px_x
stick_draw_01:
 ldaa stick_ink
 staa px_ink
 ldaa stick_row
 cmpa #1
 bne stick_draw_02
 ldaa px_x
 suba stick_x
 cmpa #11
 bcs stick_draw_02
 cmpa #14
 bcc stick_draw_02
 clr px_ink
stick_draw_02:
 jsr ui_pixel
 inc px_x
 ldaa px_x
 suba stick_x
 cmpa #24
 bne stick_draw_01
 inc px_y
 inc stick_row
 ldaa stick_row
 cmpa #3
 bne stick_draw_00
 rts
 .bss
stick_row: .ds 1 ; riichi stick row
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

 .code
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

 .code
; River-only 12x13 mockup: face11 + white/black line + black line.
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
 ldab #11
 jsr ui_pixel_line
 clr px_ink
 ldab #1
 jsr ui_pixel_line
 inc px_y
 ldaa sm_x
 staa px_x
 ldab #12
 ; Draw B pixels horizontally, using the current px_ink.
ui_pixel_line:
 pshb
 jsr ui_pixel
 pulb
 inc px_x
 decb
 bne ui_pixel_line
 rts

 .code
; X = height followed by five-bit-wide row masks (MSB first).
; Uses small-sprite scratch, without changing the live discard-marker state.
ui_icon:
 ldaa px_x
 staa sm_align
 ldaa 0,x
 staa sm_n
 inx
 stx sm_src
ui_icon_00:
 ldx sm_src
 ldaa 0,x
 staa sm_bits
 inx
 stx sm_src
 ldaa #5
 staa sm_flags
ui_icon_01:
 asl sm_bits
 ldaa #0
 rola
 staa px_ink
 jsr ui_pixel
 inc px_x
 dec sm_flags
 bne ui_icon_01
 ldaa sm_align
 staa px_x
 inc px_y
 dec sm_n
 bne ui_icon_00
 rts
cursor_icon:
 .byte 3,$F8,$70,$20
kan_icon:
 .byte 5,$88,$90,$E0,$90,$88
