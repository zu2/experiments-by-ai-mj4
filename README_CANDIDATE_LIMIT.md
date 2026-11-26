# MJ4 V39 candidate limit experiment

This package contains an experimental copy of official V39. The official V39 source was not modified. The adjustable shortlist limit is 4–6; the default remains 4. `cc_limit` is clamped to the supported range when candidate selection starts.

## Build and run

From this directory:

```sh
make
gcc -O2 -I. -Ivendor/bm2-core \
  -DSYMBOL_HEADER='"build/symbols.h"' \
  evidence/harness/run_ms.c vendor/bm2-core/m6800.c \
  -o evidence/harness/run_ms
./evidence/harness/run_ms mj4.raw evidence/candidate6/trace.bin 6 > evidence/candidate6/ms.csv
python3 evidence/analyze_cap6.py
```

The harness replays game IDs 12846–12865, using the recorded formula `((game_id * 0x9e3779b9) + 0x7f4a7c15) & 0xffffff`. Change its third argument to 4, 5, or 6 to select the shortlist size. `evidence/baseline4/` contains the original four-candidate trace, turn log, and symbols; `evidence/candidate6/` contains the six-candidate run.

## Six-candidate result (2026-10-27 JST)

The 20 games completed. The trace contains 829 complete decision records, of which 412 meet the existing structural review filter (`full=1`, non-riichi, recorded shanten 1–3). The six-candidate run had no duplicated kinds in any of those candidate lists, no selected discard with a worse post-discard shanten than the legal minimum, and no same-shanten acceptance gap of 16 or more. Its largest same-shanten gap was 8 tiles. The best structural discard was absent from the six candidates in 30/412 decisions; the actual pick was inside the shortlist in all 412.

For the four-candidate baseline, the corresponding counts are 403 filtered decisions, 0 shanten regressions, 61 decisions with lower acceptance on the same shanten, maximum gap 14, best candidate absent in 47, and actual pick outside the shortlist in 0. The decision paths can diverge after a changed pick, so these per-run totals are not a strict same-position comparison. Among 307 matched board states, six picks changed; each was structurally equal or better by shanten and acceptance.

An earlier draft of the variable shift produced duplicate candidates and was discarded. The final source uses explicit 4/5/6 pointer adjustment; the final trace has zero duplicate candidate lists in the filtered decisions.

This review checks shanten and unseen-tile acceptance only. It does not establish full hand value, defense, or strategic quality. No 5-candidate run is included.

## Flush call review: final structure (2026-10-27 JST)

Call and discard decisions retain separate collection and eligibility rules. set_intents collects hand facts for each decision. For a flush call, flush_route_ok reuses leaf_parts once before any pattern trial; call_flush caches its result throughout the trials. Discard filtering keeps its prior policy. The target/color facts are already computed by set_intents. No cross-decision cache or new scratch variables were added.

Historical size at the flush-call experiment (before the same-shanten pon rule): 27972 bytes, +13 versus the 27959-byte pre-call-fix experiment; BSS was $33A3. The current official version and its size review are recorded in ../MJ4_V39_SIZE_REVIEW_20261027.md. The first newly written tile-copy/counting loop was discarded; no such loop remains.

All 12 checks passed, including taatsu overlap and independent yakuhai permission. All 20 games completed at limit 6; targeted 12860 replay declined the problematic chi. Comparative strength and timing are unmeasured. Original candidate6 evidence retains frozen pre-call-fix symbols and binary.
