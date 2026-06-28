
module top (
    output TX,
    output spi_mosi,
    output reg spi_sclk,
    output reg spi_cs,
    input spi_miso,
    input CLK
);

localparam IDLE = 2'd0, TRANSFER = 2'd1, DONE = 2'd2;

reg [7:0] tx_rate_counter = 0;
reg [9:0] uart_shift_register = 10'h3FF;
reg [15:0] spi_shift_register;
reg [5:0] uart_bit_counter = 0;
reg [4:0] spi_bit_counter = 0;
reg [2:0] clock_divider = 0;
reg [1:0] state = IDLE;
reg [7:0] spi_result = 0;
reg spi_rx_bit = 0;

assign TX = uart_shift_register[0];
assign spi_mosi = spi_shift_register[15];

always @(posedge CLK) begin
    tx_rate_counter <= tx_rate_counter + 1;
    clock_divider <= clock_divider + 1;

    if (tx_rate_counter == 103) begin
        tx_rate_counter <= 0;

        if (uart_bit_counter == 10) begin
            uart_bit_counter <= 0;
            uart_shift_register <= {1'b1, 8'h55, 1'b0};
        end else begin
            uart_bit_counter <= uart_bit_counter + 1;
            uart_shift_register <= {1'b1, uart_shift_register[9:1]};
        end
    end

    if (clock_divider == 4) begin
        clock_divider <= 0;

        case (state)
            IDLE: begin
                spi_cs <= 1;
                spi_sclk <= 0;
                spi_shift_register <= 16'h8000;
                spi_bit_counter <= 0;
                state <= TRANSFER;
                
            end TRANSFER: begin
                spi_cs <= 0;
                spi_sclk <= ~spi_sclk;

                if (spi_sclk == 0) begin
                    spi_rx_bit <= spi_miso;
                end else begin
                    spi_shift_register <= {spi_shift_register[14:0], spi_rx_bit};
                    spi_bit_counter <= spi_bit_counter + 1;

                    if (spi_bit_counter == 15) begin
                        state <= DONE;
                    end
                end

            end DONE: begin
                spi_cs <= 1;
                spi_result <= spi_shift_register[7:0];
                state <= IDLE;
            end
        endcase

    end
end
endmodule