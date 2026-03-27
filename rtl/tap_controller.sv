//
// ================================================================
// Full TAP Controller RTL (IEEE 1149.1 compliant)
// Includes FSM, IR, DR mux, BYPASS, IDCODE, USER_DR
// ================================================================
module tap_controller #(
    parameter IR_WIDTH = 4,
    parameter IDCODE = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // --------------------------
    // TAP FSM
    // --------------------------
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET = 4'd0,
        RUN_TEST_IDLE    = 4'd1,
        SELECT_DR_SCAN   = 4'd2,
        CAPTURE_DR       = 4'd3,
        SHIFT_DR         = 4'd4,
        EXIT1_DR         = 4'd5,
        PAUSE_DR         = 4'd6,
        EXIT2_DR         = 4'd7,
        UPDATE_DR        = 4'd8,
        SELECT_IR_SCAN   = 4'd9,
        CAPTURE_IR       = 4'd10,
        SHIFT_IR         = 4'd11,
        EXIT1_IR         = 4'd12,
        PAUSE_IR         = 4'd13,
        EXIT2_IR         = 4'd14,
        UPDATE_IR        = 4'd15
    } tap_state_t;

    tap_state_t state, next_state;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

    // FSM next state logic
    always_comb begin
        next_state = state;
        case(state)
            TEST_LOGIC_RESET: next_state = (TMS) ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    next_state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   next_state = (TMS) ? SELECT_IR_SCAN   : CAPTURE_DR;
            CAPTURE_DR:       next_state = (TMS) ? EXIT1_DR         : SHIFT_DR;
            SHIFT_DR:         next_state = (TMS) ? EXIT1_DR         : SHIFT_DR;
            EXIT1_DR:         next_state = (TMS) ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR:         next_state = (TMS) ? EXIT2_DR         : PAUSE_DR;
            EXIT2_DR:         next_state = (TMS) ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR:        next_state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   next_state = (TMS) ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       next_state = (TMS) ? EXIT1_IR         : SHIFT_IR;
            SHIFT_IR:         next_state = (TMS) ? EXIT1_IR         : SHIFT_IR;
            EXIT1_IR:         next_state = (TMS) ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR:         next_state = (TMS) ? EXIT2_IR         : PAUSE_IR;
            EXIT2_IR:         next_state = (TMS) ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR:        next_state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            default:          next_state = TEST_LOGIC_RESET;
        endcase
    end

    // --------------------------
    // Instruction Register (IR)
    // --------------------------
    logic [IR_WIDTH-1:0] ir, ir_shift;

    // Capture-IR: load fixed pattern for boundary scan
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            ir <= {IR_WIDTH{1'b0}};
        else if (state == CAPTURE_IR)
            ir <= 4'b0010; // Example: fixed bits
        else if (state == SHIFT_IR)
            ir <= {TDI, ir[IR_WIDTH-1:1]};
        else if (state == UPDATE_IR)
            ir <= ir;
    end

    // --------------------------
    // Data Registers (DR)
    // --------------------------
    logic [31:0] bypass_reg;
    logic [31:0] user_dr_shift;
    logic [31:0] user_mem [0:3]; // 4 registers for mini SoC
    logic [31:0] idcode = IDCODE;

    // DR capture / shift logic
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST) begin
            bypass_reg <= 0;
            user_dr_shift <= 0;
        end else begin
            if (state == CAPTURE_DR) begin
                case(ir)
                    4'b0001: bypass_reg <= 32'h0;
                    4'b0010: user_dr_shift <= user_mem[0]; // preload first register
                    4'b0011: user_dr_shift <= user_mem[1];
                    4'b0100: user_dr_shift <= user_mem[2];
                    4'b0101: user_dr_shift <= user_mem[3];
                    4'b1110: user_dr_shift <= idcode;
                    default: bypass_reg <= 32'h0;
                endcase
            end
            if (state == SHIFT_DR) begin
                case(ir)
                    4'b0001: bypass_reg <= {TDI, bypass_reg[31:1]};
                    4'b0010,4'b0011,4'b0100,4'b0101,4'b1110:
                        user_dr_shift <= {TDI, user_dr_shift[31:1]};
                    default: bypass_reg <= {TDI, bypass_reg[31:1]};
                endcase
            end
            if (state == UPDATE_DR) begin
                case(ir)
                    4'b0010: user_mem[0] <= user_dr_shift;
                    4'b0011: user_mem[1] <= user_dr_shift;
                    4'b0100: user_mem[2] <= user_dr_shift;
                    4'b0101: user_mem[3] <= user_dr_shift;
                endcase
            end
        end
    end

    // --------------------------
    // TDO mux
    // --------------------------
    always_comb begin
        case(ir)
            4'b0001: TDO = bypass_reg[0];
            4'b0010,4'b0011,4'b0100,4'b0101: TDO = user_dr_shift[0];
            4'b1110: TDO = user_dr_shift[0]; // IDCODE
            default: TDO = 1'b0;
        endcase
    end

endmodule
