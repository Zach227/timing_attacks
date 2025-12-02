//////////////////////////////////////////////////////////////////////////////////
// Module: compare
// Author: Jacob Brown
// Date: 11/19/2025
// Description:
//   When enable goes high, compare the 8 bit values 2 bits at a time. Exit with failure
//   as soon as a mismatch is found. Otherwise raise success. Hold success/fail high until
//   restart is asserted.
//////////////////////////////////////////////////////////////////////////////////

module compare(
    input logic clk, rst, enable, //restart,
    input logic [7:0] correct_value,
    input logic [7:0] guessed_value,
    output logic success, fail,
    output logic [3:0] multi_debug_out
);

    localparam WAIT_ST = 2'b00;
    localparam COMPARE_ST = 2'b01;
    localparam DONE_ST = 2'b10;

    logic [1:0] current_st;
    logic [3:0] current_index;

    assign multi_debug_out = current_index;

    logic compare0_0, compare0_1, compare1_0, compare1_1;
    logic match;
    assign compare0_0 = correct_value[current_index];
    assign compare0_1 = correct_value[current_index+1];
    assign compare1_0 = guessed_value[current_index];
    assign compare1_1 = guessed_value[current_index+1];
    assign match = (compare0_0 == compare1_0) && (compare0_1 == compare1_1);

    always_ff @(posedge clk) begin
        if (rst) begin
            current_st <= WAIT_ST;
            current_index <= 0;
            success <= 0;
            fail <= 0;
        end
        else begin
            if (current_st == WAIT_ST) begin
                if (enable) begin
                    current_st <= COMPARE_ST;
                end
            end
            else if (current_st == COMPARE_ST) begin
                if (match) begin
                    if (current_index == 6) begin
                        current_st <= DONE_ST;
                        success <= 1;
                    end
                    else begin
                        current_index <= current_index + 2;
                    end
                end
                else begin
                    current_st <= DONE_ST;
                    fail <= 1;
                end
            end
            else if (current_st == DONE_ST) begin
            end
        end

    end

endmodule
