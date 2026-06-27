
module top (
    output LEDG_N,
    input CLK
);

reg [23:0] counter;

always @(posedge CLK) begin
    counter <= counter + 1;
end

assign LEDG_N = counter[23];

endmodule