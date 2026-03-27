module bisr #(
    parameter DATA_WIDTH = 8,       // number of BISR data bits
    parameter NUM_SIB_BITS = 2      // SIB bits in DR
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    output logic tdo,
    input  logic [3:0] ir,
    input  logic [DATA_WIDTH+NUM_SIB_BITS-1:0] user_dr_shift
);

    // ---------------------------
    // Internal registers
    // ---------------------------
    logic [DATA_WIDTH-1:0] bisr_data;
    logic [NUM_SIB_BITS-1:0] sib_bits;

    // Shift register for BISR + SIB happens in TAP (user_dr_shift)
    // Capture on UPDATE_DR
    always_ff @(posedge tck or posedge trst_n) begin
        if (trst_n) begin
            bisr_data <= '0;
            sib_bits  <= '0;
            tdo       <= 0;
        end else if (ir == 4'b0010) begin // USER_DR instruction
            // SIB = MSBs of DR
            sib_bits  <= user_dr_shift[DATA_WIDTH+NUM_SIB_BITS-1:DATA_WIDTH];
            bisr_data <= user_dr_shift[DATA_WIDTH-1:0];
            tdo       <= bisr_data[DATA_WIDTH-1]; // shift out MSB first
        end else begin
            tdo <= tdi; // bypass if not USER_DR
        end
    end

endmodule
