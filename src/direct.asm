; Heads and sets of counts, and the residual incomplete sets: the lowest
; shanten number of the decompositions is left in sg_best.
	.code
sh_general:
 ldaa #8
 jsr sg_lmax_set
sh_general_lim:
 ldx #sg_leaf
 clra
; X = routine called at each leaf (and head of four sets), A = sg_batch.
; Every search sets both, so no search depends on an earlier one.
sg_start:
 stx sg_call_leaf+1
 stx sg_call_head+1
 staa sg_batch
 clr sg_left
 ldaa nfuro
 staa sets_n
 clr heads_n
 ldaa #8
 staa sg_best
 ldaa #$80
 staa sg_stop
 ldx #counts
 stx sg_restore_x+1
 bsr sg_entry_x
 ldaa sg_best
 rts

; Search the shanten array by kind. The kinds that are not tiles separate
; the suits, so sequence lookahead cannot cross a suit boundary.
; The operand of sg_restore_x holds X of the current kind.
sg_entry_set:
 inc sets_n
sg_entry_x:
 ldaa sg_restore_x+2
 psha
 ldaa sg_left
 psha
 ldaa sets_n
 cmpa #4
 bne sg_entry_x_00
 ; Four sets may leave a head in fourteen-tile callers.
sg_four:
 ldaa sg_batch
 cmpa #3
 bcc sg_call_leaf
 tst heads_n
 bne sg_call_leaf
 ldx #counts
sg_four_00:
 ldaa 0,x
 cmpa #2
 bcc sg_four_01
 inx
 cpx #counts+KN
 bne sg_four_00
 bra sg_call_leaf
sg_four_01:
 inc heads_n
sg_call_head:
 .byte $BD
 .word sg_leaf
 dec heads_n
 bra sg_ret
sg_advance:
 inx
sg_entry_x_00:
 ldaa 0,x
 beq sg_advance
 bpl sg_found
sg_call_leaf:
 .byte $BD
 .word sg_leaf
 bra sg_ret
sg_found:
 stx sg_restore_x+1
 cmpa #3
 bcs sg_call_leaf_00
 suba #3
 staa 0,x
 bsr sg_entry_set
 dec sets_n
 ldaa 0,x
 adda #3
 staa 0,x
sg_call_leaf_00:
 ldaa sg_restore_x+2
 cmpa #<[counts+K_HONOR]
 bcc sg_call_leaf_01
 tst 1,x
 beq sg_call_leaf_01
 tst 2,x
 beq sg_call_leaf_01
 dec 0,x
 dec 1,x
 dec 2,x
 bsr sg_entry_set
 dec sets_n
 inc 0,x
 inc 1,x
 inc 2,x
sg_call_leaf_01:
 ldaa heads_n
 bne sg_skip
 ldaa 0,x
 cmpa #2
 bcs sg_skip
 suba #2
 staa 0,x
 inc heads_n
 jsr sg_entry_x
 dec heads_n
 inc 0,x
 inc 0,x
; The tiles left at this kind stay out of every set and head below.
sg_skip:
 ldaa 0,x
 adda sg_left
 staa sg_left
 cmpa sg_lmax
 bls sg_advance
sg_ret:
 pula
 staa sg_left
 pula
 staa sg_restore_x+2
sg_restore_x:
 ldx #counts
 rts

; Evaluate one complete-set decomposition. greedy only sees the 9 tile kinds
; in each suit; honor pairs are counted separately as taatsu.
sg_leaf:
 ; With taatsu capped at 4-sets_n, no result can beat 4-sets_n-heads_n.
 ; Avoid greedy when even that optimistic result cannot improve the goal.
 ldaa #4
 suba sets_n
 staa sg_cap
 suba heads_n
 cmpa sg_best
 bge sg_leaf_04
 ; leaf_parts returns the sum for all suits and honors, capped at sg_cap.
 ldab sg_cap
 beq sg_leaf_no_taatsu
 jsr leaf_parts
 cmpa sg_cap
 bls sg_leaf_03
 ldaa sg_cap
 bra sg_leaf_03
