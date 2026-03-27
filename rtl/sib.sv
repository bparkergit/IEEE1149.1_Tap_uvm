module sib #(
    parameter NUM_INSTR = 2,           // number of instruments on the bus
    parameter MAX_WIDTH = 32           // max width of instrument data
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out
);

    // ---------------------------
    // Instrument select register
    // ---------------------------
    logic [$clog2(NUM_INSTR)-1:0] sel_bits;  // select which instrument
    logic [MAX_WIDTH-1:0] instr_shift [NUM_INSTR-1:0]; // per-instrument shift registers

    logic tdi, tdo_chain;
    assign tdi = tdi_in;

    // ---------------------------
    // Serial shifting logic
    // ---------------------------
    integer i;
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            sel_bits <= '0;
            for (i=0; i<NUM_INSTR; i=i+1)
                instr_shift[i] <= '0;
        end else begin
            // shift instrument select first (MSBs)
            sel_bits <= {sel_bits[$clog2(NUM_INSTR)-2:0], tdi};

            // then shift instrument data
            for (i=0; i<NUM_INSTR; i=i+1) begin
                if (i == sel_bits)
                    instr_shift[i] <= {instr_shift[i][MAX_WIDTH-2:0], tdi}; // active instrument
                // inactive instruments can bypass or just hold their state
            end
        end
    end

    // ---------------------------
    // TDO multiplexer
    // ---------------------------
    assign tdo_out = instr_shift[sel_bits][MAX_WIDTH-1];

endmodule
