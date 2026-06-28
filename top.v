
module top (
    output TX,
    input BTN_N,
    input CLK
);

reg [7:0] tx_rate_counter = 0;
reg [9:0] shift_register = 10'h3FF;
reg [5:0] bit_counter = 0;

assign TX = shift_register[0];

always @(posedge CLK) begin
    tx_rate_counter <= tx_rate_counter + 1;

    if (tx_rate_counter == 103) begin
        tx_rate_counter <= 0;

        if (bit_counter == 10) begin
            bit_counter <= 0;
            shift_register <= {1'b1, 8'h55, 1'b0};
        end else begin
            bit_counter <= bit_counter + 1;
            shift_register <= {1'b1, shift_register[9:1]};
        end
    end
end
endmodule