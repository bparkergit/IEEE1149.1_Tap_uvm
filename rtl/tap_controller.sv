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

    // Realistic outputs for external instruments
    output logic [IR_WIDTH-1:0] ir_out,
    output logic [DR_WIDTH-1:0] dr_out,
    output logic bypass_enable
);

    // --------------------------
    // TAP FSM
    // --------------------------
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET=0,
        RUN_TEST_IDLE   =1,
        SELECT_DR_SCAN  =2,
        CAPTURE_DR      =3,
        SHIFT_DR        =4,
        EXIT1_DR        =5,
        PAUSE_DR        =6,
        EXIT2_DR        =7,
        UPDATE_DR       =8,
        SELECT_IR_SCAN  =9,
        CAPTURE_IR      =10,
        SHIFT_IR        =11,
        EXIT1_IR        =12,
        PAUSE_IR        =13,
        EXIT2_IR        =14,
        UPDATE_IR       =15
    } tap_state_t;

    tap_state_t state, next_state;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

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
            default: next_state = TEST_LOGIC_RESET;
        endcase
    end

    // --------------------------
    // Instruction Register
    // --------------------------
    logic [IR_WIDTH-1:0] ir_shift;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            ir_shift <= '0;
        else if (state == CAPTURE_IR)
            ir_shift <= 4'b0010;  // example fixed capture
        else if (state == SHIFT_IR)
            ir_shift <= {TDI, ir_shift[IR_WIDTH-1:1]};
        else if (state == UPDATE_IR)
            ir_shift <= ir_shift;
    end

    assign ir_out = ir_shift;

    // --------------------------
    // Data Register Mux
    // --------------------------
    logic [DR_WIDTH-1:0] dr_shift;
    logic [DR_WIDTH-1:0] bypass_reg;
    logic [DR_WIDTH-1:0] idcode_reg = IDCODE;

    // Capture phase
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST) begin
            dr_shift <= '0;
            bypass_reg <= 0;
        end else if (state == CAPTURE_DR) begin
            case(ir_shift)
                4'b0001: bypass_reg <= 0;
                4'b1110: dr_shift <= idcode_reg; // IDCODE
                4'b0010: dr_shift <= '0; // USER_DR (BISR can use this)
                default: bypass_reg <= 0;
            endcase
        end
        else if (state == SHIFT_DR) begin
            case(ir_shift)
                4'b0001: bypass_reg <= {TDI, bypass_reg[DR_WIDTH-1:1]};
                default: dr_shift <= {TDI, dr_shift[DR_WIDTH-1:1]};
            endcase
        end
    end

    assign dr_out = dr_shift;
    assign bypass_enable = (ir_shift == 4'b0001);

    // --------------------------
    // TDO mux
    // --------------------------
    always_comb begin
        case(ir_shift)
            4'b0001: TDO = bypass_reg[0];
            4'b1110: TDO = dr_shift[0];
            4'b0010: TDO = dr_shift[0]; // USER_DR -> BISR
            default: TDO = 1'b0;
        endcase
    end

endmodule
