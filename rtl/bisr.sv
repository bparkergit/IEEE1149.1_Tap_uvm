module bisr #(
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 256
)(
    input  logic             tck,
    input  logic             trst_n,
    input  logic             tdi,
    output logic             tdo,
    input  logic             enable,           // SIB enable
    input  logic             capture_dr,       // TAP signals
    input  logic             shift_dr,
    input  logic             update_dr,
    input  logic [$clog2(MEM_DEPTH)-1:0] addr // optional: memory address
);

    // ---------------------------
    // Internal memory
    // ---------------------------
    logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // ---------------------------
    // Shift register
    // ---------------------------
    logic [DATA_WIDTH-1:0] shift_reg;

    // ---------------------------
    // TAP-controlled behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
        end else if (enable) begin
            if (capture_dr) begin
                // Preload shift register with memory contents
                shift_reg <= memory[addr];
            end else if (shift_dr) begin
                // Shift in new TDI bit
                shift_reg <= {tdi, shift_reg[DATA_WIDTH-1:1]};
            end else if (update_dr) begin
                // Write back to memory
                memory[addr] <= shift_reg;
            end
        end
    end

    // ---------------------------
    // Serial output
    // ---------------------------
    assign tdo = shift_reg[0];

endmodule
