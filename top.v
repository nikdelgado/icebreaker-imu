
module top (
    output LEDG_N,
    output LEDR_N,
    input BTN_N,
    input CLK
);

reg [23:0] counter;

always @(posedge CLK) begin
    counter <= counter + 1;

end

assign LEDG_N = counter[23];
assign LEDR_N = BTN_N;

endmodule