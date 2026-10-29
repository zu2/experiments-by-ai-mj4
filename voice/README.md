# 発声データ

2026-10-20 JST
更新：2026-10-29 JST　サンプリング周波数を 8 kHz から 7,168 Hz（再生は 7,169 Hz）に下げた

Open JTalk 1.11-5、HTS Engine 1.10-7build1、NAIST辞書、女性音声tohoku-f01-neutral.htsvoiceで生成した日本語合成音声。

生成語：ポン、チー、カン、ロン、ツモ、リーチ。Open JTalkの読み上げ速度は`-r 0.75`。`source/*.wav`が生成時の原音で、再生用モデル・辞書・実行ファイルは同梱しない。

`tools/voice.py`で7,168Hzへ帯域制限付きリサンプルし、ピークの2.5%を超える最初と最後のサンプルの外側を除去（前後に余白は残さない。2026-10-29に、前160・後240サンプルの余白を削った）、音量調整・10ミリ秒のフェードを加えて5ビットへ量子化した。再生成にnumpyとscipyを使うが、ゲームの再ビルドには不要。

音声モデルのクレジット：
HTS voice tohoku-f01-neutral.
Copyright(c) 2015 Intelligent Communication Network (Ito-Nose) Laboratory, Tohoku University.
Creative Commons Attribution 4.0。
https://creativecommons.org/licenses/by/4.0/
取得先：https://github.com/icn-lab/htsvoice-tohoku-f01
ライセンス原文を`VOICE-COPYRIGHT.txt`に同梱。生成音声には無音除去、リサンプリング、EQ、音量調整、5ビット化を施した。

`dac.csv`はbm2 MC6800コアで`pcm_play`を割り込みなしで実行したDAC書込み（語名、最初の書込みからのCPUサイクル数、値）。`tools/voice_preview.py`で754,560HzのCPUクロックとして再構成し、試聴用にDC除去とローパス処理を施す。`*-dac.wav`は各語、`preview.wav`は6語を順に並べたもの。実機音質・スピーカーの周波数特性は未確認。

`.pcm`は5ビットをMSBから順に詰め、8サンプルで5バイト。6語は8,625バイト（8kHzの版は9,735バイト）。`tools/voice_pack.py`がサンプル差分をHuffman符号で圧縮し、`packed.s`と各語の`.lz`を生成する（拡張子は旧形式の名残だが内容はHuffman）。符号の木は2つで、直前の差分が0のとき（最初のサンプルも）は`voice_tree0`、それ以外は`voice_tree`を使う。圧縮本体5,209バイト、復号木200バイト（`voice_tree0` 88、`voice_tree` 112）、ヘッダー18バイト。8kHzの版は圧縮本体5,649バイト、復号木184バイト。ゲームは`packed.s`だけを組み込み、`data.s`と`.pcm`は原データ・照合用として残す。

各語のヘッダーは$FFとサンプル数。発声直前に1語を$2100から、1サンプル1バイト（DACに書く値）で展開する。最大4,040バイト（$2100〜$30C7、`riichi`）。BSSは$3300から置くので、4,608サンプルまで展開できる（`build.py`の`BSS_SPEECH`と`tools/voice_pack.py`の検査を同じ値にする）。全語で、展開した値の列が`.pcm`の値の2倍と一致することをシミュレータで確認した。展開時間はIRQなしのシミュレータで約0.43〜0.95秒。再生は1サンプル105サイクル、8サンプルごとに107サイクルで、8サンプルで842サイクル（7,169Hz）。

音声生成時に250Hzを基準とする緩やかな低域抑制（低域端で−3dB）と、2.5kHz中心・Q=1.1の+4dB補正を適用。その後ピーク音量を調整して5ビット化する。

`source-preview.wav`は同じ6語の原音を並べた比較用音声。音量調整と無音除去のみで、EQ・5ビット化は行っていない。
