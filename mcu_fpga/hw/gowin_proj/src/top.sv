
module top (
    input  wire logic CLK_50,
    input  wire logic CLK_inter,   // MCU-driven interconnect clock
    input  wire logic [0:0]  SW,          // active-high reset
    inout  logic [7:0]  CM,          // bidirectional bus
    output logic [7:0] LED
);
    localparam CODE_LEN = 2;

    // Protocol bytes
    localparam [7:0] START_BYTE         = 8'h01;
    localparam [7:0] BEGIN_GUESSING     = 8'h02;
    localparam [7:0] YES                = 8'h03;
    localparam [7:0] NO                 = 8'h04;
    localparam [7:0] END_BYTE           = 8'h05;
    localparam [7:0] START_GUESS_RANGE  = 8'h06;

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        SEND_GUESS,
        COUNT_DELAY,
        STORE_DELAY,
        SET_CORRECT_GUESS,
        RESET_FOR_NEXT_BYTE
    } state_t;

    state_t current_state, next_state;

    // Instantiate send_guess module
    logic [7:0] guess_word [0:CODE_LEN-1]; // Should this be CODE_LEN-1:0 ??
    logic waiting_for_reply;
    logic begin_transaction;
    logic [7:0] data_from_mcu;

    send_guess #(
        .CODE_LEN(CODE_LEN)
    ) send_guess_inst (
        .CLK_50(CLK_50),
        .CLK_inter(CLK_inter),
        .SW(SW),
        .CM(CM),
        .guess(guess_word),
        .begin_transaction(begin_transaction),
        .waiting_for_reply(waiting_for_reply),
        .data_from_mcu(data_from_mcu)
    );

    // Guess byte increment logic
    logic [7:0] guess_byte;
    logic inc_guess_byte;
    logic inc_guess_byte_reg;
    logic reset_guess_byte;
    
    always_ff @(posedge CLK_50) begin
        if (SW[0]) begin
            guess_byte <= START_GUESS_RANGE;
        end else begin
            if (reset_guess_byte) begin
                guess_byte <= START_GUESS_RANGE;
            end else if (inc_guess_byte_reg) begin
                if (guess_byte == 8'hFF)
                    guess_byte <= START_GUESS_RANGE;
                else
                    guess_byte <= guess_byte + 1'b1;
            end
        end
    end

    // Inc register for Safety
    always_ff @(posedge CLK_50) begin
        inc_guess_byte_reg <= inc_guess_byte;
    end

    // Byte counter
    localparam int BYTE_COUNT_WIDTH = (CODE_LEN > 1) ? $clog2(CODE_LEN) : 1;
    logic [BYTE_COUNT_WIDTH-1:0] byte_counter;
    logic inc_byte_counter;

    always_ff @(posedge CLK_50) begin
        if (SW[0]) begin
            byte_counter <= 2'd0;
        end else if (inc_byte_counter) begin
            byte_counter <= byte_counter + 1'b1;
        end
    end

    // Delay Counter
    logic [31:0] delay_counter;
    logic reset_delay_counter;
    logic inc_delay_counter;

    always_ff @(posedge CLK_50) begin
        if (SW[0])
            delay_counter <= 32'd0;
        else begin
            if (reset_delay_counter)
                delay_counter <= 32'd0;
            else if (inc_delay_counter)
                delay_counter <= delay_counter + 1'b1;
        end
    end

    // Memory to store delays
    logic [31:0] delay_memory [0:255];
    logic store_byte;

    always_ff @(posedge CLK_50) begin
        if (store_byte) begin
            delay_memory[guess_byte] <= delay_counter;
        end
    end

    // Correct Bytes memory
    logic [7:0] correct_bytes [CODE_LEN-1:0];

    always_comb begin
        // Default guess_word copies correct_bytes
        for (int i = 0; i < CODE_LEN; i++)
            guess_word[i] = correct_bytes[i];

        // Replace current byte with guess_byte
        guess_word[byte_counter] = guess_byte;
    end

    // Process to search for the byte that had the longest delay time
    always_ff @(posedge CLK_50) begin
        if (SW[0]) begin
            for (int i = 0; i < CODE_LEN; i++) begin
                correct_bytes[i] <= 8'h00;
            end
        end
        else begin
            if (current_state == SET_CORRECT_GUESS) begin
                // find max
                integer i;
                logic [31:0] max_delay;
                logic [7:0]  max_byte;
                max_delay = 32'd0;
                max_byte  = 8'd0;
                for (i = 0; i < 256; i = i + 1) begin
                    if (delay_memory[i] > max_delay) begin
                        max_delay = delay_memory[i];
                        max_byte  = i[7:0];
                    end
                end
                correct_bytes[byte_counter] <= max_byte;
            end
        end
    end

    // State Machine transition logic and outputs
    always_comb begin
        // Default assignments
        begin_transaction = 1'b0;
        reset_delay_counter = 1'b0;
        inc_delay_counter = 1'b0;
        store_byte = 1'b0;
        inc_guess_byte      = 1'b0;
        reset_guess_byte    = 1'b0;
        inc_byte_counter    = 1'b0;
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (data_from_mcu == BEGIN_GUESSING) begin
                    next_state = SEND_GUESS;
                end else begin
                    next_state = IDLE;
                end
            end

            SEND_GUESS: begin
                // outputs
                begin_transaction = 1'b1;
                reset_delay_counter = 1'b1;

                // transition logic
                if (waiting_for_reply)
                    next_state = COUNT_DELAY;
            end

            COUNT_DELAY: begin
                // outputs
                inc_delay_counter = 1'b1;

                // transition logic
                if (!waiting_for_reply)
                    next_state = STORE_DELAY;
            end

            STORE_DELAY: begin
                // outputs
                store_byte = 1'b1;

                // transition logic
                if (guess_byte == 8'hFF) begin
                    next_state = SET_CORRECT_GUESS;
                end else begin
                    inc_guess_byte = 1'b1;
                    next_state = SEND_GUESS;
                end
            end

            SET_CORRECT_GUESS: begin

                // transition logic
                next_state = RESET_FOR_NEXT_BYTE;
            end

            RESET_FOR_NEXT_BYTE: begin
                // outputs
                reset_guess_byte = 1'b1;
                inc_byte_counter = 1'b1;

                // transition logic
                if (byte_counter == CODE_LEN-1)
                    next_state = IDLE;
                else
                    next_state = SEND_GUESS;
            end

            default: next_state = IDLE;
        endcase
    end

    // State register
    always_ff @(posedge CLK_50) begin
        if (SW[0])
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // LED output for debugging
    assign LED = guess_byte;

endmodule