// 50mhz clock
`default_nettype none
module tb_harness ( input wire clk, input wire rst );

    ////////////////////////
    // wire declarations //
    //////////////////////
    wire uart_rx;
    wire uart_tx;
    wire finished;

    CoreWrapper iCORE(
        .clk(clk), 
        .rst(rst),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .finished(finished)
    );

    /////////////////////////////
    // instantiate uart model //
    ///////////////////////////
    uartdpi #(
        .BAUD(115200),
        .FREQ(50_000_000)
    ) iUART (
        .clk_i(clk),
        .rst_ni(~rst),
        .active(1'b1),
        .tx_o(uart_rx),
        .rx_i(uart_tx)
    );

initial begin
    if ($test$plusargs("trace") != 0) begin
        $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
        $dumpfile("logs/vlt_dump.vcd");
        $dumpvars();
    end
end
    always @* begin
        if (finished) $finish;
    end
endmodule
`default_nettype wire