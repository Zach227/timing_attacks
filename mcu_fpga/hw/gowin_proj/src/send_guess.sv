
module send_guess #(
    parameter int CODE_LEN = 2
) (
    input  wire logic CLK_50,
    input  wire logic CLK_inter,   // MCU-driven interconnect clock
    input  wire logic [9:0]  SW,          // active-high reset
    inout  logic [7:0]  CM,          // bidirectional bus
    input  logic [7:0] guess [CODE_LEN-1:0],
    input  logic begin_transaction,
    output logic waiting_for_reply,
    output logic [7:0] data_from_mcu,
    output logic correct_flag
);

    // Protocol bytes
    localparam [7:0] START_BYTE         = 8'h01;
    localparam [7:0] BEGIN_GUESSING     = 8'h02;
    localparam [7:0] YES                = 8'h03;
    localparam [7:0] NO                 = 8'h04;
    localparam [7:0] END_BYTE           = 8'h05;
    localparam [7:0] START_GUESS_RANGE  = 8'h06;

    // FSM states
    typedef enum logic [3:0] {
        IDLE,
        WAIT_BEFORE_START,
        SEND_START,
        SEND_DATA,
        SEND_END,
        SHORT_DELAY,
        WAIT_REPLY,
        CORRECT
    } state_t;

    state_t current_state, next_state;

    // CM data drive signals
    logic  [7:0] data_out;
    logic        drive_en;
    logic [7:0] data_in;

    // CM bus output
    assign CM = drive_en ? data_out : 8'bZ;

    // CM bus input Sychronizer
    reg [7:0] data_in_sync0, data_in_sync1;
    assign data_in = CM;

    always_ff @(posedge CLK_50) begin
        data_in_sync0 <= data_in;
        data_in_sync1 <= data_in_sync0;
    end

    assign data_from_mcu = data_in_sync1;

    // detect edges of clk_inter (synchronized into CLK_50 domain)
    logic clk_inter_sync0, clk_inter_sync1;
    logic clk_inter_rise, clk_inter_fall;
    always_ff @(posedge CLK_50) begin
        clk_inter_sync0 <= CLK_inter;
        clk_inter_sync1 <= clk_inter_sync0;
    end
    assign clk_inter_rise =  clk_inter_sync0 & ~clk_inter_sync1;
    assign clk_inter_fall = ~clk_inter_sync0 &  clk_inter_sync1;


    // byte counter for sending CODE_LEN bytes
    localparam int BYTE_COUNT_WIDTH = (CODE_LEN > 1) ? $clog2(CODE_LEN) : 1;
    logic [BYTE_COUNT_WIDTH-1:0] byte_count;
    always_ff @(posedge CLK_50) begin
        if (SW[9])
            byte_count <= '0;
        else begin
            if (current_state != SEND_DATA)
                byte_count <= '0;
            else if (current_state == SEND_DATA && clk_inter_fall)
                byte_count <= byte_count + 1'b1;
        end
    end


    // Next-state logic
    always_comb begin
        next_state = current_state; // default to hold
        case (current_state)
            IDLE: begin
                if (begin_transaction)
                    next_state = WAIT_BEFORE_START;
            end

            WAIT_BEFORE_START: begin
                if (clk_inter_fall) 
                    next_state = SEND_START;
            end

            SEND_START: begin
                // hold START for one pulse then move to SEND_DATA
                if (clk_inter_fall)
                    next_state = SEND_DATA;
            end

            SEND_DATA: begin
                if (clk_inter_fall) begin
                    if (byte_count == CODE_LEN-1)
                        next_state = SEND_END;
                    else
                        next_state = SEND_DATA;
                end
            end
           
            SEND_END: begin
                if (clk_inter_fall)
                    next_state = SHORT_DELAY;
            end

            SHORT_DELAY: begin
                    next_state = WAIT_REPLY;
            end

            WAIT_REPLY: begin
                if (data_in_sync1 == YES) begin
                    next_state = CORRECT;
                end
                else if (data_in_sync1 == NO) begin
                    next_state = IDLE;
                end
            end

            CORRECT: begin
                next_state = CORRECT;
            end

            default: next_state = IDLE;
        endcase
    end

    // Moore outputs
    always @(*) begin
        drive_en = 1'b0;
        data_out = 8'h00;
        waiting_for_reply = 1'b0;
        correct_flag = 1'b0;

        case (current_state)
            SEND_START: begin
                drive_en = 1'b1;
                data_out = START_BYTE;
            end
            SEND_DATA: begin
                drive_en = 1;
                data_out = guess[byte_count];
            end
            SEND_END: begin
                drive_en = 1;
                data_out = END_BYTE;
            end
            WAIT_REPLY: begin
                waiting_for_reply = 1'b1;
            end
            CORRECT: begin
                correct_flag = 1'b1;
            end
        endcase
    end


    // State register
    always @(posedge CLK_50) begin
        if (SW[9])
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

   

endmodule