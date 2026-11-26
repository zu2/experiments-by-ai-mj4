# MJ4

ベーシックマスター Jr. 用の麻雀ゲームです。MC6800 のアセンブラで書いています。

## 必要な物

- POSIX の make
- git（Fuzix-Bintools を取得します）
- C コンパイラ（Fuzix-Bintools の `as6800` と `ld6800` をビルドします）
- Python 3 と Pillow（`python3 -m pip install pillow`）

## ビルド

```sh
make
```

最初の `make` は、Fuzix-Bintools を `vendor/bintools` に clone して、
`Makefile` の `BINTOOLS_COMMIT` を checkout し、`as6800` と `ld6800` をビルドします。

| ターゲット | 出力 |
|---|---|
| `make` | `mj4.raw`、`mj4.s19`。`build/` に `mj4.map`、`mj4.lst`、`symbols.h`、`symbols.json` |
| `make clean` | `build/` と出力を消します |
| `make distclean` | `vendor/` も消します |

`mj4.raw` は $4000 から読み込むバイナリ、`mj4.s19` は同じ内容の S レコードです。開始番地は $4000 です。

## ソースの順番

as6800 には `.include` がないので、`Makefile` が次の順番でファイルを `build/all.s` に結合して、1 回でアセンブルします。

1. `src/directpage.asm`、`src/entry.asm`（$4000 の入口と、ページをまたいではいけない表）
2. `voice/trees.s`（同じページに置く音声の木）
3. `src/main.asm` 〜 `src/direct.asm`
4. `build/data.s`（`tools/gen.py` が作る文字列、牌、フォント）
5. `src/speech.asm`、`src/unpack.asm`、`voice/packed.s`（音声）
6. `src/end.asm`（BSS の終わり）

`tools/post.py` は、map と listing から番地を読んで配置を検査し、`mj4.raw` と `mj4.s19` を書きます。

`voice/*.pcm` か `tools/voice_pack.py` を変えると、`make` は `voice/packed.s`、`voice/trees.s`、`voice/*.lz` を作り直します。これらのファイルはリポジトリに入っています。
