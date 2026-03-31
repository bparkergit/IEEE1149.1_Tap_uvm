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
    input  logic                 update_dr
);

    // ---------------------------
    // DR shift register
    // ---------------------------
    logic [DR_WIDTH-1:0] shift_reg;

    // Extract address and data from DR
    wire [$clog2(MEM_DEPTH)-1:0] addr = shift_reg[DR_WIDTH-1 -: $clog2(MEM_DEPTH)];
    wire [DATA_WIDTH-1:0]        data = shift_reg[DATA_WIDTH-1:0];

    // ---------------------------
    // Memory instance
    // ---------------------------
    logic                     mem_write_en;
    logic [DATA_WIDTH-1:0]    mem_data_out;

    memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(MEM_DEPTH)
    ) mem_inst (
        .clk      (tck),
        .write_en (mem_write_en),
        .addr     (addr),
        .data_in  (data),
        .data_out (mem_data_out)
    );

    // ---------------------------
    // TAP-controlled behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
        end else begin
            if (capture_dr) begin
                // Preload shift register with memory output at current addr
                shift_reg <= { {($clog2(MEM_DEPTH)){1'b0}}, mem_data_out };
            end else if (shift_dr) begin
                // Shift in TDI
                shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
            end
            // update_dr handled separately by memory write enable
        end
    end

    // Drive memory write enable only during UPDATE_DR
    assign mem_write_en = update_dr;

    // Serial output
    assign tdo = shift_reg[0];

endmodule
