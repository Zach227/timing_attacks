
module top(CLK_50, CLK_inter, SW, CM, LED);
    input CLK_50;
    input CLK_inter;
    input [0:0] SW;
    inout [7:0] CM;
	output [7:0] LED;


    // Protocol Bytes
    localparam START_BYTE      = 8'h01;
    localparam BEGIN_GUESSING  = 8'h02;
    localparam YES             = 8'h03;
    localparam NO              = 8'h04;
    localparam END_BYTE        = 8'h05;

    // FSM States
    localparam IDLE        = 3'b000;
    localparam SEND_START  = 3'b001;
    localparam SEND_DATA   = 3'b010;
    localparam SEND_END    = 3'b011;
    localparam WAIT_REPLY  = 3'b100;
    localparam DONE        = 3'b101;

    // State Machine Variables
    reg [1:0] current_state, next_state;
    reg [7:0] data_out;
    wire [7:0] data_in;
    wire drive_en;

    // State Transition Logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (data_in == 8'hCC)
                    next_state = SEND;
                else
                    next_state = IDLE;
            end
            SEND: begin
                next_state = WAIT_REPLY;
            end
            WAIT_REPLY: begin
                if (data_in == 8'hA5)
                    next_state = DONE;
                else if (data_in == 8'h5A)
                    next_state = SEND;
                else
                    next_state = WAIT_REPLY;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // State Machine Outputs
    assign drive_en = (current_state == SEND);
    assign LED = (current_state == DONE) ? data_out : 8'h00;

    // State Register and Data counter
    always @(posedge CLK_50) begin
        if (SW[0]) begin
            data_out <= 8'h00;
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;

            if (current_state == SEND)
                data_out <= data_out + 1;
        end
    end

    // Instantiate the cm_bus_if module
    cm_bus_if cmb_0(.clk(CLK_inter), .rst(SW[0]), .data_out(data_out), .drive_en(drive_en), .data_in(data_in), .cm(CM));

endmodule