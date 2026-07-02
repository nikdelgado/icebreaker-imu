PROJ    = top
PIN_DEF = icebreaker.pcf
DEVICE  = up5k
PACKAGE = sg48
ADD_SRC = uart_tx.v spi_master.v

prog: iceprog

include main.mk
