#!/usr/bin/env python3
"""Aggregate ai_game_stats_batch logs (one independent hand per seed)."""
import re
import sys
from pathlib import Path

YAKU = {
    0: "Riichi", 1: "Double riichi", 2: "Ippatsu", 3: "Tsumo",
    4: "Pinfu", 5: "Tanyao", 6: "Iipeikou", 7: "Haku",
    8: "Hatsu", 9: "Chun", 10: "Round wind", 11: "Seat wind",
    12: "Rinshan", 13: "Chankan", 14: "Haitei", 15: "Houtei",
    16: "Sanshoku", 17: "Ittsu", 18: "Chanta", 19: "Chiitoi",
    20: "Toitoi", 21: "Sanankou", 22: "Doukou", 23: "Sankantsu",
    24: "Honroutou", 25: "Shousangen", 26: "Ryanpeikou",
    27: "Junchan", 28: "Honitsu", 29: "Chinitsu", 30: "Dora",
    31: "Aka dora", 32: "Ura dora", 42: "Kokushi",
}
SUMMARY = re.compile(
    r"^SUMMARY decisions=(\d+) wins=(\d+) intents kokushi=(\d+) "
    r"chiitoi=(\d+) chanta=(\d+) flush=(\d+) tanyao=(\d+)$", re.M
)


def main(paths):
    totals = [0] * 7
    yaku_totals = {}
    all_hands = []
    for name in paths:
        path = Path(name)
        text = path.read_text()
        match = SUMMARY.search(text)
        if not match:
            raise SystemExit(f"Missing SUMMARY line: {path}")
        values = list(map(int, match.groups()))
        totals = [a + b for a, b in zip(totals, values)]
        hands = list(map(int, re.findall(r"^HAND (\d+) complete", text, re.M)))
        all_hands.extend(hands)
        print(f"{path}: {len(hands)} hands, {values[1]} wins, {len(hands)-values[1]} draws")
        for code, count in re.findall(r"^YAKU,(\d+),(\d+)$", text, re.M):
            code = int(code)
            yaku_totals[code] = yaku_totals.get(code, 0) + int(count)

    decisions, wins, kokushi, chiitoi, chanta, flush, tanyao = totals
    if len(all_hands) != 100 or len(set(all_hands)) != len(all_hands):
        print(f"WARNING: got {len(all_hands)} hand records, {len(set(all_hands))} unique")
    print(f"TOTAL hands={len(all_hands)} decisions={decisions} wins={wins} draws={len(all_hands)-wins}")
    print("INTENT flags are overlapping per-discard counts:")
    for label, count in (("kokushi", kokushi), ("chiitoi", chiitoi), ("chanta", chanta),
                         ("flush", flush), ("tanyao", tanyao)):
        print(f"  {label}: {count} ({count/decisions*100:.1f}% of decisions)")
    print("YAKU counts (not mutually exclusive; percent uses wins as denominator):")
    for code in sorted(set(yaku_totals) | {28, 29}):
        count = yaku_totals.get(code, 0)
        print(f"  {YAKU.get(code, f'code {code}')}: {count} ({count/wins*100:.1f}% of wins)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} LOG... ")
    main(sys.argv[1:])
