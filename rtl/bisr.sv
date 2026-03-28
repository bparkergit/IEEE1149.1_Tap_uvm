module bisr #(
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 256,
    parameter DR_WIDTH   = DATA_WIDTH + $clog2(MEM_DEPTH)
)(
    input  logic                 tck,
    input  logic                 trst_n,
    input  logic                 tdi,
    output logic                 tdo,
    input  logic                 enable,       // SIB enable / instrument select
    input  logic                 capture_dr,
    input  logic                 shift_dr,
    input  logic                 update_dr
);

    // ---------------------------
    // Internal memory
    // ---------------------------
    logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // ---------------------------
    // DR shift register
    // ---------------------------
    logic [DR_WIDTH-1:0] shift_reg;

    // ---------------------------
    // Extract address & data from DR
    // ---------------------------
    wire [$clog2(MEM_DEPTH)-1:0] addr = shift_reg[DR_WIDTH-1 -: $clog2(MEM_DEPTH)];
    wire [DATA_WIDTH-1:0]        data = shift_reg[DATA_WIDTH-1:0];

    // ---------------------------
    // TAP-controlled behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
        end else if (enable) begin
            if (capture_dr) begin
                // Preload shift register with memory[addr=0] as example
                // Can be extended to select different addresses if needed
                shift_reg <= { {($clog2(MEM_DEPTH)){1'b0}}, memory[0] };
            end else if (shift_dr) begin
                // Shift in TDI
                shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
            end else if (update_dr) begin
                // Write to memory at decoded address
                memory[addr] <= data;
            end
        end
    end

    // ---------------------------
    // Serial output
    // ---------------------------
    assign tdo = shift_reg[0];

endmodule
