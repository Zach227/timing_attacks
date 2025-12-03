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
    input clk, rst,
    input [2:0] btn,
    input restart,
    input [7:0] key,
    output success, fail
);

    // states: wait receive, wait check, done
    localparam WAIT_RECEIVE_ST = 2'b00;
    localparam WAIT_CHECK_ST = 2'b01;
    localparam DONE_ST = 2'b10;

    reg [1:0] current_st;
    reg [7:0] btn_vals;
    wire receive_done;
    reg internal_restart;

    wire internal_success;
    wire internal_fail;

    assign success = internal_success;
    assign fail = internal_fail;

    receive_buttons #(
        .CLK_FREQUENCY(500000000),
        .DEBOUNCE_DELAY_US(1_000))
    receive_buttons (
        .clk(clk),
        .reset(rst),
        .restart(internal_restart),
        .btns_in(btn),
        .done(receive_done),
        .btns_out(btn_vals) // size 4 array of 2 bit values 
    );

    compare compare(
        .clk(clk),
        .rst(rst),
        .enable(),
        .correct_value(key),
        .guessed_value(btn_vals),
        .success(success),
        .fail(fail)
    );

    always @(posedge clk) begin
        if (rst) begin
            current_st <= WAIT_RECEIVE_ST;
            internal_restart <= 0;
        end
        else begin
            if (current_st == WAIT_RECEIVE_ST) begin
                internal_restart <= 0;
                if (receive_done) begin
                    current_st <= WAIT_CHECK_ST;
                end
            end
            if (current_st == WAIT_CHECK_ST) begin
                if (success) begin
                    current_st <= DONE_ST;
                end
                else if (fail) begin
                    current_st <= WAIT_RECEIVE_ST;
                    internal_restart <= 1;
                end
            end
            if (current_st == DONE_ST) begin
                if (restart) begin
                    current_st <= WAIT_RECEIVE_ST;
                    internal_restart <= 1;
                end

            end
            
        end

    end


endmodule