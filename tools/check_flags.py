"""Checks the routines whose header says "N and Z set from A" (or B).

Every RTS that such a routine can reach must follow an instruction that set
N and Z from that register, so a caller may branch on them without TSTA.
"""
import re
import sys
from pathlib import Path

FROM_A = set('ldaa tsta clra coma nega inca deca asla asra lsra rola rora adda adca '
             'suba sbca anda oraa eora staa tba aba sba daa'.split())
FROM_B = set('ldab tstb clrb comb negb incb decb aslb asrb lsrb rolb rorb addb adcb '
             'subb sbcb andb orab eorb stab'.split())
KEEP = set('bra jmp psha pshb ins des txs tsx nop'.split())
BRANCHES = set('bcc bcs beq bge bgt bhi ble bls blt bmi bne bpl bvc bvs'.split())


def load(files):
    code = []
    labels = {}
    contracts = []
    marker = None
    for name in files:
        for number, line in enumerate(Path(name).read_text().splitlines(), 1):
            text = line.split(';')[0].rstrip()
            comment = line[len(text):]
            found = re.search(r'N and Z set from ([AB])', comment)
            if found and not text.strip():
                marker = found[1]
            label = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', text)
            if label:
                labels[label[1]] = len(code)
                if marker:
                    contracts.append((label[1], marker))
                    marker = None
                text = label[2]
            if not text.strip() or re.match(r'^\w+\s+\.equ', text):
                continue
            parts = text.split(None, 1)
            code.append((name, number, parts[0].lower(), parts[1].strip() if len(parts) > 1 else ''))
    return code, labels, contracts


def state_after(op, state, reg):
    if op == 'tab':
        return 'B' if reg == 'B' else 'A'
    if op in FROM_A:
        return 'A'
    if op in FROM_B:
        return 'B'
    if op in KEEP or op in BRANCHES:
        return state
    if op == 'pulb' and state == 'A':
        return state
    if op == 'pula' and state == 'B':
        return state
    return None


def check(code, labels, routine, reg):
    errors = []
    seen = set()
    work = [(labels[routine], None)]
    while work:
        index, state = work.pop()
        while (index, state) not in seen:
            seen.add((index, state))
            if index >= len(code):
                errors.append(f'{routine}: runs off the end')
                break
            name, number, op, arg = code[index]
            if op.startswith('.'):
                errors.append(f'{routine}: reaches data at {name}:{number}')
                break
            if op == 'rts':
                if state != reg:
                    errors.append(f'{routine}: RTS at {name}:{number} without N and Z set from {reg}')
                break
            if op in ('jmp', 'bra'):
                if arg not in labels:
                    errors.append(f'{routine}: {op} {arg} at {name}:{number} cannot be followed')
                    break
                index = labels[arg]
                continue
            if op in BRANCHES:
                work.append((labels[arg], state))
            state = state_after(op, state, reg)
            index += 1
    return errors


if __name__ == '__main__':
    code, labels, contracts = load(sys.argv[1:])
    errors = [e for routine, reg in contracts for e in check(code, labels, routine, reg)]
    for error in errors:
        print(error)
    sys.exit(1 if errors else 0)