sg_leaf_no_taatsu:
 clra
sg_leaf_03:
 tab
 ldaa sg_cap
 asla
 suba heads_n
 sba
 cmpa sg_best
 bge sg_leaf_04
 staa sg_best
 jmp sg_lmax_set
sg_leaf_04:
 rts

; Enumerate complete regular winning decompositions for eval_places.
; counts, sets_n and se_kind are restored; incomplete residual tiles fail.
search:
 ldaa se_kind
 psha
 ldaa sets_n
 cmpa #4
 beq search_01
 bsr se_counts_x
search_00:
 tst 0,x
 bne search_02
 inc se_kind
 inx
 bra search_00
search_01:
 jsr eval_places
 bra search_04
search_02:
 ldaa 0,x
 cmpa #3
 bcs search_03
 suba #3
 staa 0,x
 clra
 bsr se_block
 ldaa 0,x
 adda #3
 staa 0,x
search_03:
 ldaa se_kind
 cmpa #K_HONOR
 bcc search_04
 tst 1,x
 beq search_04
 tst 2,x
 beq search_04
 dec 0,x
 dec 1,x
 dec 2,x
 ldaa #1
 bsr se_block
 inc 0,x
 inc 1,x
 inc 2,x
search_04:
 pula
 staa se_kind
; Returns X = &counts[se_kind].
se_counts_x:
 ldab se_kind
 jmp	counts_x
; A = block type (0 triplet, 1 sequence) of kind se_kind.
se_block:
 ldab se_kind
 jsr push_block
 bsr search
 dec sets_n
 rts

 .bss
; se_kind is allocated in directpage.asm.
sg_batch: .ds 1 ; 3 while batch_prepare searches
sg_left: .ds 1 ; tiles left out of the sets and heads so far
sg_lmax: .ds 1 ; sg_entry_x stops when sg_left goes above it
; heads_n is allocated in directpage.asm.
; sg_best is allocated in directpage.asm.
; sg_cap is allocated in directpage.asm.
ad_forbidden_s: .ds 1 ; best shanten of a forbidden discard (127 if none)

 .code
; A = goal. Acceptance by the 13-tile decompositions of value <= goal. A draw
; wk_draw lowers the regular shanten number below the goal only if it improves
; one of them: added to the residual, completing a set with residual tiles, or
; completing the head with a residual tile.
; ac_yes: 0 = not asked, 1 = asked, 2 = lowers the shanten number.
acc_mark:
 psha
 ldx #unseen
acc_mark_00:
 clra
 tst rel-unseen,x
 bne acc_mark_01
 tst ac_kok_active
 beq acc_mark_02
acc_mark_01:
 ldab 0,x
 beq acc_mark_02
 inca
acc_mark_02:
 staa ac_yes-unseen,x
 inx
 cpx #unseen+KN
 bne acc_mark_00
 pula
; A = goal, ac_yes already made. Marks the asked draws that lower the value.
acc_search:
 staa acc_goal
 inca
 jsr sg_lmax_set
 ldx #acc_leaf
 clra
 jmp sg_start
acc_leaf:
 ldaa #4
 suba sets_n
 staa al_cap
 jsr leaf_parts
 ldab heads_n
 stab al_heads
 ldab al_cap
 jsr al_value
 bgt acc_leaf_04
 ; Try the asked draws part by part. counts does not cross a page.
 clr al_part
 ldx #leaf_part_taatsu
 stx al_gptr
 ldx #counts+K_FIRST
 stx al_end
acc_leaf_00:
 stx al_base
 ldaa al_base+1
 adda #9
 ldab al_part
 cmpb #3
 bne acc_leaf_01
 ldaa #<[counts+KN]
acc_leaf_01:
 staa al_end+1
 ldx al_gptr
 ldaa leaf_taatsu
 suba 0,x
 staa al_other
 inx
 stx al_gptr
 ldx al_base
acc_leaf_02:
 ldaa ac_yes-counts,x
 cmpa #1
 bne acc_leaf_03
 stx al_x
 bsr al_try
 ldx al_x
