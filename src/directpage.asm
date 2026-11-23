; Names, prefixes and abbreviations are listed in NAMES.md.
; User-authorized direct RAM: $0072..$00F1, exactly 128 bytes.
; No aliases or overlapping lifetimes. Intent accumulators stay contiguous in BSS.
DP_FIRST .equ $0072
DP_END .equ $00F2
wk_kind .equ $0072 ; shared work: kind being checked (ai_discard loop, loops of its parts; kind_* entries read it)
posx .equ $0073 ; text column (stx posx also sets posy)
posy .equ $0074 ; text row
turn .equ $0075 ; player in turn
sm_x .equ $0076 ; pixel x of smalltile
wk_num .equ $0077 ; shared work: 16-bit number (div8_a operand and result, payer_amount and score_total sums, print_num input)
ai_player .equ $0079 ; computer player that is thinking
min_s .equ $007A ; lowest shanten of the discards
wk_draw .equ $007B ; shared work: kind of the draw (acceptance, ev_tally)
loop_p .equ $007C ; player index for loops (settle, scores, count_ge)
sh_best .equ $007D ; best shanten in shanten
ht_p .equ $007E ; player whose hand is drawn
px_x .equ $007F ; pixel x
sm_y .equ $0080 ; pixel y of smalltile
ry_v .equ $0081 ; signed transfer of the draw (units of 100); points count_at compares with
dealer .equ $0083 ; dealer player
cursor .equ $0084 ; cursor position in the own hand ($FF = none)
discarder .equ $0085 ; player who discarded dc_tile
pai_kind .equ $0086 ; kind set_intents is counting
kan_kind .equ $0087 ; kind of the kan
sets_n .equ $0088 ; sets of the current decomposition, furo included
al_cap .equ $0089 ; taatsu cap (4 - sets_n)
ui_sp .equ $008A ; player index for the score page
ad_pick .equ $008B ; kind ai_discard chose
ht_n .equ $008C ; tiles of the hand drawn
kk1 .equ $008D ; kind that may not be discarded ($FF = none)
other .equ $008E ; player reacting to dc_tile
call_kind .equ $008F ; kind of dc_tile for ai_call
cc_key .equ $0090 ; rank of the candidate (lower is cut first)
ck_a .equ $0091 ; first hand kind of the call
wk_count .equ $0092 ; shared work: tile count (set_intents per kind)
knew .equ $0093 ; keys pressed in this frame
px_y .equ $0094 ; pixel y
sflags .equ $0095 ; F_* flags for score_hand
ck_b .equ $0096 ; second hand kind of the call
e1_i .equ $0097 ; kind of the discard i (ev1_discard)
kk2 .equ $0098 ; second kind that may not be discarded ($FF = none)
attr_or .equ $0099 ; OR of kattr over the hand
dc_tile .equ $009A ; tile just discarded
fi_han .equ $009B ; han for fi_limit
ko_k .equ $009C ; kind kan_options checks
rp_chi .equ $009D ; chi patterns possible (bits)
seed .equ $009E ; rand state (3 bytes, never 0)
wk_accept .equ $00A1 ; shared work: acceptance sum (output of acceptance, ev_tally)
wk_best .equ $00A2 ; shared work: best value (least_danger, best_accept)
cur_fu .equ $00A3 ; fu of the decomposition
head_kind .equ $00A4 ; kind of the head
sg_best .equ $00A5 ; lowest shanten found by sh_general
pcm_phase .equ $00A7 ; samples left to the shorter eighth sample
fi_basic .equ $00A8 ; basic points (16 bits)
attr_and .equ $00AA ; AND of kattr over the hand
best_han .equ $00AB ; han of the best result
best_pts .equ $00AC ; points of the best result (units of 100)
cop_t .equ $00AE ; kind of dc_tile for call_options
cw_p .equ $00AF ; player check_win checks
dcc_count .equ $00B0 ; dora loss per matching indicator
dora_cnt .equ $00B1 ; open dora indicators
dora_n .equ $00B2 ; dora in the hand
sg_cap .equ $00B3 ; taatsu that can still count (4 - sets_n)
greedy_sum .equ $00B4 ; taatsu so far
fmk_kind .equ $00B5 ; first kind of the furo
nfuro .equ $00B6 ; furo of the hand
react_act .equ $00B7 ; R_* answer of the reacting player
s3_kind .equ $00B8 ; kind sanshoku_cut checks
se_kind .equ $00B9 ; kind search is at
toi_slots .equ $00BA ; toitoi blocks still needed
best_fu .equ $00BB ; fu of the best result
leaf_taatsu .equ $00BC ; output of leaf_parts: taatsu of all parts
wk_bonus .equ $00BD ; shared work: toitoi bonus (choose_cands -> discard_bonus, then its sum)
dcc_cost .equ $00BE ; dora cost of the candidate
dh_i .equ $00BF ; hand tile index being drawn
dcl_kind .equ $00C0 ; kind of the called tile
df_type .equ $00C1 ; type of the furo being drawn (M_*)
mark_tip .equ $00C3 ; x of the marker tip
react_pat .equ $00C4 ; chi pattern of react_act
wk_first .equ $00C5 ; shared work: first kind changed (ad_rel_build, rel_restore)
round .equ $00C6 ; round counter (0..3 east, 4.. south)
al_j .equ $00C7 ; kind index of the draw
sr_row .equ $00C8 ; text row of the result page
title_i .equ $00C9 ; title tile index
win_kind .equ $00CA ; kind of the winning tile
pay_amt .equ $00CC ; points one payer pays
wk_unseen .equ $00CE ; shared work: unseen copies of wk_draw (acceptance, ev_tally)
aka_n .equ $00CF ; red fives in the hand
best_n .equ $00D0 ; yaku of the best result
chi_pat .equ $00D2 ; chi pattern the human chose
df_j .equ $00D3 ; tile index in the furo
dv_divisor .equ $00D4 ; divisor of div8
ed_wait .equ $00D5 ; W_* wait of the winning tile
kyotaku .equ $00D8 ; riichi sticks on the table
fmk_type .equ $00D9 ; M_* type of the furo
fmk_k .equ $00DA ; kind furo_make takes next
ot_i .equ $00DB ; position in the shown hand
pay_factor .equ $00DC ; payment factor of the payer
px_ink .equ $00DD ; nonzero to set the pixel
ry_tenpai .equ $00DE ; tenpai players (bits)
cc_sanshoku .equ $00DF ; choose_cands: 13-tile sanshoku value of the candidate (read by discard_bonus)
heads_n .equ $00E0 ; 1 when the decomposition has its head
sm_flags .equ $00E1 ; smalltile flags
ss_i .equ $00E2 ; dora indicator index
stick_x .equ $00E3 ; x of the riichi stick
tb_n_live .equ $00E4 ; live pairs
ura_n .equ $00E5 ; ura dora in the hand
al_x .equ $00E6 ; &counts[draw]
e1_dst .equ $00E8 ; ev1_discard: destination of the tenpai draws
sm_src .equ $00EA ; image address
wk_score .equ $00ED ; shared work: acceptance of the candidate (best_accept)
cop_pat .equ $00EF ; chi pattern call_options checks
wk_limit .equ $00F0 ; shared work: shanten limit (ai_discard -> least_danger; batch_prepare low)
dc_p .equ $00F1 ; player who discarded
