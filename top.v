// top - controller that wakes the IMU, burst-reads 3-axis accel, and streams
// it as "XXXX YYYY ZZZZ\r\n" over UART. All the real work lives in the
// spi_master and uart_tx modules; this is just orchestration.
module top (
    output TX,
    output spi_mosi,
    output spi_sclk,
    output spi_cs,
    input  spi_miso,
    input  CLK
);
    // ---------------- SPI master ----------------
    reg  [55:0] spi_tx_data  = 0;
    reg  [6:0]  spi_num_bits = 0;
    reg         spi_start    = 0;
    wire [47:0] spi_rx_data;
    wire        spi_done;

    spi_master #(.HALF_CLKS(4)) u_spi (
        .clk(CLK), .tx_data(spi_tx_data), .num_bits(spi_num_bits),
        .start(spi_start), .miso(spi_miso),
        .sclk(spi_sclk), .mosi(spi_mosi), .cs(spi_cs),
        .rx_data(spi_rx_data), .done(spi_done)
    );

    // ---------------- UART transmitter ----------------
    reg  [7:0] uart_data  = 0;
    reg        uart_start = 0;
    wire       uart_busy;

    uart_tx #(.CLKS_PER_BIT(104)) u_uart (
        .clk(CLK), .data(uart_data), .start(uart_start),
        .tx(TX), .busy(uart_busy)
    );

    // ---------------- formatting helpers ----------------
    reg [47:0] spi_result = 0;        // latest X/Y/Z sample
    reg [3:0]  char_index = 0;        // which of the 16 output chars

    function [7:0] hex_to_char(input [3:0] nibble);
        if (nibble < 10) hex_to_char = "0" + nibble;
        else             hex_to_char = "A" + (nibble - 10);
    endfunction

    function [7:0] get_tx_byte(input [3:0] idx);
        case (idx)
            4'd0:  get_tx_byte = hex_to_char(spi_result[47:44]);
            4'd1:  get_tx_byte = hex_to_char(spi_result[43:40]);
            4'd2:  get_tx_byte = hex_to_char(spi_result[39:36]);
            4'd3:  get_tx_byte = hex_to_char(spi_result[35:32]);
            4'd4:  get_tx_byte = 8'h20;                         // space
            4'd5:  get_tx_byte = hex_to_char(spi_result[31:28]);
            4'd6:  get_tx_byte = hex_to_char(spi_result[27:24]);
            4'd7:  get_tx_byte = hex_to_char(spi_result[23:20]);
            4'd8:  get_tx_byte = hex_to_char(spi_result[19:16]);
            4'd9:  get_tx_byte = 8'h20;                         // space
            4'd10: get_tx_byte = hex_to_char(spi_result[15:12]);
            4'd11: get_tx_byte = hex_to_char(spi_result[11:8]);
            4'd12: get_tx_byte = hex_to_char(spi_result[7:4]);
            4'd13: get_tx_byte = hex_to_char(spi_result[3:0]);
            4'd14: get_tx_byte = 8'h0D;                         // \r
            default: get_tx_byte = 8'h0A;                       // \n
        endcase
    endfunction

    // ---------------- controller FSM ----------------
    localparam WAKE_START  = 3'd0,   // issue the wake write
               WAKE_WAIT   = 3'd1,
               READ_START  = 3'd2,   // issue the accel burst read
               READ_WAIT   = 3'd3,
               PRINT_NEXT  = 3'd4,   // hand one byte to the UART
               PRINT_BUSY  = 3'd5,   // wait for UART to accept it
               PRINT_WAIT  = 3'd6;   // wait for UART to finish it
    reg [2:0] cstate = WAKE_START;

    always @(posedge CLK) begin
        spi_start  <= 0;   // pulses: default low, raised for one cycle below
        uart_start <= 0;

        case (cstate)
            WAKE_START: begin
                spi_tx_data  <= {24'h060100, 32'h0};  // PWR_MGMT_1<=0x01, PWR_MGMT_2<=0x00
                spi_num_bits <= 24;
                spi_start    <= 1;
                cstate       <= WAKE_WAIT;
            end
            WAKE_WAIT: if (spi_done) cstate <= READ_START;

            READ_START: begin
                spi_tx_data  <= {8'hAD, 48'h0};        // read ACCEL_XOUT_H + 6 bytes
                spi_num_bits <= 56;
                spi_start    <= 1;
                cstate       <= READ_WAIT;
            end
            READ_WAIT: if (spi_done) begin
                spi_result <= spi_rx_data;
                char_index <= 0;
                cstate     <= PRINT_NEXT;
            end

            PRINT_NEXT: begin
                uart_data  <= get_tx_byte(char_index);
                uart_start <= 1;
                cstate     <= PRINT_BUSY;
            end
            PRINT_BUSY: if (uart_busy) cstate <= PRINT_WAIT;
            PRINT_WAIT: if (!uart_busy) begin
                if (char_index == 15) cstate <= READ_START;   // done; read again
                else begin
                    char_index <= char_index + 1;
                    cstate     <= PRINT_NEXT;
                end
            end
        endcase
    end
endmodule
