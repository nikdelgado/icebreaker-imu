#!/usr/bin/env python3
"""Parse and display the IMU accel telemetry streamed by top.v.
Example:
    ./imu_view.py --port /dev/cu.usbserial-ibqrdrF21
"""
import argparse
import sys

import serial  

LSB_PER_G = 16384.0  

def to_signed16(raw):
    """Interpret a 16-bit value as two's-complement signed."""
    return raw - 0x10000 if raw & 0x8000 else raw


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--port", "-p", required=True)
    args = ap.parse_args()

    with serial.Serial(args.port, 115200) as ser:
        print(f"# reading {args.port}")
        while True:
            line = ser.readline().decode("ascii", errors="replace").strip()
            if not line:
                continue
            fields = line.split()
            try:
                x, y, z = (to_signed16(int(f, 16)) for f in fields)
            except ValueError:
                continue

            else:
                print(f"x={x:7d} ({x/LSB_PER_G :+.3f}g)  "
                      f"y={y:7d} ({y/LSB_PER_G :+.3f}g)  "
                      f"z={z:7d} ({z/LSB_PER_G :+.3f}g)")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
