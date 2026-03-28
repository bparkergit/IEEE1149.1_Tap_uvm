module bisr #(
    parameter DATA_WIDTH = 8
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    output logic tdo,
    input  logic [DATA_WIDTH-1:0] user_dr_shift,
    input  logic [3:0] ir,
    input  logic enable
);

    logic [DATA_WIDTH-1:0] shift_reg;
    logic [DATA_WIDTH-1:0] memory [0:255]; // memory inside BISR

    always_ff @(posedge tck or posedge trst_n) begin
        if (trst_n) shift_reg <= '0;
        else if (enable) shift_reg <= {tdi, shift_reg[DATA_WIDTH-1:1]};
    end

    assign tdo = shift_reg[0];

endmodule
