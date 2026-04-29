#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def parse_vcd(path: Path):
    sym_to_name = {}
    values = {}
    scalars = {}
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if line.startswith("$var"):
                parts = line.split()
                if len(parts) >= 5:
                    code = parts[3]
                    name = parts[4]
                    sym_to_name[code] = name
                    values.setdefault(name, [])
            elif line.startswith("b"):
                m = re.match(r"b([01xXzZ]+)\s+(\S+)", line)
                if m and m.group(2) in sym_to_name:
                    name = sym_to_name[m.group(2)]
                    values.setdefault(name, []).append(m.group(1).lower())
            elif line and line[0] in "01xXzZ":
                code = line[1:]
                if code in sym_to_name:
                    name = sym_to_name[code]
                    bit = line[0].lower()
                    scalars.setdefault(name, []).append(bit)
    return values, scalars


def has_unknown(bits):
    return any(("x" in b or "z" in b) for b in bits)


def last_is_known(bits):
    if not bits:
        return False
    b = bits[-1]
    return ("x" not in b) and ("z" not in b)


def expect(condition, msg):
    if not condition:
        raise SystemExit(f"vcd sanity fail: {msg}")


def known_scalar_samples(samples):
    return [b for b in samples if b in ("0", "1")]


def known_vector_samples(samples):
    return [b for b in samples if ("x" not in b and "z" not in b)]


def vector_int_samples(samples):
    out = []
    for b in known_vector_samples(samples):
        out.append(int(b, 2))
    return out


def vector_int_events(samples):
    out = []
    for idx, sample in enumerate(samples):
        if isinstance(sample, tuple):
            t, b = sample
        else:
            t, b = idx, sample
        if "x" in b or "z" in b:
            continue
        out.append((t, int(b, 2)))
    return out


def check_mode(mode, vectors, scalars):
    if mode == "pq":
        expect("head_valid" in scalars, "missing head_valid")
        hv = known_scalar_samples(scalars["head_valid"])
        expect(hv, "head_valid has no known samples")
        expect("1" in hv, "head_valid never asserted")
        expect(last_is_known(scalars["head_valid"]), "head_valid final state unknown")
        expect("depth" in vectors, "missing depth")
        depth_vals = vector_int_samples(vectors["depth"])
        expect(depth_vals, "depth has no known samples")
        expect(max(depth_vals) > 0, "depth never increases above zero")
    elif mode == "sq":
        expect("wake_valid" in scalars, "missing wake_valid")
        wv = known_scalar_samples(scalars["wake_valid"])
        expect(wv, "wake_valid has no known samples")
        expect("1" in wv, "wake_valid never asserted")
        expect(last_is_known(scalars["wake_valid"]), "wake_valid final state unknown")
        expect("depth" in vectors, "missing depth")
        depth_vals = vector_int_samples(vectors["depth"])
        expect(depth_vals, "depth has no known samples")
        expect(max(depth_vals) > 0, "sleep queue depth never increases above zero")
    elif mode == "top":
        expect("irq_n" in scalars, "missing irq_n")
        irq = known_scalar_samples(scalars["irq_n"])
        expect(irq, "irq_n has no known samples")
        expect(last_is_known(scalars["irq_n"]), "irq_n final state unknown")
        expect("ext_irq" in vectors, "missing ext_irq")
        ext_events = vector_int_events(vectors["ext_irq"])
        expect(ext_events, "ext_irq has no known vector samples")
        expect(any(v != 0 for _, v in ext_events), "ext_irq never asserted in top waveform")
        expect("0" in irq, "irq_n never asserted low in top waveform")
    elif mode == "ctrl":
        expect("need_word2" in scalars, "missing need_word2")
        nw2 = known_scalar_samples(scalars["need_word2"])
        expect(nw2, "need_word2 has no known samples")
        expect("1" in nw2, "need_word2 never asserted")
        expect(last_is_known(scalars["need_word2"]), "need_word2 final state unknown")
        expect("pending_word2" in scalars, "missing pending_word2")
        pw2 = known_scalar_samples(scalars["pending_word2"])
        expect(pw2, "pending_word2 has no known samples")
        expect("1" in pw2, "pending_word2 never asserted")
        expect(last_is_known(scalars["pending_word2"]), "pending_word2 final state unknown")
        expect("irq_reason" in vectors, "missing irq_reason")
        irq_reason_vals = set(vector_int_samples(vectors["irq_reason"]))
        expect(0x05 in irq_reason_vals, "fast external irq reason 0x05 not observed")
        expect(0x06 in irq_reason_vals, "slow external irq reason 0x06 not observed")
    elif mode == "phase1":
        expect("need_word2" in scalars, "missing need_word2")
        nw2 = known_scalar_samples(scalars["need_word2"])
        expect("1" in nw2, "need_word2 did not pulse in phase1 waveform")

        expect("rsp_word" in vectors, "missing rsp_word")
        rsp_vals = set(vector_int_samples(vectors["rsp_word"]))
        expect(0x0000C006 in rsp_vals, "modify response 0x0000C006 not observed")

        expect("sq_enq_counter" in vectors, "missing sq_enq_counter")
        sq_vals = set(vector_int_samples(vectors["sq_enq_counter"]))
        expect(0x12345678 in sq_vals, "32-bit long sleep counter value not observed")
    else:
        raise SystemExit(f"unsupported mode: {mode}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vcd_path")
    ap.add_argument("--mode", required=True, choices=["pq", "sq", "top", "ctrl", "phase1"])
    args = ap.parse_args()

    path = Path(args.vcd_path)
    expect(path.exists(), f"vcd file not found: {path}")
    vectors, scalars = parse_vcd(path)
    check_mode(args.mode, vectors, scalars)
    print(f"vcd sanity pass: {path.name} mode={args.mode}")


if __name__ == "__main__":
    main()
