"""Images as canonical Huffman codes of their rows (tile_image in ui.asm).

A row is 2 bytes (tiles) or 1 byte (font). A row is a symbol; with 2-byte
rows, a row equal to the row before it is the symbol REPEAT, the row
$00,$01: no image row has bit 0 of the second byte set. The dictionary lists
the rows in the order of their codes (shorter codes first), so the code needs
no list of symbols, only the number of codes of each length (COUNTS bytes).
The codes of 8 images follow each other without padding (a group); a table
has the address of each group, and tile_image reads past the images before
the one it draws.
"""
import collections
import heapq

REPEAT = (0x00, 0x01)
COUNTS = 10
GROUP = 8


def lengths(freq):
    heap = [[n, i, [sym]] for i, (sym, n) in enumerate(freq.items())]
    heapq.heapify(heap)
    depth = collections.Counter()
    order = len(heap)
    while len(heap) > 1:
        a = heapq.heappop(heap)
        b = heapq.heappop(heap)
        for sym in a[2] + b[2]:
            depth[sym] += 1
        order += 1
        heapq.heappush(heap, [a[0] + b[0], order, a[2] + b[2]])
    return {sym: max(depth[sym], 1) for sym in freq}


def code_of(images, wide):
    tokens = []
    for rows in images:
        if wide:
            assert all(row[1] & 1 == 0 for row in rows)
            tokens.append([REPEAT if y and rows[y] == rows[y - 1] else rows[y]
                           for y in range(len(rows))])
        else:
            tokens.append(list(rows))
    freq = collections.Counter(t for ts in tokens for t in ts)
    size = lengths(freq)
    symbols = sorted(freq, key=lambda s: (size[s], s))
    assert len(symbols) <= 128
    counts = [0] * COUNTS
    code = {}
    value = 0
    length = 1
    for sym in symbols:
        while length < size[sym]:
            value <<= 1
            length += 1
        code[sym] = format(value, '0%db' % length)
        value += 1
        counts[length - 1] += 1
    groups = []
    for g in range(0, len(tokens), GROUP):
        bits = ''.join(code[t] for ts in tokens[g:g + GROUP] for t in ts)
        bits += '0' * (-len(bits) % 8)
        groups.append([int(bits[k:k + 8], 2) for k in range(0, len(bits), 8)])
    return symbols, counts, groups


def decode(symbols, counts, groups, nrows, index, wide):
    """The same steps as tile_image, for the generator's own check."""
    bits = ''.join(format(b, '08b') for b in groups[index // GROUP])
    pos = 0
    rows = []
    for k in range((index % GROUP + 1) * nrows):
        rel = 0
        base = 0
        level = 0
        while True:
            rel = rel * 2 + int(bits[pos])
            pos += 1
            assert rel < 256
            if rel < counts[level]:
                break
            rel -= counts[level]
            base += counts[level]
            level += 1
        if k < index % GROUP * nrows:
            continue
        row = symbols[base + rel]
        rows.append(rows[-1] if wide and row == REPEAT else row)
    return rows


def assembly(name, images, wide):
    """The lines of the set <name>: rows, width, address of the group table,
    counts, dictionary; then the group table and the groups."""
    nrows = len(images[0])
    assert all(len(rows) == nrows for rows in images)
    assert (len(images) % GROUP or GROUP) * nrows < 256
    symbols, counts, groups = code_of(images, wide)
    for i, rows in enumerate(images):
        assert decode(symbols, counts, groups, nrows, i, wide) == list(rows)
    dictionary = [v for row in symbols for v in row] if wide else symbols
    assert len(dictionary) + COUNTS <= 256

    def lines(data):
        return ['\t.byte\t' + ','.join('$%02X' % v for v in data[k:k + 16])
                for k in range(0, len(data), 16)]
    out = [name + ':', '\t.byte\t%d,%d' % (nrows, 1 if wide else 0),
           '\t.word\t%s_groups' % name]
    out += lines(counts) + lines(dictionary)
    out.append(name + '_groups:')
    out += ['\t.word\t%s_g%d' % (name, g) for g in range(len(groups))]
    for g, data in enumerate(groups):
        out.append('%s_g%d:' % (name, g))
        out += lines(data)
    return out
