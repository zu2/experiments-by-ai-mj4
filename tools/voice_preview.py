"""Reconstruct a listening preview from the native CPU verifier's DAC trace."""
import csv
import wave
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt

root = Path(__file__).resolve().parents[1]
traces = {}
with (root / 'voice/dac.csv').open() as f:
    for name, cycle, value in csv.reader(f):
        traces.setdefault(name, []).append((int(cycle), int(value)))
parts = []
for name, trace in traces.items():
    t = np.array(trace)
    times = np.arange(0, t[-1, 0] + 95, 754560 / 24000)
    index = np.clip(np.searchsorted(t[:, 0], times, side='right') - 1, 0, len(t)-1)
    x = (t[index, 1].astype(float) - 32) / 32
    # Listening approximation only: remove DC and soften sample stair steps.
    x = sosfilt(butter(1, 60, 'highpass', fs=24000, output='sos'), x)
    x = sosfilt(butter(2, 3600, fs=24000, output='sos'), x)
    parts += [x, np.zeros(7200)]
    with wave.open(str(root / 'voice' / (name + '-dac.wav')), 'wb') as f:
        f.setparams((1, 2, 24000, 0, 'NONE', 'not compressed'))
        f.writeframes((np.clip(x, -1, 1) * 28000).astype('<i2').tobytes())
with wave.open(str(root / 'voice/preview.wav'), 'wb') as f:
    f.setparams((1, 2, 24000, 0, 'NONE', 'not compressed'))
    f.writeframes((np.clip(np.concatenate(parts), -1, 1) * 28000).astype('<i2').tobytes())

# Unquantized source reference, with the same word order and silence gaps.
parts = []
source_rate = None
for name in traces:
    with wave.open(str(root / 'voice/source' / (name + '.wav'))) as f:
        rate = f.getframerate()
        x = np.frombuffer(f.readframes(f.getnframes()), dtype='<i2').astype(float)
    if source_rate is None:
        source_rate = rate
    assert rate == source_rate
    active = np.flatnonzero(abs(x) > max(abs(x)) * .025)
    x = x[max(0, active[0] - int(rate * .02)):min(len(x), active[-1] + int(rate * .03))]
    parts += [x / max(abs(x)) * 24000, np.zeros(int(rate * .3))]
with wave.open(str(root / 'voice/source-preview.wav'), 'wb') as f:
    f.setparams((1, 2, source_rate, 0, 'NONE', 'not compressed'))
    f.writeframes(np.concatenate(parts).astype('<i2').tobytes())
