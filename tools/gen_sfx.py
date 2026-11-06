#!/usr/bin/env python3
"""Magnet Shift ses efektlerini sıfırdan sentezler (dış kaynak/lisanslı ses yok).

Kullanım: python3 tools/gen_sfx.py  ->  audio/sfx/*.wav (44.1 kHz, 16 bit, mono)

- hero_ahh   : kahramanın "Ahh!" çığlığı. Düşen perdeli ses teli kaynağı + "a" ünlüsünün
               formant rezonansları (F1~800, F2~1200, F3~2600 Hz) + nefes; hafif metalik
               (kahramanlar robot) halka modülasyonu.
- zap        : lazer elektrik çarpması (çatırtı + vızıltı) ve ardından yanma cızırtısı
- hit        : bekçi yakalaması (tok darbe + metal tınısı)
- portal     : çıkış kapısına çekilme (yükselen rüzgâr)
- level_clear: başarı zili (arpej)
- beam_in    : yeni level başında kahramanın ışınlanması
Sadece standart kütüphane kullanır.
"""
import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")
random.seed(7)


def write(name, samples, peak=0.89):
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))
    print("yazıldı:", path, "%.2fs" % (len(samples) / SR))


class Bandpass:
    """RBJ biquad bant geçiren (0 dB tepe). Frekansı zamanla değiştirilebilir."""

    def __init__(self, f, bw):
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        self.set(f, bw)

    def set(self, f, bw):
        f = max(20.0, min(f, SR * 0.45))
        w0 = 2 * math.pi * f / SR
        q = max(0.3, f / bw)
        alpha = math.sin(w0) / (2 * q)
        a0 = 1 + alpha
        self.b0, self.b2 = alpha / a0, -alpha / a0
        self.a1, self.a2 = -2 * math.cos(w0) / a0, (1 - alpha) / a0

    def __call__(self, x):
        y = self.b0 * x + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2
        self.x2, self.x1 = self.x1, x
        self.y2, self.y1 = self.y1, y
        return y


class OnePoleHP:
    def __init__(self, fc):
        self.a = math.exp(-2 * math.pi * fc / SR)
        self.px = self.py = 0.0

    def __call__(self, x):
        y = self.a * (self.py + x - self.px)
        self.px, self.py = x, y
        return y


def env_adsr(t, dur, a=0.01, r=0.1):
    if t < a:
        return t / a
    if t > dur - r:
        return max(0.0, (dur - t) / r)
    return 1.0


def hero_ahh():
    dur = 0.78
    n = int(SR * dur)
    out = []
    phase = 0.0
    # (frekans, bant genişliği, kazanç): "a" ünlüsü
    forms = [(820, 90, 1.0), (1220, 110, 0.55), (2650, 170, 0.22), (3400, 230, 0.10)]
    fb = [Bandpass(f, bw) for f, bw, _ in forms]
    nb = [Bandpass(f, bw * 1.6) for f, bw, _ in forms]
    jitter = 0.0
    for i in range(n):
        t = i / SR
        # perde: ani yükselip (çığlık) düşen
        if t < 0.05:
            f0 = 250 + 70 * (t / 0.05)
        else:
            f0 = 165 + 155 * math.exp(-2.4 * (t - 0.05))
        if t > 0.15:
            f0 *= 1 + 0.025 * math.sin(2 * math.pi * 6.2 * t)
        if i % 220 == 0:
            jitter = random.uniform(-0.012, 0.012)
        f0 *= 1 + jitter
        phase += 2 * math.pi * f0 / SR
        kmax = int(4800 / f0)
        src = 0.0
        for k in range(1, kmax + 1):
            src += math.sin(k * phase) / (k ** 1.15)
        # sona doğru ağız kapanıyor: F1/F2 hafif iniyor
        if i % 64 == 0:
            close = min(1.0, t / dur)
            for j, (f, bw, _) in enumerate(forms):
                ff = f * (1 - 0.12 * close) if j < 2 else f
                fb[j].set(ff, bw)
                nb[j].set(ff, bw * 1.6)
        voiced = sum(g * fb[j](src) for j, (_, _, g) in enumerate(forms))
        noise = random.uniform(-1, 1)
        breath_amt = 0.55 if t < 0.03 else (0.12 + 0.25 * max(0.0, (t - 0.5) / 0.28))
        breath = sum(g * nb[j](noise) for j, (_, _, g) in enumerate(forms)) * breath_amt
        s = voiced + breath
        # hafif robotik tını
        s = s * (0.88 + 0.12 * math.sin(2 * math.pi * 92 * t))
        amp = min(1.0, t / 0.022) * (1.0 - t / dur) ** 0.7 * (1.15 if t < 0.12 else 1.0)
        out.append(s * amp)
    return out


