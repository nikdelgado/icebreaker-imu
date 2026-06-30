
module top (
    output TX,
    output spi_mosi,
    output reg spi_sclk,
    output reg spi_cs,
    input spi_miso,
    input CLK
);

localparam IDLE = 2'd0, ASSERT = 2'd1, TRANSFER = 2'd2, DONE = 2'd3;

reg [7:0]   uart_tx_rate_counter = 0;
reg [3:0]   uart_char_index = 0;
reg [9:0]   uart_shift_register = 10'h3FF;
reg [5:0]   uart_bit_counter = 0;
reg [55:0]  spi_shift_register;
reg [5:0]   spi_bit_counter = 0;
reg [47:0]  spi_result = 0;
reg [5:0]   spi_num_bits = 0;
reg         spi_rx_bit = 0;
reg         spi_woken = 0;
reg [2:0]   clock_divider = 0;
reg [1:0]   state = IDLE;

assign TX = uart_shift_register[0];
assign spi_mosi = spi_shift_register[55];

function [7:0] hex_to_char(input [3:0] nibble);
    if (nibble < 10) 
        hex_to_char = "0" + nibble;
    else
        hex_to_char = "A" + (nibble - 10);
endfunction

function [7:0] get_tx_byte (input [3:0] idx);
    case (idx)
        4'd0: get_tx_byte = hex_to_char(spi_result[47:44]);
        4'd1: get_tx_byte = hex_to_char(spi_result[43:40]);
        4'd2: get_tx_byte = hex_to_char(spi_result[39:36]);
        4'd3: get_tx_byte = hex_to_char(spi_result[35:32]);
        4'd4: get_tx_byte = 8'h20;
        4'd5: get_tx_byte = hex_to_char(spi_result[31:28]);
        4'd6: get_tx_byte = hex_to_char(spi_result[27:24]);
        4'd7: get_tx_byte = hex_to_char(spi_result[23:20]);
        4'd8: get_tx_byte = hex_to_char(spi_result[19:16]);
        4'd9: get_tx_byte = 8'h20;
        4'd10: get_tx_byte = hex_to_char(spi_result[15:12]);
        4'd11: get_tx_byte = hex_to_char(spi_result[11:8]);
        4'd12: get_tx_byte = hex_to_char(spi_result[7:4]);
        4'd13: get_tx_byte = hex_to_char(spi_result[3:0]);
        4'd14: get_tx_byte = 8'h0D;
        default: get_tx_byte = 8'h0A;
    endcase
endfunction

always @(posedge CLK) begin
    uart_tx_rate_counter <= uart_tx_rate_counter + 1;
    clock_divider <= clock_divider + 1;

    if (uart_tx_rate_counter == 103) begin
        uart_tx_rate_counter <= 0;

        if (uart_bit_counter == 10) begin
            uart_bit_counter <= 0;
            uart_shift_register <= {1'b1, get_tx_byte(uart_char_index), 1'b0};
            uart_char_index <= uart_char_index + 1;

        end else begin
            uart_bit_counter <= uart_bit_counter + 1;
            uart_shift_register <= {1'b1, uart_shift_register[9:1]};
        end
    end

    if (clock_divider == 4) begin
        clock_divider <= 0;

        case (state)
            IDLE: begin
                if (!spi_woken) begin
                    spi_shift_register <= {24'h060100, 32'h0}; 
                    spi_num_bits <= 24;
                end else begin
                    spi_shift_register <= {8'hAD, 48'h0}; 
                    spi_num_bits <= 56;
                end

                spi_cs <= 1;
                spi_sclk <= 0;
                spi_bit_counter <= 0;
                state <= ASSERT;

            end ASSERT: begin
                spi_cs <= 0;
                state <= TRANSFER;

            end TRANSFER: begin
                spi_sclk <= ~spi_sclk;

                if (spi_sclk == 0) begin
                    spi_rx_bit <= spi_miso;
                end else begin
                    spi_shift_register <= {spi_shift_register[54:0], spi_rx_bit};
                    spi_bit_counter <= spi_bit_counter + 1;

                    if (spi_bit_counter == spi_num_bits - 1) begin
                        state <= DONE;
                    end
                end

            end DONE: begin
                spi_cs <= 1;
                spi_result <= spi_shift_register[47:0];
                spi_woken <= 1;
                state <= IDLE;
            end
        endcase

    end
end
endmodule