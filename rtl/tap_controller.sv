module tap_controller #(
    parameter IR_WIDTH = 4,
    parameter IDCODE   = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO,

    // IR output (for debug / decode)
    output logic [IR_WIDTH-1:0] ir_out,

    // DR control signals (to IJTAG / BISR)
    output logic shift_dr,
    output logic capture_dr,
    output logic update_dr,

    // External DR interface (IJTAG chain)
    output logic tdi_dr,
    input  logic tdo_dr
);

    // ============================================================
    // TAP FSM
    // ============================================================
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET, RUN_TEST_IDLE, SELECT_DR_SCAN,
        CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
        SELECT_IR_SCAN, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
    } tap_state_t;

    tap_state_t state, next_state;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

    // Next-state logic
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

    // ============================================================
    // DR CONTROL SIGNALS (EXPORTED)
    // ============================================================
    assign shift_dr   = (state == SHIFT_DR);
    assign capture_dr = (state == CAPTURE_DR);
    assign update_dr  = (state == UPDATE_DR);

    // ============================================================
    // IR REGISTER
    // ============================================================
    logic [IR_WIDTH-1:0] ir;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            ir <= '0;
        else if (state == CAPTURE_IR)
            ir <= 4'b0010;  // USER_DR default pattern
        else if (state == SHIFT_IR)
            ir <= {TDI, ir[IR_WIDTH-1:1]};
    end

    assign ir_out = ir;

    // ============================================================
    // BYPASS REGISTER (1-bit in real JTAG, kept simple here)
    // ============================================================
    logic bypass_reg;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            bypass_reg <= 1'b0;
        else if (state == CAPTURE_DR)
            bypass_reg <= 1'b0;
        else if (state == SHIFT_DR && ir != 4'b0010)
            bypass_reg <= TDI;
    end

    // ============================================================
    // DR PATH ROUTING
    // ============================================================

    // Always drive TDI into external DR chain
    assign tdi_dr = TDI;

    // TDO mux:
    // USER_DR → external IJTAG chain
    // otherwise → bypass
    always_comb begin
        case (ir)
            4'b0010: TDO = tdo_dr;     // USER_DR
            default: TDO = bypass_reg; // BYPASS
        endcase
    end

endmodule
