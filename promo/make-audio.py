#!/usr/bin/env python3
"""Build the 50 s promo soundtrack from a deterministic pad and the TTS stems."""
from __future__ import annotations
import math, random, struct, subprocess, wave
from pathlib import Path

SR = 48000
DURATION = 50.0
ROOT = Path(__file__).resolve().parent
AUDIO = ROOT / 'audio'
OUT = AUDIO / 'dshd-linux-promo-mix.wav'

# (start seconds, file); measured with ffprobe after `say -v Samantha -r 150`.
VOICE = [
    (0.70, 'vo-01.wav'),
    (5.90, 'vo-02.wav'),
    (13.80, 'vo-03.wav'),
    (21.40, 'vo-04.wav'),
    (29.00, 'vo-05.wav'),
    (37.00, 'vo-06.wav'),
    (45.00, 'vo-07.wav'),
]
VOICE_TEXT = {
    'vo-01.wav': 'DSHD. DeepSeek Harness Desktop. Now on Linux.',
    'vo-02.wav': 'A complete AI workspace. Real providers, sessions, files, and a terminal.',
    'vo-03.wav': 'Bring your own API key. Keep the workspace on your machine.',
    'vo-04.wav': 'Plugins, models, permissions, settings. One coherent desktop.',
    'vo-05.wav': 'Office to PDF, with a bundled WASM engine. No system LibreOffice. No cloud round trip.',
    'vo-06.wav': 'One app. AppImage, deb, rpm, Flatpak. X86 and ARM64.',
    'vo-07.wav': 'DSHD for Linux. Release candidate, on GitHub.',
}

# A minor / F / C / G, two bars each.
CHORDS = [
    (0.0, 7.5, [110.00, 130.81, 164.81, 220.00], 55.00),
    (7.5, 15.0, [87.31, 110.00, 130.81, 174.61], 43.65),
    (15.0, 22.5, [130.81, 164.81, 196.00, 261.63], 65.41),
    (22.5, 30.0, [98.00, 123.47, 146.83, 196.00], 49.00),
    (30.0, 37.5, [110.00, 130.81, 164.81, 220.00], 55.00),
    (37.5, 45.0, [87.31, 110.00, 130.81, 174.61], 43.65),
    (45.0, 50.0, [130.81, 164.81, 196.00, 261.63], 65.41),
]

def ensure_voice_stems() -> None:
    """Regenerate missing TTS stems on macOS with the same text and rate."""
    for _, name in VOICE:
        wav = AUDIO / name
        if wav.exists():
            continue
        aiff = wav.with_suffix('.aiff')
        try:
            subprocess.run(
                ['say', '-v', 'Samantha', '-r', '150', '-o', str(aiff), VOICE_TEXT[name]],
                check=True,
            )
        except FileNotFoundError as exc:
            raise SystemExit('macOS `say` is required to regenerate the voice stems') from exc
        subprocess.run(
            ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(aiff),
             '-ar', str(SR), '-ac', '1', str(wav)],
            check=True,
        )
        aiff.unlink(missing_ok=True)

ensure_voice_stems()
random.seed(7)
N = int(SR * DURATION)
left = [0.0] * N
right = [0.0] * N

def env(t: float, start: float, end: float, attack: float = 0.7, release: float = 0.8) -> float:
    if t < start or t > end:
        return 0.0
    return min(1.0, (t - start) / max(attack, 1e-6), (end - t) / max(release, 1e-6))

def add(i: int, l: float, r: float) -> None:
    left[i] += l
    right[i] += r

# Pads, sub bass, soft pulse and a distant shimmer.
for start, end, notes, sub in CHORDS:
    for n, f in enumerate(notes):
        detune = 1.0 + (0.0018 if n % 2 else -0.0015)
        phase_l = random.random() * math.tau
        phase_r = random.random() * math.tau
        amp = 0.072 if n < 2 else 0.048
        pan = (n - 1.5) * 0.12
        for i in range(int(start * SR), min(N, int(end * SR))):
            t = i / SR
            e = env(t, start, end, 1.0, 1.2)
            if e <= 0:
                continue
            # Slow chorus movement keeps the pad from sounding static.
            vib = 1.0 + 0.00035 * math.sin(math.tau * 0.11 * t + n)
            wl = math.sin(math.tau * f * detune * vib * t + phase_l)
            wr = math.sin(math.tau * f * (2.0 - detune) * vib * t + phase_r)
            add(i, wl * amp * e * (1.0 - pan), wr * amp * e * (1.0 + pan))
            # A quiet octave harmonic adds air.
            if n == len(notes) - 1:
                h = math.sin(math.tau * f * 2 * t) * 0.012 * e
                add(i, h, h)
    for i in range(int(start * SR), min(N, int(end * SR))):
        t = i / SR
        e = env(t, start, end, 0.8, 1.0)
        b = math.sin(math.tau * sub * t) * 0.085 * e
        add(i, b, b)

