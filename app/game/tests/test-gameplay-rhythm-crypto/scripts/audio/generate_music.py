#!/usr/bin/env python3
"""Render the retained original arrangement as a looping PCM WAV."""

from array import array
import json
import math
from pathlib import Path
import random
import wave


SCENE_ROOT = Path(__file__).resolve().parents[2]
CONTEXT = SCENE_ROOT / "test-gameplay-rhythm-crypto.json"


def midi_frequency(note):
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    pitch = note[:-1]
    octave = int(note[-1])
    accidental = 1 if "#" in pitch else -1 if "b" in pitch else 0
    semitone = names[pitch[0]] + accidental
    number = (octave + 1) * 12 + semitone
    return 440.0 * 2.0 ** ((number - 69) / 12.0)


def envelope(t, duration, attack, release):
    attack_gain = min(1.0, t / max(attack, 1e-5))
    release_gain = min(1.0, max(0.0, duration - t) / max(release, 1e-5))
    return attack_gain * release_gain


def add_tone(buffer, sample_rate, start, duration, frequency, waveform, gain):
    first = max(0, int(round(start * sample_rate)))
    count = min(int(round(duration * sample_rate)), len(buffer) - first)
    if count <= 0:
        return
    attack = min(0.018, duration * 0.25)
    release = min(0.11, duration * 0.32)
    for offset in range(count):
        t = offset / sample_rate
        phase = 2.0 * math.pi * frequency * t
        if waveform == "pulse":
            value = (math.sin(phase) + 0.34 * math.sin(3 * phase) +
                     0.16 * math.sin(5 * phase)) / 1.5
        else:
            value = (math.sin(phase) - math.sin(3 * phase) / 9.0 +
                     math.sin(5 * phase) / 25.0) * 0.92
        buffer[first + offset] += gain * envelope(t, duration, attack, release) * value


def add_kick(buffer, sample_rate, start, gain):
    first = int(round(start * sample_rate))
    duration = 0.20
    count = min(int(duration * sample_rate), len(buffer) - first)
    for offset in range(max(0, count)):
        t = offset / sample_rate
        frequency = 43.0 + 108.0 * math.exp(-24.0 * t)
        phase = 2.0 * math.pi * (43.0 * t + 108.0 * (1.0 - math.exp(-24.0 * t)) / 24.0)
        buffer[first + offset] += gain * math.exp(-21.0 * t) * math.sin(phase)


def add_snare(buffer, sample_rate, start, gain, noise):
    first = int(round(start * sample_rate))
    duration = 0.17
    count = min(int(duration * sample_rate), len(buffer) - first)
    for offset in range(max(0, count)):
        t = offset / sample_rate
        body = math.sin(2.0 * math.pi * (185.0 - 30.0 * t) * t) * 0.35
        hiss = (noise.random() * 2.0 - 1.0) * 0.65
        buffer[first + offset] += gain * math.exp(-26.0 * t) * (body + hiss)


def add_hat(buffer, sample_rate, start, gain, noise, previous):
    first = int(round(start * sample_rate))
    duration = 0.055
    count = min(int(duration * sample_rate), len(buffer) - first)
    last = previous[0]
    for offset in range(max(0, count)):
        t = offset / sample_rate
        raw = noise.random() * 2.0 - 1.0
        high_pass = raw - last * 0.78
        last = raw
        buffer[first + offset] += gain * math.exp(-68.0 * t) * high_pass
    previous[0] = last


def render(music):
    sample_rate = music["synthesis"]["sample_rate_hz"]
    bpm = music["tempo_bpm"]
    beats_per_bar = music["time_signature"][0]
    bars = music["bar_count"]
    beat = 60.0 / bpm
    bar_duration = beat * beats_per_bar
    eighth = beat / music["subdivisions_per_beat"]
    duration = bar_duration * bars
    samples = array("f", [0.0]) * int(round(duration * sample_rate))
    parts = music["parts"]

    for bar, notes in enumerate(parts["lead"]["notes_by_bar_eighths"]):
        for step, note in enumerate(notes):
            if note:
                add_tone(samples, sample_rate, bar * bar_duration + step * eighth,
                         eighth * 0.84, midi_frequency(note), parts["lead"]["waveform"],
                         parts["lead"]["gain"])

    bass = parts["bass"]
    if "notes_by_bar_eighths" in bass:
        for bar, notes in enumerate(bass["notes_by_bar_eighths"]):
            for step, note in enumerate(notes):
                if note:
                    add_tone(samples, sample_rate, bar * bar_duration + step * eighth,
                             eighth * 0.78, midi_frequency(note), bass["waveform"],
                             bass["gain"])
    else:
        for bar, notes in enumerate(bass["notes_by_bar_quarters"]):
            for beat_index, note in enumerate(notes):
                add_tone(samples, sample_rate, bar * bar_duration + beat_index * beat,
                         beat * 0.86, midi_frequency(note), bass["waveform"],
                         bass["gain"])

    for bar, chord in enumerate(parts["pad"]["chords_by_bar"]):
        start = bar * bar_duration
        for note in chord:
            add_tone(samples, sample_rate, start, bar_duration, midi_frequency(note),
                     parts["pad"]["waveform"], parts["pad"]["gain"])

    noise = random.Random(1731)
    previous_hat_noise = [0.0]
    drums = parts["drums"]
    for bar in range(bars):
        start = bar * bar_duration
        for step in drums["kick_steps_by_bar"][bar]:
            add_kick(samples, sample_rate, start + step * eighth, 0.31)
        for step in drums["snare_steps_by_bar"][bar]:
            add_snare(samples, sample_rate, start + step * eighth, 0.12, noise)
        for step in drums["hat_steps_by_bar"][bar]:
            hat_gain = 0.028 if step % 2 == 0 else 0.052
            add_hat(samples, sample_rate, start + step * eighth, hat_gain, noise, previous_hat_noise)

    peak = max((abs(value) for value in samples), default=1.0)
    scale = music["synthesis"]["master_gain"] / max(peak, 1e-5)
    pcm = array("h")
    for value in samples:
        clipped = max(-1.0, min(1.0, value * scale))
        pcm.append(int(round(clipped * 32767)))
    if pcm.itemsize != 2:
        raise RuntimeError("Questo script richiede campioni PCM a 16 bit.")
    return sample_rate, pcm


def main():
    music = json.loads(CONTEXT.read_text(encoding="utf-8"))["music-original"]
    sample_rate, pcm = render(music)
    destination = SCENE_ROOT / "exports" / Path(music["loop_export"]).name
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(pcm.tobytes())
    print(f"Creato {destination} ({len(pcm) / sample_rate:.2f} s, {sample_rate} Hz)")


if __name__ == "__main__":
    main()
