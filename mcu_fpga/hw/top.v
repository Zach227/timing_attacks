
module top(CLK_50, CLK_inter, SW, CM, LED);
    input CLK_50;
    input CLK_inter;
    input [0:0] SW;
    inout [7:0] CM;
	output [7:0] LED;


    //-----------------------------------------
    // Protocol Bytes
    //-----------------------------------------
    localparam START_BYTE      = 8'h01;
    localparam BEGIN_GUESSING  = 8'h02;
    localparam YES             = 8'h03;
    localparam NO              = 8'h04;
    localparam END_BYTE        = 8'h05;

    //-----------------------------------------
    // FSM States
    //-----------------------------------------
    localparam IDLE              = 4'h0;
    localparam WAIT_BEFORE_START = 4'h1;
    localparam SEND_START        = 4'h2;
    localparam SEND_DATA         = 4'h4;
    localparam SEND_END          = 4'h6;
    localparam WAIT_REPLY        = 4'h8;

    //-----------------------------------------
    // Registers
    //-----------------------------------------
    reg [3:0] current_state, next_state;
    reg [7:0] data_out;
    reg drive_en;
    reg [7:0] guess_byte = 8'h05;

    //-----------------------------------------
    // Wires
    //-----------------------------------------
    wire [7:0] data_in;


    //-----------------------------------------
    // Guess counter
    //-----------------------------------------
    always @(posedge CLK_50) begin
        if (SW[0]) begin
            guess_byte <= 8'h05;
        end 
        else if (current_state == WAIT_REPLY && data_in == NO) begin
            guess_byte <= (guess_byte == 8'hFF) ? 8'h05 : guess_byte + 1;
        end
    end

    //-----------------------------------------
    // Detect rising+falling edge of CLK_inter
    //-----------------------------------------
    reg clk_inter_d;
    always @(posedge CLK_50) begin
        clk_inter_d <= CLK_inter;
    end

    wire clk_rise = (CLK_inter & ~clk_inter_d);
    wire clk_fall = (~CLK_inter & clk_inter_d);

    reg saw_rise;
    wire full_pulse = saw_rise && clk_fall;

    always @(posedge CLK_50) begin
        if (SW[0]) begin
            saw_rise <= 0;
        end 
        else begin
            if (clk_rise)
                saw_rise <= 1;
            if (clk_fall)
                saw_rise <= 0;  // reset after pulse complete
        end
    end

    //-----------------------------------------
    // State Transition Logic
    //-----------------------------------------
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (data_in == BEGIN_GUESSING)
                    next_state = WAIT_BEFORE_START;
                else
                    next_state = IDLE;
            end
            WAIT_BEFORE_START: begin
                if (full_pulse)
                    next_state = SEND_START;
            end
            SEND_START: begin
                if (full_pulse)
                    next_state = SEND_DATA;
            end
            SEND_DATA: begin
                if (full_pulse)
                    next_state = SEND_END;
            end
            SEND_END: begin
                if (full_pulse)
                    next_state = WAIT_REPLY;
            end
            WAIT_REPLY: begin
                if (data_in == YES)
                    next_state = IDLE;
                else if (data_in == NO)
                    next_state = WAIT_BEFORE_START;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    

    //-----------------------------------------
    // Output Logic
    //-----------------------------------------
    assign drive_en = (current_state == SEND_START || current_state == SEND_DATA || current_state == SEND_END);
    assign data_out = (current_state == SEND_START) ? START_BYTE :
                      (current_state == SEND_DATA) ? guess_byte :
                      (current_state == SEND_END) ? END_BYTE : 8'bZZ; 

    assign LED = guess_byte;

    //-----------------------------------------
    // State Register
    //-----------------------------------------
    always @(posedge CLK_50) begin
        if (SW[0]) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Instantiate the cm_bus_if module
    cm_bus_if cmb_0(.clk(CLK_inter), .rst(SW[0]), .data_out(data_out), .drive_en(drive_en), .data_in(data_in), .cm(CM));

endmodule