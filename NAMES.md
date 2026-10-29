# 名前の決まり（v27）

## 規則
- 名前は 16 文字以下にする（ラベル、`.equ`、変数）。
- ルーチンの中のラベルと、そのルーチンだけが使う変数は「接頭辞_働き」にする。接頭辞はルーチンごとに一つで、一つの接頭辞は一つの意味だけに使う。下の表が全部の接頭辞である。
- 英語の単語の接頭辞（`hand_`、`draw_` など）は、その単語の意味で使う。
- 麻雀の用語はローマ字にする（`shanten`、`toitoi`、`chiitoi`、`yaochu`、`dora`、`furo`、`minshun`、`minkou`、`minkan`、`ankan`）。長い音は書く（`minkou`）。「子」は省く（明順子 → `minshun`）。副露（`furo`）は暗槓を含む。
- 名前の中の数字は次の意味に限る。
  - `14`: 打牌の前の手（門前なら 14 枚）。`13`: 打牌の後の手。
  - 番号（`pai_suit0`〜`2`、`sm_x` など）と、ルーチン名の一部（`mul8`、`div8`、`bits4`）。
  - 番号のラベルの `_NN`（下の規則）。
- 入口のラベル（呼ぶ前の 1 命令を持つラベル）は、入れる値＋ルーチン名にする（例: `turn_player` は A = turn を入れて player）。
- 定数は大文字の接頭辞にする（下の表）。
- 分岐だけのラベルは番号にする。形は「ルーチン名_NN」（NN は 2 桁）。
  - 小さいルーチン（50 命令以下）と、展開で大きくなっただけのルーチンでは、すべての分岐先を番号にする。
  - 大きいルーチンでは、働きだけのラベルを番号にし、処理のまとまりの見出しは読める名前（接頭辞＋働き）にする。
  - 10 の位は、ルーチンの中の処理のまとまりごとに変える（00〜09 が最初のまとまり、10〜19 が次のまとまり）。
- 略語の略語は使わない。
- 変数の名前は、役目で決める。
  - 1 つのルーチンだけの局所変数: そのルーチンの接頭辞。
  - ルーチンの入力・出力（引数、返り値）: 受け取る側・作る側のルーチンの接頭辞。定義のコメントは「input of ルーチン:」「output of ルーチン:」で始める。
  - 共用する作業用の変数（局所変数の代わり。使う期間が重ならないルーチンが共用する）: `wk_` ＋役目。定義のコメントは「shared work:」で始め、使うルーチンを書く。
  - 全体の状態: 単語の名前（`nfuro`、`min_s` など）。
- あるルーチンの局所変数を、それが生きている間に、ほかのルーチンから読み書きしない。値を渡すときは、入力・出力の変数を使う。
  - 全体の状態: 単語の名前（`nmelds`、`min_s` など）。

## 定数の接頭辞
| 接頭辞 | 意味 |
|---|---|
| `Y_` | 役の番号 |
| `P_` | プレイヤーの領域の中の位置と、P_FLAG のビット |
| `K_` | 牌の種類 |
| `KEY_` | キーのビット |
| `A_` | kattr（牌の属性）のビット |
| `F_` | score_hand に渡すフラグ（sflags） |
| `M_` | 副露の種類（M_CHI、M_PON、M_MINKAN、M_ANKAN） |
| `W_` | 待ちの種類 |
| `FURO_` | furo_attr のビット（副露が禁じる役） |
| `R_` | 他家の打牌への反応（R_PASS など） |
| `ROW_` | 画面の行 |
| `ABORT_` | 途中流局の理由（abortive_draw に渡す番号） |
| `B_` | ブロックの種類 |
| `ACT_` | 手番の行動 |

