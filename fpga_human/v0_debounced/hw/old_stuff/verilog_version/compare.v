//////////////////////////////////////////////////////////////////////////////////
// Module: compare
// Author: Jacob Brown
// Date: 11/19/2025
// Description:
//   When enable goes high, compare the 8 bit values 2 bits at a time. Exit with failure
//   as soon as a mismatch is found. Otherwise raise success. Hold success/fail high until
//   enable is deasserted and reasserted again (signal to compare again).
//////////////////////////////////////////////////////////////////////////////////

module compare(
    input clk, rst, enable,
    input [7:0] correct_value,
    input [7:0] guessed_value,
    output success, fail
);


    localparam WAIT_ST = 2'b00;
    localparam COMPARE_ST = 2'b01;
    localparam DONE_ST = 2'b10;

    reg [1:0] current_st;
    reg [3:0] current_index;
    reg success_internal;
    reg fail_internal;

    assign success = success_internal;
    assign fail = fail_internal;

    always @(posedge clk) begin
        if (rst) begin
            current_st <= WAIT_ST;
            current_index <= 0;
            success_internal <= 0;
            fail_internal <= 0;
        end
        else begin
            if (current_st == WAIT_ST) begin
                if (enable) begin
                    current_st <= COMPARE_ST;
                    success_internal <= 0;
                    fail_internal <= 0;
                end
            end
            else if (current_st == COMPARE_ST) begin
                if (current_index == 8) begin
                    current_st <= DONE_ST;
                    success_internal <= 1;
                end
                else begin
                    // if (correct_value[current_index+1:current_index] == guessed_value[current_index+1:current_index]) begin
                    if ((correct_value[current_index+1] == guessed_value[current_index+1]) && (correct_value[current_index] == guessed_value[current_index])) begin
                        current_index <= current_index + 2;
                    end
                    else begin
                        current_st <= DONE_ST;
                        fail_internal <= 1;
                    end
                end
            end
            else if (current_st == DONE_ST) begin
                if (~enable) begin
                    current_st <= WAIT_ST;
                end
            end
        end

    end

endmodule