# Pulse every 2 s, entering after the intro.
for beat in [x * 2.0 for x in range(3, 25)]:
    if beat >= DURATION - 0.5:
        continue
    for k in range(int(0.22 * SR)):
        t = k / SR
        i = int(beat * SR) + k
        if i >= N:
            break
        e = math.exp(-t * 22.0)
        f = 54.0 * (1.0 + 0.10 * math.exp(-t * 30.0))
        s = math.sin(math.tau * f * t) * 0.11 * e
        add(i, s, s)

# Shimmer notes on the chord grid, very quiet.
for start, end, notes, _ in CHORDS:
    t0 = start + 1.0
    while t0 < end - 0.5:
        f = notes[int((t0 - start) / 1.25) % len(notes)] * 4.0
        for k in range(int(0.55 * SR)):
            t = k / SR
            i = int(t0 * SR) + k
            if i >= N:
                break
            e = math.exp(-t * 5.0) * min(1.0, t / 0.02)
            s = math.sin(math.tau * f * t) * 0.008 * e
            add(i, s * 0.8, s)
        t0 += 1.25

# Air/riser at the big cuts; deterministic noise.
for center, width in [(5.3, 0.65), (13.1, 0.55), (20.7, 0.5), (28.1, 0.55), (35.9, 0.6), (43.9, 0.55)]:
    for i in range(max(0, int((center - width) * SR)), min(N, int((center + width) * SR))):
        t = i / SR
        x = (t - (center - width)) / (2 * width)
        e = max(0.0, 1.0 - abs(t - center) / width) ** 2
        n = random.uniform(-1, 1) * 0.008 * e
        add(i, n * (1 - x), n * x)

# Duck the music under the narration.
duck = [1.0] * N
for start, name in VOICE:
    path = AUDIO / name
    with wave.open(str(path), 'rb') as w:
        frames = w.readframes(w.getnframes())
        voice = struct.unpack('<' + 'h' * (len(frames) // 2), frames)
    end = start + len(voice) / SR
    for i in range(int(max(0, start - 0.25) * SR), min(N, int((end + 0.35) * SR))):
        t = i / SR
        if t < start:
            target = 0.45 + 0.55 * (t - (start - 0.25)) / 0.25
        elif t <= end:
            target = 0.45
        else:
            target = 0.45 + 0.55 * (t - end) / 0.35
        duck[i] = min(duck[i], max(0.45, min(1.0, target)))

# Mix voice and music, then normalize to a healthy peak.
for start, name in VOICE:
    with wave.open(str(AUDIO / name), 'rb') as w:
        frames = w.readframes(w.getnframes())
        voice = struct.unpack('<' + 'h' * (len(frames) // 2), frames)
    offset = int(start * SR)
    for k, v in enumerate(voice):
        i = offset + k
        if i >= N:
            break
        s = (v / 32768.0) * 0.95
        # TTS stems are mono; keep them centered.
        left[i] += s
        right[i] += s

peak = max(max(abs(x) for x in left), max(abs(x) for x in right), 1e-9)
gain = 0.89 / peak
fade_in = int(0.35 * SR)
fade_out = int(1.1 * SR)
with wave.open(str(OUT), 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    data = bytearray()
    for i in range(N):
        g = gain
        if i < fade_in: g *= i / fade_in
        if i > N - fade_out: g *= (N - i) / fade_out
        l = max(-1.0, min(1.0, left[i] * g * duck[i]))
        r = max(-1.0, min(1.0, right[i] * g * duck[i]))
        data += struct.pack('<hh', int(l * 32767), int(r * 32767))
    w.writeframes(data)
print(f'wrote {OUT} ({DURATION:.0f}s, peak gain {gain:.2f})')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(OUT),'-c:a','aac','-b:a','192k',str(AUDIO/'dshd-linux-promo.m4a')], check=True)
print('encoded audio/dshd-linux-promo.m4a')
