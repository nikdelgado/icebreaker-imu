// uart_tx - 8N1 UART transmitter with a start/busy handshake.
//
//   start : pulse high 1 cycle to begin sending `data` (ignored while busy)
//   busy  : high from the moment a byte is accepted until its stop bit ends
//
// Interface idea: the caller presents a byte, pulses `start`, then waits for
// `busy` to fall before sending the next one.
module uart_tx #(
    parameter CLKS_PER_BIT = 104   // 12 MHz / 115200 baud
) (
    input        clk,
    input  [7:0] data,
    input        start,
    output       tx,
    output reg   busy
);
    reg [9:0] shift_reg = 10'h3FF;  // idle line = all ones
    reg [3:0] bit_count = 0;        // which of the 10 frame bits we're on
    reg [7:0] clk_count = 0;        // baud divider

    assign tx = shift_reg[0];       // LSB-first: start bit leaves first

    initial busy = 0;

    always @(posedge clk) begin
        if (!busy) begin
            if (start) begin
                shift_reg <= {1'b1, data, 1'b0}; // stop, data, start
                bit_count <= 0;
                clk_count <= 0;
                busy      <= 1;
            end
        end else begin
            if (clk_count == CLKS_PER_BIT - 1) begin
                clk_count <= 0;
                if (bit_count == 9) begin
                    busy      <= 0;          // stop bit done
                    shift_reg <= 10'h3FF;    // return line to idle high
                end else begin
                    bit_count <= bit_count + 1;
                    shift_reg <= {1'b1, shift_reg[9:1]};
                end
            end else begin
                clk_count <= clk_count + 1;
            end
        end
    end
endmodule
