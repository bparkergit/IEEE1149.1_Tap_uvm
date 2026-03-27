module tap_controller #(
    parameter IR_WIDTH = 4,
    parameter DR_WIDTH = 32,
    parameter IDCODE   = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO,
    output logic [IR_WIDTH-1:0] ir_out,
    output logic [DR_WIDTH-1:0] dr_out
);

    // TAP states
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET, RUN_TEST_IDLE, SELECT_DR_SCAN,
        CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
        SELECT_IR_SCAN, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
    } tap_state_t;

    tap_state_t state, next_state;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST) state <= TEST_LOGIC_RESET;
        else state <= next_state;
    end

    // Next state logic
    always_comb begin
        next_state = state;
        case(state)
            TEST_LOGIC_RESET: next_state = TMS ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    next_state = TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   next_state = TMS ? SELECT_IR_SCAN : CAPTURE_DR;
            CAPTURE_DR:       next_state = TMS ? EXIT1_DR : SHIFT_DR;
            SHIFT_DR:         next_state = TMS ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR:         next_state = TMS ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR:         next_state = TMS ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR:         next_state = TMS ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR:        next_state = TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   next_state = TMS ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       next_state = TMS ? EXIT1_IR : SHIFT_IR;
            SHIFT_IR:         next_state = TMS ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR:         next_state = TMS ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR:         next_state = TMS ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR:         next_state = TMS ? UPDATE_IR : SHIFT_IR;
            UPDATE_IR:        next_state = TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            default:          next_state = TEST_LOGIC_RESET;
        endcase
    end

    // IR register
    logic [IR_WIDTH-1:0] ir;
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST) ir <= '0;
        else if (state == CAPTURE_IR) ir <= 4'b0010; // USER_DR
        else if (state == SHIFT_IR) ir <= {TDI, ir[IR_WIDTH-1:1]};
    end
    assign ir_out = ir;

    // DR register
    logic [DR_WIDTH-1:0] dr_shift, bypass;
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST) begin
            dr_shift <= '0;
            bypass   <= '0;
        end else begin
            if (state == CAPTURE_DR) dr_shift <= '0;
            if (state == SHIFT_DR) begin
                if (ir == 4'b0010) dr_shift <= {TDI, dr_shift[DR_WIDTH-1:1]};
                else bypass <= {TDI, bypass[DR_WIDTH-1:1]};
            end
        end
    end
    assign dr_out = dr_shift;

    // TDO
    assign TDO = (ir == 4'b0010) ? dr_shift[0] : bypass[0];

endmodule
