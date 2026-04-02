// ================================================================
// BISR with real memory and SIB control
// ================================================================
module bisr #(
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 256,
    parameter DR_WIDTH   = DATA_WIDTH + $clog2(MEM_DEPTH)
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    input logic tms,
    output logic tdo,
    input  logic shift_dr,
    input  logic capture_dr,
    input  logic update_dr,
    input  logic enable
);

    // ---------------------------
    // DR shift register
    // ---------------------------
    logic [DR_WIDTH-1:0] shift_reg;

    // Extract address/data
    wire [$clog2(MEM_DEPTH)-1:0] addr_in  = shift_reg[DR_WIDTH-1 -: $clog2(MEM_DEPTH)];
    wire [DATA_WIDTH-1:0]        data_in  = shift_reg[DATA_WIDTH-1:0];

    // Latch address/data on UPDATE_DR
    logic [$clog2(MEM_DEPTH)-1:0] latched_addr;
    logic [DATA_WIDTH-1:0]        latched_data;
	logic latched_update, latched_enable;
  
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            latched_addr <= '0;
            latched_data <= '0;
            latched_update <= 0;
        end else if (update_dr & enable) begin
            latched_addr <= addr_in;
            latched_data <= data_in;
        end
      		latched_update <= update_dr;
      		latched_enable <= enable;
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
      .write_en (latched_update & latched_enable),
        .addr     (latched_addr),
        .data_in  (latched_data),
        .data_out (mem_data_out)
    );

    // ---------------------------
    // Shift register behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            shift_reg <= '0;
        else if (enable) begin
            if (capture_dr)
                shift_reg <= {addr_in, mem_data_out};
          else if (shift_dr && !tms)
                shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
        end
    end

    // ---------------------------
    // Serial output
    // ---------------------------
    assign tdo = shift_reg[0];

endmodule