## 略語の接頭辞
| 接頭辞 | 意味 | 名前の数 | 例 |
|---|---|---:|---|
| `ab_` | all_yaochu | 1 | ab_index |
| `ac_` | acceptance（受け入れの計算）とその変数 | 5 | ac_kok_active ac_lower ac_ptr ac_special |
| `acc_` | acc_mark / acc_search / acc_leaf | 4 | acc_goal acc_leaf acc_mark acc_search |
| `acceval_` | accept_eval の中の見出し | 2 | acceval_regular acceval_yes |
| `ad_` | ai_discard（打牌の思考）の局所変数と状態 | 10 | ad_allowed ad_best_ukeire ad_flush_cand ad_forbidden_s |
| `ak_` | ai_kan | 1 | ak_before |
| `al_` | acc_leaf | 19 | al_base al_cap al_ccap al_check |
| `an_` | analyse | 1 | an_k |
| `ara_` | rel_adjust | 1 | ara_last |
| `attr_` | 牌の属性 | 2 | attr_and attr_or |
| `ba_` | batch_leaf | 6 | ba_bound ba_cap ba_delta ba_k |
| `ca_` | ai_call | 1 | ca_none |
| `calc_` | 計算 | 1 | calc_fu |
| `calldisc_` | call_discard の中の見出し | 1 | calldisc_cpu |
| `cc_` | choose_cands | 12 | cc_bonus cc_cand_bonus cc_costs cc_focus |
| `cflush_` | call_flush_ok の中の見出し | 1 | cflush_yes |
| `ch_` | drawchar | 4 | ch_cnt ch_dst ch_src ch_yoff |
| `ck_` | チーに使う手の 2 種類（chi_kinds） | 2 | ck_a ck_b |
| `cl_` | collect | 1 | cl_i |
| `cn_` | connection | 1 | cn_honor_weights |
| `cop_` | call_options | 2 | cop_pat cop_t |
| `cp_` | cp_position | 2 | cp_k cp_position |
| `cv_` | chi_valid | 1 | cv_check |
| `cw_` | check_win | 2 | cw_p cw_ron |
| `dc_` | 捨てた牌（dc_tile、dc_p、dc_k） | 3 | dc_k dc_p dc_tile |
| `dcc_` | dora_cut_cost | 3 | dcc_cost dcc_count dcc_honor_table |
| `dcl_` | do_call | 1 | dcl_kind |
| `dd_` | ui_indicators（ドラ表示牌の描画） | 2 | dd_i dd_off |
| `df_` | ui_furo（副露の描画） | 10 | df_cx df_from df_i df_j |
| `dg_` | danger_one | 3 | dg_rank dg_sides dg_suji |
| `dh_` | draw_hand の牌の番号 | 1 | dh_i |
| `div8_` | div8 | 2 | div8 div8_a |
| `docall_` | do_call の中の見出し | 5 | docall_add docall_chi docall_chi_first docall_pon |
| `dst_` | drawstr | 1 | dst_ptr |
| `dt_` | drawtile | 6 | dt_cnt dt_color dt_dst dt_repeat |
| `dv_` | div8 | 2 | dv_bits dv_divisor |
| `e1_` | ev1_discard（1 向聴の打点の評価）の局所変数 | 17 | e1_d e1_e e1_ebit e1_ebyte |
| `ed_` | eval_decomp | 4 | ed_pinfu ed_wait ed_wi ed_yhead |
| `eh_` | each_head | 1 | eh_routine |
| `el_` | eval_load | 2 | el_dst el_src |
| `ep_` | eval_places | 3 | ep_i ep_kind ep_off |
| `er_` | erase | 5 | er_cnt er_h er_p er_w |
| `ev1_` | ev1_discard とその中のルーチン | 3 | ev1_best ev1_discard ev1_draw |
| `ev_` | ev_discard（聴牌での打牌の評価） | 17 | ev_acceptance ev_base_aka ev_base_dora ev_best |
| `evacc_` | ev_acceptance の中の見出し | 4 | evacc_add_points evacc_is_furiten evacc_live_wait evacc_no_carry |
| `evdisc_` | ev_discard の中の見出し | 2 | evdisc_candidate evdisc_next_cand |
| `evprep_` | ev_prepare の中の見出し | 1 | evprep_clear |
| `fc_` | fi_copy | 2 | fc_i fc_src |
| `fcn_` | furo_counts | 3 | fcn_dst fcn_n fcn_src |
| `fi_` | finish（点の計算の仕上げ） | 8 | fi_basic fi_better fi_copy fi_fu |
| `fmk_` | furo_make とその入力 | 11 | fmk_from fmk_j fmk_k fmk_kind |
| `fp_` | furo_find_pon | 2 | fp_k fp_n |
| `fup_` | furo_upgrade | 1 | fup_x |
| `fw_` | find_waits | 2 | fw_kokushi fw_result |
| `fy_` | find_yakuman | 2 | fy_pair fy_trip |
| `gd_` | greedy | 10 | gd_smc_read0 gd_smc_read1 gd_smc_read2 gd_smc_read3 |
| `hat_` | hand_at | 4 | hat_drawn hat_left hat_n hat_red |
| `hreact_` | human_react の中の見出し | 2 | hreact_ask hreact_show |
| `ht_` | 描く手牌（ht_p、ht_n） | 2 | ht_n ht_p |
| `ib_` | intent_bias | 1 | ib_kind |
| `ibn_` | intent_bonus | 6 | ibn_best ibn_chanta ibn_chiitoi ibn_flush |
| `ir_` | in_opp_river | 1 | ir_kind |
| `iw_` | set_intents（手の狙い）とその結果 | 9 | iw_bias iw_chi iw_chiitoi iw_flush |
| `iyk_` | is_yakuhai | 1 | iyk_kind |
| `kans_` | 槓 | 1 | kans_done |
| `kattr_` | 牌の種類の属性の表（kind attribute） | 2 | kattr kattr_x |
| `ko_` | kan_options | 1 | ko_k |
| `ku_` | kuikae_ok | 1 | ku_ok |
| `kv_` | keep_value | 1 | kv_base |
| `mul_` | mul8 | 2 | mul_a mul_bits |
| `n_` | 数（n_seq、n_trip、n_conc） | 3 | n_conc n_seq n_trip |
| `ot_` | 表示している手牌の位置 | 2 | ot_hand_tile_x ot_i |
| `ownkan_` | own_kan の中の見出し | 3 | ownkan_chankan ownkan_kakan ownkan_no_rob |
| `p0_` | プレイヤー 0（人） | 1 | p0_hand_at |
| `pcm_` | 音声の再生（pcm_play） | 2 | pcm_phase pcm_play |
| `pl_` | play（音を鳴らす） | 3 | pl_delay pl_p pl_waves |
| `pn_` | print_num | 2 | pn_buf pn_p |
| `pscore_` | print_score の中の見出し | 1 | pscore_zero |
| `px_` | ピクセル | 4 | px_addr px_ink px_x px_y |
| `ra_` | riichi_allowed | 1 | ra_player |
| `rand_` | 乱数 | 2 | rand rand_below |
| `rb_` | rand_below | 1 | rb_n |
| `reg_` | 通常の役（regular） | 1 | reg_yaku_han |
| `rel_` | relevant（聴牌に関わる牌） | 4 | rel rel_adjust rel_restore rel_tenpai |
| `rh_` | reveal_hands | 1 | rh_rows |
| `ri_` | riichi_ok | 2 | ri_kind ri_player |
| `rk_` | scan_keys | 2 | rk_bit rk_data |
| `rn_` | ron_ok | 2 | rn_n rn_x |
| `rnd_` | rand | 2 | rnd_t0 rnd_t1 |
| `rp_` | 鳴ける形（rp_pon、rp_kan、rp_chi） | 3 | rp_chi rp_kan rp_pon |
| `rr_` | ui_river_draw | 2 | rr_k rr_p |
| `rvt_` | ui_river_tile | 5 | rvt_flag rvt_img rvt_index rvt_player |
| `ry_` | 流局（settle_draw と表示） | 5 | ry_bits4_x ry_n ry_score_before ry_tenpai |
| `s3_` | 三色（sanshoku_near） | 8 | s3_best s3_full s3_intent s3_iso_ok |
| `sbt_` | sort_bytes | 1 | sbt_swapped |
| `se_` | search | 3 | se_block se_counts_x se_kind |
| `sg_` | sh_general | 16 | sg_advance sg_batch sg_best sg_call_head |
| `sh_` | shanten | 3 | sh_best sh_chiitoi sh_general |
| `shf_` | shuffle | 3 | shf_left shf_pi shf_pj |
| `showdraw_` | show_draw の中の見出し | 5 | showdraw_amount showdraw_gain showdraw_no_pay showdraw_noten |
| `sm_` | smalltile | 14 | sm_align sm_bits sm_dst sm_flags |
| `snd_` | 効果音のデータ | 9 | snd_chi snd_discard snd_kan snd_notify |
| `spec_` | 特別な形（七対子・国士無双）の値（spec_prep14、spec_cut、spec_shanten） | 12 | spec_before spec_cut spec_kinds13 spec_kinds14 |
| `sr_` | show_result | 3 | sr_i sr_id sr_row |
| `ss_` | setup_score | 5 | ss_count ss_flag_if ss_furo ss_i |
| `ta_` | textaddr | 1 | ta_p |
| `tb_` | toi_bonus | 4 | tb_n_dead tb_n_live tb_n_pairs tb_n_trips |
| `toib_` | toi_bonus の中の見出し | 9 | toib_add_dead toib_cap toib_done toib_drop_dead |
| `tp_` | toi_prepare | 1 | tp_kind |
| `tt_` | draw_title | 1 | tt_line |
| `ui_` | 画面の描画 | 67 | ui_all ui_back_n ui_band ui_big |
| `up_` | unpack_voice | 7 | up_bits up_dst up_end up_flag |
| `wf_` | wait_frames | 1 | wf_cnt |
| `wk_` | 共通の作業領域（work）。使う期間が重ならないルーチンが共用する。定義のコメントに使うルーチンを書く | 12 | wk_accept wk_best wk_bonus wk_count |
| `yao_` | 么九牌 | 5 | yao_kinds yao_offsets yao_pairs yao_ptr |
| `ym_` | 役満 | 3 | ym_extra ym_n ym_y |

