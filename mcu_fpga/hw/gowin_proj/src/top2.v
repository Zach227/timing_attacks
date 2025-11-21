module top (
    input        CLK_50,
    input        CLK_inter,
    input  [0:0] SW,
    inout  [7:0] CM,
    output [7:0] LED
);

    //------------------------------------------------------------
    // Protocol Bytes
    //------------------------------------------------------------
    localparam START_BYTE      = 8'h01;
    localparam BEGIN_GUESSING  = 8'h02;
    localparam YES             = 8'h03;
    localparam NO              = 8'h04;
    localparam END_BYTE        = 8'h05;
    localparam START_GUESS_RANGE  = 8'h06;

    //------------------------------------------------------------
    // States
    //------------------------------------------------------------
    localparam IDLE              = 4'h0;
    localparam WAIT_BEFORE_START = 4'h1;
    localparam SEND_START        = 4'h2;
    localparam SEND_DATA         = 4'h3;
    localparam SEND_END          = 4'h4;
    localparam WAIT_REPLY        = 4'h5;

    reg [3:0] current_state, next_state;

    //------------------------------------------------------------
    // Guess byte
    //------------------------------------------------------------
    reg [7:0] guess_byte = START_GUESS_RANGE;

    // Increment guess after completing SEND_END → WAIT_REPLY transition
    always @(posedge CLK_50) begin
        if (SW[0]) begin
            guess_byte <= START_GUESS_RANGE;
        end
        else if (current_state == SEND_END && next_state == WAIT_REPLY) begin
            guess_byte <= (guess_byte == 8'hFF) ? START_GUESS_RANGE : (guess_byte + 8'h01);
        end
    end

    //------------------------------------------------------------
    // Capture CM rising+falling edges to form a "full pulse"
    //------------------------------------------------------------
    reg clk_inter_d;

    always @(posedge CLK_50)
        clk_inter_d <= CLK_inter;

    wire clk_rise =  CLK_inter & ~clk_inter_d;
    wire clk_fall = ~CLK_inter &  clk_inter_d;

    reg saw_rise;
    wire full_pulse = saw_rise && clk_fall;

    always @(posedge CLK_50) begin
        if (SW[0]) begin
            saw_rise <= 0;
        end else begin
            if (clk_rise) saw_rise <= 1;
            if (clk_fall) saw_rise <= 0;
        end
    end

    //------------------------------------------------------------
    // Bidirectional Bus Interface
    //------------------------------------------------------------
    wire [7:0] data_in;
    reg  [7:0] data_out;
    reg        drive_en;

    cm_bus_if cmb_0(
        .clk      (CLK_inter),
        .rst      (SW[0]),
        .data_out (data_out),
        .drive_en (drive_en),
        .data_in  (data_in),
        .cm       (CM)
    );

    //------------------------------------------------------------
    // Next State Logic
    //------------------------------------------------------------
    always @(*) begin
        next_state = current_state;
        case (current_state)

            IDLE: begin
                if (data_in == BEGIN_GUESSING)
                    next_state = WAIT_BEFORE_START;
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

        endcase
    end

    //------------------------------------------------------------
    // Output Logic for Bus Driving
    //------------------------------------------------------------
    always @(*) begin
        // Default
        drive_en = 0;
        data_out = 8'h00;

        case (current_state)
            SEND_START: begin
                drive_en = 1;
                data_out = START_BYTE;
            end
            SEND_DATA: begin
                drive_en = 1;
                data_out = guess_byte;
            end
            SEND_END: begin
                drive_en = 1;
                data_out = END_BYTE;
            end
        endcase
    end

    //------------------------------------------------------------
    // State Register
    //------------------------------------------------------------
    always @(posedge CLK_50) begin
        if (SW[0])
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    assign LED = SW[0] ? 8'h00 : guess_byte;

endmodule
