#!/usr/bin/env python3
"""Send the existing FIR input vector to an ACX750 and check UART results."""

import argparse
import csv
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COEFF_RE = re.compile(
    r"localparam\s+signed\s+\[(\d+):0\]\s+COEFF_([ABC])_(\d+)\s*=\s*\d+'h([0-9A-Fa-f]+)"
)


def read_coefficients(config):
    values = {}
    for width_m1, name, index, raw in COEFF_RE.findall((ROOT / "coeffs_config.vh").read_text()):
        if name == config:
            width = int(width_m1) + 1
            value = int(raw, 16)
            if value & (1 << (width - 1)):
                value -= 1 << width
            values[int(index)] = (width, value)
    if sorted(values) != list(range(8)):
        raise ValueError(f"Expected eight {config} coefficients in coeffs_config.vh")
    return [values[i] for i in range(8)]


def signed_hex(value, width):
    value = int(value, 16)
    if value & (1 << (width - 1)):
        value -= 1 << width
    return value


def expected_output(history, coefficients):
    total = 0
    for sample, (width, coeff) in zip(history, coefficients):
        shift = 0 if width == 16 else 8 if width == 8 else 12
        total += sample * coeff * (1 << shift)
    total &= (1 << 35) - 1
    if total & (1 << 34):
        total -= 1 << 35
    return total


def main():
    try:
        import serial
    except ImportError:
        raise SystemExit("Install pyserial first: python -m pip install pyserial")

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("port", help="serial port, for example COM5")
    parser.add_argument("--config", choices="ABC", default="C")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--count", type=int, default=157)
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--csv", type=Path, help="save every observed response and reference result")
    args = parser.parse_args()

    inputs = [signed_hex(line.strip(), 16) for line in (ROOT / "input_seq.hex").read_text().splitlines() if line.strip()]
    if not inputs:
        raise SystemExit("input_seq.hex is empty; generate MATLAB test vectors first")
    inputs = inputs[:args.count]
    coefficients = read_coefficients(args.config)
    history = [0] * 8
    errors = 0
    rows = []

    with serial.Serial(args.port, args.baud, timeout=args.timeout, write_timeout=args.timeout) as link:
        link.reset_input_buffer()
        link.reset_output_buffer()
        time.sleep(0.1)
        for index, sample in enumerate(inputs):
            history = [sample] + history[:-1]
            expected = expected_output(history, coefficients)
            encoded = sample & 0xFFFF
            link.write(bytes((encoded & 0xFF, (encoded >> 8) & 0xFF)))
            response = link.read(5)
            if len(response) != 5:
                raise SystemExit(
                    f"Timeout at sample {index}: received {len(response)}/5 response bytes. "
                    "Check board reset, bitstream CONFIG, UART wiring, and baud rate."
                )
            observed = int.from_bytes(response, byteorder="big", signed=True)
            rows.append((index, sample, expected, observed, response.hex(), int(observed == expected)))
            if observed != expected:
                errors += 1
                print(f"Mismatch {index}: input={sample} expected={expected} got={observed}")
            elif index < 5:
                print(f"Pass {index}: input={sample} output={observed}")

    if args.csv:
        with args.csv.open("w", newline="", encoding="utf-8") as output:
            writer = csv.writer(output)
            writer.writerow(("index", "input_signed16", "expected_signed35", "observed_signed40", "response_hex", "match"))
            writer.writerows(rows)
        print(f"Saved {len(rows)} sample records to {args.csv}")
    print(f"Config {args.config}: {len(inputs)} samples, {errors} mismatches")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