## 単語の接頭辞
| 接頭辞 | 意味 | 名前の数 | 例 |
|---|---|---:|---|
| `abort_` | 途中流局 | 2 | abort_names abort_reason |
| `abortive_` | 途中流局 | 1 | abortive_draw |
| `accept_` | 受け入れ | 5 | accept_acc accept_compare accept_eval accept_full |
| `add_` | 足す | 8 | add_action add_fu add_fu2 add_kan_option |
| `addxb_` | addxb（X に B を足す） | 2 | addxb addxb_tmp |
| `after_` | あと | 1 | after_draw |
| `agari_` | 和了 | 1 | agari_sets |
| `ai_` | コンピュータの思考 | 10 | ai_call ai_can_riichi ai_discard ai_furo_x |
| `aka_` | 赤五 | 1 | aka_n |
| `all_` | すべて | 1 | all_yaochu |
| `ankan_` | 暗槓子 | 1 | ankan_n |
| `any_` | どれか | 1 | any_riichi |
| `append_` | 列の末尾に加える | 1 | append_yaku |
| `apply_` | 当てる | 1 | apply_open |
| `arrow_` | 矢印（draw_arrow、select_arrow） | 3 | arrow_done arrow_full arrow_width |
| `ask_` | 聞く | 1 | ask_ron |
| `auto_` | 自動対局 | 1 | auto_play |
| `base_` | 基本 | 12 | base_chankan base_ippatsu base_last base_last_add |
| `batch_` | まとめて | 7 | batch_add_total batch_evaluate batch_leaf batch_man |
| `best_` | 最もよい結果の役と点 | 7 | best_accept best_fu best_han best_n |
| `bias_` | intent_bias（狙いによる打牌の補正）の中の見出し | 8 | bias_addc_chi bias_addc_flush bias_addc_kok bias_chanta |
| `bits4_` | bits4（4 ビットの表示） | 2 | bits4 bits4_x |
| `block_` | ブロック | 1 | block_fu |
| `bss_` | BSS の範囲 | 2 | bss_all_end bss_start |
| `btype_` | ブロックの種類 | 2 | btype btype_x |
| `call_` | 鳴き | 21 | call_bit call_chanta_pats call_chi call_chi_yaku |
| `can_` | できること | 3 | can_riichi can_ron can_win |
| `cand_` | choose_cands の中の見出し | 6 | cand_clear_order cand_isolated cand_loop cand_next |
| `chankan_` | 槍槓 | 1 | chankan_f |
| `char_` | drawchar の中の見出し | 2 | char_line char_no_carry |
| `check_` | 確かめる | 1 | check_win |
| `chi_` | チー | 10 | chi_forbidden chi_i1 chi_i2 chi_key |
| `chiitoi_` | 七対子 | 2 | chiitoi_kinds chiitoi_pairs |
| `choose_` | 選ぶ | 2 | choose_cands choose_chi |
| `clear_` | 消す | 5 | clear_bss clear_directpage clear_ippatsu clear_letters |
| `closed_` | 門前 | 1 | closed_flag |
| `count_` | 数える | 1 | count_yaochu |
| `counts_` | 手牌の数え上げ | 2 | counts counts_x |
| `cpu_` | CPU | 1 | cpu_turn |
| `cur_` | 今調べている分け方の役と点 | 4 | cur_fu cur_han cur_n cur_y |
| `cursor_` | カーソル | 2 | cursor cursor_icon |
| `danger_` | 危険度 | 4 | danger danger_max danger_one danger_player |
| `deal_` | 配牌 | 2 | deal_cnt deal_player |
| `dealer_` | 親 | 3 | dealer dealer_flag dealer_top |
| `decomp_` | 分け方 | 20 | decomp_all decomp_ankou decomp_chanta decomp_chanta2 |
| `discard_` | 打牌 | 3 | discard discard_bonus discard_step |
| `do_` | 行う | 1 | do_call |
| `dora_` | ドラ | 8 | dora_cnt dora_cut_cost dora_hits dora_kind_at |
| `draw_` | 描く | 10 | draw_arrow draw_hand draw_info draw_name |
| `draws_` | 残りのツモ | 1 | draws_left |
| `drawstr_` | drawstr | 2 | drawstr drawstr_x |
| `each_` | それぞれ | 1 | each_head |
| `end_` | 終わり | 1 | end_cursor |
| `eval_` | 評価 | 3 | eval_decomp eval_load eval_places |
| `final_` | 最後 | 1 | final_scores |
| `find_` | 探す | 2 | find_waits find_yakuman |
| `finish_` | finish（役と点を決める最後の処理） | 6 | finish finish_aka finish_han_total finish_normal |
| `flush_` | 混一色 | 2 | flush_filter flush_only |
| `furo_` | 副露（暗槓を含む。チー・ポン・明槓・暗槓でできた面子） | 8 | furo_attr furo_counts furo_facts furo_facts_end |
| `game_` | 半荘 | 2 | game_active game_end |
| `greedy_` | greedy（ブロックを欲張りに数える） | 2 | greedy greedy_sum |
| `hand_` | 手牌 | 7 | hand_add hand_add_go hand_at hand_draw |
| `has_` | 判定 | 3 | has_four has_wait has_wait_cut |
| `head_` | 雀頭 | 2 | head_fu head_kind |
| `heads_` | 雀頭の数 | 1 | heads_n |
| `hide_` | 隠す | 1 | hide_riichi |
| `hint_` | ヒントの行 | 9 | hint_add hint_char hint_chars hint_clear |
| `honor_` | 字牌 | 1 | honor_pairs |
| `human_` | 人の手番 | 10 | human_called human_discard human_letters human_manual |
| `image_` | 画像 | 1 | image_of_kind |
| `img_` | 画像 | 2 | img_of img_of_b |
| `in_` | 中にある | 1 | in_opp_river |
| `intent_` | 手の狙い | 13 | intent_bias intent_bonus intent_fl_check intent_flags |
| `is_` | 判定（A = 0 か 1） | 7 | is_agari is_closed is_dora_kind is_kokushi |
| `isolated_` | 孤立牌（ad_isolated の出力） | 3 | isolated_cand isolated_kind isolated_n |
| `kan_` | 槓 | 6 | kan_icon kan_k kan_kind kan_n |
| `keep_` | 残す | 10 | keep_check_flush keep_chiitoi keep_honor keep_honor_old |
| `kind_` | 牌の種類（A = 牌の種類を受け取るルーチンと、wk_kind を入れて呼ぶ入口。例: kind_counts_x は B = wk_kind で counts_x） | 7 | kind_counts_x kind_is_yaochu kind_number kind_number_b |
| `kokushi_` | 国士無双 | 1 | kokushi_dead |
| `kuikae_` | 喰い替え | 1 | kuikae_ok |
| `kyoku_` | 局 | 2 | kyoku kyoku_init_calls |
| `kyuushu_` | 九種九牌 | 2 | kyuushu_ask kyuushu_check |
| `leaf_` | 分け方の葉 | 9 | leaf_check_cap leaf_head leaf_part_taatsu leaf_parts |
| `least_` | 最も小さい | 1 | least_danger |
| `let_` | 文字 | 1 | let_n |
| `limit_` | 満貫以上の名前 | 1 | limit_name |
| `lone_` | 孤立 | 2 | lone_dora lone_dora_kind |
| `loop_` | いくつかのルーチンが使うループの番号 | 1 | loop_p |
| `make_` | 作る | 1 | make_tot |
| `mark_` | 河の印 | 5 | mark_clear mark_live mark_tip mark_top |
| `min_` | 最小 | 1 | min_s |
| `minkan_` | 明槓子 | 1 | minkan_n |
| `minkou_` | 明刻子 | 1 | minkou_n |
| `minshun_` | 明順子 | 1 | minshun_n |
| `move_` | 動かす | 1 | move_cursor |
| `near_` | 近く | 1 | near_sum |
| `next_` | 次 | 1 | next_zero |
| `noten_` | 不聴 | 2 | noten_delta noten_pay |
| `number_` | 数牌 | 1 | number_bias |
| `off_` | 色の外（off_suit） | 1 | off_suit |
| `open_` | CPU の手を見せる | 3 | open_cur open_mode open_prev |
| `options_` | call_options の中の見出し | 4 | options_bit options_chi options_ploop options_pnext |
| `own_` | 人の手番の表示 | 4 | own_hint_str own_hint_x own_hint_y own_kan |
| `page_` | score_page の中の見出し | 6 | page_advance page_gain page_header page_put_sign |
| `pai_` | 牌（scan_pai が数える、手牌と副露の牌の事実） | 46 | pai_acc_end pai_acc_start pai_add_simple pai_block |
| `pair_` | 牌の組 | 2 | pair_remove pair_restore |
| `pay_` | 支払い | 3 | pay_amt pay_basic pay_factor |
| `payer_` | 支払う人 | 1 | payer_amount |
| `pending_` | あとで開くドラ | 1 | pending_dora |
| `pick_` | 選ぶ | 1 | pick_kan |
| `pixel_` | ピクセル | 2 | pixel_address pixel_masks |
| `player_` | プレイヤーの領域 | 2 | player player_base |
| `posy_` | 行 | 2 | posy posy_textaddr |
| `print_` | 数を表示する | 6 | print_a2 print_byte_num print_num print_score |
| `push_` | 積む | 1 | push_block |
| `react_` | 他家の打牌への反応 | 30 | react_act react_answer react_call react_called |
| `redraw_` | 描き直す | 1 | redraw_all |
| `result_` | 結果の画面 | 1 | result_active |
| `reveal_` | 手を見せる | 2 | reveal reveal_hands |
| `riichi_` | リーチ | 9 | riichi_allowed riichi_hint_live riichi_hint_x riichi_mode |
| `rinshan_` | 嶺上 | 2 | rinshan rinshan_draw |
| `river_` | 河 | 3 | river_footer river_mark river_mark_done |
| `rmark_` | river_mark | 1 | rmark_pixels |
| `ron_` | ロン | 3 | ron_no ron_ok ron_yes |
| `round_` | 場風 | 2 | round round_kind |
| `sanshoku_` | 三色 | 14 | sanshoku_alive sanshoku_back sanshoku_cut sanshoku_full |
| `save_` | 保存 | 1 | save_scores |
| `scan_` | 読む・集める | 2 | scan_keys scan_pai |
| `score_` | 点 | 3 | score_hand score_page score_total |
| `seat_` | 自風 | 1 | seat_kind |
| `select_` | 選ぶ | 1 | select_arrow |
| `seq_` | 順子 | 1 | seq_n |
| `set_` | 決めて書く | 1 | set_intents |
| `sets_` | 面子の数 | 2 | sets_n sets_ok |
| `settle_` | 点の移動 | 9 | settle_draw settle_factor settle_han settle_honba |
| `setup_` | 点の計算の入力を作る（setup_score、setup_place、setup_win） | 14 | setup_aka setup_dk setup_dora setup_flags |
| `shanten_` | シャンテン数 | 3 | shanten shanten_furo shanten_lim |
| `shape_` | 形 | 1 | shape_add |
| `short_` | 候補の順 | 1 | short_conn |
| `show_` | 表示する | 6 | show_draw show_kan_hint show_own_hint show_result |
| `shuffle_` | 牌山を混ぜる | 4 | shuffle shuffle_honor shuffle_kind shuffle_put |
| `single_` | 1 ビット | 1 | single_bit |
| `small_` | smalltile の中の見出し | 6 | small_aligned small_next_row small_row_bits small_row_turned |
| `sort_` | 並べ替え | 4 | sort_base sort_best sort_bytes sort_n |
| `start_` | 始め | 3 | start start_yaku start_yaku_clr |
| `stick_` | リーチ棒 | 4 | stick_draw stick_ink stick_row stick_x |
| `tanyao_` | タンヤオ | 1 | tanyao_iso_ok |
| `tenpai_` | 聴牌 | 2 | tenpai_pay tenpai_without |
| `tie_` | 同点 | 2 | tie_policy tie_ukeire |
| `tile_` | drawtile の中の見出し | 8 | tile_attr tile_colors tile_crow tile_line |
| `title_` | タイトル画面 | 8 | title title_dragons title_i title_lines |
| `toggle_` | 切り替える | 1 | toggle_open |
| `toi_` | トイトイ | 5 | toi_bonus toi_dead toi_live toi_prepare |
| `total_` | 点の合計 | 1 | total_tmp |
| `trip_` | 刻子 | 2 | trip_n trip_n_x |
| `tsumo_` | ツモ | 1 | tsumo_flag |
| `turn_` | 手番 | 4 | turn turn_eval_load turn_loop turn_player |
| `turn90_` | sm_turn（牌を 90 度回す）の中の見出し | 3 | turn90_align_w turn90_col turn90_fetch |
| `unpack_` | 展開 | 1 | unpack_voice |
| `unseen_` | 考えている人から見えていない牌（unshown − 手牌。ai_unseen が作る） | 2 | unseen unseen_x |
| `unshown_` | 場にまだ見せていない牌（全員に共通。出来事のときに更新する） | 5 | unshown unshown_dora unshown_init unshown_kind |
| `ura_` | 裏ドラ | 1 | ura_n |
| `wait_` | 待つ | 3 | wait_frames wait_known wait_space |
| `waits_` | 待ち | 3 | waits waits_old waits_start |
| `wall_` | 牌山 | 3 | wall wall_next wall_x |
| `win_` | 和了 | 7 | win_game_end win_kind win_ron win_show |
| `wind_` | 風 | 2 | wind_kinds wind_names |
| `yaku_` | 役 | 2 | yaku_han yaku_han_of |
| `yakuhai_` | 役牌 | 1 | yakuhai_call |
| `yakuman_` | 役満 | 16 | yakuman_basic yakuman_c9 yakuman_chuuren yakuman_cmid |

