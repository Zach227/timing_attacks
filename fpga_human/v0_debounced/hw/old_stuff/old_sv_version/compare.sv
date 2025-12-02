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
    input logic clk, rst, enable, restart,
    input logic [7:0] correct_value,
    input logic [7:0] guessed_value,
    output logic success, fail
);

    localparam WAIT_ST = 2'b00;
    localparam COMPARE_ST = 2'b01;
    localparam DONE_ST = 2'b10;

    logic [1:0] current_st;
    logic [3:0] current_index;

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
                if (current_index == 8) begin
                    current_st <= DONE_ST;
                    success <= 1;
                end
                else begin
                    if ((correct_value[current_index+1] == guessed_value[current_index+1]) && (correct_value[current_index] == guessed_value[current_index])) begin
                        current_index <= current_index + 2;
                    end
                    else begin
                        current_st <= DONE_ST;
                        fail <= 1;
                    end
                end
            end
            else if (current_st == DONE_ST) begin
                if (~enable || restart) begin
                    current_st <= WAIT_ST;
                    success <= 0;
                    fail <= 0;
                end
            end
        end

    end

endmodule
