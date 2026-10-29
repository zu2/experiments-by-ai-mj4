# 発声データ

2026-10-20 JST
更新：2026-10-29 JST　前後の余白を削った

Open JTalk 1.11-5、HTS Engine 1.10-7build1、NAIST辞書、女性音声tohoku-f01-neutral.htsvoiceで生成した日本語合成音声。

生成語：ポン、チー、カン、ロン、ツモ、リーチ。Open JTalkの読み上げ速度は`-r 0.75`。`source/*.wav`が生成時の原音で、再生用モデル・辞書・実行ファイルは同梱しない。

`tools/voice.py`で8kHzへ帯域制限付きリサンプルし、ピークの2.5%を超える最初と最後のサンプルの外側を除去（前後に余白は残さない。2026-10-29に、前160・後240サンプルの余白を削った）、音量調整・短いフェードを加えて5ビットへ量子化した。再生成にnumpyとscipyを使うが、ゲームの再ビルドには不要。

音声モデルのクレジット：
HTS voice tohoku-f01-neutral.
Copyright(c) 2015 Intelligent Communication Network (Ito-Nose) Laboratory, Tohoku University.
Creative Commons Attribution 4.0。
https://creativecommons.org/licenses/by/4.0/
取得先：https://github.com/icn-lab/htsvoice-tohoku-f01
ライセンス原文を`VOICE-COPYRIGHT.txt`に同梱。生成音声には無音除去、リサンプリング、EQ、音量調整、5ビット化を施した。

`dac.csv`はbm2 MC6800コアで実行したゲームのDAC書込み（語名、最初の書込みからのCPUサイクル数、値）。`tools/voice_preview.py`で754,560HzのCPUクロックとして再構成し、試聴用にDC除去とローパス処理を施す。`*-dac.wav`は各語、`preview.wav`は6語を順に並べたもの。実機音質・スピーカーの周波数特性は未確認。

5ビットはMSBから順に詰め、8サンプルで5バイト。6語は9,735バイト（余白を削る前は11,230バイト）。`tools/voice_pack.py`がサンプル差分を共通Huffman符号で圧縮し、`packed.s`と各語の`.lz`を生成する（拡張子は旧形式の名残だが内容はHuffman）。圧縮本体5,984バイト（余白を削る前は6,305バイト）、復号木108バイト、ヘッダー18バイト。ゲームは`packed.s`だけを組み込み、`data.s`と`.pcm`は原データ・照合用として残す。

各語のヘッダーは$FFとサンプル数。発声直前に1語を$2100から、1サンプル1バイト（DACに書く値）で展開する。最大4,504バイト（$2100〜$3297、`riichi`）で、BSSは$3298から置く（`build.py`の`BSS_SPEECH`と`tools/voice_pack.py`の検査を同じ値にする）。全語で、DACに書く値の列が5バイトに8サンプルを詰めていた版と一致することをシミュレータで確認した。展開時間はIRQなしのシミュレータで約0.53〜1.07秒（余白を削る前の値。5バイトに8サンプルの版は約0.63〜1.26秒）。再生は8サンプルで746サイクルで、5バイトに8サンプルの版と同じ。音質は元の5ビット版と同一。

音声生成時に250Hzを基準とする緩やかな低域抑制（低域端で−3dB）と、2.5kHz中心・Q=1.1の+4dB補正を適用。その後ピーク音量を調整して5ビット化する。波形長とデータ容量は変更しない。

`source-preview.wav`は同じ6語の原音を並べた比較用音声。音量調整と無音除去のみで、EQ・5ビット化は行っていない。
