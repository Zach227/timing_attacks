// top.v -- clean FSM + handshake
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
        SEND_DATA         = 4'h4,
        SEND_END          = 4'h6,
        WAIT_REPLY        = 4'h8;

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
            if (current_state == WAIT_REPLY && data_in == NO) begin
                if (guess_byte == 8'hFF)
                    guess_byte <= START_GUESS_RANGE;
                else
                    guess_byte <= guess_byte + 1;
            end
        end
    end

    // ----------------------------------------
    // Detect full MCU clock pulse (rising then falling)
    // sample clk edges using CLK_50 domain
    // ----------------------------------------
    reg clk_inter_d;
    always @(posedge CLK_50) clk_inter_d <= CLK_inter;

    wire clk_rise = CLK_inter & ~clk_inter_d;
    wire clk_fall = ~CLK_inter & clk_inter_d;

    // saw_rise indicates we've seen a rising edge and are waiting for the falling edge
    reg saw_rise;
    wire full_pulse = saw_rise && clk_fall;

    always @(posedge CLK_50) begin
        if (SW[0]) begin
            saw_rise <= 1'b0;
        end else begin
            if (clk_rise)
                saw_rise <= 1'b1;
            if (clk_fall)
                saw_rise <= 1'b0; // clear after falling -> completes full pulse
        end
    end

    // ----------------------------------------
    // Next-state (combinational)
    // ----------------------------------------
    always @(*) begin
        next_state = current_state; // default to hold
        case (current_state)
            IDLE: begin
                if (data_in == BEGIN_GUESSING)
                    next_state = WAIT_BEFORE_START;
                else
                    next_state = IDLE;
            end

            WAIT_BEFORE_START: begin
                // Wait for MCU to provide one pulse (used to pace start)
                if (full_pulse)
                    next_state = SEND_START;
                else
                    next_state = WAIT_BEFORE_START;
            end

            SEND_START: begin
                // hold START for one pulse then move to SEND_DATA
                if (full_pulse)
                    next_state = SEND_DATA;
                else
                    next_state = SEND_START;
            end

            SEND_DATA: begin
                if (full_pulse)
                    next_state = SEND_END;
                else
                    next_state = SEND_DATA;
            end

            SEND_END: begin
                if (full_pulse)
                    next_state = WAIT_REPLY;
                else
                    next_state = SEND_END;
            end

            WAIT_REPLY: begin
                if (data_in == YES)
                    next_state = IDLE;               // success, restart
                else if (data_in == NO)
                    next_state = WAIT_BEFORE_START;  // try next guess
                else
                    next_state = WAIT_REPLY;         // keep waiting
            end

            default: next_state = IDLE;
        endcase
    end

    // ----------------------------------------
    // Output logic (combinational)
    // drive_en and data_out MUST hold stable for the whole SEND_* state
    // ----------------------------------------
    always @(*) begin
        // defaults
        drive_en = 1'b0;
        data_out = 8'h00;

        case (current_state)
            SEND_START: begin
                drive_en = 1'b1;
                data_out = START_BYTE;
            end

            SEND_DATA: begin
                drive_en = 1'b1;
                data_out = guess_byte;
            end

            SEND_END: begin
                drive_en = 1'b1;
                data_out = END_BYTE;
            end

            default: begin
                drive_en = 1'b0;   // listen
                data_out = 8'h00;  // value ignored when not driving
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
        .clk(CLK_inter),
        .rst(SW[0]),
        .data_out(data_out),
        .drive_en(drive_en),
        .data_in(data_in),
        .cm(CM)
    );

endmodule


// ------------------------------------------------------------------
// cm_bus_if: tri-state bus interface used by top
// - data_out is sampled/registered on rising edge of CLK_inter to
//   give stable outputs synchronized with MCU clock
// - when drive_en==1 the FPGA drives the bus; otherwise bus is Z
// - data_in reads the bus (unsigned 8-bit)
// ------------------------------------------------------------------
module cm_bus_if (
    input  wire       clk,       // MCU clock line
    input  wire       rst,
    input  wire [7:0] data_out,  // value to drive when drive_en=1
    input  wire       drive_en,
    output wire [7:0] data_in,
    inout  wire [7:0] cm
);
    // register outgoing data synchronized to clk (helps setup/hold)
    reg [7:0] out_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            out_reg <= 8'h00;
        else
            out_reg <= data_out;
    end

    // tri-state driver: cm driven only when drive_en is asserted
    assign cm = drive_en ? out_reg : 8'bZZ;

    // sample bus asynchronously into FPGA domain via simple assign
    // (top synchronizes usage of data_in using full_pulse and CLK_50 domain)
    assign data_in = cm;

endmodule
