
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
        COMPARE_DELAY,
        SET_CORRECT_GUESS,
        RESET_FOR_NEXT_BYTE
    } state_t;

    state_t current_state, next_state;

    // Instantiate send_guess module
    logic [7:0] guess_word [CODE_LEN-1:0];
    logic waiting_for_reply;
    logic begin_transaction;
    logic [7:0] data_from_mcu;
    logic correct_flag;

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
        .data_from_mcu(data_from_mcu),
        .correct_flag(correct_flag)
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
    logic [23:0] delay_counter;
    logic reset_delay_counter;
    logic inc_delay_counter;

    always_ff @(posedge CLK_50) begin
        if (SW[0])
            delay_counter <= 24'd0;
        else begin
            if (reset_delay_counter)
                delay_counter <= 24'd0;
            else if (inc_delay_counter)
                delay_counter <= delay_counter + 1'b1;
        end
    end

    // Delay comparison
    logic [23:0] max_delay;
    logic [7:0] max_byte_guess;
    logic compare_delay;
    logic reset_max;

    always_ff @(posedge CLK_50) begin
        if (SW[0]) begin
            max_delay <= '0;
            max_byte_guess <= 8'h00;
        end else if (reset_max) begin
            max_delay <= '0;
            max_byte_guess <= 8'h00;
        end else if (compare_delay) begin
            if (delay_counter > max_delay) begin
                max_delay <= delay_counter;
                max_byte_guess <= guess_byte;
            end
        end
    end


    // Correct code bytes
    logic [7:0] correct_bytes [CODE_LEN-1:0];
    logic set_correct;

    // Set correct bytes
    logic [BYTE_COUNT_WIDTH:0] correct_bytes_i;
    always_ff @(posedge CLK_50) begin
        if (SW[0]) begin
            for (correct_bytes_i = 0; correct_bytes_i < CODE_LEN; correct_bytes_i++)
                correct_bytes[correct_bytes_i] = START_GUESS_RANGE;
        end
        else if (set_correct) begin
            correct_bytes[byte_counter] <= max_byte_guess;
        end
    end

    // Set guess_word
    logic [BYTE_COUNT_WIDTH:0] guess_word_i;
    always_comb begin
        if (SW[0]) begin
            for (guess_word_i = 0; guess_word_i < CODE_LEN; guess_word_i++)
                guess_word[guess_word_i] = START_GUESS_RANGE;
        end
        else begin
            for (guess_word_i = 0; guess_word_i < CODE_LEN; guess_word_i++) begin
                if (guess_word_i == byte_counter)
                    guess_word[guess_word_i] = guess_byte;
                else
                    guess_word[guess_word_i] = correct_bytes[guess_word_i];
            end
        end
    end

    // State Machine transition logic and outputs
    always_comb begin
        // Default assignments
        begin_transaction   = 1'b0;
        reset_delay_counter = 1'b0;
        inc_delay_counter   = 1'b0;
        compare_delay       = 1'b0;
        reset_max           = 1'b0;
        inc_guess_byte      = 1'b0;
        reset_guess_byte    = 1'b0;
        inc_byte_counter    = 1'b0;
        set_correct         = 1'b0;


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
                    next_state = COMPARE_DELAY;
            end

            COMPARE_DELAY: begin
                // outputs
                compare_delay = 1'b1;

                // transition logic
                if (guess_byte == 8'hFF) begin
                    next_state = SET_CORRECT_GUESS;
                end else begin
                    inc_guess_byte = 1'b1;
                    next_state = SEND_GUESS;
                end
            end

            SET_CORRECT_GUESS: begin
                // outputs
                set_correct = 1'b1;

                // transition logic
                if (correct_flag)
                    next_state = IDLE;
                else
                    next_state = RESET_FOR_NEXT_BYTE;
            end

            RESET_FOR_NEXT_BYTE: begin
                // outputs
                reset_guess_byte = 1'b1;
                inc_byte_counter = 1'b1;
                reset_max = 1'b1;

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