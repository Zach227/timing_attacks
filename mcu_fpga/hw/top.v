
module top(
    input  wire        CLK_50,
    input  wire        CLK_inter,   // MCU-driven interconnect clock
    input  wire [0:0]  SW,          // active-high reset
    inout  wire [7:0]  CM,          // bidirectional bus
    output wire [7:0]  LED
);

    // ----------------------------------------
    // Protocol bytes
    // ----------------------------------------
    localparam [7:0] START_BYTE         = 8'h01;
    localparam [7:0] BEGIN_GUESSING     = 8'h02;
    localparam [7:0] YES                = 8'h03;
    localparam [7:0] NO                 = 8'h04;
    localparam [7:0] END_BYTE           = 8'h05;
    localparam [7:0] START_GUESS_RANGE  = 8'h06;

    // ----------------------------------------
    // FSM states (4-bit)
    // ----------------------------------------
    localparam [3:0]
        IDLE              = 4'h0,
        WAIT_BEFORE_START = 4'h1,
        SEND_START        = 4'h2,
        SEND_DATA         = 4'h3,
        SEND_END          = 4'h4,
        SHORT_DELAY       = 4'h5,
        WAIT_REPLY        = 4'h6;

    // ----------------------------------------
    // Registers / wires
    // ----------------------------------------
    reg  [3:0] current_state, next_state;
    reg  [7:0] data_out;
    reg        drive_en;
    reg  [7:0] guess_byte;

    wire [7:0] data_in;

    // Show current guess on LEDs for debug
    assign LED = guess_byte;

    // ----------------------------------------
    // Guess counter: initialize and increment only on MCU NO reply
    // ----------------------------------------
    always @(posedge CLK_50) begin
        if (SW[0]) begin
            guess_byte <= START_GUESS_RANGE; // start at 0x05 per your design
        end else begin
            // increment only when we are in WAIT_REPLY and MCU replied NO
            if (current_state == SHORT_DELAY) begin
                if (guess_byte == 8'hFF)
                    guess_byte <= START_GUESS_RANGE;
                else
                    guess_byte <= guess_byte + 1'b1;
            end
        end
    end

    // ----------------------------------------
    // Detect full MCU clock pulse (rising then falling)
    // sample clk edges using CLK_50 domain
    // ----------------------------------------
    reg clk_inter_sync0, clk_inter_sync1;

    always @(posedge CLK_50) begin
        clk_inter_sync0 <= CLK_inter;
        clk_inter_sync1 <= clk_inter_sync0;
    end

    wire clk_inter_rise =  clk_inter_sync0 & ~clk_inter_sync1;
    wire clk_inter_fall = ~clk_inter_sync0 &  clk_inter_sync1;

    // ----------------------------------------
    // Sychronizer for data in 
    // ----------------------------------------
    reg [7:0] data_in_sync0, data_in_sync1;

    always @(posedge CLK_50) begin
        data_in_sync0 <= data_in;        // raw bus sampled
        data_in_sync1 <= data_in_sync0; // stable copy for FSM
    end


    // ----------------------------------------
    // Next-state (combinational)
    // ----------------------------------------
    always @(*) begin
        next_state = current_state; // default to hold
        case (current_state)
            IDLE: begin
                if (data_in_sync0 == BEGIN_GUESSING)
                    next_state = WAIT_BEFORE_START;
                else 
                    next_state = IDLE;
            end

            WAIT_BEFORE_START: begin
                if (clk_inter_fall) 
                    next_state = SEND_START;
                else
                    next_state = WAIT_BEFORE_START;
            end

            SEND_START: begin
                // hold START for one pulse then move to SEND_DATA
                if (clk_inter_fall)
                    next_state = SEND_DATA;
                else
                    next_state = SEND_START;
            end

            SEND_DATA: begin
                if (clk_inter_fall)
                    next_state = SEND_END;
                else
                    next_state = SEND_DATA;
            end
           
            SEND_END: begin
                if (clk_inter_fall)
                    next_state = SHORT_DELAY;
                else
                    next_state = SEND_END;
            end

            SHORT_DELAY: begin
                    next_state = WAIT_REPLY;
            end

            WAIT_REPLY: begin
                if (data_in_sync0 == YES)
                    next_state = IDLE;
                else if (data_in_sync0 == NO)
                    next_state = WAIT_BEFORE_START;
                else 
                    next_state = WAIT_REPLY;
            end

            default: next_state = IDLE;
        endcase
    end

    // -------------------------------------------------------------
    // Output (Moore) logic for SEND states
    // -------------------------------------------------------------
    always @(*) begin
        drive_en = 1'b0;
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


    // ----------------------------------------
    // State register (synchronous)
    // ----------------------------------------
    always @(posedge CLK_50) begin
        if (SW[0])
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // ----------------------------------------
    // Instantiate bus interface
    // ----------------------------------------
    cm_bus_if cmb_0(
        .data_out(data_out),
        .drive_en(drive_en),
        .data_in(data_in),
        .cm(CM)
    );

endmodule