acc_leaf_03:
 inx
 cpx al_end
 bne acc_leaf_02
 inx
 inc al_part
 ldab al_part
 cmpb #4
 bne acc_leaf_00
acc_leaf_04:
 rts
; X = al_x = &counts[j], ac_yes[j] = 1. A draw without residual tiles
; within two kinds keeps every part value, so it cannot lower the value.
al_try:
 ldaa al_x+1
 suba #<counts
 staa al_j
 cmpa #K_HONOR
 ldab 0,x
 bcc al_try_02
 cmpa #K_FIRST+2
 bcs al_try_00
 dex
 dex
 bra al_try_01
al_try_00:
 ldx #counts+K_FIRST
al_try_01:
 ldaa 0,x
 oraa 1,x
 oraa 2,x
 oraa 3,x
 oraa 4,x
 bne al_try_03
 rts
al_try_02:
 bne al_try_03
 rts
al_try_03:
 ldx al_x
 inc 0,x
 ; Kept in the residual: only a taatsu below the cap can help.
 ldaa leaf_taatsu
 cmpa al_cap
 bcc al_try_10
 jsr al_check
 jmi leaf_yes
al_try_10:
 tst al_cap
 beq leaf_head
 ldx al_x
 ldaa 0,x
 cmpa #3
 bcs al_seq
 suba #3
 staa 0,x
 jsr al_check_m
 staa al_res
 ldx al_x
 ldaa 0,x
 adda #3
 staa 0,x
 tst al_res
 bmi leaf_yes
; Sequences with j: from j needs j+1 and j+2, from j-1 needs j-1 and j+1,
; from j-2 needs j-2 and j-1.
al_seq:
 ldab al_part
 cmpb #3
 beq leaf_head
 ldx al_x
 tst 1,x
 beq leaf_seq_down
 tst 2,x
 beq leaf_seq_mid
 bsr al_seq_try
 bmi leaf_yes
leaf_seq_mid:
 ldx al_x
 dex
 tst 0,x
 beq leaf_head
 bsr al_seq_try
 bmi leaf_yes
 bra leaf_seq_low
leaf_seq_down:
 dex
 tst 0,x
 beq leaf_head
leaf_seq_low:
 dex
 tst 0,x
 beq leaf_head
 bsr al_seq_try
 bmi leaf_yes
leaf_head:
 tst heads_n
 bne al_seq_00
 ldx al_x
 ldaa 0,x
 cmpa #2
 bcs al_seq_00
 suba #2
 staa 0,x
 inc al_heads
 bsr al_check
 staa al_res
 clr al_heads
 ldx al_x
 inc 0,x
 inc 0,x
 tst al_res
 bmi leaf_yes
al_seq_00:
 ldx al_x
 dec 0,x
 rts
leaf_yes:
 ldx al_x
 dec 0,x
 ldaa #2
 staa ac_yes-counts,x
 rts
; X = first count of a sequence. Returns N set if it lowers the value.
al_seq_try:
 dec 0,x
 dec 1,x
 dec 2,x
 stx al_seq_x
 bsr al_check_m
 staa al_res
 ldx al_seq_x
 inc 0,x
 inc 1,x
 inc 2,x
 tst al_res
 rts
; Returns A = value - acc_goal for the part al_part re-evaluated, one set more
; (al_check_m) or not, and al_heads heads.
al_check_m:
 ldab al_cap
 decb
 bra leaf_check_cap
al_check:
 ldab al_cap
leaf_check_cap:
 stab al_ccap
 ldx al_base
 ldab al_part
 cmpb #3
 beq al_check_00
 jsr greedy
 bra al_check_01
al_check_00:
 bsr honor_pairs
al_check_01:
 adda al_other
 ldab al_ccap
; A = taatsu, B = cap. Returns A = 2*cap - al_heads - min(A, cap) - acc_goal.
al_value:
 cba
 bls al_value_00
 tba
al_value_00:
 staa al_tmp
 tba
 asla
 suba al_tmp
 suba al_heads
 suba acc_goal
 rts
