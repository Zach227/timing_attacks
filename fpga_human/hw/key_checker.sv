//////////////////////////////////////////////////////////////////////////////////
// Module: key_checker
// Author: Jacob Brown
// Date: 11/19/2025
// Description:
//   Module that receives 4 button presses, compares against the key set by the
//   switches, and sets success or fail high. Compare function is not constant time
//   so it is susceptible to a timing attack.
//////////////////////////////////////////////////////////////////////////////////

module key_checker(
    input logic clk, rst,
    input logic [2:0] btn,
    input logic [7:0] key,
    output logic success, fail
);

    // states
    localparam WAIT_RECEIVE_ST = 2'b00;
    localparam WAIT_CHECK_ST = 2'b01;
    localparam DONE_ST = 2'b10;

    logic [1:0] current_st;
    logic [7:0] btn_vals;
    logic receive_done;
    logic enable_compare;

    assign in_receive = current_st == WAIT_RECEIVE_ST;
    assign in_compare = current_st == WAIT_CHECK_ST;
    assign in_done = current_st == DONE_ST;

    receive_buttons #(
        .CLK_FREQUENCY(50000000),
        .DEBOUNCE_DELAY_US(1_000))
    receive_buttons (
        .clk(clk),
        .reset(rst),
        .btns_in(btn),
        .done(receive_done),
        .btns_out(btn_vals) // size 4 array of 2 bit values 
    );

    compare compare(
        .clk(clk),
        .rst(rst),
        .enable(enable_compare),
        .correct_value(key),
        .guessed_value(btn_vals),
        .success(success),
        .fail(fail)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            current_st <= WAIT_RECEIVE_ST;
            enable_compare <= 0;
        end
        else begin
            if (current_st == WAIT_RECEIVE_ST) begin
                if (receive_done) begin
                    current_st <= WAIT_CHECK_ST;
                    enable_compare <= 1;
                end
            end
            if (current_st == WAIT_CHECK_ST) begin
                if (success | fail) begin
                    current_st <= DONE_ST;
                    enable_compare <= 0;
                end
            end
            if (current_st == DONE_ST) begin
            end
        end
    end

endmodule