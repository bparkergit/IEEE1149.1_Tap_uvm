module tap_controller #(
    parameter IR_WIDTH = 4
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO,

    output logic [IR_WIDTH-1:0] ir_out,

    // DR control signals for each segment
    output logic shift_dr_bisr,
    output logic capture_dr_bisr,
    output logic update_dr_bisr,

    output logic shift_dr_mbist,
    output logic capture_dr_mbist,
    output logic update_dr_mbist,

    output logic shift_dr_sib,
    output logic capture_dr_sib,
    output logic update_dr_sib,
    // DR serial interface
    output logic tdi_dr,
    input  logic tdo_dr
);

  localparam IR_BISR = 4'b0010;
  localparam IR_MBIST = 4'b0100;
  localparam IR_SIB = 4'b0011;  
  
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET, RUN_TEST_IDLE, SELECT_DR_SCAN,
        CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
        SELECT_IR_SCAN, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
    } tap_state_t;

    tap_state_t state, next_state;

    // FSM state register
    always_ff @(posedge TCK or posedge TRST)
        state <= (TRST) ? TEST_LOGIC_RESET : next_state;

    // FSM next-state logic
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

    // =================================================
    // IR register
    // =================================================
    logic [IR_WIDTH-1:0] ir;
    logic [IR_WIDTH-1:0] ir_active;

    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            ir <= 4'b1111;  // BYPASS
        else if (state == CAPTURE_IR)
            ir <= 4'b0010;  // default USER_DR / BISR
      else if (state == SHIFT_IR && !TMS)
            ir <= {TDI, ir[IR_WIDTH-1:1]};
        else if (state == UPDATE_IR)
            ir_active <= ir;
    end

    assign ir_out = ir;

    // =================================================
    // DR control signals
    // =================================================
    assign shift_dr_bisr   = (state == SHIFT_DR)  && (ir_active == 4'b0010);
    assign capture_dr_bisr = (state == CAPTURE_DR)&& (ir_active == 4'b0010);
    assign update_dr_bisr  = (state == UPDATE_DR) && (ir_active == 4'b0010);

    assign shift_dr_mbist   = (state == SHIFT_DR)  && (ir_active == 4'b0100);
    assign capture_dr_mbist = (state == CAPTURE_DR)&& (ir_active == 4'b0100);
    assign update_dr_mbist  = (state == UPDATE_DR) && (ir_active == 4'b0100);

    assign shift_dr_sib   = (state == SHIFT_DR)  && (ir_active == IR_SIB);
    assign capture_dr_sib = (state == CAPTURE_DR)&& (ir_active == IR_SIB);
    assign update_dr_sib  = (state == UPDATE_DR) && (ir_active == IR_SIB);
  
    // =================================================
    // Bypass / DR mux
    // =================================================
    logic bypass_reg;
    always_ff @(posedge TCK or posedge TRST) begin
        if (TRST)
            bypass_reg <= 1'b0;
        else if (state == CAPTURE_DR)
            bypass_reg <= 1'b0;
        else if (state == SHIFT_DR && ir_active != 4'b0010 && ir_active != 4'b0100)
            bypass_reg <= TDI;
    end

    assign tdi_dr = TDI;

    always_comb begin
        case (ir_active)
            4'b0010: TDO = tdo_dr;    // BISR / memory
            4'b0100: TDO = tdo_dr;    // MBIST
            default: TDO = bypass_reg;
        endcase
    end

endmodule