; Taatsu of each part of counts in leaf_part_taatsu, total in A and leaf_taatsu.
leaf_parts:
 ldx #counts+K_FIRST
 jsr greedy
 staa leaf_part_taatsu
 ldx #counts+K_FIRST+10
 jsr greedy
 staa leaf_part_taatsu+1
 ldx #counts+K_FIRST+20
 jsr greedy
 staa leaf_part_taatsu+2
 ldx #counts+K_HONOR
 bsr honor_pairs
 staa leaf_part_taatsu+3
 adda leaf_part_taatsu
 adda leaf_part_taatsu+1
 adda leaf_part_taatsu+2
 staa leaf_taatsu
 rts
; X = first honor count. Returns A = honor pairs.
honor_pairs:
 clra
honor_pairs_00:
 ldab 0,x
 lsrb
 aba
 inx
 cpx #counts+KN
 bne honor_pairs_00
 rts
 .bss
acc_goal: .ds 1 ; input of acc_search: the shanten value a draw must go below
leaf_part_taatsu: .ds 4 ; output of leaf_parts: taatsu of each part (man, pin, sou, honors)
al_heads: .ds 1 ; heads of the leaf, with the tried head
; leaf_taatsu is allocated in directpage.asm.
al_ccap: .ds 1 ; cap used by al_check
; al_cap is allocated in directpage.asm.
al_other: .ds 1 ; taatsu of the other parts
al_part: .ds 1 ; part tried (0 man .. 3 honors)
al_base: .ds 2 ; first count of the part
al_tmp: .ds 1 ; min(taatsu, cap)
; al_j is allocated in directpage.asm.
al_seq_x: .ds 2 ; first count of the tried sequence
al_end: .ds 2 ; end of the part
al_gptr: .ds 2 ; leaf_part_taatsu entry of the part
; al_x is allocated in directpage.asm.
 .code
; Sets sk to the ordinary-shape shanten of every discard (batch_leaf).
batch_prepare:
 ldaa #$7F
 staa wk_limit
batch_prepare_lim:
 ldaa #3
; A = sg_batch: 3, or 4 to collect the waits too (batch_prepare_waits).
batch_prepare_mode:
 psha
 ldaa wk_limit
 inca
 jsr sg_lmax_set
 ldaa #$7F
 ldx #counts
batch_prepare_00:
 staa sk-counts,x
 inx
 cpx #counts+KN
 bne batch_prepare_00
 ldx #batch_leaf
 pula
 jmp sg_start
; Like batch_prepare_lim with wk_limit 0, and fw_bits of each kind d gets the
; regular-shape waits of counts - d: the leaves of value 0 have 4 sets and 1
; tile (tanki), or 3 sets, a head and a taatsu. Every such leaf is visited.
batch_prepare_waits:
 ldx #fw_bits
batch_prepare_01:
 clr 0,x
 inx
 cpx #fw_bits+KN*5
 bne batch_prepare_01
 clr wk_limit
 ldaa #4
 bra batch_prepare_mode
batch_leaf:
 ldaa #4
 suba sets_n
 staa ba_cap
 suba heads_n
 staa ba_bound
 cmpa wk_limit
 jgt batch_leaf_13
 jsr leaf_parts
 clr ba_k
 ldx #counts
batch_leaf_00:
 stx ba_ptr
 tst 0,x
 jeq batch_leaf_12
 ldaa ba_bound
 cmpa sk-counts,x
 blt batch_leaf_01
 jgt batch_leaf_12
 ; An equal value is only needed for its waits.
 ldab sg_batch
 cmpb #4
 bne batch_leaf_12
batch_leaf_01:
 dec 0,x
 ldaa ba_k
 cmpa #10
 bcs batch_man
 cmpa #20
 bcs batch_pin
 cmpa #30
 bcs batch_sou
 ldab 0,x
 andb #1
 ldaa leaf_taatsu
 sba
 bra batch_evaluate
batch_man:
 ldx #counts+K_FIRST
 jsr greedy
 suba leaf_part_taatsu
 bra batch_add_total
