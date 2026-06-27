# icebreaker-imu

Learning Verilog/FPGAs from scratch on an **iCEBreaker** (Lattice iCE40 UP5K, sg48),
building up to reading sensor telemetry from an **ICM-20948 IMU** over SPI and
eventually displaying it over HDMI/DVI.

This is a learning project: every line is written by hand, one concept at a time.

## Toolchain

[oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) (yosys, nextpnr-ice40,
icepack, iceprog, iverilog, gtkwave). Put it on PATH for the current shell:

```sh
export PATH="$HOME/oss-cad-suite/bin:$PATH"
# or: source ~/oss-cad-suite/environment
```

## Build & flash

```sh
make            # synth (yosys) -> place&route (nextpnr) -> bitstream (top.bin)
make prog       # flash top.bin to the board over USB (iceprog)
make clean      # remove build artifacts
```

The top-level module must be named `top` and live in `top.v`. Port names must match
the signal names in `icebreaker.pcf` (that file maps names -> physical pins).

## Simulation

```sh
iverilog -g2012 -o sim tb_<thing>.v <thing>.v   # compile testbench + module
vvp sim                                          # run; prints output, writes wave.vcd
gtkwave wave.vcd                                 # inspect waveforms
```

Lesson learned early: **a testbench only proves what it actually checks.** Always
verify the signals you *drive* (e.g. MOSI), not just the ones you receive.

## Board cheat-sheet (from icebreaker.pcf)

| Signal      | Pin | Notes                                  |
|-------------|-----|----------------------------------------|
| `CLK`       | 35  | 12 MHz oscillator                      |
| `BTN_N`     | 10  | user button, **active low**            |
| `LEDR_N`    | 11  | red LED, **active low** (drive 0 = on) |
| `LEDG_N`    | 37  | green LED, **active low**              |
| `RX` / `TX` | 6/9 | UART (for debug printing later)        |
| PMOD 1A/1B/2|     | external headers (IMU goes here later) |

## Roadmap

1. **Light an LED solid** — module, ports, the PCF, build & flash. *(no clock)*
2. **Blink an LED** — the clock, registers, `always @(posedge clk)`, counters.
3. **Button -> LED** — inputs, combinational vs clocked logic.
4. **UART TX** — send a byte to the PC so we have a real debug channel.
5. **SPI master** — bit-bang/FSM to clock data in and out.
6. **Read WHO_AM_I (0x00) from ICM-20948** — expect `0xEA`. First real handshake.
7. Sensor reads (accel/gyro), then HDMI/DVI display.
