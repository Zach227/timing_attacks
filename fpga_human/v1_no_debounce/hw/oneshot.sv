/////////////////////////////////////////////////////////////
// Module: oneshot
// Name: Jacob Brown
// Class: ECEN 520
// Date: 9/13/2024
// Description: Oneshot detector. Detects a rising edge and outputs a pulse
// 		one clock cycle long.
/////////////////////////////////////////////////////////////

module oneshot (
    input wire logic clk, rst, in,
    output logic out
);

    logic in_before;

    // watch for when the in signal has a rising edge and pulse an output
    always_ff @(posedge clk) begin
        if (rst) begin
            in_before <= 1'b0;
            out <= 1'b0;
        end
        else begin
            in_before <= in;
            if ((!in_before) && in)
                out <= 1'b1;
            else
                out <= 1'b0;
        end
    end

endmodule
