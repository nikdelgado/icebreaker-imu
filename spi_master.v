// spi_master - variable-length SPI mode-0 master with start/done handshake.
//
//   tx_data  : up to 56 bits, sent MSB-first starting from bit [55]
//   num_bits : how many bits this transfer clocks (e.g. 24 write, 56 read)
//   start    : pulse high 1 cycle to begin
//   done     : pulses high 1 cycle when the transfer finishes
//   rx_data  : the low 48 received bits (the data bytes after the command)
//
// Mode 0: SCLK idles low, MOSI changes on the falling edge, MISO is sampled
// on the rising edge, CS active-low with a one-half-period setup (ASSERT).
module spi_master #(
    parameter HALF_CLKS = 4    // SCLK half-period, in clk cycles
) (
    input         clk,
    input  [55:0] tx_data,
    input  [6:0]  num_bits,
    input         start,
    input         miso,
    output reg    sclk,
    output        mosi,
    output reg    cs,
    output [47:0] rx_data,
    output reg    done
);
    localparam IDLE = 2'd0, ASSERT = 2'd1, TRANSFER = 2'd2, FINISH = 2'd3;
    reg [1:0]  state = IDLE;
    reg [55:0] shreg = 0;
    reg [6:0]  bit_count = 0;
    reg [6:0]  len = 0;
    reg [2:0]  div = 0;
    reg        rx_bit = 0;

    assign mosi    = shreg[55];     // MSB-first out
    assign rx_data = shreg[47:0];

    initial begin cs = 1; sclk = 0; done = 0; end

    always @(posedge clk) begin
        done <= 0;                  // default; only pulses in FINISH
        case (state)
            IDLE: begin
                cs   <= 1;
                sclk <= 0;
                if (start) begin
                    shreg     <= tx_data;
                    len       <= num_bits;
                    bit_count <= 0;
                    div       <= 0;
                    state     <= ASSERT;
                end
            end

            ASSERT: begin            // CS low, SCLK still low: setup time
                cs <= 0;
                if (div == HALF_CLKS) begin
                    div   <= 0;
                    state <= TRANSFER;
                end else div <= div + 1;
            end

            TRANSFER: begin
                if (div == HALF_CLKS) begin
                    div  <= 0;
                    sclk <= ~sclk;
                    if (sclk == 0) begin            // about to rise: sample
                        rx_bit <= miso;
                    end else begin                  // about to fall: shift+count
                        shreg     <= {shreg[54:0], rx_bit};
                        bit_count <= bit_count + 1;
                        if (bit_count == len - 1) state <= FINISH;
                    end
                end else div <= div + 1;
            end

            FINISH: begin
                cs    <= 1;
                done  <= 1;          // 1-cycle completion pulse
                state <= IDLE;
            end
        endcase
    end
endmodule