batch_pin:
 ldx #counts+K_FIRST+10
 jsr greedy
 suba leaf_part_taatsu+1
 bra batch_add_total
batch_sou:
 ldx #counts+K_FIRST+20
 jsr greedy
 suba leaf_part_taatsu+2
batch_add_total:
 adda leaf_taatsu
batch_evaluate:
 cmpa ba_cap
 bls batch_leaf_10
 ldaa ba_cap
batch_leaf_10:
 ; B holds the capped taatsu until the shanten value is computed.
 tab
 ldaa ba_cap
 asla
 suba heads_n
 sba
 ldx ba_ptr
 tsta
 bne batch_leaf_02
 ldab sg_batch
 cmpb #4
 bne batch_leaf_02
 bsr bw_collect
 clra
 ldx ba_ptr
batch_leaf_02:
 cmpa sk-counts,x
 bge batch_leaf_11
 staa sk-counts,x
 cmpa wk_limit
 bge batch_leaf_11
 ldab ba_k
 cmpb kk1
 beq batch_leaf_11
 cmpb kk2
 beq batch_leaf_11
 staa wk_limit
 inca
 bsr sg_lmax_set
batch_leaf_11:
 inc 0,x
batch_leaf_12:
 inx
 inc ba_k
 ldaa ba_k
 cmpa #K_END
 jne batch_leaf_00
batch_leaf_13:
 rts
; A = G. sg_lmax = 3 * G (255 if G > 84). A leaf of at most 14 tiles whose
; 4 - sets_n - heads_n is below G leaves at most 3 * G tiles out of its sets
; and heads: G is sg_best for sh_general, wk_limit + 1 for batch_leaf and
; acc_goal + 1 for acc_leaf.
sg_lmax_set:
 cmpa #85
 bcs sg_lmax_set_00
 ldaa #85
sg_lmax_set_00:
 tab
 asla
 aba
 staa sg_lmax
 rts
; counts (without ba_k) is the 1 or 2 tiles left at a leaf of value 0. Sets
; in fw_bits of ba_k the waits: a single tile or a pair waits on itself, two
; neighbours on both outer kinds of their suit, two with a gap on the middle.
bw_collect:
 ldaa ba_k
 tab
 asla
 asla
 aba
 staa bw_off
 clrb
 ldx #counts
bw_collect_00:
 tst 0,x
 bne bw_collect_01
 inx
 incb
 bra bw_collect_00
bw_collect_01:
 stab bw_a
 ldaa 0,x
 cmpa #2
 bcc bw_collect_09
bw_collect_02:
 inx
 incb
 cmpb #K_END
 beq bw_collect_09
 tst 0,x
 beq bw_collect_02
 subb bw_a
 ldaa bw_a
 cmpb #1
 beq bw_collect_03
 inca
 bra bw_set
bw_collect_03:
 ; Neighbours: below a and above a + 1, where still in the suit.
 jsr kind_number
 cmpa #1
 beq bw_collect_04
 ldaa bw_a
 deca
 bsr bw_set
bw_collect_04:
 ldaa bw_a
 inca
 jsr kind_number
 cmpa #9
 beq bw_collect_05
 ldaa bw_a
 adda #2
 bra bw_set
bw_collect_05:
 rts
bw_collect_09:
 ldaa bw_a
; A = kind: sets its bit in fw_bits of ba_k.
bw_set:
 jsr kind_bit
 addb bw_off
 ldx #fw_bits
 jsr addxb
 oraa 0,x
 staa 0,x
 rts
 .bss
bw_a: .ds 1 ; first kind left at the leaf (bw_collect)
bw_off: .ds 1 ; ba_k * 5: the waits of ba_k in fw_bits
fw_bits: .ds KN*5 ; regular-shape waits of counts - d for each d (batch_prepare_waits)
ba_cap: .ds 1 ; taatsu cap (4 - sets_n)
ba_bound: .ds 1 ; lowest value a discard can reach
ba_k: .ds 1 ; kind tried
ba_ptr: .ds 2 ; &counts[ba_k]
 .code
