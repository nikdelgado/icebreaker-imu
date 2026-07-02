# icebreaker-imu

Learning Verilog/FPGAs from scratch on an **iCEBreaker** (Lattice iCE40 UP5K, sg48).
The goal is to implement SPI and UART from scratch in Verilog and use them to read an
ICM-20948 IMU, streaming accelerometer data back to the PC over UART.

## Demo
https://youtu.be/aYoU_bqlsIE

## Toolchain

[oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) (yosys, nextpnr-ice40,
icepack, iceprog). Put it on PATH for the current shell:

```sh
source ~/oss-cad-suite/environment
```

## Build & flash

```sh
make            
make prog       
make clean      
```

## Viewing telemetry

`top.v` streams `XXXX YYYY ZZZZ\r\n` (hex, 16-bit signed accel) at 115200 8N1.
`imu_view.py` decodes it to signed ints and g:

```sh
./imu_view.py --port <serial-device>  
```

## icebreaker.pcf

| Signal      | Pin | Notes                                  |
|-------------|-----|----------------------------------------|
| `CLK`       | 35  | 12 MHz oscillator                      |
| `TX`        | 9   | UART to PC                             |
| `spi_sclk`  | 19  | SPI clock                              |
| `spi_mosi`  | 25  | master -> IMU                          |
| `spi_miso`  | 21  | IMU -> master                          |
| `spi_cs`    | 27  | chip select, **active low**            |