## 番号のラベル
番号のラベルは 640 個で、226 のルーチンにある。
| ルーチン | 番号の数 |
|---|---:|
| `ac_special` | 9 |
| `acc_leaf` | 5 |
| `acc_mark` | 3 |
| `acceptance` | 6 |
| `ad_allowed` | 1 |
| `ad_flush_cand` | 1 |
| `ad_isolated` | 2 |
| `ad_rel_build` | 2 |
| `ad_s_loop` | 8 |
| `add_action` | 3 |
| `add_set_fu` | 1 |
| `addxb` | 1 |
| `after_draw` | 5 |
| `ai_call` | 5 |
| `ai_kan` | 3 |
| `ai_riichi` | 1 |
| `ai_unseen` | 1 |
| `al_check` | 2 |
| `al_seq` | 1 |
| `al_try` | 5 |
| `al_value` | 1 |
| `all_yaochu` | 5 |
| `analyse` | 2 |
| `any_riichi` | 3 |
| `apply_open` | 2 |
| `ask_ron` | 1 |
| `base_yaku` | 2 |
| `batch_leaf` | 5 |
| `batch_prepare` | 1 |
| `best_accept` | 5 |
| `calc_fu` | 11 |
| `call_chi_yaku` | 4 |
| `call_discard` | 1 |
| `call_flush_ok` | 1 |
| `call_options` | 2 |
| `call_yaku_ok` | 3 |
| `cc_rank` | 5 |
| `check_win` | 4 |
| `chi_forbidden` | 3 |
| `chi_kinds` | 3 |
| `chi_step` | 5 |
| `chi_valid` | 4 |
| `choose_cands` | 2 |
| `choose_chi` | 4 |
| `clear_ippatsu` | 1 |
| `clear_letters` | 1 |
| `collect` | 7 |
| `concealed` | 2 |
| `connection` | 1 |
| `count_yaochu` | 3 |
| `cp_position` | 2 |
| `cpu_turn` | 3 |
| `cv_check` | 1 |
| `danger` | 2 |
| `danger_one` | 9 |
| `dealer_top` | 3 |
| `discard_step` | 6 |
| `div8` | 2 |
| `dora_cut_cost` | 5 |
| `dora_next` | 4 |
| `draw_name` | 2 |
| `draw_nokori` | 1 |
| `draw_riichi` | 2 |
| `draw_title` | 1 |
| `drawstr` | 2 |
| `drawtile` | 1 |
| `each_head` | 3 |
| `erase` | 5 |
| `ev_acceptance` | 4 |
| `ev_discard` | 3 |
| `ev_prepare` | 3 |
| `eval_decomp` | 6 |
| `eval_load` | 1 |
| `eval_places` | 7 |
| `fi_better` | 2 |
| `fi_copy` | 2 |
| `fi_limit` | 4 |
| `final_scores` | 1 |
| `find_yakuman` | 1 |
| `finish` | 1 |
| `flush_filter` | 6 |
| `fmk_note` | 3 |
| `fmk_take` | 1 |
| `furo_counts` | 5 |
| `furo_facts` | 4 |
| `furo_find_pon` | 4 |
| `furo_make` | 6 |
| `furo_upgrade` | 1 |
| `game_end` | 3 |
| `hand_add` | 1 |
| `hand_at` | 6 |
| `hand_pick` | 1 |
| `hand_remove` | 1 |
| `hand_tile_x` | 2 |
| `has_four` | 1 |
| `head_fu` | 3 |
| `hide_riichi` | 1 |
| `hint_clear` | 1 |
| `hint_start` | 1 |
| `honor_pairs` | 1 |
| `human_called` | 2 |
| `human_react` | 8 |
| `human_turn` | 6 |
| `ibn_chiitoi` | 2 |
| `ibn_flush` | 1 |
| `ibn_kokushi` | 1 |
| `img_of` | 1 |
| `in_opp_river` | 3 |
| `intent_bias` | 1 |
| `intent_bonus` | 2 |
| `is_agari` | 1 |
| `is_closed` | 3 |
| `is_kokushi` | 1 |
| `is_simple` | 1 |
| `is_yakuhai` | 5 |
| `is_yaochu` | 1 |
| `isolated_cand` | 1 |
| `kan_options` | 4 |
| `kan_riichi_ok` | 4 |
| `keep_value` | 3 |
| `kind_number` | 2 |
| `kind_suit` | 3 |
| `kuikae_ok` | 3 |
| `kv_base` | 2 |
| `kyoku` | 5 |
| `kyoku_init_calls` | 1 |
| `kyuushu_ask` | 1 |
| `kyuushu_check` | 3 |
| `least_danger` | 2 |
| `limit_name` | 3 |
| `lone_dora` | 4 |
| `make_tot` | 1 |
| `move_cursor` | 5 |
| `mul8` | 2 |
| `near_sum` | 3 |
| `noten_delta` | 2 |
| `number_bias` | 2 |
| `off_suit` | 2 |
| `own_kan` | 3 |
| `payer_amount` | 1 |
| `pcm_play` | 4 |
| `pick_kan` | 2 |
| `play` | 5 |
| `print_num` | 2 |
| `print_score` | 1 |
| `print_win_pts` | 2 |
| `react` | 8 |
| `redraw_all` | 2 |
| `reg_yaku_han` | 1 |
| `rel_restore` | 4 |
| `rel_tenpai` | 2 |
| `relevant` | 2 |
| `reveal_hands` | 1 |
| `riichi_allowed` | 1 |
| `riichi_ok` | 2 |
| `riichi_turn` | 6 |
| `river_footer` | 2 |
| `rmark_pixels` | 2 |
| `ron_ok` | 3 |
| `rotate` | 1 |
| `s3_iso_ok` | 2 |
| `sanshoku_near` | 4 |
| `save_scores` | 1 |
| `scan_keys` | 5 |
| `scan_pai` | 8 |
| `score_hand` | 3 |
| `score_page` | 1 |
| `score_total` | 3 |
| `search` | 6 |
| `set_intents` | 4 |
| `sets_ok` | 7 |
| `settle_draw` | 5 |
| `settle_win` | 2 |
| `setup_win` | 3 |
| `sg_call_leaf` | 2 |
| `sg_entry_x` | 1 |
| `sg_four` | 2 |
| `sg_init` | 1 |
| `sg_leaf` | 5 |
| `sh_chiitoi` | 3 |
| `shanten` | 4 |
| `shanten_lim` | 1 |
| `short_conn` | 3 |
| `show_draw` | 2 |
| `show_result` | 8 |
| `shuffle` | 1 |
| `single_bit` | 1 |
| `sm_turn` | 1 |
| `smalltile` | 2 |
| `sort_bytes` | 4 |
| `spec_cut` | 6 |
| `spec_prep14` | 1 |
| `spec_shanten` | 2 |
| `ss_flag_if` | 1 |
| `ss_furo` | 7 |
| `stick_draw` | 3 |
| `tanyao_iso_ok` | 4 |
| `tie_policy` | 2 |
| `title_wait` | 2 |
| `tobi` | 2 |
| `toi_bonus` | 1 |
| `toi_prepare` | 4 |
| `turn_loop` | 1 |
| `ui_call_mark` | 3 |
| `ui_erase_px` | 5 |
| `ui_furo` | 6 |
| `ui_header` | 1 |
| `ui_human` | 1 |
| `ui_icon` | 2 |
| `ui_indicators` | 2 |
| `ui_mark_tsumo` | 2 |
| `ui_pixel` | 1 |
| `ui_river_draw` | 2 |
| `ui_river_tile` | 1 |
| `ui_river_y` | 1 |
| `ui_scores` | 5 |
| `ui_stick` | 1 |
| `unpack_voice` | 5 |
| `unshown_init` | 1 |
| `unshown_kind` | 1 |
| `wait_frames` | 1 |
| `wait_known` | 2 |
| `win_tsumo` | 5 |
| `yaku_han_of` | 4 |
| `yakuhai_call` | 2 |
| `yakuman_basic` | 1 |
