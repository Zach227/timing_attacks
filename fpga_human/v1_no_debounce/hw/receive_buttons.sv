//////////////////////////////////////////////////////////////////////////////////
// Module: receive_buttons
// Author: Jacob Brown
// Date: 11/19/2025
// Description:
//   Receive 4 buttons presses and indicate when they have been received.
//////////////////////////////////////////////////////////////////////////////////

module receive_buttons (
    input logic clk, reset,
    input logic [2:0] btns_in,
    output logic done,
    output logic oneshotted_or,
    output logic [7:0] btns_out // four 2 bit values 
);

    logic [2:0] btn_presses;
    logic [3:0] index;
    logic [2:0] btns_oneshot;

    assign oneshotted_or = btns_oneshot[0] | btns_oneshot[1] | btns_oneshot[2];

    // oneshot the debounced buttons
    oneshot oneshot_0 (.clk, .rst(reset), .in(btns_in[0]), .out(btns_oneshot[0]));
    oneshot oneshot_1 (.clk, .rst(reset), .in(btns_in[1]), .out(btns_oneshot[1]));
    oneshot oneshot_2 (.clk, .rst(reset), .in(btns_in[2]), .out(btns_oneshot[2]));
    
    // watch for button presses and register them in btns_out
    always_ff @(posedge clk) begin
        if (reset) begin
            btn_presses <= 0;
            done <= 0;
            btns_out <= 0;
            index <= 0;
        end
        else begin
            if (btn_presses < 4) begin
                if (btns_oneshot[0]) begin
                    btns_out[index] <= 1'b0;
                    btns_out[index+1] <= 1'b0;
                    btn_presses <= btn_presses + 1;
                    index <= index + 2;
                end
                else if (btns_oneshot[1]) begin
                    btns_out[index] <= 1'b1;
                    btns_out[index+1] <= 1'b0;
                    btn_presses <= btn_presses + 1;
                    index <= index + 2;
                end
                else if (btns_oneshot[2]) begin
                    btns_out[index] <= 1'b0;
                    btns_out[index+1] <= 1'b1;
                    btn_presses <= btn_presses + 1;
                    index <= index + 2;
                end
            end
            else begin
                done <= 1;
            end
        end
    end

endmodule