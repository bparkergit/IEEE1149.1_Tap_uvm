// ================================================================
// BISR (Built-In Self-Repair) RTL with real memory
// Supports TAP-controlled DR shift, address + data, and SIB enable
// ================================================================
module bisr #(
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 256,
    parameter DR_WIDTH   = DATA_WIDTH + $clog2(MEM_DEPTH)
)(
    input  logic                 tck,
    input  logic                 trst_n,
    input  logic                 tdi,
    output logic                 tdo,
    input  logic                 capture_dr,
    input  logic                 shift_dr,
    input  logic                 update_dr,
    input  logic                 enable        // from SIB
);

    // ---------------------------
    // DR shift register
    // ---------------------------
    logic [DR_WIDTH-1:0] shift_reg;

    // Extract address and data from DR
    wire [$clog2(MEM_DEPTH)-1:0] addr_in  = shift_reg[DR_WIDTH-1 -: $clog2(MEM_DEPTH)];
    wire [DATA_WIDTH-1:0]        data_in  = shift_reg[DATA_WIDTH-1:0];

    // ---------------------------
    // Latch address/data on UPDATE_DR
    // ---------------------------
    logic [$clog2(MEM_DEPTH)-1:0] latched_addr;
    logic [DATA_WIDTH-1:0]        latched_data;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            latched_addr <= '0;
            latched_data <= '0;
        end else if (update_dr & enable) begin
            latched_addr <= addr_in;
            latched_data <= data_in;
        end
    end

    // ---------------------------
    // Memory instance
    // ---------------------------
    logic [DATA_WIDTH-1:0] mem_data_out;

    memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(MEM_DEPTH)
    ) mem_inst (
        .clk      (tck),
        .write_en (update_dr & enable),
        .addr     (latched_addr),
        .data_in  (latched_data),
        .data_out (mem_data_out)
    );

    // ---------------------------
    // TAP-controlled behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
        end else if (enable) begin
            if (capture_dr) begin
                // Preload shift_reg with memory content at latched address
                shift_reg <= {addr_in, mem_data_out};
            end else if (shift_dr) begin
                // Shift in new TDI bit
                shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
            end
        end
    end

    // ---------------------------
    // Serial output
    // ---------------------------
    assign tdo = shift_reg[0];

endmodule