def zap():
    dur = 1.05
    n = int(SR * dur)
    out = [0.0] * n
    # elektrik çatırtısı: rastgele kısa kıvılcım patlamaları (ilk 0.55 sn yoğun)
    t = 0.0
    while t < 0.6:
        t += random.expovariate(260 if t < 0.4 else 120)
        start = int(t * SR)
        ln = int(SR * random.uniform(0.002, 0.009))
        bp = Bandpass(random.uniform(1800, 6500), 2500)
        g = random.uniform(0.4, 1.0) * (1.0 if t < 0.45 else 0.5)
        for k in range(ln):
            if start + k < n:
                out[start + k] += bp(random.uniform(-1, 1)) * g * math.exp(-k / (ln * 0.35))
    # 100 Hz şebeke vızıltısı, düzensiz genlik
    hum_env = 0.0
    hp = OnePoleHP(60)
    for i in range(n):
        tt = i / SR
        if i % 400 == 0:
            hum_env = random.uniform(0.3, 1.0)
        sq = 1.0 if math.sin(2 * math.pi * 100 * tt) > 0 else -1.0
        hum = hp(sq) * 0.22 * hum_env * (max(0.0, 1 - tt / 0.55) if tt < 0.55 else 0.0)
        out[i] += hum
    # yanma cızırtısı: 0.35 sn'den sonra yükselip sönen yüksek frekanslı gürültü
    hp2 = OnePoleHP(2500)
    flutter = 1.0
    for i in range(n):
        tt = i / SR
        if i % 300 == 0:
            flutter = random.uniform(0.5, 1.0)
        if tt > 0.3:
            e = min(1.0, (tt - 0.3) / 0.1) * math.exp(-(tt - 0.4) * 3.2 if tt > 0.4 else 0)
            out[i] += hp2(random.uniform(-1, 1)) * 0.28 * e * flutter
    for i in range(int(0.004 * SR)):
        out[i] *= i / (0.004 * SR)
    return out


def hit():
    dur = 0.55
    n = int(SR * dur)
    out = []
    ph = 0.0
    partials = [(523, 0.5), (1187, 0.35), (1873, 0.25), (2711, 0.15)]
    for i in range(n):
        t = i / SR
        f = 45 + 110 * math.exp(-t * 18)
        ph += 2 * math.pi * f / SR
        thump = math.sin(ph) * math.exp(-t * 9)
        clank = sum(a * math.sin(2 * math.pi * fq * t) for fq, a in partials) * math.exp(-t * 11) * 0.45
        click = random.uniform(-1, 1) * math.exp(-t * 160) * 0.6
        out.append(thump + clank + click)
    return out


def portal():
    dur = 0.75
    n = int(SR * dur)
    out = []
    bp = Bandpass(300, 400)
    ph = 0.0
    for i in range(n):
        t = i / SR
        x = t / dur
        if i % 64 == 0:
            bp.set(300 + 3200 * x * x, 300 + 900 * x)
        whoosh = bp(random.uniform(-1, 1)) * 1.8
        f = 180 + 780 * x ** 1.6
        ph += 2 * math.pi * f / SR
        glide = math.sin(ph) * 0.25 + math.sin(ph * 2.01) * 0.08
        amp = (x ** 1.4) * (1 if x < 0.92 else max(0.0, (1 - x) / 0.08))
        out.append((whoosh + glide) * amp)
    return out


def bell(freq, t):
    if t < 0:
        return 0.0
    e = math.exp(-t * 4.2) * min(1.0, t / 0.004)
    return e * (math.sin(2 * math.pi * freq * t) + 0.32 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 3)
                + 0.14 * math.sin(2 * math.pi * freq * 3.01 * t) * math.exp(-t * 6))


def level_clear():
    dur = 1.25
    n = int(SR * dur)
    notes = [(1046.5, 0.0), (1318.5, 0.085), (1568.0, 0.17), (2093.0, 0.27)]
    out = []
    for i in range(n):
        t = i / SR
        s = sum(bell(f, t - st) * (1.0 if j < 3 else 1.2) for j, (f, st) in enumerate(notes))
        shimmer = math.sin(2 * math.pi * 3136 * t) * math.exp(-max(0, t - 0.27) * 5) * 0.08 if t > 0.27 else 0
        out.append(s + shimmer)
    return out


def beam_in():
    dur = 0.5
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        x = t / dur
        f = 400 + 1400 * x
        ph += 2 * math.pi * f / SR
        tone = math.sin(ph) * 0.5 + math.sin(ph * 1.5) * 0.2
        sparkle = math.sin(2 * math.pi * (2600 + 900 * math.sin(40 * t)) * t) * 0.15
        amp = math.sin(math.pi * x) ** 1.2
        out.append((tone + sparkle) * amp)
    return out


if __name__ == "__main__":
    write("hero_ahh", hero_ahh())
    write("zap", zap())
    write("hit", hit(), peak=0.85)
    write("portal", portal(), peak=0.7)
    write("level_clear", level_clear(), peak=0.75)
    write("beam_in", beam_in(), peak=0.55)
